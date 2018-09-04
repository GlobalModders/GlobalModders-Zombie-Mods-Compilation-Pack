#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Secondary: Balrog-I"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define CSW_BALROG1 CSW_DEAGLE
#define weapon_balrog1 "weapon_deagle"

#define V_MODEL_A "models/zombie_thehero/weapon/sec/v_balrog1_A.mdl"
#define V_MODEL_B "models/zombie_thehero/weapon/sec/v_balrog1_B.mdl"
#define P_MODEL "models/zombie_thehero/weapon/sec/p_balrog1.mdl" // p_deagle.mdl" //
#define W_MODEL "models/zombie_thehero/weapon/sec/w_balrog1.mdl"

#define DAMAGE 41
#define CLIP 10
#define BPAMMO 100
#define RELOAD_TIME 2.3
#define EXP_RADIUS 150.0

#define CHANGETIME_A 2.0
#define CHANGETIME_B 1.3
#define RESETA_TIME 3.0

#define WEAPON_SECRETCODE 47
#define TASK_CHANGING 280200

new const Weapon_Sound[2][] = 
{
	"weapons/balrog1-1.wav",
	"weapons/balrog1-2.wav"
	//"weapons/balrog1_draw.wav",
	//"weapons/balrog1_reload.wav",
	//"weapons/balrog1_reloadb.wav",
	//"weapons/balrog1_changea.wav",
	//"weapons/balrog1_changeb.wav"
}

new const ExpSpr[] = "sprites/balrog5stack.spr"

enum
{
	MODE_A = 1,
	MODE_B
}

enum
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT_EMPTY,
	ANIM_RELOAD,
	ANIM_DRAW,
	ANIM_CHANGE
}

new g_balrog1
new g_had_balrog1[33], g_balrog1_mode[33], g_Balrog1_Clip[33], g_balrog1_changing[33]
new g_Balrog1_Event, g_smokepuff_id, m_iBlood[2], g_old_weapon[33], ExpSprId, g_MaxPlayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CheckWeapon", "be", "1=1")
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")	
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")	
	RegisterHam(Ham_Item_AddToPlayer, weapon_balrog1, "fw_AddToPlayer_Post", 1)
	
	RegisterHam(Ham_Weapon_Reload, weapon_balrog1, "fw_WeaponReload")
	RegisterHam(Ham_Weapon_Reload, weapon_balrog1, "fw_WeaponReload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_balrog1, "fw_Item_PostFrame")		

	g_MaxPlayers = get_maxplayers()
	
	register_clcmd("weapon_balrog1", "hook_weapon")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL_A)
	engfunc(EngFunc_PrecacheModel, V_MODEL_B)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	for(new i = 0; i < sizeof(Weapon_Sound); i++)
		engfunc(EngFunc_PrecacheSound, Weapon_Sound[i])
	
	ExpSprId = engfunc(EngFunc_PrecacheModel, ExpSpr)

	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")		
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	g_balrog1 = zbheroex_register_weapon("Balrog-I", WEAPON_SECONDARY, CSW_BALROG1, 0)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/deagle.sc", name))
		g_Balrog1_Event = get_orig_retval()	
}

public zbheroex_weapon_bought(id, itemid)
{
	if(itemid == g_balrog1) get_balrog1(id)
}

public zbheroex_weapon_remove(id, itemid)
{
	if(itemid == g_balrog1) remove_balrog1(id)
}

public get_balrog1(id)
{
	if(!is_user_alive(id))
		return
	
	g_had_balrog1[id] = 1
	g_balrog1_mode[id] = MODE_A
	
	give_item(id, weapon_balrog1)
	//cs_set_user_bpammo(id, CSW_BALROG1, BPAMMO)
	
	static balrog1; balrog1 = fm_find_ent_by_owner(-1, weapon_balrog1, id)
	if(pev_valid(balrog1)) cs_set_weapon_ammo(balrog1, CLIP)
	
	engclient_cmd(id, weapon_balrog1)
}

public remove_balrog1(id)
{
	g_had_balrog1[id] = 0
	g_balrog1_mode[id] = 0
	g_balrog1_changing[id] = 0
	g_Balrog1_Clip[id] = 0
}

public hook_weapon(id) engclient_cmd(id, weapon_balrog1)

