#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: PowerSaw"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define V_MODEL "models/zombie_thehero/weapon/pri/v_chainsaw.mdl"
#define P_MODEL "models/zombie_thehero/weapon/pri/p_chainsaw.mdl"
#define W_MODEL "models/zombie_thehero/weapon/pri/w_chainsaw.mdl"

#define DAMAGE_A 35
#define DAMAGE_B 450
#define CLIP 100
#define BPAMMO 200

#define DRAW_TIME 1.0
#define RELOAD_TIME 3.0

#define ATTACK_DELAY 0.075
#define ATTACK_RANGE 90.0

#define SLASH_TIME 1.0
#define SLASH_DELAY 0.05
#define SLASH_RANGE 140.0
#define SLASH_KNOCKPOWER 3000.0

#define CSW_POWERSAW CSW_M249
#define weapon_powersaw "weapon_m249"
#define WEAPON_EVENT "events/m249.sc"
#define OLD_W_MODEL "models/w_m249.mdl"
#define WEAPON_SECRETCODE 1984

#define PLAYER_ANIM_EXT_A "m249"
#define PLAYER_ANIM_EXT_B "knife"

#define TASK_ATTACK 28070

new const Saw_Sounds[15][] =
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
	"weapons/chainsaw_reload.wav",
	"weapons/chainsaw_slash1.wav",
	"weapons/chainsaw_slash2.wav",
	"weapons/chainsaw_slash3.wav",
	"weapons/chainsaw_slash4.wav"
}

new const Saw_Resources[3][] =
{
	"sprites/weapon_chainsaw.txt",
	"sprites/640hud21_2.spr",
	"sprites/640hud84_2.spr"
}

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

new g_PowerSaw
new g_Had_PowerSaw[33], g_PowerSaw_Clip[33], g_SlashType[33], g_Checking_Mode[33], g_PowerSaw_State[33], 
Float:g_Saw_AttackDelay[33], g_Old_Weapon[33], g_PowerSaw_Event, m_iBlood[2], g_smokepuff_id,
g_Msg_HideWeapon, g_Msg_AmmoX, g_Msg_CurWeapon, g_Msg_WeaponList, g_MaxPlayers

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")

	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")	
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_CmdStart, "fw_CmdStart")	
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")			
	
	RegisterHam(Ham_Item_PostFrame, weapon_powersaw, "fw_Item_PostFrame")	
	RegisterHam(Ham_Weapon_Reload, weapon_powersaw, "fw_Weapon_Reload")
	RegisterHam(Ham_Weapon_Reload, weapon_powersaw, "fw_Weapon_Reload_Post", 1)
	RegisterHam(Ham_Weapon_WeaponIdle, weapon_powersaw, "fw_Weapon_WeaponIdle_Post", 1)
	RegisterHam(Ham_Item_AddToPlayer, weapon_powersaw, "fw_Item_AddToPlayer_Post", 1)
	
	g_Msg_HideWeapon = get_user_msgid("HideWeapon")
	g_Msg_AmmoX = get_user_msgid("AmmoX")
	g_Msg_CurWeapon = get_user_msgid("CurWeapon")
	g_Msg_WeaponList = get_user_msgid("WeaponList")
	
	g_MaxPlayers = get_maxplayers()
	register_clcmd("weapon_chainsaw", "Hook_Weapon")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, V_MODEL)
	engfunc(EngFunc_PrecacheModel, P_MODEL)
	engfunc(EngFunc_PrecacheModel, W_MODEL)
	
	new i
	for(i = 0; i < sizeof(Saw_Sounds); i++)
		engfunc(EngFunc_PrecacheSound, Saw_Sounds[i])
	
	for(i = 0; i < sizeof(Saw_Resources); i++)
	{
		if(i == 0) engfunc(EngFunc_PrecacheGeneric, Saw_Resources[i])
		else  engfunc(EngFunc_PrecacheModel, Saw_Resources[i])
	}
	
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")		
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)
	g_PowerSaw = zbheroex_register_weapon("PowerSaw", WEAPON_PRIMARY, CSW_POWERSAW, 16000)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(WEAPON_EVENT, name))
		g_PowerSaw_Event = get_orig_retval()		
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_PowerSaw) Get_PowerSaw(id)
}

