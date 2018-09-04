#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>
#include <zombie_giant>

#define PLUGIN "[ZG] Boss: Dione"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon Leon"

#define GIANT_BASEHEALTH 1500
#define GIANT_SPEED 360.0
#define GIANT_MODEL "models/zombie_giant/giant/dione.mdl"
#define GIANT_CLASSNAME "dione"

#define SKILL_HUD_X -1.0
#define SKILL_HUD_Y 0.75
#define LANG_DEFAULT LANG_SERVER
#define LANG_FILE "zombie_giant.txt"

#define MANA_ATTACK 25
#define MANA_ROLLING 75
#define MANA_POISON 50

#define DAMAGE_ATTACK 750.0
#define DAMAGE_ROLLING 999999.0 // Death Confirmation
#define DAMAGE_POISON 750.0

#define DIONE_EF_ATTACK1 "models/zombie_giant/ef_dione.mdl"
#define DIONE_EF_ATTACK2 "models/zombie_giant/ef_swing.mdl"
#define DIONE_EF_POISON "models/zombie_giant/ef_poison.mdl"
#define DIONE_EF_POISONGROUND "models/zombie_giant/ef_poisonground.mdl"
#define DIONE_EF_POISONEXP1 "sprites/zombie_giant/poisonexp.spr"
#define DIONE_EF_POISONEXP2 "sprites/zombie_giant/poisonexp2.spr"

new const GiantSounds[15][] =
{
	"zombie_giant/giant/dione/appear2.wav", // 0
	"zombie_giant/giant/dione/attack1_1.wav", // 1
	"zombie_giant/giant/dione/attack1_2.wav", // 2
	"zombie_giant/giant/dione/attack2.wav", // 3
	"zombie_giant/giant/dione/dash.wav", // 4
	"zombie_giant/giant/dione/death1.wav", // 5
	"zombie_giant/giant/dione/evolution.wav", // 6
	"zombie_giant/giant/dione/footstep1.wav", // 7
	"zombie_giant/giant/dione/footstep2.wav", // 8
	"zombie_giant/giant/dione/idle.wav", // 9
	"zombie_giant/giant/dione/skill_final.wav", // 10
	"zombie_giant/giant/dione/skill_poison.wav", // 11
	"zombie_giant/giant/dione/skill_rolling.wav", // 12
	"zombie_giant/giant/dione/skill_rolling_end.wav", // 13
	"zombie_giant/giant/dione/skill_tantacle.wav" // 14
}

enum
{
	ANIME_DUMMY = 0,
	ANIME_IDLE,
	ANIME_RUN_LF,
	ANIME_WALK, //ANIME_RUN_F,
	ANIME_RUN_RF,
	ANIME_RUN_L,
	ANIME_RUN_R,
	ANIME_RUN_LB,
	ANIME_RUN_B,
	ANIME_RUN_RB,
	ANIME_DASH_F,
	ANIME_DASH_L,
	ANIME_DASH_R,
	ANIME_DASH_B,
	ANIME_ATTACK_11,
	ANIME_ATTACK_12,
	ANIME_ATTACK_2,
	ANIME_SKILL_ROLLING,
	ANIME_SKILL_ROLLING_END,
	ANIME_SKILL_TENTACLE,
	ANIME_SKILL_POISON,
	ANIME_APPEAR,
	ANIME_DEATH,
	ANIME_SKILL_FINAL,
	ANIME_EVOLUTION
}

enum
{
	STATE_NONE = 0,
	STATE_COMBAT,
	STATE_DEATH
}

const pev_state = pev_iuser1

#define TASK_ATTACK 17110
#define TASK_EFFECT 17111
#define TASK_ROLLING 17112
#define TASK_POISON 17113

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_GiantDione, g_SkillHud
new g_MyGiant[33], g_CanMove, g_Attacking, g_ModelIndex
new g_Exp_SprID, g_Exp2_SprID, g_Rock_SprID, g_MaxPlayers, g_HamReg, m_iBlood[2]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_FILE)
	
	register_think(GIANT_CLASSNAME, "fw_GiantThink")
	register_think("dione_effect", "fw_EffectThink")
	register_touch("dione_poison", "*", "fw_PoisonTouch")
	
	g_SkillHud = CreateHudSyncObj(4)
	g_MaxPlayers = get_maxplayers()
	
	g_GiantDione = zg_register_giantclass(GIANT_BASEHEALTH)
}

public plugin_precache()
{
	g_ModelIndex = precache_model(GIANT_MODEL)
	
	precache_model(DIONE_EF_ATTACK1)
	precache_model(DIONE_EF_ATTACK2)
	precache_model(DIONE_EF_POISON)
	precache_model(DIONE_EF_POISONGROUND)
	
	g_Exp_SprID = precache_model(DIONE_EF_POISONEXP1)
	g_Exp2_SprID = precache_model(DIONE_EF_POISONEXP2)
	g_Rock_SprID = precache_model("models/rockgibs.mdl")
	
	for(new i = 0; i < sizeof(GiantSounds); i++)
		precache_sound(GiantSounds[i])
		
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")
}

public zg_round_new()
{
	remove_entity_name(GIANT_CLASSNAME)
	remove_entity_name("dione_effect")
	remove_entity_name("dione_poison")
	
	for(new i = 0; i < g_MaxPlayers; i++)
		g_MyGiant[i] = 0
}

