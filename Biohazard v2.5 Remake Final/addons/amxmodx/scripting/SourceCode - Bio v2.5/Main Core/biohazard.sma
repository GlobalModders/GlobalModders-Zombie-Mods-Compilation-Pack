#define VERSION	"2.5 Beta"

#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <cstrike>
#include <hamsandwich>
#include <xs>
#include <fun>
#include <bio_shop>
#include <cstrike>

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

#define OFFSET_LASTPRIM 368
#define OFFSET_LASTSEC 369
#define OFFSET_LASTKNI 370

#define TASKID_STRIPNGIVE 698
#define TASKID_NEWROUND	641
#define TASKID_INITROUND 222
#define TASKID_STARTROUND 153
#define TASKID_BALANCETEAM 375
#define TASKID_UPDATESCR 264
#define TASKID_SPAWNDELAY 786
#define TASKID_WEAPONSMENU 564
#define TASKID_CHECKSPAWN 423
#define TASKID_CZBOTPDATA 312

#define EQUIP_PRI (1<<0)
#define EQUIP_SEC (1<<1)
#define EQUIP_GREN (1<<2)
#define EQUIP_ALL (1<<0 | 1<<1 | 1<<2)

#define HAS_NVG (1<<0)
#define ATTRIB_BOMB (1<<1)
#define DMG_HEGRENADE (1<<24)

#define MODEL_CLASSNAME "player_model"
#define IMPULSE_FLASHLIGHT 100

#define MAX_SPAWNS 128
#define MAX_CLASSES 10
#define MAX_DATA 12

#define DATA_HEALTH 0
#define DATA_SPEED 1
#define DATA_GRAVITY 2
#define DATA_ATTACK 3
#define DATA_DEFENCE 4
#define DATA_HEDEFENCE 5
#define DATA_HITSPEED 6
#define DATA_HITDELAY 7
#define DATA_REGENDLY 8
#define DATA_HITREGENDLY 9
#define DATA_KNOCKBACK 10
#define DATA_MODELINDEX 11

#define fm_get_user_team(%1) get_pdata_int(%1, OFFSET_TEAM)
#define fm_get_user_deaths(%1) get_pdata_int(%1, OFFSET_DEATH)
#define fm_set_user_deaths(%1,%2) set_pdata_int(%1, OFFSET_DEATH, %2)
#define fm_get_user_money(%1) get_pdata_int(%1, OFFSET_CSMONEY)
#define fm_get_user_armortype(%1) get_pdata_int(%1, OFFSET_ARMOR)
#define fm_set_user_armortype(%1,%2) set_pdata_int(%1, OFFSET_ARMOR, %2)
#define fm_get_weapon_id(%1) get_pdata_int(%1, OFFSET_WEAPONTYPE, EXTRAOFFSET_WEAPONS)
#define fm_get_weapon_ammo(%1) get_pdata_int(%1, OFFSET_CLIPAMMO, EXTRAOFFSET_WEAPONS)
#define fm_set_weapon_ammo(%1,%2) set_pdata_int(%1, OFFSET_CLIPAMMO, %2, EXTRAOFFSET_WEAPONS)
#define fm_reset_user_primary(%1) set_pdata_int(%1, OFFSET_PRIMARYWEAPON, 0)
#define fm_lastprimary(%1) get_pdata_cbase(id, OFFSET_LASTPRIM)
#define fm_lastsecondry(%1) get_pdata_cbase(id, OFFSET_LASTSEC)
#define fm_lastknife(%1) get_pdata_cbase(id, OFFSET_LASTKNI)
#define fm_get_user_model(%1,%2,%3) engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, %1), "model", %2, %3) 

#define _random(%1) random_num(0, %1 - 1)
#define AMMOWP_NULL (1<<0 | 1<<CSW_KNIFE | 1<<CSW_FLASHBANG | 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)

// Config
// fog settings
#define FOG_ENABLE  	     1
#define FOG_DENSITY	    "0.00075"
#define FOG_COLOR   	    "0 0 0"

// default zombie setting
#define DEFAULT_PMODEL	    "models/player/tank_zombi_host/tank_zombi_host.mdl"
#define DEFAULT_WMODEL	    "models/biohazard/v_knife_normal.mdl"

#define DEFAULT_HEALTH 	    170.0 //Health value
#define DEFAULT_SPEED	    280.0 //Speed value
#define DEFAULT_GRAVITY	    1.0   //Gravity multiplier
#define DEFAULT_ATTACK	    2.0   //Zombie damage multiplier
#define DEFAULT_DEFENCE	    0.087 //Bullet damage multiplier
#define DEFAULT_HEDEFENCE   1.0   //HE damage multiplier
#define DEFAULT_HITSPEED    0.89  //Pain speed multiplier
#define DEFAULT_HITDELAY    0.28  //Pain speed delay value
#define DEFAULT_REGENDLY    0.18  //Regeneration delay value
#define DEFAULT_HITREGENDLY 2.0   //Pain regeneration delay value
#define DEFAULT_KNOCKBACK   1.0   //Knockback multiplier
#define DEFAULT_MODELINDEX  0.0   //Model Index

new g_zombie_weapname[] = "nano_knife"
new g_infection_name[]  = "t-virus"

// primary weapons (menu|game)
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
	{ "P90",      "weapon_p90"     }
	//{ "M249",     "weapon_m249"    },
	//{ "SG550",    "weapon_sg550"   },
	//{ "G3SG1",    "weapon_g3sg1"   }			
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
	"weapon_flashbang",
	"weapon_flashbang",
	"weapon_smokegrenade"
}

new Float:g_knockbackpower[] =
{
	3.0,  // KBPOWER_357SIG
	4.0,  // KBPOWER_762NATO
	7.5,  // KBPOWER_BUCKSHOT
	3.0,  // KBPOWER_45ACP
	4.5,  // KBPOWER_556NATO
	3.0,  // KBPOWER_9MM
	3.5,  // KBPOWER_57MM
	8.0, // KBPOWER_338MAGNUM
	4.0,  // KBPOWER_556NATOBOX
	3.8   // KBPOWER_50AE
}

new g_survivor_win_sounds[][] =
{
	"biohazard/iridescent_win1.wav",
	"biohazard/win_human.wav",
	"biohazard/survivor_win1.wav",
	"biohazard/survivor_win2.wav",
	"biohazard/survivor_win3.wav"
}

new g_zombie_win_sounds[][] = 
{ 
	"biohazard/win_zombie.wav",
	"biohazard/zombie_win1.wav", 
	"biohazard/zombie_win2.wav",
	"biohazard/zombie_win3.wav" 	
}

new g_appear_sounds[][] = 
{
	"biohazard/zombi_coming_1.wav",
	"biohazard/zombi_coming_2.wav",
	"biohazard/zombie_coming_3.wav",
	"biohazard/zombi_comeback.wav"
}

new g_scream_sounds[][] = 
{ 
	"biohazard/scream1.wav", 
	"scientist/scream01.wav",
	"biohazard/scream2.wav", 
	"biohazard/zombie_infec3.wav",
	"biohazard/scream3.wav",
	"scientist/c1a0_sci_catscream.wav",
	"biohazard/scream4.wav",
	"biohazard/scream5.wav"
}

new g_zombie_miss_sounds[][] = 
{ 
	//"zombie/claw_miss1.wav", 
	//"zombie/claw_miss2.wav" 	
	"biohazard/zombi_swing_1.wav",
	"biohazard/zombi_swing_2.wav",
	"biohazard/zombi_swing_3.wav"
}

new g_zombie_hit_sounds[][] = 
{ 
	//"zombie/claw_strike1.wav",
	//"zombie/claw_strike2.wav",
	//"zombie/claw_strike3.wav"
	"biohazard/zombi_attack_1.wav",
	"biohazard/zombi_attack_2.wav",
	"biohazard/zombi_attack_3.wav"
}

new g_zombie_wall_sounds[][] =
{
	"biohazard/zombi_wall_1.wav",
	"biohazard/zombi_wall_2.wav",
	"biohazard/zombi_wall_3.wav"
}

new g_zombie_pain_sounds[][] =
{
	"biohazard/zombie_hurt_01.wav",
	"biohazard/zombie_hurt_02.wav"
}

new g_zombie_die_sounds[][] = 
{
	"biohazard/death1.wav",
	"biohazard/zombi_death_1.wav",
	"biohazard/death2.wav",
	"biohazard/zombi_death_2.wav",
	"biohazard/death3.wav",
	"biohazard/zombi_chinese_death.wav"
}

// Human Config
new human_model[][] = 
{
	"arctic",
	"davidblack",
	"gign",
	"leon1",
	"gsg9",
	//"spetsnaz",
	"guerilla",
	//"stalker_human",
	"leet",
	"umbrella1",
	"sas",
	"terror",
	"urban",
	"gerrard"
}

// Hero Config
new hero_model[][] = 
{
	"hero"
}

new hero_appear_sound[][] = 
{
	"biohazard/survivor1_app.wav",
	"biohazard/survivor2_app.wav"
}

// Boss Config
new g_boss_model[][] = 
{
	"zombie_nemesis_new"
}

new g_boss_claws[] = "models/biohazard/v_knife_normal.mdl"

new g_boss_appear_sounds[][] =
{
	"biohazard/zombie_coming_3.wav"
}

// Human Evolution Vars + Config
new level_up_sound[][] = 
{
	"biohazard/levelup.wav"
}

new Float:XDAMAGE[11] = {
	1.0,
	1.1,
	1.2,
	1.3,
	1.4,
	1.5,
	1.6,
	1.7,
	1.8,
	1.9,
	2.0
}

new Float:XRECOIL[11] = {
	1.0,
	0.9,
	0.8,
	0.7,
	0.6,
	0.5,
	0.4,
	0.3,
	0.2,
	0.1,
	0.0
}

new const MAXBPAMMO[] = { -1, 52, -1, 150, 1, 32, 1, 200, 150, 1, 150, 200, 200, 150, 150, 150, 200, 150,
			30, 120, 200, 32, 90, 120, 150, 2, 35, 150, 150, -1, 200 }
// Amount of ammo to give when buying additional clips for weapons
new const BUYAMMO[] = { -1, 13, -1, 30, -1, 8, -1, 12, 30, -1, 30, 50, 12, 30, 30, 30, 12, 30,
			10, 30, 30, 8, 30, 30, 30, -1, 7, 30, 30, -1, 50 }
			
new g_level[33], g_point[33]
const NOCLIP_WPN_BS = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
new WpnName[32]
new Float:cl_pushangle[33][3]
const MAX_LEVEL_HUMAN = 10
const MAX_POINT = 1
new id_sprites_levelup
new const sprites_effects_levelup[] = "sprites/biohazard/levelup.spr"
#define TASK_GLOWSHELL 2011
new level_damage[33]

// [Bio] SmokeFlare (by 5c0r)
new bool:has_flaregrenade[33]
new const grenade_flare[][] = { "items/nvg_on.wav" }
new const sprite_grenade_trail[] = { "sprites/laserbeam.spr" }
const NADE_TYPE_FLARE = 4444
const PEV_FLARE_COLOR = pev_punchangle
const PEV_NADE_TYPE = pev_flTimeStepSound
const TASK_NADES = 1000
// Flare and flame tasks
#define FLARE_ENTITY args[0]
#define FLARE_DURATION args[1]
#define FLARE_R args[2]
#define FLARE_G args[3]
#define FLARE_B args[4]

new g_trailSpr
new cvar_flaregrenades,cvar_flareduration,cvar_flaresize,cvar_flarecolor

// Zombie Day System
#define MAX_DAY 12
#define MAX_PLAYER_BOSS_ROUND 10
#define TASK_AURA 323232
new g_day, g_human_win
new bool:g_boss_round, bool:had_boss
new const g_day_name[13][] = {
	"The Beginning",
	"Where Humans Become Zombies",
	"The Bloodless",
	"The Nightmare",
	"The Realism Plague",
	"The Darkness",
	"Rock The Zombies",
	"The Blood Revenge",
	"Hell on Earth",
	"Zombies House Party",
	"All Zombie Must Die",
	"Preparing For Final Battle",
	"The Final Battle (Humans VS Nemesis)"
}

new Float:health_multi[13] = {
	1.0,
	1.1,
	1.2,
	1.3,
	1.4,
	1.5,
	1.5,
	1.6,
	1.7,
	1.8,
	1.9,
	2.0,
	2.0
}

new light_day[13][] = {
	"f",
	"f",
	"e",
	"e",
	"d",
	"d",
	"c",
	"c",
	"c",
	"b",
	"b",
	"b",
	"b"
}

#define TASK_RESPAWN 123543
new cvar_respawn, cvar_timerespawn

#define TASK_GLOW_DIE 5655545
new glow_mode[33]

#define TASK_MUTATING 756756
new bool:mutating[33]
new bool:can_mutating[33]

#define TASK_HEALING 11111
new bool:healing[33]
new Float:last_heal[33]

new const autoheal_sound[] = "biohazard/zombi_heal.wav"

//#define SET_MODELINDEX_OFFSET
//new default_modelindex

#define TASK_LEVEL_NEM 1112312

// New NVG
#define TASK_NVISION 1310  
#define ID_NVISION (taskid - TASK_NVISION)

//const HAS_NVGOGGLES = (1<<0)
new g_nvision[33] // has night vision
new g_nvisionenabled[33] // has night vision turned on
new g_msgNVGToggle
new cvar_nvggive,cvar_cnvg,cvar_nvgsize,cvar_nvgcolor[3]

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }
			
// Allowed weapons for zombies (added grenades/bomb for sub-plugin support, since they shouldn't be getting them anyway)
const ZOMBIE_ALLOWED_WEAPONS_BITSUM = (1<<CSW_KNIFE)|(1<<CSW_HEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_C4)

new const g_respawn_spr[] = "sprites/biohazard/zb3_respawn.spr"
new g_respawn_sprid
new g_joined[33]

// CountDown
#define TASK_COUNTDOWN 0789789
new countdown_timer
new const g_countdown_sound[][] = { 
	"biohazard/countdown/one.wav", 
	"biohazard/countdown/two.wav", 
	"biohazard/countdown/three.wav", 
	"biohazard/countdown/four.wav", 
	"biohazard/countdown/five.wav", 
	"biohazard/countdown/six.wav", 
	"biohazard/countdown/seven.wav", 
	"biohazard/countdown/eight.wav", 
	"biohazard/countdown/nine.wav", 
	"biohazard/countdown/ten.wav" 
}

new g_sink_time[33]
new Float:g_max_health[33]
#define TASK_BLOOD 8987878
#define ID_BLOOD (taskid - TASK_BLOOD)
new const zombie_decals[] = {184 , 185 , 186 , 187 , 188 , 189}
	

// Biohazard Other Vars
enum
{
	MAX_CLIP = 0,
	MAX_AMMO
}

enum
{
	MENU_PRIMARY = 1,
	MENU_SECONDARY
}

enum
{
	CS_TEAM_UNASSIGNED = 0,
	CS_TEAM_T,
	CS_TEAM_CT,
	CS_TEAM_SPECTATOR
}

enum
{
	CS_ARMOR_NONE = 0,
	CS_ARMOR_KEVLAR,
	CS_ARMOR_VESTHELM
}

enum
{
	KBPOWER_357SIG = 0,
	KBPOWER_762NATO,
	KBPOWER_BUCKSHOT,
	KBPOWER_45ACP,
	KBPOWER_556NATO,
	KBPOWER_9MM,
	KBPOWER_57MM,
	KBPOWER_338MAGNUM,
	KBPOWER_556NATOBOX,
	KBPOWER_50AE
}

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

new const g_weapon_knockback[] =
{
	-1, 
	KBPOWER_357SIG, 
	-1, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_BUCKSHOT, 
	-1, 
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	-1, 
	KBPOWER_9MM, 
	KBPOWER_57MM,
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_45ACP,
	KBPOWER_9MM, 
	KBPOWER_338MAGNUM,
	KBPOWER_9MM, 
	KBPOWER_556NATOBOX,
	KBPOWER_BUCKSHOT, 
	KBPOWER_556NATO, 
	KBPOWER_9MM, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_50AE, 
	KBPOWER_556NATO, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_57MM
}

new const g_remove_entities[][] = 
{ 
	"func_bomb_target",    
	"info_bomb_target", 
	"hostage_entity",      
	"monster_scientist", 
	"func_hostage_rescue", 
	"info_hostage_rescue",
	"info_vip_start",      
	"func_vip_safetyzone", 
	"func_escapezone",     
	"func_buyzone"
}

new const g_dataname[][] = 
{ 
	"HEALTH", 
	"SPEED", 
	"GRAVITY", 
	"ATTACK", 
	"DEFENCE", 
	"HEDEFENCE", 
	"HITSPEED", 
	"HITDELAY", 
	"REGENDLY", 
	"HITREGENDLY", 
	"KNOCKBACK" 
}
new const g_teaminfo[][] = 
{ 
	"UNASSIGNED", 
	"TERRORIST",
	"CT",
	"SPECTATOR" 
}

new g_maxplayers, g_spawncount, g_buyzone, g_botclient_pdata, g_sync_hpdisplay, 
    g_sync_msgdisplay, g_fwd_spawn, g_fwd_result, g_fwd_infect, g_fwd_gamestart, 
    g_msg_flashlight, g_msg_teaminfo, g_msg_scoreattrib, g_msg_money, g_msg_scoreinfo, 
    g_msg_deathmsg , g_msg_screenfade, Float:g_buytime,  Float:g_spawns[MAX_SPAWNS+1][9],
    Float:g_vecvel[3], bool:g_brestorevel, bool:g_infecting, bool:g_gamestarted,
    bool:g_roundstarted, bool:g_roundended, bool:g_czero, g_class_name[MAX_CLASSES+1][32], 
    g_classcount, g_class_desc[MAX_CLASSES+1][32], g_class_pmodel[MAX_CLASSES+1][64], 
    g_class_wmodel[MAX_CLASSES+1][64], Float:g_class_data[MAX_CLASSES+1][MAX_DATA],
    bool:g_lasthuman[33], cvar_zombie_health
    
