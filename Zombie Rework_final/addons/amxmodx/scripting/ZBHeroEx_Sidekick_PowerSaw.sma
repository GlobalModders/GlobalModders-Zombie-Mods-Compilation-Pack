#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "[ZEVO] Sidekick: PowerSaw"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon Leon"

#define V_MODEL "models/zombie_evolution/swpn/v_chainsaw.mdl"
#define P_MODEL "models/zombie_evolution/swpn/p_chainsaw.mdl"
#define W_MODEL "models/zombie_evolution/swpn/w_chainsaw.mdl"

#define DAMAGE_A 72
#define DAMAGE_B 500
#define CLIP 100
#define BPAMMO 200

#define DRAW_TIME 0.5
#define RELOAD_TIME 3.0

#define ATTACK_DELAY 0.065
#define ATTACK_RANGE 125.0

#define SLASH_TIME 1.0
#define SLASH_RANGE 130.0
#define SLASH_KNOCKPOWER 1250.0

#define CSW_POWERSAW CSW_M249
#define weapon_powersaw "weapon_m249"

#define WEAPON_EVENT "events/m249.sc"
#define OLD_W_MODEL "models/w_m249.mdl"
#define WEAPON_SECRETCODE 1984

#define PLAYER_ANIM_EXT_A "m249"
#define PLAYER_ANIM_EXT_B "knife"

#define TASK_ATTACK 28070

new const Weapon_Sounds[11][] =
{
	"weapons/chainsaw_attack1_end.wav",
	"weapons/chainsaw_attack1_loop.wav",
	"weapons/chainsaw_attack1_start.wav",
	"weapons/chainsaw_draw.wav",
	"weapons/chainsaw_draw1.wav",
	"weapons/chainsaw_hit1.wav",
	"weapons/chainsaw_hit2.wav",
	"weapons/chainsaw_hit3.wav",
	"weapons/chainsaw_hit4.wav",
	"weapons/chainsaw_idle.wav",
	"weapons/chainsaw_reload.wav"
	//"weapons/chainsaw_slash1.wav",
	//"weapons/chainsaw_slash2.wav",
	//"weapons/chainsaw_slash3.wav",
	//"weapons/chainsaw_slash4.wav"
}

/*
new const Weapon_Resources[3][] =
{
	"sprites/weapon_chainsaw.txt",
	"sprites/640hud21_2.spr",
	"sprites/640hud84_2.spr"
}*/

enum
{
	SAW_ANIM_IDLE = 0,
	SAW_ANIM_DRAW,
	SAW_ANIM_DRAW_EMPTY,
	SAW_ANIM_ATTACK_BEGIN,
	SAW_ANIM_ATTACK_LOOP,
	SAW_ANIM_ATTACK_END,
	SAW_ANIM_RELOAD,
	SAW_ANIM_SLASH1,
	SAW_ANIM_SLASH2,
	SAW_ANIM_SLASH3,
	SAW_ANIM_SLASH4,
	SAW_ANIM_IDLE_EMPTY
}

enum
{
	SAW_ATTACK_NOT = 0,
	SAW_ATTACK_BEGIN,
	SAW_ATTACK_LOOP,
	SAW_ATTACK_END
}


// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Vars
new g_PowerSaw
new g_Had_PowerSaw, g_PowerSaw_Clip[33], g_SlashType[33], g_Checking_Mode[33], g_PowerSaw_State[33], 
Float:g_Saw_AttackDelay[33], Float:g_Saw_AttackDelay2[33], g_PowerSaw_Event, m_iBlood[2], g_SmokePuff_SprID,
g_MsgAmmoX, g_MsgCurWeapon, g_MsgWeaponList, g_MaxPlayers

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	Register_SafetyFunc()
	
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")			
	
	RegisterHam(Ham_Item_Deploy, weapon_powersaw, "fw_Item_Deploy_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_powersaw, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_powersaw, "fw_Item_AddToPlayer_Post", 1)
	RegisterHam(Ham_Item_PostFrame, weapon_powersaw, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_powersaw, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_powersaw, "fw_Weapon_Reload_Post", 1)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	
	g_MsgAmmoX = get_user_msgid("AmmoX")
	g_MsgCurWeapon = get_user_msgid("CurWeapon")
	g_MsgWeaponList = get_user_msgid("WeaponList")
	g_MaxPlayers = get_maxplayers()
	
	g_PowerSaw = zbheroex_register_specialweapon("PowerSaw", HUMAN_SIDEKICK)
	register_clcmd("weapon_chainsaw", "Hook_Weapon")
	register_clcmd("dias_get_powersaw", "Get_PowerSaw", ADMIN_ADMIN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	new i
	for(i = 0; i < sizeof(Weapon_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, Weapon_Sounds[i])
		/*
	for(i = 0; i < sizeof(Weapon_Resources); i++)
	{
		if(i == 0) engfunc(EngFunc_PrecacheGeneric, Weapon_Resources[i])
		else  engfunc(EngFunc_PrecacheModel, Weapon_Resources[i])
	}*/
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")		
	g_SmokePuff_SprID = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_PowerSaw_Event = get_orig_retval()		
}

public client_putinserver(id) 
{
	Safety_Connected(id)
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
public client_disconnect(id) Safety_Disconnected(id)
public Register_HamBot(id) 
{
	Register_SafetyFuncBot(id)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post", 1)
}

public zbheroex_specialweapon(id, Type, ItemID)
{
	if(ItemID == g_PowerSaw) Get_PowerSaw(id)
}

public zbheroex_specialweapon_refill(id, ItemID)
{
	if(ItemID == g_PowerSaw)
	{
		cs_set_user_bpammo(id, CSW_POWERSAW, BPAMMO)
	}
}

public zbheroex_specialweapon_remove(id, ItemID)
{
	if(ItemID == g_PowerSaw) Remove_PowerSaw(id)
}

public Get_PowerSaw(id)
{
	Set_BitVar(g_Had_PowerSaw, id)
	g_SlashType[id] = 0
	g_PowerSaw_State[id] = 0
	
	give_item(id, weapon_powersaw)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_POWERSAW, BPAMMO)
	
	update_ammo_hud(id, CLIP, BPAMMO)
}

public Remove_PowerSaw(id)
{
	remove_task(id+TASK_ATTACK)
	
	UnSet_BitVar(g_Had_PowerSaw, id)
	g_SlashType[id] = 0
	g_PowerSaw_State[id] = 0
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_powersaw)
	return PLUGIN_HANDLED
}

public update_ammo_hud(id, ammo, bpammo)
{
	if(!is_alive(id))
		return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_MsgCurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_POWERSAW)
	write_byte(ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgAmmoX, _, id)
	write_byte(1)
	write_byte(bpammo)
	message_end()
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) == CSW_POWERSAW && Get_BitVar(g_Had_PowerSaw, id))
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_alive(invoker))
		return FMRES_IGNORED	
	if(get_player_weapon(invoker) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, invoker))
		return FMRES_IGNORED
	
	if(eventid == g_PowerSaw_Event)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)
		return FMRES_SUPERCEDE
	} 
	
	return FMRES_HANDLED
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
		static weapon; weapon = fm_find_ent_by_owner(-1, weapon_powersaw, entity)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED;
		
		if(Get_BitVar(g_Had_PowerSaw, iOwner))
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			engfunc(EngFunc_SetModel, entity, W_MODEL)
			
			Remove_PowerSaw(iOwner)
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}


