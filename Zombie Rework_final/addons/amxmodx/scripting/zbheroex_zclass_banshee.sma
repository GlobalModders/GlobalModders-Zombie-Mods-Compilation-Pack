#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Class: Banshee"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define PULLING_COOLDOWN_ORIGIN 20
#define PULLING_COOLDOWN_HOST 10

#define TASK_DELAY_ANIM 2312321

// Zombie Configs
new zclass_name[24] = "Banshee"
new zclass_desc[24] = "Pulling & Chaos"
new zclass_desc1[24] = "Pulling"
new zclass_desc2[24] = "Chaos"
new const zclass_sex = SEX_FEMALE
new zclass_lockcost = 7000
new const zclass_hostmodel[] = "witch2_zombi_host"
new const zclass_originmodel[] = "witch2_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_witch2_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_witch2_zombi_origin.mdl"
new const Float:zclass_gravity = 0.80
new const Float:zclass_speed = 280.0
new const Float:zclass_knockback = 1.5
new const DeathSound[] = "zombie_thehero/zombie/zombi_banshee_death.wav"
new const HurtSound[] = "zombie_thehero/zombie/zombi_banshee_hurt.wav"
new const HealSound[] = "zombie_thehero/zombie/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution_female.wav"

new const Target_MaleSound[] = "zombie_thehero/human_male_surprise.wav"
new const Target_FemaleSound[] = "zombie_thehero/human_female_surprise.wav"

// Chaos
#define CHAOS_CLAWANIM 8
#define CHAOS_PLAYERANIM 57

#define CHAOS_CLASSNAME "chaos"
#define CHAOS_MODEL "models/zombie_thehero/w_zombibomb.mdl"
#define CHAOS_EXPSOUND "zombie_thehero/zombi_bomb_exp.wav"
#define CHAOS_HITSOUND "zombie_thehero/zombie/skill/confusion_keep.wav"
#define CHAOS_HITSPRITE "sprites/zombie_thehero/zb_confuse.spr"

#define CHAOS_SPEED 500
#define CHAOS_HOST_COOLDOWN 15
#define CHAOS_ORIGIN_COOLDOWN 15
#define CHAOS_HOST_HITTIME 7
#define CHAOS_ORIGIN_HITTIME 7
#define CHAOS_RADIUS_HIT 150

#define TASK_CHAOS 3123123

#define CHAOS_EXPSPR "sprites/zombie_thehero/zombiebomb_exp.spr"

// Bat
#define BAT_CREATETIME 1.0

#define PULLING_CLAWANIM 1
#define PULLING_CLAWANIM_LOOP 2
#define PULLING_PLAYERANIM 151
#define PULLING_PLAYERANIM_LOOP 152

#define BAT_CLASSNAME "bat"
#define BAT_MODEL "models/zombie_thehero/bat_witch.mdl"
#define BAT_FLYSOUND "zombie_thehero/zombie/banshee_pulling_fire.wav"
#define BAT_PULLINGSOUND "zombie_thehero/zombie/zombi_banshee_laugh.wav"
#define BAT_EXPSOUND "zombie_thehero/zombie/skill/bat_exp.wav"
#define BAT_EXPSPR "sprites/zombie_thehero/ef_bat.spr"

#define BAT_SPEED 600
#define BAT_HOST_MAXDISTANCE 700
#define BAT_ORIGIN_MAXDISTANCE 1500
#define BAT_HOST_LIVETIME 7
#define BAT_ORIGIN_LIVETIME 15

// HardCore
const pev_state = pev_iuser1
const pev_user = pev_iuser2
const pev_livetime = pev_fuser1
const pev_maxdistance = pev_fuser2
const pev_hittime = pev_fuser3

enum
{
	BAT_STATE_NONE = 0,
	BAT_STATE_TARGETING,
	BAT_STATE_RETURNING
}

new g_BatExp_SprId, g_ChaosExp_SprId

