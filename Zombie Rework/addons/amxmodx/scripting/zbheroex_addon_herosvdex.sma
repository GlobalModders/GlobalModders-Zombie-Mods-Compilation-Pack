#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Addon: Hero's SVDEX"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define V_MODEL "models/zombie_thehero/weapon/v_svdex.mdl"
#define P_MODEL "models/zombie_thehero/weapon/p_svdex.mdl"
#define S_MODEL "models/zombie_thehero/weapon/s_svdex.mdl"

#define CSW_SVDEX CSW_AK47
#define weapon_svdex "weapon_ak47"
#define WEAPON_EVENT "events/ak47.sc"

#define DAMAGE 240
#define CLIP 20
#define BPAMMO 180
#define SPEED 4.0
#define RECOIL 0.1
#define ACCURACY 0.1

#define GRENADE_DAMAGE 800
#define GRENADE_RADIUS 200
#define GRENADE_DEFAULT 10
#define RELOAD_TIME 3.8
#define GRENADE_RELOAD_TIME 2.8

#define PLAYER_SPEED 270.0
#define CHANGE_TIME 1.5

#define TASK_CHANGE 1986

new const WeaponSounds[10][] = 
{
	"weapons/svdex-1.wav",
	"weapons/svdex-launcher.wav",
	"weapons/svdex_draw.wav",
	"weapons/svdex_clipin.wav",
	"weapons/svdex_clipon.wav",
	"weapons/svdex_clipout.wav",
	"weapons/svdex_foley1.wav",
	"weapons/svdex_foley2.wav",
	"weapons/svdex_foley3.wav",
	"weapons/svdex_foley4.wav"
}

enum
{
	ANIM_CARBINE_IDLE = 0,
	ANIM_CARBINE_SHOOT,
	ANIM_CARBINE_RELOAD,
	ANIM_CARBINE_DRAW,
	ANIM_GRENADE_IDLE,
	ANIM_GRENADE_SHOOT1,
	ANIM_GRENADE_SHOOT2,
	ANIM_GRENADE_DRAW,
	ANIM_MOVE_TO_GRENADE,
	ANIM_MOVE_TO_CARBINE
}

enum
{
	SVDEX_MODE_CARBINE = 1,
	SVDEX_MODE_GRENADE
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_SVDEX, g_InGrenadeMode, g_Changing, g_GrenadeAmmo[33], Float:g_Recoil[33][3], g_Clip[33]
new g_old_weapon[33], g_smokepuff_id, g_ham_bot, R762_ShellID, g_svdex_event, spr_trail, g_expspr_id, g_SmokeSprId
new g_Msg_CurWeapon, g_Msg_AmmoX
new g_MaxPlayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_touch("grenade2", "*", "fw_GrenadeTouch")

	register_forward(FM_Think, "fw_Think")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_CmdStart, "fw_CmdStart")	
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_svdex, "fw_Weapon_PrimaryAttack_Post", 1)	
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_svdex, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_svdex, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_svdex, "fw_Weapon_WeaponIdle_Post", 1)

	g_Msg_CurWeapon = get_user_msgid("CurWeapon")
	g_Msg_AmmoX = get_user_msgid("AmmoX")
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, S_MODEL)
	
	new i 
	for(i = 0; i < sizeof(WeaponSounds); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSounds[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	R762_ShellID = engfunc(EngFunc_PrecacheModel, "models/rshell_big.mdl")
	spr_trail = engfunc(EngFunc_PrecacheModel, "sprites/laserbeam.spr")
	g_expspr_id = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
	g_SmokeSprId = engfunc(EngFunc_PrecacheModel, "sprites/steam1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_svdex_event = get_orig_retval()		
}

public zbheroex_user_hero(id, FemaleHero)
{
	if(FemaleHero) return
	Get_SVDEX(id)
}

public zbheroex_user_infected(id) Remove_SVDEX(id)
public zbheroex_user_died(id) Remove_SVDEX(id)
public zbheroex_user_spawned(id, Zombie)
{
	if(Zombie) return
	Remove_SVDEX(id)
}

public Get_SVDEX(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_Had_SVDEX, id)
	UnSet_BitVar(g_InGrenadeMode, id)
	UnSet_BitVar(g_Changing, id)
	g_GrenadeAmmo[id] = GRENADE_DEFAULT
	
	fm_give_item(id, weapon_svdex)
	
	// Set Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	
	for(new i = 0; i < 6; i++) give_ammo(id, 0, CSW_SVDEX)
	update_ammo(id, CSW_SVDEX, CLIP, BPAMMO)
}

public update_ammo(id, CSWID, Ammo, BpAmmo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSWID)
	write_byte(Ammo)
	message_end()		
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_AmmoX, _, id)
	write_byte(1)
	write_byte(BpAmmo)
	message_end()
}

public Remove_SVDEX(id)
{	
	UnSet_BitVar(g_Had_SVDEX, id)
	UnSet_BitVar(g_InGrenadeMode, id)
	UnSet_BitVar(g_Changing, id)
	g_GrenadeAmmo[id] = 0
}