new cvar_randomspawn, cvar_skyname, cvar_autoteambalance[4], cvar_starttime, 
    cvar_winsounds, cvar_weaponsmenu, cvar_lights, cvar_killbonus, cvar_enabled, 
    cvar_gamedescription, cvar_botquota, cvar_maxzombies, cvar_flashbang, cvar_buytime,
    cvar_respawnaszombie, cvar_punishsuicide, cvar_infectmoney, cvar_showtruehealth,
    cvar_obeyarmor, cvar_impactexplode, cvar_caphealthdisplay, cvar_zombie_hpmulti,
    cvar_randomclass, cvar_zombiemulti, cvar_ammo, cvar_pushpwr_weapon, cvar_pushpwr_zombie,
    cvar_knockback_duck, cvar_killreward, cvar_painshockfree, cvar_zombie_class,
    cvar_shootobjects, cvar_level_recoil, cvar_glowshell_time, cvar_auto_light
    
new cvar_humanhealth
new cvar_hero_enable, cvar_hero_health, cvar_hero_speed, cvar_hero_knife_damage
new cvar_day_system, cvar_zwin_change
new cvar_nemesis_mode, cvar_nemesis_health, cvar_nemesis_speed, cvar_nemesis_gravity,
cvar_nemesis_aura_r, cvar_nemesis_aura_g, cvar_nemesis_aura_b
    
new bool:g_zombie[33], bool:g_falling[33], bool:g_disconnected[33], g_boss[33],
    bool:g_showmenu[33], bool:g_menufailsafe[33], bool:g_preinfect[33], bool:g_welcomemsg[33], 
    bool:g_suicide[33], Float:g_regendelay[33], Float:g_hitdelay[33], g_mutate[33], g_victim[33], 
    g_menuposition[33], g_player_class[33], g_player_weapons[33][2], bool:g_lockmodel[33],
    g_hero[33]
    
new g_fwUserLastHuman, g_fwDummyResult
new cvar_readydieeffect, cvar_readydieeffecthp
new cvar_mutatingenable, cvar_mutatingtime
new cvar_autoheal_enable, cvar_autoheal_timestart, cvar_autoheal_delay, cvar_autoheal_amount
new cvar_enable_sink, cvar_zombie_appear_sound
new cvar_knockback, cvar_knockback_damage, cvar_knockback_power, cvar_knockback_bydata
new cvar_zombiebleeding

public plugin_precache()
{
	register_plugin("Biohazard", VERSION, "cheap_suit")
	register_cvar("bh_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("bh_version", VERSION)
	
	cvar_enabled = register_cvar("bh_enabled", "1")

	if(!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_gamedescription = register_cvar("bh_gamedescription", "Biohazard")
	cvar_skyname = register_cvar("bh_skyname", "drkg")
	cvar_auto_light = register_cvar("bh_auto_light", "0")
	cvar_lights = register_cvar("bh_lights", "d")
	cvar_starttime = register_cvar("bh_starttime", "15.0")
	cvar_buytime = register_cvar("bh_buytime", "0")
	cvar_randomspawn = register_cvar("bh_randomspawn", "0")
	cvar_punishsuicide = register_cvar("bh_punishsuicide", "1")
	cvar_winsounds = register_cvar("bh_winsounds", "1")
	cvar_respawnaszombie = register_cvar("bh_respawnaszombie", "1")
	cvar_painshockfree = register_cvar("bh_painshockfree", "1")
	cvar_obeyarmor = register_cvar("bh_obeyarmor", "0")
	cvar_infectmoney = register_cvar("bh_infectionmoney", "0")
	cvar_caphealthdisplay = register_cvar("bh_caphealthdisplay", "1")
	cvar_weaponsmenu = register_cvar("bh_weaponsmenu", "1")
	cvar_ammo = register_cvar("bh_ammo", "1")
	cvar_maxzombies = register_cvar("bh_maxzombies", "31")
	cvar_flashbang = register_cvar("bh_flashbang", "1")
	cvar_impactexplode = register_cvar("bh_impactexplode", "1")
	cvar_showtruehealth = register_cvar("bh_showtruehealth", "1")
	cvar_zombiemulti = register_cvar("bh_zombie_countmulti", "0.15")
	cvar_zombie_hpmulti = register_cvar("bh_zombie_hpmulti", "2.0")
	cvar_zombie_class = register_cvar("bh_zombie_class", "1")
	cvar_randomclass = register_cvar("bh_randomclass", "1")
	cvar_killbonus = register_cvar("bh_kill_bonus", "1")
	cvar_killreward = register_cvar("bh_kill_reward", "2")
	cvar_shootobjects = register_cvar("bh_shootobjects", "1")
	cvar_humanhealth = register_cvar("bh_humanhealth", "300")
	cvar_level_recoil = register_cvar("bh_level_recoil", "1")
	cvar_glowshell_time = register_cvar("bh_glowshell_time", "10.0")
	cvar_respawn = register_cvar("bh_zombie_respawn", "1")
	cvar_timerespawn = register_cvar("bh_time_respawn", "10.0")
	cvar_zombie_appear_sound = register_cvar("bh_zb_appear_sound", "2")
	cvar_zombie_health = register_cvar("bh_zb_health", "2")
	cvar_zombiebleeding = register_cvar("bh_zb_bleeding", "1")
	
	// KnockBack System
	cvar_knockback = register_cvar("bh_knockback", "1")
	cvar_knockback_damage = register_cvar("bh_knockback_damage", "1")
	cvar_knockback_power = register_cvar("bh_knockback_power", "1")
	cvar_knockback_duck = register_cvar("bh_knockback_duck", "1")
	cvar_knockback_bydata = register_cvar("bh_knockback_bydata", "1")
	
	cvar_pushpwr_weapon = register_cvar("bh_pushpwr_weapon", "2.0")
	cvar_pushpwr_zombie = register_cvar("bh_pushpwr_zombie", "5.0")
	
	// Auto Heal
	cvar_autoheal_enable = register_cvar("bh_autoheal_enable", "1")
	cvar_autoheal_timestart = register_cvar("bh_autoheal_timestart", "5.0")
	cvar_autoheal_delay = register_cvar("bh_autoheal_delay", "1.0")
	cvar_autoheal_amount = register_cvar("bh_autoheal_amount", "100.0")
	
	// Mutating Effect
	cvar_mutatingenable = register_cvar("bh_mutate_enable", "0")
	cvar_mutatingtime = register_cvar("bh_mutate_time", "3.0")
	
	// Ready Die Effect
	cvar_readydieeffect = register_cvar("bh_ready_die_effect", "1")
	cvar_readydieeffecthp = register_cvar("bh_ready_die_effect_hp", "400")
	
	// HERO Cvars
	cvar_hero_enable = register_cvar("bh_hero_enable", "0")
	cvar_hero_health = register_cvar("bh_hero_health", "500")
	cvar_hero_speed = register_cvar("bh_hero_speed", "270.0")
	cvar_hero_knife_damage = register_cvar("bh_hero_knife_damage", "750.0")
	
	// Biohazard: SmokeFlare (By 5c0r)
	cvar_flaregrenades = register_cvar("bh_flare_grenades","1")
	cvar_flareduration = register_cvar("bh_flare_duration", "180")
	cvar_flaresize = register_cvar("bh_flare_size", "30")
	cvar_flarecolor = register_cvar("bh_flare_color", "0")
	
	// Day System
	cvar_day_system = register_cvar("bh_day_system", "1")
	cvar_zwin_change = register_cvar("bh_zwin_change_day", "1")
	
	// Nemesis
	cvar_nemesis_mode = register_cvar("bh_nemesis_active", "1")
	cvar_nemesis_health = register_cvar("bh_nemesis_health", "50000.0")
	cvar_nemesis_speed = register_cvar("bh_nemesis_speed", "295.0")
	cvar_nemesis_gravity = register_cvar("bh_nemesis_gravity", "0.5")
	
	cvar_nemesis_aura_r = register_cvar("bh_nem_aura_r", "200")
	cvar_nemesis_aura_g = register_cvar("bh_nem_aura_g", "0")
	cvar_nemesis_aura_b = register_cvar("bh_nem_aura_b", "0")
	
	// New NVG
	cvar_nvggive = register_cvar("bh_zb_nvg_give", "2")
	cvar_cnvg = register_cvar("bh_nvg_custom", "1")
	cvar_nvgsize = register_cvar("bh_zb_nvg_size", "70")
	cvar_nvgcolor[0] = register_cvar("bh_zb_nvg_color_R", "100")
	cvar_nvgcolor[1] = register_cvar("bh_zb_nvg_color_G", "100")
	cvar_nvgcolor[2] = register_cvar("bh_zb_nvg_color_B", "100")
	
	// Death Sink off on ground
	cvar_enable_sink = register_cvar("bh_zb_death_sink", "0")
	
	//register_clcmd("say /set_day", "set_day")
	//register_clcmd("check_victim", "check_victim")

	// Cont Biohazard
	new file[64]
	get_configsdir(file, 63)
	format(file, 63, "%s/bio_cvars.cfg", file)
	
	if(file_exists(file)) 
		server_cmd("exec %s", file)
	
	new mapname[32]
	get_mapname(mapname, 31)
	register_spawnpoints(mapname)
		
	register_zombieclasses("bio_zombieclass.ini")
	register_dictionary("biohazard.txt")
	
	// Precache Sprites
	id_sprites_levelup = precache_model(sprites_effects_levelup)
	
	precache_model(DEFAULT_PMODEL)
	precache_model(DEFAULT_WMODEL)
	//default_modelindex = precache_model("models/player/gign/gign.mdl")
	
	new i, buffer[64]
	for(i = 0; i < g_classcount; i++)
	{
		precache_model(g_class_pmodel[i])
		precache_model(g_class_wmodel[i])
	}
	
	for(i = 0; i < sizeof g_zombie_miss_sounds; i++)
		precache_sound(g_zombie_miss_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_hit_sounds; i++) 
		precache_sound(g_zombie_hit_sounds[i])

	for(i = 0; i < sizeof g_zombie_wall_sounds; i++) 
		precache_sound(g_zombie_wall_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_pain_sounds; i++) 
		precache_sound(g_zombie_pain_sounds[i])

	for(i = 0; i < sizeof g_scream_sounds; i++) 
		precache_sound(g_scream_sounds[i])
	for(i = 0; i < sizeof g_appear_sounds; i++)
		precache_sound(g_appear_sounds[i])	
	for(i = 0; i < sizeof g_zombie_die_sounds; i++)
		precache_sound(g_zombie_die_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_win_sounds; i++) 
		precache_sound(g_zombie_win_sounds[i])
	for(i = 0; i < sizeof human_model; i++)
	{
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", human_model[i], human_model[i])
		precache_model(buffer)
	}
	if(get_pcvar_num(cvar_hero_enable))
	{
		for(i = 0; i < sizeof hero_appear_sound; i++)
			precache_sound(hero_appear_sound[i])
		for(i = 0; i < sizeof hero_model; i++)
		{
			formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", hero_model[i], hero_model[i])
			precache_model(buffer)		
		}		
	}
	for(i = 0; i < sizeof level_up_sound; i++)
		precache_sound(level_up_sound[i])
		
	for(i = 0; i < sizeof g_boss_model; i++)
	{
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", g_boss_model[i], g_boss_model[i])
		precache_model(buffer)		
	}
	for(i = 0; i < sizeof g_countdown_sound; i++)
		precache_sound(g_countdown_sound[i])
	
	
	precache_model(g_boss_claws)
	for(i = 0; i < sizeof g_boss_appear_sounds; i++)
		precache_sound(g_boss_appear_sounds[i])	
		
	precache_sound(autoheal_sound)	
	g_respawn_sprid = precache_model(g_respawn_spr)
		
	// [Bio] SmokeFlare (by 5c0r)
	for (i = 0; i < sizeof grenade_flare; i++)
		engfunc(EngFunc_PrecacheSound, grenade_flare[i])
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)

	g_fwd_spawn = register_forward(FM_Spawn, "fwd_spawn")
	
	g_buyzone = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "func_buyzone"))
	if(g_buyzone) 
	{
		dllfunc(DLLFunc_Spawn, g_buyzone)
		set_pev(g_buyzone, pev_solid, SOLID_NOT)
	}
	
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_bomb_target"))
	if(ent) 
	{
		dllfunc(DLLFunc_Spawn, ent)
		set_pev(ent, pev_solid, SOLID_NOT)
	}

	#if FOG_ENABLE
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
	if(ent)
	{
		fm_set_kvd(ent, "density", FOG_DENSITY, "env_fog")
		fm_set_kvd(ent, "rendercolor", FOG_COLOR, "env_fog")
	}
	#endif
}

public plugin_init()
{
	if(!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_botquota = get_cvar_pointer("bot_quota")
	cvar_autoteambalance[0] = get_cvar_pointer("mp_autoteambalance")
	cvar_autoteambalance[1] = get_pcvar_num(cvar_autoteambalance[0])
	set_pcvar_num(cvar_autoteambalance[0], 0)

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("chooseteam", "cmd_jointeam")
	register_clcmd("say /class", "cmd_classmenu")
	register_clcmd("say /guns", "cmd_enablemenu")
	register_clcmd("say /help", "cmd_helpmotd")
	register_clcmd("bio_infect", "cmd_infectuser", ADMIN_BAN, "<name or #userid>")
	register_clcmd("bio_set_day", "cmd_setday", ADMIN_BAN, "<day number>")
	register_clcmd("nightvision", "clcmd_nightvision")
	
	register_menu("Equipment", 1023, "action_equip")
	register_menu("Primary", 1023, "action_prim")
	register_menu("Secondary", 1023, "action_sec")
	register_menu("Class", 1023, "action_class")
	
	unregister_forward(FM_Spawn, g_fwd_spawn)
	register_forward(FM_CmdStart, "fwd_cmdstart")
	register_forward(FM_CmdStart, "fwd_cmdstart2")
	register_forward(FM_EmitSound, "fwd_emitsound")
	register_forward(FM_GetGameDescription, "fwd_gamedescription")
	register_forward(FM_ClientDisconnect, "fwd_clientdisconnect_post", 1)
	register_forward(FM_CreateNamedEntity, "fwd_createnamedentity")
	register_forward(FM_ClientKill, "fwd_clientkill")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink_post", 1)
	register_forward(FM_PlayerPostThink, "fwd_player_postthink")
	register_forward(FM_SetClientKeyValue, "fwd_setclientkeyvalue")
	
	// [Bio] SmokeFlare
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")

	RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player")
	RegisterHam(Ham_Killed, "player", "bacon_killed_player")
	RegisterHam(Ham_Spawn, "player", "bacon_spawn_player_post", 1)
	RegisterHam(Ham_TraceAttack, "player", "bacon_traceattack_player")
	RegisterHam(Ham_TraceAttack, "func_pushable", "bacon_traceattack_pushable")
	RegisterHam(Ham_Use, "func_tank", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankmortar", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankrocket", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tanklaser", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_pushable", "bacon_use_pushable")
	RegisterHam(Ham_Touch, "func_pushable", "bacon_touch_pushable")
	RegisterHam(Ham_Touch, "weaponbox", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "grenade", "bacon_touch_grenade")
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "bacon_deploy_post", 1)
	
	for(new i=1; i<=CSW_P90; i++)
	{
		if( !(NOCLIP_WPN_BS & (1<<i)) && get_weaponname(i, WpnName, charsmax(WpnName)) )
		{
			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fwd_primary_attack") 
			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fwd_primary_attack_post",1) 
		}
	}
	
	register_message(get_user_msgid("Health"), "msg_health")
	register_message(get_user_msgid("TextMsg"), "msg_textmsg")
	register_message(get_user_msgid("SendAudio"), "msg_sendaudio")
	register_message(get_user_msgid("StatusIcon"), "msg_statusicon")
	register_message(get_user_msgid("ScoreAttrib"), "msg_scoreattrib")
	register_message(get_user_msgid("DeathMsg"), "msg_deathmsg")
	register_message(get_user_msgid("ScreenFade"), "msg_screenfade")
	register_message(get_user_msgid("TeamInfo"), "msg_teaminfo")
	register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")
	register_message(get_user_msgid("WeapPickup"), "msg_weaponpickup")
	register_message(get_user_msgid("AmmoPickup"), "msg_ammopickup")
	
	register_event("TextMsg", "event_textmsg", "a", "2=#Game_will_restart_in")
	register_event("TextMsg","logevent_round_end","a","2=#Game_Commencing","2=#Game_will_restart_in")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_event("ArmorType", "event_armortype", "be")
	register_event("Damage", "event_damage", "be")
	register_event("DeathMsg", "event_death", "a")
	
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	// Block Hero to Drop Weapon
	register_clcmd("drop", "cmd_drop")
	register_clcmd("buyammo1", "clcmd_buyammo")
	register_clcmd("buyammo2", "clcmd_buyammo2")
	
	g_msgNVGToggle = get_user_msgid("NVGToggle")
	g_msg_flashlight = get_user_msgid("Flashlight")
	g_msg_teaminfo = get_user_msgid("TeamInfo")
	g_msg_scoreattrib = get_user_msgid("ScoreAttrib")
	g_msg_scoreinfo = get_user_msgid("ScoreInfo")
	g_msg_deathmsg = get_user_msgid("DeathMsg")
	g_msg_money = get_user_msgid("Money")
	g_msg_screenfade = get_user_msgid("ScreenFade")
	
	g_fwd_infect = CreateMultiForward("event_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwd_gamestart = CreateMultiForward("event_gamestart", ET_IGNORE)
	g_fwUserLastHuman = CreateMultiForward("event_last_human", ET_IGNORE, FP_CELL)

	g_sync_hpdisplay = CreateHudSyncObj(1)
	g_sync_msgdisplay = CreateHudSyncObj(2)
	
	g_maxplayers = get_maxplayers()
	
	new mod[3]
	get_modname(mod, 2)
	
	g_czero = (mod[0] == 'c' && mod[1] == 'z') ? true : false
	
	new skyname[32]
	get_pcvar_string(cvar_skyname, skyname, 31)
		
	if(strlen(skyname) > 0)
		set_cvar_string("sv_skyname", skyname)
		
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
	
	set_cvar_num("mp_roundtime", 3)
	
	if(get_pcvar_num(cvar_showtruehealth))
		set_task(0.1, "task_showtruehealth", _, _, _, "b")

	set_cvars()
}

public plugin_end()
{
	if(get_pcvar_num(cvar_enabled))
		set_pcvar_num(cvar_autoteambalance[0], cvar_autoteambalance[1])
}

public plugin_natives()
{
	register_library("biohazardf")
	register_native("preinfect_user", "native_preinfect_user", 1)
	register_native("infect_user", "native_infect_user", 1)
	register_native("cure_user", "native_cure_user", 1)
	register_native("register_class", "native_register_class", 1)
	register_native("get_class_id", "native_get_class_id", 1)
	register_native("set_class_pmodel", "native_set_class_pmodel", 1)
	register_native("set_class_wmodel", "native_set_class_wmodel", 1)
	register_native("set_class_data", "native_set_class_data", 1)
	register_native("get_class_data", "native_get_class_data", 1)
	register_native("game_started", "native_game_started", 1)
	register_native("is_user_zombie", "native_is_user_zombie", 1)
	register_native("is_user_first_zombie", "native_is_user_first_zombie", 1)
	register_native("get_user_class", "native_get_user_class",  1)
	register_native("get_user_last_human", "native_get_user_last_human", 1)
	register_native("is_boss_round", "native_is_boss_round", 1)
	register_native("is_user_boss", "native_is_user_boss", 1)
	register_native("get_user_maxhealth", "native_get_max_health", 1)
}

public set_cvars()
{
	server_cmd("mp_freezetime 0")
	server_cmd("mp_flashlight 1")
}

public client_connect(id)
{
	g_showmenu[id] = true
	g_welcomemsg[id] = true
	g_zombie[id] = false
	g_hero[id] = false
	g_preinfect[id] = false
	g_disconnected[id] = false
	g_falling[id] = false
	g_menufailsafe[id] = false
	g_victim[id] = 0
	g_mutate[id] = -1
	g_player_class[id] = 0
	g_player_weapons[id][0] = -1
	g_player_weapons[id][1] = -1
	g_regendelay[id] = 0.0
	g_hitdelay[id] = 0.0
	
	g_lockmodel[id] = true
	g_joined[id] = false
}

public client_putinserver(id)
{
	if(!g_botclient_pdata && g_czero) 
	{
		static param[1]
		param[0] = id
		
		if(!task_exists(TASKID_CZBOTPDATA))
			set_task(1.0, "task_botclient_pdata", TASKID_CZBOTPDATA, param, 1)
	}
}

public client_disconnect(id)
{
	remove_task(TASKID_STRIPNGIVE + id)
	remove_task(TASKID_UPDATESCR + id)
	remove_task(TASKID_SPAWNDELAY + id)
	remove_task(TASKID_WEAPONSMENU + id)
	remove_task(TASKID_CHECKSPAWN + id)
	remove_task(id+TASK_NVISION)
	
	remove_task(TASK_NADES)
	remove_task(TASKID_NEWROUND) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN)
	if(task_exists(id+TASK_GLOW_DIE)) remove_task(id+TASK_GLOW_DIE)
	if(task_exists(id+TASK_HEALING)) remove_task(id+TASK_HEALING)
	if(task_exists(TASK_LEVEL_NEM)) remove_task(TASK_LEVEL_NEM)
	if(task_exists(id+123654789)) remove_task(id+123654789)
	if(task_exists(id+TASK_RESPAWN+1)) remove_task(id+TASK_RESPAWN+1)
	if(task_exists(id+TASK_BLOOD)) remove_task(id+TASK_BLOOD)	

	g_disconnected[id] = true
	g_lockmodel[id] = false
	g_joined[id] = false
}

