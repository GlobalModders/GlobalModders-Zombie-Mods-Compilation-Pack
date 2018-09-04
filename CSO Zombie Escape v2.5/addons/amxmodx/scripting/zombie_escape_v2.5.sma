// Require GameMaster Module and GameMaster Plugin

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <gamemaster>

#define PLUGIN "Zombie Escape"
#define VERSION "2.5"
#define AUTHOR "Dias"

// Main Config 
#define CONFIG_FILE "zombie_escape.ini"
#define OFFICIAL_LANG LANG_PLAYER

//#define SET_MODELINDEX_OFFSET
new allow_map_prefix[1][] = 
{
	"ze_"
}

// Config Vars
new cfg_min_player, cfg_default_light[2], cfg_zom_release_time, cfg_hum_freeze_time, cfg_round_time
new cfg_use_fog, cfg_fog_density[16], cfg_fog_color[32]
new cfg_human_health, cfg_human_armor, Float:cfg_human_gravity, Float:cfg_human_speed	
new cfg_zombie_health, cfg_zombie_armor, Float:cfg_zombie_gravity, Float:cfg_zombie_speed, Float:cfg_zombie_kbpower
new cfg_skyname[10]
new Array:human_model, Array:human_modelindex, Array:host_zombie_model, Array:host_zombie_modelindex, Array:origin_zombie_model, Array:origin_zombie_modelindex, Array:zombie_claws_model
new Array:ready_sound, Array:ambience_sound, Array:zombieappear_sound, Array:zombieinfect_sound
new Array:zombiepain_sound, Array:zombieattack_sound, Array:zombieswing_sound, Array:zombiewall_sound
new count_sound[64], Array:escape_suc_sound, Array:escape_fail_sound