public zg_become_giant(id, GiantCode, Float:X, Float:Y, Float:Z)
{
	if(GiantCode != g_GiantDione)
		return

	static Float:Origin[3]
	Origin[0] = X; Origin[1] = Y; Origin[2] = Z 
	
	engfunc(EngFunc_SetOrigin, id, Origin)
	Giant_Shift(id)
}

public zg_runningtime()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(!zg_is_giant(i) || zg_get_giantclass(i) != g_GiantDione)
			continue
			
		set_hudmessage(0, 255, 0, SKILL_HUD_X, SKILL_HUD_Y, 0, 1.25, 1.25)
		ShowSyncHudMsg(i, g_SkillHud, "%L", LANG_DEFAULT, "SKILLHUD_DIONE")
	}
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
	if(!zg_is_giant(id) || zg_get_giantclass(id) != g_GiantDione)
		return
		
	// Handle Titan
	if(g_MyGiant[id])
	{
		static Float:EntOrigin[3]
		pev(g_MyGiant[id], pev_origin, EntOrigin)
		
		static Float:Think; pev(g_MyGiant[id], pev_nextthink, Think)
		if(Think >= get_gametime())
		{
			set_pev(id, pev_origin, EntOrigin)
			return
		}

		static Button; Button = get_user_button(id)
		
		if(Button & IN_ATTACK)
		{
			if(!Get_BitVar(g_Attacking, id) && Get_BitVar(g_CanMove, id))
				Attack_Normal(id, 0)
		} else if(Button & IN_ATTACK2) {
			if(!Get_BitVar(g_Attacking, id) && Get_BitVar(g_CanMove, id))
				Attack_Normal(id, 1)
		} else if(Button & IN_USE) {
			if(!Get_BitVar(g_Attacking, id) && Get_BitVar(g_CanMove, id))
				Attack_Rolling(id)
		} else if(Button & IN_RELOAD) {
			if(!Get_BitVar(g_Attacking, id) && Get_BitVar(g_CanMove, id))
				Attack_Poison(id)
		}
		
		if(Button & IN_FORWARD && Get_BitVar(g_CanMove, id))
		{
			static Float:flAngles[3]; pev(id, pev_angles, flAngles)
			static Float:Direction[3];
	
			set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
			
			static Float:ConAngles[3]
			ConAngles[0] = 0.0
			ConAngles[1] = flAngles[1]
			ConAngles[2] = flAngles[2]
			
			if(Button & IN_MOVERIGHT) ConAngles[1] -= 45.0
			if(Button & IN_MOVELEFT) ConAngles[1] += 45.0
	
			set_pev(g_MyGiant[id], pev_angles, ConAngles)
	
			angle_vector(ConAngles, ANGLEVECTOR_FORWARD, Direction)
			xs_vec_mul_scalar(Direction, GIANT_SPEED, Direction)
			
			static Float:NewOrigin[3]
			static Float:Maxs[3], Float:Mins[3]
			pev(g_MyGiant[id], pev_maxs, Maxs)
			pev(g_MyGiant[id], pev_mins, Mins)
	
			for(new Float:iAngle = ConAngles[1] - 60.0; iAngle <= ConAngles[1] + 60.0; iAngle += 10.0)
			{
				for(new Float:i = 0.0; i <= Maxs[0] + 1.0; i += 1.0)
				{
					NewOrigin[0] = floatcos(iAngle, degrees) * i
					NewOrigin[1] = floatsin(iAngle, degrees) * i
					NewOrigin[0] += EntOrigin[0]
					NewOrigin[1] += EntOrigin[1]
					NewOrigin[2] = EntOrigin[2] + Mins[2]
					
					if(PointContents(NewOrigin) == CONTENTS_SOLID && i >= Maxs[0])
					{
						for(new Float:i2 = 0.0; i2 <= 36.0; i2 += 1.0)
						{
							NewOrigin[2] += i2;
							if(PointContents(NewOrigin) != CONTENTS_SOLID)
							{
								NewOrigin[0] = EntOrigin[0]
								NewOrigin[1] = EntOrigin[1]
								NewOrigin[2] += -Mins[2]
								
								set_pev(g_MyGiant[id], pev_origin, NewOrigin)
								
								break;
							} else NewOrigin[ 2 ] -= i2;
						}
						break
					}
				}
			}
	
			static Float:z_speed[3]; pev(g_MyGiant[id], pev_velocity, z_speed)
			Direction[2] = z_speed[2]; set_pev(g_MyGiant[id], pev_velocity, Direction)
	
			if(Get_Animation(g_MyGiant[id]) != ANIME_WALK && !Get_BitVar(g_Attacking, id))
				Play_Animation(g_MyGiant[id], ANIME_WALK, 1.0)

			set_pev(g_MyGiant[id], pev_framerate, 1.0)
		} else if( Button & IN_BACK && Get_BitVar(g_CanMove, id)) {
			static Float:flAngles[3]; pev(id, pev_angles, flAngles)
			static Float:Direction[3];
	
			set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
		
			static Float:ConAngles[3]
			ConAngles[0] = 0.0
			ConAngles[1] = flAngles[1]
			ConAngles[2] = flAngles[2]
			if(Button & IN_MOVERIGHT) ConAngles[1] += 45.0
			if(Button & IN_MOVELEFT) ConAngles[1] -= 45.0
	
			set_pev(g_MyGiant[id], pev_angles, ConAngles)

			angle_vector(ConAngles, ANGLEVECTOR_FORWARD, Direction)
			xs_vec_mul_scalar(Direction, -GIANT_SPEED, Direction)
			
			static Float:NewOrigin[3]
			static Float:Maxs[3], Float:Mins[3]; 
			pev(g_MyGiant[id], pev_maxs, Maxs)
			pev(g_MyGiant[id], pev_mins, Mins)
			
			for(new Float:iAngle = ConAngles[1] - 60.0; iAngle <= ConAngles[1] + 60.0; iAngle += 10.0)
			{
				for(new Float:i = 0.0; i <= Maxs[0] + 1.0; i += 1.0)
				{
					NewOrigin[0] = floatcos(iAngle, degrees) * -i
					NewOrigin[1] = floatsin(iAngle, degrees) * -i
					NewOrigin[0] += EntOrigin[0]
					NewOrigin[1] += EntOrigin[1]
					NewOrigin[2] = EntOrigin[2] + Mins[2]
					
					if(PointContents(NewOrigin) == CONTENTS_SOLID && i >= Maxs[0])
					{
						for(new Float: i2 = 0.0; i2 <= 36.0; i2 += 1.0)
						{
							NewOrigin[2] += i2
							if(PointContents(NewOrigin) != CONTENTS_SOLID)
							{
								NewOrigin[0] = EntOrigin[0]
								NewOrigin[1] = EntOrigin[1]
								NewOrigin[2] += -Mins[2]
								
								set_pev(g_MyGiant[id], pev_origin, NewOrigin)
								break
							} else NewOrigin[2] -= i2
						}
						
						break
					}
				}
			}
	
			static Float: z_speed[3]
			pev(g_MyGiant[id], pev_velocity, z_speed)
			Direction[2] = z_speed[2]
			set_pev(g_MyGiant[id], pev_velocity, Direction)
	
			if(Get_Animation(g_MyGiant[id]) != ANIME_WALK && !Get_BitVar(g_Attacking, id))
				Play_Animation(g_MyGiant[id], ANIME_WALK, 1.0)
			
			set_pev(g_MyGiant[id], pev_framerate, -1.0)
		} else if( Button & IN_MOVERIGHT && Get_BitVar(g_CanMove, id)) {
			static Float:flAngles[3]; pev(id, pev_angles, flAngles)
			static Float:Direction[3]
	
			set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
		
			static Float:ConAngles[3]
			ConAngles[0] = 0.0
			ConAngles[1] = flAngles[1] - 90
			ConAngles[2] = flAngles[2]
	
			set_pev(g_MyGiant[id], pev_angles, ConAngles)
	
			angle_vector(ConAngles, ANGLEVECTOR_FORWARD, Direction)
			xs_vec_mul_scalar(Direction, GIANT_SPEED, Direction)
			
			static Float:NewOrigin[3]
			static Float:Maxs[3], Float:Mins[3]
			pev(g_MyGiant[id], pev_maxs, Maxs)
			pev(g_MyGiant[id], pev_mins, Mins)
	
			for(new Float:iAngle = ConAngles[1] - 60.0; iAngle <= ConAngles[1] + 60.0; iAngle += 10.0)
			{
				for(new Float:i = 0.0; i <= Maxs[0] + 1.0; i += 1.0)
				{
					NewOrigin[0] = floatcos(iAngle, degrees) * i
					NewOrigin[1] = floatsin(iAngle, degrees) * i
					NewOrigin[0] += EntOrigin[0]
					NewOrigin[1] += EntOrigin[1]
					NewOrigin[2] = EntOrigin[2] + Mins[2]
					
					if(PointContents(NewOrigin) == CONTENTS_SOLID && i >= Maxs[0])
					{
						for(new Float: i2 = 0.0; i2 <= 36.0; i2 += 1.0)
						{
							NewOrigin[2] += i2
							if(PointContents(NewOrigin) != CONTENTS_SOLID)
							{
								NewOrigin[0] = EntOrigin[0]
								NewOrigin[1] = EntOrigin[1]
								NewOrigin[2] += -Mins[2]
								
								set_pev(g_MyGiant[id], pev_origin, NewOrigin)
								break
							} else NewOrigin[2] -= i2
						}
						
						break
					}
				}
			}
	
			static Float:z_speed[3]
			pev(g_MyGiant[id], pev_velocity, z_speed)
			Direction[2] = z_speed[2]
			set_pev(g_MyGiant[id], pev_velocity, Direction)
	
			if(Get_Animation(g_MyGiant[id]) != ANIME_WALK && !Get_BitVar(g_Attacking, id))
				Play_Animation(g_MyGiant[id], ANIME_WALK, 1.0)
			
			set_pev(g_MyGiant[id], pev_framerate, 1.0)
		} else if( Button & IN_MOVELEFT && Get_BitVar(g_CanMove, id) ) {
			static Float:flAngles[3]; pev(id, pev_angles, flAngles)
			static Float:Direction[3]; 
			
			set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
		
			static Float:ConAngles[3]
			ConAngles[0] = 0.0
			ConAngles[1] = flAngles[1] + 90
			ConAngles[2] = flAngles[2]
	
			set_pev(g_MyGiant[id], pev_angles, ConAngles)
	
			angle_vector(ConAngles, ANGLEVECTOR_FORWARD, Direction)
			xs_vec_mul_scalar(Direction, GIANT_SPEED, Direction)
			
			static Float:NewOrigin[3]
			static Float:Maxs[3], Float:Mins[3]
			pev(g_MyGiant[id], pev_maxs, Maxs)
			pev(g_MyGiant[id], pev_mins, Mins)
	
			for(new Float:iAngle = ConAngles[1] - 60.0; iAngle <= ConAngles[1] + 60.0; iAngle += 10.0)
			{
				for(new Float:i = 0.0; i <= Maxs[0] + 1.0; i += 1.0)
				{
					NewOrigin[0] = floatcos(iAngle, degrees) * i
					NewOrigin[1] = floatsin(iAngle, degrees) * i
					NewOrigin[0] += EntOrigin[0]
					NewOrigin[1] += EntOrigin[1]
					NewOrigin[2] = EntOrigin[2] + Mins[2]
					if(PointContents(NewOrigin) == CONTENTS_SOLID && i >= Maxs[0])
					{
						for(new Float:i2 = 0.0; i2 <= 36.0; i2 += 1.0)
						{
							NewOrigin[2] += i2
							if(PointContents(NewOrigin) != CONTENTS_SOLID)
							{
								NewOrigin[0] = EntOrigin[0]
								NewOrigin[1] = EntOrigin[1]
								NewOrigin[2] += -Mins[2]
								
								set_pev(g_MyGiant[id], pev_origin, NewOrigin)
								break
							} else NewOrigin[2] -= i2
						}
						
						break
					}
				}
			}
	
			static Float:z_speed[3]
			pev(g_MyGiant[id], pev_velocity, z_speed)
			Direction[2] = z_speed[2]
			
			set_pev(g_MyGiant[id], pev_velocity, Direction)
	
			if(Get_Animation(g_MyGiant[id] ) != ANIME_WALK && !Get_BitVar(g_Attacking, id))
				Play_Animation(g_MyGiant[id], ANIME_WALK, 1.0)
			
			set_pev(g_MyGiant[id], pev_framerate, 1.0)
		} else if( Get_BitVar(g_CanMove, id)) {
			static Float:flAngles[3]; pev(id, pev_angles, flAngles)
		
			static Float:ConAngles[3]
			ConAngles[0] = 0.0
			ConAngles[1] = flAngles[1]
			ConAngles[2] = flAngles[2]
			set_pev(g_MyGiant[id], pev_angles, ConAngles)
	
			if(Get_Animation(g_MyGiant[id]) != ANIME_IDLE  && !Get_BitVar(g_Attacking, id))
			{
				set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_NONE)
				
				Play_Animation(g_MyGiant[id], ANIME_IDLE, 1.0)
				emit_sound(g_MyGiant[id], CHAN_BODY, GiantSounds[9], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
			}
		}
		
		set_pev(g_MyGiant[id], pev_gravity, 1.0)
		set_pev(id, pev_origin, EntOrigin)
	}
}