public cmd_jointeam(id)
{	
	if(g_joined[id])
	{
		bio_open_shop(id)
		return PLUGIN_HANDLED
	}
	
	g_joined[id] = true
	
	return PLUGIN_CONTINUE
}

public cmd_classmenu(id)
{
	if(!get_pcvar_num(cvar_zombie_class))
	{
		if(g_classcount > 1) display_classmenu(id, g_menuposition[id] = 0)
	} else {
		client_print(id, print_center, "[Class da duoc chon ngau nhien !!!]")
	}
}
	
public cmd_enablemenu(id)
{	
	if(get_pcvar_num(cvar_weaponsmenu))
	{
		client_print(id, print_chat, "%L", id, g_showmenu[id] == false ? "MENU_REENABLED" : "MENU_ALENABLED")
		g_showmenu[id] = true
	}
}

public cmd_helpmotd(id)
{
	static motd[2048]
	formatex(motd, 2047, "%L", id, "HELP_MOTD")
	replace(motd, 2047, "#Version#", VERSION)
	
	show_motd(id, motd, "Biohazard Help")
}	

public cmd_infectuser(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED_MAIN
	
	static arg1[32]
	read_argv(1, arg1, 31)
	
	static target
	target = cmd_target(id, arg1, (CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE))
	
	if(!is_user_connected(target) || g_zombie[target])
		return PLUGIN_HANDLED_MAIN
	
	if(!allow_infection())
	{
		console_print(id, "%L", id, "CMD_MAXZOMBIES")
		return PLUGIN_HANDLED_MAIN
	}
	
	if(!g_gamestarted)
	{
		console_print(id, "%L", id, "CMD_GAMENOTSTARTED")
		return PLUGIN_HANDLED_MAIN
	}
			
	static name[32] 
	get_user_name(target, name, 31)
	
	console_print(id, "%L", id, "CMD_INFECTED", name)
	infect_user(target, 0)
	
	return PLUGIN_HANDLED_MAIN
}

public cmd_setday(id, level, cid)
{
	if(!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED_MAIN
	
	static arg1[5], arg1_int
	read_argv(1, arg1, sizeof(arg1))
	
	arg1_int = str_to_num(arg1)
	
	if(arg1_int < MAX_DAY)
	{
		g_day = arg1_int
		client_print(id, print_console, "[Bio] You Set %ith Day", arg1_int)
	} else {
		client_print(id, print_console, "[Bio] Day must be < 12", arg1_int)
	}
	
	return PLUGIN_HANDLED_MAIN
}

public cmd_drop(id)
{
	if(g_hero[id]) return PLUGIN_HANDLED
	
	return 0
}

public msg_teaminfo(msgid, dest, id)
{
	if(!g_gamestarted)
		return PLUGIN_CONTINUE

	static team[2]
	get_msg_arg_string(2, team, 1)
	
	if(team[0] != 'U')
		return PLUGIN_CONTINUE

	id = get_msg_arg_int(1)
	if(is_user_alive(id) || !g_disconnected[id])
		return PLUGIN_CONTINUE

	g_disconnected[id] = false
	id = randomly_pick_zombie()
	if(id)
	{
		fm_set_user_team(id, (g_zombie[id] || g_boss[id]) ? CS_TEAM_CT : CS_TEAM_T, 0)
		set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	}
	return PLUGIN_CONTINUE
}

public msg_screenfade(msgid, dest, id)
{
	if(!get_pcvar_num(cvar_flashbang))
		return PLUGIN_CONTINUE
	
	if(!g_zombie[id] || !g_boss[id] || !is_user_alive(id))
	{
		static data[4]
		data[0] = get_msg_arg_int(4)
		data[1] = get_msg_arg_int(5)
		data[2] = get_msg_arg_int(6)
		data[3] = get_msg_arg_int(7)
		
		if(data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] > 199)
			return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public msg_scoreattrib(msgid, dest, id)
{
	static attrib 
	attrib = get_msg_arg_int(2)
	
	if(attrib == ATTRIB_BOMB)
		set_msg_arg_int(2, ARG_BYTE, 0)
}

public msg_statusicon(msgid, dest, id)
{
	static icon[3]
	get_msg_arg_string(2, icon, 2)
	
	return (icon[0] == 'c' && icon[1] == '4') ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

public msg_weaponpickup(msgid, dest, id)
{
	if(g_zombie[id] || g_boss[id])
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public msg_ammopickup(msgid, dest, id)
{
	if(g_zombie[id] || g_boss[id])
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public msg_deathmsg(msgid, dest, id) 
{
	static killer
	killer = get_msg_arg_int(1)

	if(is_user_connected(killer) && (g_zombie[killer] || g_boss[killer]))
		set_msg_arg_string(4, g_zombie_weapname)
}

public msg_sendaudio(msgid, dest, id)
{
	if(!get_pcvar_num(cvar_winsounds))
		return PLUGIN_CONTINUE
	
	static audiocode [22]
	get_msg_arg_string(2, audiocode, 21)
	
	if(equal(audiocode[7], "terwin"))
		set_msg_arg_string(2, g_zombie_win_sounds[_random(sizeof g_zombie_win_sounds)])
	else if(equal(audiocode[7], "ctwin"))
		set_msg_arg_string(2, g_survivor_win_sounds[_random(sizeof g_survivor_win_sounds)])
	
	return PLUGIN_CONTINUE
}

public msg_health(msgid, dest, id)
{
	if(!get_pcvar_num(cvar_caphealthdisplay))
		return PLUGIN_HANDLED
		
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
		
	static health, Float:class_health, new_health, real_health	
		
	if(g_zombie[id])
	{
		health = pev(id, pev_health)
		
		if(native_is_user_first_zombie(id))
		{
			if(get_pcvar_num(cvar_zombie_health) == 1)
			{
				class_health = native_get_class_data(native_get_user_class(id), DATA_HEALTH) * get_pcvar_float(cvar_zombie_hpmulti)
			} else if(get_pcvar_num(cvar_zombie_health) == 2) {
				class_health = g_max_health[id]
			}
			
			new_health = floatround((health / class_health) * 200.0)
			real_health = clamp(new_health, 1, 200)
		} else {
			if(get_pcvar_num(cvar_zombie_health) == 1)
			{
				class_health = native_get_class_data(native_get_user_class(id), DATA_HEALTH)
			} else if(get_pcvar_num(cvar_zombie_health) == 2) {
				class_health = g_max_health[id]
			}
			
			new_health = floatround((health / class_health) * 100.0)
			real_health = clamp(new_health, 1, 100)
		}

		set_msg_arg_int(1, ARG_BYTE, real_health)
	} else if(!g_zombie[id]) {
		health = pev(id, pev_health)
		class_health = g_max_health[id]
		new_health = floatround((health / class_health) * 100.0)
		real_health = clamp(new_health, 1, 100)
		
		set_msg_arg_int(1, ARG_BYTE, real_health)
	} else if(g_boss[id]) {
		health = pev(id, pev_health)
		class_health = get_pcvar_float(cvar_nemesis_health)
		new_health = floatround((health / class_health) * 100.0)
		real_health = clamp(new_health, 1, 100)
		
		set_msg_arg_int(1, ARG_BYTE, real_health)
	} else if(g_hero[id]) {
		health = pev(id, pev_health)
		class_health = get_pcvar_float(cvar_hero_health)
		new_health = floatround((health / class_health) * 100.0)
		real_health = clamp(new_health, 1, 100)
		
		set_msg_arg_int(1, ARG_BYTE, real_health)		
	}
	
	return PLUGIN_CONTINUE
}

public msg_textmsg(msgid, dest, id)
{
	if(get_msg_arg_int(1) != 4)
		return PLUGIN_CONTINUE
	
	static txtmsg[25], winmsg[32]
	get_msg_arg_string(2, txtmsg, 24)
	
	if(equal(txtmsg[1], "Game_bomb_drop"))
		return PLUGIN_HANDLED

	else if(equal(txtmsg[1], "Terrorists_Win"))
	{
		formatex(winmsg, 31, "%L", LANG_SERVER, "WIN_TXT_ZOMBIES")
		set_msg_arg_string(2, winmsg)
	}
	else if(equal(txtmsg[1], "Target_Saved") || equal(txtmsg[1], "CTs_Win"))
	{
		formatex(winmsg, 31, "%L", LANG_SERVER, "WIN_TXT_SURVIVORS")
		set_msg_arg_string(2, winmsg)
		
		if(get_pcvar_num(cvar_zwin_change) && g_human_win == 0)
		{
			g_human_win = 1
		}
	}
	return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
	id = get_msg_arg_int(12)
	if(!g_zombie[id] || g_boss[id])
		return PLUGIN_CONTINUE
	
	static ent
	ent = fm_find_ent_by_owner(-1, MODEL_CLASSNAME, id)
	
	if(ent)
	{
		static model[64]
		pev(ent, pev_model, model, 63)
		
		set_msg_arg_string(1, model)
	}
	return PLUGIN_CONTINUE
}

public logevent_round_start()
{
	g_roundended = false
	g_roundstarted = true
	
	if(get_pcvar_num(cvar_weaponsmenu))
	{
		static id, team
		for(id = 1; id <= g_maxplayers; id++) if(is_user_alive(id))
		{
			team = fm_get_user_team(id)
			if(team == CS_TEAM_T || team == CS_TEAM_CT)
			{
				if(is_user_bot(id)) 
					bot_weapons(id)
				else 
				{
					if(g_showmenu[id])
					{
						add_delay(id, "display_equipmenu")
						
						g_menufailsafe[id] = true
						set_task(10.0, "task_weaponsmenu", TASKID_WEAPONSMENU + id)
					}
					else	
						equipweapon(id, EQUIP_ALL)
				}
			}
		}
	}
}

public logevent_round_end()
{
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true
	
	remove_task(TASKID_BALANCETEAM) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	if(task_exists(TASK_LEVEL_NEM)) remove_task(TASK_LEVEL_NEM)
	if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN)
	
	if(get_pcvar_num(cvar_auto_light))
	{
		set_lights("#OFF")
	}
	
	set_cvar_num("semiclip", 1)
	set_task(0.1, "task_balanceteam", TASKID_BALANCETEAM)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(task_exists(i+TASK_RESPAWN))
		{
			remove_task(i+TASK_RESPAWN)
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, i)
			write_short(0)
			message_end()
		}	
	}
}

public event_textmsg()
{
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true
	
	static seconds[5] 
	read_data(3, seconds, 4)
	
	static Float:tasktime 
	tasktime = float(str_to_num(seconds)) - 0.5
	
	remove_task(TASKID_BALANCETEAM)
	
	set_task(tasktime, "task_balanceteam", TASKID_BALANCETEAM)
}

public event_newround()
{
	g_gamestarted = false
	g_boss_round = false
	had_boss = false
	
	static buytime 
	buytime = get_pcvar_num(cvar_buytime)
	
	if(buytime) 
		g_buytime = buytime + get_gametime()
	
	// [Bio] SmokeFlare (by 5c0r)
	remove_task(TASK_NADES)
	remove_task(TASKID_NEWROUND) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN)
	if(task_exists(TASK_LEVEL_NEM)) remove_task(TASK_LEVEL_NEM)

	
	countdown_timer = 18
	set_task(0.1, "zombie_countdown", TASK_COUNTDOWN)
	
	for(new i; i <= get_maxplayers() ; ++i)
	{
		if(is_user_connected(i) && (1 < i < 33))
		{
			if(get_pcvar_num(cvar_randomclass) && g_classcount > 1)
				g_player_class[i] = _random(g_classcount)	
			
			if(task_exists(i+123654789)) remove_task(i+123654789)
			if(task_exists(i+TASK_RESPAWN+1)) remove_task(i+TASK_RESPAWN+1)
			if(task_exists(i+TASK_BLOOD)) remove_task(i+TASK_BLOOD)
			if(task_exists(i+TASK_GLOW_DIE)) remove_task(i+TASK_GLOW_DIE)
			if(task_exists(i+TASK_HEALING)) remove_task(i+TASK_HEALING)
			
			can_mutating[i] = false
			has_flaregrenade[i] = true
			mutating[i] = false
			if(task_exists(i+TASK_MUTATING)) remove_task(i+TASK_MUTATING)
			if(task_exists(i+TASK_RESPAWN)) 
			{
				remove_task(i+TASK_RESPAWN)
				
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, i)
				write_short(0)
				message_end()
			}			
			
			if(g_nvision[i] || g_nvisionenabled[i] )
			{
				g_nvision[i] = false
				g_nvisionenabled[i] = false
			}
			
			if(is_user_alive(i) && is_user_connected(i))
			{
				strip_user_weapons(i)
				give_item(i, "weapon_knife")
			}
			
			set_user_rendering(i, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 25)
		}
	}
	
	
	
	set_task(0.1, "task_newround", TASKID_NEWROUND)
	
	if(get_pcvar_num(cvar_day_system))
	{
		if(g_day == MAX_DAY)
			g_day = 0
					
		if(get_pcvar_num(cvar_zwin_change))
		{
			if(g_human_win == 1)
			{
				g_day++
				g_human_win = 0
			}
		} else {
			g_day++
		}
		
		set_task(3.0, "task_showday")
	}
	
	static player_num
	player_num = get_playersnum()
	
	if(g_day == MAX_DAY && get_pcvar_num(cvar_nemesis_mode) == 1 && player_num >= MAX_PLAYER_BOSS_ROUND)
	{
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_alive(i) && is_user_connected(i))
				g_level[i] = 10
		}
		
		g_boss_round = true
		set_task(get_pcvar_float(cvar_starttime) + 3.0, "task_initbossround", TASKID_INITROUND)
	} else {
		set_task(get_pcvar_float(cvar_starttime), "task_initround", TASKID_INITROUND)
	}
}

