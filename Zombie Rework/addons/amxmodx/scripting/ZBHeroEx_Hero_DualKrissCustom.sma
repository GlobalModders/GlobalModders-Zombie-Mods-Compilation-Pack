#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "[ZEVO] Hero: Dual Kriss Custom"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define DAMAGE 186
#define CLIP 70
#define BPAMMO 210
#define SPEED 0.15
#define RECOIL 0.5

#define PLAYER_SPEED 280.0
#define TIME_CHANGE 1.5
#define TIME_RELOAD 3.25

#define CSW_DKRISS CSW_UMP45
#define weapon_dkriss "weapon_ump45"

#define MODEL_V "models/zombie_evolution/swpn/v_dualkrisshero.mdl"
#define MODEL_P "models/zombie_evolution/swpn/p_dualkrisshero.mdl"

#define ANIM_EXT "dualpistols"
#define ANIM_EXT_B "dualpistols_1"

new const WeaponSounds[1][] =
{
	"weapons/dualkrisshero-1.wav"
	//"weapons/dualkriss_clipin.wav",
	//"weapons/dualkriss_clipout.wav",
	//"weapons/dualkriss_draw.wav"
}

/*
new const WeaponResources[3][] = 
{
	"sprites/weapon_dualkrisshero.txt",
	"sprites/640hud127_2.spr",
	"sprites/640hud7_2.spr"
}*/

enum
{
	ANIME_IDLE = 0,
	ANIME_IDLE_LEFTEMPT,
	ANIME_SHOOT_L1,
	ANIME_SHOOT_L2,
	ANIME_SHOOT_L_LAST,
	ANIME_SHOOT_R1,
	ANIME_SHOOT_R2,
	ANIME_SHOOT_R_LAST,
	ANIME_RELOAD,
	ANIME_DRAW
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Vars
new g_DKriss
new g_Had_DKriss, g_Clip[33], Float:g_Recoil[33][3], g_RightShoot, g_Zoom, Float:ZoomTime[33]
new g_Event_DKriss, g_SmokePuff_SprId, ShellID, m_iBlood[2]
new g_MsgWeaponList, g_MsgCurWeapon

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33], g_HamBot

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")

	register_message(get_user_msgid("DeathMsg"), "Event_DeathMsg")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_dkriss, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_dkriss, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_dkriss, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_dkriss, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_dkriss, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_dkriss, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dkriss, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_dkriss, "fw_Weapon_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	

	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgWeaponList = get_user_msgid("WeaponList")
	
	g_DKriss = zbheroex_register_specialweapon("Dual Kriss Custom", HUMAN_HERO)
	register_clcmd("weapon_dualkrisshero", "Hook_Weapon")
}

public plugin_precache()
{
	precache_model(MODEL_V)
	precache_model(MODEL_P)

	for(new i = 0; i < sizeof(WeaponSounds); i++)
		precache_sound(WeaponSounds[i])
	
	/*
	precache_generic(WeaponResources[0])
	precache_model(WeaponResources[1])
	precache_model(WeaponResources[2])*/

	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")		
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/zerogxplode.spr")
	ShellID = precache_model("models/pshell.mdl")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/ump45.sc", name)) g_Event_DKriss = get_orig_retval()		
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
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
}

public zbheroex_specialweapon(id, Type, ItemID)
{
	if(ItemID == g_DKriss) Get_DKriss(id)
}

public zbheroex_specialweapon_refill(id,  ItemID)
{
	if(ItemID == g_DKriss) 
	{
		cs_set_user_bpammo(id, CSW_DKRISS, BPAMMO)
	}
}

public zbheroex_specialweapon_remove(id, ItemID)
{
	if(ItemID == g_DKriss) Remove_DKriss(id)
}

public Get_DKriss(id)
{
	UnSet_BitVar(g_Zoom, id)
	UnSet_BitVar(g_RightShoot, id)
	Set_BitVar(g_Had_DKriss, id)
	give_item(id, weapon_dkriss)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DKRISS)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_DKRISS, BPAMMO)
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_DKRISS)
	write_byte(CLIP)
	message_end()
}