public fw_GiantThink(Ent)
{
	if(!pev_valid(Ent))
		return
	
	static id; id = pev(Ent, pev_owner)
	if(!is_user_alive(id) && pev(Ent, pev_state) != STATE_DEATH)
	{
		Giant_Death(Ent)
		return
	}
		
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
}

public Giant_Death(Ent)
{
	remove_task(Ent+TASK_ATTACK)
	remove_task(Ent+TASK_EFFECT)
	remove_task(Ent+TASK_ROLLING)
	remove_task(Ent+TASK_POISON)
	
	set_pev(Ent, pev_state, STATE_DEATH)
	
	set_pev(Ent, pev_solid, SOLID_NOT)
	set_pev(Ent, pev_movetype, MOVETYPE_NONE)
	
	set_task(0.1, "Giant_Death2", Ent)
}

public Giant_Death2(Ent)
{
	if(!pev_valid(Ent))
		return
		
	Play_Animation(Ent, ANIME_DEATH, 1.0)
	emit_sound(Ent, CHAN_BODY, GiantSounds[5], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public Attack_Normal(id, Strong)
{
	if(zg_get_mana(id) < MANA_ATTACK)
		return
	
	zg_set_mana(id, zg_get_mana(id) - MANA_ATTACK)
	
	// Setting
	UnSet_BitVar(g_CanMove, id)
	Set_BitVar(g_Attacking, id)
	
	// Start
	//Play_Animation(g_MyGiant[id], ANIME_IDLE, 1.0)
		
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_NONE)
	set_pev(g_MyGiant[id], pev_velocity, {0.0, 0.0, 0.0})	

	remove_task(id+TASK_ATTACK)
	
	if(!Strong) 
	{
		set_task(0.1, "Boss_StartAttackNormalA", id+TASK_ATTACK)
		set_task(0.85, "Boss_StartAttackNormalAA", id+TASK_ATTACK)
		set_task(2.5, "Finish_AttackNormal", id+TASK_ATTACK)
	}
	else set_task(0.1, "Boss_StartAttackNormalB", id+TASK_ATTACK)	
}

public Boss_StartAttackNormalA(id)
{
	id -= TASK_ATTACK
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return

	Play_Animation(g_MyGiant[id], ANIME_ATTACK_11, 1.0)
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[1], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(0.25, "Task_AttackEffect1", id+TASK_EFFECT)
}

public Boss_StartAttackNormalAA(id)
{
	id -= TASK_ATTACK
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	Play_Animation(g_MyGiant[id], ANIME_ATTACK_12, 1.0)
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[2], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(0.25, "Task_AttackEffect2", id+TASK_EFFECT)
}

public Task_AttackEffect1(id)
{
	id -= TASK_EFFECT
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	Check_AttackDamge1(id, g_MyGiant[id])
	Call_AttackEffect(g_MyGiant[id], DIONE_EF_ATTACK1, 0, 0.75)
}

public Task_AttackEffect2(id)
{
	id -= TASK_EFFECT
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	Check_AttackDamge1(id, g_MyGiant[id])
	Call_AttackEffect(g_MyGiant[id], DIONE_EF_ATTACK1, 1, 0.75)
}

public Check_AttackDamge1(id, Ent)
{
	if(!pev_valid(Ent))
		return
	
	static Float:Origin[3]; Get_Position(Ent, 250.0, 0.0, 0.0, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
			
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 240.0)
			continue
		if(cs_get_user_team(id) == cs_get_user_team(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, id, DAMAGE_ATTACK, DMG_SLASH)
		Make_PlayerShake(i)
	}
}

public Boss_StartAttackNormalB(id)
{
	id -= TASK_ATTACK
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	Play_Animation(g_MyGiant[id], ANIME_ATTACK_2, 1.0)
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[3], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(0.1, "Task_AttackEffect3", id+TASK_EFFECT)
	set_task(2.0, "Finish_AttackNormal", id+TASK_ATTACK)
}

public Task_AttackEffect3(id)
{
	id -= TASK_EFFECT
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	Check_AttackDamage2(id, g_MyGiant[id])
	Call_AttackEffect2(g_MyGiant[id], DIONE_EF_ATTACK2, 0, 0.75)
}

public Check_AttackDamage2(id, Ent)
{
	if(!pev_valid(Ent))
		return
	
	static Float:Origin[3]; Get_Position(Ent, 0.0, 0.0, 0.0, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 200.0)
			continue
		if(cs_get_user_team(id) == cs_get_user_team(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, id, DAMAGE_ATTACK * 2.0, DMG_SLASH)
		Make_PlayerShake(i)
	}
}

public Call_AttackEffect(Ent, const Model[], Anim, Float:LifeTime)
{
	static Effect; Effect = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Effect)) return
		
	static Float:Vector[3]
	pev(Ent, pev_origin, Vector); set_pev(Effect, pev_origin, Vector)
	pev(Ent, pev_angles, Vector); set_pev(Effect, pev_angles, Vector)
	
	// Set Config
	set_pev(Effect, pev_classname, "dione_effect")
	engfunc(EngFunc_SetModel, Effect, Model)
		
	set_pev(Effect, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(Effect, pev_aiment, Ent)
	
	//fm_set_rendering(Effect, kRenderFxNone, 100, 100, 100, kRenderTransAdd, 255)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Effect, mins, maxs)
	
	Play_Animation(Effect, Anim, 1.0)
	set_pev(Effect, pev_nextthink, get_gametime() + LifeTime)
}

