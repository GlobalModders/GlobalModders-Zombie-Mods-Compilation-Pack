#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "M134 Vulcan"
#define VERSION "1.0"
#define AUTHOR "Dias Leon"

#define MODEL_V "models/zombie_evolution/swpn/v_m134hero.mdl"
#define MODEL_P "models/zombie_evolution/swpn/p_m134hero.mdl"

#define MUZZLEFLASH "sprites/muzzleflash6_2.spr"
#define MUZZLEFLASH2 "sprites/muzzleflash7_2.spr"

#define DAMAGE 60
#define CLIP 100
#define BPAMMO 200

#define SPEED_A 0.04
#define SPEED_B 0.02
#define TIME_RELOAD 5.0

#define CSW_M134V CSW_M249
#define weapon_m134v "weapon_m249"
#define WEAPON_ANIMEXT "m134"

new const WeaponSounds[4][] =
{
	"weapons/m134ex-1.wav",
	//"weapons/m134_clipoff.wav",
	//"weapons/m134_clipon.wav",
	//"weapons/m134ex_spin.wav",
	//"weapons/m134hero_draw.wav",
	//"weapons/m134hero_fire_after_overheat.wav",
	//"weapons/m134hero_overheat_end.wav",
	//"weapons/m134hero_overload.wav",
	"weapons/m134hero_spindown.wav",
	"weapons/m134hero_spinup.wav",
	"weapons/steam.wav"
}

/*
new const WeaponResources[3][] = 
{
	"sprites/weapon_m134hero.txt",
	"sprites/640hud128_2.spr",
	"sprites/640hud7_2.spr"
}*/

new const Steam[] = "sprites/m134hero_steam.spr"
new const Shell1[] = "models/shell_m1.mdl"
new const Shell2[] = "models/shell_m2.mdl"

enum
{
	ANIME_IDLE = 0,
	ANIME_DRAW,
	ANIME_RELOAD,
	ANIME_FIRE_START,
	ANIME_FIRE_LOOP,
	ANIME_FIRE_END,
	ANIME_NANI1,
	ANIME_NANI2,
	ANIME_OH_DRAW,
	ANIME_OH_START,
	ANIME_OH_IDLE,
	ANIME_OH_END,
	ANIME_SFIRE_START,
	ANIME_SFIRE_LOOP,
	ANIME_SFIRE_END
}

enum
{
	M134_ATTACK_NOT = 0,
	M134_ATTACK_BEGIN,
	M134_ATTACK_LOOP,
	M134_ATTACK_END
}

#define TASK_ATTACK 1972
#define TASK_OVERHEAT 1973

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Vars
new g_M134V
new g_Had_M134V, g_Clip[33], g_M134State[33], Float:g_SpeedControl[33], Float:g_AttackDelay[33], g_RapidMode
new g_Event_M134V, g_SmokePuff_SprId, m_iBlood[2], g_OverHeat, g_Fired, g_ShellID1, g_ShellID2
new g_MsgWeaponList, g_MsgCurWeapon, g_SteamID, Float:SteamTime[33], FiringTime[33], g_InTempingAttack
new g_MsgScreenShake