public zombie_countdown()
{   	
	if (countdown_timer > 0)
	{ 
		if(countdown_timer <= 10)
		{
			emit_sound(0, CHAN_VOICE, g_countdown_sound[countdown_timer - 1], 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
		client_print(0, print_center, "Zombie Se Xuat Hien Sau: [%i] Giay !!!", countdown_timer)	
	}
	
	--countdown_timer
		
	if(countdown_timer > 0)
	{
		set_task(1.0, "zombie_countdown", TASK_COUNTDOWN)
	} else {
		remove_task(TASK_COUNTDOWN)
	}
}  

public event_curweapon(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	
	static weapon
	weapon = read_data(2)
	
	
	//if(g_zombie[id] || g_hero[id] || g_boss[id])
	//{
	//	if(weapon != CSW_KNIFE && !task_exists(TASKID_STRIPNGIVE + id))
	//		set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + id)
	//	
	//	return PLUGIN_CONTINUE
	//}

	static ammotype
	ammotype = get_pcvar_num(cvar_ammo)
	
	if(!ammotype || (AMMOWP_NULL & (1<<weapon)))
		return PLUGIN_CONTINUE

	static maxammo
	switch(ammotype)
	{
		case 1: maxammo = g_weapon_ammo[weapon][MAX_AMMO]
		case 2: maxammo = g_weapon_ammo[weapon][MAX_CLIP]
	}

	if(!maxammo)
		return PLUGIN_CONTINUE
	
	switch(ammotype)
	{
		case 1:
		{
			static ammo
			ammo = fm_get_user_bpammo(id, weapon)
			
			if(ammo < 200) 
				fm_set_user_bpammo(id, weapon, maxammo)
		}
		case 2:
		{
			static clip; clip = read_data(3)
			if(clip < 1)
			{
				static weaponname[32]
				get_weaponname(weapon, weaponname, 31)
				
				static ent 
				ent = fm_find_ent_by_owner(-1, weaponname, id)
				
				fm_set_weapon_ammo(ent, maxammo)
			}
		}
		case 3:
		{
			static ammo, weapon
			
			ammo = fm_get_user_bpammo(id, weapon)
			weapon = get_user_weapon(id)
			
			if(weapon == CSW_P228 || weapon == CSW_ELITE || weapon == CSW_FIVESEVEN 
			|| weapon == CSW_USP || weapon == CSW_GLOCK18)
			{
				if(ammo < 200) 
					fm_set_user_bpammo(id, weapon, maxammo)			
			}
		}
	}	
	return PLUGIN_CONTINUE
}

public event_armortype(id)
{
	if(!is_user_alive(id) || !g_zombie[id] || !g_boss[id])
		return PLUGIN_CONTINUE
	
	if(fm_get_user_armortype(id) != CS_ARMOR_NONE)
		fm_set_user_armortype(id, CS_ARMOR_NONE)
	
	return PLUGIN_CONTINUE
}

public event_damage(victim)
{
	if(!is_user_alive(victim) || !g_gamestarted)
		return PLUGIN_CONTINUE
	
	if(g_zombie[victim])
	{
		static Float:gametime
		gametime = get_gametime()
		
		g_regendelay[victim] = gametime + g_class_data[g_player_class[victim]][DATA_HITREGENDLY]
		g_hitdelay[victim] = gametime + g_class_data[g_player_class[victim]][DATA_HITDELAY]
	}
	else
	{
		static attacker
		attacker = get_user_attacker(victim)
		
		if(!is_user_alive(attacker) || !g_zombie[attacker] || g_infecting)
			return PLUGIN_CONTINUE
		
		if(g_victim[attacker] == victim)
		{
			g_infecting = true
			g_victim[attacker] = 0

			message_begin(MSG_ALL, g_msg_deathmsg)
			write_byte(attacker)
			write_byte(victim)
			write_byte(0)
			write_string(g_infection_name)
			message_end()
			
			message_begin(MSG_ALL, g_msg_scoreattrib)
			write_byte(victim)
			write_byte(0)
			message_end()
			
			infect_user(victim, attacker)
			
			static Float:frags, deaths
			pev(attacker, pev_frags, frags)
			deaths = fm_get_user_deaths(victim)
			
			set_pev(attacker, pev_frags, frags  + 1.0)
			fm_set_user_deaths(victim, deaths + 1)
			
			fm_set_user_money(attacker, get_pcvar_num(cvar_infectmoney))
		
			static params[2]
			params[0] = attacker 
			params[1] = victim
	
			set_task(0.3, "task_updatescore", TASKID_UPDATESCR, params, 2)
		}
		g_infecting = false
	}
	return PLUGIN_CONTINUE
}

public event_death()
{
	new attacker = read_data(1)
	new victim = read_data(2) 	
	new headshot = read_data(3)
	
	if(task_exists(victim+TASK_GLOW_DIE)) remove_task(victim+TASK_GLOW_DIE)
	set_user_rendering(victim, kRenderFxGlowShell, 0, 0, 0, kRenderNormal, 25)
	
	// Zombie Die
	if (g_zombie[victim] && !g_zombie[attacker])
	{
		UpdateLevelTeamHuman()
	}	
	
	if(g_zombie[victim] && get_pcvar_num(cvar_respawn) && !g_preinfect[victim] && headshot == 0)
	{
		set_task(get_pcvar_float(cvar_timerespawn), "do_respawn", victim+TASK_RESPAWN)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, victim)
		write_short(get_pcvar_num(cvar_timerespawn))
		message_end()
		
		client_print(victim, print_center, "Ban Se Hoi Sinh Sau: [%i] Giay", get_pcvar_num(cvar_timerespawn))
		
		set_task(2.0, "respawn_effect", victim+TASK_RESPAWN+1)
		g_sink_time[victim] = 500
		
	}
	
	if(get_pcvar_num(cvar_enable_sink))
		set_task(4.0, "sink_off", victim)	
	
	if(g_zombie[victim] && g_preinfect[victim])
	{
		client_print(victim, print_center, "First Zombie khong the Hoi Sinh...")
	} else if(g_zombie[victim] && headshot == 1) {
		client_print(victim, print_center, "Khong the Hoi Sinh khi bi HeadShot...")
	}
}

public respawn_effect(id)
{
	id -= (TASK_RESPAWN-1)
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2] + 30.0)
	write_short(g_respawn_sprid)
	write_byte(8)
	write_byte(255)
	message_end()
}

public sink_off(id)
{
	if(is_user_alive(id) || !g_zombie[id] || g_sink_time[id] < 0)
	{
		remove_task(id)
		return PLUGIN_HANDLED
	}
	
	g_sink_time[id]--
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	Origin[2] -= 1.0
	set_pev(id, pev_origin, Origin)
	
	set_task(0.1, "sink_off", id)
	
	return PLUGIN_CONTINUE
}

public do_respawn(taskid)
{
	static id
	id = taskid - TASK_RESPAWN
	
	if(g_zombie[id])
	{
		ExecuteHam(Ham_CS_RoundRespawn, id)
		client_print(id, print_center, "Hoi Sinh !!!")
	}
}

public fwd_primary_attack(ent)
{
	new id = pev(ent,pev_owner)
	pev(id,pev_punchangle, cl_pushangle[id])
	
	return HAM_IGNORED
}

public fwd_primary_attack_post(ent)
{
	new id = pev(ent,pev_owner)
	if ((!g_zombie[id] || !g_boss[id]) && g_level[id] && get_pcvar_num(cvar_level_recoil))
	{
		//Recoil Wpn
		new Float: xrecoil = XRECOIL[g_level[id]]
		new Float:push[3]
		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)
		xs_vec_mul_scalar(push,xrecoil,push)
		xs_vec_add(push,cl_pushangle[id],push)
		set_pev(id,pev_punchangle,push)
	}
	
	return HAM_IGNORED
}
public fwd_clientdisconnect_post(id)
{
	last_check()
}

public fwd_player_prethink(id)
{
	if(!is_user_alive(id) || !g_zombie[id] || !g_boss[id])
		return FMRES_IGNORED
	
	static flags
	flags = pev(id, pev_flags)
	
	if(flags & FL_ONGROUND)
	{
		if(get_pcvar_num(cvar_painshockfree))
		{
			pev(id, pev_velocity, g_vecvel)
			g_brestorevel = true
		}
	}
	else
	{
		static Float:fallvelocity
		pev(id, pev_flFallVelocity, fallvelocity)
		
		g_falling[id] = fallvelocity >= 350.0 ? true : false
	}
		
	if(g_gamestarted)
	{	
		static Float:gametime
		gametime = get_gametime()
		
		static pclass
		pclass = g_player_class[id]

		static Float:health
		pev(id, pev_health, health)
		
		if(health < g_class_data[pclass][DATA_HEALTH] && g_regendelay[id] < gametime)
		{
			set_pev(id, pev_health, health + 1.0)
			g_regendelay[id] = gametime + g_class_data[pclass][DATA_REGENDLY]
		}
	}
	return FMRES_IGNORED
}

public fwd_player_prethink_post(id)
{
	if(!g_brestorevel)
		return FMRES_IGNORED

	g_brestorevel = false
		
	static flag
	flag = pev(id, pev_flags)
	
	if(!(flag & FL_ONTRAIN))
	{
		static ent
		ent = pev(id, pev_groundentity)
		
		if(pev_valid(ent) && (flag & FL_CONVEYOR))
		{
			static Float:vectemp[3]
			pev(id, pev_basevelocity, vectemp)
			
			xs_vec_add(g_vecvel, vectemp, g_vecvel)
		}

		if(g_hitdelay[id] > get_gametime() && (!(pev(id, pev_flags) & FL_DUCKING)))
			xs_vec_mul_scalar(g_vecvel, g_class_data[g_player_class[id]][DATA_HITSPEED], g_vecvel)
	
		set_pev(id, pev_velocity, g_vecvel)
		return FMRES_HANDLED
	}
	return FMRES_IGNORED
}

public fwd_player_postthink(id)
{ 
	if(!is_user_alive(id))
		return FMRES_IGNORED
	
	if((g_zombie[id] || g_boss[id]) && g_falling[id] && (pev(id, pev_flags) & FL_ONGROUND))
	{	
		set_pev(id, pev_watertype, CONTENTS_WATER)
		g_falling[id] = false
	}
	
	if(get_pcvar_num(cvar_buytime))
	{
		if(pev_valid(g_buyzone) && g_buytime > get_gametime())
			dllfunc(DLLFunc_Touch, g_buyzone, id)
	}
	
	if(is_user_alive(id) && get_pcvar_num(cvar_readydieeffect))
	{
		if(g_zombie[id] && get_user_health(id) <= get_pcvar_num(cvar_readydieeffecthp))
		{
			set_task(0.25, "set_glow", id+TASK_GLOW_DIE)
		} else {
			if(task_exists(id+TASK_GLOW_DIE)) remove_task(id+TASK_GLOW_DIE)
		}
	}
	
	if(get_pcvar_num(cvar_autoheal_enable))
	{
		static Float:Time
		Time = get_gametime()
		
		if(Time - get_pcvar_float(cvar_autoheal_delay) > last_heal[id])
		{
			if(is_user_alive(id) && g_zombie[id] && !g_boss[id] && healing[id])
			{
				if(entity_get_float(id, EV_FL_health) < g_max_health[id])
				{	
					static Float:health
					health = entity_get_float(id, EV_FL_health)
					entity_set_float(id, EV_FL_health, health + get_pcvar_float(cvar_autoheal_amount))
					PlaySound2(id, autoheal_sound)
				} else {
					healing[id] = false
				}
			}
			last_heal[id] = Time
		}
	}
	
	return FMRES_IGNORED
}

public set_glow(taskid)
{
	static id
	id = taskid - TASK_GLOW_DIE
	
	if(glow_mode[id] == 0)
	{
		glow_mode[id] = 1
		set_user_rendering(id, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 25)
	} else {
		glow_mode[id] = 0
		set_user_rendering(id, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 25)		
	}
}
public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{	
	// Block all those unneeeded hostage sounds
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	// Replace these next sounds for zombies only
	if (!is_user_connected(id))
		return FMRES_IGNORED

	if(g_zombie[id] || g_boss[id])
	{
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			emit_sound(id, channel, g_zombie_pain_sounds[_random(sizeof g_zombie_pain_sounds)], volume, attn, flag, pitch)
			
			return FMRES_SUPERCEDE;
		}	
			
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
				return FMRES_SUPERCEDE;
			}
			
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					emit_sound(id, channel, g_zombie_wall_sounds[_random(sizeof g_zombie_wall_sounds)], volume, attn, flag, pitch)
					return FMRES_SUPERCEDE;
				} else {
					emit_sound(id, channel, g_zombie_hit_sounds[_random(sizeof g_zombie_hit_sounds)], volume, attn, flag, pitch)
					return FMRES_SUPERCEDE;
				}
			}
			
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				emit_sound(id, channel, g_zombie_hit_sounds[_random(sizeof g_zombie_hit_sounds)], volume, attn, flag, pitch)
				return FMRES_SUPERCEDE;
			}
		}	
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			emit_sound(id, channel, g_zombie_die_sounds[_random(sizeof g_zombie_die_sounds)], volume, attn, flag, pitch)
			return FMRES_SUPERCEDE;
		}
	}
		
	return FMRES_IGNORED
}