public zbheroex_weapon_remove(id, ItemID)
{
	if(ItemID == g_PowerSaw) Remove_PowerSaw(id)
}

public Get_PowerSaw(id)
{
	if(!is_user_alive(id))
		return

	g_Had_PowerSaw[id] = 1
	g_SlashType[id] = 0
	g_PowerSaw_State[id] = 0
	
	fm_give_item(id, weapon_powersaw)
	
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
	if(!pev_valid(Ent)) return
	
	cs_set_weapon_ammo(Ent, CLIP)
	cs_set_user_bpammo(id, CSW_POWERSAW, BPAMMO)
	
	update_ammo_hud(id, CLIP, BPAMMO)
}

public Remove_PowerSaw(id)
{
	if(!is_user_connected(id))
		return
	
	remove_task(id+TASK_ATTACK)
	
	g_Had_PowerSaw[id] = 0
	g_SlashType[id] = 0
	g_PowerSaw_State[id] = 0
}

public Hook_Weapon(id)
{
	engclient_cmd(id, weapon_powersaw)
	return PLUGIN_HANDLED
}

public Event_NewRound()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		Remove_PowerSaw(i)
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	if(g_Had_PowerSaw[id] && (get_user_weapon(id) == CSW_POWERSAW && g_Old_Weapon[id] != CSW_POWERSAW))
	{ // Draw
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
		
		// Draw Anim
		set_weapon_anim(id, SAW_ANIM_DRAW)
		
		// Draw Time
		set_weapon_timeidle(id, DRAW_TIME - 0.5)
		set_player_nextattack(id, DRAW_TIME)
		
		// Set Player Anim
		set_pdata_string(id, (492) * 4, PLAYER_ANIM_EXT_A, -1 , 20)
		
		g_SlashType[id] = 1
		g_PowerSaw_State[id] = SAW_ATTACK_NOT
		
		Hide_Crosshair(id)
	} else if(get_user_weapon(id) != CSW_POWERSAW && g_Old_Weapon[id] == CSW_POWERSAW) {
		Draw_Crosshair(id)
	}
	
	g_Old_Weapon[id] = get_user_weapon(id)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_POWERSAW && g_Had_PowerSaw[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED	
	if(get_user_weapon(invoker) != CSW_POWERSAW || !g_Had_PowerSaw[invoker])
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
		
		if(g_Had_PowerSaw[iOwner])
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
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])	
		return
		
	static NewButton; NewButton = get_uc(uc_handle, UC_Buttons)
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
	
	if(!pev_valid(Ent))
		return

	if(NewButton & IN_ATTACK2)
	{
		if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP)
		{
			set_weapon_timeidle(id, 0.0)
			set_player_nextattack(id, 0.0)
			
			remove_task(id+TASK_ATTACK)
			g_PowerSaw_State[id] = SAW_ATTACK_NOT
		}
		
		if(get_pdata_float(id, 83, 5) > 0.0 || get_pdata_float(Ent, 46, 4) > 0.0 || get_pdata_float(Ent, 47, 4) > 0.0) 
			return
		
		g_Checking_Mode[id] = 1
		static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
		if(pev_valid(weapon_ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_ent)
		g_Checking_Mode[id] = 0
		
		set_weapon_timeidle(id, SLASH_TIME - 0.5)
		set_player_nextattack(id, SLASH_TIME)
		
		static TargetSlash, StartSlash
		if(cs_get_weapon_ammo(Ent) > 0) { StartSlash = SAW_ANIM_SLASH1; TargetSlash = SAW_ANIM_SLASH2; }
		else { StartSlash = SAW_ANIM_SLASH3; TargetSlash = SAW_ANIM_SLASH4; } 
		
		if(g_SlashType[id]) set_weapon_anim(id, StartSlash)
		else set_weapon_anim(id, TargetSlash)

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
			set_weapon_anim(id, SAW_ANIM_ATTACK_BEGIN)

			set_weapon_timeidle(id, 0.5)
			set_player_nextattack(id, 0.5)
			
			if(!task_exists(id+TASK_ATTACK)) set_task(0.40, "Task_ChangeState_Loop", id+TASK_ATTACK)
		} else if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP) {
			if(cs_get_weapon_ammo(Ent) > 0)
			{
				set_weapon_anim(id, SAW_ANIM_ATTACK_LOOP)
				
				set_weapon_timeidle(id, 0.5)
				set_player_nextattack(id, 0.5)
			} else {
				g_PowerSaw_State[id] = SAW_ATTACK_END
				set_weapon_anim(id, SAW_ANIM_ATTACK_END)
				
				set_weapon_timeidle(id, 0.5)
				set_player_nextattack(id, 1.5)
				
				remove_task(id+TASK_ATTACK)
				g_PowerSaw_State[id] = SAW_ATTACK_NOT	
			}
		}
	} else {
		if(g_PowerSaw_State[id] == SAW_ATTACK_LOOP) 
		{
			g_PowerSaw_State[id] = SAW_ATTACK_END
			set_weapon_anim(id, SAW_ANIM_ATTACK_END)
			
			set_weapon_timeidle(id, 0.5)
			set_player_nextattack(id, 1.5)
			
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
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])
		return
	if(g_PowerSaw_State[id] != SAW_ATTACK_LOOP)
		return	

	if(get_gametime() - ATTACK_DELAY > g_Saw_AttackDelay[id])
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0)
		{
			cs_set_weapon_ammo(Ent, cs_get_weapon_ammo(Ent) - 1)
			
			// Shake Screen
			static Float:PunchAngles[3]
			PunchAngles[0] = random_float(-1.75, 1.75)
			PunchAngles[1] = random_float(-1.75, 1.75)
			
			set_pev(id, pev_punchangle, PunchAngles)
			
			static Body, Target
			get_user_aiming(id, Target, Body, floatround(ATTACK_RANGE))
			
			if(is_user_alive(Target)) 
			{
				do_attack(id, Target, 0, float(DAMAGE_A))
				emit_sound(id, CHAN_WEAPON, Saw_Sounds[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
			} else {
				static Float:StartOrigin[3], Float:EndOrigin[3]
				
				pev(id, pev_origin, StartOrigin)
				get_weapon_attachment(id, EndOrigin, ATTACK_RANGE + 2.5)
				
				if(is_wall_between_points(StartOrigin, EndOrigin, id))
				{
					emit_sound(id, CHAN_WEAPON, Saw_Sounds[5], 1.0, ATTN_NORM, 0, PITCH_NORM)
						
					static ptr; ptr = create_tr2() 
					engfunc(EngFunc_TraceLine, StartOrigin, EndOrigin, id, id, ptr)

					//static Float:EndPos[3]
					//get_tr2(ptr, TR_vecEndPos, EndPos)
					
					//make_bullet(id, EndPos)
					fake_smoke(id, ptr)
					
					free_tr2(ptr)
				}
			}
		} else {
			g_PowerSaw_State[id] = SAW_ATTACK_END
			set_weapon_anim(id, SAW_ANIM_ATTACK_END)
			
			set_weapon_timeidle(id, 0.5)
			set_player_nextattack(id, 1.5)
			
			remove_task(id+TASK_ATTACK)
			g_PowerSaw_State[id] = SAW_ATTACK_NOT
		}
		
		g_Saw_AttackDelay[id] = get_gametime()
	}
}

