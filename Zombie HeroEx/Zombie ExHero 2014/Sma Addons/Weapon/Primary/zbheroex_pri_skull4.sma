#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: Skull-4"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define V_MODEL "models/zombie_thehero/weapon/pri/v_skull4.mdl"
#define P_MODEL "models/zombie_thehero/weapon/pri/p_skull4.mdl"
#define W_MODEL "models/zombie_thehero/weapon/pri/w_skull4.mdl"

#define CSW_DI CSW_M4A1
#define weapon_di "weapon_m4a1"

#define ANIM_EXT "dualpistols_1"
#define WEAPON_SECRETCODE 1953

#define WEAPON_EVENT "events/m4a1.sc"
#define OLD_W_MODEL "models/w_m4a1.mdl"

#define DRAW_TIME 0.75
#define RELOAD_TIME 3.4
#define PLAYER_SPEED 200.0

#define DAMAGE 63
#define CLIP 48
#define BPAMMO 200

#define FIRE_SOUND "weapons/skull4-1.wav"
#define BODY_NUM 0

new g_DualInfinity
new g_Had_DualInfinity
new g_OldWeapon[33], g_Clip[33], g_di_event, g_ShellId, g_ham_bot, g_smokepuff_id

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")		
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	
	
	RegisterHam(Ham_Item_PostFrame, weapon_di, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_di, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_di, "fw_Weapon_Reload_Post", 1)		
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_di, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_di, "fw_Item_AddToPlayer_Post", 1)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	engfunc(EngFunc_PrecacheSound, FIRE_SOUND)
	
	g_ShellId = engfunc(EngFunc_PrecacheModel, "models/rshell.mdl")
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	g_DualInfinity = zbheroex_register_weapon("Skull-4", WEAPON_PRIMARY, CSW_DI, 6999)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_di_event = get_orig_retval()		
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
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_DualInfinity) Get_DualInfinity(id)
}

public zbheroex_weapon_remove(id, ItemID)
{
	if(ItemID == g_DualInfinity) Remove_DualInfinity(id)
}

public Get_DualInfinity(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_Had_DualInfinity, id)
	
	fm_give_item(id, weapon_di)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DI)
	if(pev_valid(Ent)) cs_set_weapon_ammo(Ent, CLIP)
	
	//cs_set_user_bpammo(id, CSW_DI, BPAMMO)	
}

public Remove_DualInfinity(id)
{
	UnSet_BitVar(g_Had_DualInfinity, id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSWID; CSWID = read_data(2)
	if(Get_BitVar(g_Had_DualInfinity, id) && (CSWID == CSW_DI && g_OldWeapon[id] != CSW_DI))
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, "")
	
		// Draw Scene
		set_weapon_anim(id, 2)
		
		set_weapon_timeidle(id, CSW_DI, DRAW_TIME)
		set_player_nextattack(id, DRAW_TIME)
		
		// Set Ext Anim
		set_pdata_string(id, (492) * 4, ANIM_EXT, -1 , 20)
		Draw_NewWeapon(id, CSWID)
		
		set_pev(id, pev_maxspeed, PLAYER_SPEED)
	}  else if((CSWID == CSW_DI && g_OldWeapon[id] == CSW_DI) && Get_BitVar(g_Had_DualInfinity, id)) {
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_DI)
		if(!pev_valid(Ent))
		{
			g_OldWeapon[id] = get_user_weapon(id)
			return
		}
		
		set_pdata_float(Ent, 46, get_pdata_float(Ent, 46, 4) * 2.5, 4)
	}  else if(CSWID != CSW_DI && g_OldWeapon[id] == CSW_DI) Draw_NewWeapon(id, CSWID)
	
	g_OldWeapon[id] = CSWID
}

public Draw_NewWeapon(id, CSW_ID)
{
	if(CSW_ID == CSW_DI)
	{
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_DI)
		
		if(pev_valid(ent) && Get_BitVar(g_Had_DualInfinity, id))
		{
			set_pev(ent, pev_effects, pev(ent, pev_effects) &~ EF_NODRAW) 
			engfunc(EngFunc_SetModel, ent, P_MODEL)	
			set_pev(ent, pev_body, BODY_NUM)
		}
	} else {
		static ent
		ent = fm_get_user_weapon_entity(id, CSW_DI)
		
		if(pev_valid(ent)) set_pev(ent, pev_effects, pev(ent, pev_effects) | EF_NODRAW) 			
	}
	
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_DI && Get_BitVar(g_Had_DualInfinity, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_DI || !Get_BitVar(g_Had_DualInfinity, invoker))
		return FMRES_IGNORED
	
	if(eventid == g_di_event)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		Weapon_Attack(invoker)
		
		return FMRES_SUPERCEDE
	} 
	
	return FMRES_HANDLED
}