new const sound_nvg[2][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

// Game Vars
new g_endround, g_count, bot_register, g_gamestart, score_hud, Float:delay_hud[33], stat_hud
new notice_hud, g_started, g_zombie[33], g_zombie_type[33], g_nvg[33], g_team_score[6]
new Float:g_spawn_origin[33][3], g_escape_point[33], g_escape_rank[4]
new g_MsgDeathMsg

enum
{
	RANK_NONE = 0,
	RANK_FIRST,
	RANK_SECOND,
	RANK_THIRD
}

// Hardcode
new g_primaryweapons[][][] = 
{ 
	{ "M4A1",     "weapon_m4a1"    },
	{ "AK47",     "weapon_ak47"    },
	{ "AUG",      "weapon_aug"     },
	{ "SG552",    "weapon_sg552"   },
	{ "Galil",    "weapon_galil"   },
	{ "Famas",    "weapon_famas"   },
	{ "MP5 Navy", "weapon_mp5navy" },
	{ "XM1014",   "weapon_xm1014"  },
	{ "M3",       "weapon_m3"      },
	{ "P90",      "weapon_p90"     },
	{ "M249",     "weapon_m249"    },
	{ "SG550",    "weapon_sg550"   },
	{ "G3SG1",    "weapon_g3sg1"   }			
}

// secondary weapons (menu|game)
new g_secondaryweapons[][][] = 
{ 
	{ "USP",      "weapon_usp"     },
	{ "Deagle",   "weapon_deagle"  },
	{ "Elite",    "weapon_elite"   } 
}

// grenade loadout (game)
new g_grenades[][] = 
{ 
	"weapon_hegrenade",
	"weapon_smokegrenade"
}

new g_szObjectiveClassNames[][] =
{
	"func_bomb_target",
	"info_bomb_target",
	"info_vip_start",
	"func_vip_safetyzone",
	"func_escapezone",
	"hostage_entity",
	"monster_scientist",
	"func_hostage_rescue",
	"info_hostage_rescue",
	"item_longjump"
}
enum
{
	TASK_COUNTDOWN = 52000,
	TASK_COUNTDOWN2,
	TASK_AMBIENCE,
	TASK_ROUNDTIME
}
enum
{
	TEAM_T = 1,
	TEAM_CT = 2,
	TEAM_ALL = 5,
	TEAM_START = 6
}
enum
{
	AL_NOT = 0,
	AL_ALIVE = 1,
	AL_BOTH = 2
}
enum
{
	ZOMBIE_TYPE_HOST = 0,
	ZOMBIE_TYPE_ORIGIN
}

new g_WinText[7][64]

// Menu Weapon Code (Thank to Cheap_Suit)
new bool:g_showmenu[33], bool:g_menufailsafe[33], g_player_weapons[33][2], g_menuposition[33]
#define TASKID_WEAPONSMENU 564
#define EQUIP_PRI (1<<0)
#define EQUIP_SEC (1<<1)
#define EQUIP_GREN (1<<2)
#define EQUIP_ALL (1<<0 | 1<<1 | 1<<2)

#define OFFSET_LASTPRIM 368
#define OFFSET_LASTSEC 369
#define OFFSET_LASTKNI 370

#define OFFSET_DEATH 444
#define OFFSET_TEAM 114
#define OFFSET_ARMOR 112
#define OFFSET_NVG 129
#define OFFSET_CSMONEY 115
#define OFFSET_PRIMARYWEAPON 116
#define OFFSET_WEAPONTYPE 43
#define OFFSET_CLIPAMMO	51
#define EXTRAOFFSET_WEAPONS 4

#define OFFSET_AMMO_338MAGNUM 377
#define OFFSET_AMMO_762NATO 378
#define OFFSET_AMMO_556NATOBOX 379
#define OFFSET_AMMO_556NATO 380
#define OFFSET_AMMO_BUCKSHOT 381
#define OFFSET_AMMO_45ACP 382
#define OFFSET_AMMO_57MM 383
#define OFFSET_AMMO_50AE 384
#define OFFSET_AMMO_357SIG 385
#define OFFSET_AMMO_9MM 386

#define fm_lastprimary(%1) get_pdata_cbase(id, OFFSET_LASTPRIM)
#define fm_lastsecondry(%1) get_pdata_cbase(id, OFFSET_LASTSEC)
#define fm_lastknife(%1) get_pdata_cbase(id, OFFSET_LASTKNI)
#define fm_get_weapon_id(%1) get_pdata_int(%1, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)

new const g_weapon_ammo[][] =
{
	{ -1, -1 },
	{ 13, 200 },
	{ -1, -1 },
	{ 10, 200 },
	{ -1, -1 },
	{ 7, 200 },
	{ -1, -1 },
	{ 30, 200 },
	{ 30, 200 },
	{ -1, -1 },
	{ 30, 200 },
	{ 20, 200 },
	{ 25, 000 },
	{ 30, 200 },
	{ 35, 200 },
	{ 25, 200 },
	{ 12, 200 },
	{ 20, 200 },
	{ 10, 200 },
	{ 30, 200 },
	{ 100, 200 },
	{ 8, 200 },
	{ 30, 200 },
	{ 30, 200 },
	{ 20, 200 },
	{ -1, -1 },
	{ 7, 200 },
	{ 30, 200 },
	{ 30, 200 },
	{ -1, -1 },
	{ 50, 200 }
}

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2

// Fowards
#define MAX_FORWARD 5
enum
{
	FORWARD_NONE = 0,
	FORWARD_INFECTED,
	FORWARD_HUMANIZED,
	FORWARD_GAMESTART,
	FORWARD_ROUNDEND
}

new g_forwards[MAX_FORWARD], g_fwDummyResult

// Custom GamePlay
enum
{
	START_TYPE_NEW = 0,
	START_ZOMBIE_APPEAR,
	START_ZOMBIE_RELEASE
}

new g_gamestop[3], g_MaxPlayers

// Player Config
new g_ena_ready_sound[33], g_ena_background_sound[33]

// Plugin & Precache & Config Zone
public plugin_init()
{
	new map_name[32], check_index
	get_mapname(map_name, sizeof(map_name))
	
	for(check_index = 0; check_index < sizeof(allow_map_prefix); check_index++)
	{
		if(equali(map_name, allow_map_prefix[check_index], strlen(allow_map_prefix[check_index])))
			break
	}
	
	if(check_index == sizeof(allow_map_prefix))
	{
		set_fail_state("[ZE] Wrong Map")
		return
	}  
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	GM_EndRound_Block(true)
	
	register_cvar("ze_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("ze_version", VERSION)	
	
	// Lang
	register_dictionary("zombie_escape.txt")
	
	format(g_WinText[TEAM_T], 63, "Escape Fail")
	format(g_WinText[TEAM_CT], 63, "Escape Success")		
	format(g_WinText[TEAM_ALL], 63, "#Round_Draw")
	format(g_WinText[TEAM_START], 63, "#Game_Commencing")	
	
	register_menu("Equipment", 1023, "action_equip")
	register_menu("Primary", 1023, "action_prim")
	register_menu("Secondary", 1023, "action_sec")
	
	// Event
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_logevent("event_roundend", 2, "1=Round_End")
	register_event("TextMsg","event_roundend","a","2=#Game_Commencing","2=#Game_will_restart_in")	
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
	
	// Message
	register_message(get_user_msgid("Health"), "message_health")
	register_message(get_user_msgid("StatusIcon"), "message_StatusIcon")
	
	// Forward & Ham
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")

	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Killed, "player", "fw_Killed_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	
	set_cvar_string("sv_skyname", cfg_skyname)
	
	// Hud
	notice_hud = CreateHudSyncObj(1)
	score_hud = CreateHudSyncObj(2)
	stat_hud = CreateHudSyncObj(3)
	
	// Cache
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	g_MaxPlayers = get_maxplayers()	
	
	// Create Forwards
	g_forwards[FORWARD_INFECTED] = CreateMultiForward("ze_user_infected", ET_IGNORE, FP_CELL, FP_CELL)
	g_forwards[FORWARD_HUMANIZED] = CreateMultiForward("ze_user_humanized", ET_IGNORE, FP_CELL)
	g_forwards[FORWARD_GAMESTART] = CreateMultiForward("ze_gamestart", ET_IGNORE, FP_CELL)
	g_forwards[FORWARD_ROUNDEND] = CreateMultiForward("ze_roundend", ET_IGNORE, FP_CELL)

	// Some Commands
	register_clcmd("nightvision", "cmd_nightvision")
	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("joinclass", "cmd_joinclass")
	register_clcmd("chooseteam", "cmd_jointeam")		
	
	set_task(60.0, "server_check", _, _, _, "b")
	
	// Reset GamePlay
	native_reset_gameplay(0)
}

public plugin_cfg()
{
	new map_name[32], check_index
	get_mapname(map_name, sizeof(map_name))
	
	for(check_index = 0; check_index < sizeof(allow_map_prefix); check_index++)
	{
		if(equali(map_name, allow_map_prefix[check_index], strlen(allow_map_prefix[check_index])))
			break
	}
	
	if(check_index == sizeof(allow_map_prefix))
		return
	
	set_cvar_float("mp_freezetime", float(cfg_hum_freeze_time) + 2.0)
	set_cvar_float("mp_roundtime", float(cfg_round_time))
}
	
public plugin_precache()
{
	new map_name[32], check_index
	get_mapname(map_name, sizeof(map_name))
	
	for(check_index = 0; check_index < sizeof(allow_map_prefix); check_index++)
	{
		if(equali(map_name, allow_map_prefix[check_index], strlen(allow_map_prefix[check_index])))
			break
	}
	
	if(check_index == sizeof(allow_map_prefix))
		return
	
	// Create Array
	human_model = ArrayCreate(64, 1)
	human_modelindex = ArrayCreate(1, 1)
	host_zombie_model = ArrayCreate(64, 1)
	host_zombie_modelindex = ArrayCreate(1, 1)
	origin_zombie_model = ArrayCreate(64, 1)
	origin_zombie_modelindex = ArrayCreate(1, 1)
	zombie_claws_model = ArrayCreate(64, 1)
	
	ready_sound = ArrayCreate(64, 1)
	ambience_sound = ArrayCreate(64, 1)
	zombieappear_sound = ArrayCreate(64, 1)
	zombieinfect_sound = ArrayCreate(64, 1)
	
	zombiepain_sound = ArrayCreate(64, 1)
	zombieattack_sound = ArrayCreate(64, 1)
	zombieswing_sound = ArrayCreate(64, 1)
	zombiewall_sound = ArrayCreate(64, 1)
	
	escape_suc_sound = ArrayCreate(64, 1)
	escape_fail_sound = ArrayCreate(64, 1)
	
	// Load Custom Config
	load_config_file()
	
	new i, buffer[128], temp_string[256]
	
	// Model
	for(i = 0; i < ArraySize(human_model); i++)
	{
		ArrayGetString(human_model, i, temp_string, sizeof(temp_string))
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", temp_string, temp_string)
		
		ArrayPushCell(human_modelindex, precache_model(buffer))
	}
	for(i = 0; i < ArraySize(origin_zombie_model); i++)
	{
		ArrayGetString(origin_zombie_model, i, temp_string, sizeof(temp_string))
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", temp_string, temp_string)
		
		ArrayPushCell(origin_zombie_modelindex, precache_model(buffer))
	}
	for(i = 0; i < ArraySize(host_zombie_model); i++)
	{
		ArrayGetString(host_zombie_model, i, temp_string, sizeof(temp_string))
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", temp_string, temp_string)
		
		ArrayPushCell(host_zombie_modelindex, precache_model(buffer))
	}
	
	for(i = 0; i < ArraySize(zombie_claws_model); i++)
	{
		ArrayGetString(zombie_claws_model, i, temp_string, sizeof(temp_string))
		precache_model(temp_string)
	}
	
	// Sound
	for(i = 0; i < ArraySize(ready_sound); i++)
	{
		ArrayGetString(ready_sound, i, temp_string, sizeof(temp_string))
	
		if(equal(temp_string[strlen(temp_string) - 4], ".mp3"))
		{
			format(buffer, charsmax(buffer), "sound/%s", temp_string)
			precache_generic(buffer)
		} else {
			precache_sound(temp_string)
		}
	}
	for(i = 0; i < ArraySize(ambience_sound); i++)
	{
		ArrayGetString(ambience_sound, i, temp_string, sizeof(temp_string))
	
		if(equal(temp_string[strlen(temp_string) - 4], ".mp3"))
		{
			format(buffer, charsmax(buffer), "sound/%s", temp_string)
			precache_generic(buffer)
		} else {
			precache_sound(temp_string)
		}
	}
	for(i = 0; i < ArraySize(zombieappear_sound); i++)
	{
		ArrayGetString(zombieappear_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(zombieinfect_sound); i++)
	{
		ArrayGetString(zombieinfect_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(zombiepain_sound); i++)
	{
		ArrayGetString(zombiepain_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(zombieattack_sound); i++)
	{
		ArrayGetString(zombieattack_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(zombieswing_sound); i++)
	{
		ArrayGetString(zombieswing_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(zombiewall_sound); i++)
	{
		ArrayGetString(zombiewall_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for (i = 1; i <= 10; i++)
	{
		new sound_count[64]
		format(sound_count, sizeof sound_count - 1, count_sound, i)
		engfunc(EngFunc_PrecacheSound, sound_count)
	}
	for(i = 0; i < ArraySize(escape_suc_sound); i++)
	{
		ArrayGetString(escape_suc_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}
	for(i = 0; i < ArraySize(escape_fail_sound); i++)
	{
		ArrayGetString(escape_fail_sound, i, temp_string, sizeof(temp_string))
		precache_sound(temp_string)
	}		
	
	formatex(buffer, sizeof(buffer), "gfx/env/%sbk.tga", cfg_skyname)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sdn.tga", cfg_skyname)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sft.tga", cfg_skyname)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%slf.tga", cfg_skyname)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%srt.tga", cfg_skyname)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sup.tga", cfg_skyname)
	precache_generic(buffer)	
	
	if(cfg_use_fog == 1)
	{
		static ent
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if(pev_valid(ent))
		{
			DispatchKeyValue(ent, "density", cfg_fog_density)
			DispatchKeyValue(ent, "rendercolor", cfg_fog_color)
			DispatchSpawn(ent)
		}
	}
	
	register_forward(FM_Spawn, "fw_Spawn")	
}

public plugin_end()
{
	GM_EndRound_Block(false)
}

public server_check()
{
	// Check this every 60 second(s)
	check_win_con()
}
	
public fw_Spawn(iEnt)
{
	if (!pev_valid(iEnt))
		return FMRES_IGNORED;
	
	static s_szClassName[32], s_iNum
	pev(iEnt, pev_classname, s_szClassName, 31)
	
	for (s_iNum = 0; s_iNum < sizeof g_szObjectiveClassNames; s_iNum++)
	{
		if (equal(s_szClassName, g_szObjectiveClassNames[s_iNum]))
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED
}

public client_putinserver(id)
{
	if(!bot_register && is_user_bot(id))
	{
		bot_register = 1
		set_task(1.0, "do_register", id)
	}
	
	g_showmenu[id] = true
	g_escape_point[id] = 0
	g_ena_ready_sound[id] = g_ena_background_sound[id] = 1
}

public client_disconnect(id)
{
	check_win_con()
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")	
	RegisterHamFromEntity(Ham_Killed, id, "fw_Killed_Post", 1)
}

public load_config_file()
{
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, CONFIG_FILE)
	
	// File not present
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "[ZE] Can't Load Config File: %s!", path)
		set_fail_state(error)
		return;
	}
	
	// Set up some vars to hold parsing info
	new linedata[1024], key[64], value[960], section
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	while (file && !feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// New section starting
		if (linedata[0] == '[')
		{
			section++
			continue;
		}
	
		// Get key and value(s)
		strtok(linedata, key, charsmax(key), value, charsmax(value), '=')

		// Trim spaces
		trim(key)
		trim(value)

		switch (section)
		{
			case 1: // Main Config
			{	
				if (equal(key, "MIN_PLAYER"))
					cfg_min_player = str_to_num(value)
				else if (equal(key, "DEFAULT_LIGHT"))
					copy(cfg_default_light, sizeof(cfg_default_light), value)
				else if (equal(key, "ZOMBIE_RELEASE_TIME"))
					cfg_zom_release_time = str_to_num(value)
				else if (equal(key, "HUMAN_FREEZE_TIME"))
					cfg_hum_freeze_time = str_to_num(value)
				else if (equal(key, "ROUND_TIME"))
					cfg_round_time = str_to_num(value)					
					
			}
			case 2: // Fog
			{
				if (equal(key, "FOG_ENABLE"))
					cfg_use_fog = str_to_num(value)
				else if (equal(key, "FOG_DENSITY"))
					copy(cfg_fog_density, sizeof(cfg_fog_density), value)
				else if (equal(key, "FOG_COLOR"))
					copy(cfg_fog_color, sizeof(cfg_fog_color), value)		
			}
			case 3: // Human Config
			{
				if (equal(key, "HUMAN_HEALTH"))
					cfg_human_health = str_to_num(value)
				else if (equal(key, "HUMAN_ARMOR"))
					cfg_human_armor = str_to_num(value)
				else if (equal(key, "HUMAN_GRAVITY"))
					cfg_human_gravity = str_to_float(value)
				else if (equal(key, "HUMAN_SPEED"))
					cfg_human_speed = str_to_float(value)				
			}
			case 4: // Zombie Config
			{
				if (equal(key, "ZOMBIE_HEALTH"))
					cfg_zombie_health = str_to_num(value)
				else if (equal(key, "ZOMBIE_ARMOR"))
					cfg_zombie_armor = str_to_num(value)
				else if (equal(key, "ZOMBIE_GRAVITY"))
					cfg_zombie_gravity = str_to_float(value)
				else if (equal(key, "ZOMBIE_SPEED"))
					cfg_zombie_speed = str_to_float(value)	
				else if (equal(key, "ZOMBIE_KNOCKBACK_POWER"))
					cfg_zombie_kbpower = str_to_float(value)						
			}
			case 5: // Sky
			{
				if(equal(key, "SKY_NAME"))
					copy(cfg_skyname, sizeof(cfg_skyname), value)
			}
			case 6: // Model
			{
				if (equal(key, "HUMAN_MODEL"))
				{
					// Parse sounds
					while(value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(human_model, key)
					}
				}
				else if(equal(key, "ZOMBIE_ORIGIN_MODEL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(origin_zombie_model, key)
					}
				}
				else if(equal(key, "ZOMBIE_HOST_MODEL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(host_zombie_model, key)
					}
				}
				else if(equal(key, "ZOMBIE_CLAW_MODEL"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(zombie_claws_model, key)
					}
				}				
			}
			case 7: // Sound
			{
				if (equal(key, "READY"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(ready_sound, key)
					}
				}
				else if (equal(key, "AMBIENCE"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(ambience_sound, key)
					}
				}
				if (equal(key, "ZOMBIE_APPEAR"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombieappear_sound, key)
					}
				}
				else if (equal(key, "PLAYER_INFECT"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombieinfect_sound, key)
					}
				}
				else if (equal(key, "ZOMBIE_PAIN"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombiepain_sound, key)
					}
				}
				else if (equal(key, "COUNTDOWN"))
				{
					copy(count_sound, sizeof(count_sound), value)
				}
				else if (equal(key, "ESCAPE_SUCCESS"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(escape_suc_sound, key)
					}
				}
				else if (equal(key, "ESCAPE_FAIL"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(escape_fail_sound, key)
					}
				}
				else if (equal(key, "ATTACK_HIT"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombieattack_sound, key)
					}
				}
				else if (equal(key, "ATTACK_MISS"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombieswing_sound, key)
					}
				}			
				else if (equal(key, "ATTACK_WALL"))
				{
					// Parse weapons
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to weapons array
						ArrayPushString(zombiewall_sound, key)
					}
				}	
			}
		}
	}
	if (file) fclose(file)	
}

