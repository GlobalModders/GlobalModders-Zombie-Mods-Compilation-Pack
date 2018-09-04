#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Zombie Class: Deimos"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define SHOCK_DISTANCE_HOST 700
#define SHOCK_DISTANCE_ORIGIN 1500
#define SHOCK_COOLDOWN_HOST 15
#define SHOCK_COOLDOWN_ORIGIN 7

#define SHOCK_CLASSNAME "Speed_Of_Light"
#define SHOCK_FOV 100
#define SHOCK_ANIM 8
#define SHOCK_PLAYERANIM 10
#define SHOCK_STARTTIME 0.75
#define SHOCK_HOLDTIME 1.35
#define SHOCK_VELOCITY 2000

#define TASK_COOLDOWN 12001
#define TASK_SKILLING 12002

// Zombie Configs
new zclass_name[] = "Deimos"
new zclass_desc[] = "Shock"
new const zclass_sex = SEX_MALE
new zclass_lockcost = 5000
new const zclass_hostmodel[] = "deimos3_zombi_host"
new const zclass_originmodel[] = "deimos3_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_deimos_zombi_host.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_deimos_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speed = 280.0
new const Float:zclass_knockback = 0.85
new const DeathSound[2][] =
{
	"zombie_thehero/zombie/zombi_death_1.wav",
	"zombie_thehero/zombie/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombie/zombi_hurt_01.wav",
	"zombie_thehero/zombie/zombi_hurt_02.wav"	
}
new const HealSound[] = "zombie_thehero/zombie/zombi_heal.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution.wav"

new const SkillStart[] = "zombie_thehero/zombie/skill/deimos_skill_start.wav"
new const SkillHit[] = "zombie_thehero/zombie/skill/deimos_skill_hit.wav"
new const SkillExp[] = "zombie_thehero/zombi_bomb_exp.wav"
new const SkillSpr[] = "sprites/zombie_thehero/deimosexp.spr"
new const SkillTrail[] = "sprites/laserbeam.spr"
new const SkillModel[] = "models/zombie_thehero/w_hiddentail.mdl"

new g_SkillSpr_Id, g_SkillTrail_Id
new g_Zombie_Deimos, g_CanShock, g_TempingAttack
new g_synchud1, g_Msg_Fov, g_Msg_Shake, ReadyWords[32]

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	register_think(SHOCK_CLASSNAME, "fw_Shock_Think")
	register_touch(SHOCK_CLASSNAME, "*", "fw_Shock_Touch")
	
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_Msg_Shake = get_user_msgid("ScreenShake")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	// Load Cost & Name & Desc
	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "DEIMOS_COST")
	
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_DEIMOS_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_DEIMOS_DESC")		
	
	// Register Zombie Class
	g_Zombie_Deimos = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	zbheroex_set_zombiecode(g_Zombie_Deimos, 1962)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheModel, SkillModel)
	
	engfunc(EngFunc_PrecacheSound, SkillStart)
	engfunc(EngFunc_PrecacheSound, SkillHit)
	engfunc(EngFunc_PrecacheSound, SkillExp)
	
	g_SkillSpr_Id = engfunc(EngFunc_PrecacheModel, SkillSpr)
	g_SkillTrail_Id = precache_model(SkillTrail)
}

public zbheroex_user_infected(id)
{
	reset_skill(id)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_Zombie_Deimos)
		return
		
	Set_BitVar(g_CanShock, id)
	zbheroex_set_user_time(id, 100)
	
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Deimos)
		return
	if(!Get_BitVar(g_CanShock, id))
	{
		if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
		return
	}
	
	Do_Shock(id)
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_Zombie_Deimos)
		return
		
	reset_skill(id)
}

public reset_skill(id)
{
	UnSet_BitVar(g_CanShock, id)
	UnSet_BitVar(g_TempingAttack, id)
	zbheroex_set_user_time(id, 0)

	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_SKILLING)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id)
}

public zbheroex_user_died(id) reset_skill(id)
public zbheroex_round_new() remove_entity_name(SHOCK_CLASSNAME)

public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_Zombie_Deimos)
		return
	if(!Get_BitVar(g_CanShock, id))
		return

	Do_Skill(id)
}

public Do_Skill(id)
{
	UnSet_BitVar(g_CanShock, id)
	zbheroex_set_user_time(id, 0)
	
	set_weapons_timeidle(id, SHOCK_HOLDTIME)
	set_player_nextattack(id, SHOCK_HOLDTIME)
	
	do_fake_attack(id)
	set_fov(id, SHOCK_FOV)
	set_weapon_anim(id, SHOCK_ANIM)
	set_pev(id, pev_sequence, SHOCK_PLAYERANIM)
	
	EmitSound(id, CHAN_ITEM, SkillStart)

	// Start Attack
	remove_task(id+TASK_SKILLING)
	set_task(SHOCK_STARTTIME, "Do_Shock", id+TASK_SKILLING)
	
	// set_task(zbheroex_get_user_level(id) > 1 ? float(SHOCK_COOLDOWN_ORIGIN) : float(SHOCK_COOLDOWN_HOST), "Remove_Cooldown", id+TASK_COOLDOWN)
}

public Do_Shock(id)
{
	id -= TASK_SKILLING
	
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Deimos)
		return 
		
	UnSet_BitVar(g_CanShock, id)
	set_fov(id)

	// Create Light
	Create_Light(id)
}