new g_Muzzleflash_Ent, g_Muzzleflash
new g_Muzzleflash_Ent2, g_Muzzleflash2

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33], g_HamBot

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Safety
	Register_SafetyFunc()
	//register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	// Forward
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")

	register_forward(FM_AddToFullPack, "fw_AddToFullPack_post", 1)
	register_forward(FM_CheckVisibility, "fw_CheckVisibility")
	
	// Ham
	RegisterHam(Ham_Item_Deploy, weapon_m134v, "fw_Item_Deploy_Post", 1)	
	RegisterHam(Ham_Item_AddToPlayer, weapon_m134v, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_m134v, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_m134v, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_m134v, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_m134v, "fw_Weapon_Reload_Post", 1)	
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m134v, "fw_Weapon_PrimaryAttack")
	RegisterHam(Ham_Weapon_PrimaryAttack, weapon_m134v, "fw_Weapon_PrimaryAttack_Post", 1)
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack_World")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Player")	

	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgWeaponList = get_user_msgid("WeaponList")
	g_MsgScreenShake = get_user_msgid("ScreenShake")
	
	g_M134V = zbheroex_register_specialweapon("M134 Vulcan", HUMAN_HERO)
	register_clcmd("weapon_m134hero", "Hook_Weapon")
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

	g_SteamID = precache_model(Steam)
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
	g_SmokePuff_SprId = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	
	g_ShellID1 = precache_model(Shell1)
	g_ShellID2 = precache_model(Shell2)
	
	// Muzzleflash 1
	g_Muzzleflash_Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	precache_model(MUZZLEFLASH)
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent, MUZZLEFLASH)
	set_pev(g_Muzzleflash_Ent, pev_scale, 0.2)
	
	set_pev(g_Muzzleflash_Ent, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent, pev_renderamt, 0.0)
	
	// Muzzleflash 2
	g_Muzzleflash_Ent2 = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	precache_model(MUZZLEFLASH2)
	engfunc(EngFunc_SetModel, g_Muzzleflash_Ent2, MUZZLEFLASH2)
	set_pev(g_Muzzleflash_Ent2, pev_scale, 0.2)
	
	set_pev(g_Muzzleflash_Ent2, pev_rendermode, kRenderTransTexture)
	set_pev(g_Muzzleflash_Ent2, pev_renderamt, 0.0)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal("events/m249.sc", name)) g_Event_M134V = get_orig_retval()		
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
	//RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Player")	
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
}

public zbheroex_specialweapon(id, Type, ItemID)
{
	if(ItemID == g_M134V) Get_M134V(id)
}

public zbheroex_specialweapon_refill(id,  ItemID)
{
	if(ItemID == g_M134V) 
	{
		cs_set_user_bpammo(id, CSW_M134V, BPAMMO)
	}
}

public zbheroex_specialweapon_remove(id, ItemID)
{
	if(ItemID == g_M134V) Remove_M134V(id)
}

public Get_M134V(id)
{
	remove_task(id+TASK_OVERHEAT)
	
	UnSet_BitVar(g_InTempingAttack, id)
	UnSet_BitVar(g_Fired, id)
	UnSet_BitVar(g_OverHeat, id)
	UnSet_BitVar(g_RapidMode, id)
	g_M134State[id] = M134_ATTACK_NOT
	FiringTime[id] = 0
	
	Set_BitVar(g_Had_M134V, id)
	give_item(id, weapon_m134v)
	
	// Clip & Ammo
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M134V)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_M134V, BPAMMO)
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgCurWeapon, _, id)
	write_byte(1)
	write_byte(CSW_M134V)
	write_byte(CLIP)
	message_end()
}

public Remove_M134V(id)
{
	UnSet_BitVar(g_InTempingAttack, id)
	UnSet_BitVar(g_Had_M134V, id)
	UnSet_BitVar(g_OverHeat, id)
	UnSet_BitVar(g_RapidMode, id)
	
	remove_task(id+TASK_OVERHEAT)
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_m134v)
	return PLUGIN_HANDLED
}

public fw_AddToFullPack_post(esState, iE, iEnt, iHost, iHostFlags, iPlayer, pSet)
{
	if(iEnt == g_Muzzleflash_Ent)
	{
		if(Get_BitVar(g_Muzzleflash, iHost))
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
				
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			UnSet_BitVar(g_Muzzleflash, iHost)
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	} if(iEnt == g_Muzzleflash_Ent2) {
		if(Get_BitVar(g_Muzzleflash2, iHost))
		{
			set_es(esState, ES_Frame, float(random_num(0, 2)))
				
			set_es(esState, ES_RenderMode, kRenderTransAdd)
			set_es(esState, ES_RenderAmt, 255.0)
			
			UnSet_BitVar(g_Muzzleflash2, iHost)
		}
			
		set_es(esState, ES_Skin, iHost)
		set_es(esState, ES_Body, 1)
		set_es(esState, ES_AimEnt, iHost)
		set_es(esState, ES_MoveType, MOVETYPE_FOLLOW)
	}
}

