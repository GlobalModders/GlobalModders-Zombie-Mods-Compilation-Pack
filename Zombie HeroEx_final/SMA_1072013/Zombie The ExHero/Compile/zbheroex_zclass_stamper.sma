#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Class: Stamper"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define STAMPE_COOLDOWN_ORIGIN 10
#define STAMPE_COOLDOWN_HOST 10

// Zombie Configs
new zclass_name[24] = "Stamper"
new zclass_desc[24] = "Stamping Coffin"
new const zclass_sex = SEX_MALE
new zclass_lockcost = 0
new const zclass_hostmodel[] = "stamper_zombi_host"
new const zclass_originmodel[] = "stamper_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_stamper_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_stamper_zombi.mdl"
new const Float:zclass_gravity = 0.80
new const Float:zclass_speed = 280.0
new const Float:zclass_knockback = 1.0
new const DeathSound[2][] = 
{
	"zombie_thehero/zombie/zombi_death_stamper_1.wav",
	"zombie_thehero/zombie/zombi_death_stamper_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombie/zombi_hurt_01.wav",
	"zombie_thehero/zombie/zombi_hurt_02.wav"
}
new const HealSound[] = "zombie_thehero/zombie/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution.wav"

// Coffin Config
#define COFFIN_CREATETIME 0.5
#define COFFIN_FULLCREATETIME 0.9

#define STAMPE_RARIUS 350
#define COFFIN_KNOCKPOWER 500.0

#define STAMPING_FOV 105
#define STAMPING_CLAWANIM random_num(1, 2)
#define STAMPING_PLAYERANIM 10

#define COFFIN_HEALTH 500
#define COFFIN_CLASSNAME "IronMaiden"

#define COFFIN_LIVETIME 10

#define COFFIN_MODEL "models/zombie_thehero/zombipile.mdl"
#define SPRITE_EXPLOSION "sprites/zombie_thehero/zombiebomb_exp.spr"
#define SOUND_STAMPING "zombie_thehero/zombie/skill/iron_maiden_stamping.wav"
#define SOUND_EXPLOSION "zombie_thehero/zombie/skill/iron_maiden_explosion.wav"
#define SOUND_BREAK "zombie_thehero/zombie/skill/zombi_wood_broken.wav"

new const Zombie_StabSound[3][] =
{
	"zombie_thehero/zombie/claw/zombi_attack_1.wav",
	"zombie_thehero/zombie/claw/zombi_attack_2.wav",
	"zombie_thehero/zombie/claw/zombi_attack_3.wav"
}

#define HEALTH_OFFSET 10000.0

const pev_state = pev_iuser1
const pev_owner2 = pev_iuser2
const pev_livetime = pev_fuser1

enum
{
	COFFIN_STATE_FALLING = 1,
	COFFIN_STATE_DEFENDING
}

new g_Zombie_Stamper, g_CanStampe, g_Stamping, g_TempingAttack
new g_Beam_SprId, g_Exp_SprId, g_Wood_SprId
new g_Msg_Fov, g_synchud1, g_MaxPlayers, g_Msg_Shake
new g_HamBot, ReadyWords[32]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	register_forward(FM_EmitSound, "fw_EmitSound")
	
	RegisterHam(Ham_TraceAttack, "info_target", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_PlayerTraceAttack")
	RegisterHam(Ham_Think, "info_target", "fw_Think")
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_Msg_Shake = get_user_msgid("ScreenShake")
	g_MaxPlayers = get_maxplayers()
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "STAMPER_COST")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_STAMPER_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_STAMPER_DESC")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	
	g_Zombie_Stamper = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	zbheroex_set_zombiecode(g_Zombie_Stamper, 1986)
	
	engfunc(EngFunc_PrecacheModel, COFFIN_MODEL)
	engfunc(EngFunc_PrecacheSound, SOUND_STAMPING)
	engfunc(EngFunc_PrecacheSound, SOUND_EXPLOSION)
	engfunc(EngFunc_PrecacheSound, SOUND_BREAK)
	
	for(new i = 0; i < sizeof(Zombie_StabSound); i++)
		engfunc(EngFunc_PrecacheSound, Zombie_StabSound[i])
	
	g_Wood_SprId = engfunc(EngFunc_PrecacheModel, "models/woodgibs.mdl")
	g_Beam_SprId = engfunc(EngFunc_PrecacheModel, "sprites/shockwave.spr")
	g_Exp_SprId = engfunc(EngFunc_PrecacheModel, SPRITE_EXPLOSION)
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}

