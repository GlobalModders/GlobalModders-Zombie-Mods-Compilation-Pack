#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>

#define PLUGIN "[ZBHeroEx] Addon: Heroine's Gatling"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define CSW_GATLING CSW_M3
#define weapon_gatling "weapon_m3"
#define WEAPON_ANIMEXT "m249"
#define DEFAULT_W_MODEL "models/w_m3.mdl"
#define WEAPON_SECRET_CODE 1942
#define old_event "events/m3.sc"

#define DAMAGE 48
#define SPEED 0.25
#define RECOIL 0.5
#define RELOAD_TIME 4.5
#define DEFAULT_CLIP 40
#define DEFAULT_BPAMMO 200

new const WeaponModel[2][] =
{
	"models/zombie_thehero/weapon/v_gatling.mdl", // V
	"models/zombie_thehero/weapon/p_gatling.mdl" // P
}

new const WeaponSound[7][] =
{
	"weapons/gatling-1.wav",
	"weapons/gatling_boltpull.wav",
	"weapons/gatling_clipin1.wav",
	"weapons/gatling_clipin2.wav",
	"weapons/gatling_clipout1.wav",
	"weapons/gatling_clipout2.wav",
	"weapons/usas_draw.wav"
}

enum
{
	GATLING_ANIM_IDLE = 0,
	GATLING_ANIM_SHOOT1,
	GATLING_ANIM_SHOOT2,
	GATLING_ANIM_RELOAD,
	GATLING_ANIM_DRAW
}

const PDATA_SAFE = 2
const OFFSET_LINUX_WEAPONS = 4
const OFFSET_LINUX_PLAYER = 5
const OFFSET_WEAPONOWNER = 41
const m_iClip = 51
const m_fInReload = 54
const m_flNextAttack = 83
const m_szAnimExtention = 492

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_Had_Gatling, Float:g_punchangles[33][3], g_gatling_event, g_smokepuff_id, m_iBlood[2], g_ham_bot
new g_Msg_CurWeapon, g_Msg_AmmoX

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")		
	
	RegisterHam(Ham_Item_Deploy, weapon_gatling, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_Reload, weapon_gatling, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_gatling, "fw_Item_PostFrame")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gatling, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_gatling, "fw_Weapon_PrimaryAttack_Post", 1)
	
	g_Msg_CurWeapon = get_user_msgid("CurWeapon")
	g_Msg_AmmoX = get_user_msgid("AmmoX")
	
	register_clcmd("dias2_get_gatling", "get_gatling")
}

public plugin_precache()
{
	new i
	
	for(i = 0; i < sizeof(WeaponModel); i++)
		engfunc(EngFunc_PrecacheModel, WeaponModel[i])
	for(i = 0; i < sizeof(WeaponSound); i++)
		engfunc(EngFunc_PrecacheSound, WeaponSound[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = engfunc(EngFunc_PrecacheModel, "sprites/blood.spr")
	m_iBlood[1] = engfunc(EngFunc_PrecacheModel, "sprites/bloodspray.spr")		
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(old_event, name))
		g_gatling_event = get_orig_retval()
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_ham_bot)
	{
		g_ham_bot = 1
		set_task(0.1, "Do_Register_Ham", id)
	}
}

public Do_Register_Ham(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")	
}

public CMD_Drop(id)
{
	if(get_user_weapon(id) == CSW_GATLING && Get_BitVar(g_Had_Gatling, id))
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public zbheroex_user_hero(id, FemaleHero)
{
	if(!FemaleHero) return
	get_gatling(id)
}

public zbheroex_user_infected(id) remove_gatling(id)
public zbheroex_user_died(id) remove_gatling(id)
public zbheroex_user_spawned(id, Zombie)
{
	if(Zombie) return
	remove_gatling(id)
}

public get_gatling(id)
{
	if(!is_user_alive(id))
		return

	Set_BitVar(g_Had_Gatling, id)
	fm_give_item(id, weapon_gatling)
	
	// Set Clip
	static ent; ent = fm_get_user_weapon_entity(id, CSW_GATLING)
	if(pev_valid(ent)) cs_set_weapon_ammo(ent, DEFAULT_CLIP)
	
	// Set BpAmmo
	for(new i = 0; i < 25; i++) give_ammo(id, 0, CSW_GATLING)
	
	// Update Ammo
	update_ammo(id, CSW_GATLING, DEFAULT_CLIP, DEFAULT_BPAMMO)
}

public remove_gatling(id)
{
	UnSet_BitVar(g_Had_Gatling, id)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_GATLING || !Get_BitVar(g_Had_Gatling, id))
		return
		
	// Speed
	static ent; ent = fm_get_user_weapon_entity(id, CSW_GATLING)
	if(!pev_valid(ent)) 
		return
		
	set_pdata_float(ent, 46, get_pdata_float(ent, 46, OFFSET_LINUX_WEAPONS) * SPEED, OFFSET_LINUX_WEAPONS)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_GATLING || !Get_BitVar(g_Had_Gatling, id))
		return 

	static CurButton; CurButton = get_uc(uc_handle, UC_Buttons)

	if(CurButton & IN_RELOAD)
	{
		CurButton &= ~IN_RELOAD
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		static ent; ent = fm_get_user_weapon_entity(id, CSW_GATLING)
		if(!pev_valid(ent)) return
		
		static fInReload; fInReload = get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS)
		static Float:flNextAttack; flNextAttack = get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYER)
		
		if (flNextAttack > 0.0)
			return
			
		if (fInReload)
		{
			set_weapon_anim(id, GATLING_ANIM_IDLE)
			return
		}
		
		if(cs_get_weapon_ammo(ent) >= DEFAULT_CLIP)
		{
			set_weapon_anim(id, GATLING_ANIM_IDLE)
			return
		}
			
		fw_Weapon_Reload_Post(ent)
	}
}