public fw_CheckVisibility(iEntity, pSet)
{
	if(iEntity == g_Muzzleflash_Ent)
	{
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	} else if(iEntity == g_Muzzleflash_Ent2) {
		forward_return(FMV_CELL, 1)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}


public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_connected(id))
		return FMRES_IGNORED
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
			return FMRES_SUPERCEDE
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't')
		{
			if (sample[17] == 'w')  return FMRES_SUPERCEDE
			else  return FMRES_SUPERCEDE
		}
		if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
			return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(!Get_BitVar(g_InTempingAttack, id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	xs_vec_mul_scalar(v_forward, 0.0, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) == CSW_M134V && Get_BitVar(g_Had_M134V, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_connected(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_M134V || !Get_BitVar(g_Had_M134V, invoker))
		return FMRES_IGNORED
		
	if(eventid == g_Event_M134V)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		//Set_WeaponAnim(invoker, ANIME_FIRE_LOOP)
		//emit_sound(invoker, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.4, 0, 94 + random_num(0, 15))

		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_M134V || !Get_BitVar(g_Had_M134V, id))
		return
	
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M134V)
	
	if(!pev_valid(Ent))
		return
		
	if(NewButton & IN_ATTACK)
	{
		NewButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, NewButton)

		if(get_pdata_float(id, 83, 5) > 0.0) 
			return
		if(Get_BitVar(g_OverHeat, id))
			return
		if(cs_get_weapon_ammo(Ent) <= 0)
		{
			if(get_pdata_int(Ent, 54))
				return
		
			set_pdata_int(Ent, 54, 1, 4)
			ExecuteHamB(Ham_Weapon_Reload, Ent)
			
			return
		}
		
		if(g_M134State[id] == M134_ATTACK_NOT)
		{
			g_M134State[id] = M134_ATTACK_BEGIN
			
			FiringTime[id] = 0
			UnSet_BitVar(g_Fired, id)
			UnSet_BitVar(g_RapidMode, id)
		} else if(g_M134State[id] == M134_ATTACK_BEGIN) {
			if(pev(id, pev_weaponanim) != ANIME_FIRE_END) Set_WeaponAnim(id, ANIME_FIRE_START)

			emit_sound(Ent, CHAN_WEAPON, WeaponSounds[2], 1.0, 0.52, 0, 94 + random_num(0, 15))
			
			Set_WeaponIdleTime(id, CSW_M134V, 0.2)
			Set_PlayerNextAttack(id, 0.2)
			
			if(!task_exists(id+TASK_ATTACK)) set_task(0.15, "Task_ChangeState_Loop", id+TASK_ATTACK)
		} else if(g_M134State[id] == M134_ATTACK_LOOP) {
			if(cs_get_weapon_ammo(Ent) > 0)
			{
				if(!Get_BitVar(g_RapidMode, id)) Set_WeaponAnim(id, ANIME_FIRE_LOOP)
				else Set_WeaponAnim(id, ANIME_SFIRE_LOOP)
				
				ScreenShake(id)
				
				Set_WeaponIdleTime(id, CSW_M134V, 0.5)
				Set_PlayerNextAttack(id, 0.5)
			} else {
				g_M134State[id] = M134_ATTACK_END
				Set_WeaponAnim(id, ANIME_FIRE_END)
				
				emit_sound(Ent, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.52, 0, 94 + random_num(0, 15))
				
				Set_WeaponIdleTime(id, CSW_M134V, 2.0)
				Set_PlayerNextAttack(id, 0.25)
				
				remove_task(id+TASK_ATTACK)
				g_M134State[id] = M134_ATTACK_NOT	
			}
		}
	} else if(NewButton & IN_ATTACK2) {
		NewButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, NewButton)

		if(get_pdata_float(id, 83, 5) > 0.0) 
			return
		if(Get_BitVar(g_OverHeat, id))
			return
		if(cs_get_weapon_ammo(Ent) <= 0)
		{
			if(get_pdata_int(Ent, 54))
				return
		
			set_pdata_int(Ent, 54, 1, 4)
			ExecuteHamB(Ham_Weapon_Reload, Ent)
			
			return
		}
		
		if(g_M134State[id] == M134_ATTACK_NOT)
		{
			Set_BitVar(g_RapidMode, id)
			
			FiringTime[id] = 0
			UnSet_BitVar(g_Fired, id)
			g_M134State[id] = M134_ATTACK_BEGIN
		} else if(g_M134State[id] == M134_ATTACK_BEGIN) {
			if(pev(id, pev_weaponanim) != ANIME_FIRE_END) Set_WeaponAnim(id, ANIME_SFIRE_START)

			emit_sound(Ent, CHAN_WEAPON, WeaponSounds[2], 1.0, 0.52, 0, 94 + random_num(0, 15))
			
			ScreenShake(id)
			
			Set_WeaponIdleTime(id, CSW_M134V, 0.2)
			Set_PlayerNextAttack(id, 0.2)
			
			if(!task_exists(id+TASK_ATTACK)) set_task(0.15, "Task_ChangeState_Loop", id+TASK_ATTACK)
		} else if(g_M134State[id] == M134_ATTACK_LOOP) {
			if(cs_get_weapon_ammo(Ent) > 0)
			{
				if(!Get_BitVar(g_RapidMode, id)) Set_WeaponAnim(id, ANIME_FIRE_LOOP)
				else Set_WeaponAnim(id, ANIME_SFIRE_LOOP)
				
				Set_WeaponIdleTime(id, CSW_M134V, 0.5)
				Set_PlayerNextAttack(id, 0.5)
			} else {
				g_M134State[id] = M134_ATTACK_END
				emit_sound(Ent, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.52, 0, 94 + random_num(0, 15))
				
				Overheat_Begin(id)
				
				remove_task(id+TASK_ATTACK)
				g_M134State[id] = M134_ATTACK_NOT	
			}
		}
	} else {
		if(g_M134State[id] == M134_ATTACK_LOOP) 
		{
			g_M134State[id] = M134_ATTACK_END
			
			emit_sound(Ent, CHAN_WEAPON, WeaponSounds[1], 1.0, 0.52, 0, 94 + random_num(0, 15))
			
			Set_WeaponIdleTime(id, CSW_M134V, 2.0)
			if(cs_get_weapon_ammo(Ent) > 0) Set_PlayerNextAttack(id, 0.25)
			
			if(!Get_BitVar(g_RapidMode, id)) Set_WeaponAnim(id, ANIME_FIRE_END)
			else Overheat_Begin(id)
			
			remove_task(id+TASK_ATTACK)
			g_M134State[id] = M134_ATTACK_NOT
		}
	}
	
	if(NewButton & IN_RELOAD)
	{
		if(get_pdata_int(Ent, 54))
			return
		if(Get_BitVar(g_OverHeat, id))
			return
		if(cs_get_weapon_ammo(Ent) >= CLIP)
			return
		if(get_pdata_float(id, 83, 5) > 0.0 || get_pdata_float(Ent, 46, 4) > 0.0 || get_pdata_float(Ent, 47, 4) > 0.0) 
			return
			
		set_pdata_int(Ent, 54, 1, 4)
		ExecuteHamB(Ham_Weapon_Reload, Ent)
	}
}