public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))	
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
	
	if(!pev_valid(Ent))
		return

	if(NewButton & IN_ATTACK2)
	{
		if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP)
		{
			Set_WeaponIdleTime(id, CSW_POWERSAW, 0.0)
			Set_Player_NextAttack(id, 0.0)
			
			remove_task(id+TASK_ATTACK)
			g_PowerSaw_State[id] = SAW_ATTACK_NOT
		}
		
		if(get_pdata_float(id, 83, 5) > 0.0) 
			return
		
		g_Checking_Mode[id] = 1
		static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
		if(pev_valid(weapon_ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_ent)
		g_Checking_Mode[id] = 0
		
		Set_WeaponIdleTime(id, CSW_POWERSAW, SLASH_TIME + 0.5)
		Set_Player_NextAttack(id, SLASH_TIME)
		
		static TargetSlash, StartSlash
		if(cs_get_weapon_ammo(Ent) > 0) { StartSlash = SAW_ANIM_SLASH1; TargetSlash = SAW_ANIM_SLASH2; }
		else { StartSlash = SAW_ANIM_SLASH3; TargetSlash = SAW_ANIM_SLASH4; } 
		
		if(g_SlashType[id]) Set_WeaponAnim(id, StartSlash)
		else Set_WeaponAnim(id, TargetSlash)

		set_pdata_string(id, (492) * 4, PLAYER_ANIM_EXT_B, -1 , 20)
		PowerSaw_Do_Damage(id)
		
		g_SlashType[id] = !g_SlashType[id]
	}	
	
	if(NewButton & IN_ATTACK)
	{
		NewButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, NewButton)

		if(get_pdata_float(id, 83, 5) > 0.0 || get_pdata_float(Ent, 46, 4) > 0.0 || get_pdata_float(Ent, 47, 4) > 0.0) 
			return
		
		if(g_PowerSaw_State[id] == SAW_ATTACK_NOT)
		{
			g_PowerSaw_State[id] = SAW_ATTACK_BEGIN
		} else if(g_PowerSaw_State[id] == SAW_ATTACK_BEGIN) {
			Set_WeaponAnim(id, SAW_ANIM_ATTACK_BEGIN)

			Set_WeaponIdleTime(id, CSW_POWERSAW, 0.5)
			Set_Player_NextAttack(id, 0.5)
			
			if(!task_exists(id+TASK_ATTACK)) set_task(0.40, "Task_ChangeState_Loop", id+TASK_ATTACK)
		} else if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP) {
			if(cs_get_weapon_ammo(Ent) > 0)
			{
				Set_WeaponAnim(id, SAW_ANIM_ATTACK_LOOP)
				
				Set_WeaponIdleTime(id, CSW_POWERSAW, 0.5)
				Set_Player_NextAttack(id, 0.5)
			} else {
				g_PowerSaw_State[id] = SAW_ATTACK_END
				Set_WeaponAnim(id, SAW_ANIM_ATTACK_END)
				
				Set_WeaponIdleTime(id, CSW_POWERSAW, 0.5)
				Set_Player_NextAttack(id, 1.5)
				
				remove_task(id+TASK_ATTACK)
				g_PowerSaw_State[id] = SAW_ATTACK_NOT	
			}
		}
	} else {
		if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP) 
		{
			g_PowerSaw_State[id] = SAW_ATTACK_END
			Set_WeaponAnim(id, SAW_ANIM_ATTACK_END)
			
			Set_WeaponIdleTime(id, CSW_POWERSAW, 1.5)
			Set_Player_NextAttack(id, 0.1)
			
			remove_task(id+TASK_ATTACK)
			g_PowerSaw_State[id] = SAW_ATTACK_NOT
		}
		if(pev(id, pev_oldbuttons) & IN_ATTACK)
		{
			if((cs_get_weapon_ammo(Ent) <= 0) && get_pdata_int(Ent, 54, 4) != 1)
			{
				set_pdata_int(Ent, 54, 1, 4)
				ExecuteHamB(Ham_Weapon_Reload, Ent)
			}
		}
	}
	
	if(NewButton & IN_RELOAD)
	{
		if(get_pdata_int(Ent, 54))
			return
		if(cs_get_weapon_ammo(Ent) >= CLIP)
			return
		if(get_pdata_float(id, 83, 5) > 0.0 || get_pdata_float(Ent, 46, 4) > 0.0 || get_pdata_float(Ent, 47, 4) > 0.0) 
			return
			
		set_pdata_int(Ent, 54, 1, 4)
		ExecuteHamB(Ham_Weapon_Reload, Ent)
	}
}