public fwd_cmdstart(id, handle, seed)
{
	if(!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	
	static impulse
	impulse = get_uc(handle, UC_Impulse)
	
	if(impulse == IMPULSE_FLASHLIGHT)
	{
		set_uc(handle, UC_Impulse, 0)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_cmdstart2(id, handle, seed)
{
	if(get_pcvar_num(cvar_autoheal_enable) && g_zombie[id])
	{
		static Float:fmove, Float:smove
	
		get_uc(handle, UC_ForwardMove, fmove)
		get_uc(handle, UC_SideMove, smove)
		fmove = floatabs(fmove)
		smove = floatabs(smove)
	
		if(fmove == 0.0 && smove == 0.0)
		{
			if(task_exists(id+TASK_HEALING))
				return FMRES_IGNORED
			
			set_task(get_pcvar_float(cvar_autoheal_timestart), "start_healing", id+TASK_HEALING)
		} else {
			remove_task(id+TASK_HEALING)
			healing[id] = false
		}
	}
	
	return FMRES_HANDLED
}

public start_healing(taskid)
{
	static id
	id = taskid - TASK_HEALING
	
	healing[id] = true
}

public fwd_spawn(ent)
{
	if(!pev_valid(ent)) 
		return FMRES_IGNORED
	
	static classname[32]
	pev(ent, pev_classname, classname, 31)

	static i
	for(i = 0; i < sizeof g_remove_entities; ++i)
	{
		if(equal(classname, g_remove_entities[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fwd_gamedescription() 
{ 
	static gamename[32], temp[32]
	get_pcvar_string(cvar_gamedescription, gamename, 31)
	format(temp, sizeof(temp), "%s %s", gamename, VERSION)
	
	
	forward_return(FMV_STRING, temp)
	
	return FMRES_SUPERCEDE
}  

public fwd_createnamedentity(entclassname)
{
	static classname[10]
	engfunc(EngFunc_SzFromIndex, entclassname, classname, 9)
	
	return (classname[7] == 'c' && classname[8] == '4') ? FMRES_SUPERCEDE : FMRES_IGNORED
}

public fwd_clientkill(id)
{
	if(get_pcvar_num(cvar_punishsuicide) && is_user_alive(id))
		g_suicide[id] = true
}

public fwd_setclientkeyvalue(id, infobuffer, const key[])
{
	static model[32]
	fm_get_user_model(id, model, 31)
	
	if(equal(model, "gordon"))
		return FMRES_IGNORED
		
	if(g_lockmodel[id])
		return FMRES_SUPERCEDE
		
	return FMRES_HANDLED
}

public fw_SetModel(entity, const model[])
{
	static owner
	owner = pev(entity, pev_owner)
	
	if (has_flaregrenade[owner] && equal(model[7], "w_sm", 4) && get_pcvar_num(cvar_flaregrenades)) // Flare
	{
		// Make the flare color
		static rgb[3]
		switch (get_pcvar_num(cvar_flarecolor))
		{
			case 0: // white
			{
				rgb[0] = 255 // r
				rgb[1] = 255 // g
				rgb[2] = 255 // b
			}
			case 1: // red
			{
				rgb[0] = random_num(50,255) // r
				rgb[1] = 0 // g
				rgb[2] = 0 // b
			}
			case 2: // green
			{
				rgb[0] = 0 // r
				rgb[1] = random_num(50,255) // g
				rgb[2] = 0 // b
			}
			case 3: // blue
			{
				rgb[0] = 0 // r
				rgb[1] = 0 // g
				rgb[2] = random_num(50,255) // b
			}
			case 4: // random (all colors)
			{
				rgb[0] = random_num(50,200) // r
				rgb[1] = random_num(50,200) // g
				rgb[2] = random_num(50,200) // b
			}
			case 5: // random (r,g,b)
			{
				switch (random_num(1, 3))
				{
					case 1: // red
					{
						rgb[0] = random_num(50,255) // r
						rgb[1] = 0 // g
						rgb[2] = 0 // b
					}
					case 2: // green
					{
						rgb[0] = 0 // r
						rgb[1] = random_num(50,255) // g
						rgb[2] = 0 // b
					}
					case 3: // blue
					{
						rgb[0] = 0 // r
						rgb[1] = 0 // g
						rgb[2] = random_num(50,255) // b
					}
				}
			}
		}
		
		// Give it a glow
		fm_set_rendering(entity, kRenderFxGlowShell, rgb[0], rgb[1], rgb[2], kRenderNormal, 16);
		
		// And a colored trail
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BEAMFOLLOW) // TE id
		write_short(entity) // entity
		write_short(g_trailSpr) // sprite
		write_byte(10) // life
		write_byte(10) // width
		write_byte(rgb[0]) // r
		write_byte(rgb[1]) // g
		write_byte(rgb[2]) // b
		write_byte(200) // brightness
		message_end()
		
		// Set grenade type on the thrown grenade entity
		set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_FLARE)
		
		// Set flare color on the thrown grenade entity
		set_pev(entity, PEV_FLARE_COLOR, rgb)
	}
}	

// Ham Weapon Touch Forward
public bacon_touch_weapon(weapon, id)
{
	// Not a player
	if (!is_user_connected(id))
		return HAM_IGNORED;
	
	// Dont pickup weapons if zombie or survivor
	if (g_zombie[id] || g_hero[id] || g_boss[id])
		return HAM_SUPERCEDE;
	
	return HAM_HANDLED
}

public bacon_use_tank(ent, caller, activator, use_type, Float:value)
	return (is_user_alive(caller) && g_zombie[caller]) ? HAM_SUPERCEDE : HAM_IGNORED

public bacon_use_pushable(ent, caller, activator, use_type, Float:value)
	return HAM_SUPERCEDE

public bacon_traceattack_player(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
	if(!g_gamestarted) 
		return HAM_SUPERCEDE
	
	if(!get_pcvar_num(cvar_knockback) || !(damagetype & DMG_BULLET))
		return HAM_IGNORED
	
	if(!is_user_connected(attacker) || !g_zombie[victim])
		return HAM_IGNORED
	
	static kbpower
	kbpower = g_weapon_knockback[get_user_weapon(attacker)]
	
	if(kbpower != -1) 
	{
		static flags
		flags = pev(victim, pev_flags)
		
		if(get_pcvar_num(cvar_knockback_duck) && ((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
			return HAM_IGNORED
		
		static Float:origins[2][3]
		pev(victim, pev_origin, origins[0])
		pev(attacker, pev_origin, origins[1])

		static Float:velocity[3]
		pev(victim, pev_velocity, velocity)
		
		static Float:tempvec
		tempvec = velocity[2]	
		
		// Use damage on knockback calculation
		if(get_pcvar_num(cvar_knockback_damage))
			xs_vec_mul_scalar(direction, damage, direction)
			
		if(get_pcvar_num(cvar_knockback_power) && g_knockbackpower[kbpower] > 0.0)
			xs_vec_mul_scalar(direction, g_knockbackpower[kbpower], direction)
		if(get_pcvar_num(cvar_knockback_bydata))
			xs_vec_mul_scalar(direction, g_class_data[g_player_class[victim]][DATA_KNOCKBACK], direction)
		
		xs_vec_add(direction, velocity, velocity)
		velocity[2] = tempvec
		
		set_pev(victim, pev_velocity, velocity)
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public bacon_touch_grenade(ent, world)
{
	if(!get_pcvar_num(cvar_impactexplode))
		return HAM_IGNORED
	
	static model[12]
	pev(ent, pev_model, model, 11)
	
	if(model[9] == 'h' && model[10] == 'e')
	{
		set_pev(ent, pev_dmgtime, 0.0)
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public bacon_deploy_post(weapon_ent)
{
	// Get weapon's owner
	static owner
	owner = get_pdata_cbase(weapon_ent, 41, 4);
	
	// Get weapon's id
	static weaponid
	weaponid = cs_get_weapon_id(weapon_ent)

	// Zombie not holding an allowed weapon for some reason
	if (g_zombie[owner] && !((1<<weaponid) & ZOMBIE_ALLOWED_WEAPONS_BITSUM))
	{
		// Switch to knife
		engclient_cmd(owner, "weapon_knife")

		set_pev(owner, pev_weaponmodel2, "")
		set_pev(owner, pev_viewmodel2, g_class_wmodel[g_player_class[owner]])
	}
	
	if(g_zombie[owner] && (1<<weaponid & (1<<CSW_KNIFE)))
	{
		set_pev(owner, pev_weaponmodel2, "")
		set_pev(owner, pev_viewmodel2, g_class_wmodel[g_player_class[owner]])
	}
	
}

// Ham Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	static owner
	owner = pev(entity, pev_owner)
	
	if(!has_flaregrenade[owner])
		return HAM_IGNORED
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_FLARE: // Flare
		{			
			// Light up when it's stopped on ground
			if ((pev(entity, pev_flags) & FL_ONGROUND) && fm_get_speed(entity) < 10)
			{
				// Flare sound
				engfunc(EngFunc_EmitSound, entity, CHAN_WEAPON, grenade_flare[random_num(0, sizeof grenade_flare - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				// Our task params
				static params[5]
				params[0] = entity // entity id
				params[1] = get_pcvar_num(cvar_flareduration)/5 // duration
				
				// Retrieve flare color from entity
				pev(entity, PEV_FLARE_COLOR, params[2]) // params[2] r - params[3] g - params[4] b
				
				// Call our lighting task
				set_task(0.1, "flare_lighting", TASK_NADES, params, sizeof params)
			}
			else
			{
				// Delay the explosion until we hit ground
				set_pev(entity, pev_dmgtime, get_gametime() + 0.5)
				return HAM_IGNORED;
			}
		}
		default: return HAM_IGNORED;
	}
	
	return HAM_SUPERCEDE
}
// Flare Lighting
public flare_lighting(args[5])
{
	// Unexistant flare entity?
	if (!pev_valid(FLARE_ENTITY))
		return;
	
	// Flare depleted -clean up the mess-
	if (FLARE_DURATION <= 0)
	{
		engfunc(EngFunc_RemoveEntity, FLARE_ENTITY)
		return;
	}
	
	// Get origin
	static Float:originF[3]
	pev(FLARE_ENTITY, pev_origin, originF)
	
	// Lighting
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(get_pcvar_num(cvar_flaresize)) // radius
	write_byte(FLARE_R) // r
	write_byte(FLARE_G) // g
	write_byte(FLARE_B) // b
	write_byte(51) //life
	write_byte((FLARE_DURATION < 2) ? 3 : 0) //decay rate
	message_end()
	
	// Sparks
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPARKS) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	message_end()
	
	// Decrease task cycle counter
	FLARE_DURATION -= 1;
	
	// Keep sending flare messaegs
	set_task(5.0, "flare_lighting", TASK_NADES, args, sizeof args)
}

public bacon_takedamage_player(victim, inflictor, attacker, Float:damage, damagetype)
{
	if(damagetype & DMG_GENERIC || victim == attacker || !is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED

	if(!g_gamestarted || ((damagetype & DMG_HEGRENADE) && g_zombie[attacker]) || mutating[victim])
		return HAM_SUPERCEDE
		
	if(g_zombie[victim] && healing[victim])
		healing[victim] = false
	
	if(!g_zombie[attacker] && !g_boss[attacker])
	{
		// X Damage
		if (g_level[attacker] && !g_zombie[attacker] && !g_boss[attacker] && !g_hero[attacker])
		{
			new Float: xdmg = XDAMAGE[g_level[attacker]]
			damage *= xdmg
		}

		SetHamParamFloat(4, damage)
		
		damage *= (damagetype & DMG_HEGRENADE) ? g_class_data[g_player_class[victim]][DATA_HEDEFENCE] : g_class_data[g_player_class[victim] ][DATA_DEFENCE]

		if(g_hero[attacker] && get_user_weapon(attacker) == CSW_KNIFE)
			SetHamParamFloat(4, damage + get_pcvar_float(cvar_hero_knife_damage))
	}
	else if(g_zombie[attacker])
	{
		if(get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_SUPERCEDE

		damage *= g_class_data[g_player_class[attacker]][DATA_ATTACK]
		
		static Float:armor
		pev(victim, pev_armorvalue, armor)
		
		if(get_pcvar_num(cvar_obeyarmor) && armor > 0.0)
		{
			armor -= damage
			
			if(armor < 0.0) 
				armor = 0.0
			
			set_pev(victim, pev_armorvalue, armor)
			SetHamParamFloat(4, 0.0)
		}
		else
		{
			static bool:infect
			infect = allow_infection()
			
			g_victim[attacker] = infect ? victim : 0
					
			if(!g_infecting)
				SetHamParamFloat(4, infect ? 0.0 : damage)
			else	
				SetHamParamFloat(4, 0.0)
		}
	} else if(!g_zombie[attacker] && g_boss[attacker]) {
		SetHamParamFloat(4, damage * 10.0)
	}
	
	return HAM_HANDLED
}

public bacon_killed_player(victim, killer, shouldgib)
{
	if(!is_user_alive(killer) || g_zombie[killer] || !g_zombie[victim] || g_hero[killer])
		return HAM_IGNORED
	
	static killbonus
	killbonus = get_pcvar_num(cvar_killbonus)
	
	if(killbonus)
		set_pev(killer, pev_frags, pev(killer, pev_frags) + float(killbonus))
	
	static killreward
	killreward = get_pcvar_num(cvar_killreward)
	
	if(!killreward) 
		return HAM_IGNORED
	
	static weapon, maxclip, ent, weaponname[32]
	switch(killreward)
	{
		case 1: 
		{
			weapon = get_user_weapon(killer)
			maxclip = g_weapon_ammo[weapon][MAX_CLIP]
			if(maxclip)
			{
				get_weaponname(weapon, weaponname, 31)
				ent = fm_find_ent_by_owner(-1, weaponname, killer)
					
				fm_set_weapon_ammo(ent, maxclip)
			}
		}
		case 2:
		{
			if(!user_has_weapon(killer, CSW_HEGRENADE))
			{
				has_flaregrenade[killer] = true
				bacon_give_weapon(killer, "weapon_hegrenade")
			}
		}
		case 3:
		{
			weapon = get_user_weapon(killer)
			maxclip = g_weapon_ammo[weapon][MAX_CLIP]
			if(maxclip)
			{
				get_weaponname(weapon, weaponname, 31)
				ent = fm_find_ent_by_owner(-1, weaponname, killer)
					
				fm_set_weapon_ammo(ent, maxclip)
			}
				
			if(!user_has_weapon(killer, CSW_HEGRENADE))
				bacon_give_weapon(killer, "weapon_hegrenade")
		}
	}
	
	remove_task(victim+TASK_BLOOD)
	last_check()
	
	return HAM_IGNORED
}

public bacon_spawn_player_post(id)
{	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED
	
	static team
	team = fm_get_user_team(id)
	
	if(team != CS_TEAM_T && team != CS_TEAM_CT)
		return HAM_IGNORED
	
	RemoveGlowShell(id+TASK_GLOWSHELL)
	remove_task(id+TASK_AURA)
	remove_task(id+TASK_BLOOD)
	
	if(g_zombie[id] && !g_boss[id])
	{
		if(get_pcvar_num(cvar_respawnaszombie) && !g_roundended)
		{
			set_zombie_attibutes(id)
			
			return HAM_IGNORED
		}
		else
		{
			cure_user(id)
			bacon_spawn_player_post(id)
		}
	} else if(!g_zombie[id] && g_boss[id]) {
		cure_user(id)
	} else {
		g_point[id] = 0
		g_level[id] = 0
		
		static Float:health
		health = get_pcvar_float(cvar_humanhealth)
		g_max_health[id] = health
		entity_set_float(id, EV_FL_health, health)
		
		add_delay(id, "fm_reset_user_model")
		has_flaregrenade[id] = true
		
		if(g_hero[id])
		{
			g_hero[id] = false
			set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
		}
	}

	g_lasthuman[id] = false
	
	set_task(0.3, "task_spawned", TASKID_SPAWNDELAY + id)
	set_task(5.0, "task_checkspawn", TASKID_CHECKSPAWN + id)
	
	last_check()

	return HAM_IGNORED
}

public bacon_touch_pushable(ent, id)
{
	static movetype
	pev(id, pev_movetype)
	
	if(movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_NONE)
		return HAM_IGNORED	
	
	if(is_user_alive(id))
	{
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		
		if(!(pev(id, pev_flags) & FL_ONGROUND))
			return HAM_SUPERCEDE
	}
	
	if(!get_pcvar_num(cvar_shootobjects))
		return HAM_IGNORED
	
	static Float:velocity[2][3]
	pev(ent, pev_velocity, velocity[0])
	
	if(vector_length(velocity[0]) > 0.0)
	{
		pev(id, pev_velocity, velocity[1])
		velocity[1][0] += velocity[0][0]
		velocity[1][1] += velocity[0][1]
		
		set_pev(id, pev_velocity, velocity[1])
	}
	return HAM_SUPERCEDE
}

public bacon_traceattack_pushable(ent, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
	if(!get_pcvar_num(cvar_shootobjects) || !is_user_alive(attacker))
		return HAM_IGNORED
	
	static Float:velocity[3]
	pev(ent, pev_velocity, velocity)
			
	static Float:tempvec
	tempvec = velocity[2]	
			
	xs_vec_mul_scalar(direction, damage, direction)
	xs_vec_mul_scalar(direction, g_zombie[attacker] ? 
	get_pcvar_float(cvar_pushpwr_zombie) : get_pcvar_float(cvar_pushpwr_weapon), direction)
	xs_vec_add(direction, velocity, velocity)
	velocity[2] = tempvec
	
	set_pev(ent, pev_velocity, velocity)
	
	return HAM_HANDLED
}
public task_spawned(taskid)
{
	static id
	id = taskid - TASKID_SPAWNDELAY
	
	if(is_user_alive(id))
	{
		if(g_welcomemsg[id])
		{
			g_welcomemsg[id] = false
			
			static message[192]
			formatex(message, 191, "%L", id, "WELCOME_TXT")
			replace(message, 191, "#Version#", VERSION)
			
			client_print(id, print_chat, message)
		}
		
		if(g_suicide[id])
		{
			g_suicide[id] = false
			
			user_silentkill(id)
			remove_task(TASKID_CHECKSPAWN + id)

			client_print(id, print_chat, "%L", id, "SUICIDEPUNISH_TXT")
			
			return
		}
		
		if(get_pcvar_num(cvar_weaponsmenu) && g_roundstarted && g_showmenu[id])
		{
			if(is_user_bot(id))
			{
				bot_weapons(id)
			} else {
				static menu
				menu = menu_create("Select Weapon Shop", "select_wp_shop")
				
				menu_additem(menu, "Default Weapon (Free)", "0")
				menu_additem(menu, "Extra Weapon (Required: Money)", "1")
				
				menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
				menu_display(id, menu)
			}
		}
		
		client_printc(id, "!g[Bio]!n Press !t,!n of !t.!n to !tBuy Ammo!n !!!")
		
		if(!g_gamestarted)
		{
			//static temp[64]
			//formatex(temp, sizeof(temp), "%L %L", id, "SCAN_RESULTS", id, g_preinfect[id] ? "SCAN_INFECTED" : "SCAN_CLEAN")
			
			//client_printc(id, temp)
			//client_print(id, print_chat, "%L %L", id, "SCAN_RESULTS", id, g_preinfect[id] ? "SCAN_INFECTED" : "SCAN_CLEAN")
		}
		else
		{
			static team
			team = fm_get_user_team(id)
			
			if(team == CS_TEAM_T)
				fm_set_user_team(id, CS_TEAM_CT)
		}
	}
}

public select_wp_shop(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	
	static data[6], szName[64], access1, callback
	static temp_integer1
	menu_item_getinfo(menu, item, access1, data, charsmax(data), szName, charsmax(szName), callback)
	
	temp_integer1 = str_to_num(data)
	
	if(temp_integer1 == 0)
	{
		display_equipmenu(id)
	} else if(temp_integer1 == 1) {
		bio_open_shop(id)
		
		g_menufailsafe[id] = false
		if(TASKID_WEAPONSMENU + id) remove_task(TASKID_WEAPONSMENU + id)
	}
	
	return PLUGIN_CONTINUE
}

public task_checkspawn(taskid)
{
	static id
	id = taskid - TASKID_CHECKSPAWN
	
	if(!is_user_connected(id) || is_user_alive(id) || g_roundended)
		return
	
	static team
	team = fm_get_user_team(id)
	
	if(team == CS_TEAM_T || team == CS_TEAM_CT)
		ExecuteHamB(Ham_CS_RoundRespawn, id)
}
	
public task_showtruehealth()
{
	static id, class
	for(id = 1; id <= g_maxplayers; id++) 
	{
		if(is_user_alive(id) && !is_user_bot(id) && g_zombie[id])
		{
			class = g_player_class[id]
			set_hudmessage(0, 255, 0, 0.03, 0.87, 0, 0.2, 0.2)
			static temp[100]
			format(temp, sizeof(temp), "Class: %s^nSkill: %s", g_class_name[class], g_class_desc[class])
			
			ShowSyncHudMsg(id, g_sync_hpdisplay, temp)
		} else if(is_user_alive(id) && !is_user_bot(id) && !g_zombie[id] && !g_hero[id]) {
			level_damage[id] = (g_level[id]*10)+100
			static max_point1 
			max_point1 = MAX_POINT
			
			set_hudmessage(0, 255, 0, 0.03, 0.90, 0, 0.2, 0.2)

			if(max_point1 > 1)
			{
				ShowSyncHudMsg(id, g_sync_hpdisplay, "Level: %i [Point: %i/%i] - Damage: %i%", g_level[id], g_point[id], MAX_POINT, level_damage[id])
			} else {
				ShowSyncHudMsg(id, g_sync_hpdisplay, "Level: %i - Damage: %i%", g_level[id], level_damage[id])
			}
		} else if(is_user_alive(id) && !is_user_bot(id) && !g_zombie[id] && g_hero[id]) {
			set_hudmessage(0, 255, 0, 0.03, 0.90, 0, 0.2, 0.2)
			ShowSyncHudMsg(id, g_sync_hpdisplay, "Class: Hero")
		} else if(is_user_alive(id) && !is_user_bot(id) && !g_zombie[id] && !g_hero[id] && g_boss[id]) {
			set_hudmessage(0, 255, 0, 0.03, 0.90, 0, 0.2, 0.2)
			ShowSyncHudMsg(id, g_sync_hpdisplay, "Class: Nemesis")
		}
	}
}

public task_showday()
{
	if(!get_pcvar_num(cvar_day_system))
		return PLUGIN_HANDLED
		
	if(!g_boss_round)
	{
		static color[3]
		color[0] = get_color_day(0)
		color[1] = get_color_day(1)
		color[2] = get_color_day(2)
			
		static day_health
		day_health = (g_day*10)+100
		set_hudmessage(color[0], color[1], color[2], 0.50, 0.15, 2, 7.0, 7.0)
		ShowSyncHudMsg(0, g_sync_msgdisplay, "Day: %i - %s^nZombie Health: %i%%^nLight: %s", g_day, g_day_name[g_day], day_health, light_day[g_day])
	} else {
		static color[3]
		color[0] = get_color_day(0)
		color[1] = get_color_day(1)
		color[2] = get_color_day(2)
			
		set_hudmessage(color[0], color[1], color[2], 0.50, 0.15, 2, 7.0, 7.0)
		ShowSyncHudMsg(0, g_sync_msgdisplay, "Day: %i - %s^nLight: %s^nLet's Preparing^nThis is the final day. We will meet the Nemesis", g_day, g_day_name[g_day], light_day[g_day])		
	}
	
	return PLUGIN_CONTINUE
}

public task_lights()
{
	if(get_pcvar_num(cvar_auto_light))
	{
		set_lights(light_day[g_day])
	} else {
		new tempstring[5]
		get_pcvar_string(cvar_lights, tempstring, sizeof(tempstring))
		
		set_lights(tempstring)
	}
}

public task_updatescore(params[])
{
	if(!g_gamestarted) 
		return
	
	static attacker
	attacker = params[0]
	
	static victim
	victim = params[1]
	
	if(!is_user_connected(attacker))
		return

	static frags, deaths, team
	frags  = get_user_frags(attacker)
	deaths = fm_get_user_deaths(attacker)
	team   = get_user_team(attacker)
	
	message_begin(MSG_BROADCAST, g_msg_scoreinfo)
	write_byte(attacker)
	write_short(frags)
	write_short(deaths)
	write_short(0)
	write_short(team)
	message_end()
	
	if(!is_user_connected(victim))
		return
	
	frags  = get_user_frags(victim)
	deaths = fm_get_user_deaths(victim)
	team   = get_user_team(victim)
	
	message_begin(MSG_BROADCAST, g_msg_scoreinfo)
	write_byte(victim)
	write_short(frags)
	write_short(deaths)
	write_short(0)
	write_short(team)
	message_end()
}

public task_weaponsmenu(taskid)
{
	static id
	id = taskid - TASKID_WEAPONSMENU
	
	if(is_user_alive(id) && !g_zombie[id] && !g_boss[id] && g_menufailsafe[id])
		display_equipmenu(id)
}

public task_stripngive(taskid)
{
	static id
	id = taskid - TASKID_STRIPNGIVE
	
	if(is_user_alive(id) && g_zombie[id] && !g_boss[id])
	{
		//fm_strip_user_weapons(id)
		//fm_reset_user_primary(id)

		if(!get_pcvar_num(cvar_mutatingenable))
		{
			bacon_give_weapon(id, "weapon_knife")
		
			set_pev(id, pev_weaponmodel2, "")
			set_pev(id, pev_viewmodel2, g_class_wmodel[g_player_class[id]])
			set_pev(id, pev_maxspeed, g_class_data[g_player_class[id]][DATA_SPEED])
			set_pev(id, pev_gravity, g_class_data[g_player_class[id]][DATA_GRAVITY])
		} else {
			if(can_mutating[id])
			{
				set_pev(id, pev_weaponmodel2, "")
				set_pev(id, pev_maxspeed, 0.00001)
				set_pev(id, pev_gravity, g_class_data[g_player_class[id]][DATA_GRAVITY])
				
				mutating[id] = true
				
				set_task(get_pcvar_float(cvar_mutatingtime), "finish_mutating", id+TASK_MUTATING)
				
				client_print(id, print_center, "[Dang chuyen hoa...]")
				
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, id)
				write_short(get_pcvar_num(cvar_mutatingtime))
				message_end()
			} else {
				bacon_give_weapon(id, "weapon_knife")
			
				set_pev(id, pev_weaponmodel2, "")
				set_pev(id, pev_viewmodel2, g_class_wmodel[g_player_class[id]])
				set_pev(id, pev_maxspeed, g_class_data[g_player_class[id]][DATA_SPEED])
				set_pev(id, pev_gravity, g_class_data[g_player_class[id]][DATA_GRAVITY])	
			}
		}
		can_mutating[id] = false
		
	} else if(is_user_alive(id) && g_hero[id]) {
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_hero_speed))		
	} else if(is_user_alive(id) && g_boss[id]) {
		//fm_strip_user_weapons(id)
		//fm_reset_user_primary(id)
		bacon_give_weapon(id, "weapon_knife")	
		
		set_pev(id, pev_weaponmodel2, "")
		set_pev(id, pev_viewmodel2, g_boss_claws)
	}
}

public finish_mutating(taskid)
{
	new id = taskid - TASK_MUTATING
	mutating[id] = false
	if(is_user_alive(id) && g_zombie[id])
	{
		bacon_give_weapon(id, "weapon_knife")
		
		set_pev(id, pev_weaponmodel2, "")
		set_pev(id, pev_viewmodel2, g_class_wmodel[g_player_class[id]])
		set_pev(id, pev_maxspeed, g_class_data[g_player_class[id]][DATA_SPEED])
	}
}

public task_newround()
{
	static players[32], num, zombies, i, id
	get_players(players, num, "a")

	if(num > 1)
	{
		for(i = 0; i < num; i++) 
			g_preinfect[players[i]] = false
		
		zombies = clamp(floatround(num * get_pcvar_float(cvar_zombiemulti)), 1, 31)
		
		i = 0
		while(i < zombies)
		{
			id = players[_random(num)]
			if(!g_preinfect[id])
			{
				g_preinfect[id] = true
				i++
			}
		}
	}
	
	if(!get_pcvar_num(cvar_randomspawn) || g_spawncount <= 0) 
		return
	
	static team
	for(i = 0; i < num; i++)
	{
		id = players[i]
		
		team = fm_get_user_team(id)
		if(team != CS_TEAM_T && team != CS_TEAM_CT || pev(id, pev_iuser1))
			continue
		
		static spawn_index
		spawn_index = _random(g_spawncount)
	
		static Float:spawndata[3]
		spawndata[0] = g_spawns[spawn_index][0]
		spawndata[1] = g_spawns[spawn_index][1]
		spawndata[2] = g_spawns[spawn_index][2]
		
		if(!fm_is_hull_vacant(spawndata, HULL_HUMAN))
		{
			static i
			for(i = spawn_index + 1; i != spawn_index; i++)
			{
				if(i >= g_spawncount) i = 0

				spawndata[0] = g_spawns[i][0]
				spawndata[1] = g_spawns[i][1]
				spawndata[2] = g_spawns[i][2]

				if(fm_is_hull_vacant(spawndata, HULL_HUMAN))
				{
					spawn_index = i
					break
				}
			}
		}

		spawndata[0] = g_spawns[spawn_index][0]
		spawndata[1] = g_spawns[spawn_index][1]
		spawndata[2] = g_spawns[spawn_index][2]
		engfunc(EngFunc_SetOrigin, id, spawndata)

		spawndata[0] = g_spawns[spawn_index][3]
		spawndata[1] = g_spawns[spawn_index][4]
		spawndata[2] = g_spawns[spawn_index][5]
		set_pev(id, pev_angles, spawndata)

		spawndata[0] = g_spawns[spawn_index][6]
		spawndata[1] = g_spawns[spawn_index][7]
		spawndata[2] = g_spawns[spawn_index][8]
		set_pev(id, pev_v_angle, spawndata)

		set_pev(id, pev_fixangle, 1)
	}
}

public task_initround()
{
	task_lights()
	
	static zombiecount, newzombie
	zombiecount = 0
	newzombie = 0

	static players[32], num, i, id
	get_players(players, num, "a")

	for(i = 0; i < num; i++) if(g_preinfect[players[i]])
	{
		newzombie = players[i]
		zombiecount++
	}
	
	if(zombiecount > 1) 
		newzombie = 0
	else if(zombiecount < 1) 
		newzombie = players[_random(num)]
	
	for(i = 0; i < num; i++)
	{
		id = players[i]
		if(id == newzombie || g_preinfect[id])
		{
			// PlaySound(g_appear_sounds[random_num(0, charsmax(g_appear_sounds))])
			infect_user(id, 0)
		}
		else
		{
			fm_set_user_team(id, CS_TEAM_CT, 0)
			add_delay(id, "update_team")
		}
	}
	
	if(get_pcvar_num(cvar_zombie_appear_sound) == 2)
		PlaySound(g_appear_sounds[random_num(0, charsmax(g_appear_sounds))])
	
	set_hudmessage(0, 255, 0, _, _, 1)
	if(newzombie)
	{
		static name[32]
		get_user_name(newzombie, name, 31)
		
		ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "INFECTED_HUD", name)
		
		static temp[64]
		formatex(temp, sizeof(temp), "%L", LANG_PLAYER, "INFECTED_TXT", name)
		
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
				client_printc(i, temp)
		}
		
		//client_print(0, print_chat, "%L", LANG_PLAYER, "INFECTED_TXT", name)
	}
	else
	{
		static temp[64]
		formatex(temp, sizeof(temp), "%L", LANG_PLAYER, "INFECTED_TXT2")

		ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "INFECTED_HUD2")
		
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
				client_printc(i, temp)
		}
		
		//client_print(0, print_chat, "%L", LANG_PLAYER, "INFECTED_TXT2")
	}
	
	set_cvar_num("semiclip", 0)
	set_task(0.51, "task_startround", TASKID_STARTROUND)

	last_check()
}

public task_initbossround()
{
	task_lights()
	
	static zombiecount, newzombie
	zombiecount = 0
	newzombie = 0

	static players[32], num, i, id
	get_players(players, num, "a")

	for(i = 0; i < num; i++) if(g_preinfect[players[i]])
	{
		newzombie = players[i]
		zombiecount++
	}
	
	if(zombiecount > 1) 
		newzombie = 0
	else if(zombiecount < 1) 
		newzombie = players[_random(num)]
	
	for(i = 0; i < num; i++)
	{
		id = players[i]
		if(id == newzombie || g_preinfect[id])
		{
			PlaySound(g_boss_appear_sounds[random_num(0, charsmax(g_boss_appear_sounds))])
			make_user_boss(id)
		}
		else
		{
			fm_set_user_team(id, CS_TEAM_CT, 0)
			add_delay(id, "update_team")
		}
	}
	
	set_hudmessage(0, 255, 0, _, _, 1)
	if(newzombie)
	{
		static name[32]
		get_user_name(newzombie, name, 31)
		
		ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "BOSS_APPEAR_HUD", name)
		
		static temp[64]
		formatex(temp, sizeof(temp), "%L", LANG_PLAYER, "BOSS_APPEAR_TXT", name)
		
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
				client_printc(i, temp)
		}
		
		//client_print(0, print_chat, "%L", LANG_PLAYER, "BOSS_APPEAR_TXT", name)
	}
	else
	{
		ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "BOSS_APPEAR_HUD2")
		
		static temp[64]
		formatex(temp, sizeof(temp), "%L", LANG_PLAYER, "BOSS_APPEAR_TXT2")
		
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i))
				client_printc(i, temp)
		}
		
		//client_print(0, print_chat, "%L", LANG_PLAYER, "BOSS_APPEAR_TXT2")
	}

	set_task(3.0, "set_nem_day_lv", TASK_LEVEL_NEM)
	
	set_cvar_num("semiclip", 0)
	set_task(0.51, "task_startround", TASKID_STARTROUND)
	
	if(task_exists(TASK_COUNTDOWN)) remove_task(TASK_COUNTDOWN)
	
	last_check()
}

public set_nem_day_lv()
{
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_connected(i) && !g_boss[i] && !g_zombie[i])
		{
			g_level[i] = MAX_LEVEL_HUMAN
			g_point[i] = MAX_POINT
			
			client_printc(i, "!g[Bio] !nTo day is Nemesis Day. You got !tMAX !nLevel and !tMAX !nPoint !!!")
		}
	}	
}