public ScreenShake(id)
{
	// Shake
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenShake, {0,0,0},id)
	write_short((1<<12) * 10)
	write_short((1<<12) * 2)
	write_short((1<<12) * 10)
	message_end()
}

public Overheat_Begin(id)
{
	if(Get_BitVar(g_Fired, id))
	{
		if(FiringTime[id] > 0)
		{
			Set_BitVar(g_OverHeat, id)
			
			SteamTime[id] = get_gametime() + 1.0
			
			Set_WeaponIdleTime(id, CSW_M134V, 2.0 + 1.0)
			Set_PlayerNextAttack(id, float(FiringTime[id]) + 1.0)
			
			Set_WeaponAnim(id, ANIME_OH_START)
			
			remove_task(id+TASK_OVERHEAT)
			set_task(float(FiringTime[id]) + 1.0, "Overheat_End", id+TASK_OVERHEAT)
		} else {
			Set_WeaponIdleTime(id, CSW_M134V, 2.0)
			Set_PlayerNextAttack(id, 0.25)
			
			Set_WeaponAnim(id, ANIME_SFIRE_END)
		}
	} else {
		Set_WeaponIdleTime(id, CSW_M134V, 2.0)
		Set_PlayerNextAttack(id, 0.25)
		
		Set_WeaponAnim(id, ANIME_SFIRE_END)
	}
}