public Call_AttackEffect2(Ent, const Model[], Anim, Float:LifeTime)
{
	static Effect; Effect = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Effect)) return
		
	static Float:Vector[3]
	pev(Ent, pev_origin, Vector); Vector[2] -= 140.0;set_pev(Effect, pev_origin, Vector)
	pev(Ent, pev_angles, Vector); set_pev(Effect, pev_angles, Vector)
	
	fm_set_rendering(Effect, kRenderFxNone, 100, 100, 100, kRenderTransAdd, 255)
	
	// Set Config
	set_pev(Effect, pev_classname, "dione_effect")
	engfunc(EngFunc_SetModel, Effect, Model)
		
	//set_pev(Effect, pev_movetype, MOVETYPE_FOLLOW)
	//set_pev(Effect, pev_aiment, Ent)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Effect, mins, maxs)
	
	Play_Animation(Effect, Anim, 1.0)
	set_pev(Effect, pev_nextthink, get_gametime() + LifeTime)
}

public Finish_AttackNormal(id)
{
	id -= TASK_ATTACK
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	remove_task(id+TASK_ATTACK)
	
	Set_BitVar(g_CanMove, id)
	UnSet_BitVar(g_Attacking, id)
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
	Play_Animation(g_MyGiant[id], ANIME_IDLE, 1.0)
}