public task_startround()
{
	g_gamestarted = true
	ExecuteForward(g_fwd_gamestart, g_fwd_result)
}

public task_balanceteam()
{
	static players[3][32], count[3]
	get_players(players[CS_TEAM_UNASSIGNED], count[CS_TEAM_UNASSIGNED])
	
	count[CS_TEAM_T] = 0
	count[CS_TEAM_CT] = 0
	
	static i, id, team
	for(i = 0; i < count[CS_TEAM_UNASSIGNED]; i++)
	{
		id = players[CS_TEAM_UNASSIGNED][i] 
		team = fm_get_user_team(id)
		
		if(team == CS_TEAM_T || team == CS_TEAM_CT)
			players[team][count[team]++] = id
	}

	if(abs(count[CS_TEAM_T] - count[CS_TEAM_CT]) <= 1) 
		return

	static maxplayers
	maxplayers = (count[CS_TEAM_T] + count[CS_TEAM_CT]) / 2
	
	if(count[CS_TEAM_T] > maxplayers)
	{
		for(i = 0; i < (count[CS_TEAM_T] - maxplayers); i++)
			fm_set_user_team(players[CS_TEAM_T][i], CS_TEAM_CT, 0)
	}
	else
	{
		for(i = 0; i < (count[CS_TEAM_CT] - maxplayers); i++)
			fm_set_user_team(players[CS_TEAM_CT][i], CS_TEAM_T, 0)
	}
}

public task_botclient_pdata(id) 
{
	if(g_botclient_pdata || !is_user_connected(id))
		return
	
	if(get_pcvar_num(cvar_botquota) && is_user_bot(id))
	{
		RegisterHamFromEntity(Ham_TakeDamage, id, "bacon_takedamage_player")
		RegisterHamFromEntity(Ham_Killed, id, "bacon_killed_player")
		RegisterHamFromEntity(Ham_TraceAttack, id, "bacon_traceattack_player")
		RegisterHamFromEntity(Ham_Spawn, id, "bacon_spawn_player_post", 1)
		
		g_botclient_pdata = 1
	}
}

public bot_weapons(id)
{
	g_player_weapons[id][0] = _random(sizeof g_primaryweapons)
	g_player_weapons[id][1] = _random(sizeof g_secondaryweapons)
	
	equipweapon(id, EQUIP_ALL)
}

public update_team(id)
{
	if(!is_user_connected(id))
		return
	
	static team
	team = fm_get_user_team(id)
	
	if(team == CS_TEAM_T || team == CS_TEAM_CT)
	{
		emessage_begin(MSG_ALL, g_msg_teaminfo)
		ewrite_byte(id)
		ewrite_string(g_teaminfo[team])
		emessage_end()
	}
}

public infect_user(victim, attacker)
{
	if(!is_user_alive(victim))
		return

	message_begin(MSG_ONE, g_msg_screenfade, _, victim)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0)
	write_byte((g_mutate[victim] != -1) ? 255 : 100)
	write_byte(100)
	write_byte(100)
	write_byte(250)
	message_end()
	
	if(g_mutate[victim] != -1)
	{
		g_player_class[victim] = g_mutate[victim]
		g_mutate[victim] = -1
		
		set_hudmessage(_, _, _, _, _, 1)
		ShowSyncHudMsg(victim, g_sync_msgdisplay, "%L", victim, "MUTATION_HUD", g_class_name[g_player_class[victim]])
	}
	
	fm_set_user_team(victim, CS_TEAM_T)
	
	set_zombie_attibutes(victim)
	
	PlaySound(g_scream_sounds[_random(sizeof g_scream_sounds)])
	ExecuteForward(g_fwd_infect, g_fwd_result, victim, attacker)
}

public make_user_boss(id)
{
	if(!is_user_alive(id))
		return
		
	if(had_boss)
		return

	if(g_mutate[id] != -1)
	{
		g_player_class[id] = g_mutate[id]
		g_mutate[id] = -1
		
		set_hudmessage(_, _, _, _, _, 1)
		ShowSyncHudMsg(id, g_sync_msgdisplay, "%L", id, "MUTATION_HUD", g_class_name[g_player_class[id]])
	}	
		
	fm_set_user_team(id, CS_TEAM_T)
	set_boss_attibutes(id)
	
	set_task(0.2, "boss_aura", id+TASK_AURA, _, _, "b")
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && is_user_connected(i) && !g_zombie[i] && !g_boss[i])
		{
			set_task(0.2, "player_light", i+TASK_AURA, _, _, "b")
		}
	}
	
	ExecuteForward(g_fwd_infect, g_fwd_result, id, id)
	had_boss = true
}