public Overheat_End(id)
{
	id -= TASK_OVERHEAT
	
	if(!is_alive(id))
		return
		
	UnSet_BitVar(g_OverHeat, id)
	
	if(get_player_weapon(id) != CSW_M134V || !Get_BitVar(g_Had_M134V, id))
		return
		
	Set_WeaponAnim(id, ANIME_OH_END)

	Set_WeaponIdleTime(id, CSW_M134V, 2.0)
	Set_PlayerNextAttack(id, 2.0)
}

public client_PostThink(id)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_M134V || !Get_BitVar(g_Had_M134V, id))
		return
	if(Get_BitVar(g_OverHeat, id))
	{
		if(get_gametime() - 1.0 > SteamTime[id])
		{
			static Float:Origin[3]
			get_position(id, 20.0, 0.0, 0.0, Origin)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_SPRITE)
			write_coord_f(Origin[0])
			write_coord_f(Origin[1])
			write_coord_f(Origin[2])
			write_short(g_SteamID)
			write_byte(1)
			write_byte(250)
			message_end()
			
			emit_sound(id, CHAN_WEAPON, WeaponSounds[3], 1.0, 0.52, 0, 94 + random_num(0, 15))
			
			SteamTime[id] = get_gametime()
		}
	}
	if(g_M134State[id] != M134_ATTACK_LOOP)
		return	
		
	static Float:DerSpeed; DerSpeed = Get_BitVar(g_RapidMode, id) ? SPEED_B : SPEED_A
	
	if(get_gametime() - DerSpeed > g_SpeedControl[id])
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M134V)
		if(!pev_valid(Ent)) return

		if(cs_get_weapon_ammo(Ent) > 0)
		{
			Set_BitVar(g_Fired, id)
			
			// Shake Screen
			static Float:PunchAngles[3]
			PunchAngles[0] = random_float(-1.5, 1.5)
			PunchAngles[1] = random_float(-1.5, 1.5)
			
			set_pev(id, pev_punchangle, PunchAngles)
			
			Set_BitVar(g_Muzzleflash, id)
			Set_BitVar(g_Muzzleflash2, id)
			
			Create_Vodan(id)
			emit_sound(Ent, CHAN_WEAPON, WeaponSounds[0], 1.0, 0.52, 0, 94 + random_num(0, 15))
			
			static Float:Origin[3], Float:Target[3]
			pev(id, pev_origin, Origin); Origin[2] += 16.0
			get_position(id, 4096.0, 0.0, 0.0, Target)
			
			if(get_gametime() - 1.0 > SteamTime[id])
			{
				FiringTime[id]++
				SteamTime[id] = get_gametime()
			}
			
			Create_FakeAttack(id)
			
			static Trace; Trace = create_tr2()
			engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, Trace)
			static Hit; Hit = get_tr2(Trace, TR_pHit)
			
			if(is_alive(Hit))
			{
				do_attack(id, Hit, 0, float(DAMAGE))
			} else {
				static ptr; ptr = create_tr2() 
				engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, ptr)

				static Float:EndPos[3]
				get_tr2(ptr, TR_vecEndPos, EndPos)
				
				make_bullet(id, EndPos)
				fake_smoke(id, ptr)
				
				free_tr2(ptr)
			}
			
			free_tr2(Trace)
		} else {
			g_M134State[id] = M134_ATTACK_END
			if(!Get_BitVar(g_RapidMode, id)) Set_WeaponAnim(id, ANIME_FIRE_END)
			else Set_WeaponAnim(id, ANIME_SFIRE_END)
			
			Set_WeaponIdleTime(id, CSW_M134V, 2.0)
			Set_PlayerNextAttack(id, 0.25)
			
			remove_task(id+TASK_ATTACK)
			g_M134State[id] = M134_ATTACK_NOT
		}
		
		g_SpeedControl[id] = get_gametime()
	}
	
	static Float:DerTime; DerTime = Get_BitVar(g_RapidMode, id) ? 0.1 : 0.25
	if(get_gametime() -  DerTime > g_AttackDelay[id])
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_M134V)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0) 
		{
			cs_set_weapon_ammo(Ent, cs_get_weapon_ammo(Ent) - 1)
			if(cs_get_weapon_ammo(Ent) <= 0 && Get_BitVar(g_RapidMode, id))
				set_task(0.1, "Overheat_Begin", id)
		}
		
		g_AttackDelay[id] = get_gametime()
	}
}

