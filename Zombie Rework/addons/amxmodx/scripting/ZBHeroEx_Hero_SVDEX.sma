#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "[ZEVO] Hero: SVDEX"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define DAMAGE_A 450
#define DAMAGE_B 1300
#define CLIP 20
#define BPAMMO 180
#define SPEED 0.35
#define RECOIL 0.5
#define SVDEX_KNOCKPOWER 200.0

#define GRENADE_RADIUS 180
#define GRENADE_DEFAULT 10
#define GRENADE_RELOAD_TIME 2.8

#define PLAYER_SPEED 280.0
#define TIME_CHANGE 1.5
#define TIME_RELOAD 4.0

#define CSW_SVDEX CSW_AK47
#define weapon_svdex "weapon_ak47"

#define MODEL_V "models/zombie_evolution/swpn/v_svdex.mdl"
#define MODEL_P "models/zombie_evolution/swpn/p_svdex.mdl"
#define MODEL_S "models/zombie_evolution/swpn/shell_svdex.mdl"

new const WeaponSounds[3][] =
{
	"weapons/svdex-1.wav",
	"weapons/svdex-launcher.wav",
	"weapons/svdex_exp.wav"
	//"weapons/svdex_clipin.wav",
	//"weapons/svdex_clipon.wav",
	//"weapons/svdex_clipout.wav",
	//"weapons/svdex_draw.wav",
	//"weapons/svdex_foley1.wav",
	//"weapons/svdex_foley2.wav",
	//"weapons/svdex_foley3.wav",
	//"weapons/svdex_foley4.wav"
}

/*
new const WeaponResources[4][] = 
{
	"sprites/weapon_svdex.txt",
	"sprites/640hud36_2.spr",
	"sprites/640hud41_2.spr",
	"sprites/640hud7_2.spr"
}*/

enum
{
	ANIME_IDLE = 0,
	ANIME_SHOOT,
	ANIME_RELOAD,
	ANIME_DRAW,
	ANIME_GRENADE_IDLE,
	ANIME_GRENADE_SHOOT,
	ANIME_GRENADE_SHOOT_LAST,
	ANIME_GRENADE_DRAW,
	ANIME_TO_GRENADE,
	ANIME_TO_CARBINE
}

#define TASK_CHANGE 1986

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Vars
new g_SVDEX
new g_Had_SVDEX, g_InGrenadeMode, g_Clip[33], Float:g_Recoil[33][3], g_Changing, g_GrenadeAmmo[33]
new g_Event_SVDEX, g_SmokePuff_SprId, R762_ShellID, g_Trail_SprID, g_Exp_SprID, g_Smoke_SprID
new g_MsgWeaponList, g_MsgCurWeapon, g_MsgAmmoX, m_iBlood[2]

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33], g_HamBot

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_touch("svdex_shell", "*", "fw_GrenadeTouch")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")

	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_svdex, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_svdex, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_svdex, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_svdex, "fw_Item_PostFrame")
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_Weapon_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player_Post", 1)	

	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgAmmoX = get_user_msgid("AmmoX")
	g_MsgWeaponList = get_user_msgid("WeaponList")
	
	g_SVDEX = zbheroex_register_specialweapon("SVDEX", HUMAN_HERO)
	register_clcmd("weapon_svdex", "Hook_Weapon")
}

public plugin_precache()
{
	precache_model(MODEL_V)
	precache_model(MODEL_P)
	precache_model(MODEL_S)

	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
	
	/*
	precache_generic(WeaponResources[0])
	precache_model(WeaponResources[1])
	precache_model(WeaponResources[2])
	precache_model(WeaponResources[3])*/

	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	R762_ShellID = engfunc(EngFunc_PrecacheModel, "models/rshell_big.mdl")
	g_Trail_SprID = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_Exp_SprID = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
	g_Smoke_SprID = engfunc(EngFunc_PrecacheModel, "sprites/steam1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/ak47.sc", name)) g_Event_SVDEX = get_orig_retval()		
}

public client_putinserver(id)
{
	Safety_Connected(id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id) 
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player_Post", 1)
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
}

public zbheroex_specialweapon(id, Type, ItemID)
{
	if(ItemID == g_SVDEX) Get_SVDEX(id)
}

public zbheroex_specialweapon_refill(id,  ItemID)
{
	if(ItemID == g_SVDEX) 
	{
		cs_set_user_bpammo(id, CSW_SVDEX, BPAMMO)
	}
}