public boss_aura(taskid)
{
	static id
	id = taskid - TASK_AURA

	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(get_pcvar_num(cvar_nemesis_aura_r)) // r
	write_byte(get_pcvar_num(cvar_nemesis_aura_g)) // g
	write_byte(get_pcvar_num(cvar_nemesis_aura_b)) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

public player_light(taskid)
{
	static id
	id = taskid - TASK_AURA
	
	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(100) // r
	write_byte(100) // g
	write_byte(100) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

public cure_user(id)
{
	if(!is_user_alive(id) || !is_user_connected(id)) 
		return

	g_zombie[id] = false
	g_boss[id] = false
	g_falling[id] = false

	// fm_reset_user_model(id)
	fm_set_user_nvg(id, 0)
	set_pev(id, pev_gravity, 1.0)
	
	static viewmodel[64]
	pev(id, pev_viewmodel2, viewmodel, 63)
	
	if(equal(viewmodel, g_class_wmodel[g_player_class[id]]))
	{
		static weapon 
		weapon = fm_lastknife(id)

		if(pev_valid(weapon))
			ExecuteHam(Ham_Item_Deploy, weapon)
	}
}

public display_equipmenu(id)
{
	static menubody[512], len
  	len = formatex(menubody, 511, "\y%L^n^n", id, "MENU_TITLE1")
	
	static bool:hasweap
	hasweap = ((g_player_weapons[id][0]) != -1 && (g_player_weapons[id][1] != -1)) ? true : false
	
	len += formatex(menubody[len], 511 - len,"\w1. %L^n", id, "MENU_NEWWEAPONS")
	len += formatex(menubody[len], 511 - len,"%s2. %L^n", hasweap ? "\w" : "\d", id, "MENU_PREVSETUP")
	len += formatex(menubody[len], 511 - len,"%s3. %L^n^n", hasweap ? "\w" : "\d", id, "MENU_DONTSHOW")
	len += formatex(menubody[len], 511 - len,"\w5. %L^n", id, "MENU_EXIT")
	
	static keys
	keys = (MENU_KEY_1|MENU_KEY_5)
	
	if(hasweap) 
		keys |= (MENU_KEY_2|MENU_KEY_3)
	
	show_menu(id, keys, menubody, -1, "Equipment")
}

public action_equip(id, key)
{
	if(!is_user_alive(id) || g_zombie[id])
		return PLUGIN_HANDLED
	
	switch(key)
	{
		case 0: display_weaponmenu(id, MENU_PRIMARY, g_menuposition[id] = 0)
		case 1: equipweapon(id, EQUIP_ALL)
		case 2:
		{
			g_showmenu[id] = false
			equipweapon(id, EQUIP_ALL)
			client_print(id, print_chat, "%L", id, "MENU_CMDENABLE")
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
	maxitem = menuid == MENU_PRIMARY ? sizeof g_primaryweapons : sizeof g_secondaryweapons

  	if(start >= maxitem)
    		start = pos = g_menuposition[id]
	
	static menubody[512], len
  	len = formatex(menubody, 511, "\y%L\w^n^n", id, menuid == MENU_PRIMARY ? "MENU_TITLE2" : "MENU_TITLE3")

	static end
	end = start + 8
	if(end > maxitem)
    		end = maxitem
	
	static keys
	keys = MENU_KEY_0
	
	static a, b
	b = 0
	
  	for(a = start; a < end; ++a) 
	{
		keys |= (1<<b)
		len += formatex(menubody[len], 511 - len,"%d. %s^n", ++b, menuid == MENU_PRIMARY ? g_primaryweapons[a][0]: g_secondaryweapons[a][0])
  	}

  	if(end != maxitem)
	{
    		formatex(menubody[len], 511 - len, "^n9. %L^n0. %L", id, "MENU_MORE", id, pos ? "MENU_BACK" : "MENU_EXIT")
    		keys |= MENU_KEY_9
  	}
  	else	
		formatex(menubody[len], 511 - len, "^n0. %L", id, pos ? "MENU_BACK" : "MENU_EXIT")
	
  	show_menu(id, keys, menubody, -1, menuid == MENU_PRIMARY ? "Primary" : "Secondary")
}

public action_prim(id, key)
{
	if(!is_user_alive(id) || g_zombie[id] || g_boss[id])
		return PLUGIN_HANDLED

	switch(key)
	{
    		case 8: display_weaponmenu(id, MENU_PRIMARY, ++g_menuposition[id])
		case 9: display_weaponmenu(id, MENU_PRIMARY, --g_menuposition[id])
    		default:
		{
			g_player_weapons[id][0] = g_menuposition[id] * 8 + key
			equipweapon(id, EQUIP_PRI)
			
			display_weaponmenu(id, MENU_SECONDARY, g_menuposition[id] = 0)
		}
	}
	return PLUGIN_HANDLED
}

public action_sec(id, key)
{
	if(!is_user_alive(id) || g_zombie[id] || g_boss[id])
		return PLUGIN_HANDLED
	
	switch(key) 
	{
    		case 8: display_weaponmenu(id, MENU_SECONDARY, ++g_menuposition[id])
		case 9: display_weaponmenu(id, MENU_SECONDARY, --g_menuposition[id])
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

public display_classmenu(id, pos)
{
	if(pos < 0)
		return
	
	static start
	start = pos * 8
	
	static maxitem
	maxitem = g_classcount

  	if(start >= maxitem)
    		start = pos = g_menuposition[id]
	
	static menubody[512], len
  	len = formatex(menubody, 511, "\y%L\w^n^n", id, "MENU_TITLE4")

	static end
	end = start + 8
	
	if(end > maxitem)
    		end = maxitem
	
	static keys
	keys = MENU_KEY_0
	
	static a, b
	b = 0
	
  	for(a = start; a < end; ++a) 
	{
		keys |= (1<<b)
		len += formatex(menubody[len], 511 - len,"%d. %s^n", ++b, g_class_name[a])
  	}

  	if(end != maxitem)
	{
    		formatex(menubody[len], 511 - len, "^n9. %L^n0. %L", id, "MENU_MORE", id, pos ? "MENU_BACK" : "MENU_EXIT")
    		keys |= MENU_KEY_9
  	}
  	else	
		formatex(menubody[len], 511 - len, "^n0. %L", id, pos ? "MENU_BACK" : "MENU_EXIT")
	
  	show_menu(id, keys, menubody, -1, "Class")
}

public action_class(id, key)
{
	switch(key) 
	{
    		case 8: display_classmenu(id, ++g_menuposition[id])
		case 9: display_classmenu(id, --g_menuposition[id])
    		default:
		{
			g_mutate[id] = g_menuposition[id] * 8 + key
			client_print(id, print_chat, "%L", id, "MENU_CHANGECLASS", g_class_name[g_mutate[id]])
		}
	}
	return PLUGIN_HANDLED
}

public UpdateLevelTeamHuman()
{
	static id
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && !g_zombie[id] && !g_boss[id] && !g_hero[id])
		{
			if(g_point[id] < MAX_POINT)
			{
				g_point[id]++
			} else if(g_point[id] >= MAX_POINT) {
				UpdateLevelHuman(id, 1)
			}
		}
	}
	
	return 1	
}

UpdateLevelHuman(id, num)
{
	// update level
	g_level[id] += num
	if (g_level[id] > MAX_LEVEL_HUMAN)
	{
		g_level[id] = MAX_LEVEL_HUMAN
		g_point[id] = MAX_POINT
	}
	else
	{
		// Reset Point
		g_point[id] = 0
		
		// Play Sound
		for(new i = 0; i < get_maxplayers(); i++)
		{
			if(is_user_connected(i) && !g_zombie[i])
				PlaySound2(i, level_up_sound[random_num(0, charsmax(level_up_sound))])
		}
		
		// Effect
		EffectLevelUp(id)

		// show hudtext
		set_hudmessage(0, 255, 0, -1.0, 0.40, 1, 5.0, 5.0)
		ShowSyncHudMsg(id, g_sync_msgdisplay, "%L", LANG_PLAYER, "LEVEL_UP", g_level[id])
	}
	
	//client_print(id, print_chat, "L[%i]", g_level[id])
}

public RemoveGlowShell(taskid)
{
	new id = taskid - TASK_GLOWSHELL
	fm_set_rendering(id)
	
	if (task_exists(taskid)) remove_task(taskid)
}

public register_spawnpoints(const mapname[])
{
	new configdir[32]
	get_configsdir(configdir, 31)
	
	new csdmfile[64], line[64], data[10][6]
	formatex(csdmfile, 63, "%s/csdm/%s.spawns.cfg", configdir, mapname)

	if(file_exists(csdmfile))
	{
		new file
		file = fopen(csdmfile, "rt")
		
		while(file && !feof(file))
		{
			fgets(file, line, 63)
			if(!line[0] || str_count(line,' ') < 2) 
				continue

			parse(line, data[0], 5, data[1], 5, data[2], 5, data[3], 5, data[4], 5, data[5], 5, data[6], 5, data[7], 5, data[8], 5, data[9], 5)

			g_spawns[g_spawncount][0] = floatstr(data[0]), g_spawns[g_spawncount][1] = floatstr(data[1])
			g_spawns[g_spawncount][2] = floatstr(data[2]), g_spawns[g_spawncount][3] = floatstr(data[3])
			g_spawns[g_spawncount][4] = floatstr(data[4]), g_spawns[g_spawncount][5] = floatstr(data[5])
			g_spawns[g_spawncount][6] = floatstr(data[7]), g_spawns[g_spawncount][7] = floatstr(data[8])
			g_spawns[g_spawncount][8] = floatstr(data[9])
			
			if(++g_spawncount >= MAX_SPAWNS) 
				break
		}
		if(file) 
			fclose(file)
	}
}

public register_zombieclasses(filename[])
{
	new configdir[32]
	get_configsdir(configdir, 31)
	
	new configfile[64]
	formatex(configfile, 63, "%s/%s", configdir, filename)

	if(get_pcvar_num(cvar_zombie_class) && file_exists(configfile))
	{			
		new line[128], leftstr[32], rightstr[64],  classname[32], data[MAX_DATA], i
		
		new file
		file = fopen(configfile, "rt")
		
		while(file && !feof(file))
		{
			fgets(file, line, 127), trim(line)
			if(!line[0] || line[0] == ';') continue
			
			if(line[0] == '[' && line[strlen(line) - 1] == ']')
			{
				copy(classname, strlen(line) - 2, line[1])

				if(register_class(classname) == -1)
					break
				
				continue
			}
			strtok(line, leftstr, 31, rightstr, 63, '=', 1)
				
			if(equali(leftstr, "DESC"))
				copy(g_class_desc[g_classcount - 1], 31, rightstr)
			else if(equali(leftstr, "PMODEL"))
				copy(g_class_pmodel[g_classcount - 1], 63, rightstr)
			else if(equali(leftstr, "WMODEL"))
				copy(g_class_wmodel[g_classcount - 1], 63, rightstr)
				
			for(i = 0; i < MAX_DATA; i++)
				data[i] = equali(leftstr, g_dataname[i])
				
			for(i = 0; i < MAX_DATA; i++) if(data[i])
			{
				g_class_data[g_classcount - 1][i] = floatstr(rightstr)
				break
			}
		}
		if(file) fclose(file)
	} 
	else 
		register_class("default")
}

public register_class(classname[])
{
	if(g_classcount >= MAX_CLASSES)
		return -1
	
	copy(g_class_name[g_classcount], 31, classname)
	copy(g_class_pmodel[g_classcount], 63, DEFAULT_PMODEL)
	copy(g_class_wmodel[g_classcount], 63, DEFAULT_WMODEL)
		
	g_class_data[g_classcount][DATA_HEALTH] = DEFAULT_HEALTH
	g_class_data[g_classcount][DATA_SPEED] = DEFAULT_SPEED	
	g_class_data[g_classcount][DATA_GRAVITY] = DEFAULT_GRAVITY
	g_class_data[g_classcount][DATA_ATTACK] = DEFAULT_ATTACK
	g_class_data[g_classcount][DATA_DEFENCE] = DEFAULT_DEFENCE
	g_class_data[g_classcount][DATA_HEDEFENCE] = DEFAULT_HEDEFENCE
	g_class_data[g_classcount][DATA_HITSPEED] = DEFAULT_HITSPEED
	g_class_data[g_classcount][DATA_HITDELAY] = DEFAULT_HITDELAY
	g_class_data[g_classcount][DATA_REGENDLY] = DEFAULT_REGENDLY
	g_class_data[g_classcount][DATA_HITREGENDLY] = DEFAULT_HITREGENDLY
	g_class_data[g_classcount++][DATA_KNOCKBACK] = DEFAULT_KNOCKBACK
	
	return (g_classcount - 1)
}

public native_register_class(classname[], description[])
{
	param_convert(1)
	param_convert(2)
	
	static classid
	classid = register_class(classname)

	if(classid != -1)
		copy(g_class_desc[classid], 31, description)

	return classid
}

public native_set_class_pmodel(classid, player_model[])
{
	param_convert(2)
	copy(g_class_pmodel[classid], 63, player_model)
}

public native_set_class_wmodel(classid, weapon_model[])
{
	param_convert(2)
	copy(g_class_wmodel[classid], 63, weapon_model) 
}

public native_is_user_zombie(index)
	return g_zombie[index] == true ? 1 : 0

public native_get_user_class(index)
	return g_player_class[index]

public native_is_user_first_zombie(index)
	return g_preinfect[index] == true ? 1 : 0

public native_game_started()
	return g_gamestarted

public native_preinfect_user(index, bool:yesno)
{
	if(is_user_alive(index) && !g_gamestarted)
		g_preinfect[index] = yesno
}

public native_infect_user(victim, attacker)
{
	if(allow_infection() && g_gamestarted)
		infect_user(victim, attacker)
}

public native_cure_user(index)
	cure_user(index)

public native_get_class_id(classname[])
{
	param_convert(1)
	
	static i
	for(i = 0; i < g_classcount; i++)
	{
		if(equali(classname, g_class_name[i]))
			return i
	}
	return -1
}

public Float:native_get_class_data(classid, dataid)
	return g_class_data[classid][dataid]

public native_set_class_data(classid, dataid, Float:value)
	g_class_data[classid][dataid] = value
	
public native_get_user_last_human(id)
{
	return g_lasthuman[id];
}

public native_is_boss_round()
{
	return g_boss_round
}

public native_is_user_boss(id)
{
	return g_boss[id]
}

public Float:native_get_max_health(id)
{
	return g_max_health[id]
}

stock bool:fm_is_hull_vacant(const Float:origin[3], hull)
{
	static tr
	tr = 0
	
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, tr)
	return (!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen)) ? true : false
}

stock fm_set_kvd(entity, const key[], const value[], const classname[] = "") 
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	return dllfunc(DLLFunc_KeyValue, entity, 0)
}

stock fm_strip_user_weapons(index) 
{
	static stripent
	if(!pev_valid(stripent))
	{
		stripent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
		dllfunc(DLLFunc_Spawn, stripent), set_pev(stripent, pev_solid, SOLID_NOT)
	}
	dllfunc(DLLFunc_Use, stripent, index)
	
	return 1
}

stock fm_set_entity_visibility(index, visible = 1)
	set_pev(index, pev_effects, visible == 1 ? pev(index, pev_effects) & ~EF_NODRAW : pev(index, pev_effects) | EF_NODRAW)

stock fm_find_ent_by_owner(index, const classname[], owner) 
{
	static ent
	ent = index
	
	while((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) && pev(ent, pev_owner) != owner) {}
	
	return ent
}

stock bacon_give_weapon(index, weapon[])
{
	if(!equal(weapon,"weapon_", 7))
		return 0

	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, weapon))
	
	if(!pev_valid(ent)) 
		return 0
    
	set_pev(ent, pev_spawnflags, SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
   
	if(!ExecuteHamB(Ham_AddPlayerItem, index, ent))
	{
		if(pev_valid(ent)) set_pev(ent, pev_flags, pev(ent, pev_flags) | FL_KILLME)
		return 0
	}
	ExecuteHamB(Ham_Item_AttachToPlayer, ent, index)

	return 1
}

stock bacon_strip_weapon(index, weapon[])
{
	if(!equal(weapon, "weapon_", 7)) 
		return 0

	static weaponid 
	weaponid = get_weaponid(weapon)
	
	if(!weaponid) 
		return 0

	static weaponent
	weaponent = fm_find_ent_by_owner(-1, weapon, index)
	
	if(!weaponent) 
		return 0

	if(get_user_weapon(index) == weaponid) 
		ExecuteHamB(Ham_Weapon_RetireWeapon, weaponent)

	if(!ExecuteHamB(Ham_RemovePlayerItem, index, weaponent)) 
		return 0
	
	ExecuteHamB(Ham_Item_Kill, weaponent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))

	return 1
}

stock fm_set_user_team(index, team, update = 1)
{
	set_pdata_int(index, OFFSET_TEAM, team)
	if(update)
	{
		emessage_begin(MSG_ALL, g_msg_teaminfo)
		ewrite_byte(index)
		ewrite_string(g_teaminfo[team])
		emessage_end()
	}
	return 1
}

stock fm_get_user_bpammo(index, weapon)
{
	static offset
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AMMO_338MAGNUM
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: offset = OFFSET_AMMO_762NATO
		case CSW_M249: offset = OFFSET_AMMO_556NATOBOX
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, 
		CSW_SG550, CSW_GALI, CSW_SG552: offset = OFFSET_AMMO_556NATO
		case CSW_M3, CSW_XM1014: offset = OFFSET_AMMO_BUCKSHOT
		case CSW_USP, CSW_UMP45, CSW_MAC10: offset = OFFSET_AMMO_45ACP
		case CSW_FIVESEVEN, CSW_P90: offset = OFFSET_AMMO_57MM
		case CSW_DEAGLE: offset = OFFSET_AMMO_50AE
		case CSW_P228: offset = OFFSET_AMMO_357SIG
		case CSW_GLOCK18, CSW_TMP, CSW_ELITE, 
		CSW_MP5NAVY: offset = OFFSET_AMMO_9MM
		default: offset = 0
	}
	return offset ? get_pdata_int(index, offset) : 0
}

stock fm_set_user_bpammo(index, weapon, amount)
{
	static offset
	switch(weapon)
	{
		case CSW_AWP: offset = OFFSET_AMMO_338MAGNUM
		case CSW_SCOUT, CSW_AK47, CSW_G3SG1: offset = OFFSET_AMMO_762NATO
		case CSW_M249: offset = OFFSET_AMMO_556NATOBOX
		case CSW_FAMAS, CSW_M4A1, CSW_AUG, 
		CSW_SG550, CSW_GALI, CSW_SG552: offset = OFFSET_AMMO_556NATO
		case CSW_M3, CSW_XM1014: offset = OFFSET_AMMO_BUCKSHOT
		case CSW_USP, CSW_UMP45, CSW_MAC10: offset = OFFSET_AMMO_45ACP
		case CSW_FIVESEVEN, CSW_P90: offset = OFFSET_AMMO_57MM
		case CSW_DEAGLE: offset = OFFSET_AMMO_50AE
		case CSW_P228: offset = OFFSET_AMMO_357SIG
		case CSW_GLOCK18, CSW_TMP, CSW_ELITE, 
		CSW_MP5NAVY: offset = OFFSET_AMMO_9MM
		default: offset = 0
	}
	
	if(offset) 
		set_pdata_int(index, offset, amount)
	
	return 1
}

stock fm_set_user_nvg(index, onoff = 1)
{
	static nvg
	nvg = get_pdata_int(index, OFFSET_NVG)
	
	set_pdata_int(index, OFFSET_NVG, onoff == 1 ? nvg | HAS_NVG : nvg & ~HAS_NVG)
	return 1
}

stock fm_set_user_money(index, addmoney, update = 1)
{
	static money
	money = fm_get_user_money(index) + addmoney
	
	set_pdata_int(index, OFFSET_CSMONEY, money)
	
	if(update)
	{
		message_begin(MSG_ONE, g_msg_money, _, index)
		write_long(clamp(money, 0, 16000))
		write_byte(1)
		message_end()
	}
	return 1
}

stock str_count(str[], searchchar)
{
	static maxlen
	maxlen = strlen(str)
	
	static i, count
	count = 0
	
	for(i = 0; i <= maxlen; i++) if(str[i] == searchchar)
		count++

	return count
}

stock set_zombie_attibutes(index)
{
	if(!is_user_alive(index)) 
		return
	
	g_zombie[index] = true
	RemoveGlowShell(index+TASK_GLOWSHELL)

	has_flaregrenade[index] = false
	can_mutating[index] = true
	
	fm_strip_user_weapons(index)

	if(!task_exists(TASKID_STRIPNGIVE + index))
		set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + index)

	static Float:health
	
	if(g_preinfect[index]) 
	{
		if(get_pcvar_num(cvar_zombie_health) == 1)
		{
			health = g_class_data[g_player_class[index]][DATA_HEALTH] *= get_pcvar_float(cvar_zombie_hpmulti)
		} else if(get_pcvar_num(cvar_zombie_health) == 2) {
			health = (get_player_num() / get_class_count()) * (1000 * health_multi[g_day])
		}
	} else {
		
		if(get_pcvar_num(cvar_zombie_health) == 1)
		{
			health = (g_class_data[g_player_class[index]][DATA_HEALTH] * health_multi[g_day])
		} else if(get_pcvar_num(cvar_zombie_health) == 2) {
			health = (get_player_num() / get_class_count()) * (1000 * health_multi[g_day])
		}
	}
	
	g_max_health[index] = health
	entity_set_float(index, EV_FL_health, health)
	
	fm_set_user_nvg(index)
	set_pev(index, pev_armorvalue, 0.0)
	check_nvg(index)
	
	if(contain(g_class_pmodel[g_player_class[index]], ".mdl") != -1)
	{
		replace(g_class_pmodel[g_player_class[index]], 63, ".mdl", "")
		replace_all(g_class_pmodel[g_player_class[index]], 63, "/", " ")
		replace_all(g_class_pmodel[g_player_class[index]], 63, "\", " ")
	}
	
	infection_effects(index)
	
	static null[2], model[32]
	parse(g_class_pmodel[g_player_class[index]], null, 1, null, 1, model, 31)
	
	fm_set_user_model(index, model)

	static effects
	effects = pev(index, pev_effects)
	
	if(effects & EF_DIMLIGHT)
	{
		message_begin(MSG_ONE, g_msg_flashlight, _, index)
		write_byte(0)
		write_byte(100)
		message_end()
		
		set_pev(index, pev_effects, effects & ~EF_DIMLIGHT)
	}
	
	// Call the bloody task
	if (get_pcvar_num(cvar_zombiebleeding))
		set_task(0.7, "make_blood", index+TASK_BLOOD, _, _, "b")	
	
	if(get_pcvar_num(cvar_zombie_appear_sound) == 1)
		PlaySound(g_appear_sounds[random_num(0, charsmax(g_appear_sounds))])
	
	last_check()
}