public Task_ChangeState_Loop(id)
{
	id -= TASK_ATTACK
	
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])
		return
	if(g_PowerSaw_State[id] != SAW_ATTACK_BEGIN)
		return
		
	g_PowerSaw_State[id] = SAW_ATTACK_LOOP
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])
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
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])
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

public PowerSaw_Do_Damage(id)
{
	if(!is_user_alive(id))
		return
	if(get_user_weapon(id) != CSW_POWERSAW || !g_Had_PowerSaw[id])	

	if(Check_SlashAttack(id))
	{
		static Ent; Ent = fm_get_user_weapon_entity(id, CSW_POWERSAW)
		if(!pev_valid(Ent)) return
		
		if(cs_get_weapon_ammo(Ent) > 0) emit_sound(id, CHAN_WEAPON, Saw_Sounds[6], 1.0, ATTN_NORM, 0, PITCH_NORM)
		else emit_sound(id, CHAN_WEAPON, Saw_Sounds[random_num(7, 8)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
}

public fw_Item_PostFrame(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_PowerSaw[id])
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
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_PowerSaw[id])
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
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_PowerSaw[id])
		return HAM_IGNORED
		
	if((get_pdata_int(ent, 54, 4) == 1))
	{ // Reload
		if (g_PowerSaw_Clip[id] == -1)
			return HAM_IGNORED
		
		set_pdata_int(ent, 51, g_PowerSaw_Clip[id], 4)
		
		set_weapon_anim(id, SAW_ANIM_RELOAD)
		
		set_weapon_timeidle(id, RELOAD_TIME - 1.0)
		set_player_nextattack(id, RELOAD_TIME)
	}
	
	return HAM_HANDLED
}