public zbheroex_specialweapon_remove(id, ItemID)
{
	if(ItemID == g_SVDEX) Remove_SVDEX(id)
}

public Get_SVDEX(id)
{
	Set_BitVar(g_Had_SVDEX, id)
	UnSet_BitVar(g_InGrenadeMode, id)
	UnSet_BitVar(g_Changing, id)
	g_GrenadeAmmo[id] = GRENADE_DEFAULT
	
	give_item(id, weapon_svdex)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_SVDEX, BPAMMO)
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(CLIP)
	message_end()
}

public Remove_SVDEX(id)
{
	UnSet_BitVar(g_Had_SVDEX, id)
	UnSet_BitVar(g_InGrenadeMode, id)
	UnSet_BitVar(g_Changing, id)
	g_GrenadeAmmo[id] = 0
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_svdex)
	return PLUGIN_HANDLED
}

public update_ammo2(id, ammo, bpammo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_MsgCurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgAmmoX, _, id)
	write_byte(1)
	write_byte(bpammo)
	message_end()
	
	cs_set_user_bpammo(id, CSW_SVDEX, bpammo)
}

public Event_CurWeapon(id)
{
	static CSW; CSW = read_data(2)
	if(CSW != CSW_SVDEX)
		return
	if(!Get_BitVar(g_Had_SVDEX, id))	
		return

	static Float:Delay, Float:Delay2
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(!pev_valid(Ent)) return
	/*
	Delay = get_pdata_float(Ent, 46, 4) * SPEED
	Delay2 = get_pdata_float(Ent, 47, 4) * SPEED
	
	if(Delay > 0.0)
	{*/
		set_pdata_float(Ent, 46, SPEED, 4)
		set_pdata_float(Ent, 47, SPEED, 4)
	//}
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) == CSW_SVDEX && Get_BitVar(g_Had_SVDEX, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, invoker))
		return FMRES_IGNORED
		
	if(eventid == g_Event_SVDEX)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		Set_WeaponAnim(invoker, ANIME_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.4, 0, 94 + random_num(0, 15))
	
		// Eject Shell
		Eject_Shell(invoker, R762_ShellID, 0.0)
	
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, id))	
		return FMRES_IGNORED
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	
	if(NewButton & IN_ATTACK)
	{
		if(Get_BitVar(g_Changing, id))
		{
			NewButton &= ~IN_ATTACK
			set_uc(uc_handle, UC_Buttons, NewButton)
			
			return FMRES_IGNORED
		}
		
		if(!Get_BitVar(g_InGrenadeMode, id))
			return FMRES_IGNORED
			
		NewButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, NewButton)
		
		Shoot_Grenade_Handle(id)
	} 
	
	if(NewButton & IN_ATTACK2) {
		NewButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, NewButton)
		
		NewButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, NewButton)
		
		if((pev(id, pev_oldbuttons) & IN_ATTACK2))
			return FMRES_IGNORED
		if(get_pdata_float(id, 83, 5) > 0.0)
			return FMRES_IGNORED
			
		Set_BitVar(g_Changing, id)
			
		Set_WeaponIdleTime(id, CSW_SVDEX, TIME_CHANGE + 0.5)
		Set_PlayerNextAttack(id, TIME_CHANGE + 0.25)	
			
		Set_WeaponAnim(id, !Get_BitVar(g_InGrenadeMode, id) ? ANIME_TO_GRENADE : ANIME_TO_CARBINE)
		set_task(TIME_CHANGE, "SVDEX_CHANGE_COMPLETE", id+TASK_CHANGE)
	}
	
	return FMRES_IGNORED
}

public SVDEX_CHANGE_COMPLETE(id)
{
	id -= TASK_CHANGE
	
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, id))	
		return
	if(!Get_BitVar(g_Changing, id))
		return
		
	UnSet_BitVar(g_Changing, id)
			
	if(!Get_BitVar(g_InGrenadeMode, id)) Set_BitVar(g_InGrenadeMode, id)
	else UnSet_BitVar(g_InGrenadeMode, id)
	
	Change_Complete(id)
}

public Change_Complete(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(!pev_valid(Ent))
		return
		
	if(!Get_BitVar(g_InGrenadeMode, id))
	{
		update_ammo2(id, pev(Ent, pev_iuser3), pev(Ent, pev_iuser4))
	} else {
		set_pev(Ent, pev_iuser3, cs_get_weapon_ammo(Ent))
		set_pev(Ent, pev_iuser4, cs_get_user_bpammo(id, CSW_SVDEX))
		
		update_ammo2(id, -1, g_GrenadeAmmo[id])
	}
}