public Attack_Rolling(id)
{
	if(zg_get_mana(id) < MANA_ROLLING)
		return
	
	zg_set_mana(id, zg_get_mana(id) - MANA_ROLLING)
	
	UnSet_BitVar(g_CanMove, id)
	Set_BitVar(g_Attacking, id)
	
	Play_Animation(g_MyGiant[id], ANIME_SKILL_ROLLING, 1.0)
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[12], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	static Float:Target[3];
	Get_Position(g_MyGiant[id], 512.0, 0.0, 0.0, Target)
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
	HookEnt(g_MyGiant[id], Target, 2500.0)
	
	remove_task(id+TASK_ROLLING)
	set_task(0.01, "Task_Rolling", id+TASK_ROLLING, _, _, "b")
	set_task(1.0, "Task_RollingSound", id+TASK_ROLLING, _, _, "b")
	set_task(2.0, "End_Rolling", id+TASK_ROLLING)
}

public Task_Rolling(id)
{
	id -= TASK_ROLLING
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
	{
		remove_task(id+TASK_ROLLING)
		return
	}
		
	static Float:Target[3];
	Get_Position(g_MyGiant[id], 512.0, 0.0, 0.0, Target)
	
	static Float:Origin[3]; pev(g_MyGiant[id], pev_origin, Origin)
	Create_Rock(Origin)
	
	Check_RollingDamge(id, g_MyGiant[id])
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
	HookEnt(g_MyGiant[id], Target, 2000.0)
}