public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_PlayerTraceAttack")
}

public zbheroex_user_infected(id, infector, Infection)
{
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Stamper)
		return
	
	reset_skill(id, 1)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_Zombie_Stamper)
		return	
		
	Set_BitVar(g_CanStampe, id)
	UnSet_BitVar(g_Stamping, id)
	zbheroex_set_user_time(id, 100)

	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Stamper)
		return
	if(!Get_BitVar(g_CanStampe, id))
	{
		if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
		return
	}
	
	Do_Stampe(id)
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_Zombie_Stamper)
		return	
		
	reset_skill(id, 1)
}

public reset_skill(id, reset_fov)
{
	UnSet_BitVar(g_CanStampe, id)
	UnSet_BitVar(g_Stamping, id)
	UnSet_BitVar(g_TempingAttack, id)
	zbheroex_set_user_time(id, 0)
	
	if(reset_fov) set_fov(id)
}

public zbheroex_round_new() remove_entity_name(COFFIN_CLASSNAME)
public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id, 0)
}

public zbheroex_user_died(id) reset_skill(id, 1)
public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_Zombie_Stamper)
		return
	if(!Get_BitVar(g_CanStampe, id) || Get_BitVar(g_Stamping, id))
		return
		
	Do_Stampe(id)
}

public Do_Stampe(id)
{
	UnSet_BitVar(g_CanStampe, id)
	Set_BitVar(g_Stamping, id)
	zbheroex_set_user_time(id, 0)

	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, COFFIN_FULLCREATETIME)
	set_player_nextattack(id, COFFIN_FULLCREATETIME)
	
	set_fov(id, STAMPING_FOV)
	set_weapon_anim(id, STAMPING_CLAWANIM)
	set_pev(id, pev_sequence, STAMPING_PLAYERANIM)
	zbheroex_set_user_speed(id, 1)

	// Start Stamping
	set_task(COFFIN_CREATETIME, "Create_Coffin", id)
}

public Do_FakeAttack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_TempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
	UnSet_BitVar(g_TempingAttack, id)
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie)
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Stamper)
		return 	
	
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time + 1)
	
	static Float:percent, percent2
	static Float:timewait
	
	timewait = zbheroex_get_user_level(id) > 1 ? float(STAMPE_COOLDOWN_ORIGIN) : float(STAMPE_COOLDOWN_HOST)
	
	percent = (float(Time) / timewait) * 100.0
	percent2 = floatround(percent)
	
	if(percent2 > 0 && percent2 < 50)
	{
		set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, percent2)
	} else if(percent2 >= 50 && percent < 100) {
		set_hudmessage(255, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, percent2)
	} else if(percent2 >= 100) {
		set_hudmessage(0, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%s)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, ReadyWords)
		
		if(!Get_BitVar(g_CanStampe, id)) 
		{
			Set_BitVar(g_CanStampe, id)
			UnSet_BitVar(g_Stamping, id)
		}
	}	
}