public client_PostThink(id)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))
		return
	if(g_PowerSaw_State[id] != SAW_ATTACK_LOOP)
		return	
	if(get_gametime() - ATTACK_DELAY > g_Saw_AttackDelay[id])
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0)
		{
			// Shake Screen
			static Float:PunchAngles[3]
			PunchAngles[0] = random_float(-1.0, 1.0)
			PunchAngles[1] = random_float(-1.0, 1.0)
			
			set_pev(id, pev_punchangle, PunchAngles)
			
			static Float:Origin[3], Float:Target[3]
			pev(id, pev_origin, Origin); Origin[2] += 26.0
			get_position(id, ATTACK_RANGE, 0.0, 0.0, Target)
			
			static Trace; Trace = create_tr2()
			engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, Trace)
			static Hit; Hit = get_tr2(Trace, TR_pHit)
			
			if(is_alive(Hit))
			{
				do_attack(id, Hit, 0, float(DAMAGE_A))
				emit_sound(Ent, CHAN_WEAPON, Weapon_Sounds[5], 1.0, 0.4, 0, 94 + random_num(0, 15))
			} else {
				get_position(id, ATTACK_RANGE, -10.0, 0.0, Target)
				engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, Trace)
				Hit = get_tr2(Trace, TR_pHit)
				
				if(is_alive(Hit))
				{
					do_attack(id, Hit, 0, float(DAMAGE_A))
					emit_sound(Ent, CHAN_WEAPON, Weapon_Sounds[5], 1.0, 0.4, 0, 94 + random_num(0, 15))
				} else {
					get_position(id, ATTACK_RANGE, 10.0, 0.0, Target)
					engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, Trace)
					Hit = get_tr2(Trace, TR_pHit)
					
					if(is_alive(Hit))
					{
						do_attack(id, Hit, 0, float(DAMAGE_A))
						emit_sound(Ent, CHAN_WEAPON, Weapon_Sounds[5], 1.0, 0.4, 0, 94 + random_num(0, 15))
					} else {
						get_position(id, ATTACK_RANGE, 0.0, 0.0, Target)
						if(is_wall_between_points(Origin, Target, id))
						{
							emit_sound(Ent, CHAN_WEAPON, Weapon_Sounds[5], 1.0, 0.4, 0, 94 + random_num(0, 15))
							
							static ptr; ptr = create_tr2() 
							engfunc(EngFunc_TraceLine, Origin, Target, DONT_IGNORE_MONSTERS, id, ptr)
		
							static Float:EndPos[3]
							get_tr2(ptr, TR_vecEndPos, EndPos)
							
							make_bullet(id, EndPos)
							fake_smoke(id, ptr)
							
							free_tr2(ptr)
						}
					}
				}
			}
			
			free_tr2(Trace)
		} else {
			g_PowerSaw_State[id] = SAW_ATTACK_END
			Set_WeaponAnim(id, SAW_ANIM_ATTACK_END)
			
			Set_WeaponIdleTime(id, CSW_POWERSAW, 0.5)
			Set_Player_NextAttack(id, 1.5)
			
			remove_task(id+TASK_ATTACK)
			g_PowerSaw_State[id] = SAW_ATTACK_NOT
		}
		
		g_Saw_AttackDelay[id] = get_gametime()
	}
	
	if(get_gametime() -  0.15 > g_Saw_AttackDelay2[id])
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0)
		{
			cs_set_weapon_ammo(Ent, cs_get_weapon_ammo(Ent) - 1)
		}
		
		g_Saw_AttackDelay2[id] = get_gametime()
	}
}