public client_putinserver(id)
{
	if(!g_ham_bot && is_user_bot(id))
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_HamBot", id)
	}
}

public Do_Register_HamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if((get_user_weapon(id) == CSW_SVDEX && Get_BitVar(g_Had_SVDEX, id)) && g_old_weapon[id] != CSW_SVDEX)
	{ // Draw
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		if(Get_BitVar(g_InGrenadeMode, id))
		{
			static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
			update_ammo(id, CSW_SVDEX, pev(Ent, pev_iuser3), pev(Ent, pev_iuser4))
		}
		
		UnSet_BitVar(g_InGrenadeMode, id)
		
		set_weapon_anim(id, ANIM_CARBINE_DRAW)
		set_pev(id, pev_maxspeed, PLAYER_SPEED)
	} else {
		if(Get_BitVar(g_InGrenadeMode, id))
		{
			static Ent; Ent = fm_get_user_weapon_entity(id, CSW_SVDEX)
			if(!pev_valid(Ent))
				return
			
			cs_set_user_bpammo(id, CSW_SVDEX, pev(Ent, pev_iuser4))
		} 
		
		UnSet_BitVar(g_Changing, id)
	
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_SVDEX && Get_BitVar(g_Had_SVDEX, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(eventid == g_svdex_event)
	{
		if(get_user_weapon(invoker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, invoker))
			return FMRES_IGNORED
		
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		
		set_weapon_anim(invoker, ANIM_CARBINE_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
		// Eject Shell
		Eject_Shell(invoker, R762_ShellID, 0.0)
		
		return FMRES_SUPERCEDE
	} 
	
	return FMRES_HANDLED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, id))	
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
			
		set_weapons_timeidle(id, CHANGE_TIME + 0.1)
		set_player_nextattack(id, CHANGE_TIME)	
			
		set_weapon_anim(id, !Get_BitVar(g_InGrenadeMode, id) ? ANIM_MOVE_TO_GRENADE : ANIM_MOVE_TO_CARBINE)
		set_task(CHANGE_TIME, "SVDEX_CHANGE_COMPLETE", id+TASK_CHANGE)
	}
	
	return FMRES_IGNORED
}

public SVDEX_CHANGE_COMPLETE(id)
{
	id -= TASK_CHANGE
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, id))	
		return
	if(!Get_BitVar(g_Changing, id))
		return
		
	UnSet_BitVar(g_Changing, id)
			
	if(!Get_BitVar(g_InGrenadeMode, id)) Set_BitVar(g_InGrenadeMode, id)
	else UnSet_BitVar(g_InGrenadeMode, id)
	
	Change_Complete(id)
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
			
		set_weapons_timeidle(id, CHANGE_TIME + 0.1)
		set_player_nextattack(id, CHANGE_TIME)	
			
		set_weapon_anim(id, !Get_BitVar(g_InGrenadeMode, id) ? ANIM_MOVE_TO_GRENADE : ANIM_MOVE_TO_CARBINE)
		set_task(CHANGE_TIME, "SVDEX_CHANGE_COMPLETE", id+TASK_CHANGE)
		
		return
	}
	
	g_GrenadeAmmo[id]--
	update_ammo2(id, -1, g_GrenadeAmmo[id])
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	if(pev_valid(weapon_ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_ent)	
	
	if(g_GrenadeAmmo[id]) 
	{
		set_weapons_timeidle(id, GRENADE_RELOAD_TIME + 0.1)
		set_player_nextattack(id, GRENADE_RELOAD_TIME)
		
		set_weapon_anim(id, ANIM_GRENADE_SHOOT1)
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	} else {
		set_weapons_timeidle(id, (GRENADE_RELOAD_TIME / 2.0) + 0.1)
		set_player_nextattack(id, (GRENADE_RELOAD_TIME / 2.0))
		
		set_weapon_anim(id, ANIM_GRENADE_SHOOT2)
		emit_sound(id, CHAN_WEAPON, WeaponSounds[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	static Float:PunchAngles[3]
	PunchAngles[0] = random_float(-1.0, -2.0)
	PunchAngles[2] = random_float(2.0, -2.0)
	
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
	
	set_pev(Ent, pev_classname, "grenade2")
	engfunc(EngFunc_SetModel, Ent, S_MODEL)
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
	write_short(spr_trail) // sprite
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
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Make_Explosion(ent)
{
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_expspr_id)	// sprite index
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
	write_short(g_SmokeSprId)	// sprite index 
	write_byte(50)	// scale in 0.1's 
	write_byte(10)	// framerate 
	message_end()
	
	static Float:Origin2[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, Origin2)
		if(get_distance_f(Origin, Origin2) > float(GRENADE_RADIUS))
			continue
		if(!zbheroex_get_user_zombie(i))
			continue

		ExecuteHamB(Ham_TakeDamage, i, 0, pev(ent, pev_owner), float(GRENADE_DAMAGE), DMG_BULLET)
	}
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

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, attacker))
		return HAM_IGNORED
		
		
	SetHamParamFloat(3, float(DAMAGE))	

	return HAM_HANDLED
}