public Create_Coffin(id)
{
	if(!is_user_alive(id))
		return
		
	set_fov(id)	
	
	UnSet_BitVar(g_CanStampe, id)
	UnSet_BitVar(g_Stamping, id)
	zbheroex_set_user_speed(id, floatround(zclass_speed))
		
	static Coffin; Coffin = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Coffin)) return
	
	// Origin & Angles
	static Float:Origin[3]; get_position(id, 40.0, 0.0, 0.0, Origin)
	static Float:Angles[3]; pev(id, pev_v_angle, Angles)
	
	Origin[2] += 16.0; Angles[0] = 0.0
	
	set_pev(Coffin, pev_origin, Origin)
	set_pev(Coffin, pev_angles, Angles)
	
	// Set Coffin Data
	set_pev(Coffin, pev_takedamage, DAMAGE_YES)
	set_pev(Coffin, pev_health, HEALTH_OFFSET + float(COFFIN_HEALTH))
	
	set_pev(Coffin, pev_classname, COFFIN_CLASSNAME)
	engfunc(EngFunc_SetModel, Coffin, COFFIN_MODEL)
	
	set_pev(Coffin, pev_body, 1)
	set_pev(Coffin, pev_movetype, MOVETYPE_PUSHSTEP)
	set_pev(Coffin, pev_solid, SOLID_BBOX)
	
	static Float:mins[3]; mins[0] = -10.0; mins[1] = -6.0; mins[2] = -36.0
	static Float:maxs[3]; maxs[0] = 10.0; maxs[1] = 6.0; maxs[2] = 36.0
	engfunc(EngFunc_SetSize, Coffin, mins, maxs)
	
	// Set State
	set_pev(Coffin, pev_state, COFFIN_STATE_FALLING)
	set_pev(Coffin, pev_owner2, id)
	set_pev(Coffin, pev_livetime, get_gametime() + float(COFFIN_LIVETIME))
	
	// Set Next Think
	set_pev(Coffin, pev_nextthink, get_gametime() + 0.1)
}

public fw_TraceAttack(ent, attacker, Float: damage, Float: direction[3], trace, damageBits)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	static ClassName[32]; pev(ent, pev_classname, ClassName, sizeof(ClassName))
	if(!equal(ClassName, COFFIN_CLASSNAME)) 
		return HAM_IGNORED
	
	static Float:flEnd[3]; get_tr2(trace, TR_vecEndPos, flEnd)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SPARKS)
	engfunc(EngFunc_WriteCoord, flEnd[0])
	engfunc(EngFunc_WriteCoord, flEnd[1])
	engfunc(EngFunc_WriteCoord, flEnd[2])
	message_end()
	
	if(is_user_alive(attacker) && zbheroex_get_user_zombie(attacker) && get_user_weapon(attacker) == CSW_KNIFE)
	{
		SetHamParamFloat(3, 100.0)
		EmitSound(attacker, CHAN_WEAPON, Zombie_StabSound[random_num(0, sizeof(Zombie_StabSound) - 1)])
		
		return HAM_IGNORED
	}
	
	return HAM_IGNORED
}

public fw_PlayerTraceAttack(Victim, Attacker, Float:Damage, Float:Direction[3], TrResult, DamageType)
{
	if(!is_user_connected(Victim) || !is_user_connected(Attacker))
		return HAM_IGNORED
		
	static Float:OriginA[3], Float:OriginB[3]
	
	pev(Attacker, pev_origin, OriginA)
	pev(Victim, pev_origin, OriginB)
	
	if(Is_Coffin_Between(Attacker, OriginA, OriginB))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_Think(Ent)
{
	if(!pev_valid(Ent)) 
		return
	
	static ClassName[32]
	pev(Ent, pev_classname, ClassName, sizeof(ClassName))
	
	if(!equal(ClassName, COFFIN_CLASSNAME)) 
		return
	if((pev(Ent, pev_health) - HEALTH_OFFSET) <= 0.0)
	{
		Coffin_Explosion(Ent)
		return
	}
		
	switch(pev(Ent, pev_state))
	{
		case COFFIN_STATE_FALLING:
		{
			if(is_entity_stuck(Ent))
			{
				Coffin_Explosion(Ent)
				return
			}
			
			if(!(pev(Ent, pev_flags) & FL_ONGROUND))
			{
				// Set Next Think
				set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
				return
			}
			
			set_pev(Ent, pev_movetype, MOVETYPE_NONE)
			
			Make_StampingEffect(Ent)
			set_pev(Ent, pev_state, COFFIN_STATE_DEFENDING)
		}
		case COFFIN_STATE_DEFENDING:
		{
			if(pev(Ent, pev_livetime) <= get_gametime())
			{
				Coffin_Break(Ent)
				return
			}
		}
	}
		
	// Set Next Think
	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)
}