public plugin_natives()
{
	new map_name[32], check_index
	get_mapname(map_name, sizeof(map_name))
	
	for(check_index = 0; check_index < sizeof(allow_map_prefix); check_index++)
	{
		if(equali(map_name, allow_map_prefix[check_index], strlen(allow_map_prefix[check_index])))
			break
	}
	
	if(check_index == sizeof(allow_map_prefix))
		return
		
	// Check
	register_native("ze_is_user_zombie", "native_get_zombie", 1)
	register_native("ze_get_zombie_type", "native_get_zombie_type", 1)
	
	// Set
	register_native("ze_set_user_zombie", "native_set_zombie", 1)
	register_native("ze_set_user_human", "native_set_human", 1)
	
	// GamePlays
	register_native("ze_set_stopgame", "native_set_stopgame", 1)
	register_native("ze_reset_gameplay", "native_reset_gameplay", 1)
}
// End of Plugin & Precache & Config Zone

// Native
public native_get_zombie(id)
{
	if(!is_user_connected(id))
		return 0 
	if(!is_user_alive(id))
		return 0
		
	return g_zombie[id]
}

public native_get_zombie_type(id)
{
	if(!is_user_connected(id))
		return -1
	if(!is_user_alive(id))
		return -1
		
	return g_zombie_type[id]
}

public native_set_zombie(id, zombie_type)
{
	if(!is_user_connected(id))
		return 0 
	if(!is_user_alive(id))
		return 0
	if(g_zombie[id])
		return 0
		
	set_user_zombie(id, zombie_type, 1)
	return 1
}

public native_set_human(id)
{
	if(!is_user_connected(id))
		return 0 
	if(!is_user_alive(id))
		return 0	
		
	set_human_stuff(id)
	return 0
}

public native_set_stopgame(stop_type, stop)
{
	g_gamestop[stop_type] = stop
	return 1
}

public native_reset_gameplay(restart)
{
	g_gamestop[START_TYPE_NEW] = 0
	g_gamestop[START_ZOMBIE_APPEAR] = 0
	g_gamestop[START_ZOMBIE_RELEASE] = 0
	
	if(restart) End_Round(5.0, 1, CS_TEAM_UNASSIGNED)
}
// End Of Native

// Event: New Round
public event_newround()
{
	ExecuteForward(g_forwards[FORWARD_GAMESTART], g_fwDummyResult, g_gamestart)
	
	// Reset Vars
	g_endround = 0
	g_gamestart = 0
	g_count = cfg_hum_freeze_time
	
	// Remove Task
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_COUNTDOWN2)
	remove_task(TASK_ROUNDTIME)
	
	ambience_sound_stop(0)
	
	if(g_gamestop[START_TYPE_NEW])
		return
	
	set_task(0.1, "event_newround2")	
}