public fw_Weapon_WeaponIdle_Post(ent)
{
	static id; id = pev(ent, pev_owner)
	if(!is_user_alive(id))
		return HAM_IGNORED
	if(!g_Had_PowerSaw[id])
		return HAM_IGNORED
		
	if(get_pdata_float(ent, 48, 4) <= 0.1) 
	{
		set_weapon_anim(id, cs_get_weapon_ammo(ent) > 0 ? SAW_ANIM_IDLE : SAW_ANIM_IDLE_EMPTY)
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
		g_Had_PowerSaw[id] = 1
		set_pev(ent, pev_impulse, 0)
	}		
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_WeaponList, .player = id)
	write_string(g_Had_PowerSaw[id] == 1 ? "weapon_chainsaw" : "weapon_m249")
	write_byte(3) // PrimaryAmmoID
	write_byte(200) // PrimaryAmmoMaxAmount
	write_byte(-1) // SecondaryAmmoID
	write_byte(-1) // SecondaryAmmoMaxAmount
	write_byte(0) // SlotID (0...N)
	write_byte(4) // NumberInSlot (1...N)
	write_byte(g_Had_PowerSaw[id] == 1 ? CSW_POWERSAW : CSW_M249) // WeaponID
	write_byte(0) // Flags
	message_end()

	return HAM_HANDLED	
}

public Check_SlashAttack(id)
{
	static Float:Max_Distance, Float:Point[4][3], Float:TB_Distance, Float:Point_Dis
	
	Point_Dis = 48.0
	Max_Distance = SLASH_RANGE
	TB_Distance = Max_Distance / 4.0
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < 4; i++) get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
		
	static Have_Victim; Have_Victim = 0
	static ent
	ent = fm_get_user_weapon_entity(id, get_user_weapon(id))
		
	if(!pev_valid(ent))
		return 0
		
	static IsDias; IsDias = 0
	static SteamID[64]; get_user_authid(id, SteamID, sizeof(SteamID))
	if(equal(SteamID, "STEAM_0:1:48204318")) IsDias = 1
		
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(id == i)
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue
			
		if(get_distance_f(VicOrigin, Point[0]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[1]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[2]) <= Point_Dis
		|| get_distance_f(VicOrigin, Point[3]) <= Point_Dis)
		{
			if(!Have_Victim) Have_Victim = 1
			
			if(zbheroex_get_user_zombie(i))
			{
				if(!IsDias) do_attack(id, i, 0, float(DAMAGE_B))
				else do_attack(id, i, 0, 99999.0)
				hook_ent2(i, MyOrigin, SLASH_KNOCKPOWER, 2)
			}
		}
	}	
	
	if(Have_Victim)
		return 1
	else
		return 0
	
	return 0
}

public update_ammo_hud(id, ammo, bpammo)
{
	if(!is_user_alive(id))
		return
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, g_Msg_CurWeapon, {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_POWERSAW)
	write_byte(ammo)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_AmmoX, _, id)
	write_byte(1)
	write_byte(bpammo)
	message_end()
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

stock set_weapon_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	static entwpn; entwpn = fm_get_user_weapon_entity(id, CSW_POWERSAW)
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
	
	create_blood(fEndPos)
	
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

stock Hide_Crosshair(id)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_HideWeapon, _, id)
	write_byte(1<<6)
	message_end()
}

stock Draw_Crosshair(id)
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_HideWeapon, _, id)
	write_byte(0)
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