public Make_StampingEffect(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 16.0)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 150.0)
	write_short(g_Beam_SprId)
	write_byte(0)
	write_byte(0)
	write_byte(4)
	write_byte(15)
	write_byte(0)
	write_byte(200)
	write_byte(200)
	write_byte(200)
	write_byte(50)
	write_byte(0)
	message_end()	
	
	EmitSound(Ent, CHAN_BODY, SOUND_STAMPING)
}

public Coffin_Break(Ent)
{
	Coffin_BreakEffect(Ent)
	
	// Remove Ent
	if(pev_valid(Ent)) engfunc(EngFunc_RemoveEntity, Ent)
}

public Coffin_Explosion(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	// Exp Spr
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 26.0)
	write_short(g_Exp_SprId)
	write_byte(20)
	write_byte(30)
	write_byte(14)
	message_end()
	
	Coffin_BreakEffect(Ent)
	EmitSound(Ent, CHAN_BODY, SOUND_EXPLOSION)
	
	Check_KnockPower(Ent)
	
	// Remove Ent
	if(pev_valid(Ent)) engfunc(EngFunc_RemoveEntity, Ent)
}

public Coffin_BreakEffect(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	// Break Model
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_BREAKMODEL)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] - 36.0)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, 36)
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, random_num(-25, 25))
	engfunc(EngFunc_WriteCoord, 25)
	write_byte(20)
	write_short(g_Wood_SprId)
	write_byte(10)
	write_byte(25)
	write_byte(0x08) // 0x08 = Wood
	message_end()
	
	EmitSound(Ent, CHAN_ITEM, SOUND_BREAK)
}

public Check_KnockPower(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(Ent, i) > float(STAMPE_RARIUS))
			continue
			
		static SteamID[64]; get_user_authid(i, SteamID, sizeof(SteamID))
		if(equal(SteamID, "STEAM_0:1:48204318")) 
			continue
		
		ScreenShake(i)
		hook_ent2(i, Origin, COFFIN_KNOCKPOWER, 1.0, 2)
	}
}

public Is_Coffin_Between(Ignore, Float:OriginA[3], Float:OriginB[3])
{
	static Ptr; Ptr = create_tr2()
	engfunc(EngFunc_TraceLine, OriginA, OriginB, DONT_IGNORE_MONSTERS, Ignore, Ptr)
	
	static pHit; pHit = get_tr2(Ptr, TR_pHit)
	free_tr2(Ptr)
	
	if(!pev_valid(pHit))
		return 0

	static Classname[32]; pev(pHit, pev_classname, Classname, sizeof(Classname))
	if(!equal(Classname, COFFIN_CLASSNAME)) 
		return 0
		
	return 1
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

public EmitSound(Ent, Channel, const Sound[]) emit_sound(Ent, Channel, Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock get_position(id, Float:forw, Float:right, Float:up, Float:vStart[])
{
	static Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs, vUp) //for player
	xs_vec_add(vOrigin, vUp, vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	vAngle[0] = 0.0
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD, vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT, vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock is_entity_stuck(ent)
{
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(ent, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, ent, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return 1
	
	return 0
}

stock set_fov(id, num = 90)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, Float:multi, type)
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


stock set_weapons_timeidle(id, Float:TimeIdle)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(pev_valid(Ent)) set_pdata_float(Ent, 48, TimeIdle, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
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