// Main Var
new g_Zombie_Banshee
new g_CanPulling, g_CanChaos, g_Pulling, g_Chaosing, g_TempingAttack
new g_synchud1, g_synchud2, ReadyWords[32], g_Time2[33], g_MaxPlayers, g_Msg_Shake

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_think(BAT_CLASSNAME, "fw_Bat_Think")
	register_touch(BAT_CLASSNAME, "*", "fw_Bat_Touch")
	register_touch(CHAOS_CLASSNAME, "*", "fw_Chaos_Touch")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	g_MaxPlayers = get_maxplayers()
	g_Msg_Shake = get_user_msgid("ScreenShake")
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_synchud2 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
}

public plugin_precache()
{
	amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "BANSHEE_COST")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_DESC")
	formatex(zclass_desc1, sizeof(zclass_desc1), "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_DESC1")
	formatex(zclass_desc2, sizeof(zclass_desc2), "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_DESC2")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	
	g_Zombie_Banshee = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound, DeathSound, HurtSound, HurtSound, HealSound, EvolSound)
	zbheroex_set_zombiecode(g_Zombie_Banshee, 1975)
	
	engfunc(EngFunc_PrecacheModel, BAT_MODEL)
	engfunc(EngFunc_PrecacheModel, CHAOS_MODEL)
	engfunc(EngFunc_PrecacheModel, CHAOS_HITSPRITE)
	engfunc(EngFunc_PrecacheSound, BAT_EXPSOUND)
	engfunc(EngFunc_PrecacheSound, BAT_FLYSOUND)
	engfunc(EngFunc_PrecacheSound, BAT_PULLINGSOUND)
	engfunc(EngFunc_PrecacheSound, CHAOS_HITSOUND)
	
	engfunc(EngFunc_PrecacheSound, Target_MaleSound)
	engfunc(EngFunc_PrecacheSound, Target_FemaleSound)
	
	g_BatExp_SprId = engfunc(EngFunc_PrecacheModel, BAT_EXPSPR)
	g_ChaosExp_SprId = engfunc(EngFunc_PrecacheModel, CHAOS_EXPSPR)
}

public zbheroex_user_infected(id, infector, Infection)
{
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Banshee)
		return
	
	reset_skill(id)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_Zombie_Banshee)
		return	
		
	Set_BitVar(g_CanPulling, id)
	UnSet_BitVar(g_Pulling, id)
	Set_BitVar(g_CanChaos, id)
	UnSet_BitVar(g_Chaosing, id)
	UnSet_BitVar(g_TempingAttack, id)
	
	zbheroex_set_user_time(id, 100)
	g_Time2[id] = 100
	
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Banshee)
		return
	if(!Get_BitVar(g_CanChaos, id))
	{
		if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
		return
	}
	
	Skill2_Handle(id)
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_Zombie_Banshee)
		return	
		
	reset_skill(id)
}

public reset_skill(id)
{
	UnSet_BitVar(g_CanPulling, id)
	UnSet_BitVar(g_CanChaos, id)
	UnSet_BitVar(g_Pulling, id)
	UnSet_BitVar(g_Chaosing, id)
	UnSet_BitVar(g_TempingAttack, id)
	
	client_cmd(id, "cl_minmodels 0")
	
	zbheroex_set_user_time(id, 0)
	g_Time2[id] = 0
}

public zbheroex_round_new() 
{
	remove_entity_name(BAT_CLASSNAME)
	remove_entity_name(CHAOS_CLASSNAME)
}
public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id)
}

public zbheroex_user_died(id) reset_skill(id)
public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_Zombie_Banshee)
		return
	if(!Get_BitVar(g_CanPulling, id) || Get_BitVar(g_Pulling, id) || Get_BitVar(g_Chaosing, id))
		return
	if(!(pev(id, pev_flags) & FL_ONGROUND))
	{
		client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_ONGROUND")
		return
	}
	if(pev(id, pev_flags) & FL_DUCKING)
	{
		client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_BANSHEE_DUCK")
		return
	}
		
	Do_Pulling(id)
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie)
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Banshee)
		return 	
	
	Show_PullingSkill(id)
	Show_ChaosSkill(id)
}

