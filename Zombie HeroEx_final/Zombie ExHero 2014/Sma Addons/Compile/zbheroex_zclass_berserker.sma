#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEX] Zombie Class: Berserker"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define BERSERK_COLOR_R 255
#define BERSERK_COLOR_G 3
#define BERSERK_COLOR_B 0

#define HEALTH_DECREASE 500
#define FASTRUN_FOV 105
#define BERSERK_SPEED 375
#define BERSERK_GRAVITY 0.75
#define BERSERK_FRAMERATE 1.5

#define BERSERK_HOST_TIME 5
#define BERSERK_HOST_COOLDOWN 10
#define BERSERK_ORIGIN_TIME 10
#define BERSERK_ORIGIN_COOLDOWN 5

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

// Zombie Configs
new zclass_name[24] = "Berserker"
new zclass_desc[24] = "Berserk"
new const zclass_sex = SEX_MALE
new zclass_lockcost = 0
new const zclass_hostmodel[] = "tank_zombi_host"
new const zclass_originmodel[] = "tank_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_tank_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_tank_zombi.mdl"
new const Float:zclass_gravity = 0.80
new const Float:zclass_speed = 280.0
new const Float:zclass_knockback = 1.0
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

new g_ZombieClass_Berserker, g_CanBerserk, g_Berserking
new g_Msg_Fov, g_synchud1
new const berserk_startsound[] = "zombie_thehero/zombie/skill/zombi_pressure.wav"
new const berserk_sound[2][] =
{
	"zombie_thehero/zombie/skill/zombi_pre_idle_1.wav",
	"zombie_thehero/zombie/skill/zombi_pre_idle_2.wav"
}

#define TASK_BERSERKING 12000
#define TASK_COOLDOWN 12001
#define TASK_BERSERK_SOUND 12002
#define TASK_AURA 12003

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new ReadyWords[16]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "REGULAR_COST")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_REGULAR_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_REGULAR_DESC")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	
	// Register Zombie Class
	g_ZombieClass_Berserker = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	
	zbheroex_set_zombiecode(g_ZombieClass_Berserker, 1912)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, berserk_startsound)
	
	for(new i = 0; i < sizeof(berserk_sound); i++)
		engfunc(EngFunc_PrecacheSound, berserk_sound[i])
}

public zbheroex_user_infected(id, infector, Infection)
{
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return
	
	reset_skill(id, 1)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_ZombieClass_Berserker)
		return	
		
	Set_BitVar(g_CanBerserk, id)
	zbheroex_set_user_time(id, 100)
	
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return
	if(!Get_BitVar(g_CanBerserk, id))
	{
		if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
		return
	}
	
	Do_Berserk(id)
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_ZombieClass_Berserker)
		return	
		
	reset_skill(id, 1)
}

public reset_skill(id, reset_fov)
{
	UnSet_BitVar(g_CanBerserk, id)
	UnSet_BitVar(g_Berserking, id)
	zbheroex_set_user_time(id, 0)
	
	remove_task(id+TASK_BERSERKING)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_BERSERK_SOUND)
	
	if(reset_fov) set_fov(id)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id, 0)
}

public zbheroex_user_died(id) reset_skill(id, 1)
public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_ZombieClass_Berserker)
		return
	if(!Get_BitVar(g_CanBerserk, id) || Get_BitVar(g_Berserking, id))
		return
		
	Do_Berserk(id)
}

public Do_Berserk(id)
{
	if((get_user_health(id) - HEALTH_DECREASE) <= 0)
	{
		client_print(id, print_center, "%L", LANG_OFFICIAL, "ZOMBIE_REGULAR_CANTBERSERK")
		return
	}
	
	// Set Vars
	Set_BitVar(g_Berserking, id)
	UnSet_BitVar(g_CanBerserk, id)
	zbheroex_set_user_time(id, 0)
	
	// Decrease Health & Set Render
	zbheroex_set_user_health(id, get_user_health(id) - HEALTH_DECREASE, 0)
	zbheroex_set_user_rendering(id, kRenderFxGlowShell, BERSERK_COLOR_R, BERSERK_COLOR_G, BERSERK_COLOR_B, kRenderNormal, 0)

	// Set Fov
	set_fov(id, FASTRUN_FOV)
	Effect_RedAura(id+TASK_AURA)
	
	// Set MaxSpeed & Gravity
	set_pev(id, pev_gravity, BERSERK_GRAVITY)
	set_pev(id, pev_framerate, BERSERK_FRAMERATE)
	zbheroex_set_user_speed(id, BERSERK_SPEED)
	
	// Play Berserk Sound
	EmitSound(id, CHAN_VOICE, berserk_startsound)
	
	// Set Task
	set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
	
	static Float:SkillTime
	SkillTime = zbheroex_get_user_level(id) <= 1 ? float(BERSERK_HOST_TIME) : float(BERSERK_ORIGIN_TIME)
	
	set_task(SkillTime, "Remove_Berserk", id+TASK_BERSERKING)
}

public Effect_RedAura(id)
{
	id -= TASK_AURA
	
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return
	if(!Get_BitVar(g_Berserking, id))
		return
		
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
		
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(10) // radius
	write_byte(BERSERK_COLOR_R) // r
	write_byte(BERSERK_COLOR_G) // g
	write_byte(BERSERK_COLOR_B) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
	
	set_task(0.1, "Effect_RedAura", id+TASK_AURA)
}

public Remove_Berserk(id)
{
	id -= TASK_BERSERKING

	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return 
	if(!Get_BitVar(g_Berserking, id))
		return	

	// Set Vars
	UnSet_BitVar(g_Berserking, id)
	UnSet_BitVar(g_CanBerserk, id)
	
	// Reset Rendering
	zbheroex_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 0)
	
	// Reset FOV
	set_fov(id)
	
	// Reset Speed
	zbheroex_set_user_speed(id, floatround(zclass_speed))
	
	// Reset FrameRate
	set_pev(id, pev_framerate, 1.0)
}

public Berserk_HeartBeat(id)
{
	id -= TASK_BERSERK_SOUND
	
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return 
	if(!Get_BitVar(g_Berserking, id))
		return
		
	EmitSound(id, CHAN_VOICE, berserk_sound[random_num(0, charsmax(berserk_sound))])
	set_task(2.0, "Berserk_HeartBeat", id+TASK_BERSERK_SOUND)
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie) return
	if(zbheroex_get_user_zombie_class(id) != g_ZombieClass_Berserker)
		return 	
		
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time+1)

	static Float:percent, percent2
	static Float:timewait, Float:time_remove
	
	if(zbheroex_get_user_level(id) > 1) // Origin
	{
		timewait = float(BERSERK_ORIGIN_COOLDOWN)
		time_remove = float(BERSERK_ORIGIN_TIME)
	} else { // Host
		timewait = float(BERSERK_HOST_COOLDOWN)
		time_remove = float(BERSERK_HOST_TIME)
	}
	
	percent = (float(Time) / (timewait + time_remove)) * 100.0
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
		
		if(!Get_BitVar(g_CanBerserk, id)) Set_BitVar(g_CanBerserk, id)
	}	
	
	if(Get_BitVar(g_Berserking, id) && pev(id, pev_framerate) != BERSERK_FRAMERATE)
		set_pev(id, pev_framerate, BERSERK_FRAMERATE)
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
	static Ent; Ent = = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if(pev_valid(Ent)) set_pdata_float(Ent, 48, TimeIdle, 4)
}

stock set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
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