public Task_ChangeState_Loop(id)
{
	id -= TASK_ATTACK
	
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))
		return
	if(g_PowerSaw_State[id] != SAW_ATTACK_BEGIN)
		return
		
	g_PowerSaw_State[id] = SAW_ATTACK_LOOP
}

public PowerSaw_Do_Damage(id)
{
	if(!is_alive(id))
		return
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))	
		return
	
	if(Check_SlashAttack(id))
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0) emit_sound(id, CHAN_WEAPON, Weapon_Sounds[6], 1.0, 0.4, 0, 94 + random_num(0, 15))
		else emit_sound(id, CHAN_WEAPON, Weapon_Sounds[random_num(7, 8)], 1.0, 0.4, 0, 94 + random_num(0, 15))
	}
}

public Check_SlashAttack(id)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	
	Point_Dis = 48.0 * 2.0
	Max_Distance = SLASH_RANGE
	TB_Distance = Max_Distance / 4.0
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin); MyOrigin[2] += 26.0
	
	for(new i = 0; i < 4; i++) get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent; ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
	pev(id, pev_origin, MyOrigin);
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
		if(id == i)
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		//if(is_wall_between_points(MyOrigin, VicOrigin, id))
		//	continue
		if(!is_in_viewcone(id, VicOrigin, 1))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[1]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[2]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[3]) <= Point_Dis)
		{
			if(!Have_Victim) Have_Victim = 1
			do_attack(id, i, 0, float(DAMAGE_B))
			
			if(cs_get_user_team(id) != cs_get_user_team(i))
				hook_ent3(i, MyOrigin, SLASH_KNOCKPOWER, 2.0, 2)
		}
	}	
	
	if(Have_Victim) return 1
	else return 0
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))
		return FMRES_IGNORED
	if(!g_Checking_Mode[id])
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
	if(get_player_weapon(id) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, id))
		return FMRES_IGNORED
	if(!g_Checking_Mode[id])
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

public fw_Item_Deploy_Post(Ent)
{
	if(pev_valid(Ent) != 2)
		return
	static Id; Id = get_pdata_cbase(Ent, 41, 4)
	if(get_pdata_cbase(Id, 373) != Ent)
		return
	if(!Get_BitVar(g_Had_PowerSaw, Id))
		return
	
	set_pev(Id, pev_viewmodel2, V_MODEL)
	set_pev(Id, pev_weaponmodel2, P_MODEL)
	
	// Draw Anim
	Set_WeaponAnim(Id, SAW_ANIM_DRAW)
	
	// Draw Time
	Set_WeaponIdleTime(Id, CSW_POWERSAW, DRAW_TIME + 0.5)
	Set_Player_NextAttack(Id, DRAW_TIME)
	
	// Set Player Anim
	set_pdata_string(Id, (492) * 4, PLAYER_ANIM_EXT_A, -1 , 20)
	
	g_SlashType[Id] = 1
	g_PowerSaw_State[Id] = SAW_ATTACK_NOT
}

public fw_Item_PostFrame(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_PowerSaw, id))
		return HAM_IGNORED	
	
	static Float:flNextAttack; flNextAttack = get_pdata_float(id, 83, 5)
	static bpammo; bpammo = cs_get_user_bpammo(id, CSW_POWERSAW)
	
	static iClip; iClip = get_pdata_int(ent, 51, 4)
	static fInReload; fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload && flNextAttack <= 0.0)
	{
		static temp1
		temp1 = min(CLIP - iClip, bpammo)

		set_pdata_int(ent, 51, iClip + temp1, 4)
		cs_set_user_bpammo(id, CSW_POWERSAW, bpammo - temp1)		
		
		set_pdata_int(ent, 54, 0, 4)
		
		fInReload = 0
	}		
	
	return HAM_IGNORED
}