public Weapon_Attack(id)
{
	static iFlags, iAnimDesired, iWeaponState, iItem, szAnimation[64]
	
	#define WEAPONSTATE_ELITE_LEFT (1 << 3)
	
	iItem = fm_get_user_weapon_entity(id, CSW_DI)
	if(!pev_valid(iItem)) return
	
	iFlags = pev(id, pev_flags);
	iWeaponState = get_pdata_int(iItem, 74, 4)
	
	if(iWeaponState & WEAPONSTATE_ELITE_LEFT)
	{	
		iWeaponState &= ~ WEAPONSTATE_ELITE_LEFT;
		
		set_weapon_anim(id, 3)
		make_shell(id, 0)
		
		formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot_%s" : "ref_shoot_%s", ANIM_EXT);
	} else {
		iWeaponState |= WEAPONSTATE_ELITE_LEFT;
		
		set_weapon_anim(id, random_num(4, 5))
		make_shell(id, 1)
		
		formatex(szAnimation, charsmax(szAnimation), iFlags & FL_DUCKING ? "crouch_shoot2_%s" : "ref_shoot2_%s", ANIM_EXT);
	}
	
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0;
	
	set_pev(id, pev_sequence, iAnimDesired)
	set_pdata_int(iItem, 74, iWeaponState, 4)
	
	emit_sound(id, CHAN_WEAPON, FIRE_SOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[32]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, OLD_W_MODEL))
	{
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_di, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_DualInfinity, iOwner))
		{
			UnSet_BitVar(g_Had_DualInfinity, iOwner)
		
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			set_pev(entity, pev_body, BODY_NUM)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) != CSW_DI || !Get_BitVar(g_Had_DualInfinity, id))	
		return FMRES_IGNORED
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	if(NewButton & IN_ATTACK2)
	{
		NewButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, NewButton)
	}
	
	return FMRES_IGNORED
}

public fw_TraceAttack_World(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_DI || !Get_BitVar(g_Had_DualInfinity, attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
		
	make_bullet(attacker, flEnd)
	fake_smoke(attacker, ptr)
		
	SetHamParamFloat(3, float(DAMAGE))	

	return HAM_HANDLED
}

public fw_TraceAttack_Player(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_DI || !Get_BitVar(g_Had_DualInfinity, attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE))

	return HAM_HANDLED
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_DualInfinity, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_DI)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_DI, bpammo - temp1)		
		
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
	if(!Get_BitVar(g_Had_DualInfinity, id))
		return HAM_IGNORED

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_DI)
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
	if(!Get_BitVar(g_Had_DualInfinity, id))
		return HAM_IGNORED
		
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if(g_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_Clip[id], 4)
		
		set_weapon_anim(id, 1)
		
		set_weapon_timeidle(id, CSW_DI, RELOAD_TIME)
		set_player_nextattack(id, RELOAD_TIME)
	}
	
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_DualInfinity, id))
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 48, 4) <= 0.1) 
	{
		set_weapon_anim(id, 0)
		set_pdata_float(ent, 48, 20.0, 4)
	}
	
	return HAM_IGNORED
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_DualInfinity, id)
		set_pev(ent, pev_impulse, 0)
	}		

	return HAM_HANDLED	
}

public make_shell(id, Right)
{
	static Float:player_origin[3], Float:origin[3], Float:origin2[3], Float:gunorigin[3], Float:oldangles[3], Float:v_forward[3], Float:v_forward2[3], Float:v_up[3], Float:v_up2[3], Float:v_right[3], Float:v_right2[3], Float:viewoffsets[3];
	
	pev(id,pev_v_angle, oldangles); pev(id,pev_origin,player_origin); pev(id, pev_view_ofs, viewoffsets);

	engfunc(EngFunc_MakeVectors, oldangles)
	
	global_get(glb_v_forward, v_forward); global_get(glb_v_up, v_up); global_get(glb_v_right, v_right);
	global_get(glb_v_forward, v_forward2); global_get(glb_v_up, v_up2); global_get(glb_v_right, v_right2);
	
	xs_vec_add(player_origin, viewoffsets, gunorigin);
	
	if(!Right)
	{
		xs_vec_mul_scalar(v_forward, 10.3, v_forward); xs_vec_mul_scalar(v_right, 2.9, v_right);
		xs_vec_mul_scalar(v_up, -3.7, v_up);
		xs_vec_mul_scalar(v_forward2, 10.0, v_forward2); xs_vec_mul_scalar(v_right2, 3.0, v_right2);
		xs_vec_mul_scalar(v_up2, -4.0, v_up2);
	} else {
		xs_vec_mul_scalar(v_forward, 10.3, v_forward); xs_vec_mul_scalar(v_right, 2.9, v_right);
		xs_vec_mul_scalar(v_up, -3.7, v_up);
		xs_vec_mul_scalar(v_forward2, 10.0, v_forward2); xs_vec_mul_scalar(v_right2, -3.0, v_right2);
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
	write_short(g_ShellId)
	write_byte(1)
	write_byte(20)
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	static decal; decal = random_num(41, 45)

	// Put decal on "world" (a wall)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_WORLDDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(decal)
	message_end()
	
	// Show sparcles
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_GUNSHOTDECAL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(id)
	write_byte(decal)
	message_end()
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

stock get_speed_vector(const Float:origin1[3],const Float:origin2[3],Float:speed, Float:new_velocity[3])
{
	new_velocity[0] = origin2[0] - origin1[0]
	new_velocity[1] = origin2[1] - origin1[1]
	new_velocity[2] = origin2[2] - origin1[2]
	static Float:num; num = floatsqroot(speed*speed / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
	new_velocity[0] *= num
	new_velocity[1] *= num
	new_velocity[2] *= num
	
	return 1;
}

stock set_weapon_timeidle(id, CSWID, Float:TimeIdle)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSWID)
	if(!pev_valid(Ent)) 
		return
	
	set_pdata_float(Ent, 46, TimeIdle, 4)
	set_pdata_float(Ent, 47, TimeIdle, 4)
	set_pdata_float(Ent, 48, TimeIdle + 1.0, 4)
}

stock set_player_nextattack(id, Float:Time) set_pdata_float(id, 83, Time, 5)
stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