public Shoot_Grenade_Handle(id)
{
	if(get_pdata_float(id, 83, 5) > 0.0)
		return
	if(!Get_BitVar(g_InGrenadeMode, id))	
		return
	if(Get_BitVar(g_Changing, id))
		return
	if(!g_GrenadeAmmo[id])
	{
		Set_BitVar(g_Changing, id)
			
		Set_WeaponIdleTime(id, CSW_SVDEX, TIME_CHANGE + 0.5)
		Set_PlayerNextAttack(id, TIME_CHANGE + 0.25)	
			
		Set_WeaponAnim(id, !Get_BitVar(g_InGrenadeMode, id) ? ANIME_TO_GRENADE : ANIME_TO_CARBINE)
		set_task(TIME_CHANGE, "SVDEX_CHANGE_COMPLETE", id+TASK_CHANGE)
		
		return
	}
	
	g_GrenadeAmmo[id]--
	update_ammo2(id, -1, g_GrenadeAmmo[id])
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	if(pev_valid(weapon_ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_ent)	
	
	if(g_GrenadeAmmo[id]) 
	{
		Set_WeaponIdleTime(id, CSW_SVDEX, GRENADE_RELOAD_TIME + 0.1)
		Set_PlayerNextAttack(id, GRENADE_RELOAD_TIME)
		
		Set_WeaponAnim(id, ANIME_GRENADE_SHOOT)
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	} else {
		Set_WeaponIdleTime(id, CSW_SVDEX, (GRENADE_RELOAD_TIME / 2.0) + 0.1)
		Set_PlayerNextAttack(id, (GRENADE_RELOAD_TIME / 2.0))
		
		Set_WeaponAnim(id, ANIME_GRENADE_SHOOT_LAST)
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	static Float:PunchAngles[3]
	PunchAngles[0] = random_float(-2.0, -3.0)
	
	set_pev(id, pev_punchangle, PunchAngles)
	
	Create_Grenade(id)
}

public Create_Grenade(id)
{
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	static Float:Origin[3], Float:Angles[3]
	
	get_weapon_attachment(id, Origin, 24.0)
	pev(id, pev_angles, Angles)
	
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	
	set_pev(Ent, pev_classname, "svdex_shell")
	engfunc(EngFunc_SetModel, Ent, MODEL_S)
	set_pev(Ent, pev_origin, Origin)
	set_pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_owner, id)
	
	// Create Velocity
	static Float:Velocity[3], Float:TargetOrigin[3]
	
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, 1800.0, Velocity)
	
	set_pev(Ent, pev_velocity, Velocity)
	
	// Make a Beam
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent) // entity
	write_short(g_Trail_SprID) // sprite
	write_byte(20)  // life
	write_byte(4)  // width
	write_byte(200) // r
	write_byte(200);  // g
	write_byte(200);  // b
	write_byte(200); // brightness
	message_end();
}

public fw_GrenadeTouch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
		
	Make_Explosion(Ent)
	
	// Remove
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
	set_pev(Ent, pev_flags, FL_KILLME)
}

public Make_Explosion(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	static ID; ID = pev(Ent, pev_owner)
	if(!is_connected(ID))
		return
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Exp_SprID)	// sprite index
	write_byte(40)	// scale in 0.1's
	write_byte(20)	// framerate
	write_byte(0)	// flags
	message_end()
	
	// Put decal on "world" (a wall)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(random_num(46, 48))
	message_end()	
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_SMOKE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_Smoke_SprID)	// sprite index 
	write_byte(50)	// scale in 0.1's 
	write_byte(10)	// framerate 
	message_end()
	
	static Victim; Victim = -1
	while((Victim = find_ent_in_sphere(Victim, Origin, float(GRENADE_RADIUS))) != 0)
	{
		if(!is_alive(Victim))
			continue
		if(cs_get_user_team(Victim) == cs_get_user_team(ID))
			continue
		if(!zbheroex_get_user_zombie(Victim))
			return
			
		ExecuteHamB(Ham_TakeDamage, Victim, 0, ID, float(DAMAGE_B), DMG_BULLET)
	}
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_SVDEX, Id))
		return
	
	remove_task(Id+TASK_CHANGE)
	UnSet_BitVar(g_Changing, Id)
	
	if(Get_BitVar(g_InGrenadeMode, Id))
	{
		UnSet_BitVar(g_InGrenadeMode, Id)
		Change_Complete(Id)
	}
	
	set_pev(Id, pev_viewmodel2, MODEL_V)
	set_pev(Id, pev_weaponmodel2, MODEL_P)

	set_pev(Id, pev_maxspeed, PLAYER_SPEED)
	Set_WeaponAnim(Id, ANIME_DRAW)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2172015)
	{
		Set_BitVar(g_Had_SVDEX, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	/*
	if(Get_BitVar(g_Had_SVDEX, id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgWeaponList, _, id)
		write_string("weapon_svdex")
		write_byte(2)
		write_byte(180)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(1)
		write_byte(CSW_SVDEX)
		write_byte(0)
		message_end()
	}*/
	
	return HAM_HANDLED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_SVDEX, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SVDEX)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_SVDEX, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		fInReload = 0
	}		
	
	return HAM_IGNORED
}