public Create_Vodan(id)
{
	Eject_Shell2(id, g_ShellID1, 0)
	Eject_Shell2(id, g_ShellID2, 1)
}

public Task_ChangeState_Loop(id)
{
	id -= TASK_ATTACK
	
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_M134V || !Get_BitVar(g_Had_M134V, id))
		return
	if(g_M134State[id] != M134_ATTACK_BEGIN)
		return
		
	g_M134State[id] = M134_ATTACK_LOOP
}

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_M134V, Id))
		return
	
	set_pev(Id, pev_viewmodel2, MODEL_V)
	set_pev(Id, pev_weaponmodel2, MODEL_P)

	if(!Get_BitVar(g_OverHeat, Id)) Set_WeaponAnim(Id, ANIME_DRAW)
	else Set_WeaponAnim(Id, ANIME_OH_DRAW)
	
	set_pdata_string(Id, (492) * 4, WEAPON_ANIMEXT, -1 , 20)
}

public fw_Item_AddToPlayer_Post(Ent, id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
		
	if(pev(Ent, pev_impulse) == 2172015)
	{
		Set_BitVar(g_Had_M134V, id)
		set_pev(Ent, pev_impulse, 0)
	}
	
	/*
	if(Get_BitVar(g_Had_M134V, id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgWeaponList, _, id)
		write_string("weapon_m134hero")
		write_byte(3)
		write_byte(200)
		write_byte(-1)
		write_byte(-1)
		write_byte(0)
		write_byte(4)
		write_byte(CSW_M134V)
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
	if(!Get_BitVar(g_Had_M134V, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_M134V)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_M134V, bpammo - temp1)		
		
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
	if(!Get_BitVar(g_Had_M134V, id))
		return HAM_IGNORED	
	if(Get_BitVar(g_OverHeat, id))
		return HAM_SUPERCEDE

	g_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_M134V)
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
	if(!Get_BitVar(g_Had_M134V, id))
		return HAM_IGNORED	
	if(Get_BitVar(g_OverHeat, id))
		return HAM_SUPERCEDE
	
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
	if(!Get_BitVar(g_Had_M134V, Id))
		return
		
	if(get_pdata_float(iEnt, 48, 4) <= 0.25)
	{
		if(!Get_BitVar(g_OverHeat, Id)) Set_WeaponAnim(Id, ANIME_IDLE)
		else Set_WeaponAnim(Id, ANIME_OH_IDLE)
		set_pdata_float(iEnt, 48, 20.0, 4)
	}	
}

public fw_Weapon_PrimaryAttack(Ent)
{
	/*
	static id; id = pev(Ent, pev_owner)
	pev(id, pev_punchangle, g_Recoil[id])
	
	return HAM_IGNORED*/
}

public fw_Weapon_PrimaryAttack_Post(Ent)
{
	/*
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
	}*/
}

public fw_TraceAttack_World(Victim, Attacker, Float:Damage, Float:Direction[3], Ptr, DamageBits)
{
	if(!is_connected(Attacker))
		return HAM_IGNORED	
	if(get_player_weapon(Attacker) != CSW_M134V || !Get_BitVar(g_Had_M134V, Attacker))
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
	if(get_player_weapon(Attacker) != CSW_M134V || !Get_BitVar(g_Had_M134V, Attacker))
		return HAM_IGNORED

	SetHamParamFloat(3, float(DAMAGE))
	
	return HAM_HANDLED
}

public Create_FakeAttack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_InTempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)
	
	// Set Real Attack Anim
	static iAnimDesired,  szAnimation[64]

	formatex(szAnimation, charsmax(szAnimation), (pev(id, pev_flags) & FL_DUCKING) ? "crouch_shoot_%s" : "ref_shoot_%s", WEAPON_ANIMEXT)
	if((iAnimDesired = lookup_sequence(id, szAnimation)) == -1)
		iAnimDesired = 0
	
	set_pev(id, pev_sequence, iAnimDesired)
	UnSet_BitVar(g_InTempingAttack, id)
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

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	free_tr2(ptr)
	return floatround(get_distance_f(end, EndPos))
} 