public event_newround2()
{
	if(get_player_num(TEAM_ALL, AL_ALIVE) < cfg_min_player)
	{
		client_printc(0, "!g[Zombie Escape]!n %L", OFFICIAL_LANG, "NOT_ENOUGH_PLAYER", cfg_min_player)
		g_started = 0
		
		return
	}
	
	client_printc(0, "!g[Zombie Escape]!n %L", OFFICIAL_LANG, "GOOD_LUCK")
	
	static temp_string[128]
	ArrayGetString(ready_sound, random_num(0, ArraySize(ready_sound) - 1), temp_string, sizeof(temp_string))
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!g_ena_ready_sound[i])
			continue

		PlaySound(i, temp_string)
	}
	
	set_task(1.0, "do_countdown", TASK_COUNTDOWN, _, _, "b")
	set_task(get_cvar_float("mp_roundtime") * 60.0 + 43.0, "do_zombie_win", TASK_ROUNDTIME)	
}

public do_countdown(taskid)
{
	if(g_endround)
	{
		remove_task(taskid)
		return
	}
	
	if (!g_count)
	{
		start_game_now()
		remove_task(taskid)
		return
	}
	
	if (g_count <= cfg_hum_freeze_time)
	{
		static sound[64]
		format(sound, sizeof sound - 1, count_sound, g_count)
		PlaySound(0, sound)
	}
	
	new message[64]
	format(message, charsmax(message), "%L", OFFICIAL_LANG, "RUN_READY_COUNTDOWN", g_count)
	client_print(0, print_center, message)
	
	g_count--
}
// End of Event: New Round

// Event: Round End
public event_roundend()
{
	g_endround = 1
	
	remove_task(TASK_COUNTDOWN)
	remove_task(TASK_COUNTDOWN2)
	for(new i = 0; i < g_MaxPlayers; i++)
		remove_task(i+TASK_AMBIENCE)
	remove_task(TASK_ROUNDTIME)
	
	ambience_sound_stop(0)
}

// End of Event: Round End

public cmd_jointeam(id)
{	
	if(!is_user_connected(id))
		return 1
	
	if(cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T)
	{
		open_game_menu(id)
		return 1
	}
	
	return PLUGIN_CONTINUE
}

public cmd_joinclass(id)
{
	if(!is_user_connected(id))
		return 1
	if(cs_get_user_team(id) != CS_TEAM_CT || cs_get_user_team(id) != CS_TEAM_T)
		return 0
	if(g_gamestart == 1 || g_gamestart == 2)
	{
		GM_Set_PlayerTeam(id, CS_TEAM_CT)
		
		g_zombie[id] = 0
		g_zombie_type[id] = 0
		g_nvg[id] = 0
		g_menufailsafe[id] = false
		
		if(TASKID_WEAPONSMENU + id) remove_task(TASKID_WEAPONSMENU + id)
	}
	
	return 0
}

public open_game_menu(id)
{
	static menu, string[128]
	
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "GAME_MENU_NAME")
	menu = menu_create(string, "gamem_handle")
	
	// Enable Equipment Menu
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "EQUIPMENT_NAME")
	menu_additem(menu, string, "1", 0)
	
	// Game Infomation
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "GAMEINFO_NAME")
	menu_additem(menu, string, "2", 0)
	
	// Game Infomation
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "PCONFIG_NAME")
	menu_additem(menu, string, "3", 0)	
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public gamem_handle(id, menu, item)
{
	if(!is_user_connected(id))
		return
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1: // Equipment
		{
			g_showmenu[id] = true
			client_printc(id, "!g[Zombie Escape]!n %L", OFFICIAL_LANG, "EQUIP_ENABLE")
		}
		case 2: // Game Info
		{
			static string_name[128], string_data[1028]
			
			// Game Infomation
			formatex(string_name, sizeof(string_name), "%L", OFFICIAL_LANG, "GAMEINFO_NAME")
			formatex(string_data, sizeof(string_data), "%L", OFFICIAL_LANG, "GAME_INFORMATION")
			
			show_motd(id, string_data, string_name)
		}	
		case 3: // Player Config
		{
			player_config(id)
		}			
	}
	
	return
}

// Player Config
public player_config(id)
{
	static menu, string[128], on_off[10]
	
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "PCONFIG_NAME")
	menu = menu_create(string, "pconfig_handle")
	
	// Ready Sound
	if(g_ena_ready_sound[id])
	{
		formatex(on_off, sizeof(on_off), "%L", OFFICIAL_LANG, "PCONFIG_ON")
		formatex(string, sizeof(string), "%L	\y%s", OFFICIAL_LANG, "PCONFIG_READY_SOUND", on_off)
	} else {
		formatex(on_off, sizeof(on_off), "%L", OFFICIAL_LANG, "PCONFIG_OFF")
		formatex(string, sizeof(string), "%L	\r%s", OFFICIAL_LANG, "PCONFIG_READY_SOUND", on_off)	
	}
	menu_additem(menu, string, "1", 0)
	
	// Background Sound
	if(g_ena_background_sound[id])
	{
		formatex(on_off, sizeof(on_off), "%L", OFFICIAL_LANG, "PCONFIG_ON")
		formatex(string, sizeof(string), "%L	\y%s", OFFICIAL_LANG, "PCONFIG_BACKGROUND_SOUND", on_off)
	} else {
		formatex(on_off, sizeof(on_off), "%L", OFFICIAL_LANG, "PCONFIG_OFF")
		formatex(string, sizeof(string), "%L	\r%s", OFFICIAL_LANG, "PCONFIG_BACKGROUND_SOUND", on_off)	
	}
	menu_additem(menu, string, "2", 0)
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)	
}

public pconfig_handle(id, menu, item)
{
	if(!is_user_connected(id))
		return
	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return
	}
	
	new data[6], szName[64];
	new access, callback;
	
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback);
	
	new key = str_to_num(data);
	
	switch(key)
	{
		case 1: // Ready Sound
		{
			if(g_ena_ready_sound[id])
			{
				g_ena_ready_sound[id] = 0
				if(g_gamestart == 0) ambience_sound_stop(id)
			} else {
				g_ena_ready_sound[id] = 1
				if(g_gamestart == 0)
				{
					static temp_string[128]
					ArrayGetString(ready_sound, random_num(0, ArraySize(ready_sound) - 1), temp_string, sizeof(temp_string))
					
					PlaySound(id, temp_string)
				}
			}
			player_config(id)
		}
		case 2: // Background Sound
		{
			if(g_ena_background_sound[id])
			{
				g_ena_background_sound[id] = 0
				if(g_gamestart > 0) ambience_sound_stop(id)
			} else {
				g_ena_background_sound[id] = 1
				if(g_gamestart > 0)
				{
					static temp_string[128]
					ArrayGetString(ambience_sound, random_num(0, ArraySize(ambience_sound) - 1), temp_string, sizeof(temp_string))
	
					PlaySound(id, temp_string)	
					set_task(105.0, "check_ambience_sound", id+TASK_AMBIENCE, _, _, "b")	
				}
			}
			player_config(id)			
		}
	}
}

// NightVision
public cmd_nightvision(id)
{
	if (!is_user_alive(id) || !g_zombie[id]) return PLUGIN_HANDLED;
	
	if (!g_nvg[id])
	{
		SwitchNvg(id, 1)
		PlaySound(id, sound_nvg[1])
	}
	else
	{
		SwitchNvg(id, 0)
		PlaySound(id, sound_nvg[0])
	}	
	
	return PLUGIN_CONTINUE
}

public SwitchNvg(id, mode)
{
	if (!is_user_connected(id)) return;
	
	g_nvg[id] = mode
	set_user_nvision(id)
}

public set_user_nvision(id)
{	
	if (!is_user_connected(id)) return;
	
	new alpha
	if (g_nvg[id]) alpha = 70
	else alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	write_byte(253) // r
	write_byte(110) // g
	write_byte(110) // b
	write_byte(alpha) // alpha
	message_end()
	
	if(g_nvg[id])
	{
		set_player_light(id, "z")
		} else {
		set_player_light(id, cfg_default_light)
	}
}

public set_player_light(id, const LightStyle[])
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}
// End of NightVision