public fw_Weapon_Reload(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_PowerSaw, id))
		return HAM_IGNORED	

	g_PowerSaw_Clip[id] = -1
		
	static BPAmmo; BPAmmo = cs_get_user_bpammo(id, CSW_POWERSAW)
	static iClip; iClip = get_pdata_int(ent, 51, 4)
		
	if(BPAmmo <= 0)
		return HAM_SUPERCEDE
	if(iClip >= CLIP)
		return HAM_SUPERCEDE		
			
	g_PowerSaw_Clip[id] = iClip	
	
	return HAM_HANDLED
}

public fw_Weapon_Reload_Post(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_PowerSaw, id))
		return HAM_IGNORED	
		
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if (g_PowerSaw_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_PowerSaw_Clip[id], 4)
		
		Set_WeaponAnim(id, SAW_ANIM_RELOAD)
		
		Set_WeaponIdleTime(id, CSW_POWERSAW, RELOAD_TIME - 1.0)
		Set_Player_NextAttack(id, RELOAD_TIME)
	}
	
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post(ent)
{
	static id; id = get_pdata_cbase(ent, 41, 4)
	if(!is_alive(id))
		return HAM_IGNORED
	if(!Get_BitVar(g_Had_PowerSaw, id))
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 48, 4) <= 0.1) 
	{
		Set_WeaponAnim(id, cs_get_weapon_ammo(ent) > 0 ? SAW_ANIM_IDLE : SAW_ANIM_IDLE_EMPTY)
		set_pdata_float(ent, 48, 20.0, 4)
		
		set_pdata_string(id, (492) * 4, PLAYER_ANIM_EXT_A, -1 , 20)
	}
	
	return HAM_IGNORED	
}

public fw_Item_AddToPlayer_Post(ent, id)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		Set_BitVar(g_Had_PowerSaw, id)
		set_pev(ent, pev_impulse, 0)
	}		
	
	/*
	if(Get_BitVar(g_Had_PowerSaw, id))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgWeaponList, .player = id)
		write_string("weapon_chainsaw" )
		write_byte(3) // PrimaryAmmoID
		write_byte(200) // PrimaryAmmoMaxAmount
		write_byte(-1) // SecondaryAmmoID
		write_byte(-1) // SecondaryAmmoMaxAmount
		write_byte(0) // SlotID (0...N)
		write_byte(4) // NumberInSlot (1...N)
		write_byte(CSW_POWERSAW) // WeaponID
		write_byte(0) // Flags
		message_end()
	}*/

	return HAM_HANDLED	
}

public fw_TakeDamage_Post(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!is_alive(Attacker) || !is_alive(Victim))
		return HAM_IGNORED
	if(get_player_weapon(Attacker) != CSW_POWERSAW || !Get_BitVar(g_Had_PowerSaw, Attacker))
		return HAM_IGNORED
	if(cs_get_user_team(Victim) == cs_get_user_team(Attacker))
		return HAM_IGNORED
		
	set_pdata_float(Victim, 108, 0.01, 5)
		
	return HAM_HANDLED
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
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

stock Set_Player_NextAttack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock Set_WeaponAnim(id, Anim)
{
	set_pev(id, pev_weaponanim, Anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(Anim)
	write_byte(pev(id, pev_body))
	message_end()
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

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time)
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time)
		fl_Velocity[2] = ((VicOrigin[2] - EntOrigin[2]) / fl_Time) + random_float(200.0, 300.0)	
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time)
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time)
		fl_Velocity[2] = ((EntOrigin[2] - VicOrigin[2]) / fl_Time) + random_float(200.0, 300.0)
	}

	set_pev(ent, pev_velocity, fl_Velocity)
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
	write_short(g_SmokePuff_SprID)
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

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

stock hook_ent3(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	static Float:EntVelocity[3]

	pev(ent, pev_velocity, EntVelocity)
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	static Float:fl_Time2; fl_Time2 = distance_f / (speed * multi)
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.0
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.0
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.0
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.0
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}