public Event_CheckWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	
	if(read_data(2) == CSW_BALROG1 && g_had_balrog1[id])
	{
		if(g_old_weapon[id] != CSW_BALROG1) // Draw
		{
			if(g_balrog1_mode[id] == MODE_B) g_balrog1_mode[id] = MODE_A
		}
		
		set_pev(id, pev_viewmodel2, g_balrog1_mode[id] == MODE_A ? V_MODEL_A : V_MODEL_B)
		set_pev(id, pev_weaponmodel2, P_MODEL)	
	} else {
		if(read_data(2) != CSW_BALROG1 && g_old_weapon[id] == CSW_BALROG1)
		{
			g_balrog1_changing[id] = 0
			remove_task(id+TASK_CHANGING)
		}
	}
	
	g_old_weapon[id] = read_data(2)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(zbheroex_get_user_zombie(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) == CSW_BALROG1 && g_had_balrog1[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(zbheroex_get_user_zombie(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) != CSW_BALROG1 || !g_had_balrog1[invoker])
		return FMRES_IGNORED
	
	if(eventid == g_Balrog1_Event) 
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		
		static Balrog1; Balrog1 = fm_find_ent_by_owner(-1, weapon_balrog1, invoker)
		if(pev_valid(Balrog1)) Weapon_Shoot(invoker, Balrog1)
	}
	return FMRES_HANDLED
}

public Weapon_Shoot(id, ent)
{
	set_weapon_anim(id, random_num(ANIM_SHOOT1, ANIM_SHOOT2))
	
	if(g_balrog1_mode[id] == MODE_A) emit_sound(id, CHAN_WEAPON, Weapon_Sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
	else emit_sound(id, CHAN_WEAPON, Weapon_Sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static szClassName[64]
	pev(entity, pev_classname, szClassName, sizeof(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED
	
	static iOwner
	iOwner = pev(entity, pev_owner)
	
	if(equal(model, "models/w_deagle.mdl"))
	{
		static weapon
		weapon = fm_find_ent_by_owner(-1, weapon_balrog1, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(g_had_balrog1[iOwner])
		{
			g_had_balrog1[iOwner] = 0
			
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED;
}

public fw_TraceAttack_World(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	if(zbheroex_get_user_zombie(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_BALROG1 || !g_had_balrog1[attacker])
		return HAM_IGNORED
	
	static Float:flEnd[3], Float:vecPlane[3]
	
	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
	
	make_bullet(attacker, flEnd)
	fake_smoke(attacker, ptr)
	
	SetHamParamFloat(3, float(DAMAGE))
	
	if(g_balrog1_mode[attacker] == MODE_B)
	{
		Make_Explosion(attacker, flEnd)
		set_weapon_nextattack(attacker, CSW_BALROG1, RESETA_TIME)
		
		set_task(RESETA_TIME, "ResetA_Complete", attacker+TASK_CHANGING)
	}
	
	return HAM_HANDLED
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker) || !is_user_connected(attacker))
		return HAM_IGNORED	
	if(zbheroex_get_user_zombie(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_BALROG1 || !g_had_balrog1[attacker])
		return HAM_IGNORED
	
	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)	
	
	SetHamParamFloat(3, float(DAMAGE))
	
	if(g_balrog1_mode[attacker] == MODE_B)
	{
		Make_Explosion(attacker, flEnd)
		set_weapon_nextattack(attacker, CSW_BALROG1, RESETA_TIME)
		
		set_task(RESETA_TIME, "ResetA_Complete", attacker+TASK_CHANGING)
	}
	
	return HAM_HANDLED
}

public Make_Explosion(id, Float:ExpOrigin[3])
{
	static TE_FLAG; TE_FLAG = 0
	
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, ExpOrigin[0])
	engfunc(EngFunc_WriteCoord, ExpOrigin[1])
	engfunc(EngFunc_WriteCoord, ExpOrigin[2] + 16.0)
	write_short(ExpSprId)	// sprite index
	write_byte(15)	// scale in 0.1's
	write_byte(20)	// framerate
	write_byte(TE_FLAG)	// flags
	message_end()
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_DLIGHT)
	engfunc(EngFunc_WriteCoord, ExpOrigin[0])
	engfunc(EngFunc_WriteCoord, ExpOrigin[1])
	engfunc(EngFunc_WriteCoord, ExpOrigin[2])
	write_byte(20); // radius
	write_byte(255) // r
	write_byte(25) // g
	write_byte(25) // b
	write_byte(10) // life <<<<<<<<
	write_byte(50) // decay rate
	message_end()	
	
	static Float:Origin[3]
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i) || !zbheroex_get_user_zombie(i))
			continue
		
		pev(i, pev_origin, Origin)
		if(get_distance_f(ExpOrigin, Origin) > EXP_RADIUS)
			continue
		
		ExecuteHamB(Ham_TakeDamage, i, 0, id, DAMAGE * 4.0, DMG_BURN)
	}
	
	/*while((Victim = engfunc(EngFunc_FindEntityInSphere, id, ExpOrigin, EXP_RADIUS)) != 0)
	{
		if(!is_user_alive(Victim) || !zp_get_user_zombie(Victim))
			continue
		
		ExecuteHamB(Ham_TakeDamage, Victim, 0, id, DAMAGE * 4.0, DMG_BLAST)
	}*/
}

public ResetA_Complete(id)
{
	id -= TASK_CHANGING
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_BALROG1 || !g_had_balrog1[id])
		return 
	
	g_balrog1_mode[id] = MODE_A
	set_pev(id, pev_viewmodel2, g_balrog1_mode[id] == MODE_A ? V_MODEL_A : V_MODEL_B)
	set_weapon_anim(id, ANIM_IDLE)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_BALROG1 || !g_had_balrog1[id])
		return 
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if((CurButton & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		set_uc(uc_handle, UC_Buttons, CurButton &= ~IN_ATTACK2)
		
		if(get_pdata_float(id, 83, 5) > 0.0)
			return
		if(g_balrog1_changing[id])
			return
		
		if(g_balrog1_mode[id] == MODE_A)
		{
			g_balrog1_changing[id] = MODE_B
			
			set_weapon_nextattack(id, CSW_BALROG1, CHANGETIME_A)
			set_weapon_anim(id, ANIM_CHANGE)
			
			set_task(CHANGETIME_A, "Balrog1_Changed", id+TASK_CHANGING)
			} else if(g_balrog1_mode[id] == MODE_B) {
			g_balrog1_changing[id] = MODE_A
			
			set_weapon_nextattack(id, CSW_BALROG1, CHANGETIME_B)
			set_weapon_anim(id, ANIM_CHANGE)
			
			set_task(CHANGETIME_B, "Balrog1_Changed", id+TASK_CHANGING)
		}
	}
}