// Start Game
public start_game_now()
{
	g_gamestart = 1
	
	static temp_string[128]
	ArrayGetString(ambience_sound, random_num(0, ArraySize(ambience_sound) - 1), temp_string, sizeof(temp_string))
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!g_ena_background_sound[i])
			continue
		
		PlaySound(i, temp_string)	
		set_task(105.0, "check_ambience_sound", i+TASK_AMBIENCE, _, _, "b")
	}
	
	if(g_gamestop[START_ZOMBIE_APPEAR])
	{
		ExecuteForward(g_forwards[FORWARD_GAMESTART], g_fwDummyResult, g_gamestart)
		return
	}
		
	// Make Zombies
	for(new i = 0; i < require_zombie(); i++)
	{
		ExecuteForward(g_forwards[FORWARD_INFECTED], g_fwDummyResult, i, 0)
		set_user_zombie(get_random_player(TEAM_CT, AL_ALIVE), ZOMBIE_TYPE_ORIGIN, 0)
	}
	
	g_count = cfg_zom_release_time
	set_task(1.0, "do_count_rezombie", TASK_COUNTDOWN2, _, _, "b")
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(is_user_connected(i) && is_user_alive(i) && !g_zombie[i])
		{
			GM_Reset_PlayerSpeed(i)
			
			GM_Set_PlayerSpeed(i, cfg_human_speed, 1)
			set_user_gravity(i, cfg_human_gravity)
		}
	}
	
	ExecuteForward(g_forwards[FORWARD_GAMESTART], g_fwDummyResult, g_gamestart)
}

public check_ambience_sound(id)
{
	id -= TASK_AMBIENCE
	
	if(g_endround)
	{
		remove_task(id+TASK_AMBIENCE)
		return
	}
	if(!g_ena_background_sound[id])
	{
		remove_task(id+TASK_AMBIENCE)
		return		
	}
	
	static temp_string[128]
	ArrayGetString(ambience_sound, random_num(0, ArraySize(ambience_sound) - 1), temp_string, sizeof(temp_string))
	
	PlaySound(id, temp_string)	
}

public do_count_rezombie(taskid)
{
	if(g_endround)
	{
		remove_task(taskid)
		return
	}
	
	if (!g_count)
	{
		release_zombie()
		remove_task(taskid)
		return
	}
	
	set_hudmessage(255, 255, 0, -1.0, 0.21, 1, 2.0, 2.0)
	ShowSyncHudMsg(0, notice_hud, "%L", OFFICIAL_LANG, "ZOMBIE_RELEASE_COUNTDOWN", g_count)
	
	g_count--
}
// End of Start Game

// Game Main
public release_zombie()
{
	g_gamestart = 2
	
	if(g_gamestop[START_ZOMBIE_RELEASE])
	{
		ExecuteForward(g_forwards[FORWARD_GAMESTART], g_fwDummyResult, g_gamestart)
		return
	}
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i))
			continue
		if(!g_zombie[i])
			continue
		
		GM_Set_PlayerSpeed(i, cfg_zombie_speed, 1)
		set_user_gravity(i,  cfg_zombie_gravity)		
	}
	
	ExecuteForward(g_forwards[FORWARD_GAMESTART], g_fwDummyResult, g_gamestart)	
}

public client_PostThink(id)
{
	if(!is_user_connected(id))
		return
	if(get_gametime() - 1.0 > delay_hud[id])
	{
		// Show Score
		set_hudmessage(255, 255, 255, -1.0, 0.0, 0, 2.0, 2.0)
		ShowSyncHudMsg(id, score_hud, "%L", OFFICIAL_LANG, "HUD_SCORE", g_team_score[TEAM_T], g_team_score[TEAM_CT])
		
		// Add Point for Who is Running Fast
		if(!g_zombie[id])
		{
			static Float:Velocity[3], Speed
			
			pev(id, pev_velocity, Velocity)
			Speed = floatround(vector_length(Velocity))
			
			switch(Speed)
			{
				case 210..229: g_escape_point[id] += 1
				case 230..249: g_escape_point[id] += 2
				case 250..300: g_escape_point[id] += 3
			}
		}
		
		// Show Stat
		show_stat(id)
		delay_hud[id] = get_gametime()
	}
	if(!g_gamestart)
	{
		if(!is_user_connected(id) || !is_user_alive(id))
			return
		
		if(cs_get_user_team(id) != CS_TEAM_CT) 
		{
			set_human_stuff(id)
		}
	} else {
		if(cs_get_user_team(id) == CS_TEAM_T && !g_zombie[id]) 
		{
			set_human_stuff(id)
		}
	}
}

public show_stat(id)
{
	get_stat()
	new temp_string_first[64], temp_string_second[64], temp_string_third[64], curid, Player_Name[64], none[32]
	
	formatex(none, sizeof(none), "%L", OFFICIAL_LANG, "RANK_NONE")
	
	// Rank First
	curid = g_escape_rank[RANK_FIRST]
	if(is_user_alive(curid) && !g_zombie[curid] && g_escape_point[curid] != 0)
	{
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_first, sizeof(temp_string_first), "%L", OFFICIAL_LANG, "RANK_FIRST", Player_Name)
	} else {
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_first, sizeof(temp_string_first), "%L", OFFICIAL_LANG, "RANK_FIRST", none)	
	}
	
	// Rank Second
	curid = g_escape_rank[RANK_SECOND]
	if(is_user_alive(curid) && !g_zombie[curid] && g_escape_point[curid] != 0)
	{
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_second, sizeof(temp_string_second), "%L", OFFICIAL_LANG, "RANK_SECOND", Player_Name)
	} else {
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_second, sizeof(temp_string_second), "%L", OFFICIAL_LANG, "RANK_SECOND", none)	
	}
	
	// Rank Third
	curid = g_escape_rank[RANK_THIRD]
	if(is_user_alive(curid) && !g_zombie[curid] && g_escape_point[curid] != 0)
	{
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_third, sizeof(temp_string_third), "%L", OFFICIAL_LANG, "RANK_THIRD", Player_Name)
	} else {
		get_user_name(curid, Player_Name, sizeof(Player_Name))
		formatex(temp_string_third, sizeof(temp_string_third), "%L", OFFICIAL_LANG, "RANK_THIRD", none)	
	}	

	set_hudmessage(0, 255, 0, 0.05, 0.30, 0, 2.0, 2.0)
	ShowSyncHudMsg(id, stat_hud, "%L^n%s^n%s^n%s", OFFICIAL_LANG, "RANK_INFO", temp_string_first, temp_string_second, temp_string_third)	
}

public get_stat()
{
	static highest, current
	highest = current = 0
	
	// Rank First
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!is_user_alive(i))
			continue
		if(g_zombie[i])
			continue
			
		if(g_escape_point[i] > highest)
		{
			current = i
			highest = g_escape_point[i]
		}
	}
	g_escape_rank[RANK_FIRST] = current
	
	// Rank Second
	highest = current = 0	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!is_user_alive(i))
			continue
		if(g_zombie[i])
			continue			
		if(g_escape_rank[RANK_FIRST] == i)
			continue
			
		if(g_escape_point[i] > highest)
		{
			current = i
			highest = g_escape_point[i]
		}
	}
	g_escape_rank[RANK_SECOND] = current		
	
	// Rank Third
	highest = current = 0	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!is_user_alive(i))
			continue
		if(g_zombie[i])
			continue			
		if(g_escape_rank[RANK_FIRST] == i || g_escape_rank[RANK_SECOND] == i)
			continue
			
		if(g_escape_point[i] > highest)
		{
			current = i
			highest = g_escape_point[i]
		}
	}
	g_escape_rank[RANK_THIRD] = current	
}