public Show_PullingSkill(id)
{
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time + 1)
	
	static Float:percent, percent2
	static Float:timewait
	
	timewait = zbheroex_get_user_level(id) > 1 ? float(PULLING_COOLDOWN_ORIGIN) : float(PULLING_COOLDOWN_HOST)
	
	percent = (float(Time) / timewait) * 100.0
	percent2 = floatround(percent)
	
	if(percent2 > 0 && percent2 < 50)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc1, percent2)
	} else if(percent2 >= 50 && percent < 100) {
		set_hudmessage(255, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc1, percent2)
	} else if(percent2 >= 100) {
		set_hudmessage(0, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n^n[G] - %s (%s)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc1, ReadyWords)
		
		if(!Get_BitVar(g_CanPulling, id)) 
		{
			Set_BitVar(g_CanPulling, id)
			UnSet_BitVar(g_Pulling, id)
		}
	}	
}

public Show_ChaosSkill(id)
{
	if(g_Time2[id] < 100) g_Time2[id]++
	
	static Float:percent, percent2
	static Float:timewait
	
	timewait = zbheroex_get_user_level(id) > 1 ? float(CHAOS_ORIGIN_COOLDOWN) : float(CHAOS_HOST_COOLDOWN)
	
	percent = (float(g_Time2[id]) / timewait) * 100.0
	percent2 = floatround(percent)
	
	if(percent2 > 0 && percent2 < 50)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.175, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud2, "[R] - %s (%i%%)", zclass_desc2, percent2)
	} else if(percent2 >= 50 && percent < 100) {
		set_hudmessage(255, 255, 0, -1.0, 0.175, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud2, "[R] - %s (%i%%)", zclass_desc2, percent2)
	} else if(percent2 >= 100) {
		set_hudmessage(0, 255, 0, -1.0, 0.175, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud2, "[R] - %s (%s)", zclass_desc2, ReadyWords)
		
		if(!Get_BitVar(g_CanChaos, id)) 
		{
			Set_BitVar(g_CanChaos, id)
			UnSet_BitVar(g_Chaosing, id)
		}
	}	
}

public Skill2_Handle(id)
{
	if(!Get_BitVar(g_CanChaos, id) || Get_BitVar(g_Chaosing, id))
		return
		
	UnSet_BitVar(g_CanChaos, id)
	Set_BitVar(g_Chaosing, id)
	g_Time2[id] = 0
	
	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 0.7)
	set_player_nextattack(id, 0.7)
	
	set_weapon_anim(id, CHAOS_CLAWANIM)
	set_pev(id, pev_framerate, 1.0)
	set_pev(id, pev_sequence, !(pev(id, pev_flags) & FL_DUCKING) ? CHAOS_PLAYERANIM : CHAOS_PLAYERANIM + 2)
	
	set_task(0.2, "Create_Chaos", id)
	set_task(0.7, "Reset_Chaos", id)
}

public Create_Chaos(id)
{
	if(!is_user_alive(id))
		return
		
	static Chaos; Chaos = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Chaos)) return
	
	// Origin & Angles
	static Float:Origin[3]; get_position(id, 40.0, 0.0, 0.0, Origin)
	static Float:Angles[3]; pev(id, pev_v_angle, Angles)
	
	set_pev(Chaos, pev_origin, Origin)
	set_pev(Chaos, pev_angles, Angles)
	
	// Set Bat Data
	set_pev(Chaos, pev_takedamage, DAMAGE_NO)
	set_pev(Chaos, pev_health, 1000.0)
	
	set_pev(Chaos, pev_classname, CHAOS_CLASSNAME)
	engfunc(EngFunc_SetModel, Chaos, CHAOS_MODEL)
	
	set_pev(Chaos, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Chaos, pev_solid, SOLID_BBOX)
	set_pev(Chaos, pev_gamestate, 1)
	
	static Float:mins[3]; mins[0] = -1.0; mins[1] = -1.0; mins[2] = -1.0
	static Float:maxs[3]; maxs[0] = 1.0; maxs[1] = 1.0; maxs[2] = 1.0
	engfunc(EngFunc_SetSize, Chaos, mins, maxs)
	
	// Set State
	set_pev(Chaos, pev_user, id)
	set_pev(Chaos, pev_hittime, zbheroex_get_user_level(id) > 1 ? float(CHAOS_ORIGIN_HITTIME) : float(CHAOS_HOST_HITTIME))
	
	// Anim
	Set_Entity_Anim(Chaos, 0)
	
	// Set Speed
	static Float:TargetOrigin[3], Float:Velocity[3]
	fm_get_aim_origin(id, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, float(CHAOS_SPEED), Velocity)

	set_pev(Chaos, pev_velocity, Velocity)	
}