public fw_Weapon_Reload(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_SVDEX, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_SVDEX)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= CLIP)
		return HAM_SUPERCEDE		
			
	g_Clip[id] = iClip	
	
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_SVDEX, id))
		return HAM_IGNORED	
	
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if(g_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_Clip[id], 4)
		Set_WeaponAnim(id, ANIME_RELOAD)
		
		Set_PlayerNextAttack(id, TIME_RELOAD)
	}
	
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post( iEnt )
{
	if(pev_valid(iEnt) != 2)
		return
	static Id; Id = get_pdata_cbase(iEnt, 41, 4)
	if(get_pdata_cbase(Id, 373) != iEnt)
		return
	if(!Get_BitVar(g_Had_SVDEX, Id))
		return
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		if(!Get_BitVar(g_InGrenadeMode, Id)) Set_WeaponAnim(Id, ANIME_IDLE)
		else Set_WeaponAnim(Id, ANIME_GRENADE_IDLE)
		
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}

public fw_Weapon_PrimaryAttack(Ent)
{
	static id; id = pev(Ent, pev_owner)
	pev(id, pev_punchangle, g_Recoil[id])
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	static id; id = pev(Ent, pev_owner)
	
	if(Get_BitVar(g_Had_SVDEX, id))
	{
		static Float:Push[3]
		pev(id, pev_punchangle, Push)
		xs_vec_sub(Push, g_Recoil[id], Push)
		
		xs_vec_mul_scalar(Push, RECOIL, Push)
		xs_vec_add(Push, g_Recoil[id], Push)
		set_pev(id, pev_punchangle, Push)
		
		set_pdata_float(Ent, 62 , 0.1, 4)
	}
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)

	SetHamParamFloat(3, float(DAMAGE_A))
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, Attacker))
		return HAM_IGNORED

	static Float:flEnd[3]
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	create_blood(flEnd)
		
	SetHamParamFloat(3, float(DAMAGE_A))
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player_Post(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, Attacker))
		return HAM_IGNORED
	if(cs_get_user_team(Victim) == cs_get_user_team(Attacker))
		return HAM_IGNORED
		
	set_pdata_float(Victim, 108, 0.5, 5)
	
	static Float:Ori[3], Float:Ori2[3], Float:Vel[3]
	
	pev(Attacker, pev_origin, Ori)
	pev(Victim, pev_origin, Ori2)
	
	Get_SpeedVector(Ori, Ori2, SVDEX_KNOCKPOWER, Vel)
	set_pev(Victim, pev_velocity, Vel)
	
	return HAM_HANDLED
}

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_alive(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	if(!Get_BitVar(g_IsAlive, id)) 
		return 0
	
	return 1
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

/* ===============================
--------- End of SAFETY ----------
=================================*/

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Make_BulletHole(id, Float:Origin[3], Float:Damage)
{
	// Find target
	static Decal; Decal = random_num(41, 45)
	static LoopTime; 
	
	if(Damage > 100.0) LoopTime = 2
	else LoopTime = 1
	
	for(new i = 0; i < LoopTime; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(Decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(Decal)
		message_end()
	}
}

stock Make_BulletSmoke(id, TrResult)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(TrResult, TR_vecEndPos, vecSrc)
	get_tr2(TrResult, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	static Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	static Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	static Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	static Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock Set_WeaponIdleTime(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock Set_PlayerNextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Get_Position(id,Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

stock Get_SpeedVector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	new Float:num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= (num * 2.0)
	new_velocity[1] *= (num * 2.0)
	new_velocity[2] *= (num / 2.0)
}  