public fw_TraceAttack_World(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_GATLING || !Get_BitVar(g_Had_Gatling, attacker))
		return HAM_IGNORED
		
	static Float:flEnd[3], Float:vecPlane[3]

	get_tr2(ptr, TR_vecEndPos, flEnd)
	get_tr2(ptr, TR_vecPlaneNormal, vecPlane)		
	
	Make_BulletHole(attacker, flEnd, Damage)
	fake_smoke(attacker, ptr)
		
	SetHamParamFloat(3, float(DAMAGE) / random_float(1.5, 2.5))	

	return HAM_HANDLED
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_GATLING || !Get_BitVar(g_Had_Gatling, attacker))
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE) / random_float(1.5, 2.5))	

	return HAM_HANDLED
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_GATLING || !Get_BitVar(g_Had_Gatling, id))
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if(!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(eventid != g_gatling_event)
		return FMRES_IGNORED
		
	if(get_user_weapon(invoker) == CSW_GATLING && Get_BitVar(g_Had_Gatling, invoker))
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		Event_Gatling_Shoot(invoker)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public fw_Item_Deploy_Post(ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(ent)
	if (!pev_valid(id))
		return
	
	static weaponid
	weaponid = cs_get_weapon_id(ent)
	
	if(weaponid != CSW_GATLING)
		return
	if(!Get_BitVar(g_Had_Gatling, id))
		return
		
	set_pev(id, pev_viewmodel2, WeaponModel[0])
	set_pev(id, pev_weaponmodel2, WeaponModel[1])
	
	set_weapon_anim(id, GATLING_ANIM_DRAW)
	set_pdata_string(id, m_szAnimExtention * 4, WEAPON_ANIMEXT, -1 , 20)
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = pev(ent, pev_owner)

	if(Get_BitVar(g_Had_Gatling, id))
	{
		static CurBpAmmo; CurBpAmmo = cs_get_user_bpammo(id, CSW_GATLING)
		
		if(CurBpAmmo  <= 0)
			return HAM_IGNORED

		set_pdata_int(ent, 55, 0, OFFSET_LINUX_WEAPONS)
		set_pdata_float(id, 83, RELOAD_TIME, OFFSET_LINUX_PLAYER)
		set_pdata_float(ent, 48, RELOAD_TIME + 0.5, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, 46, RELOAD_TIME + 0.25, OFFSET_LINUX_WEAPONS)
		set_pdata_float(ent, 47, RELOAD_TIME + 0.25, OFFSET_LINUX_WEAPONS)
		set_pdata_int(ent, m_fInReload, 1, OFFSET_LINUX_WEAPONS)
		
		set_weapon_anim(id, GATLING_ANIM_RELOAD)			
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED	
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!Get_BitVar(g_Had_Gatling, id)) return

	static iBpAmmo ; iBpAmmo = get_pdata_int(id, 381, OFFSET_LINUX_PLAYER)
	static iClip ; iClip = get_pdata_int(ent, m_iClip, OFFSET_LINUX_WEAPONS)
	static iMaxClip ; iMaxClip = DEFAULT_CLIP

	if(get_pdata_int(ent, m_fInReload, OFFSET_LINUX_WEAPONS) && get_pdata_float(id, m_flNextAttack, OFFSET_LINUX_PLAYER) <= 0.0)
	{
		static j; j = min(iMaxClip - iClip, iBpAmmo)
		set_pdata_int(ent, m_iClip, iClip + j, OFFSET_LINUX_WEAPONS)
		set_pdata_int(id, 381, iBpAmmo-j, OFFSET_LINUX_PLAYER)
		
		set_pdata_int(ent, m_fInReload, 0, OFFSET_LINUX_WEAPONS)
		cs_set_weapon_ammo(ent, DEFAULT_CLIP)
	
		update_ammo(id, CSW_GATLING, cs_get_weapon_ammo(ent), cs_get_user_bpammo(id, CSW_GATLING))
	
		return
	}
}

public fw_Weapon_PrimaryAttack(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!Get_BitVar(g_Had_Gatling, id))
		return
		
	pev(id, pev_punchangle, g_punchangles[id])
}

public fw_Weapon_PrimaryAttack_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!Get_BitVar(g_Had_Gatling, id))
		return
		
	static Float:push[3]
	pev(id, pev_punchangle, push)
	xs_vec_sub(push, g_punchangles[id], push)
	
	xs_vec_mul_scalar(push, RECOIL, push)
	xs_vec_add(push, g_punchangles[id], push)
	set_pev(id, pev_punchangle, push)	
}

public update_ammo(id, csw_id, clip, bpammo)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, _, id)
	write_byte(1)
	write_byte(csw_id)
	write_byte(clip)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_AmmoX, _, id)
	write_byte(3)
	write_byte(bpammo)
	message_end()
}

public Event_Gatling_Shoot(id)
{
	set_weapon_anim(id, random_num(GATLING_ANIM_SHOOT1, GATLING_ANIM_SHOOT2))
	emit_sound(id, CHAN_WEAPON, WeaponSound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	if (pev_valid(ent) != PDATA_SAFE)
		return -1
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
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
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