public fw_Chaos_Touch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
		
	Chaos_Explosion(Ent)
}

public Chaos_Explosion(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	// Exp Spr
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_ChaosExp_SprId)
	write_byte(20)
	write_byte(30)
	write_byte(14)
	message_end()	
	
	// Check Radius
	Chaos_Active(Ent)
	
	// Sound
	emit_sound(Ent, CHAN_BODY, CHAOS_EXPSOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Remove
	if(pev_valid(Ent)) engfunc(EngFunc_RemoveEntity, Ent)	
}

public Chaos_Active(Ent)
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(Ent, i) > float(CHAOS_RADIUS_HIT))
			continue
		if(zbheroex_get_user_zombie(i))
			continue
		
		client_cmd(i, "cl_minmodels 1")
		
		static Float:Time; pev(Ent, pev_hittime, Time)
		set_task(Time, "Remove_Chaos", i+TASK_CHAOS)
		
		ScreenShake(i)
		PlaySound(i, CHAOS_HITSOUND)
		
		zbheroex_show_attachment(i, CHAOS_HITSPRITE, Time, 1.0, 1.0, 6)
	}
}

public Remove_Chaos(id)
{
	id -= TASK_CHAOS
	if(!is_user_connected(id))
		return
		
	client_cmd(id, "cl_minmodels 0")
}

public Reset_Chaos(id)
{
	if(!is_user_alive(id))
		return
	
	UnSet_BitVar(g_Chaosing, id)
		
	set_weapons_timeidle(id, 0.75)
	set_player_nextattack(id, 0.75)
	set_weapon_anim(id, 3)
	
	set_pev(id, pev_framerate, 1.0)
}

public Do_Pulling(id)
{
	UnSet_BitVar(g_CanPulling, id)
	Set_BitVar(g_Pulling, id)
	zbheroex_set_user_time(id, 0)

	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 9999.0)
	set_player_nextattack(id, 9999.0)

	set_weapon_anim(id, PULLING_CLAWANIM)
	set_pev(id, pev_framerate, 0.35)
	set_pev(id, pev_sequence, PULLING_PLAYERANIM)
	
	zbheroex_set_user_speed(id, 1)

	emit_sound(id, CHAN_ITEM, BAT_PULLINGSOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Start Stamping
	set_task(BAT_CREATETIME, "Create_Bat", id)
}

public Do_FakeAttack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_TempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
	UnSet_BitVar(g_TempingAttack, id)
}

