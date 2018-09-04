#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEX] Zombie Class: Sting Finger"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

// Zombie Configs
new zclass_name[24] = "Sting Finger"
new zclass_desc[32] = "Penetrate & Heavenly Jump"
new zclass_desc1[24] = "Penetrate"
new zclass_desc2[24] = "Heavenly Jump"
new const zclass_sex = SEX_FEMALE
new zclass_lockcost = 2500
new const zclass_hostmodel[] = "resident_zombi_host"
new const zclass_originmodel[] = "resident_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_resident_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_resident_zombi.mdl"
new const Float:zclass_gravity = 0.78
new const Float:zclass_speed = 285.0
new const Float:zclass_knockback = 1.5
new const DeathSound[] = "zombie_thehero/zombie/resident_death.wav"
new const HurtSound[2][] = 
{
	"zombie_thehero/zombie/resident_hurt1.wav",
	"zombie_thehero/zombie/resident_hurt2.wav"
}
new const HealSound[] = "zombie_thehero/zombie/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution_female.wav"

#define PENETRATE_SOUND "zombie_thehero/zombie/skill/resident_skill1.wav"
#define HEAVENLYJUMP_SOUND "zombie_thehero/zombie/skill/resident_skill2.wav"

// Penetrate
#define PENETRATE_ANIM 8
#define PENETRATE_PLAYERANIM 91

#define PENETRATE_COOLDOWN_ORIGIN 120
#define PENETRATE_COOLDOWN_HOST 240
#define PENETRATE_DISTANCE 140

// Heavy Jump
#define HEAVENLYJUMP_ANIM 9
#define HEAVENLYJUMP_PLAYERANIM 98
#define HEAVENLYJUMP_FOV 105

#define HEAVENLYJUMP_COOLDOWN_ORIGIN 100
#define HEAVENLYJUMP_COOLDOWN_HOST 200
#define HEAVENLYJUMP_TIME_ORIGIN 10
#define HEAVENLYJUMP_TIME_HOST 5
#define HEAVENLYJUMP_AMOUNT_ORIGIN 0.35
#define HEAVENLYJUMP_AMOUNT_HOST 0.35

#define TASK_HEAVENLYJUMP 312543
#define TASK_HEAVENLYJUMP_START 423423

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_ZombieClass_Resident
new g_CanPenetrate, g_CanHJ, g_HJIng, g_TempingAttack, g_Time[33]
new g_Msg_Fov, g_MaxPlayers, g_synchud1, g_synchud2, ReadyWords[16]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	register_forward(FM_EmitSound, "fw_EmitSound")	
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_MaxPlayers = get_maxplayers()
	
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_synchud2 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "RESIDENT_COST")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_RESIDENT_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_RESIDENT_DESC")
	formatex(zclass_desc1, sizeof(zclass_desc1), "%L", LANG_OFFICIAL, "ZOMBIE_RESIDENT_DESC1")
	formatex(zclass_desc2, sizeof(zclass_desc2), "%L", LANG_OFFICIAL, "ZOMBIE_RESIDENT_DESC2")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	
	// Register Zombie Class
	g_ZombieClass_Resident = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound, DeathSound, HurtSound[0], HurtSound[1], HealSound, EvolSound)
	zbheroex_set_zombiecode(g_ZombieClass_Resident, 1996)
	
	// Precache Sound
	engfunc(EngFunc_PrecacheSound, PENETRATE_SOUND)
	engfunc(EngFunc_PrecacheSound, HEAVENLYJUMP_SOUND)
}

public zbheroex_user_infected(id, infector, Infection)
{
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Resident)
		return
	
	reset_skill(id, 1)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_ZombieClass_Resident)
		return	
		
	Set_BitVar(g_CanPenetrate, id)
	Set_BitVar(g_CanHJ, id)
	UnSet_BitVar(g_TempingAttack, id)
	
	zbheroex_set_user_time(id, 100)
	g_Time[id] = 100
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_ZombieClass_Resident)
		return	
		
	reset_skill(id, 1)
}

public reset_skill(id, reset_fov)
{
	UnSet_BitVar(g_CanPenetrate, id)
	UnSet_BitVar(g_CanHJ, id)
	
	zbheroex_set_user_time(id, 0)
	g_Time[id] = 0
	
	remove_task(id+TASK_HEAVENLYJUMP)
	remove_task(id+TASK_HEAVENLYJUMP_START)
	
	if(reset_fov) set_fov(id)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id, 0)
}

public zbheroex_user_died(id) reset_skill(id, 1)
public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_ZombieClass_Resident)
		return
	if(!Get_BitVar(g_CanPenetrate, id))
		return
		
	Do_Penetrate(id)
}

public Skill2_Handle(id)
{
	if(!Get_BitVar(g_CanHJ, id) || Get_BitVar(g_HJIng, id))
		return
		
	Do_HeavenlyJump(id)
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie) return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Resident)
		return 	
		
	Show_SkillPenetrate(id)
	Show_SkillHJ(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Resident)
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