public Create_Light(id)
{
	static Float:StartOrigin[3], Float:Velocity[3], Float:Angles[3]
	
	get_position(id, 100.0, 0.0, 10.0, StartOrigin)
	velocity_by_aim(id, SHOCK_VELOCITY, Velocity)
	pev(id, pev_angles, Angles)
	
	// Create Entity
	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return
	
	set_pev(Ent, pev_classname, SHOCK_CLASSNAME)
	engfunc(EngFunc_SetModel, Ent, SkillModel)
	
	set_pev(Ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(Ent, pev_maxs, Float:{1.0, 1.0, 1.0})

	set_pev(Ent, pev_origin, StartOrigin)
	set_pev(Ent, pev_angles, Angles)
	
	set_pev(Ent, pev_movetype, MOVETYPE_FLY)
	set_pev(Ent, pev_gravity, 0.01)
	
	set_pev(Ent, pev_velocity, Velocity)
	set_pev(Ent, pev_owner, id)
	set_pev(Ent, pev_solid, SOLID_BBOX)
	
	Make_TrailEffect(StartOrigin, Ent)

	set_pev(Ent, pev_nextthink, get_gametime() + 0.1)	
}

public fw_Shock_Think(ent)
{
	if(!pev_valid(ent))
		return
	
	static id; id = pev(ent, pev_owner)
	
	if(!is_user_alive(id))
	{
		LightExp(ent, -1)
		return
	}
	
	if(entity_range(id, ent) >= (zbheroex_get_user_level(id) > 1 ? SHOCK_DISTANCE_ORIGIN : SHOCK_DISTANCE_HOST))
	{
		LightExp(ent, -1)
		return
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 0.1)	
}

public fw_Shock_Touch(shock, id)
{
	if (!pev_valid(shock)) 
		return
	
	LightExp(shock, id)
	
	return
}

public LightExp(ent, victim)
{
	if(!pev_valid(ent)) 
		return
	
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	for(new i = 0; i < 3; i++)
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(g_SkillSpr_Id)
		write_byte(40)
		write_byte(30)
		write_byte(14)
		message_end()
	}
	
	if(is_user_alive(victim) && !zbheroex_get_user_zombie(victim) && !zbheroex_get_user_hero(victim))
	{
		static wpnname[64]
		if(!(WPN_NOT_DROP & (1<<get_user_weapon(victim))) && get_weaponname(get_user_weapon(victim), wpnname, charsmax(wpnname)))
		{
			engclient_cmd(victim, "drop", wpnname)
			EmitSound(victim, CHAN_ITEM, SkillHit)
		}

		ScreenShake(victim)
	}
	
	EmitSound(ent, CHAN_BODY, SkillExp)
	engfunc(EngFunc_RemoveEntity, ent)
}

public ScreenShake(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Shake, _, id)
	write_short(255<<14)
	write_short(10<<14)
	write_short(255<<14)
	message_end()
}

public Remove_Cooldown(id)
{
	id -= TASK_COOLDOWN

	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Deimos)
		return 
	if(Get_BitVar(g_CanShock, id))
		return	
		
	Set_BitVar(g_CanShock, id)
	zbheroex_set_user_time(id, 100)
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie)
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_Deimos)
		return 	
	
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time + 1)
	
	static Float:percent, percent2
	static Float:timewait
	
	timewait = zbheroex_get_user_level(id) > 1 ? float(SHOCK_COOLDOWN_ORIGIN) : float(SHOCK_COOLDOWN_HOST)
	
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
		
		if(!Get_BitVar(g_CanShock, id)) Set_BitVar(g_CanShock, id)
	}	
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!zbheroex_get_user_zombie(id))
		return FMRES_IGNORED
	if(!Get_BitVar(g_TempingAttack, id))
		return FMRES_IGNORED
		
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
	
	return FMRES_IGNORED
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

stock EmitSound(id, chan, const file_sound[])
{
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
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
	static entwpn; entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) set_pdata_float(entwpn, 48, TimeIdle + 3.0, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

public do_fake_attack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_TempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
	UnSet_BitVar(g_TempingAttack, id)
}

stock Make_TrailEffect(Float:StartOrigin[3], ent)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMENTPOINT)
	write_short(ent)	// start entity
	engfunc(EngFunc_WriteCoord, StartOrigin[0])
	engfunc(EngFunc_WriteCoord, StartOrigin[1])
	engfunc(EngFunc_WriteCoord, StartOrigin[2])
	write_short(g_SkillTrail_Id)	// sprite index
	write_byte(0)	// starting frame
	write_byte(0)	// frame rate in 0.1's
	write_byte(30)	// life in 0.1's
	write_byte(10)	// line width in 0.1's
	write_byte(0)	// noise amplitude in 0.01's
	write_byte(255)
	write_byte(212)
	write_byte(0)
	write_byte(255)	// brightness
	write_byte(0)	// scroll speed in 0.1's
	message_end()
}

stock set_fov(id, num = 90)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
{
	if(!pev_valid(iIndex))
		return 0
		
	pev(iIndex, pev_v_angle, fViewAngle)
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance
	
	return 1
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

stock get_position(id,Float:forw, Float:right, Float:up, Float:vStart[])
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