public Create_Bat(id)
{
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	
	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 9999.0)
	set_player_nextattack(id, 9999.0)
	
	set_weapon_anim(id, PULLING_CLAWANIM_LOOP)
	
	set_pev(id, pev_framerate, 0.5)
	set_pev(id, pev_sequence, PULLING_PLAYERANIM_LOOP)
	
	set_task(1.0, "Delay_Anim", id+TASK_DELAY_ANIM)
	
	static Bat; Bat = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Bat)) return
	
	// Origin & Angles
	static Float:Origin[3]; get_position(id, 40.0, 0.0, 0.0, Origin)
	static Float:Angles[3]; pev(id, pev_v_angle, Angles)
	
	set_pev(Bat, pev_origin, Origin)
	set_pev(Bat, pev_angles, Angles)
	
	// Set Bat Data
	set_pev(Bat, pev_takedamage, DAMAGE_NO)
	set_pev(Bat, pev_health, 1000.0)
	
	set_pev(Bat, pev_classname, BAT_CLASSNAME)
	engfunc(EngFunc_SetModel, Bat, BAT_MODEL)
	
	set_pev(Bat, pev_movetype, MOVETYPE_FLY)
	set_pev(Bat, pev_solid, SOLID_BBOX)
	set_pev(Bat, pev_gamestate, 1)
	
	static Float:mins[3]; mins[0] = -5.0; mins[1] = -5.0; mins[2] = -5.0
	static Float:maxs[3]; maxs[0] = 5.0; maxs[1] = 5.0; maxs[2] = 5.0
	engfunc(EngFunc_SetSize, Bat, mins, maxs)
	
	// Set State
	set_pev(Bat, pev_state, BAT_STATE_TARGETING)
	set_pev(Bat, pev_user, id)
	set_pev(Bat, pev_maxdistance, zbheroex_get_user_level(id) > 1 ? float(BAT_ORIGIN_LIVETIME) : float(BAT_HOST_LIVETIME))
	set_pev(Bat, pev_livetime, get_gametime() + (zbheroex_get_user_level(id) > 1 ? float(BAT_ORIGIN_LIVETIME) : float(BAT_HOST_LIVETIME)))
	
	// Anim
	Set_Entity_Anim(Bat, 0)
	
	// Set Next Think
	set_pev(Bat, pev_nextthink, get_gametime() + 0.1)
	
	// Set Speed
	static Float:TargetOrigin[3], Float:Velocity[3]
	get_position(id, 4000.0, 0.0, 0.0, TargetOrigin)
	get_speed_vector(Origin, TargetOrigin, float(BAT_SPEED), Velocity)
	
	emit_sound(id, CHAN_BODY, BAT_FLYSOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_pev(Bat, pev_velocity, Velocity)
}

public Delay_Anim(id)
{
	id -= TASK_DELAY_ANIM
	
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Pulling, id))
		return
		
	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 9999.0)
	set_player_nextattack(id, 9999.0)
	
	set_weapon_anim(id, PULLING_CLAWANIM_LOOP)
	
	set_pev(id, pev_framerate, 0.5)
	set_pev(id, pev_sequence, PULLING_PLAYERANIM_LOOP)
	
	set_task(1.0, "Delay_Anim", id+TASK_DELAY_ANIM)
}

public fw_Bat_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Owner; Owner = pev(Ent, pev_user)
	if(!is_user_alive(Owner) ||  !zbheroex_get_user_zombie(Owner))
	{
		Bat_Explosion(Ent)
		return
	}
	if(entity_range(Owner, Ent) > pev(Ent, pev_maxdistance))
	{
		Bat_Explosion(Ent)
		return
	}
	if(pev(Ent, pev_livetime) <= get_gametime())
	{
		Bat_Explosion(Ent)
		return
	}
	if(pev(Ent, pev_state) == BAT_STATE_RETURNING)
	{
		static Victim; Victim = pev(Ent, pev_enemy)
		if(!is_user_alive(Victim))
		{
			Bat_Explosion(Ent)
			return
		}
		if(entity_range(Owner, Victim) <= 48.0)
		{
			Bat_Explosion(Ent)
			return
		}
		
		static Float:Origin[3]
		pev(Owner, pev_origin, Origin)
		
		HookEnt(Victim, Origin, float(BAT_SPEED) / 3.0, 1.0, 1)
	}
	
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public fw_Bat_Touch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
		
	static Owner; Owner = pev(Ent, pev_user)
	if(!is_user_alive(Owner) ||  !zbheroex_get_user_zombie(Owner))
	{
		Bat_Explosion(Ent)
		return
	}	
	if(is_user_alive(Id) && Owner != Id) // We got a player
	{
		Capture_Victim(Ent, Id)
	} else {
		Bat_Explosion(Ent)
	}
}