public set_user_zombie(id, zombie_type, forward_exec)
{
	GM_Set_PlayerTeam(id, CS_TEAM_T)
	
	g_zombie[id] = 1
	g_zombie_type[id] = zombie_type
	
	set_user_health(id, zombie_type == 0 ? floatround(float(cfg_zombie_health) / 2.0) : cfg_zombie_health)
	set_user_armor(id, cfg_zombie_armor)
	
	if(zombie_type == ZOMBIE_TYPE_HOST)
	{
		GM_Set_PlayerSpeed(id, cfg_zombie_speed, 1)
		set_user_gravity(id, cfg_zombie_gravity)
	} else {
		if(!forward_exec)
			GM_Set_PlayerSpeed(id, 0.1, 1)
		else
			GM_Set_PlayerSpeed(id, cfg_zombie_speed, 1)
		set_user_gravity(id, cfg_zombie_gravity)		
	}
	
	static temp_string[128], temp_string2[128], random1
	if(!zombie_type) // Host
	{
		random1 = random_num(0, ArraySize(origin_zombie_model) - 1)
		
		ArrayGetString(host_zombie_model, random1, temp_string, sizeof(temp_string))
		GM_Set_PlayerModel(id, temp_string)
		
		#if defined SET_MODELINDEX_OFFSET	
		static modelindex
		
		modelindex = ArrayGetCell(host_zombie_modelindex, random1)
		fm_cs_set_user_model_index(id, modelindex)
		
		#endif	
		} else { // Origin
		random1 = random_num(0, ArraySize(origin_zombie_model) - 1)
		
		ArrayGetString(origin_zombie_model, random1, temp_string, sizeof(temp_string))
		GM_Set_PlayerModel(id, temp_string)	
		
		#if defined SET_MODELINDEX_OFFSET	
		static modelindex
		
		modelindex = ArrayGetCell(origin_zombie_modelindex, random1)
		fm_cs_set_user_model_index(id, modelindex)
		#endif			
	}
	
	set_default_zombie(id, zombie_type)
	
	ArrayGetString(zombieinfect_sound, random_num(0, ArraySize(zombieinfect_sound) - 1), temp_string, sizeof(temp_string))
	ArrayGetString(zombieappear_sound, random_num(0, ArraySize(zombieappear_sound) - 1), temp_string2, sizeof(temp_string2))
	
	emit_sound(id, CHAN_BODY, temp_string, 1.0, ATTN_NORM, 0, PITCH_NORM)
	PlaySound(0, temp_string2)
	
	SwitchNvg(id, 1)
	PlaySound(id, sound_nvg[1])	
	
	check_win_con()
}

stock set_default_zombie(id, zombie_type)
{
	if(!is_user_alive(id))
		return
	if(!g_zombie[id])
		return
	
	// Set Spawn Origin
	if(zombie_type == ZOMBIE_TYPE_ORIGIN) set_pev(id, pev_origin, g_spawn_origin[id])
	
	// Remove any zoom (bugfix)
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	
	// Remove armor
	cs_set_user_armor(id, 0, CS_ARMOR_NONE)
	
	// Drop weapons when infected
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	
	// Strip zombies from guns and give them a knife
	strip_user_weapons(id)
	give_item(id, "weapon_knife")
}

public event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(!g_zombie[id])
		return 1
	if(get_user_weapon(id) != CSW_KNIFE)
	{
		drop_weapons(id, 1)
		drop_weapons(id, 2)
		
		engclient_cmd(id, "weapon_knife")
		} else {
		static temp_string[128]
		ArrayGetString(zombie_claws_model, random_num(0, ArraySize(zombie_claws_model) - 1), temp_string, sizeof(temp_string))
		
		set_pev(id, pev_viewmodel2, temp_string)
		set_pev(id, pev_weaponmodel2, "")
	}
	
	return 0
}

// End of Game Main
public check_win_con()
{
	if(g_endround)
		return
	if(!g_gamestart)
		return
	
	if(get_player_num(TEAM_T, AL_ALIVE) == 0)
	{
		End_Round(5.0, 0, CS_TEAM_CT)
		} else if(get_player_num(TEAM_CT, AL_ALIVE) == 0) {
		End_Round(5.0, 0, CS_TEAM_T)
	}
}

public do_zombie_win()
{
	End_Round(5.0, 0, CS_TEAM_T)
}