public Check_RollingDamge(id, Ent)
{
	if(!pev_valid(Ent))
		return
	
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 240.0)
			continue
		if(cs_get_user_team(id) == cs_get_user_team(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, id, DAMAGE_ROLLING, DMG_CRUSH)
		Make_PlayerShake(i)
	}
}

public Task_RollingSound(id)
{
	id -= TASK_ROLLING
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
	{
		remove_task(id+TASK_ROLLING)
		return
	}
	
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[12], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public End_Rolling(id)
{
	id -= TASK_ROLLING
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
	{
		remove_task(id+TASK_ROLLING)
		return
	}
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_NONE)
	set_pev(g_MyGiant[id], pev_velocity, {0.0, 0.0, 0.0})	
	
	remove_task(id+TASK_ROLLING)
	Play_Animation(g_MyGiant[id], ANIME_SKILL_ROLLING_END, 1.0)
	emit_sound(g_MyGiant[id], CHAN_BODY, GiantSounds[13], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(1.25, "Complete_Rolling", id+TASK_ROLLING)
}

public Complete_Rolling(id)
{
	id -= TASK_ROLLING
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
	{
		remove_task(id+TASK_ROLLING)
		return
	}
	
	remove_task(id+TASK_ROLLING)
	
	Set_BitVar(g_CanMove, id)
	UnSet_BitVar(g_Attacking, id)
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
	Play_Animation(g_MyGiant[id], ANIME_IDLE, 1.0)
}

public Attack_Poison(id)
{
	if(zg_get_mana(id) < MANA_POISON)
		return
	
	zg_set_mana(id, zg_get_mana(id) - MANA_POISON)
	
	UnSet_BitVar(g_CanMove, id)
	Set_BitVar(g_Attacking, id)
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_NONE)
	set_pev(g_MyGiant[id], pev_velocity, {0.0, 0.0, 0.0})	
	
	remove_task(id+TASK_POISON)
	set_task(0.1, "Start_PoisonAttack", id+TASK_POISON)
}

public Start_PoisonAttack(id)
{
	id -= TASK_POISON
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
	
	Play_Animation(g_MyGiant[id], ANIME_SKILL_POISON, 1.0)
	
	set_task(0.5, "EmitSound_Poison", id+TASK_POISON)
	set_task(0.75, "Emit_Poison", id+TASK_POISON)
	set_task(2.5, "End_Poison", id+TASK_POISON)
}