public fw_TraceAttack_World(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_connected(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_SVDEX || !Get_BitVar(g_Had_SVDEX, attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	Make_BulletHole(attacker, flEnd, Damage)
	fake_smoke(attacker, ptr)
		
	SetHamParamFloat(3, float(DAMAGE))	

	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && Get_BitVar(g_Had_SVDEX, id))
	{	
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
		static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SVDEX)
		static iClip; iClip = get_pdata_int(ent, 51, 4)
		static fInReload; fInReload = get_pdata_int(ent, 54, 4)
		
		if(fInReload && flNextAttack <= 0.0)
		{
			static temp1; temp1 = min(CLIP - iClip, bpammo)

			set_pdata_int(ent, 51, iClip + temp1, 4)
			cs_set_user_bpammo(id, CSW_SVDEX, bpammo - temp1)		
			
			set_pdata_int(ent, 54, 0, 4)
			
			fInReload = 0
		}		
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
	if(Get_BitVar(g_InGrenadeMode, id))
		return HAM_SUPERCEDE
	
	g_Clip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_SVDEX)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	
	if(bpammo <= 0) return HAM_SUPERCEDE
	
	if(iClip >= 20) return HAM_SUPERCEDE		
		
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
	if(Get_BitVar(g_InGrenadeMode, id))
		return HAM_IGNORED
		
	if(!Get_BitVar(g_InGrenadeMode, id))
	{ // Reload
		if (g_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_Clip[id], 4)
		set_pdata_int(ent, 54, 1, 4)
		
		set_weapon_anim(id, ANIM_CARBINE_RELOAD)
		set_pdata_float(id, 83, RELOAD_TIME, 5)
	}
	
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_SVDEX, id))
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 48, 4) <= 0.1) 
	{
		set_weapon_anim(id, !Get_BitVar(g_InGrenadeMode, id) ? ANIM_CARBINE_IDLE : ANIM_GRENADE_IDLE)
		set_pdata_float(ent, 48, 20.0, 4)
	}
	
	return HAM_IGNORED
}

public fw_Weapon_PrimaryAttack(Ent)
{
	if(!pev_valid(Ent))
		return
	static Id; Id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_SVDEX, Id))
		return
	
	pev(Id, pev_punchangle, g_Recoil[Id])
	set_pdata_float(Ent, 62, ACCURACY, 4)
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	if(!pev_valid(Ent))
		return
	static Id; Id = pev(Ent, pev_owner)
	if(!Get_BitVar(g_Had_SVDEX, Id))
		return
	
	static Float:push[3]
	pev(Id, pev_punchangle, push)
	xs_vec_sub(push, g_Recoil[Id], push)
	
	xs_vec_mul_scalar(push, RECOIL, push)
	xs_vec_add(push, g_Recoil[Id], push)
	
	push[0] -= random_float(0.25, 1.0)
	push[1] += random_float(-0.5, 0.5)
	set_pev(Id, pev_punchangle, push)
	
	set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * SPEED, 4)	
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

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
    
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
	write_short(g_smokepuff_id)
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

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock Eject_Shell(id, Shell_ModelIndex, Float:Time) // By Dias
{
	static Ent; Ent = get_pdata_cbase(id, 373, 5)
	if(!pev_valid(Ent))
		return

        set_pdata_int(Ent, 57, Shell_ModelIndex, 4)
        set_pdata_float(id, 111, get_gametime() + Time)
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, CSW_SVDEX)
	if(!pev_valid(entwpn)) 
		return
	
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	set_pdata_float(id, 83, nexttime, 5)
}

public update_ammo2(id, ammo, bpammo)
{
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_SVDEX)
	write_byte(ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_AmmoX, _, id)
	write_byte(1)
	write_byte(bpammo)
	message_end()
	
	cs_set_user_bpammo(id, CSW_SVDEX, bpammo)
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

public give_ammo(id, silent, CSWID)
{
	static Amount, Name[32]
		
	switch(CSWID)
	{
		case CSW_P228: {Amount = 13; formatex(Name, sizeof(Name), "357sig");}
		case CSW_SCOUT: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_XM1014: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_MAC10: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_AUG: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_ELITE: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_FIVESEVEN: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
		case CSW_UMP45: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_SG550: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_GALIL: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_FAMAS: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_USP: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_GLOCK18: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_AWP: {Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
		case CSW_MP5NAVY: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_M249: {Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
		case CSW_M3: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_M4A1: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_TMP: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_G3SG1: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_DEAGLE: {Amount = 7; formatex(Name, sizeof(Name), "50ae");}
		case CSW_SG552: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_AK47: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_P90: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
	}
	
	if(!silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, Amount, Name, 254)
}