public Balrog1_Changed(id)
{
	id -= TASK_CHANGING
	
	if(!is_user_connected(id))
		return
	
	static Changed_To_Mode; Changed_To_Mode = g_balrog1_changing[id]
	g_balrog1_changing[id] = 0
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(get_user_weapon(id) != CSW_BALROG1 || !g_had_balrog1[id])
	{
		g_balrog1_mode[id] = MODE_A
		return 
	}
	
	g_balrog1_mode[id] = Changed_To_Mode
	set_pev(id, pev_viewmodel2, Changed_To_Mode == MODE_A ? V_MODEL_A : V_MODEL_B)
	set_weapon_anim(id, ANIM_IDLE)
}

public fw_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_balrog1[id] = 1
		g_balrog1_mode[id] = MODE_A
		
		set_pev(ent, pev_impulse, 0)
	}	
	
	return HAM_HANDLED
}

public fw_WeaponReload(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_balrog1[id])
		return HAM_IGNORED
	if(zbheroex_get_user_zombie(id))
		return HAM_IGNORED		
	
	g_Balrog1_Clip[id] = -1
	
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BALROG1)
	if (bpammo <= 0) return HAM_SUPERCEDE
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	if(iClip >= CLIP) return HAM_SUPERCEDE		
	
	g_Balrog1_Clip[id] = iClip
	
	return HAM_IGNORED
}

public fw_WeaponReload_Post(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_balrog1[id])
		return HAM_IGNORED
	if(zbheroex_get_user_zombie(id))
		return HAM_IGNORED		
	if(g_Balrog1_Clip[id] == -1)
		return HAM_IGNORED
	
	set_pdata_float(id, 83, RELOAD_TIME, 5)
	set_pdata_int(ent, 51, g_Balrog1_Clip[id], 4)
	set_pdata_int(ent, 54, 1, 4)
	
	set_weapon_anim(id, ANIM_RELOAD)
	
	return HAM_IGNORED
}

public fw_Item_PostFrame(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !g_had_balrog1[id])
		return HAM_IGNORED
	if(zbheroex_get_user_zombie(id))
		return HAM_IGNORED
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_BALROG1)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp; temp = min(CLIP - iClip, bpammo)
		
		set_pdata_int(ent, 51, iClip + temp, 4)
		cs_set_user_bpammo(id, CSW_BALROG1, bpammo - temp)		
		set_pdata_int(ent, 54, 0, 4)
	}		
	
	return HAM_IGNORED
}

stock set_weapon_anim(id, anim)
{ 
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	static decal; decal = random_num(41, 45)
	const loop_time = 2
	
	for(new i = 0; i < loop_time; i++)
	{
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

stock set_weapon_nextattack(player, weapon_id, Float:NextTime)
{
	if(!is_user_alive(player))
		return
	
	const m_flNextPrimaryAttack = 46
	const m_flNextSecondaryAttack = 47
	const m_flTimeWeaponIdle = 48
	const m_flNextAttack = 83
	
	static weapon
	weapon = fm_get_user_weapon_entity(player, weapon_id)
	
	set_pdata_float(player, m_flNextAttack, NextTime, 5)
	if(pev_valid(weapon))
	{
		set_pdata_float(weapon, m_flNextPrimaryAttack , NextTime, 4)
		set_pdata_float(weapon, m_flNextSecondaryAttack, NextTime, 4)
		set_pdata_float(weapon, m_flTimeWeaponIdle, NextTime, 4)
	}
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