public EmitSound_Poison(id)
{
	id -= TASK_POISON
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	emit_sound(g_MyGiant[id], CHAN_WEAPON, GiantSounds[11], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
}

public Emit_Poison(id)
{
	id -= TASK_POISON
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
		
	static Float:StartPoint[5][3], Float:Target[5][3]

	Get_Position(g_MyGiant[id], 240.0, 0.0, 100.0, StartPoint[0])
	Get_Position(g_MyGiant[id], 240.0, 0.0, 100.0, StartPoint[1])
	Get_Position(g_MyGiant[id], 240.0, 0.0, 100.0, StartPoint[2])
	Get_Position(g_MyGiant[id], 240.0, 0.0, 100.0, StartPoint[3])
	Get_Position(g_MyGiant[id], 240.0, 0.0, 100.0, StartPoint[4])
	
	Get_Position(g_MyGiant[id], 480.0, -100.0, 0.0, Target[0])
	Get_Position(g_MyGiant[id], 640.0, -50.0, 0.0, Target[1])
	Get_Position(g_MyGiant[id], 640.0, 50.0, 0.0, Target[2])
	Get_Position(g_MyGiant[id], 480.0, 100.0, 0.0, Target[3])
	Get_Position(g_MyGiant[id], 480.0, 50.0, 0.0, Target[4])
	
	for(new i = 0; i < 5; i++) Create_PoisonBall(id, StartPoint[i], Target[i])
}

public Create_PoisonBall(id, Float:Origin[3], Float:Target[3])
{
	static Poison; Poison = create_entity("info_target")

	engfunc(EngFunc_SetOrigin, Poison, Origin)
	Aim_To2(Poison, Target)
	
	set_pev(Poison, pev_classname, "dione_poison")
	engfunc(EngFunc_SetModel, Poison, DIONE_EF_POISON)
	set_pev(Poison, pev_solid, SOLID_TRIGGER)
	set_pev(Poison, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(Poison, pev_owner, id)
	set_pev(Poison, pev_iuser3, 1200)
	
	fm_set_rendering(Poison, kRenderFxGlowShell, 100, 100, 100, kRenderTransAdd, 255)
	
	new Float:maxs[3] = {16.0,16.0,36.0}
	new Float:mins[3] = {-16.0,-16.0,-36.0}
	entity_set_size(Poison, mins, maxs)
	
	HookEnt(Poison, Target, 2000.0)
}

public End_Poison(id)
{
	id -= TASK_POISON
	
	if(!is_user_alive(id) || !pev_valid(g_MyGiant[id]) || pev(g_MyGiant[id], pev_state) == STATE_DEATH)
		return
	
	remove_task(id+TASK_POISON)
	
	Set_BitVar(g_CanMove, id)
	UnSet_BitVar(g_Attacking, id)
	
	set_pev(g_MyGiant[id], pev_movetype, MOVETYPE_PUSHSTEP)
	Play_Animation(g_MyGiant[id], ANIME_IDLE, 1.0)
}

public fw_EffectThink(Ent)
{
	if(!pev_valid(Ent))
		return
	
	set_pev(Ent, pev_flags, FL_KILLME)
}

public fw_PoisonTouch(Ent, Id)
{
	if(!pev_valid(Ent))
		return
	if(pev_valid(Id) && pev(Id, pev_iuser3) == 1200)
		return
		
	static id; id = pev(Ent, pev_owner)
	static Float:Origin[3]; pev(Ent, pev_origin, Origin)
	static Float:Angles[3]; pev(Ent, pev_angles, Angles)
	set_pev(Ent, pev_flags, FL_KILLME)
	
	Create_PoisonZone(id, Origin, Angles)
	Create_PoisonEffect(Origin)
	Check_PoisonDamge(id, Origin)
}

public Check_PoisonDamge(id, Float:Origin[3])
{
	static Float:POrigin[3]
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		pev(i, pev_origin, POrigin)
		if(get_distance_f(Origin, POrigin) > 200.0)
			continue
		if(cs_get_user_team(id) == cs_get_user_team(i))
			continue
			
		ExecuteHamB(Ham_TakeDamage, i, 0, id, DAMAGE_POISON, DMG_POISON)
		Make_PlayerShake(i)
	}
}

public Create_PoisonZone(id, Float:Origin[3], Float:Angles[3])
{
	// Create Ground
	static Effect; Effect = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Effect)) return
		
	set_pev(Effect, pev_origin, Origin)
	Angles[0] = 0.0
	set_pev(Effect, pev_angles, Angles)
	
	// Set Config
	set_pev(Effect, pev_classname, "dione_effect")
	engfunc(EngFunc_SetModel, Effect, DIONE_EF_POISONGROUND)
	
	fm_set_rendering(Effect, kRenderFxNone, 100, 100, 100, kRenderTransAdd, 255)
	
	// Set Size
	new Float:maxs[3] = {1.0, 1.0, 1.0}
	new Float:mins[3] = {-1.0, -1.0, -1.0}
	engfunc(EngFunc_SetSize, Effect, mins, maxs)
	
	drop_to_floor(Effect)
	
	Play_Animation(Effect, 0, 1.0)
	set_pev(Effect, pev_nextthink, get_gametime() + random_float(1.5, 3.0))
}

public Create_PoisonEffect(Float:Origin[3])
{
	// Make Explosion
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord_f(Origin[0])	// start position
	write_coord_f(Origin[1])
	write_coord_f(Origin[2] + 60.0)
	write_short(g_Exp_SprID)	// sprite index
	write_byte(random_num(15, 25))	// scale in 0.1's
	write_byte(random_num(5, 15))	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND)	// flags
	message_end()
	
	// Make Explosion 2
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	write_coord_f(Origin[0])	// start position
	write_coord_f(Origin[1])
	write_coord_f(Origin[2] + 40.0)
	write_short(g_Exp2_SprID)	// sprite index
	write_byte(random_num(25, 35))	// scale in 0.1's
	write_byte(random_num(7, 20))	// framerate
	write_byte(TE_EXPLFLAG_NOSOUND)	// flags
	message_end()
}

public Giant_Target(id)
{
	static Body, Target
	get_user_aiming(id, Target, Body, 99999)
	
	if(is_user_alive(Target)) Giant_Shift(Target)
}

public Giant_Shift(id)
{
	if(!is_user_alive(id) || pev_valid(g_MyGiant[id]))
		return 0
	
	Set_BitVar(g_CanMove, id)
	UnSet_BitVar(g_Attacking, id)
	
	// Titan Shift
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return 0
	
	static Float:Origin[3]; pev(id, pev_origin, Origin); /*Origin[0] += 200.0; */Origin[2] += 120.0
	set_pev(Ent, pev_origin, Origin)
	
	pev(id, pev_v_angle, Origin)
	Origin[0] = 0.0; set_pev(Ent, pev_angles, Origin)
	
	set_pev(Ent, pev_takedamage, DAMAGE_YES)
	set_pev(Ent, pev_health, 10000000.0)

	set_pev(Ent, pev_classname, GIANT_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, GIANT_MODEL)
	set_pev(Ent, pev_modelindex, g_ModelIndex)
	set_pev(Ent, pev_solid, SOLID_SLIDEBOX)

	//set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Ent, pev_gravity, 2.0)
	set_pev(Ent, pev_enemy, 0)
	set_pev(Ent, pev_gamestate, 1)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_state, STATE_COMBAT)
	
	entity_set_byte(Ent, EV_BYTE_controller1, 125)
	entity_set_byte(Ent, EV_BYTE_controller2, 125)
	entity_set_byte(Ent, EV_BYTE_controller3, 125)
	entity_set_byte(Ent, EV_BYTE_controller4, 125)
    
	static Float:Maxs[3], Float:Mins[3]
	Maxs[0] = 140.0;
	Maxs[1] = 140.0;
	Maxs[2] = 100.0
	Mins[0] = -140.0;
	Mins[1] = -140.0;
	Mins[2] = -140.0;
	entity_set_size(Ent, Mins, Maxs)

	Play_Animation(Ent, ANIME_APPEAR)
	
	emit_sound(g_MyGiant[id], CHAN_BODY, GiantSounds[0], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	Create_Rock(Origin)
	
	drop_to_floor(Ent)
	entity_set_float(Ent, EV_FL_nextthink, get_gametime() + 5.5)
	
	if(!g_HamReg)
	{
		g_HamReg = 1
		
		//RegisterHamFromEntity(Ham_TakeDamage, Ent, "fw_BossTakeDamage")
		RegisterHamFromEntity(Ham_TraceAttack, Ent, "fw_BossTraceAttack")
	}
	
	g_MyGiant[id] = Ent
	return Ent
}