public Remove_DKriss(id)
{
	UnSet_BitVar(g_Had_DKriss, id)
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_dkriss)
	return PLUGIN_HANDLED
}

public Event_CurWeapon(id)
{
	static CSW; CSW = read_data(2)
	if(CSW != CSW_DKRISS)
		return
	if(!Get_BitVar(g_Had_DKriss, id))	
		return

	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DKRISS)
	if(!pev_valid(Ent)) return
	
	set_pdata_float(Ent, 46, SPEED, 4)
	set_pdata_float(Ent, 47, SPEED, 4)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) == CSW_DKRISS && Get_BitVar(g_Had_DKriss, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_DKRISS || !Get_BitVar(g_Had_DKriss, invoker))
		return FMRES_IGNORED
		
	if(eventid == g_Event_DKriss)
	{
		if(!Get_BitVar(g_RightShoot, invoker))
		{
			Set_BitVar(g_RightShoot, invoker)
			
			engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
			Set_WeaponAnim(invoker, ANIME_SHOOT_L2)
			emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.4, 0, 94 + random_num(0, 15))
		
			// Eject Shell
			Eject_Shell2(invoker, ShellID, 1)
			Play_AttackAnimation(invoker, 1)
		} else {
			UnSet_BitVar(g_RightShoot, invoker)
			
			engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
			Set_WeaponAnim(invoker, ANIME_SHOOT_R2)
			emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.4, 0, 94 + random_num(0, 15))
		
			// Eject Shell
			Eject_Shell2(invoker, ShellID, 0)
			Play_AttackAnimation(invoker, 0)
		}
	
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public Play_AttackAnimation(id, Right)
{
	static iAnimDesired, szAnimation[64]
	static iFlags; iFlags = pev(id, pev_flags)

	if(zbheroex_get_user_hero(id) && !zbheroex_get_user_female(id))
	{
		if(!Right)
		{	
			formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXT_B);
		} else {
			formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXT_B);
		}
	} else {
		if(!Right)
		{	
			formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXT);
		} else {
			formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXT);
		}
	}
	
	
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0;
	
	set_pev(id, pev_sequence, iAnimDesired)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_DKRISS || !Get_BitVar(g_Had_DKriss, id))
		return
	
	static Button; Button = get_uc(uc_handle, UC_Buttons)
	if(Button & IN_ATTACK2)
	{
		if(get_gametime() - 0.25 > ZoomTime[id])
		{
			if(!Get_BitVar(g_Zoom, id))
			{
				Set_BitVar(g_Zoom, id)
				cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 1)
			} else {
				UnSet_BitVar(g_Zoom, id)
				cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
			}
			
			ZoomTime[id] = get_gametime()
		}
	}
}