do_attack(Attacker, Victim, Inflictor, Float:fDamage)
{
	fake_player_trace_attack(Attacker, Victim, fDamage)
	fake_take_damage(Attacker, Victim, fDamage, Inflictor)
}

fake_player_trace_attack(iAttacker, iVictim, &Float:fDamage)
{
	// get fDirection
	static Float:fAngles[3], Float:fDirection[3]
	pev(iAttacker, pev_angles, fAngles)
	angle_vector(fAngles, ANGLEVECTOR_FORWARD, fDirection)
	
	// get fStart
	static Float:fStart[3], Float:fViewOfs[3]
	pev(iAttacker, pev_origin, fStart)
	pev(iAttacker, pev_view_ofs, fViewOfs)
	xs_vec_add(fViewOfs, fStart, fStart)
	
	// get aimOrigin
	static iAimOrigin[3], Float:fAimOrigin[3]
	get_user_origin(iAttacker, iAimOrigin, 3)
	IVecFVec(iAimOrigin, fAimOrigin)
	
	// TraceLine from fStart to AimOrigin
	static ptr; ptr = create_tr2() 
	engfunc(EngFunc_TraceLine, fStart, fAimOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr)
	static pHit; pHit = get_tr2(ptr, TR_pHit)
	static iHitgroup; iHitgroup = get_tr2(ptr, TR_iHitgroup)
	static Float:fEndPos[3]; get_tr2(ptr, TR_vecEndPos, fEndPos)

	// get target & body at aiming
	static iTarget, iBody
	get_user_aiming(iAttacker, iTarget, iBody)
	
	// if aiming find target is iVictim then update iHitgroup
	if (iTarget == iVictim)
	{
		iHitgroup = iBody
	}
	
	// if ptr find target not is iVictim
	else if (pHit != iVictim)
	{
		// get AimOrigin in iVictim
		static Float:fVicOrigin[3], Float:fVicViewOfs[3], Float:fAimInVictim[3]
		pev(iVictim, pev_origin, fVicOrigin)
		pev(iVictim, pev_view_ofs, fVicViewOfs) 
		xs_vec_add(fVicViewOfs, fVicOrigin, fAimInVictim)
		fAimInVictim[2] = fStart[2]
		fAimInVictim[2] += get_distance_f(fStart, fAimInVictim) * floattan( fAngles[0] * 2.0, degrees )
		
		// check aim in size of iVictim
		static iAngleToVictim; iAngleToVictim = get_angle_to_target(iAttacker, fVicOrigin)
		iAngleToVictim = abs(iAngleToVictim)
		static Float:fDis; fDis = 2.0 * get_distance_f(fStart, fAimInVictim) * floatsin( float(iAngleToVictim) * 0.5, degrees )
		static Float:fVicSize[3]
		pev(iVictim, pev_size , fVicSize)
		if ( fDis <= fVicSize[0] * 0.5 )
		{
			// TraceLine from fStart to aimOrigin in iVictim
			static ptr2; ptr2 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fAimInVictim, DONT_IGNORE_MONSTERS, iAttacker, ptr2)
			static pHit2; pHit2 = get_tr2(ptr2, TR_pHit)
			static iHitgroup2; iHitgroup2 = get_tr2(ptr2, TR_iHitgroup)
			
			// if ptr2 find target is iVictim
			if ( pHit2 == iVictim && (iHitgroup2 != HIT_HEAD || fDis <= fVicSize[0] * 0.25) )
			{
				pHit = iVictim
				iHitgroup = iHitgroup2
				get_tr2(ptr2, TR_vecEndPos, fEndPos)
			}
			
			free_tr2(ptr2)
		}
		
		// if pHit still not is iVictim then set default HitGroup
		if (pHit != iVictim)
		{
			// set default iHitgroup
			iHitgroup = HIT_GENERIC
			
			new ptr3 = create_tr2() 
			engfunc(EngFunc_TraceLine, fStart, fVicOrigin, DONT_IGNORE_MONSTERS, iAttacker, ptr3)
			get_tr2(ptr3, TR_vecEndPos, fEndPos)
			
			// free ptr3
			free_tr2(ptr3)
		}
	}
	
	// set new Hit & Hitgroup & EndPos
	set_tr2(ptr, TR_pHit, iVictim)
	set_tr2(ptr, TR_iHitgroup, iHitgroup)
	set_tr2(ptr, TR_vecEndPos, fEndPos)
	
	if(cs_get_user_team(iVictim) != cs_get_user_team(iAttacker)) create_blood(fEndPos)
	
	// hitgroup multi fDamage
	static Float:fMultifDamage 
	switch(iHitgroup)
	{
		case HIT_HEAD: fMultifDamage  = 4.0
		case HIT_STOMACH: fMultifDamage  = 1.25
		case HIT_LEFTLEG: fMultifDamage  = 0.75
		case HIT_RIGHTLEG: fMultifDamage  = 0.75
		default: fMultifDamage  = 1.0
	}
	
	fDamage *= fMultifDamage
	
	// ExecuteHam
	fake_trake_attack(iAttacker, iVictim, fDamage, fDirection, ptr)
	
	// free ptr
	free_tr2(ptr)
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