// Make zombies leave footsteps and bloodstains on the floor
public make_blood(taskid)
{
	// Only bleed when moving on ground
	if (!(pev(ID_BLOOD, pev_flags) & FL_ONGROUND) || fm_get_speed(ID_BLOOD) < 80)
		return;
	
	// Get user origin
	static Float:originF[3]
	pev(ID_BLOOD, pev_origin, originF)
	
	// If ducking set a little lower
	if (pev(ID_BLOOD, pev_bInDuck))
		originF[2] -= 18.0
	else
		originF[2] -= 36.0
		
	static random1
	random1 = random_num(0, charsmax(zombie_decals))
	
	// Send the decal message
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_WORLDDECAL) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(zombie_decals[random1]) // random decal number (offsets +12 for CZ)
	message_end()
}

public check_nvg(id)
{
	// Get nightvision give setting
	static nvggive
	nvggive = get_pcvar_num(cvar_nvggive)	
	
	client_printc(id, "!g[Bio] !nPress !t(N) !nto Use NightVision")
	
	// Give Zombies Night Vision?
	if (nvggive)
	{
		g_nvision[id] = true
		
		// Turn on Night Vision automatically?
		if (nvggive == 1)
		{
			g_nvisionenabled[id] = true
			
			// Custom nvg?
			if (get_pcvar_num(cvar_cnvg))
			{
				remove_task(id+TASK_NVISION)
				set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
			}
			else
				set_user_gnvision(id, 1)
		}		
	}
}

public set_boss_attibutes(id)
{
	if(!is_user_alive(id)) 
		return
		
	g_boss[id] = true
	RemoveGlowShell(id+TASK_GLOWSHELL)

	fm_strip_user_weapons(id)
	
	if(!task_exists(TASKID_STRIPNGIVE + id))
		set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + id)
		
	has_flaregrenade[id] = false

	entity_set_float(id, EV_FL_health, get_pcvar_float(cvar_nemesis_health))
	set_pev(id, pev_gravity, get_pcvar_float(cvar_nemesis_gravity))
	set_pev(id, pev_maxspeed, get_pcvar_float(cvar_nemesis_speed))
	fm_set_user_nvg(id)
	
	check_nvg(id)
	
	infection_effects(id)
	
	fm_set_user_model(id, g_boss_model[random_num(0, charsmax(g_boss_model))])

	static effects
	effects = pev(id, pev_effects)
	
	if(effects & EF_DIMLIGHT)
	{
		message_begin(MSG_ONE, g_msg_flashlight, _, id)
		write_byte(0)
		write_byte(100)
		message_end()
		
		set_pev(id, pev_effects, effects & ~EF_DIMLIGHT)
	}
	
	last_check()	
}

stock bool:allow_infection()
{
	static count[2]
	count[0] = 0
	count[1] = 0
	
	static index, maxzombies
	for(index = 1; index <= g_maxplayers; index++)
	{
		if(is_user_connected(index) && g_zombie[index]) 
			count[0]++
		else if(is_user_alive(index)) 
			count[1]++
	}
	
	maxzombies = clamp(get_pcvar_num(cvar_maxzombies), 1, 31)
	return (count[0] < maxzombies && count[1] > 1) ? true : false
}

stock randomly_pick_zombie()
{
	static data[4]
	data[0] = 0 
	data[1] = 0 
	data[2] = 0 
	data[3] = 0
	
	static index, players[2][32]
	for(index = 1; index <= g_maxplayers; index++)
	{
		if(!is_user_alive(index)) 
			continue
		
		if(g_zombie[index])
		{
			data[0]++
			players[0][data[2]++] = index
		}
		else 
		{
			data[1]++
			players[1][data[3]++] = index
		}
	}

	if(data[0] > 0 &&  data[1] < 1) 
		return players[0][_random(data[2])]
	
	return (data[0] < 1 && data[1] > 0) ?  players[1][_random(data[3])] : 0
}

stock equipweapon(id, weapon)
{
	if(!is_user_alive(id) || !is_user_connected(id)) 
		return

	static weaponid[2], weaponent, weapname[32]
	
	if(weapon & EQUIP_PRI)
	{
		weaponent = fm_lastprimary(id)
		weaponid[1] = get_weaponid(g_primaryweapons[g_player_weapons[id][0]][1])
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
			{
				get_weaponname(weaponid[0], weapname, 31)
				bacon_strip_weapon(id, weapname)
			}
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			bacon_give_weapon(id, g_primaryweapons[g_player_weapons[id][0]][1])
		
		fm_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][MAX_AMMO])
	}

	if(weapon & EQUIP_SEC)
	{
		weaponent = fm_lastsecondry(id)
		weaponid[1] = get_weaponid(g_secondaryweapons[g_player_weapons[id][1]][1])
		
		if(pev_valid(weaponent))
		{
			weaponid[0] = fm_get_weapon_id(weaponent)
			if(weaponid[0] != weaponid[1])
			{
				get_weaponname(weaponid[0], weapname, 31)
				bacon_strip_weapon(id, weapname)
			}
		}
		else
			weaponid[0] = -1
		
		if(weaponid[0] != weaponid[1])
			bacon_give_weapon(id, g_secondaryweapons[g_player_weapons[id][1]][1])
		
		fm_set_user_bpammo(id, weaponid[1], g_weapon_ammo[weaponid[1]][MAX_AMMO])
	}
	
	if(weapon & EQUIP_GREN)
	{
		static i
		for(i = 0; i < sizeof g_grenades; i++) if(!user_has_weapon(id, get_weaponid(g_grenades[i])))
			bacon_give_weapon(id, g_grenades[i])
	}
}

stock add_delay(index, const task[])
{
	switch(index)
	{
		case 1..8:   set_task(0.1, task, index)
		case 9..16:  set_task(0.2, task, index)
		case 17..24: set_task(0.3, task, index)
		case 25..32: set_task(0.4, task, index)
	}
}

public fm_set_user_model(id, const model[])
{
	g_lockmodel[id] = false
	cs_set_user_model(id, model)

	#if defined SET_MODELINDEX_OFFSET
		static Float:modelindex2
		modelindex2 = g_class_data[g_player_class[id]][DATA_MODELINDEX]
	
		if(g_zombie[id] && modelindex2 == 1.0)
		{
			static model1[16], tmp_precache[64], modelindex
			
			fm_get_user_model(id, model1, sizeof(model1))
			formatex(tmp_precache, sizeof(tmp_precache), "models/player/%s/%s.mdl", model1, model1)
			modelindex = engfunc(EngFunc_PrecacheModel, tmp_precache)
			
			set_pdata_int(id, 491, modelindex, 5)
		} else if(!g_zombie[id]) {
			set_pdata_int(id, 491, default_modelindex, 5)	
		}
	#endif
	
	g_lockmodel[id] = true
}

public fm_reset_user_model(id)
{
	if(is_user_connected(id))
		cs_set_user_model(id, human_model[random_num(0, charsmax(human_model))])
}

last_check()
{
	if(get_pcvar_num(cvar_hero_enable) == 0)
		return PLUGIN_HANDLED
	
	static id
	for (id = 1; id <= g_maxplayers; id++)
	{
		// Last human
		if (is_user_alive(id) && !g_zombie[id] && !g_boss[id] && g_gamestarted && get_human_count() == 1)
		{
			if (!g_lasthuman[id])
			{
				// Hero forward
				ExecuteForward(g_fwUserLastHuman, g_fwDummyResult, id);
				
				// Reward extra hp
				entity_set_float(id, EV_FL_health, get_pcvar_float(cvar_hero_health))
				
				new name[32]
				get_user_name(id, name, sizeof(name))
				
				set_hudmessage(255, 255, 0, -1.0, 0.40, 1, 4.0, 4.0)
				ShowSyncHudMsg(0, g_sync_msgdisplay, "%L", LANG_PLAYER, "HERO_APPEAR", name)
				
				PlaySound(hero_appear_sound[random_num(0, charsmax(hero_appear_sound))])
				
				// Make Last Human as a Hero
				g_hero[id] = true
				
				// Set Hero Model
				fm_set_user_model(id, hero_model[random_num(0, charsmax(hero_model))])
				
				if(!task_exists(TASKID_STRIPNGIVE + id))
					set_task(0.1, "task_stripngive", TASKID_STRIPNGIVE + id)
			}
			g_lasthuman[id] = true
		}
		else
			g_lasthuman[id] = false
	}
	
	return PLUGIN_CONTINUE
}

get_human_count()
{
	static iHumans, id
	iHumans = 0
	
	for (id = 1; id <= g_maxplayers; id++)
	{
		if (is_user_alive(id) && !g_zombie[id] && !g_boss[id])
			iHumans++
	}
	
	return iHumans;
}

// Effect level up
EffectLevelUp(id)
{
	if (!is_user_alive(id)) return;
	
	// get origin
	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	// set color
	new color[3]
	color[0] = get_color_level(id, 0)
	color[1] = get_color_level(id, 1)
	color[2] = get_color_level(id, 2)

	// create effect
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, origin, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, origin[0]) // x
	engfunc(EngFunc_WriteCoord, origin[1]) // y
	engfunc(EngFunc_WriteCoord, origin[2]) // z
	engfunc(EngFunc_WriteCoord, origin[0]) // x axis
	engfunc(EngFunc_WriteCoord, origin[1]) // y axis
	engfunc(EngFunc_WriteCoord, origin[2]+100.0) // z axis
	write_short(id_sprites_levelup) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(color[0]) // red
	write_byte(color[1]) // green
	write_byte(color[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// create glow shell
	fm_set_rendering(id)
	fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 0)
	if (task_exists(id+TASK_GLOWSHELL)) remove_task(id+TASK_GLOWSHELL)
	set_task(get_pcvar_float(cvar_glowshell_time), "RemoveGlowShell", id+TASK_GLOWSHELL)
}
get_color_level(id, num)
{
	new color[3]

	switch (g_level[id])
	{
		case 1: color = {0,177,0}
		case 2: color = {0,177,0}
		case 3: color = {0,177,0}
		case 4: color = {137,191,20}
		case 5: color = {137,191,20}
		case 6: color = {250,229,0}
		case 7: color = {250,229,0}
		case 8: color = {243,127,1}
		case 9: color = {243,127,1}
		case 10: color = {255,3,0}
		case 11: color = {127,40,208}
		case 12: color = {127,40,208}
		case 13: color = {127,40,208}
		default: color = {0,177,0}
	}
	
	return color[num];
}

get_color_day(num)
{
	new color[3]

	switch (g_day)
	{
		case 0: color = {100,100,100}
		case 1: color = {100,100,100}
		case 2: color = {100,100,100}
		case 3: color = {100,100,100}
		case 4: color = {137,191,20}
		case 5: color = {137,191,20}
		case 6: color = {250,229,0}
		case 7: color = {250,229,0}
		case 8: color = {243,127,1}
		case 9: color = {243,127,1}
		case 10: color = {255,3,0}
		case 11: color = {127,40,208}
		case 12: color = {127,40,208}
		default: color = {0,177,0}
	}
	
	return color[num];
}

stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

stock fm_get_speed(entity)
{
	static Float:velocity[3]
	pev(entity, pev_velocity, velocity)
	
	return floatround(vector_length(velocity));
}

// Infection special effects
infection_effects(id)
{	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("Damage"), _, id)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
	
	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)
	
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_IMPLOSION) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(128) // radius
	write_byte(20) // count
	write_byte(3) // duration
	message_end()
	
	// Particle burst?
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_PARTICLEBURST) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_short(50) // radius
	write_byte(70) // color
	write_byte(3) // duration (will be randomized a bit)
	message_end()
}

PlaySound(const sound[])
{
	client_cmd(0, "spk ^"%s^"", sound)
}

PlaySound2(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

// Buy BP Ammo
public clcmd_buyammo(id)
{
	// Not alive or infinite ammo setting enabled
	if (!is_user_alive(id) || get_pcvar_num(cvar_ammo))
		return PLUGIN_HANDLED;
	
	// Not human
	if (g_zombie[id])
	{
		client_printc(id, "!g[Bio]!n Only !tHuman can buy Ammo !!!")
		return PLUGIN_HANDLED;
	}
	
	// Not enough ammo packs
	if (fm_get_user_money(id) < 100)
	{
		client_printc(id, "!g[Bio]!n You don't have enough money to buy ammo. Required: 100$")
		return PLUGIN_HANDLED;
	}
	
	// Get user weapons
	static weapons[32], num, i, currentammo, weaponid, refilled
	num = 0 // reset passed weapons count (bugfix)
	refilled = false
	get_user_weapons(id, weapons, num)
	
	// Loop through them and give the right ammo type
	for (i = 0; i < num; i++)
	{
		// Prevents re-indexing the array
		weaponid = weapons[i]
		
		// Primary and secondary only
		if (MAXBPAMMO[weaponid] > 2)
		{
			// Get current ammo of the weapon
			currentammo = cs_get_user_bpammo(id, weaponid)
			
			if(cs_get_user_bpammo(id, get_user_weapon(id)) < 150)
			{				
				static temp
				temp = cs_get_user_bpammo(id, get_user_weapon(id)) + BUYAMMO[weaponid]
				
				cs_set_user_bpammo(id, get_user_weapon(id), temp)
				
				// Deduce ammo packs, play clip purchase sound, and notify player
				cs_set_user_money(id, cs_get_user_money(id) - 100)
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			
			// Check whether we actually refilled the weapon's ammo
			if (cs_get_user_bpammo(id, weaponid) - currentammo > 0) refilled = true
		}
	}
	
	// Weapons already have full ammo
	if (!refilled) return PLUGIN_HANDLED;
	
	return PLUGIN_HANDLED;
}

// Buy BP Ammo
public clcmd_buyammo2(id)
{
	// Not alive or infinite ammo setting enabled
	if (!is_user_alive(id) || get_pcvar_num(cvar_ammo))
		return PLUGIN_HANDLED;
	
	// Not human
	if (g_zombie[id])
	{
		client_printc(id, "!g[Bio]!n Only !tHuman can buy Ammo !!!")
		return PLUGIN_HANDLED;
	}
	
	// Not enough ammo packs
	if (fm_get_user_money(id) < 300)
	{
		client_printc(id, "!g[Bio]!n You don't have enough money to buy ammo. Required: 200$")
		return PLUGIN_HANDLED;
	}
	
	// Get user weapons
	static weapons[32], num, i, currentammo, weaponid, refilled
	num = 0 // reset passed weapons count (bugfix)
	refilled = false
	get_user_weapons(id, weapons, num)
	
	// Loop through them and give the right ammo type
	for (i = 0; i < num; i++)
	{
		// Prevents re-indexing the array
		weaponid = weapons[i]
		
		// Primary and secondary only
		if (MAXBPAMMO[weaponid] > 2)
		{
			// Get current ammo of the weapon
			currentammo = cs_get_user_bpammo(id, weaponid)
			
			if(cs_get_user_bpammo(id, get_user_weapon(id)) < 150)
			{
				// Give additional ammo
				cs_set_user_bpammo(id, get_user_weapon(id), MAXBPAMMO[weaponid])
				
				// Deduce ammo packs, play clip purchase sound, and notify player
				cs_set_user_money(id, cs_get_user_money(id) - 300)
				emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				client_printc(id, "!g[Bio]!n You bought !tMAX!n Ammo !!!")
			}
		
			// Check whether we actually refilled the weapon's ammo
			if (cs_get_user_bpammo(id, weaponid) - currentammo > 0) refilled = true
		}
	}
	
	// Weapons already have full ammo
	if (!refilled) return PLUGIN_HANDLED;
	
	return PLUGIN_HANDLED;
}

// Nightvision toggle
public clcmd_nightvision(id)
{
	if (g_nvision[id])
	{
		// Enable-disable
		g_nvisionenabled[id] = !(g_nvisionenabled[id])
		
		// Custom nvg?
		if (get_pcvar_num(cvar_cnvg))
		{
			remove_task(id+TASK_NVISION);
			set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
		}
		else
			set_user_gnvision(id, g_nvisionenabled[id])
	}
	
	return PLUGIN_HANDLED;
}

// Custom Night Vision
public set_user_nvision(taskid)
{
	// Not meant to have nvision or not enabled
	if (!g_nvision[ID_NVISION] || !g_nvisionenabled[ID_NVISION] || !is_user_alive(ID_NVISION))
	{
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Get player origin and alive status
	static Float:originF[3]
	pev(ID_NVISION, pev_origin, originF)
	
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NVISION)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(get_pcvar_num(cvar_nvgsize)) // radius	
	write_byte(get_pcvar_num(cvar_nvgcolor[0])) // r
	write_byte(get_pcvar_num(cvar_nvgcolor[1])) // g
	write_byte(get_pcvar_num(cvar_nvgcolor[2])) // b	
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}
// Game Nightvision
set_user_gnvision(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}

client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
	write_byte(index);
	write_string(szMsg);
	message_end();
}  

public Float:get_class_count()
{
	new Float:count
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_connected(i) && g_zombie[i])
			count++
	}
	
	return count
}

public Float:get_player_num()
{
	new Float:count
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_connected(i))
			count++
	}
	
	return count	
}