public Event_DeathMsg(msg_id, msg_dest, msg_entity)
{
	static Attacker
	Attacker = get_msg_arg_int(1)

	if(is_connected(Attacker) && get_player_weapon(Attacker) == CSW_DKRISS && Get_BitVar(g_Had_DKriss, Attacker))
		set_msg_arg_string(4, "elite")
	
	return PLUGIN_CONTINUE
}  

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_DKriss, Id))
		return

	UnSet_BitVar(g_Zoom, Id)
		
	set_pev(Id, pev_viewmodel2, MODEL_V)
	set_pev(Id, pev_weaponmodel2, MODEL_P)

	if(zbheroex_get_user_hero(Id) && !zbheroex_get_user_female(Id))
		set_pdata_string(Id, (492) * 4, ANIM_EXT_B, -1 , 20)
	else set_pdata_string(Id, (492) * 4, ANIM_EXT, -1 , 20)
	set_pev(Id, pev_maxspeed, PLAYER_SPEED)
	Set_WeaponAnim(Id, ANIME_DRAW)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2172015)
	{
		Set_BitVar(g_Had_DKriss, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	/*
	if(Get_BitVar(g_Had_DKriss, id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgWeaponList, _, id)
		write_string("weapon_dualkrisshero")
		write_byte(6)
		write_byte(210)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(15)
		write_byte(CSW_DKRISS)
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
	if(!Get_BitVar(g_Had_DKriss, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_DKRISS)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_DKRISS, bpammo - temp1)		
		
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
	if(!Get_BitVar(g_Had_DKriss, id))
		return HAM_IGNORED	

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_DKRISS)
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
	if(!Get_BitVar(g_Had_DKriss, id))
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
	if(!Get_BitVar(g_Had_DKriss, Id))
		return
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		Set_WeaponAnim(Id, ANIME_IDLE)
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
	
	if(Get_BitVar(g_Had_DKriss, id))
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
	if(get_player_weapon(Attacker) != CSW_DKRISS || !Get_BitVar(g_Had_DKriss, Attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	get_tr2(Ptr, TR_vecPlaneNormal, vecPlane)		
			
	Make_BulletHole(Attacker, flEnd, Damage)
	Make_BulletSmoke(Attacker, Ptr)
	
	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_HANDLED
}

public fw_TraceAttack_Player(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_DKRISS || !Get_BitVar(g_Had_DKriss, Attacker))
		return HAM_IGNORED

	static Float:flEnd[3]
		
	get_tr2(Ptr, TR_vecEndPos, flEnd)
	create_blood(flEnd)
		
	SetHamParamFloat(3, float(DAMAGE))
	
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


public Eject_Shell2(id, ShellID, Right)
{
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	
	pev(id,pev_v_angle, oldangles); pev(id,pev_origin,player_origin); pev(id, pev_view_ofs, viewoffsets);

	engfunc(EngFunc_MakeVectors, oldangles)
	
	global_get(glb_v_forward, v_forward); global_get(glb_v_up, v_up); global_get(glb_v_right, v_right);
	global_get(glb_v_forward, v_forward2); global_get(glb_v_up, v_up2); global_get(glb_v_right, v_right2);
	
	xs_vec_add(player_origin, viewoffsets, gunorigin);
	
	if(!Right)
	{
		xs_vec_mul_scalar(v_forward, 9.0, v_forward); xs_vec_mul_scalar(v_right, -5.0, v_right);
		xs_vec_mul_scalar(v_up, -3.7, v_up);
		xs_vec_mul_scalar(v_forward2, 8.9, v_forward2); xs_vec_mul_scalar(v_right2, -4.9, v_right2);
		xs_vec_mul_scalar(v_up2, -4.0, v_up2);
	} else {
		xs_vec_mul_scalar(v_forward, 9.0, v_forward); xs_vec_mul_scalar(v_right, 5.0, v_right);
		xs_vec_mul_scalar(v_up, -3.7, v_up);
		xs_vec_mul_scalar(v_forward2, 8.9, v_forward2); xs_vec_mul_scalar(v_right2, 4.9, v_right2);
		xs_vec_mul_scalar(v_up2, -4.0, v_up2);
	}
	
	xs_vec_add(gunorigin, v_forward, origin);
	xs_vec_add(gunorigin, v_forward2, origin2);
	xs_vec_add(origin, v_right, origin);
	xs_vec_add(origin2, v_right2, origin2);
	xs_vec_add(origin, v_up, origin);
	xs_vec_add(origin2, v_up2, origin2);

	static Float:velocity[3]
	get_speed_vector(origin2, origin, random_float(140.0, 160.0), velocity)

	static angle; angle = random_num(0, 360)

	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord,origin[1])
	engfunc(EngFunc_WriteCoord,origin[2])
	engfunc(EngFunc_WriteCoord,velocity[0])
	engfunc(EngFunc_WriteCoord,velocity[1])
	engfunc(EngFunc_WriteCoord,velocity[2])
	write_angle(angle)
	write_short(ShellID)
	write_byte(1)
	write_byte(20)
	message_end()
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