stock fake_trake_attack(iAttacker, iVictim, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDamageBit)
}

stock fake_take_damage(iAttacker, iVictim, Float:fDamage, iInflictor = 0, iDamageBit = (DMG_NEVERGIB | DMG_BULLET))
{
	ExecuteHamB(Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDamageBit)
}

stock get_angle_to_target(id, const Float:fTarget[3], Float:TargetSize = 0.0)
{
	new Float:fOrigin[3], iAimOrigin[3], Float:fAimOrigin[3], Float:fV1[3]
	pev(id, pev_origin, fOrigin)
	get_user_origin(id, iAimOrigin, 3) // end position from eyes
	IVecFVec(iAimOrigin, fAimOrigin)
	xs_vec_sub(fAimOrigin, fOrigin, fV1)
	
	new Float:fV2[3]
	xs_vec_sub(fTarget, fOrigin, fV2)
	
	new iResult = get_angle_between_vectors(fV1, fV2)
	
	if (TargetSize > 0.0)
	{
		new Float:fTan = TargetSize / get_distance_f(fOrigin, fTarget)
		new fAngleToTargetSize = floatround( floatatan(fTan, degrees) )
		iResult -= (iResult > 0) ? fAngleToTargetSize : -fAngleToTargetSize
	}
	
	return iResult
}

stock get_angle_between_vectors(const Float:fV1[3], const Float:fV2[3])
{
	new Float:fA1[3], Float:fA2[3]
	engfunc(EngFunc_VecToAngles, fV1, fA1)
	engfunc(EngFunc_VecToAngles, fV2, fA2)
	
	new iResult = floatround(fA1[1] - fA2[1])
	iResult = iResult % 360
	iResult = (iResult > 180) ? (iResult - 360) : iResult
	
	return iResult
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
	write_short(g_SmokePuff_SprId)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
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
		xs_vec_mul_scalar(v_forward, 20.0, v_forward); xs_vec_mul_scalar(v_right, -2.5, v_right);
		xs_vec_mul_scalar(v_up, -1.5, v_up);
		xs_vec_mul_scalar(v_forward2, 19.9, v_forward2); xs_vec_mul_scalar(v_right2, -2.0, v_right2);
		xs_vec_mul_scalar(v_up2, -2.0, v_up2);
	} else {
		xs_vec_mul_scalar(v_forward, 20.0, v_forward); xs_vec_mul_scalar(v_right, 2.5, v_right);
		xs_vec_mul_scalar(v_up, -1.5, v_up);
		xs_vec_mul_scalar(v_forward2, 19.9, v_forward2); xs_vec_mul_scalar(v_right2, 2.0, v_right2);
		xs_vec_mul_scalar(v_up2, -2.0, v_up2);
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
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2] - 16.0)
	engfunc(EngFunc_WriteCoord,velocity[0])
	engfunc(EngFunc_WriteCoord,velocity[1])
	engfunc(EngFunc_WriteCoord,velocity[2])
	write_angle(angle)
	write_short(ShellID)
	write_byte(1)
	write_byte(20)
	message_end()
}