// Message
public message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	static szMsg[8];
	get_msg_arg_string(2, szMsg ,7);
	
	if(equal(szMsg, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(msg_entity, 235, get_pdata_int(msg_entity, 235) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public message_health(msg_id, msg_dest, msg_entity)
{
	static health
	health = get_msg_arg_int(1)
	
	if(health > 255)	
		set_msg_arg_int(1, get_msg_argtype(1), 255)
}
// End of Message

// Ham
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	// Block all those unneeeded hostage sounds
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED;
	
	static temp_string[128]
	
	// Zombie being hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't' ||
	sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a' && sample[10] == 'd')
	{
		ArrayGetString(zombiepain_sound, random_num(0, ArraySize(zombiepain_sound) - 1), temp_string, sizeof(temp_string))
		emit_sound(id, channel, temp_string, volume, attn, flags, pitch)
		
		return FMRES_SUPERCEDE;
	}
	
	// Zombie Attack
	new attack_type
	if (equal(sample,"weapons/knife_hitwall1.wav")) attack_type = 1
	else if (equal(sample,"weapons/knife_hit1.wav") ||
	equal(sample,"weapons/knife_hit3.wav") ||
	equal(sample,"weapons/knife_hit2.wav") ||
	equal(sample,"weapons/knife_hit4.wav") ||
	equal(sample,"weapons/knife_stab.wav")) attack_type = 2
	else if(equal(sample,"weapons/knife_slash1.wav") ||
		equal(sample,"weapons/knife_slash2.wav")) attack_type = 3
	if (attack_type)
	{
		if (attack_type == 1)
		{
			ArrayGetString(zombiewall_sound, random_num(0, ArraySize(zombiewall_sound) - 1), temp_string, sizeof(temp_string))
			emit_sound(id, channel, temp_string, volume, attn, flags, pitch)
			} else if (attack_type == 2) {
			ArrayGetString(zombieattack_sound, random_num(0, ArraySize(zombieattack_sound) - 1), temp_string, sizeof(temp_string))
			emit_sound(id, channel, temp_string, volume, attn, flags, pitch)
			} else if (attack_type == 3) {
			ArrayGetString(zombieswing_sound, random_num(0, ArraySize(zombieswing_sound) - 1), temp_string, sizeof(temp_string))
			emit_sound(id, channel, temp_string, volume, attn, flags, pitch)
		}
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_GetGameDesc()
{
	static GameName[64]
	formatex(GameName, sizeof(GameName), "%s %s", PLUGIN, VERSION)
	
	forward_return(FMV_STRING, GameName)
	return FMRES_SUPERCEDE
}

public fw_Spawn_Post(id)
{
	if (get_player_num(TEAM_ALL, AL_ALIVE) > 1 && !g_started)
	{
		g_started = 1
		End_Round(5.0, 1, CS_TEAM_UNASSIGNED)
	}		
	
	if(!is_user_connected(id))
		return HAM_IGNORED
	
	// Get Your Origin
	pev(id, pev_origin, g_spawn_origin[id])
	
	if(g_gamestart)
	{
		set_user_zombie(id, ZOMBIE_TYPE_ORIGIN, g_gamestart == 2 ? 1 : 0)
		return HAM_IGNORED
	}
	
	GM_Set_PlayerTeam(id, CS_TEAM_CT)
	
	g_zombie[id] = 0
	g_zombie_type[id] = 0
	g_nvg[id] = 0
	g_menufailsafe[id] = false
	g_escape_point[id] = 0
	
	if(TASKID_WEAPONSMENU + id) remove_task(TASKID_WEAPONSMENU + id)
	
	set_task(random_float(0.1, 0.5), "set_user_nvision", id)
	set_human_stuff(id)
	
	if(g_showmenu[id])
		display_equipmenu(id)
	else
	{
		equipweapon(id, EQUIP_ALL)
	}
	
	return HAM_HANDLED
}

public display_equipmenu(id)
{
	static menubody[512], len
	len = formatex(menubody, 511, "\y%L^n^n", OFFICIAL_LANG, "WPNMENU_NAME")
	
	static bool:hasweap
	hasweap = ((g_player_weapons[id][0]) != -1 && (g_player_weapons[id][1] != -1)) ? true : false
	
	len += formatex(menubody[len], 511 - len,"\w1. %L^n", OFFICIAL_LANG, "MENU_NEW_WEAPON")
	len += formatex(menubody[len], 511 - len,"\w2. %L^n^n", OFFICIAL_LANG, "MENU_PRE_WEAPON")
	len += formatex(menubody[len], 511 - len,"\w3. %L^n^n", OFFICIAL_LANG, "MENU_PRE_DONTSHOW")
	len += formatex(menubody[len], 511 - len,"\w5. %L^n", OFFICIAL_LANG, "MENU_EXIT")
	
	static keys
	keys = (MENU_KEY_1|MENU_KEY_5)
	
	if(hasweap) 
		keys |= (MENU_KEY_2|MENU_KEY_3)
	
	static string[128]
	formatex(string, sizeof(string), "%L", OFFICIAL_LANG, "EQUIPMENT_NAME")
	
	show_menu(id, keys, menubody, -1, string)
}

public action_equip(id, key)
{
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	switch(key)
	{
		case 0: display_weaponmenu(id, 1, g_menuposition[id] = 0)
			case 1: equipweapon(id, EQUIP_ALL)
			case 2:
		{
			g_showmenu[id] = false
			equipweapon(id, EQUIP_ALL)
			client_printc(id, "!g[Zombie Escape]!n %L", OFFICIAL_LANG, "HOW_ENA_EQUIPMENU")
		}
	}
	
	if(key > 0)
	{
		g_menufailsafe[id] = false
		remove_task(TASKID_WEAPONSMENU + id)
	}
	return PLUGIN_HANDLED
}


public display_weaponmenu(id, menuid, pos)
{
	if(pos < 0 || menuid < 0)
		return
	
	static start
	start = pos * 8
	
	static maxitem
	maxitem = menuid == 1 ? sizeof g_primaryweapons : sizeof g_secondaryweapons
	
	if(start >= maxitem)
		start = pos = g_menuposition[id]
	
	static menubody[512], len, primary[64], secondary[64]
	
	formatex(primary, sizeof(primary), "%L", OFFICIAL_LANG, "WPN_PRIMARY")
	formatex(secondary, sizeof(secondary), "%L", OFFICIAL_LANG, "WPN_SECONDARY")
	
	len = formatex(menubody, 511, "\y%s\w^n^n", menuid == 1 ? primary : secondary)
	
	static end
	end = start + 8
	if(end > maxitem)
		end = maxitem
	
	static keys
	keys = MENU_KEY_0
	
	static a, b
	b = 0
	
	static string_next[32], string_back[32], string_exit[32]
	
	formatex(string_next, sizeof(string_next), "%L", OFFICIAL_LANG, "MENU_NEXT")
	formatex(string_back, sizeof(string_back), "%L", OFFICIAL_LANG, "MENU_BACK")
	formatex(string_exit, sizeof(string_exit), "%L", OFFICIAL_LANG, "MENU_EXIT")
	
	for(a = start; a < end; ++a) 
	{
		keys |= (1<<b)
		len += formatex(menubody[len], 511 - len,"%d. %s^n", ++b, menuid == 1 ? g_primaryweapons[a][0]: g_secondaryweapons[a][0])
	}
	
	if(end != maxitem)
	{
		formatex(menubody[len], 511 - len, "^n9. %s^n0. %s", string_next, pos ? string_back : string_exit)
		keys |= MENU_KEY_9
	}
	else	
		formatex(menubody[len], 511 - len, "^n0. %s", pos ? string_back : string_exit)
	
	show_menu(id, keys, menubody, -1, menuid == 1 ? primary : secondary)
}

public action_prim(id, key)
{
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	switch(key)
	{
		case 8: display_weaponmenu(id, 1, ++g_menuposition[id])
		case 9: display_weaponmenu(id, 1, --g_menuposition[id])
		default:
		{
			g_player_weapons[id][0] = g_menuposition[id] * 8 + key
			equipweapon(id, EQUIP_PRI)
			
			display_weaponmenu(id, 2, g_menuposition[id] = 0)
		}
	}
	return PLUGIN_HANDLED
}

public action_sec(id, key)
{
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
		
	switch(key) 
	{
		case 8: display_weaponmenu(id, 2, ++g_menuposition[id])
		case 9: display_weaponmenu(id, 2, --g_menuposition[id])
		default:
		{
			g_menufailsafe[id] = false
			remove_task(TASKID_WEAPONSMENU + id)
			
			g_player_weapons[id][1] = g_menuposition[id] * 8 + key
			equipweapon(id, EQUIP_SEC)
			equipweapon(id, EQUIP_GREN)
		}
	}
	return PLUGIN_HANDLED
}

public set_human_stuff(id)
{
	GM_Set_PlayerTeam(id, CS_TEAM_CT)
	
	g_zombie[id] = 0
	g_zombie_type[id] = 0
	
	set_user_health(id, cfg_human_health)
	set_user_armor(id, cfg_human_armor)
	set_task(random_float(0.1, 0.2), "do_set_human_model", id)
	
	if(g_gamestart < 1)
	{
		GM_Set_PlayerSpeed(id, 0.1, 1)
	} else {
		GM_Set_PlayerSpeed(id, cfg_human_speed, 1)
	}
	
	ExecuteForward(g_forwards[FORWARD_HUMANIZED], g_fwDummyResult, id)
}

public do_set_human_model(id)
{
	static model[128], random1
	
	random1 = random_num(0, ArraySize(human_model) - 1)
	ArrayGetString(human_model, random1, model, sizeof(model))
	
	GM_Set_PlayerModel(id, model)	
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(g_gamestart < 2)
		return HAM_SUPERCEDE
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	if(!g_zombie[victim] && !g_zombie[attacker])
		return HAM_SUPERCEDE
	if(g_zombie[victim] && g_zombie[attacker])
		return HAM_SUPERCEDE		
	if(g_zombie[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
	{
		if(damagebits == DMG_GRENADE)
			return HAM_SUPERCEDE
		
		message_begin(MSG_BROADCAST, g_MsgDeathMsg)
		write_byte(attacker) // killer
		write_byte(victim) // victim
		write_byte(0) // headshot flag
		write_string("knife") // killer's weapon
		message_end()
		
		FixDeadAttrib(victim)
		
		update_frags(attacker, 1)
		update_deaths(victim, 1)
		
		set_user_zombie(victim, ZOMBIE_TYPE_HOST, 0)
		ExecuteForward(g_forwards[FORWARD_INFECTED], g_fwDummyResult, victim, attacker)
	} else if(g_zombie[victim] && !g_zombie[attacker]) {
		set_pdata_float(victim, 108, 1.0, 50)
		
		static Float:MyOrigin[3]
		pev(attacker, pev_origin, MyOrigin)
		
		hook_ent2(victim, MyOrigin, cfg_zombie_kbpower, 2)
	}
	
	return HAM_HANDLED
}

public update_frags(id, frag)
{
	if(!is_user_connected(id))
		return
	
	set_pev(id, pev_frags, float(pev(id, pev_frags) + frag))
	
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	write_byte(id) // id
	write_short(pev(id, pev_frags)) // frags
	write_short(cs_get_user_deaths(id)) // deaths
	write_short(0) // class?
	write_short(get_pdata_int(id, 114, 5)) // team
	message_end()
}

public update_deaths(id, death)
{
	if(!is_user_connected(id))
		return
	
	cs_set_user_deaths(id, cs_get_user_deaths(id) + death)
	
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
	write_byte(id) // id
	write_short(pev(id, pev_frags)) // frags
	write_short(cs_get_user_deaths(id)) // deaths
	write_short(0) // class?
	write_short(get_pdata_int(id, 114, 5)) // team
	message_end()		
}

public fw_Killed_Post(id)
{
	check_win_con()
}

public fw_PlayerResetMaxSpeed(id)
{
	if(!g_zombie[id])
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}

public fw_TouchWeapon(weapon, id)
{
	// Not a player
	if (!is_user_connected(id))
		return HAM_IGNORED
	if (g_zombie[id])
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}
// End of Ham

// Ambience Sounds Stop Task
public ambience_sound_stop(id)
{
	if(id == 0)
	{
		client_cmd(0, "mp3 stop; stopsound")
	} else {
		if(!is_user_connected(id))
			return
			
		client_cmd(id, "mp3 stop; stopsound")
	}
}

// ============================ STOCK =================================
stock get_player_num(team, alive)
{
	static player_num
	player_num = 0
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(alive == AL_NOT)
		{
			if(is_user_alive(i))
				continue
			} else if(alive == AL_ALIVE) {
			if(!is_user_alive(i))
				continue	
		}
		
		if(team == TEAM_ALL)
		{
			if(cs_get_user_team(i) == CS_TEAM_UNASSIGNED || cs_get_user_team(i) == CS_TEAM_SPECTATOR)
				continue
			} else if(team == TEAM_T) {
			if(cs_get_user_team(i) != CS_TEAM_T)
				continue
			} else if(team == TEAM_CT) {
			if(cs_get_user_team(i) != CS_TEAM_CT)
				continue
		}
		
		player_num++
	}
	
	return player_num
}

stock get_random_player(team, alive)
{
	static list_player[33], list_player_num
	static total_player
	total_player = get_player_num(team, alive)
	
	for(new i = 0; i < total_player; i++)
		list_player[i] = 0
	
	list_player_num = 0
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		
		if(alive == AL_NOT)
		{
			if(is_user_alive(i))
				continue
			} else if(alive == AL_ALIVE) {
			if(!is_user_alive(i))
				continue	
		}
		
		if(team == TEAM_ALL)
		{
			if(cs_get_user_team(i) == CS_TEAM_UNASSIGNED || cs_get_user_team(i) == CS_TEAM_SPECTATOR)
				continue
			} else if(team == TEAM_T) {
			if(cs_get_user_team(i) != CS_TEAM_T)
				continue
			} else if(team == TEAM_CT) {
			if(cs_get_user_team(i) != CS_TEAM_CT)
				continue
		}
		
		list_player[list_player_num] = i
		list_player_num++
	}
	
	static random_player; random_player = 0
	random_player = list_player[random_num(0, list_player_num - 1)]
	
	return random_player
}

stock PlaySound(id, const sound[])
{
	if(id == 0)
	{
		if (equal(sound[strlen(sound)-4], ".mp3"))
			client_cmd(0, "mp3 play ^"sound/%s^"", sound)
		else
			client_cmd(0, "spk ^"%s^"", sound)
		} else {
		if(is_user_connected(id)&& is_user_alive(id))
		{
			if (equal(sound[strlen(sound)-4], ".mp3"))
				client_cmd(id, "mp3 play ^"sound/%s^"", sound)
			else
				client_cmd(id, "spk ^"%s^"", sound)			
		}
	}
}

stock client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);
	
	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");
	
	if(index == 0)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(is_user_alive(i) && is_user_connected(i))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i);
				write_byte(i);
				write_string(szMsg);
				message_end();	
			}
		}		
		} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