public Show_SkillPenetrate(id)
{
	static Time; Time = zbheroex_get_user_time(id)
	static Float:percent, percent2
	static Float:timewait
	
	if(zbheroex_get_user_level(id) > 1) 
	{
		if(Time < PENETRATE_COOLDOWN_ORIGIN) zbheroex_set_user_time(id, Time+1)
		timewait = float(PENETRATE_COOLDOWN_ORIGIN)
	} else {
		if(Time < PENETRATE_COOLDOWN_HOST) zbheroex_set_user_time(id, Time+1)
		timewait = float(PENETRATE_COOLDOWN_HOST)
	}
	
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
		
		if(!Get_BitVar(g_CanPenetrate, id)) Set_BitVar(g_CanPenetrate, id)
	}	
	
	if(Get_BitVar(g_CanPenetrate, id)) zbheroex_set_user_time(id, 240)
}

public Show_SkillHJ(id)
{
	static Float:percent, percent2
	static Float:timewait
	
	if(zbheroex_get_user_level(id) > 1) 
	{
		if(g_Time[id] < 240) g_Time[id]++
		timewait = float(HEAVENLYJUMP_COOLDOWN_ORIGIN)
	} else {
		if(g_Time[id] < 120) g_Time[id]++
		timewait = float(HEAVENLYJUMP_COOLDOWN_HOST)
	}
	
	percent = (float(g_Time[id]) / timewait) * 100.0
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
		
		if(!Get_BitVar(g_CanHJ, id)) 
		{
			Set_BitVar(g_CanHJ, id)
			UnSet_BitVar(g_HJIng, id)
		}
	}	
}

public Do_Penetrate(id)
{
	UnSet_BitVar(g_CanPenetrate, id)
	zbheroex_set_user_time(id, 0)

	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 1.5)
	set_player_nextattack(id, 1.5)

	set_weapon_anim(id, PENETRATE_ANIM)
	set_pev(id, pev_sequence, PENETRATE_PLAYERANIM)
	EmitSound(id, CHAN_ITEM, PENETRATE_SOUND)
	
	// Check Penetrate
	Penetrating(id)
}

public Penetrating(id)
{
	#define MAX_POINT 4
	static Float:Max_Distance, Float:Point[MAX_POINT][3], Float:TB_Distance
	
	Max_Distance = float(PENETRATE_DISTANCE)
	TB_Distance = Max_Distance / float(MAX_POINT)
	
	static Float:VicOrigin[3], Float:MyOrigin[3]
	pev(id, pev_origin, MyOrigin)
	
	for(new i = 0; i < MAX_POINT; i++) get_position(id, TB_Distance * (i + 1), 0.0, 0.0, Point[i])
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(zbheroex_get_user_zombie(i))
			continue
		if(entity_range(id, i) > Max_Distance)
			continue
	
		pev(i, pev_origin, VicOrigin)
		if(is_wall_between_points(MyOrigin, VicOrigin, id))
			continue

		if(get_distance_f(VicOrigin, Point[0]) <= 32.0 
		|| get_distance_f(VicOrigin, Point[1]) <= 32.0
		|| get_distance_f(VicOrigin, Point[2]) <= 32.0
		|| get_distance_f(VicOrigin, Point[3]) <= 32.0)
		{
			ExecuteHamB(Ham_TakeDamage, i, fm_get_user_weapon_entity(id, CSW_KNIFE), id, 125.0, DMG_SLASH)
		}

	}	
}

public Do_HeavenlyJump(id)
{
	UnSet_BitVar(g_CanHJ, id)
	Set_BitVar(g_HJIng, id)
	g_Time[id] = 0

	Do_FakeAttack(id)
	
	set_weapons_timeidle(id, 1.5)
	set_player_nextattack(id, 1.5)

	set_weapon_anim(id, HEAVENLYJUMP_ANIM)
	set_pev(id, pev_sequence, HEAVENLYJUMP_PLAYERANIM)
	EmitSound(id, CHAN_ITEM, HEAVENLYJUMP_SOUND)
	
	set_task(1.5, "Start_HeavenlyJump", id+TASK_HEAVENLYJUMP_START)
}

public Start_HeavenlyJump(id)
{
	id -= TASK_HEAVENLYJUMP_START
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_HJIng, id))
		return
		
	set_fov(id, HEAVENLYJUMP_FOV)
	set_pev(id, pev_gravity, zbheroex_get_user_level(id) > 1 ? HEAVENLYJUMP_AMOUNT_ORIGIN : HEAVENLYJUMP_AMOUNT_HOST)
	
	set_task(zbheroex_get_user_level(id) > 1 ? float(HEAVENLYJUMP_TIME_ORIGIN) : float(HEAVENLYJUMP_TIME_HOST), "Stop_HeavenlyJump", id+TASK_HEAVENLYJUMP)
}

public Stop_HeavenlyJump(id)
{
	id -= TASK_HEAVENLYJUMP
	
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
		
	UnSet_BitVar(g_HJIng, id)
	
	set_fov(id)
	set_pev(id, pev_gravity, zclass_gravity)
}

public Do_FakeAttack(id)
{
	static Ent; Ent = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(!pev_valid(Ent)) return
	
	Set_BitVar(g_TempingAttack, id)
	ExecuteHamB(Ham_Weapon_PrimaryAttack, Ent)	
	UnSet_BitVar(g_TempingAttack, id)
}

stock is_wall_between_points(Float:start[3], Float:end[3], ignore_ent)
{
	static ptr
	ptr = create_tr2()

	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, ignore_ent, ptr)
	
	static Float:EndPos[3]
	get_tr2(ptr, TR_vecEndPos, EndPos)

	return floatround(get_distance_f(end, EndPos))
} 

stock set_fov(id, num = 90)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock EmitSound(id, chan, const file_sound[])
{
	if(!is_user_connected(id))
		return
		
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
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
