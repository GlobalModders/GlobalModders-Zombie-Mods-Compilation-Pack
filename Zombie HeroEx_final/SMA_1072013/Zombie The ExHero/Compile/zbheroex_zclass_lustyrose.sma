#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Zombie Class: Lusty Rose"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define INVISIBLE_HOST_TIME 10
#define INVISIBLE_HOST_COOLDOWN 20
#define INVISIBLE_HOST_SPEED 210

#define INVISIBLE_ORIGIN_TIME 20
#define INVISIBLE_ORIGIN_COOLDOWN 10
#define INVISIBLE_ORIGIN_SPEED 240

#define INVISIBLE_FOV 100

// Zombie Configs
new zclass_name[] = "Lusty Rose"
new zclass_desc[] = "Invisible"
new const zclass_sex = SEX_FEMALE
new zclass_lockcost = 0
new const zclass_hostmodel[] = "cosspeed1_host"
new const zclass_originmodel[] = "cosspeed1_origin"
new const zclass_clawsmodelhost[] = "v_knife_cosspeed1.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_cosspeed1.mdl"
new const Float:zclass_gravity = 0.7
new const Float:zclass_speed = 295.0
new const Float:zclass_knockback = 2.0
new const DeathSound[2][] =
{
	"zombie_thehero/zombie/zombi_death_female_1.wav",
	"zombie_thehero/zombie/zombi_death_female_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombie/zombi_hurt_female_1.wav",
	"zombie_thehero/zombie/zombi_hurt_female_2.wav"	
}
new const HealSound[] = "zombie_thehero/zombie/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution_female.wav"

// Skill
new const zclass_clawsinvisible[] = "models/zombie_thehero/claw/v_knife_cosspeed1_inv.mdl"
new const Inv_StartSound[] = "zombie_thehero/zombie/skill/zombi_pressure_female.wav"

// Task
#define TASK_INVISIBLE 13000
#define TASK_COOLDOWN 13001

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Var
new g_Zombie_LustyRose, g_CanInvisible, g_Invisibling
new g_Msg_Fov, g_synchud1, ReadyWords[16]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_Item_Deploy_Post", 1)
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "LIGHT_COST")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_SPEED_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_SPEED_DESC")	
	
	// Register Zombie Class
	g_Zombie_LustyRose = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	zbheroex_set_zombiecode(g_Zombie_LustyRose, 1942)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, Inv_StartSound)
	engfunc(EngFunc_PrecacheModel, zclass_clawsinvisible)
}

public zbheroex_user_infected(id)
{
	reset_skill(id, 0)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_Zombie_LustyRose)
		return
		
	Set_BitVar(g_CanInvisible, id)
	zbheroex_set_user_time(id, 100)
	
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_LustyRose)
		return
	if(!Get_BitVar(g_CanInvisible, id))
	{
		if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
		return
	}
	
	Do_Invisible(id)
	if(is_user_bot(id)) set_task(random_float(7.0, 14.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_Zombie_LustyRose)
		return
		
	reset_skill(id, 1)
}

public reset_skill(id, reset_fov)
{
	UnSet_BitVar(g_CanInvisible, id)
	UnSet_BitVar(g_Invisibling, id)
	zbheroex_set_user_time(id, 0)
	
	remove_task(id+TASK_INVISIBLE)
	remove_task(id+TASK_COOLDOWN)
	
	if(reset_fov) set_fov(id)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id, 0)
}

public zbheroex_user_died(id) reset_skill(id, 1)

public fw_Item_Deploy_Post(weapon_ent)
{
	static owner; owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	
	if (!pev_valid(owner))
		return;
	if(!zbheroex_get_user_zombie(owner))
		return
	if(zbheroex_get_user_zombie_class(owner) != g_Zombie_LustyRose)
		return
	if(cs_get_weapon_id(weapon_ent) == CSW_KNIFE && Get_BitVar(g_Invisibling, owner))
		set_pev(owner, pev_viewmodel2, zclass_clawsinvisible)
}

public zbheroex_zombie_skill(id, ClassID)
{
	if(ClassID != g_Zombie_LustyRose)
		return
	if(!Get_BitVar(g_CanInvisible, id) || Get_BitVar(g_Invisibling, id))
		return
	
	Do_Invisible(id)	
}

public Do_Invisible(id)
{
	// Set Vars
	Set_BitVar(g_Invisibling, id)
	UnSet_BitVar(g_CanInvisible, id)
	zbheroex_set_user_time(id, 0)
	
	// Set Render Red
	zbheroex_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 16)

	// Set Fov
	set_fov(id, INVISIBLE_FOV)
	
	// Get Level
	static Level; Level = zbheroex_get_user_level(id)
	
	// Set MaxSpeed & Gravity
	zbheroex_set_user_speed(id, Level > 1 ? INVISIBLE_ORIGIN_SPEED : INVISIBLE_HOST_SPEED)
	
	// Play Berserk Sound
	EmitSound(id, CHAN_ITEM, Inv_StartSound)

	// Set Invisible Claws
	set_pev(id, pev_viewmodel2, zclass_clawsinvisible)
	
	// Set Time
	set_task(Level > 1 ? float(INVISIBLE_ORIGIN_TIME) : float(INVISIBLE_HOST_TIME), "Remove_Invisible", id+TASK_INVISIBLE)
}

public Remove_Invisible(id)
{
	id -= TASK_INVISIBLE

	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_LustyRose)
		return 
	if(!Get_BitVar(g_Invisibling, id))
		return	

	// Set Vars
	UnSet_BitVar(g_Invisibling, id)
	UnSet_BitVar(g_CanInvisible, id)
	
	// Reset Rendering
	zbheroex_set_user_rendering(id, kRenderFxNone, 0, 0, 0, kRenderTransAlpha, 255)
	
	// Reset FOV
	set_fov(id)
	
	// Remove Invisible Claws
	static Claws[128]; formatex(Claws, sizeof(Claws), "models/zombie_thehero/claw/%s", zbheroex_get_user_level(id) > 1 ? zclass_clawsmodelorigin : zclass_clawsmodelhost)
	set_pev(id, pev_viewmodel2, Claws)
	
	// Reset Speed
	zbheroex_set_user_speed(id, floatround(zclass_speed))		
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie)
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_LustyRose)
		return 
		
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time + 1)
	
	static Level; zbheroex_get_user_level(id)
	static Float:percent, percent2

	percent = (float(Time) / ((Level > 1 ? float(INVISIBLE_ORIGIN_COOLDOWN) : float(INVISIBLE_HOST_COOLDOWN)) + (Level > 1 ? float(INVISIBLE_ORIGIN_TIME) : float(INVISIBLE_HOST_TIME)))) * 100.0
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
		
		if(!Get_BitVar(g_CanInvisible, id)) Set_BitVar(g_CanInvisible, id)
	}	
}

stock set_fov(id, num = 90)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
}

stock EmitSound(id, chan, const file_sound[])
{
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// Get Weapon Entity's Owner
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != 2)
		return -1;
	
	return get_pdata_cbase(ent, 41, 4);
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