public Capture_Victim(Ent, Id)
{
	static Owner; Owner = pev(Ent, pev_user)
	if(!is_user_alive(Owner) || !zbheroex_get_user_zombie(Owner))
	{
		Bat_Explosion(Ent)
		return
	}
	
	if(zbheroex_get_user_hero(Id))
	{
		Bat_Explosion(Ent)
		return
	}
	
	if(!zbheroex_get_user_zombie(Id))
	{
		if(!zbheroex_get_user_female(Id)) emit_sound(Id, CHAN_ITEM, Target_MaleSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		else emit_sound(Id, CHAN_ITEM, Target_FemaleSound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	}
	
	set_pev(Ent, pev_state, BAT_STATE_RETURNING)
	set_pev(Ent, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(Ent, pev_solid, SOLID_NOT)
	
	set_pev(Ent, pev_enemy, Id)
	set_pev(Ent, pev_aiment, Id)
}

public Bat_Explosion(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	// Exp Spr
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_BatExp_SprId)
	write_byte(20)
	write_byte(30)
	write_byte(14)
	message_end()	
	
	// Reset Owner
	Reset_Owner(Ent)
	
	// Sound
	emit_sound(Ent, CHAN_BODY, BAT_EXPSOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Remove
	if(pev_valid(Ent)) engfunc(EngFunc_RemoveEntity, Ent)
}

public Reset_Owner(Ent)
{
	static Id; Id = pev(Ent, pev_user)
	if(!is_user_alive(Id) || !zbheroex_get_user_zombie(Id))
		return
		
	UnSet_BitVar(g_Pulling, Id)
		
	set_weapons_timeidle(Id, 0.75)
	set_player_nextattack(Id, 0.75)
	set_weapon_anim(Id, 3)
	
	set_pev(Id, pev_framerate, 1.0)
	
	zbheroex_set_user_speed(Id, floatround(zclass_speed))
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Banshee)
		return
		
	static CurButton, OldButton
	
	CurButton = get_uc(uc_handle, UC_Buttons)
	OldButton = pev(id, pev_oldbuttons)
	
	if((CurButton & IN_RELOAD) && !(OldButton & IN_RELOAD))
		Skill2_Handle(id)
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE
	if(!is_user_alive(id))
		return FMRES_IGNORED

	if(Get_BitVar(g_TempingAttack, id))
	{
		if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
				return FMRES_SUPERCEDE
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if(sample[17] == 'w') return FMRES_SUPERCEDE
				else return FMRES_SUPERCEDE
			}
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
				return FMRES_SUPERCEDE;
		}
	}
		
	return FMRES_HANDLED
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!zbheroex_get_user_zombie(id))
		return FMRES_IGNORED
	if(!Get_BitVar(g_TempingAttack, id))
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
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!zbheroex_get_user_zombie(id))
		return FMRES_IGNORED
	if(!Get_BitVar(g_TempingAttack, id))
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

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles

	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
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

stock Set_Entity_Anim(Ent, Anim)
{
	set_pev(Ent, pev_animtime, get_gametime())
	set_pev(Ent, pev_sequence, Anim)
	set_pev(Ent, pev_framerate, 1.0)
	set_pev(Ent, pev_frame, 0.0)
}

stock HookEnt(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
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
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time2) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time2) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}

	xs_vec_add(EntVelocity, fl_Velocity, fl_Velocity)
	set_pev(ent, pev_velocity, fl_Velocity)
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock set_weapons_timeidle(id, Float:TimeIdle)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(pev_valid(Ent)) set_pdata_float(Ent, 48, TimeIdle, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

public ScreenShake(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Shake, _, id)
	write_short(255<<14)
	write_short(10<<14)
	write_short(255<<14)
	message_end()
}

stock amx_load_setting_int(const filename[], const setting_section[], setting_key[])
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZBHeroEX] Can't load settings: empty filename")
		return false;
	}
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZBHeroEX] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[32]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			static return_value
			// Return int by reference
			return_value = str_to_num(current_value)
			
			// Values succesfully retrieved
			fclose(file)
			return return_value
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