public fw_BossTakeDamage(Victim, Inflictor, Attacker, Float:Damage, Damagebits)
{
	if(!pev_valid(Victim) || !pev_valid(Attacker))
		return HAM_IGNORED
	if(pev(Victim, pev_state) == STATE_DEATH)
		return HAM_SUPERCEDE
		
	static Classname[64]; pev(Victim, pev_classname, Classname, 63)
	if(!equal(Classname, GIANT_CLASSNAME))
		return HAM_IGNORED // Target is not a boss
	if(!is_user_alive(Attacker) || cs_get_user_team(Attacker) != CS_TEAM_CT)
		return HAM_IGNORED

	static Owner; Owner = pev(Victim, pev_owner)
	if(!is_user_connected(Owner)) return HAM_IGNORED

	//ExecuteHamB(Ham_TakeDamage, Owner, Inflictor, Attacker, Damage, Damagebits)
	
	return HAM_HANDLED
}

public fw_BossTraceAttack(Ent, Attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!pev_valid(Ent) || !pev_valid(Attacker))
		return HAM_IGNORED
	if(pev(Ent, pev_state) == STATE_DEATH)
		return HAM_SUPERCEDE
     
	static Classname[64]; pev(Ent, pev_classname, Classname, 63)
	if(!equal(Classname, GIANT_CLASSNAME))
		return HAM_IGNORED // Target is not a boss 
	if(!is_user_alive(Attacker) || cs_get_user_team(Attacker) != CS_TEAM_CT)
		return HAM_IGNORED	 
		 
	static Float:EndPos[3] 
	get_tr2(ptr, TR_vecEndPos, EndPos)

	create_blood(EndPos)
	
	static Owner; Owner = pev(Ent, pev_owner)
	if(!is_user_connected(Owner)) return HAM_IGNORED
	
	ExecuteHamB(Ham_TraceAttack, Owner, Attacker, Damage, Dir, ptr, DamageType)
	
	return HAM_IGNORED
}

public create_blood(const Float:origin[3])
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

public Create_Rock(Float:Origin[3])
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 6.0)
	write_coord(random_num(64, 128)); // size x
	write_coord(random_num(64, 128)); // size y
	write_coord(random_num(64, 128)); // size z
	write_coord(random_num(-50, 50)); // velocity x
	write_coord(random_num(-50, 50)); // velocity y
	write_coord(25); // velocity z
	write_byte(10); // random velocity
	write_short(g_Rock_SprID); // model index that you want to break
	write_byte(random_num(25, 50)); // count
	write_byte(50); // life
	write_byte(0x01); // flags: BREAK_GLASS
	message_end(); 
}

public Make_PlayerShake(id)
{
	static MSG; if(!MSG) MSG = get_user_msgid("ScreenShake")
	
	if(!id) 
	{
		message_begin(MSG_BROADCAST, MSG)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, MSG, _, id)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	}
}

public Get_Animation(id) return pev(id, pev_sequence)
stock Play_Animation(index, sequence, Float:framerate = 1.0)
{
	entity_set_float(index, EV_FL_animtime, get_gametime())
	entity_set_float(index, EV_FL_frame, 0.0)
	entity_set_float(index, EV_FL_framerate,  framerate)
	entity_set_int(index, EV_INT_sequence, sequence)
}

stock Get_Position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	if(!pev_valid(ent))
		return
		
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_angles, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock HookEnt(ent, Float:VicOrigin[3], Float:speed)
{
	if(!pev_valid(ent))
		return
	
	static Float:fl_Velocity[3], Float:EntOrigin[3], Float:distance_f, Float:fl_Time
	
	pev(ent, pev_origin, EntOrigin)
	
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	fl_Time = distance_f / speed
		
	fl_Velocity[0] = (VicOrigin[0] - EntOrigin[0]) / fl_Time
	fl_Velocity[1] = (VicOrigin[1] - EntOrigin[1]) / fl_Time
	fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

stock Aim_To2(iEnt, Float:vTargetOrigin[3])
{
	if(!pev_valid(iEnt))	
		return
		
	static Float:Vec[3], Float:Angles[3]
	pev(iEnt, pev_origin, Vec)
	
	Vec[0] = vTargetOrigin[0] - Vec[0]
	Vec[1] = vTargetOrigin[1] - Vec[1]
	Vec[2] = vTargetOrigin[2] - Vec[2]
	engfunc(EngFunc_VecToAngles, Vec, Angles)
	//Angles[0] = Angles[2] = 0.0 
	
	set_pev(iEnt, pev_v_angle, Angles)
	set_pev(iEnt, pev_angles, Angles)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}