stock require_zombie()
{
	switch(get_player_num(TEAM_CT, 1))
	{
		case 2..5: return 1
			case 6..15: return 2
			case 16..25: return 3
			case 26..32: return 4
		}
	
	return 0
}

stock check_spawn(Float:Origin[3])
{
	new Float:originE[3], Float:origin1[3], Float:origin2[3]
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "player")) != 0)
	{
		pev(ent, pev_origin, originE)
		
		// xoy
		origin1 = Origin
		origin2 = originE
		origin1[2] = origin2[2] = 0.0
		if (vector_distance(origin1, origin2) <= 2 * 16.0)
		{
			// oz
			origin1 = Origin
			origin2 = originE
			origin1[0] = origin2[0] = origin1[1] = origin2[1] = 0.0
			if (vector_distance(origin1, origin2) <= 72.0) return 0;
		}
	}
	
	return 1
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Weapon bitsums
	const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
	const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)	
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32], weapon_ent
			get_weaponname(weaponid, wname, charsmax(wname))
			weapon_ent = fm_find_ent_by_owner(-1, wname, id)
			
			// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
			set_pev(weapon_ent, pev_iuser1, cs_get_user_bpammo(id, weaponid))
			
			// Player drops the weapon and looses his bpammo
			engclient_cmd(id, "drop", wname)
			cs_set_user_bpammo(id, weaponid, 0)
		}
	}
}

public End_Round(Float:EndTime, RoundDraw, CsTeams:Team)
// RoundDraw: Draw or Team Win
// Team: 1 - T | 2 - CT
{
	if(g_endround) return
	if(RoundDraw) 
	{
		GM_TerminateRound(EndTime, WINSTATUS_DRAW)
		client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_DRAW")
	} else {
		new Sound[64];
		if(Team == CS_TEAM_T) 
		{
			g_team_score[TEAM_T]++
			GM_TerminateRound(6.0, WINSTATUS_TERRORIST)

			ArrayGetString(escape_fail_sound, random_num(0, ArraySize(escape_fail_sound) - 1), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_FAIL")
		} else if(Team == CS_TEAM_CT) {
			g_team_score[TEAM_CT]++
			GM_TerminateRound(6.0, WINSTATUS_CT)

			ArrayGetString(escape_suc_sound, random_num(0, ArraySize(escape_suc_sound) - 1), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_SUCCESS")
		}
	}
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i))
			continue
		if(g_zombie[i])
		{
			update_deaths(i, 1)
		} else {
			update_frags(i, 3)
			g_escape_point[i] += 5
		}
	}
	
	ExecuteForward(g_forwards[FORWARD_ROUNDEND], g_fwDummyResult, Team)	
	
	g_endround = 1
}

/*
stock bool:TerminateRound(team)
{
	new winStatus;
	new event;
	new sound[64];
	
	switch(team)
	{
		case TEAM_T:
		{
			winStatus         = 2;
			event             = 9;
			ArrayGetString(escape_fail_sound, random_num(0, ArraySize(escape_fail_sound) - 1), sound, sizeof(sound))
			g_team_score[TEAM_T]++
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_FAIL")
		}
		case TEAM_CT:
		{
			winStatus         = 1;
			event             = 8;
			ArrayGetString(escape_suc_sound, random_num(0, ArraySize(escape_suc_sound) - 1), sound, sizeof(sound))
			g_team_score[TEAM_CT]++
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_SUCCESS")
		}
		case TEAM_ALL:
		{
			winStatus         = 3;
			event             = 10;
			sound             = "radio/rounddraw.wav";
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_DRAW")
		}
		case TEAM_START:
		{
			winStatus         = 3;	
			event             = 10;
			
			client_print(0, print_center, "%L", OFFICIAL_LANG, "ESCAPE_DRAW")
		}
		default:
		{
			return false;
		}
	}

	g_endround = 1
	EndRoundMessage(g_WinText[team], event)
	RoundTerminating(winStatus, team == TEAM_START ? 3.0 : 5.0)
	PlaySound(0, sound)

	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i) || !is_user_alive(i))
			continue
		if(g_zombie[i])
		{
			update_deaths(i, 1)
		} else {
			update_frags(i, 3)
			g_escape_point[i] += 5
		}
	}
	
	ExecuteForward(g_forwards[FORWARD_ROUNDEND], g_fwDummyResult, team)	
	
	return true;
}*/

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
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (VicOrigin[2] - EntOrigin[2]) / fl_Time		
		} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time
	}
	
	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}

stock equipweapon(id, weapon)
{
	if(!is_user_alive(id) || !is_user_connected(id)) 
		return
	
	static weaponid[2], weaponent
	
	if(weapon & EQUIP_PRI)
	{
		weaponent = fm_lastprimary(id)
		weaponid[1] = get_weaponid(g_primaryweapons[g_player_weapons[id][0]][1])
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
				fm_strip_user_gun(id, weaponid[0])
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			give_item(id, g_primaryweapons[g_player_weapons[id][0]][1])
		
		cs_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][1])
	}
	
	if(weapon & EQUIP_SEC)
	{
		weaponent = fm_lastsecondry(id)
		weaponid[1] = get_weaponid(g_secondaryweapons[g_player_weapons[id][1]][1])
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
				fm_strip_user_gun(id, weaponid[0])
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			give_item(id, g_secondaryweapons[g_player_weapons[id][1]][1])
		
		cs_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][1])
	}
	
	if(weapon & EQUIP_GREN)
	{
		static i
		for(i = 0; i < sizeof g_grenades; i++) if(!user_has_weapon(id, get_weaponid(g_grenades[i])))
		give_item(id, g_grenades[i])
	}
}

stock FixDeadAttrib(id)
{
	message_begin(MSG_BROADCAST, get_user_msgid("ScoreAttrib"))
	write_byte(id) // id
	write_byte(0) // attrib
	message_end()
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3076\\ f0\\ fs16 \n\\ par }
*/
