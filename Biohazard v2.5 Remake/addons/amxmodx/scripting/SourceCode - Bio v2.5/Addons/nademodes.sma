#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#define VERSION "10"

/* -------------------------------
[Plugin Link]
------------------------------- */
/*
 *  https://forums.alliedmods.net/showthread.php?t=75322&page=21
 */

/* -------------------------------
[Changelog]
------------------------------- */
/*
Version 3.0
- Initial release.

Version 3.1
- Changing an item on the second page will rebuild the menu and display on the second page.

Version 4
- Improve to the trip grenade and sounds

Version 5
- Full grenade support + satchel charge mode

Version 5.2
- Automatic save system + team bug fix

Version 5.5
- Nade choose system

Version 5.7
- New menu system

Version 5.8
- Added compatibility with Biohazzard/Zombie Plague Mod. The nades will be removed when a player is turned into a zombie

Version 5.9
- Added new cvar for teamplay the plugin won't follow friendlyfire anymore, bot support

Version 5.9b
- Bug fix -> zombie

Version 6.0
- Nade damage control (all of them)

Version 6.0b
- Nademodes invalid player bug fix + admin spectator bug fix

Version 6.0c
- Nademodes grenade disapearing bug fix + new feature the plugin can be seen on what servers is played on.

Version 7.0
- Nademodes limit added, now plugin works with ghw model change, CSX module removed + laser engine bug fix + less cpu usage

Version 7.0a
- Nademodes invalid entity bug fix, nademodes remove counter bug fix

Version 7.0aa 
- Nademodes invalid entity bug fix in play_sound 

Version 7.0b
- Nademodes code change, now plugin relies on more modules! (More efficient), change part of the code (no more hardcodes)

Version 7.5
- Nademodes smart plugin effects mode added! Changed damage system! Changed primary menu! Now we have stuff organised! Added Homing grenade!

Version 8.0
- Nademodes added hit points system! Made sec explo more customizable!

Version 8.5
- Fixed all known bugs, added client mode selection!

Version 8.6
- Fixed menu drunk cvar bug, and forward drunk bug

Version 8.7
- Added new cvar to fix the SVC_BAD errors -> use this only if the clients report that problem!!!

Version 8.8
- New grenade shot detection method (supports walls now), HP system for other nades modes (NORMAL,IMPACT,HOMING)

Version 8.9
- Added bot support for trip nades

Version 9.0
- Animation and sound for grenades that have been shot, effects when grenades desintegrate, hp system more configurable

Version 9.1
- Shot method a little different now, supports shot through all entities, added penetration

Version 9.2
- Fixed the smoke grenade block problem, fixed secondary explosions server crash

Version 9.3
- Some small code tweaks, made some predefined values for things that you would like to modify

Version 9.4
- Last adjustments

Version 9.5
- Final fixes and some security mesures, final suggestions, removed update owner cvar (unfortunately nothing else could have been done)

Version 9.6
- Team bug fix, Owner set bug fix, Homing now follows team play, Damage system bug fix 

Version 9.61
- Small unregistration bug fix!

Version 9.62
- Menu position fix, added some small conditions in damage detection, also made the nades that have exploded be ignored

Version 9.63
- Fixed the error within the is_grenade native. 

Version 9.7
- Added more configurations to the MOTION and PROXIMITY modes both support line of sight options, also added delay between explosions for SATCHEL

Version 9.8
- Added new type of effect transmition mode: "Low Bandwidth Mode" - conserve bandwidth as much as possible (useful for servers with many many grenades)

Version 9.9
- Fixed the way the cone angle was calculated, optimized parts of the plugin, added metric and inch unit conversion in the menu for better understanding

Version 10
- Optimized the code, added possibility to remove the normal grenade mode, removed amx_nms feature due to "Info string length exceded" errors, added a special forward for compatibility issues, added support for monstermod
*/

/* -------------------------------
[Thanks to]
------------------------------- */
/*
- Grenade Modes by Nomexous
- Shoot Grenades by joaquimandrade
- Testers
- Translators
- Everyone who enjoys having fun with grenades.
*/

new const ACTIVATE[] = 	"weapons/mine_activate.wav"
new const DEPLOY[] =  	"weapons/mine_deploy.wav"
new const CHARGE[] =  	"weapons/mine_charge.wav"
new const GEIGER[] =  	"player/geiger1.wav"
new const PING[] = 		"turret/tu_ping.wav"

new const SOUND_HIT[5][] = { "debris/bustmetal1.wav", "debris/bustmetal2.wav", "debris/metal1.wav", "debris/metal2.wav", "debris/metal3.wav" }

// Defines that can be modified
#define MAX_PLAYERS								32

#define ADMIN_ACCESS							ADMIN_RCON

#define NOTEAM_RGB_R_COLOR 						0
#define NOTEAM_RGB_G_COLOR 						214
#define NOTEAM_RGB_B_COLOR 						198

#define TEAMCT_RGB_R_COLOR						0
#define TEAMCT_RGB_G_COLOR						0
#define TEAMCT_RGB_B_COLOR						255

#define TEAMTE_RGB_R_COLOR						255
#define TEAMTE_RGB_G_COLOR						0
#define TEAMTE_RGB_B_COLOR						0

#define DELAY_ADDED_TO_USE						0.1

// Some defines, I suggest not modifying these! Only if you understand the code completely!
#define RING_SIZE_CONSTANT_PROXIMITY 			2.1
#define RING_SIZE_CONSTANT_MOTION	 			9.27

#define SETTINGS_REFRESH_TIME					2.0

#define OFFSET_WEAPONID							43
#define EXTRAOFFSET_WEAPONS						4

#define SMART_DISTANCE_LINE_PVS					800.0
#define SMART_RADIUS_RING_SHOW					1500.0
#define CONE_DROP_ANGLE_COSINUS					-0.30
#define EXTRALENGTH_VECTOR						200.0

#define SHOT_PENETRATION_DISTANCE 				4.0
#define SHOT_PENETRATION_READD_TIMES			20
#define SHOT_SECOND_TEST_RADIUS					10.0
#define SHOT_KNIFE_REAL_RADIUS					6.0
#define SHOT_ENTITY_QUEUE_LENGTH				5

#define BOT_MIN_DISTANCE_ATTACH					400.0
#define BOT_WALL_MIN_COSINUS					0.866026
#define BOT_MIN_HEIGHT_ALLOW 					18.0
#define BOT_MIN_CROUCH_HEIGHT_ALLOW 			10.0
#define BOT_MAX_HEIGHT_ALLOW 					55.0
#define BOT_FORCE_CROUCH_HEIGHT_CONST			76.0

#define CVAR_STRING_ALLOC						100
#define CVAR_MAX_ASSIGNED_VALUES				30
#define CVAR_MAX_STRING_LENGTH					10

#define DMG_CS_KNIFE_BULLETS 					(1 << 12 | 1 << 0)

#define CONE_CALC_ANGLE_MAX						75.0
#define CONE_CALC_ANGLE_MIN						2.0
#define CONE_CALC_DISTANCE_MAX					400.0
#define CONE_CALC_DISTANCE_MIN					10000.0
#define CONE_BASE_RADIUS						200.0

// Macros, made specially to make the code easier to read
#define CONVERT_TO_METERS(%0)					(%0 * 0.0254)

#define get_option(%1) 							get_pcvar_num(pcvars[%1])
#define toggle_option(%1)						set_pcvar_num(pcvars[%1], !get_pcvar_num(pcvars[%1]))
#define get_option_float(%1)					get_pcvar_float(pcvars[%1])
#define set_option_float(%1,%2)					set_pcvar_float(pcvars[%1], %2)

#define make_explode(%1) 						entity_set_float(%1, EV_FL_dmgtime, 0.0)
#define grenade_can_be_used(%1)					(get_option(OPTION_NADES_IN_EFFECT) & NADE_BIT[%1]) ? 1 : 0
#define allow_grenade_explode(%1)				(get_gametime() < entity_get_float(%1, EV_FL_fuser2)) ? 0 : 1
#define get_grenade_type(%1)					NadeType:entity_get_int(%1, EV_INT_iuser1)
#define set_grenade_allow_explode(%1,%2)		entity_set_float(%1, EV_FL_fuser2, get_gametime() + %2)
#define delay_explosion(%1)						entity_set_float(%1, EV_FL_dmgtime, get_gametime() + get_option_float(OPTION_EXPLOSION_DELAY_TIME))
#define get_trip_grenade_end_origin(%1,%2)		entity_get_vector(%1, EV_VEC_vuser1, %2)
#define set_trip_grenade_end_origin(%1,%2)		entity_set_vector(%1, EV_VEC_vuser1, %2)
#define set_trip_grenade_fly_velocity(%1,%2)	entity_set_vector(%1, EV_VEC_vuser2, %2)
#define get_trip_grenade_fly_velocity(%1,%2)	entity_get_vector(%1, EV_VEC_vuser2, %2)
#define get_trip_grenade_middle_origin(%1,%2)	entity_get_vector(%1, EV_VEC_vuser3, %2)
#define set_trip_grenade_middle_origin(%1,%2)	entity_set_vector(%1, EV_VEC_vuser3, %2)
#define get_trip_grenade_arm_time(%1)			entity_get_float(%1, EV_FL_fuser1)
#define set_trip_grenade_arm_time(%1,%2)		entity_set_float(%1, EV_FL_fuser1, get_gametime() + %2)
#define set_trip_grenade_attached_to(%1,%2) 	entity_set_int(%1, EV_INT_iuser4, %2)
#define get_trip_grenade_attached_to(%1) 		entity_get_int(%1, EV_INT_iuser4)
#define get_trip_grenade_mode(%1) 				TripNadeMode:entity_get_int(%1, EV_INT_iuser3)
#define set_trip_grenade_mode(%1,%2) 			entity_set_int(%1, EV_INT_iuser3, _:%2)
#define play_sound(%1,%2) 						(get_option(OPTION_PLAY_SOUNDS)) ? emit_sound(%1, CHAN_WEAPON, %2, 1.0, ATTN_STATIC, 0, PITCH_NORM) : 0
#define play_sound2(%1,%2) 						(get_option(OPTION_PLAY_SOUNDS)) ? emit_sound(%1, CHAN_ITEM, %2, 1.0, ATTN_STATIC, 0, PITCH_NORM) : 0

// Enums! First time I've ever used them. These should make the code infinitely easier to read.
enum NadeRace
{
	GRENADE_EXPLOSIVE = 0,
	GRENADE_FLASHBANG,
	GRENADE_SMOKEGREN,
}

new const NADE_MODEL[][] = 
{
	"w_hegrenade.mdl", 
	"w_flashbang.mdl", 
	"w_smokegrenade.mdl"
}

new const NADE_WPID[NadeRace] = 
{
	CSW_HEGRENADE, 
	CSW_FLASHBANG, 
	CSW_SMOKEGRENADE
}

new const NADE_BIT[NadeRace] =
{
	(1<<0), 
	(1<<1), 
	(1<<2)
}

enum NadeType
{
	NADE_DUD = -1,  
	NADE_NORMAL, 
	NADE_PROXIMITY, 
	NADE_IMPACT, 
	NADE_TRIP, 
	NADE_MOTION, 
	NADE_SATCHEL, 
	NADE_HOMING
}

new UNCOUNTABLE_NADE_MODES 		=	((1 << (_:NADE_DUD + 1)) | (1 << (_:NADE_NORMAL + 1)) | (1 << (_:NADE_IMPACT + 1)) | (1 << (_:NADE_HOMING + 1)))
new const NADE_DONT_COUNT 		= (1<<31)

enum Fward
{
	FWD_NONE_ACTIVE 	= 0, 
	FWD_CMDSTART  		= (1<<0), 
	FWD_THINK   		= (1<<1), 
	FWD_SETMODEL  	 	= (1<<2), 
	FWD_TOUCH    		= (1<<3),
	FWD_SEC_EXPLODE 	= (1<<4), 
	FWD_TAKEDAMAGE		= (1<<5), 
	FWD_THINK_POST 		= (1<<6), 
	FWD_MESSAGE 		= (1<<7),
	FWD_HPSYSTEM 		= (1<<8)
}
 
enum TripNadeMode
{
	TRIP_NOT_ATTACHED = 0, 
	TRIP_ATTACHED, 
	TRIP_WAITING, 
	TRIP_SCANNING, 
	TRIP_SHOULD_DETONATE, 
	TRIP_DETONATED
}

enum Option
{
	// Primary Off/On cvar
	OPTION_ENABLE_NADE_MODES, 
	
	// General settings
	OPTION_FRIENDLY_FIRE,
	OPTION_BOT_ALLOW, 
	OPTION_NADES_IN_EFFECT, 
	OPTION_SUPPRESS_FITH, 
	OPTION_DISPLAY_MODE_ON_DRAW, 
	OPTION_PLAY_SOUNDS, 
	OPTION_RESET_MODE_ON_THROW, 
	OPTION_RESOURCE_USE, 
	OPTION_MSG_SVC_BAD,
	OPTION_TEAM_PLAY, 
	OPTION_AFFECT_OWNER,
	OPTION_UNITS_SYSTEM,
	OPTION_MONSTERMOD_SUPPORT,
	
	// Grenade modes control menu
	OPTION_NORMAL_ENABLED,
	OPTION_PROXIMITY_ENABLED, 
	OPTION_IMPACT_ENABLED, 
	OPTION_TRIP_ENABLED, 
	OPTION_MOTION_ENABLED, 
	OPTION_SATCHEL_ENABLED, 
	OPTION_HOMING_ENABLED, 
	
	OPTION_REACT_TRIP_G, 
	OPTION_REACT_TRIP_F, 
	OPTION_REACT_TRIP_S, 
	
	OPTION_PROXIMITY_LOS,
	OPTION_MOTION_LOS,
	OPTION_SATCHEL_DELAY,
	
	// Limit settings
	OPTION_LIMIT_SYSTEM,
	
	OPTION_LIMIT_PROXIMITY, 
	OPTION_LIMIT_TRIP, 
	OPTION_LIMIT_MOTION, 
	OPTION_LIMIT_SATCHEL, 
	
	OPTION_INFINITE_GRENADES, 
	OPTION_INFINITE_FLASHES, 
	OPTION_INFINITE_SMOKES, 
	
	// Hitpoints system settings
	OPTION_MATERIAL_SYSTEM,
	
	OPTION_SEC_EXPLO_AFFECT, 
	
	OPTION_HITPOINT_NORMAL,
	OPTION_HITPOINT_PROXIMITY, 
	OPTION_HITPOINT_IMPACT,
	OPTION_HITPOINT_TRIP, 
	OPTION_HITPOINT_MOTION, 
	OPTION_HITPOINT_SATCHEL, 
	OPTION_HITPOINT_HOMING,
	
	OPTION_HITPOINT_DEATH, 
	OPTION_HITPOINT_FF,
	OPTION_HITPOINT_INTER_DMG,
	
	// Damage settings
	OPTION_DAMAGE_SYSTEM,
	
	OPTION_DMG_THROUGH_WALL,
	OPTION_DMG_SELF,
	OPTION_DMG_TEAMMATES,
	
	OPTION_DMG_NORMAL,
	OPTION_DMG_PROXIMITY,
	OPTION_DMG_IMPACT, 
	OPTION_DMG_TRIP, 
	OPTION_DMG_MOTION, 
	OPTION_DMG_SATCHEL, 
	OPTION_DMG_HOMING, 
	
	// Internal functional settings
	OPTION_EXPLOSION_DELAY_TIME,
	OPTION_RADIUS_SEC_EXPLOSION,
	
	OPTION_ARM_TIME_TRIP, 
	OPTION_ARM_TIME_MOTION, 
	OPTION_ARM_TIME_SATCHEL, 
	OPTION_ARM_TIME_PROXIMITY, 
	
	OPTION_TRIP_DETECT_DISTANCE, 
	OPTION_TRIP_FLY_SPEED, 
	
	OPTION_RADIUS_PROXIMITY,
	OPTION_RADIUS_MOTION,
	
	OPTION_HOMING_SCAN_RANGE,
	OPTION_HOMING_SUPER_RANGE,
	OPTION_HOMING_EXTRATIME,
	OPTION_HOMING_SPEED_ADD
}

enum OptionType
{
	TOPTION_TOGGLE = 1, 
	TOPTION_CELL, 
	TOPTION_FLOAT,
}

enum TraceHandles
{
	TH_LOS,
	TH_DMG,
	TH_TRIP,
	TH_BOT
}

new const CFG_FILE_NAME[] = "nade_modes.cfg"
new CFG_FILE[200]

new OptionType:option_type[Option]
new option_value[Option][CVAR_STRING_ALLOC]

new NadeType:mode[MAX_PLAYERS + 1][NadeRace]
new cvar_menu_pos[MAX_PLAYERS + 1]

new cl_is_bot = 0
new cl_counter[MAX_PLAYERS + 1][NadeRace][NadeType]
new CsTeams:cl_team[MAX_PLAYERS + 1]
new Float:cl_nextusetime[MAX_PLAYERS + 1]
new cl_weapon[MAX_PLAYERS + 1]
new cl_entity_queue[MAX_PLAYERS + 1][SHOT_ENTITY_QUEUE_LENGTH]

new settingsmenu[MAX_PLAYERS + 1]
new pcvars[Option]

new beampoint
new shockwave
new nadebits

new callbacks[2]

new modetext[][] = { "Normal", "Proximity", "Impact", "Trip laser", "Motion sensor", "Satchel charge", "Homing" }

new g_maxplayers

new Fward:bs_forward_collection = FWD_NONE_ACTIVE
new g_check_hpsystem = -1
new Trie:trace_attack_reg_class
new g_ptrace[TraceHandles]
new NadeType:g_firstenabledmode[NadeRace]
new g_FW_property


/* -------------------------------
[Plugin Start]
------------------------------- */
public plugin_precache()
{
	// Track the explosion, we regiter this here so the forward will be before all of them! It is important!
	RegisterHam(Ham_Think, "grenade", "fw_track_explosion")
	
	// Trace attack register trie
	trace_attack_reg_class = TrieCreate()
	
	// We register this here to track shots, it is also important
	register_forward(FM_Spawn, "fw_spawn", 1)
	
	beampoint = precache_model("sprites/laserbeam.spr")
	shockwave = precache_model("sprites/shockwave.spr")
	nadebits  = precache_model("models/chromegibs.mdl")
	
	precache_sound(ACTIVATE)
	precache_sound(CHARGE)
	precache_sound(DEPLOY)
	precache_sound(GEIGER)
	precache_sound(PING)
	
	for (new i=0;i<5;i++)
	{
		precache_sound(SOUND_HIT[i])
	}
}

public plugin_init()
{
	// Plugin registration (normal and net)
	register_plugin("NadeModes", VERSION, "Nomexous & OT")
	register_cvar("nademodes_version", VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	
	// Commands
	register_clcmd("amx_nade_mode_menu", "conjure_menu", ADMIN_ACCESS, "Shows settings menu for grenade modes.")
	register_clcmd("amx_nmm", "conjure_menu", ADMIN_ACCESS, "Shows settings menu for grenade modes.")
	
	register_clcmd("say /nadehelp", "conjure_help", -1, "Shows help for grenade modes.")
	register_clcmd("say_team /nadehelp", "conjure_help", -1, "Shows help for grenade modes.")
	
	// General Settings Options
	pcvars[OPTION_FRIENDLY_FIRE] = get_cvar_pointer("mp_friendlyfire")
	
	register_option(OPTION_ENABLE_NADE_MODES, "nademodes_enable", "1")
	register_option(OPTION_NADES_IN_EFFECT, "nademodes_nades_in_effect", "7", TOPTION_CELL)
	register_option(OPTION_MSG_SVC_BAD, "nademodes_svc_bad_error_fix", "0")
	
	register_option(OPTION_PLAY_SOUNDS, "nademodes_play_grenade_sounds", "1")
	register_option(OPTION_RESOURCE_USE, "nademodes_effects", "2", TOPTION_CELL)
	
	register_option(OPTION_DISPLAY_MODE_ON_DRAW, "nademodes_display_mode_on_draw", "1")
	register_option(OPTION_RESET_MODE_ON_THROW, "nademodes_reset_mode_on_throw", "0")
	register_option(OPTION_SUPPRESS_FITH, "nademodes_suppress_fire_in_the_hole", "0")
	
	register_option(OPTION_BOT_ALLOW, "nademodes_bot_support", "1")
	
	register_option(OPTION_AFFECT_OWNER, "nademodes_affect_owner", "1")
	register_option(OPTION_TEAM_PLAY, "nademodes_team_play", "1")
	register_option(OPTION_UNITS_SYSTEM, "nademodes_unit_system", "1")
	
	register_option(OPTION_MONSTERMOD_SUPPORT, "nademodes_monstermod_support", "0")
	
	// General Settings Option Values
	register_option_value(OPTION_RESOURCE_USE, "0;1;2;3")
	register_option_value(OPTION_NADES_IN_EFFECT, "0;1;2;3;4;5;6;7")
	
	// Mode Settings Options
	register_option(OPTION_NORMAL_ENABLED, "nademodes_normal_enabled", "1")
	register_option(OPTION_PROXIMITY_ENABLED, "nademodes_proximity_enabled", "0")
	register_option(OPTION_IMPACT_ENABLED, "nademodes_impact_enabled", "1")
	register_option(OPTION_TRIP_ENABLED, "nademodes_trip_enabled", "1")
	register_option(OPTION_MOTION_ENABLED, "nademodes_motion_enabled", "0")
	register_option(OPTION_SATCHEL_ENABLED, "nademodes_satchel_enabled", "0")
	register_option(OPTION_HOMING_ENABLED, "nademodes_homing_enabled", "1")
	
	register_option(OPTION_REACT_TRIP_G, "nademodes_grenade_react", "1")
	register_option(OPTION_REACT_TRIP_F, "nademodes_flash_react", "1")
	register_option(OPTION_REACT_TRIP_S, "nademodes_smoke_react", "0")
	
	register_option(OPTION_PROXIMITY_LOS, "nademodes_proximity_fov", "0")
	register_option(OPTION_MOTION_LOS, "nademodes_motion_fov", "1")
	register_option(OPTION_SATCHEL_DELAY, "nademodes_satchel_delay", "0")
	
	// Limit Settings Options
	register_option(OPTION_LIMIT_SYSTEM, "nademodes_limit_system", "2", TOPTION_CELL)
	register_option(OPTION_LIMIT_PROXIMITY, "nademodes_proximity_limit", "5", TOPTION_CELL)
	register_option(OPTION_LIMIT_TRIP, "nademodes_trip_limit", "5", TOPTION_CELL)
	register_option(OPTION_LIMIT_MOTION, "nademodes_motion_limit", "5", TOPTION_CELL)
	register_option(OPTION_LIMIT_SATCHEL, "nademodes_satchel_limit", "5", TOPTION_CELL)
	
	register_option(OPTION_INFINITE_GRENADES, "nademodes_infinite_grenades", "0")
	register_option(OPTION_INFINITE_FLASHES, "nademodes_infinite_flashes", "0")
	register_option(OPTION_INFINITE_SMOKES, "nademodes_infinite_smokes", "0")
	
	// Limit Settings Option Values
	register_option_value(OPTION_LIMIT_SYSTEM, "0;1;2")
	
	register_option_value(OPTION_LIMIT_PROXIMITY, "0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15")
	register_option_value(OPTION_LIMIT_TRIP, "0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15")
	register_option_value(OPTION_LIMIT_MOTION, "0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15")
	register_option_value(OPTION_LIMIT_SATCHEL, "0;1;2;3;4;5;6;7;8;9;10;11;12;13;14;15")
	
	// Hitpoint Options
	register_option(OPTION_MATERIAL_SYSTEM, "nademodes_material_system", "0", TOPTION_CELL)
	register_option(OPTION_HITPOINT_DEATH, "nademodes_grenade_death","1")
	
	register_option(OPTION_SEC_EXPLO_AFFECT, "nademodes_secondary_explosions_mode", "0")
	
	register_option(OPTION_HITPOINT_NORMAL, "nademodes_hitpoints_normal", "10", TOPTION_CELL)
	register_option(OPTION_HITPOINT_PROXIMITY, "nademodes_hitpoints_proximity", "100", TOPTION_CELL)
	register_option(OPTION_HITPOINT_IMPACT, "nademodes_hitpoints_impact", "10", TOPTION_CELL)
	register_option(OPTION_HITPOINT_TRIP, "nademodes_hitpoints_trip", "100", TOPTION_CELL)
	register_option(OPTION_HITPOINT_MOTION, "nademodes_hitpoints_motion", "100", TOPTION_CELL)
	register_option(OPTION_HITPOINT_SATCHEL, "nademodes_hitpoints_satchel", "100", TOPTION_CELL)
	register_option(OPTION_HITPOINT_HOMING, "nademodes_hitpoints_homing", "10", TOPTION_CELL)
	
	register_option(OPTION_HITPOINT_INTER_DMG, "nademodes_hitpoints_intergrenade_damage", "100", TOPTION_FLOAT)
	register_option(OPTION_HITPOINT_FF, "nademodes_hitpoints_friendlyfire_ammount", "50", TOPTION_FLOAT)
	
	// Hitpoint Options Values
	register_option_value(OPTION_MATERIAL_SYSTEM, "0;1;2")
	
	register_option_value(OPTION_HITPOINT_NORMAL, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_PROXIMITY, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_IMPACT, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_TRIP, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_MOTION, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_SATCHEL, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	register_option_value(OPTION_HITPOINT_HOMING, "0;1;10;20;30;40;50;60;70;80;90;100;110;120;130;140;150;175;200;250;300;400;500;750;1000")
	
	register_option_value(OPTION_HITPOINT_INTER_DMG, "0;5;10;15;20;25;30;35;45;50;55;60;65;70;75;80;85;90;95;100")
	register_option_value(OPTION_HITPOINT_FF, "0;5;10;15;20;25;30;35;45;50;55;60;65;70;75;80;85;90;95;100")
	
	// Damage System Option Registration
	register_option(OPTION_DAMAGE_SYSTEM, "nademodes_damage_system", "2", TOPTION_CELL)
	
	register_option(OPTION_DMG_THROUGH_WALL, "nademodes_damage_through_wall", "50", TOPTION_CELL)
	register_option(OPTION_DMG_SELF, "nademodes_damage_self", "50", TOPTION_CELL)
	register_option(OPTION_DMG_TEAMMATES, "nademodes_damage_teammate", "50", TOPTION_CELL)
	
	register_option(OPTION_DMG_NORMAL, "nademodes_damage_normal", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_IMPACT, "nademodes_damage_impact", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_PROXIMITY, "nademodes_damage_proximity", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_MOTION, "nademodes_damage_motion", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_SATCHEL, "nademodes_damage_satchel", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_TRIP, "nademodes_damage_trip", "1.0", TOPTION_FLOAT)
	register_option(OPTION_DMG_HOMING, "nademodes_damage_homing", "1.0", TOPTION_FLOAT)
	
	// Damage System Option Values
	register_option_value(OPTION_DAMAGE_SYSTEM, "0;1;2")
	
	register_option_value(OPTION_DMG_THROUGH_WALL, "0;5;10;15;20;25;30;35;45;50;55;60;65;70;75;80;85;90;95;100")
	register_option_value(OPTION_DMG_SELF, "0;5;10;15;20;25;30;35;45;50;55;60;65;70;75;80;85;90;95;100")
	register_option_value(OPTION_DMG_TEAMMATES, "0;5;10;15;20;25;30;35;45;50;55;60;65;70;75;80;85;90;95;100")
	
	register_option_value(OPTION_DMG_NORMAL, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_IMPACT, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_MOTION, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_PROXIMITY, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_SATCHEL, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_TRIP, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	register_option_value(OPTION_DMG_HOMING, "0.2;0.4;0.6;0.8;1;1.2;1.4;1.6;1.8;2;2.2;2.4;2.6;2.8;3;3.2;3.4;3.6;3.8;4;5;6;7")
	
	// Internal Settings Float Options
	register_option(OPTION_EXPLOSION_DELAY_TIME, "nademodes_explosion_delay_time", "60000.0", TOPTION_FLOAT)
	
	register_option(OPTION_RADIUS_SEC_EXPLOSION, "nademodes_secondary_explosion_radius", "275.0", TOPTION_FLOAT)
	
	register_option(OPTION_ARM_TIME_TRIP, "nademodes_trip_grenade_arm_time", "3.0", TOPTION_FLOAT)
	register_option(OPTION_ARM_TIME_PROXIMITY, "nademodes_proximity_arm_time", "2.0", TOPTION_FLOAT)
	register_option(OPTION_ARM_TIME_MOTION, "nademodes_motion_arm_time", "2.0",  TOPTION_FLOAT)
	register_option(OPTION_ARM_TIME_SATCHEL, "nademodes_satchel_arm_time", "2.0", TOPTION_FLOAT)
	
	register_option(OPTION_TRIP_FLY_SPEED, "nademodes_trip_grenade_fly_speed", "400.0", TOPTION_FLOAT)
	register_option(OPTION_TRIP_DETECT_DISTANCE, "nademodes_trip_grenade_detection_limit", "16000.0", TOPTION_FLOAT)
	
	register_option(OPTION_RADIUS_PROXIMITY, "nademodes_proximity_radius", "150.0", TOPTION_FLOAT)
	register_option(OPTION_RADIUS_MOTION, "nademodes_motion_radius", "200.0", TOPTION_FLOAT)
	
	register_option(OPTION_HOMING_SCAN_RANGE, "nademodes_homing_detection_range", "500.0", TOPTION_FLOAT)
	register_option(OPTION_HOMING_SUPER_RANGE, "nademodes_homing_superhoming_range", "100.0", TOPTION_FLOAT)
	register_option(OPTION_HOMING_EXTRATIME, "nademodes_homing_extratime", "0.5", TOPTION_FLOAT)
	register_option(OPTION_HOMING_SPEED_ADD, "nademodes_homing_velocity_deviation", "60.0", TOPTION_FLOAT)
	
	// Internal Settings Option Values
	register_option_value(OPTION_EXPLOSION_DELAY_TIME, "600;700;800;900;1000;1400;1800;2200;2600;3000;4000;5000;6000;10000;60000")
	
	register_option_value(OPTION_RADIUS_SEC_EXPLOSION, "25;50;75;100;125;150;175;200;225;250;275;300;325;350")
	
	register_option_value(OPTION_ARM_TIME_TRIP, "1;1.5;2;2.5;3;3.5;4;4.5;5")
	register_option_value(OPTION_ARM_TIME_PROXIMITY, "1;1.5;2;2.5;3;3.5;4;4.5;5")
	register_option_value(OPTION_ARM_TIME_MOTION, "1;1.5;2;2.5;3;3.5;4;4.5;5")
	register_option_value(OPTION_ARM_TIME_SATCHEL, "1;1.5;2;2.5;3;3.5;4;4.5;5")
	
	register_option_value(OPTION_TRIP_FLY_SPEED, "200;250;300;350;400;450;500;550;600;650;700;750;800;850;900;1000")
	register_option_value(OPTION_TRIP_DETECT_DISTANCE, "400;800;1000;2000;4000;8000;16000")
	
	register_option_value(OPTION_RADIUS_PROXIMITY, "100;110;120;130;140;150;160;170;180;190;200")
	register_option_value(OPTION_RADIUS_MOTION, "150;160;170;180;190;200;210;220;230;240;250")
	
	register_option_value(OPTION_HOMING_SCAN_RANGE,"200;250;300;350;400;450;500;550;600;650;700;750;800;850;900;950;1000")
	register_option_value(OPTION_HOMING_SUPER_RANGE, "40;60;80;100;120;140;160;180;200;220;240;260;280;300")
	register_option_value(OPTION_HOMING_EXTRATIME, "0;0.1;0.2;0.3;0.4;0.5;0.6;0.7;0.8;0.9;1")
	register_option_value(OPTION_HOMING_SPEED_ADD, "10;15;20;25;30;35;40;45;50;55;60;65;70;75;80;85;90;95;100;125;150")
	
	register_event("CurWeapon", "event_armnade", "b", "1=1", "2=4", "2=9", "2=25")
	register_event("CurWeapon", "event_curweapon", "b", "1=1")
	register_event("HLTV", "event_new_round", "a", "1=0", "2=0") 
	
	register_dictionary("nademodes.txt")
	
	g_firstenabledmode[GRENADE_EXPLOSIVE] = NADE_NORMAL
	g_firstenabledmode[GRENADE_FLASHBANG] = NADE_NORMAL
	g_firstenabledmode[GRENADE_SMOKEGREN] = NADE_NORMAL
	
	g_ptrace[TH_LOS] = create_tr2()
	g_ptrace[TH_DMG] = create_tr2()
	g_ptrace[TH_TRIP] = create_tr2()
	g_ptrace[TH_BOT] = create_tr2()
	
	callbacks[0] = menu_makecallback("callback_disabled")
	callbacks[1] = menu_makecallback("callback_enabled")
	
	// Register all the forwards
	RegisterHam(Ham_TakeDamage, 	 "player", "fw_takedamage")
	RegisterHam(Ham_TakeDamage, 	 "func_wall", "fw_monster_takedamage")
	RegisterHam(Ham_Player_PreThink, "player", "fw_playerprethink")
	
	RegisterHam(Ham_Touch, 		"grenade", "fw_touch")
	RegisterHam(Ham_Think, 		"grenade", "fw_think")
	RegisterHam(Ham_Think, 		"grenade", "fw_think_post", 1)
	RegisterHam(Ham_TakeDamage, "grenade", "fw_grenade_takedamage")
	
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_global_traceattack", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_global_traceattack", 1)
	
	g_FW_property = CreateMultiForward("fw_NM_nade_property_set", ET_STOP, FP_CELL, FP_CELL)
	
	register_forward(FM_CmdStart, 	"fw_cmdstart")
	register_forward(FM_SetModel, 	"fw_setmodel", 1)
	register_forward(FM_TraceLine, 	"fw_traceline")
	
	register_message(get_user_msgid("SendAudio"), "fith_audio")
	register_message(get_user_msgid("TextMsg"),  "fith_text")
	
	set_task(SETTINGS_REFRESH_TIME, "update_forward_registration", 0, "", 0, "b", 0)
}

public plugin_cfg()
{
	// Get the config dir
	new config[sizeof(CFG_FILE)]
	get_configsdir(config, charsmax(CFG_FILE))
	format(CFG_FILE, charsmax(CFG_FILE), "%s/%s", config, CFG_FILE_NAME)
	
	// Execute the CFG file
	if(file_exists(CFG_FILE))
		server_cmd("exec %s", CFG_FILE)
	
	AddMenuItem("Nade Mode Menu", "amx_nmm", ADMIN_ACCESS, "NadeModes")
}

public plugin_end()
{
	TrieDestroy(trace_attack_reg_class)
	DestroyForward(g_FW_property)
	
	free_tr2(g_ptrace[TH_LOS])
	free_tr2(g_ptrace[TH_DMG])
	free_tr2(g_ptrace[TH_TRIP])
	free_tr2(g_ptrace[TH_BOT])
	
	save_cfg()
}

register_option(Option:option, const name[300], const string[], OptionType:type = TOPTION_TOGGLE, flags = 0, Float:value = 0.0)
{
	pcvars[option] = register_cvar(name, string, flags, value)
	option_type[option] = type
	return
}

register_option_value(Option:option, values[CVAR_STRING_ALLOC])
{
	if (option_type[option] == TOPTION_TOGGLE)
		return
	
	option_value[option] = values
}

public save_cfg()
{
	static file[3000]
	format(file, charsmax(file), "echo [NadeModes] Executing config file ...^n")
	
	format(file, charsmax(file), "%s^n// General CVARS^n^n", file)
	
	format(file, charsmax(file), "%snademodes_enable %d^n", file, get_option(OPTION_ENABLE_NADE_MODES))
	format(file, charsmax(file), "%snademodes_nades_in_effect %d^n", file, get_option(OPTION_NADES_IN_EFFECT))
	
	format(file, charsmax(file), "%snademodes_effects %d^n", file, get_option(OPTION_RESOURCE_USE))
	format(file, charsmax(file), "%snademodes_play_grenade_sounds %d^n", file, get_option(OPTION_PLAY_SOUNDS))
	format(file, charsmax(file), "%snademodes_svc_bad_error_fix %d^n", file, get_option(OPTION_MSG_SVC_BAD))
	
	format(file, charsmax(file), "%snademodes_display_mode_on_draw %d^n", file, get_option(OPTION_DISPLAY_MODE_ON_DRAW))
	format(file, charsmax(file), "%snademodes_reset_mode_on_throw %d^n", file, get_option(OPTION_RESET_MODE_ON_THROW))
	format(file, charsmax(file), "%snademodes_suppress_fire_in_the_hole %d^n", file, get_option(OPTION_SUPPRESS_FITH))
	
	format(file, charsmax(file), "%snademodes_bot_support %d^n", file, get_option(OPTION_BOT_ALLOW))
	
	format(file, charsmax(file), "%snademodes_affect_owner %d^n", file, get_option(OPTION_AFFECT_OWNER))
	format(file, charsmax(file), "%snademodes_team_play %d^n", file, get_option(OPTION_TEAM_PLAY))
	format(file, charsmax(file), "%snademodes_unit_system %d^n", file, get_option(OPTION_UNITS_SYSTEM))
	
	format(file, charsmax(file), "%snademodes_monstermod_support %d^n", file, get_option(OPTION_MONSTERMOD_SUPPORT))
	
	format(file, charsmax(file), "%s^n// Mode CVARS^n^n", file)
	
	format(file, charsmax(file), "%snademodes_normal_enabled %d^n", file, get_option(OPTION_NORMAL_ENABLED))
	format(file, charsmax(file), "%snademodes_proximity_enabled %d^n", file, get_option(OPTION_PROXIMITY_ENABLED))
	format(file, charsmax(file), "%snademodes_impact_enabled %d^n", file, get_option(OPTION_IMPACT_ENABLED))
	format(file, charsmax(file), "%snademodes_trip_enabled %d^n", file, get_option(OPTION_TRIP_ENABLED))
	format(file, charsmax(file), "%snademodes_motion_enabled %d^n", file, get_option(OPTION_MOTION_ENABLED))
	format(file, charsmax(file), "%snademodes_satchel_enabled %d^n", file, get_option(OPTION_SATCHEL_ENABLED))
	format(file, charsmax(file), "%snademodes_homing_enabled %d^n", file, get_option(OPTION_HOMING_ENABLED))
	
	format(file, charsmax(file), "%snademodes_grenade_react %d^n", file, get_option(OPTION_REACT_TRIP_G))
	format(file, charsmax(file), "%snademodes_flash_react %d^n", file, get_option(OPTION_REACT_TRIP_F))
	format(file, charsmax(file), "%snademodes_smoke_react %d^n", file, get_option(OPTION_REACT_TRIP_S))
	
	format(file, charsmax(file), "%nademodes_proximity_fov %d^n", file, get_option(OPTION_PROXIMITY_LOS))
	format(file, charsmax(file), "%snademodes_motion_fov %d^n", file, get_option(OPTION_MOTION_LOS))
	format(file, charsmax(file), "%snademodes_satchel_delay %d^n", file, get_option(OPTION_SATCHEL_DELAY))
	
	format(file, charsmax(file), "%s^n// Limit & Test CVARS^n^n", file)
	
	format(file, charsmax(file), "%snademodes_limit_system %d^n", file, get_option(OPTION_LIMIT_SYSTEM))
	
	format(file, charsmax(file), "%snademodes_proximity_limit %d^n", file, get_option(OPTION_LIMIT_PROXIMITY))
	format(file, charsmax(file), "%snademodes_trip_limit %d^n", file, get_option(OPTION_LIMIT_TRIP))
	format(file, charsmax(file), "%snademodes_motion_limit %d^n", file, get_option(OPTION_LIMIT_MOTION))
	format(file, charsmax(file), "%snademodes_satchel_limit %d^n", file, get_option(OPTION_LIMIT_SATCHEL))
	
	format(file, charsmax(file), "%snademodes_infinite_grenades %d^n", file, get_option(OPTION_INFINITE_GRENADES))
	format(file, charsmax(file), "%snademodes_infinite_flashes %d^n", file, get_option(OPTION_INFINITE_FLASHES))
	format(file, charsmax(file), "%snademodes_infinite_smokes %d^n", file, get_option(OPTION_INFINITE_SMOKES))
	
	format(file, charsmax(file), "%s^n// Intergrenade CVARS CVARS^n^n", file)
	
	
	format(file, charsmax(file), "%snademodes_material_system %d^n", file, get_option(OPTION_MATERIAL_SYSTEM))
	format(file, charsmax(file), "%snademodes_grenade_death %d^n", file, get_option(OPTION_HITPOINT_DEATH))
	
	format(file, charsmax(file), "%snademodes_secondary_explosions_mode %d^n", file, get_option(OPTION_SEC_EXPLO_AFFECT))
	format(file, charsmax(file), "%snademodes_secondary_explosion_radius %f^n", file, get_option_float(OPTION_RADIUS_SEC_EXPLOSION))
	
	format(file, charsmax(file), "%snademodes_hitpoints_normal %d^n", file, get_option(OPTION_HITPOINT_NORMAL))
	format(file, charsmax(file), "%snademodes_hitpoints_proximity %d^n", file, get_option(OPTION_HITPOINT_PROXIMITY))
	format(file, charsmax(file), "%snademodes_hitpoints_impact %d^n", file, get_option(OPTION_HITPOINT_IMPACT))
	format(file, charsmax(file), "%snademodes_hitpoints_trip %d^n", file, get_option(OPTION_HITPOINT_TRIP))
	format(file, charsmax(file), "%snademodes_hitpoints_motion %d^n", file, get_option(OPTION_HITPOINT_MOTION))
	format(file, charsmax(file), "%snademodes_hitpoints_satchel %d^n", file, get_option(OPTION_HITPOINT_SATCHEL))
	format(file, charsmax(file), "%snademodes_hitpoints_homing %d^n", file, get_option(OPTION_HITPOINT_HOMING))
	
	format(file, charsmax(file), "%snademodes_hitpoints_intergrenade_damage %f^n", file, get_option_float(OPTION_HITPOINT_INTER_DMG))
	format(file, charsmax(file), "%snademodes_hitpoints_friendlyfire_ammount %f^n", file, get_option_float(OPTION_HITPOINT_FF))
	
	format(file, charsmax(file), "%s^n// Damage CVARS^n^n", file)
	
	format(file, charsmax(file), "%snademodes_damage_system %d^n", file, get_option(OPTION_DAMAGE_SYSTEM))
	
	format(file, charsmax(file), "%snademodes_damage_self %d^n", file, get_option(OPTION_DMG_SELF))
	format(file, charsmax(file), "%snademodes_damage_through_wall %d^n", file, get_option(OPTION_DMG_THROUGH_WALL))
	format(file, charsmax(file), "%snademodes_damage_teammate %d^n", file, get_option(OPTION_DMG_TEAMMATES))
	
	format(file, charsmax(file), "%snademodes_damage_normal %f^n", file, get_option_float(OPTION_DMG_NORMAL))
	format(file, charsmax(file), "%snademodes_damage_proximity %f^n", file, get_option_float(OPTION_DMG_PROXIMITY))
	format(file, charsmax(file), "%snademodes_damage_impact %f^n", file, get_option_float(OPTION_DMG_IMPACT))
	format(file, charsmax(file), "%snademodes_damage_trip %f^n", file, get_option_float(OPTION_DMG_TRIP))
	format(file, charsmax(file), "%snademodes_damage_motion %f^n", file, get_option_float(OPTION_DMG_MOTION))
	format(file, charsmax(file), "%snademodes_damage_satchel %f^n", file, get_option_float(OPTION_DMG_SATCHEL))
	format(file, charsmax(file), "%snademodes_damage_homing %f^n", file, get_option_float(OPTION_DMG_HOMING))
	
	format(file, charsmax(file), "%s^n// Internal Funcitonal CVARS^n^n", file)
	
	format(file, charsmax(file), "%snademodes_explosion_delay_time %f^n", file, get_option_float(OPTION_EXPLOSION_DELAY_TIME))
	
	format(file, charsmax(file), "%snademodes_proximity_arm_time %f^n", file, get_option_float(OPTION_ARM_TIME_PROXIMITY))
	format(file, charsmax(file), "%snademodes_proximity_radius %f^n", file, get_option_float(OPTION_RADIUS_PROXIMITY))
	
	format(file, charsmax(file), "%snademodes_trip_grenade_arm_time %f^n", file, get_option_float(OPTION_ARM_TIME_TRIP))
	format(file, charsmax(file), "%snademodes_trip_grenade_fly_speed %f^n", file, get_option_float(OPTION_TRIP_FLY_SPEED))
	format(file, charsmax(file), "%snademodes_trip_grenade_detection_limit %f^n", file, get_option_float(OPTION_TRIP_DETECT_DISTANCE))
	
	format(file, charsmax(file), "%snademodes_motion_arm_time %f^n", file, get_option_float(OPTION_ARM_TIME_MOTION))
	format(file, charsmax(file), "%snademodes_motion_radius %f^n", file, get_option_float(OPTION_RADIUS_MOTION))
	
	format(file, charsmax(file), "%snademodes_satchel_arm_time %f^n", file, get_option_float(OPTION_ARM_TIME_SATCHEL))
	
	format(file, charsmax(file), "%snademodes_homing_detection_range %f^n", file, get_option_float(OPTION_HOMING_SCAN_RANGE))
	format(file, charsmax(file), "%snademodes_homing_superhoming_range %f^n", file, get_option_float(OPTION_HOMING_SUPER_RANGE))
	format(file, charsmax(file), "%snademodes_homing_extratime %f^n", file, get_option_float(OPTION_HOMING_EXTRATIME))
	format(file, charsmax(file), "%snademodes_homing_velocity_deviation %f^n", file, get_option_float(OPTION_HOMING_SPEED_ADD))
	
	format(file, charsmax(file), "%s^necho [NadeModes] Settings loaded from config file", file)
	
	delete_file(CFG_FILE)
	write_file(CFG_FILE, file)
}

/* -------------------------------
[Plugin Commands & Menus]
------------------------------- */
public conjure_help(id)
{
	static help_file[3000]
	
	format(help_file, charsmax(help_file), "%L", id, "NADE_HTML")
	
	delete_file("nmm.htm")
	write_file("nmm.htm", help_file)
	show_motd(id, "nmm.htm", "Mega-Nade Mod")
	
	return PLUGIN_CONTINUE
}

public conjure_menu(id, level, cid)
{
	if (cmd_access(id, level, cid, 1))
	{
		main_menu(id)
	}
	
	return PLUGIN_HANDLED
}

stock main_menu(id)
{
	static menu
	settingsmenu[id] = menu_create("NadeModes - Main Menu", "menu_handler")
	menu = settingsmenu[id]
	
	add_option_toggle(menu, OPTION_ENABLE_NADE_MODES, "Enable nade modes", "Yes", "No")
	
	menu_additem(menu, "Execute config file")
	menu_additem(menu, "General settings", _, _, get_option(OPTION_ENABLE_NADE_MODES) ? callbacks[1] : callbacks[0])
	menu_additem(menu, "Mode control menu", _, _, get_option(OPTION_ENABLE_NADE_MODES) ? callbacks[1] : callbacks[0])
	menu_additem(menu, "Mode limit & test menu", _, _, is_nademodes_enabled() ? callbacks[1] : callbacks[0])
	menu_additem(menu, "Hitpoints menu", _, _, is_nademodes_enabled() ? callbacks[1] : callbacks[0])
	menu_additem(menu, "Mode damage settings", _, _, is_nademodes_enabled() ? callbacks[1] : callbacks[0])
	menu_additem(menu, "Internal functional settings", _, _, is_nademodes_enabled() ? callbacks[1] : callbacks[0])
	
	menu_display(id, settingsmenu[id])
	return PLUGIN_CONTINUE
}
public menu_handler(id, menu, item)
{
	if (item < 0)
	{
		return PLUGIN_HANDLED
	}
	
	switch (item)
	{
		case 0:
		{
			toggle_option(OPTION_ENABLE_NADE_MODES)
		}
		case 1:
		{
			if(file_exists(CFG_FILE))
			{
				server_cmd("exec %s", CFG_FILE)
				update_forward_registration()
			}
			else
			{
				client_print(id, print_chat, "[NDM] Config file not found!")
			}
		}
		
		default:
		{
			menu_destroy(menu)
			cvar_menu(id, 0, item - 1)
			return PLUGIN_HANDLED
		}
	}
	
	
	menu_destroy(menu)
	main_menu(id)
	return PLUGIN_HANDLED
}

stock cvar_menu(id, page = 0, menu_set = 0)
{
	if (menu_set <= 0)
		return PLUGIN_CONTINUE
	
	static menu
	
	switch (menu_set)
	{
		case 1:
		{
			settingsmenu[id] = menu_create("NadeModes - General Settings", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_nade_option(menu, OPTION_NADES_IN_EFFECT, "Affected nades")
			
			add_option_quatrotoggle(menu, OPTION_RESOURCE_USE, "Plugin effects", "\rOff", "\yNormal", "\ySmart Mode", "\yLow Bandwidth Mode")
			add_option_toggle(menu, OPTION_PLAY_SOUNDS, "Grenade sounds", "On", "Off")
			add_option_toggle(menu, OPTION_MONSTERMOD_SUPPORT, "Monstermod support", "On", "Off")
			add_option_toggle(menu, OPTION_MSG_SVC_BAD, "SVC_BAD fix", "On^n   \yNote: \wTurn on when the server has this problem!^n", "Off^n   \yNote: \wTurn on when the server has this problem!^n")
			add_option_toggle(menu, OPTION_BOT_ALLOW, "Allow bots to use the moded nades", "Yes^n", "No^n") 
			
			add_option_toggle(menu, OPTION_DISPLAY_MODE_ON_DRAW, "Display mode on draw", "Yes", "No")
			add_option_toggle(menu, OPTION_RESET_MODE_ON_THROW, "Reset mode on throw", "Yes^n", "No^n")
			
			add_option_toggle(menu, OPTION_AFFECT_OWNER, "Traps can be activated by owner", "Yes", "No")
			add_option_toggle(menu, OPTION_TEAM_PLAY, "Team play (teammates will not be affected by nades)", "Yes^n", "No^n")
			
			add_option_toggle(menu, OPTION_SUPPRESS_FITH, "Suppress ^"Fire in the hole!^"", "Yes^n", "No^n")
			
			add_option_toggle(menu, OPTION_UNITS_SYSTEM, "Unit system:", "Metric", "Inch")
			
		}
		case 2:
		{
			settingsmenu[id] = menu_create("NadeModes - Mode Control", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_option_toggle(menu, OPTION_NORMAL_ENABLED, "Enable normal grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_PROXIMITY_ENABLED, "Enable proximity grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_IMPACT_ENABLED, "Enable impact grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_TRIP_ENABLED, "Enable trip grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_MOTION_ENABLED, "Enable motion sensor grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_SATCHEL_ENABLED, "Enable satchel charge grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_HOMING_ENABLED, "Enable homing grenades", "Yes^n", "No^n")
			
			add_option_toggle(menu, OPTION_REACT_TRIP_G, "Trip grenade react method", "Boom", "Fly", OPTION_TRIP_ENABLED)
			add_option_toggle(menu, OPTION_REACT_TRIP_F, "Trip flash react method", "Boom", "Fly", OPTION_TRIP_ENABLED)
			add_option_toggle(menu, OPTION_REACT_TRIP_S, "Trip smoke react method", "Boom^n", "Fly^n", OPTION_TRIP_ENABLED)
			
			add_option_toggle(menu, OPTION_PROXIMITY_LOS, "Proximity detonate only if player is in line of sight", "Yes", "No", OPTION_PROXIMITY_ENABLED)
			add_option_toggle(menu, OPTION_MOTION_LOS, "Motion detonate only if player is in line of sight", "Yes", "No", OPTION_MOTION_ENABLED)
			add_option_toggle(menu, OPTION_SATCHEL_DELAY, "Add delay between satchel explotions", "Yes", "No", OPTION_SATCHEL_ENABLED)
		}
		case 3:
		{
			settingsmenu[id] = menu_create("NadeModes - Limit & Test Menu", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_option_tritoggle(menu, OPTION_LIMIT_SYSTEM, "Limit system", "\rOff^n", "\yAvailable for each nade^n", "\yAvailable for general quantity^n")
			
			add_cell_option(menu, OPTION_LIMIT_PROXIMITY, "Proximity throw limit", "grenades", OPTION_LIMIT_SYSTEM)
			add_cell_option(menu, OPTION_LIMIT_TRIP, "Trip grenade throw limit", "grenades", OPTION_LIMIT_SYSTEM)
			add_cell_option(menu, OPTION_LIMIT_MOTION, "Motion throw limit", "grenades", OPTION_LIMIT_SYSTEM)
			add_cell_with_space_option(menu, OPTION_LIMIT_SATCHEL, "Stachel throw limit", "grenades", OPTION_LIMIT_SYSTEM)
			
			add_option_toggle(menu, OPTION_INFINITE_GRENADES, "Infinite grenades", "Yes", "No")
			add_option_toggle(menu, OPTION_INFINITE_FLASHES, "Infinite flashes", "Yes", "No")
			add_option_toggle(menu, OPTION_INFINITE_SMOKES, "Infinite smokes", "Yes", "No")
		}
		case 4:
		{
			settingsmenu[id] = menu_create("NadeModes - Hitpoint Menu", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_option_tritoggle(menu, OPTION_MATERIAL_SYSTEM, "Interaction system", "\rOff", "\ySecondary Explosions", "\yHit Point System")
			
			
			
			switch (get_option(OPTION_MATERIAL_SYSTEM))
			{
				case 0:
				{
					add_option_toggle(menu, OPTION_HITPOINT_DEATH, "Nade death", "Explode^n", "Desintegrate^n",OPTION_MATERIAL_SYSTEM)
					
					add_cell_option(menu, OPTION_HITPOINT_NORMAL, "Normal grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_PROXIMITY, "Proximity grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_IMPACT, "Impact grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_TRIP, "Trip grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_MOTION, "Motion grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_SATCHEL, "Satchel grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
					add_cell_option(menu, OPTION_HITPOINT_HOMING, "Homing grenade hitpoints", "hitpoints", OPTION_MATERIAL_SYSTEM)
				}
				
				case 1:
				{
					add_option_toggle(menu, OPTION_SEC_EXPLO_AFFECT, "Secondary explosions", "\yEach nade affects each!^n", "\yHe grenade affects all^n")
					add_float_unit_option(menu, OPTION_RADIUS_SEC_EXPLOSION, "Secondary explosion radius affection", "")
				}
				
				case 2:
				{
					add_option_toggle(menu, OPTION_HITPOINT_DEATH, "Nade death", "Explode^n", "Desintegrate^n",OPTION_MATERIAL_SYSTEM)
					
					add_cell_option(menu, OPTION_HITPOINT_NORMAL, "Normal grenade hitpoints", "hitpoints", OPTION_NORMAL_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_PROXIMITY, "Proximity grenade hitpoints", "hitpoints", OPTION_PROXIMITY_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_IMPACT, "Impact grenade hitpoints", "hitpoints", OPTION_IMPACT_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_TRIP, "Trip grenade hitpoints", "hitpoints", OPTION_TRIP_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_MOTION, "Motion grenade hitpoints", "hitpoints", OPTION_MOTION_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_SATCHEL, "Satchel grenade hitpoints", "hitpoints", OPTION_SATCHEL_ENABLED)
					add_cell_option(menu, OPTION_HITPOINT_HOMING, "Homing grenade hitpoints", "hitpoints^n", OPTION_HOMING_ENABLED)
					
					add_float_option(menu, OPTION_HITPOINT_FF, "Friendlyfire", "%", OPTION_MATERIAL_SYSTEM)
					add_float_option(menu, OPTION_HITPOINT_INTER_DMG, "Integrenade damage", "%", OPTION_MATERIAL_SYSTEM)
					
				}
			}
		}
		case 5:
		{
			settingsmenu[id] = menu_create("NadeModes - Damage Settings", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_option_tritoggle(menu, OPTION_DAMAGE_SYSTEM, "Damage system", "\rOff^n", "\yActive for every mode^n", "\yEach mode configurable^n")
			
			add_float_option(menu, OPTION_DMG_SELF, "Nade self damage percent", "%", OPTION_DAMAGE_SYSTEM)
			add_float_option(menu, OPTION_DMG_THROUGH_WALL, "Nade through wall damage percent", "%", OPTION_DAMAGE_SYSTEM)
			
			switch (get_option(OPTION_DAMAGE_SYSTEM))
			{
				case 0:
				{
					add_float_option(menu, OPTION_DMG_TEAMMATES, "Team mates damage percent", "%^n", OPTION_DAMAGE_SYSTEM)
				}
				
				case 1:
				{
					add_float_option(menu, OPTION_DMG_TEAMMATES, "Team mates damage percent", "%^n", OPTION_FRIENDLY_FIRE)
					
					add_float_option(menu, OPTION_DMG_NORMAL, "Grenade general damage multiply","times")
				}
				
				case 2:
				{
					add_float_option(menu, OPTION_DMG_TEAMMATES, "Team mates damage percent", "%^n", OPTION_FRIENDLY_FIRE)
					
					add_float_option(menu, OPTION_DMG_NORMAL, "Normal Grenade - damage multiply","times",OPTION_NORMAL_ENABLED)
					add_float_option(menu, OPTION_DMG_PROXIMITY, "Proximity Grenade - damage multiply","times", OPTION_PROXIMITY_ENABLED)
					add_float_option(menu, OPTION_DMG_IMPACT, "Impact Grenade - damage multiply","times", OPTION_IMPACT_ENABLED)
					add_float_option(menu, OPTION_DMG_TRIP, "Trip Grenade - damage multiply","times", OPTION_TRIP_ENABLED)
					add_float_option(menu, OPTION_DMG_MOTION, "Motion Grenade - damage multiply","times", OPTION_MOTION_ENABLED)
					add_float_option(menu, OPTION_DMG_SATCHEL, "Satchel Grenade - damage multiply","times", OPTION_SATCHEL_ENABLED)
					add_float_option(menu, OPTION_DMG_HOMING, "Homing Grenade - damage multiply","times", OPTION_HOMING_ENABLED)
				}
			}
		}
		case 6:
		{
			settingsmenu[id] = menu_create("NadeModes - Internal Functional Settings", "cvar_menu_handler")
			menu = settingsmenu[id]
			
			add_float_option(menu, OPTION_EXPLOSION_DELAY_TIME, "Grenade general delay explode time", "seconds^n")
			
			add_float_option(menu, OPTION_ARM_TIME_PROXIMITY, "Proximity arm time", "seconds", OPTION_PROXIMITY_ENABLED)
			add_float_unit_option(menu, OPTION_RADIUS_PROXIMITY, "Proximity detection radius", "^n", OPTION_PROXIMITY_ENABLED)
			
			add_float_option(menu, OPTION_ARM_TIME_TRIP, "Trip grenade arm time", "seconds", OPTION_TRIP_ENABLED)
			add_float_unit_option(menu, OPTION_TRIP_DETECT_DISTANCE, "Trip grenade detection distance", "", OPTION_TRIP_ENABLED)
			add_float_unit_option(menu, OPTION_TRIP_FLY_SPEED, "Trip grenade fly speed", "^n", OPTION_TRIP_ENABLED)
			
			add_float_option(menu, OPTION_ARM_TIME_SATCHEL, "Satchel charge arm time", "seconds^n", OPTION_SATCHEL_ENABLED)
			
			add_float_option(menu, OPTION_ARM_TIME_MOTION, "Motion sensor arm time", "seconds", OPTION_MOTION_ENABLED)
			add_float_unit_option(menu, OPTION_RADIUS_MOTION, "Motion sensor detection radius", "^n", OPTION_MOTION_ENABLED)
			
			add_float_option(menu, OPTION_HOMING_EXTRATIME, "Homing extra arm explosion time", "seconds", OPTION_HOMING_ENABLED)
			add_float_unit_option(menu, OPTION_HOMING_SCAN_RANGE, "Homing grenade detection range", "", OPTION_HOMING_ENABLED)
			add_float_unit_option(menu, OPTION_HOMING_SUPER_RANGE, "Homing grenade superhoming range", "", OPTION_HOMING_ENABLED)
			add_float_unit_option(menu, OPTION_HOMING_SPEED_ADD, "Homing grenade air acceleration", "", OPTION_HOMING_ENABLED)
		}
	}
	
	cvar_menu_pos[id] = menu_set
	menu_display(id, settingsmenu[id], page)
	return PLUGIN_CONTINUE
}

stock add_option_toggle(menu, Option:control_option, const basetext[], const yestext[], const notext[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100]
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s: %s%s", basetext, (get_option(control_option) ? "\y" : "\r" ), (get_option(control_option) ? yestext : notext))
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_option_tritoggle(menu, Option:control_option, const basetext[], const text[], const text2[], const text3[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100]
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s:\y %s%s%s", basetext, (get_option(control_option) == 0 ? text : "" ), (get_option(control_option) == 1 ? text2 : "" ), (get_option(control_option) == 2 ? text3 : "" ))
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_option_quatrotoggle(menu, Option:control_option, const basetext[], const text[], const text2[], const text3[], const text4[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100]
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s:\y %s%s%s%s", basetext, (get_option(control_option) == 0 ? text : "" ), (get_option(control_option) == 1 ? text2 : "" ), (get_option(control_option) == 2 ? text3 : "" ), (get_option(control_option) == 3 ? text4 : "" ))
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_nade_option(menu, Option:control_option, const basetext[])
{
	static cmd[4], itemtext[100]
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s:%s%s%s%s^n", basetext, (get_option(control_option) ? "\y" : " \rNone" ), ((get_option(control_option) & NADE_BIT[GRENADE_EXPLOSIVE]) ? " He" : ""), ((get_option(control_option) & NADE_BIT[GRENADE_FLASHBANG]) ? " Flash" : ""), ((get_option(control_option) & NADE_BIT[GRENADE_SMOKEGREN]) ? " Smoke" : ""))
	menu_additem(menu, itemtext, cmd, _, _)
}

stock add_float_option(menu, Option:control_option, const basetext[], const unit[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100], value[20]
	float_to_str(get_option_float(control_option), value, charsmax(value))
	format(value, charsmax(value), "%0.2f", get_option_float(control_option))
	
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s: \y%s \r%s", basetext, value, unit)
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_cell_option(menu, Option:control_option, const basetext[], const unit[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100], value[20]
	num_to_str(get_option(control_option), value, charsmax(value))
	format(value, charsmax(value), "%d", get_option(control_option))
	if (!get_option(control_option))
	{
		value = "Off"
	}
	
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s: \y%s \r%s", basetext, value, get_option(control_option) ? unit : "")
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_cell_with_space_option(menu, Option:control_option, const basetext[], const unit[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100], value[20]
	num_to_str(get_option(control_option), value, charsmax(value))
	format(value, charsmax(value), "%d", get_option(control_option))
	if (!get_option(control_option))
	{
		value = "Off"
	}
	
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s: \y%s \r%s^n", basetext, value, get_option(control_option) ? unit : "")
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}

stock add_float_unit_option(menu, Option:control_option, const basetext[], const extratext[], Option:displayif = Option:-1)
{
	static cmd[4], itemtext[100], value[20]
	format(value, charsmax(value), "%0.2f", get_option(OPTION_UNITS_SYSTEM) ? CONVERT_TO_METERS(get_option_float(control_option)) : get_option_float(control_option))
	
	num_to_str(_:control_option, cmd, charsmax(cmd))
	
	format(itemtext, charsmax(itemtext), "%s: \y%s \r%s%s", basetext, value, get_option(OPTION_UNITS_SYSTEM) ? "meters" : "inches", extratext)
	menu_additem(menu, itemtext, cmd, _, (displayif != Option:-1 && !get_option(displayif)) ? callbacks[0] : callbacks[1])
}


public cvar_menu_handler(id, menu, item)
{
	new access, info[4], callback
	menu_item_getinfo(menu, item, access, info, charsmax(info), _, _, callback)
	
	if (item < 0)
	{
		update_forward_registration()
		save_cfg()
		main_menu(id)
		return PLUGIN_HANDLED
	}
	
	new cvar = str_to_num(info)
	
	switch (option_type[Option:cvar])
	{
		case TOPTION_TOGGLE:
		{
			toggle_option(Option:cvar)
		}
		case TOPTION_CELL:
		{
			new value_string[CVAR_STRING_ALLOC]
			format(value_string, charsmax(value_string), "%s;", option_value[Option:cvar])
			
			new values[CVAR_MAX_ASSIGNED_VALUES][CVAR_MAX_STRING_LENGTH]
			new true_value[CVAR_MAX_ASSIGNED_VALUES]
			
			new last = 0, newpos = 0, k = 0;
			
			for (new i=0;i<CVAR_STRING_ALLOC;i++)
			{
				if(equal(value_string[i], ";", 1))
				{
					newpos = i
				}
				
				if (newpos > last)
				{					
					for (new j=last;j<newpos;j++)
					{
						format(values[k], CVAR_MAX_STRING_LENGTH - 1, "%s%s", values[k], value_string[j])
					}
					
					last = newpos + 1
					k++
				}
				
				if (k == CVAR_MAX_ASSIGNED_VALUES)
				{
					break
				}
			}
			
			new bool:ok = false
			new counter = 0
			
			for (new i=0;i<k;i++)
			{
				counter++
				
				true_value[i] = str_to_num(values[i])
				
				if (ok == true)
				{
					set_pcvar_num(pcvars[Option:cvar], true_value[i])
					counter = 0
					break
				}
				
				if (true_value[i] == get_option(Option:cvar))
					ok = true
			}
			
			if (counter == k)
			{
				set_pcvar_num(pcvars[Option:cvar], true_value[0])
			}
		}
		case TOPTION_FLOAT:
		{
			new value_string_float[CVAR_STRING_ALLOC]
			format(value_string_float, charsmax(value_string_float), "%s;", option_value[Option:cvar])
			
			new values_float[CVAR_MAX_ASSIGNED_VALUES][CVAR_MAX_STRING_LENGTH]
			new Float:true_value_float[CVAR_MAX_ASSIGNED_VALUES]
			
			new last = 0, newpos = 0, k = 0;
			
			for (new i=0;i<CVAR_STRING_ALLOC;i++)
			{
				if(equal(value_string_float[i], ";", 1))
				{
					newpos = i
				}
				
				if (newpos > last)
				{					
					for (new j=last;j<newpos;j++)
					{
						format(values_float[k], CVAR_MAX_STRING_LENGTH - 1, "%s%s", values_float[k], value_string_float[j])
					}
					
					last = newpos + 1
					k++
				}
				
				if (k == CVAR_MAX_ASSIGNED_VALUES)
				{
					break
				}
			}
			
			new bool:ok=false
			new counter = 0
			
			for (new i=0;i<k;i++)
			{
				counter++
				
				true_value_float[i] = str_to_float(values_float[i])
				
				if (ok == true)
				{
					set_pcvar_float(pcvars[Option:cvar], true_value_float[i])
					counter = 0
					break
				}
				
				if (true_value_float[i] == get_option_float(Option:cvar))
					ok = true
			}
			
			if (counter == k)
			{
				set_pcvar_float(pcvars[Option:cvar], true_value_float[0])
			}
			
		}
	}
	
	menu_destroy(menu)
	update_forward_registration()
	cvar_menu(id, item / 7, cvar_menu_pos[id])
	save_cfg()
	return PLUGIN_HANDLED
}

public callback_disabled(id, menu, item)
{
	return ITEM_DISABLED
}

public callback_enabled(id, menu, item)
{
	return ITEM_ENABLED
}

/* -------------------------------
[Client Internet Forwards]
------------------------------- */
public client_connect(id)
{
	mode[id][GRENADE_EXPLOSIVE] = FirstEnabledMode(GRENADE_EXPLOSIVE)
	mode[id][GRENADE_FLASHBANG] = FirstEnabledMode(GRENADE_FLASHBANG)
	mode[id][GRENADE_SMOKEGREN] = FirstEnabledMode(GRENADE_SMOKEGREN)
	
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_MOTION] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_TRIP] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_MOTION] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_TRIP] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_MOTION] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_TRIP] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_SATCHEL] = 0
}

public client_putinserver(id)
{
	// Add the bot property if user is bot
	if (is_user_bot(id))
		cl_is_bot |= (1<<(id-1))
}

public client_disconnect(id)
{
	// Remove the bot property (doesn't matter wether it was true or false)
	cl_is_bot &= ~(1<<(id-1))
	
	mode[id][GRENADE_EXPLOSIVE] = FirstEnabledMode(GRENADE_EXPLOSIVE)
	mode[id][GRENADE_FLASHBANG] = FirstEnabledMode(GRENADE_FLASHBANG)
	mode[id][GRENADE_SMOKEGREN] = FirstEnabledMode(GRENADE_SMOKEGREN)
	
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_MOTION] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_TRIP] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_MOTION] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_TRIP] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_MOTION] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_TRIP] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_SATCHEL] = 0
	
	cl_nextusetime[id] = 0.0
	
	cl_team[id] = CS_TEAM_UNASSIGNED
}

/* -------------------------------
[Forwards Registration Toggle]
------------------------------- */
public update_forward_registration()
{
	// Here we also update some global constants
	g_maxplayers = get_maxplayers()
	
	if (g_check_hpsystem == -1)
	{
		g_check_hpsystem = get_option(OPTION_MATERIAL_SYSTEM)
	}
	else
	{
		if (!is_nademodes_enabled() && get_option(OPTION_MATERIAL_SYSTEM) == 2)
		{
			new i=-1
			while ((i = find_ent_by_class(i, "grenade")))
			{
				if (!is_grenade(i))
					continue
				
				if (entity_get_float(i, EV_FL_health))
				{
					entity_set_float(i, EV_FL_takedamage, DAMAGE_NO)
				}
			}
		}
		
		if (g_check_hpsystem != get_option(OPTION_MATERIAL_SYSTEM))
		{
			if ((get_option(OPTION_MATERIAL_SYSTEM) == 0 || get_option(OPTION_MATERIAL_SYSTEM) == 1) && g_check_hpsystem == 2)
			{
				new i=-1
				while ((i = find_ent_by_class(i, "grenade")))
				{
					if (!is_grenade(i))
						continue
					
					if (entity_get_float(i, EV_FL_health))
					{
						entity_set_float(i, EV_FL_takedamage, DAMAGE_NO)
					}
				}
			}
			
			if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && (g_check_hpsystem == 1 || g_check_hpsystem == 0))
			{
				
				new i=-1
				while ((i = find_ent_by_class(i, "grenade")))
				{
					if (!is_grenade(i))
						continue
					
					if (entity_get_float(i, EV_FL_health))
					{
						entity_set_float(i, EV_FL_takedamage, DAMAGE_YES)
					}
				}
			}
		}
		
		g_check_hpsystem = get_option(OPTION_MATERIAL_SYSTEM)
	}
	
	if (is_nademodes_enabled())
	{
		bs_forward_collection |= FWD_CMDSTART | FWD_SETMODEL | FWD_THINK | FWD_TOUCH 
		
		if (get_option(OPTION_DAMAGE_SYSTEM))
		{
			bs_forward_collection |= FWD_TAKEDAMAGE
		}
		else
		{
			bs_forward_collection &= ~FWD_TAKEDAMAGE
		}
		
		if (get_option(OPTION_RESOURCE_USE))
		{
			bs_forward_collection |= FWD_THINK_POST
		}
		else
		{
			bs_forward_collection &= ~FWD_THINK_POST
		}
		
		if (!get_option(OPTION_MATERIAL_SYSTEM) || get_option(OPTION_MATERIAL_SYSTEM) > 2 || get_option(OPTION_MATERIAL_SYSTEM) < 0)
		{
			bs_forward_collection &= ~(FWD_SEC_EXPLODE | FWD_HPSYSTEM)
		}
		
		if (get_option(OPTION_MATERIAL_SYSTEM) == 1)
		{
			bs_forward_collection |= FWD_SEC_EXPLODE
		}
		else
		{
			bs_forward_collection &= ~FWD_SEC_EXPLODE
		}
		
		if (get_option(OPTION_MATERIAL_SYSTEM) == 2)
		{
			bs_forward_collection |= FWD_HPSYSTEM
		}
		else
		{
			bs_forward_collection &= ~FWD_HPSYSTEM
		}
		
		if (get_option(OPTION_SUPPRESS_FITH))
		{
			bs_forward_collection |= FWD_MESSAGE
		}
		else
		{
			bs_forward_collection &= ~FWD_MESSAGE
		}
		
	}
	else
	{
		bs_forward_collection = FWD_NONE_ACTIVE
	}
}
/* -------------------------------
[Events]
------------------------------- */
public event_armnade(id)
{
	static nade
	
	switch (read_data(2))
	{
		case CSW_HEGRENADE: 	nade = _:GRENADE_EXPLOSIVE
		case CSW_FLASHBANG: 	nade = _:GRENADE_FLASHBANG
		case CSW_SMOKEGRENADE: 	nade = _:GRENADE_SMOKEGREN
		default: return PLUGIN_CONTINUE
	}
	
	if (!is_nademodes_enabled())
		return PLUGIN_CONTINUE
	
	if (get_option(OPTION_INFINITE_GRENADES + Option:nade))
	{
		cs_set_user_bpammo(id, NADE_WPID[NadeRace:nade], 2000)
	}
	
	if (get_option(OPTION_DISPLAY_MODE_ON_DRAW) && grenade_can_be_used(NadeRace:nade))
	{
		client_print(id, print_center, "Mode: %s", modetext[_:mode[id][NadeRace:nade]])
	}
	
	if (!is_mode_enabled(id, mode[id][NadeRace:nade], NadeRace:nade))
	{
		changemode(id, NadeRace:nade)
	}
	
	return PLUGIN_CONTINUE
}

public event_curweapon(id)
{
	cl_weapon[id] = read_data(2)
}

public event_new_round()
{
	static players[32], count, id
	get_players(players, count)
	
	for (new i=0;i<count;i++)
	{
		id = players[i]
		cl_counter[id][GRENADE_EXPLOSIVE][NADE_MOTION] = 0
		cl_counter[id][GRENADE_EXPLOSIVE][NADE_PROXIMITY] = 0
		cl_counter[id][GRENADE_EXPLOSIVE][NADE_TRIP] = 0
		cl_counter[id][GRENADE_EXPLOSIVE][NADE_SATCHEL] = 0
		cl_counter[id][GRENADE_FLASHBANG][NADE_MOTION] = 0
		cl_counter[id][GRENADE_FLASHBANG][NADE_PROXIMITY] = 0
		cl_counter[id][GRENADE_FLASHBANG][NADE_TRIP] = 0
		cl_counter[id][GRENADE_FLASHBANG][NADE_SATCHEL] = 0
		cl_counter[id][GRENADE_SMOKEGREN][NADE_MOTION] = 0
		cl_counter[id][GRENADE_SMOKEGREN][NADE_PROXIMITY] = 0
		cl_counter[id][GRENADE_SMOKEGREN][NADE_TRIP] = 0
		cl_counter[id][GRENADE_SMOKEGREN][NADE_SATCHEL] = 0
	}
	
	
	static ent
	
	ent = -1
	while ((ent = find_ent_by_class(ent, "grenade")))
	{
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_KILLME)
	}
	
	return PLUGIN_CONTINUE
}

/* -------------------------------
[Message Engine Forwads]
------------------------------- */
public fith_audio(msg_id, msg_dest, entity)
{
	if (!(bs_forward_collection & FWD_MESSAGE))
		return PLUGIN_CONTINUE
	
	// Get the string that holds the message and test it to see wether to block it or not
	static string[18]
	get_msg_arg_string(2, string, charsmax(string))
	
	if (equal(string, "%!MRAD_FIREINHOLE")) return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public fith_text(msg_id, msg_dest, entity)
{
	if (!(bs_forward_collection & FWD_MESSAGE))
		return PLUGIN_CONTINUE
	
	static string[18]
	
	// Get the string that holds the message and test it to see wether to block it or not
	if (get_msg_args() == 5) // CS
	{
		get_msg_arg_string(5, string, charsmax(string))
	}
	else
	{
		if (get_msg_args() == 6) // CZ
		{
			get_msg_arg_string(6, string, charsmax(string))
		}
		else
		{
			return PLUGIN_CONTINUE
		}
	}
	
	return (equal(string, "#Fire_in_the_hole")) ? PLUGIN_HANDLED : PLUGIN_CONTINUE
}

/* -------------------------------
[Ham & Fakemeta Forwards]
------------------------------- */
public fw_playerprethink(id)
{
	if (!is_user_connected(id) || is_user_connecting(id) || is_user_hltv(id))
		return HAM_IGNORED
	
	switch (cs_get_user_team(id))
	{
		case CS_TEAM_T: cl_team[id] = CS_TEAM_T
		case CS_TEAM_CT: cl_team[id] = CS_TEAM_CT
		default: return HAM_IGNORED
	}
	
	return HAM_IGNORED
}

public fw_cmdstart(id, uc_handle, seed)
{
	if (!(bs_forward_collection & FWD_CMDSTART))
		return FMRES_IGNORED
	
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	static bool:key[MAX_PLAYERS + 1] = {false, ...}
	
	static buttons
	buttons = get_uc(uc_handle, UC_Buttons)
	
	if (!(buttons & IN_USE))
	{
		cl_nextusetime[id] = 0.0
	}
	
	if ((buttons & IN_ATTACK2))
	{
		if (!key[id])
		{
			#if AMXX_VERSION_NUM < 180
			static dummy
			
			switch (get_user_weapon(id, dummy, dummy))
			{
				case CSW_HEGRENADE: 	changemode(id, GRENADE_EXPLOSIVE)
				case CSW_FLASHBANG: 	changemode(id, GRENADE_FLASHBANG)
				case CSW_SMOKEGRENADE: 	changemode(id, GRENADE_SMOKEGREN)
			}
			#endif
			
			#if AMXX_VERSION_NUM >= 180
			switch (get_user_weapon(id))
			{
				case CSW_HEGRENADE: 	changemode(id, GRENADE_EXPLOSIVE)
				case CSW_FLASHBANG: 	changemode(id, GRENADE_FLASHBANG)
				case CSW_SMOKEGRENADE:	changemode(id, GRENADE_SMOKEGREN)
			}
			#endif
		}
		
		key[id] = true
	}
	else
	{
		key[id] = false
	}
	
	return FMRES_IGNORED
}

public fw_setmodel(ent, model[])
{
	if (!pev_valid(ent))
	{
		return FMRES_IGNORED
	}
	
	// Not yet thrown
	if (entity_get_float(ent, EV_FL_gravity) == 0.0)
	{
		return FMRES_IGNORED
	}
	
	for (new i=0;i<3;i++)
	{
		if (containi(model, NADE_MODEL[i]) != -1)
		{
			set_pdata_int(ent, OFFSET_WEAPONID, NADE_WPID[NadeRace:i], EXTRAOFFSET_WEAPONS)
			
			if (bs_forward_collection & FWD_SETMODEL)
				grenade_process(pev(ent, pev_owner), ent, NadeRace:i)
			
			break
		}
	}
	
	return FMRES_IGNORED
}

grenade_process(id, grenade, NadeRace:nade)
{
	if ((cl_is_bot & (1<<(id-1))) && get_option(OPTION_BOT_ALLOW) && grenade_can_be_used(nade))
	{
		// We place the NADE_TRIP last so we can easily make another choice if it doesn't work ;)
		static const NadeType:random_vec[] = {NADE_NORMAL, NADE_IMPACT, NADE_MOTION, NADE_PROXIMITY, NADE_HOMING, NADE_TRIP}
		static NadeType:decision
		
		decision = random_vec[random_num(0, charsmax(random_vec))]
		mode[id][nade] = decision
		
		if (is_mode_enabled(id, mode[id][nade], nade))
		{
			if (decision == NADE_TRIP)
			{
				static loop[4][2] = { {0, 1}, {0, -1}, {1, 1}, {1, -1} }
				// Search in order: axis +X axis -X axis +Y axis -Y axis
				
				new Float:origin[3], Float:end[3], Float:fdest[3], Float:calc_vector[3], Float:height, Float: minimum, Float:distance = 9999999.999, Float:fraction
				
				entity_get_vector(id, EV_VEC_origin, origin)
				
				xs_vec_copy(origin, end)
				end[2] += 16000.0
				
				engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, id, g_ptrace[TH_BOT])
				
				get_tr2(g_ptrace[TH_BOT], TR_vecEndPos, end)
				
				xs_vec_sub(end, origin, end)
				
				height = xs_vec_len(end)
				
				
				xs_vec_copy(origin, end)
				end[2] -= 16000.0
				
				engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, id, g_ptrace[TH_BOT])
				
				get_tr2(g_ptrace[TH_BOT], TR_vecEndPos, end)
				
				xs_vec_sub(end, origin, end)
				
				height += xs_vec_len(end)
				
				if ( height > BOT_FORCE_CROUCH_HEIGHT_CONST)
				{
					minimum = BOT_MIN_HEIGHT_ALLOW
				}
				else
				{
					minimum = BOT_MIN_CROUCH_HEIGHT_ALLOW
					height -= BOT_MIN_CROUCH_HEIGHT_ALLOW
					
				}
				
				if ( height > BOT_MAX_HEIGHT_ALLOW )
				{
					height = BOT_MAX_HEIGHT_ALLOW
				}
				
				if (xs_vec_len(end) < height)
				{
					xs_vec_mul_scalar(end, - random_float(minimum - xs_vec_len(end),height  - xs_vec_len(end)) / xs_vec_len(end), end)
					xs_vec_add(end, origin, origin)
				}
				else
				{
					if (xs_vec_len(end) < height)
					{
						xs_vec_mul_scalar(end,  (xs_vec_len(end) - random_float(minimum, height)) / xs_vec_len(end), end)
						xs_vec_add(end, origin, origin)
					}
					else
					{
						xs_vec_mul_scalar(end, (xs_vec_len(end) - random_float(minimum, height)) / xs_vec_len(end), end)
						xs_vec_add(end, origin, origin)
					}
				}
				
				for(new i=0;i<4;i++)
				{
					// Add search direction
					xs_vec_copy(origin, end)
					end[loop[i][0]] = origin[loop[i][0]] + (16000.0 * float(loop[i][1]))
					
					// Trace to get the entity where we can attach our nade
					engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, id, g_ptrace[TH_BOT])
					
					// Get fraction to see if it has hited something
					get_tr2(g_ptrace[TH_BOT], TR_flFraction, fraction)
					
					if (fraction < 1.0)
					{
						if ( (!is_attachable_surface(get_tr2(g_ptrace[TH_BOT], TR_pHit))) || get_tr2(g_ptrace[TH_BOT], TR_AllSolid) )
						{
							continue
						}
						
						// Get plane normal for the wall
						get_tr2(g_ptrace[TH_BOT], TR_vecPlaneNormal, calc_vector)
						
						// Check if we have a wall
						if ( xs_vec_dot(calc_vector, Float:{0.0,0.0,1.0}) > BOT_WALL_MIN_COSINUS || xs_vec_dot(calc_vector, Float:{0.0,0.0,1.0}) < (-BOT_WALL_MIN_COSINUS) )
						{
							continue
						}
						
						// We use the end point for extra calculations
						get_tr2(g_ptrace[TH_BOT], TR_vecEndPos, end)
						
						xs_vec_sub(origin, end, calc_vector)
						
						if (xs_vec_len(calc_vector) < distance)
						{
							distance = xs_vec_len(calc_vector)
							xs_vec_normalize(calc_vector, calc_vector)
							xs_vec_mul_scalar(calc_vector, 1.5, calc_vector)
							xs_vec_add(end, calc_vector, end)
							xs_vec_copy(end, fdest)
						}
					}
					
				}
				
				for(new i=0;i<2;i++)
				{
					for(new j=2;j<4;j++)
					{
						// Add search direction
						xs_vec_copy(origin, end)
						
						end[loop[i][0]] = origin[loop[i][0]] + (16000.0 * float(loop[i][1]))
						end[loop[j][0]] = origin[loop[j][0]] + (16000.0 * float(loop[j][1]))
						
						engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, id, g_ptrace[TH_BOT])
						
						get_tr2(g_ptrace[TH_BOT], TR_flFraction, fraction)
						
						if (fraction < 1.0)
						{
							if ( (!is_attachable_surface(get_tr2(g_ptrace[TH_BOT], TR_pHit))) || get_tr2(g_ptrace[TH_BOT], TR_AllSolid) )
							{
								continue
							}
							
							get_tr2(g_ptrace[TH_BOT], TR_vecPlaneNormal, calc_vector)
							
							if ( xs_vec_dot(calc_vector, Float:{0.0,0.0,1.0}) > BOT_WALL_MIN_COSINUS || xs_vec_dot(calc_vector, Float:{0.0,0.0,1.0}) < (-BOT_WALL_MIN_COSINUS) )
							{
								continue
							}
							
							get_tr2(g_ptrace[TH_BOT], TR_vecEndPos, end)
							
							xs_vec_sub(origin, end, calc_vector)
							
							if (xs_vec_len(calc_vector) < distance)
							{
								distance = xs_vec_len(calc_vector)
								xs_vec_normalize(calc_vector, calc_vector)
								xs_vec_mul_scalar(calc_vector, 3.0, calc_vector)
								xs_vec_add(end, calc_vector, end)
								xs_vec_copy(end, fdest)
							}
							
						}
						
					}
				}
				
				xs_vec_sub(fdest, origin, calc_vector)
				
				if (xs_vec_len(calc_vector) <= BOT_MIN_DISTANCE_ATTACH)
				{
					xs_vec_normalize(calc_vector, calc_vector)
					xs_vec_mul_scalar(calc_vector, 20.0, calc_vector)
					entity_set_vector(grenade, EV_VEC_velocity, calc_vector)
					entity_set_int(grenade, EV_INT_movetype, MOVETYPE_FLY)
					entity_set_origin(grenade, fdest)
					set_grenade_type(grenade, mode[id][nade])
					
				}
				else
				{
					decision = random_vec[random_num(0, charsmax(random_vec) - 1)]
					mode[id][nade] = decision
					set_grenade_type(grenade, mode[id][nade])
				}
				
			}
			else
			{
				set_grenade_type(grenade, mode[id][nade])
			}
		}
		else
		{
			mode[id][nade] = NADE_NORMAL
			set_grenade_type(grenade, mode[id][nade])
		}
		
		return
	}
	
	if (is_nademodes_enabled() && is_mode_enabled(id, mode[id][nade], nade) && grenade_can_be_used(nade))
	{
		set_grenade_type(grenade, mode[id][nade])
	}
	
	if (get_option(OPTION_RESET_MODE_ON_THROW))
	{
		mode[id][nade] = NADE_NORMAL
	}
	
	return
}

public fw_spawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	static classname[32]
	pev(ent, pev_classname, classname, charsmax(classname))
	
	if(!TrieKeyExists(trace_attack_reg_class, classname))
	{
		RegisterHam(Ham_TraceAttack, classname, "fw_global_traceattack", 1)
		TrieSetCell(trace_attack_reg_class, classname, true)
	}
	
	return FMRES_IGNORED
}

public fw_track_explosion(grenade)
{
	if (entity_get_float(grenade, EV_FL_dmgtime) > get_gametime())
		return HAM_IGNORED
	
	static NadeType:type, owner, not_count
	owner = entity_get_edict(grenade, EV_ENT_owner)
	type = get_grenade_type(grenade)
	
	if (_:type & NADE_DONT_COUNT)
		not_count = true
	else
		not_count = false
	
	type &= ~NadeType:NADE_DONT_COUNT
	
	if (!is_user_connected(owner) || is_user_connecting(owner) || cl_team[owner] == CS_TEAM_UNASSIGNED)
	{
		entity_set_int(grenade, EV_INT_flags, entity_get_int(grenade, EV_INT_flags) | FL_KILLME)
		return HAM_IGNORED
	}
	
	if (not_count)
	{
		return HAM_IGNORED
	}
	else
	{
		if (get_grenade_race(grenade) == _:GRENADE_SMOKEGREN)
		{
			if (entity_get_float(grenade, EV_FL_animtime) == 0.0)
			{
				return HAM_IGNORED
			}
			else
			{
				entity_set_float(grenade, EV_FL_animtime, 0.0)
			}
			
			clear_line(grenade)
		}
		else
		{
			clear_line(grenade)
		}
		
		if (!(_:UNCOUNTABLE_NADE_MODES & (1 << (_:type + 1))))
			cl_counter[owner][NadeRace:get_grenade_race(grenade)][type] -= 1
		
		entity_set_int(grenade, EV_INT_iuser1, entity_get_int(grenade, EV_INT_iuser1) | NADE_DONT_COUNT)
	}
	
	
	if (!(bs_forward_collection & FWD_SEC_EXPLODE))
		return HAM_IGNORED
	
	new Float:origin[3]
	new Float:range
	entity_get_vector(grenade, EV_VEC_origin, origin)
	range = get_option_float(OPTION_RADIUS_SEC_EXPLOSION)
	
	new i
	i = g_maxplayers
	
	if (!get_option(OPTION_SEC_EXPLO_AFFECT) && get_grenade_race(grenade) == _:GRENADE_EXPLOSIVE)
	{
		while ((i = find_ent_in_sphere(i, origin, range)))
		{
			if (i == grenade)
				continue
			
			if (is_grenade(i, true))
			{
				if (entity_get_float(i, EV_FL_animtime) == 0.0 && get_grenade_race(i) == _:GRENADE_SMOKEGREN)
				{
					continue
				}
				
				make_explode(i)
				
				if (get_grenade_race(i) == _:GRENADE_SMOKEGREN)
				{
					entity_set_int(i, EV_INT_flags, entity_get_int(i, EV_INT_flags) | FL_ONGROUND)
					dllfunc(DLLFunc_Think, i)
				}
			}
		}
	}
	else
	{
		static race
		race = get_grenade_race(grenade)
		
		while ((i = find_ent_in_sphere(i, origin, range)))
		{
			if (i == grenade)
				continue
			
			if (is_grenade(i, true))
			{
				if (get_grenade_race(i) == race)
				{
					if (entity_get_float(i, EV_FL_animtime) == 0.0 && race == _:GRENADE_SMOKEGREN)
					{
						continue
					}
					
					make_explode(i)
					
					if (race == _:GRENADE_SMOKEGREN)
					{
						entity_set_int(i, EV_INT_flags, entity_get_int(i, EV_INT_flags) | FL_ONGROUND)
						dllfunc(DLLFunc_Think, i)
					}
				}
			}
		}
	}

	return HAM_IGNORED
}

public fw_think(ent)
{
	if (!(bs_forward_collection & FWD_THINK) || !is_valid_ent(ent))
		return HAM_IGNORED
	
	static i, Float:origin[3], Float:porigin[3], Float:fraction, owner, bs_holds
	static Float:radius, affect_owner, team_play, los
	
	affect_owner = get_option(OPTION_AFFECT_OWNER)
	team_play = get_option(OPTION_TEAM_PLAY)
	
	entity_get_vector(ent, EV_VEC_origin, origin)
	
	owner = entity_get_edict(ent, EV_ENT_owner)
	
	if (!is_user_connected(owner) || is_user_connecting(owner) || cl_team[owner] == CS_TEAM_UNASSIGNED)
	{
		entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_KILLME)
		return HAM_IGNORED
	}
	
	switch (get_grenade_type(ent))
	{
		case NADE_DUD:
		{
			return HAM_SUPERCEDE
		}
		
		case NADE_NORMAL:
		{
			return HAM_IGNORED
		}
		
		case NADE_PROXIMITY:
		{
			if (!allow_grenade_explode(ent))
				return HAM_IGNORED
			
			i = -1
			radius = get_option_float(OPTION_RADIUS_PROXIMITY)
			los = get_option(OPTION_PROXIMITY_LOS)
			
			while ((i = find_ent_in_sphere(i, origin, radius)))
			{
				if (i > g_maxplayers)
				{
					if (get_option(OPTION_MONSTERMOD_SUPPORT))
					{
						if (is_ent_monster(i))
						{
							entity_get_vector(i, EV_VEC_origin, porigin)
							
							engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, g_ptrace[TH_LOS])
							get_tr2(g_ptrace[TH_LOS], TR_flFraction, fraction)
							
							if (fraction < 1.0)
								continue
							
							make_explode(ent)
							return HAM_IGNORED
						}
						else
							continue
					}
					
					return HAM_IGNORED
				}
				
				if (!is_user_alive(i))
					continue
				
				if (los)
				{
					entity_get_vector(i, EV_VEC_origin, porigin)
					
					engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, g_ptrace[TH_LOS])
					get_tr2(g_ptrace[TH_LOS], TR_flFraction, fraction)
					
					if (fraction < 1.0)
						continue
				}
				
				if (i == owner)
				{
					if (affect_owner)
					{
						make_explode(ent)
						return HAM_IGNORED
					}
					else
					{
						continue
					}
				}
				
				if (!team_play)
				{
					make_explode(ent)
					return HAM_IGNORED
				}
				else
				{
					if (cl_team[i] != cl_team[owner])
					{
						make_explode(ent)
						return HAM_IGNORED
					}
				}
			}
			return HAM_IGNORED
		}
		
		case NADE_TRIP:
		{
			static hit, Float:point[3], Float:normal[3], Float:temp[3], Float:end[3], Float:fly[3]
			static Float:fly_speed, Float:detect_distance, Float:arm_time
			
			fly_speed = get_option_float(OPTION_TRIP_FLY_SPEED)
			detect_distance = get_option_float(OPTION_TRIP_DETECT_DISTANCE)
			arm_time = get_option_float(OPTION_ARM_TIME_TRIP)
			
			switch (get_trip_grenade_mode(ent))
			{
				case TRIP_NOT_ATTACHED, TRIP_DETONATED:
				{
					return HAM_IGNORED
				}
				
				case TRIP_ATTACHED:
				{
					static loop[6][2] = { {2, 1}, {2, -1}, {0, 1}, {0, -1}, {1, 1}, {1, -1} }
					// Search in order: +Z axis -Z axis +X axis -X axis +Y axis -Y axis
					
					for (new i; i < 6; i++)
					{
						xs_vec_copy(origin, point)
						
						point[loop[i][0]] = origin[loop[i][0]] + (2.0 * float(loop[i][1]))
						
						engfunc(EngFunc_TraceLine, origin, point, IGNORE_MONSTERS, ent, g_ptrace[TH_TRIP])
						
						get_tr2(g_ptrace[TH_TRIP], TR_flFraction, fraction)
						
						if (fraction < 1.0)
						{
							hit = get_tr2(g_ptrace[TH_TRIP], TR_pHit)
							
							if (!is_attachable_surface(hit))
							{
								set_grenade_type(ent, NADE_DUD)
								return HAM_IGNORED
							}
							
							get_tr2(g_ptrace[TH_TRIP], TR_vecPlaneNormal, normal)
							
							set_trip_grenade_attached_to(ent, hit)
							
							// Calculate and store fly velocity.
							xs_vec_mul_scalar(normal, fly_speed, temp)
							set_trip_grenade_fly_velocity(ent, temp)
							
							// Calculate and store endpoint.
							xs_vec_mul_scalar(normal, detect_distance, temp)
							xs_vec_add(temp, origin, end)
							
							// Trace to it
							engfunc(EngFunc_TraceLine, origin, end, IGNORE_MONSTERS, ent, g_ptrace[TH_TRIP])
							get_tr2(g_ptrace[TH_TRIP], TR_flFraction, fraction)
							
							// Final endpoint with no possible wall collision
							xs_vec_mul_scalar(normal, (detect_distance * fraction), temp)
							xs_vec_add(temp, origin, end)
							set_trip_grenade_end_origin(ent, end)
							
							xs_vec_mul_scalar(temp, 0.5, temp)
							xs_vec_add(temp, origin, temp)
							set_trip_grenade_middle_origin(ent, temp)
							
							set_trip_grenade_arm_time(ent, arm_time)
							
							play_sound(ent, DEPLOY)
							
							entity_set_vector(ent, EV_VEC_velocity, Float:{0.0, 0.0, 0.0}) // Stop if from moving
							
							entity_set_int(ent, EV_INT_sequence, 0) // Otherwise, grenade might make wierd motions.
							
							set_trip_grenade_mode(ent, TRIP_WAITING)
							
							set_task(0.1, "trip_activation", ent)
							
							return HAM_IGNORED
						}
					}
					
					// If we reach here, we have serious problems. This means that the grenade hit something like a func_breakable
					// that disappeared before the scan was able to take place. Now, the grenade is floating in mid air. So we just
					// kaboom it!!!
					
					make_explode(ent)
					
					if (NadeRace:get_grenade_race(ent) == GRENADE_SMOKEGREN)
					{
						entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_ONGROUND)
					}
					
					return HAM_IGNORED
				}
				
				case TRIP_WAITING:
				{
					
					if (!is_attachable_surface(get_trip_grenade_attached_to(ent)))
					{
						make_explode(ent)
					
						if (NadeRace:get_grenade_race(ent) == GRENADE_SMOKEGREN)
						{
							entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_ONGROUND)
							clear_line(ent)
						}
						
						return HAM_IGNORED
					}
					
					if (get_gametime() > get_trip_grenade_arm_time(ent))
					{
						set_trip_grenade_mode(ent, TRIP_SCANNING)
						play_sound(ent, ACTIVATE)
					}
					
					return HAM_IGNORED
				}
				
				case TRIP_SCANNING:
				{
					if (!is_attachable_surface(get_trip_grenade_attached_to(ent)))
					{
						make_explode(ent)
						
						if (NadeRace:get_grenade_race(ent) == GRENADE_SMOKEGREN)
						{
							entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_ONGROUND)
							clear_line(ent)
						}
						
						return HAM_IGNORED
					}
					
					get_trip_grenade_end_origin(ent, end)
					engfunc(EngFunc_TraceLine, end, origin, DONT_IGNORE_MONSTERS, 0, g_ptrace[TH_TRIP])
					
					static target
					target = get_tr2(g_ptrace[TH_TRIP], TR_pHit)
					
					if (is_user_alive(target))
					{
						if (owner == target)
						{
							if (affect_owner)
							{
								set_trip_grenade_mode(ent, TRIP_SHOULD_DETONATE)
								entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.001)
								return HAM_IGNORED
							}
							else
							{
								entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.001)
								return HAM_IGNORED
							}
						}
						
						if (!team_play)
						{
							set_trip_grenade_mode(ent, TRIP_SHOULD_DETONATE)
						}
						else
						{
							if (cl_team[owner] != cl_team[target])
								set_trip_grenade_mode(ent, TRIP_SHOULD_DETONATE)
						}
					}
					else if (get_option(OPTION_MONSTERMOD_SUPPORT) && is_ent_monster(target))
					{
						set_trip_grenade_mode(ent, TRIP_SHOULD_DETONATE)
					}
					
					entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.001)
					return HAM_IGNORED
				}
				
				case TRIP_SHOULD_DETONATE:
				{
					static mode
					mode = get_trip_grenade_react_method(ent)
					set_trip_grenade_mode(ent, TRIP_DETONATED)
					
					clear_line(ent)
					play_sound(ent, ACTIVATE)
					
					if (mode == 0)
					{
						cl_counter[owner][NadeRace:get_grenade_race(ent)][NADE_TRIP] -= 1
						get_trip_grenade_fly_velocity(ent, fly)
						get_trip_grenade_end_origin(ent, end)
						entity_set_vector(ent, EV_VEC_velocity, fly) 			// Send the grenade on its way.
						set_grenade_type(ent, NADE_IMPACT)		 				// Kaboom!
					}
					else
					{
						make_explode(ent)
						
						if (NadeRace:get_grenade_race(ent) == GRENADE_SMOKEGREN)
						{
							entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_ONGROUND)
							clear_line(ent)
						}
					}
					
					return HAM_IGNORED
				}
			}
		}
		
		case NADE_MOTION:
		{
			if (!allow_grenade_explode(ent))
				return HAM_IGNORED
			
			static Float:v[3], Float:velocity
			
			i = -1
			bs_holds = 0
			radius = get_option_float(OPTION_RADIUS_MOTION)
			los = get_option(OPTION_MOTION_LOS)
			
			while ((i = find_ent_in_sphere(i, origin, radius)))
			{
				if (i > g_maxplayers)
				{
					entity_set_int(ent, EV_INT_iuser2, bs_holds)
					
					if (get_option(OPTION_MONSTERMOD_SUPPORT))
					{
						if (is_ent_monster(i))
						{
							entity_get_vector(i, EV_VEC_origin, porigin)
							
							engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, g_ptrace[TH_LOS])
							get_tr2(g_ptrace[TH_LOS], TR_flFraction, fraction)
							
							if (fraction < 1.0)
								continue
							
							entity_get_vector(i, EV_VEC_velocity, v)
							velocity = xs_vec_len(v)
							
							if (velocity > 100.0)
							{
								make_explode(ent)
								return HAM_IGNORED
							}
						}
						else
							continue
					}
					
					return HAM_IGNORED
				}
				
				if (!is_user_alive(i))
					continue
				
				if (los)
				{
					entity_get_vector(i, EV_VEC_origin, porigin)
					
					engfunc(EngFunc_TraceLine, origin, porigin, IGNORE_MONSTERS, 0, g_ptrace[TH_LOS])
					get_tr2(g_ptrace[TH_LOS], TR_flFraction, fraction)
					
					if (fraction < 1.0)
						continue
				}
				
				entity_get_vector(i, EV_VEC_velocity, v)
				velocity = xs_vec_len(v)
				
				if (velocity > 200.0)
				{
					if (i == owner)
					{
						if (affect_owner)
						{
							make_explode(ent)
							return HAM_IGNORED
						}
						else
						{
							bs_holds |= (1<<(i-1))
							continue
						}
					}
					if (!team_play)
					{
						make_explode(ent)
						return HAM_IGNORED
					}
					else
					{
						if (cl_team[i] != cl_team[owner])
						{
							make_explode(ent)
							return HAM_IGNORED
						}
					}
					
					bs_holds |= (1<<(i-1))
					entity_set_int(ent, EV_INT_iuser2, bs_holds)
					play_sound(ent, GEIGER)
				}
				else if (velocity == 0.0)
				{
					continue
				}
				else
				{
					play_sound(ent, GEIGER)
					
					// Add the player to the bitsum if he is moving
					bs_holds |= (1<<(i-1))
				}
				
			}
			
			entity_set_int(ent, EV_INT_iuser2, bs_holds)
			return HAM_IGNORED
		}
		
		case NADE_SATCHEL:
		{
			if (!allow_grenade_explode(ent))
				return HAM_IGNORED
			
			if (entity_get_int(owner, EV_INT_button) & IN_USE)
			{
				if (get_option(OPTION_SATCHEL_DELAY))
				{
					if (cl_nextusetime[owner] > get_gametime())
					{
						return HAM_IGNORED 
					}
					else
					{
						cl_nextusetime[owner] = get_gametime() + DELAY_ADDED_TO_USE
					}
				}
				
				make_explode(ent)
				
				if (NadeRace:get_grenade_race(ent) == GRENADE_SMOKEGREN)
				{
					entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_ONGROUND)
				}
			}
			
			
			return HAM_IGNORED
		}
		
		case NADE_HOMING:
		{
			static target, Float:extravel
			target = entity_get_int(ent, EV_INT_iuser2)
			extravel = get_option_float(OPTION_HOMING_SPEED_ADD)
			
			if (target == 0)
			{
				static i, Float:distance
				i = -1
				distance = get_option_float(OPTION_HOMING_SCAN_RANGE)
				
				while ((i = find_ent_in_sphere(i, origin, distance)))
				{
					if (i > g_maxplayers)
					{
						if (get_option(OPTION_MONSTERMOD_SUPPORT))
						{
							if (is_ent_monster(i))
							{
								static Float:o[3]
								entity_get_vector(i, EV_VEC_origin, o)
								static Float:new_distance
								new_distance = get_distance_f(o, origin)
								
								if (new_distance < distance)
								{
									distance = new_distance
									entity_set_int(ent, EV_INT_iuser2, i)
								}
							}
							else
							{
								continue
							}
						}
						else
							break
					}
					
					if (!is_user_alive(i))
						continue
					
					if (i == owner)
						continue
					
					if ((cl_team[i] != cl_team[owner] && team_play) || !team_play)
					{
						static Float:o[3]
						entity_get_vector(i, EV_VEC_origin, o)
						static Float:new_distance
						new_distance = get_distance_f(o, origin)
						
						if (new_distance < distance)
						{
							distance = new_distance
							entity_set_int(ent, EV_INT_iuser2, i)
						}
					}
				}
				
				return HAM_IGNORED
			}
			else if (!is_user_alive(target) && target <= g_maxplayers)
			{
				return HAM_IGNORED
			}
			else if (is_in_los(ent, target))
			{
				//set_user_rendering(target)
				static Float:velocity[3], Float:aim[3], Float:targetorigin[3], Float:velocity_normal[3], Float:aim_normal[3]
				
				entity_get_vector(target, EV_VEC_origin, targetorigin)
				
				entity_get_vector(ent, EV_VEC_velocity, velocity)
				
				xs_vec_sub(targetorigin, origin, aim)
				
				xs_vec_normalize(velocity, velocity_normal)
				xs_vec_normalize(aim, aim_normal)
				
				play_sound(ent, PING)
				
				if (velocity_normal[0] < aim_normal[0])
				{
					velocity[0] += extravel
				}
				else if (velocity_normal[0] > aim_normal[0])
				{
					velocity[0] -= extravel
				}
				
				if (velocity_normal[1] < aim_normal[1])
				{
					velocity[1] += extravel
				}
				else if (velocity_normal[1] > aim_normal[1])
				{
					velocity[1] -= extravel
				}
				
				if (velocity_normal[2] < aim_normal[2])
				{
					velocity[2] += extravel
				}
				else if (velocity_normal[2] > aim_normal[2])
				{
					velocity[2] -= extravel
				}
				
				velocity[2] += 5.0
				
				entity_set_vector(ent, EV_VEC_velocity, velocity)
				
				// When within blasting range, make our homing grenade think much much faster; results in better homing.
				if (get_distance_f(origin, targetorigin) < get_option_float(OPTION_HOMING_SUPER_RANGE))
				{
					entity_set_float(ent, EV_FL_nextthink, (get_gametime() + 0.05))
				}
				else
				{
					entity_set_float(ent, EV_FL_nextthink, (get_gametime() + 0.15))
				}
			}
			
			return HAM_IGNORED
		}
	}
	
	return HAM_IGNORED
}

public trip_activation(ent)
{
	if (is_valid_ent(ent))
		play_sound(ent, CHARGE)
}

public fw_think_post(ent)
{
	if (!is_valid_ent(ent))
		return HAM_IGNORED
	
	static owner, Float:origin[3], Float:gametime, bs_affected
	
	gametime = get_gametime()
	
	if (entity_get_float(ent, EV_FL_dmgtime) <= gametime)
		return HAM_IGNORED
	
	entity_get_vector(ent, EV_VEC_origin, origin)
	owner = entity_get_edict(ent, EV_ENT_owner)
	
	if (!is_user_connected(owner) || is_user_connecting(owner) || cl_team[owner] == CS_TEAM_UNASSIGNED)
	{
		entity_set_int(ent, EV_INT_flags, entity_get_int(ent, EV_INT_flags) | FL_KILLME)
		return HAM_IGNORED
	}
	
	if (!(bs_forward_collection & FWD_THINK_POST))
	{
		switch (get_grenade_type(ent))
		{
			case NADE_TRIP:
			{
				// We do this in order to make the trip nades be 10000% more accurate!
				entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.001)
			}
		}
		
		return HAM_IGNORED
	}
	
	bs_affected = 0
	
	if (get_option(OPTION_RESOURCE_USE) != 3)
	{
		bs_affected = ~0
	}
	else
	{
		static team_play, affect_owner
		team_play = get_option(OPTION_TEAM_PLAY)
		affect_owner = get_option(OPTION_AFFECT_OWNER)
		
		if (!team_play)
		{
			bs_affected = affect_owner ? ~0 : ~(1<<(owner-1))
		}
		else
		{
			for (new i=1;i<=g_maxplayers;i++)
			{
				if (!is_user_connected(i))
					continue
				
				if (affect_owner & i == owner)
					bs_affected |= (1<<(i-1))
				
				if (team_play && cs_get_user_team(i) != cs_get_user_team(owner))
					bs_affected |= (1<<(i-1))
			}
		}
	}
	
	switch (get_grenade_type(ent))
	{
		case NADE_PROXIMITY:
		{
			if (!allow_grenade_explode(ent))
				return HAM_IGNORED
			
			if (entity_get_float(ent, EV_FL_fuser4) <= gametime)
			{						
				entity_set_float(ent, EV_FL_fuser4, gametime + 2.0)
				
				if (entity_get_int(ent, EV_INT_flags) & FL_ONGROUND)
				{
					if (!get_option(OPTION_TEAM_PLAY))
					{
						if (get_option(OPTION_RESOURCE_USE) == 1)
						{
							show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5)
						}
						else
						{
							static i
							i = -1
							
							while ( (i = find_ent_in_sphere(i, origin, SMART_RADIUS_RING_SHOW)) )
							{
								if (i > g_maxplayers)
									break
								
								if (!is_user_alive(i) || (cl_is_bot & (1<<(i-1))))
									continue
								
								if (bs_affected & (1<<(i-1)))
									show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5, _, _, _, i)
							}
						}
					}
					else
					{
						switch (cl_team[owner])
						{
							case CS_TEAM_T: 
							{
								if (get_option(OPTION_RESOURCE_USE) == 1)
								{
									show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR)
								}
								else
								{
									static i
									i = -1
									
									while ( (i = find_ent_in_sphere(i, origin, SMART_RADIUS_RING_SHOW)) )
									{
										if (i > g_maxplayers)
											break
										
										if (!is_user_alive(i) || (cl_is_bot & (1<<(i-1))))
											continue
										
										if (bs_affected & (1<<(i-1)))
											show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR, i)
									}
								}
								
							}
							case CS_TEAM_CT:
							{
								if (get_option(OPTION_RESOURCE_USE) == 1)
								{
									show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR)
								}
								else
								{
									static i
									i = -1
									
									while ( (i = find_ent_in_sphere(i, origin, SMART_RADIUS_RING_SHOW)) )
									{
										if (i > g_maxplayers)
											break
										
										if (!is_user_alive(i) || (cl_is_bot & (1<<(i-1))))
											continue
										
										if (bs_affected & (1<<(i-1)))
											show_ring(origin, get_option_float(OPTION_RADIUS_PROXIMITY) * RING_SIZE_CONSTANT_PROXIMITY, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR, i)
									}
								}
							}
						}
					}
				}
			}
		}
		
		case NADE_MOTION:
		{
			static bs_holds
			bs_holds = entity_get_int(ent, EV_INT_iuser2)
			
			if (bs_holds && entity_get_float(ent, EV_FL_fuser4) <= gametime)
			{
				entity_set_float(ent, EV_FL_fuser4, get_gametime() + 0.1)
				
				if (!get_option(OPTION_TEAM_PLAY))
				{
					if ( get_option(OPTION_RESOURCE_USE) == 1)
					{
						show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1)
					}
					else
					{
						for (new i=1;i<=g_maxplayers;i++)
						{
							if ((bs_holds & (1<<(i-1))) && (bs_affected & (1<<(i-1))))
								show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, _, _, _, i)
						}
					}
				}
				else
				{
					switch (cl_team[owner])
					{
						case CS_TEAM_T:
						{
							if ( get_option(OPTION_RESOURCE_USE) == 1 )
							{
								show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR)
							}
							else
							{
								for (new i=1;i<=g_maxplayers;i++)
								{
									if ((bs_holds & (1<<(i-1))) && (bs_affected & (1<<(i-1))))
										show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR, i)
								}
							}
						}
						case CS_TEAM_CT:
						{
							if ( get_option(OPTION_RESOURCE_USE) == 1 )
							{
								show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR)
							}
							else
							{
								for (new i=1;i<=g_maxplayers;i++)
								{
									if ((bs_holds & (1<<(i-1))) && (bs_affected & (1<<(i-1))))
										show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR, i)
								}
							}
						}
						default:
						{
							if ( get_option(OPTION_RESOURCE_USE) == 1 )
							{
								show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, _, _, _)
							}
							else
							{
								for (new i=1;i<=g_maxplayers;i++)
								{
									if ((bs_holds & (1<<(i-1))) && (bs_affected & (1<<(i-1))))
										show_ring(origin, get_option_float(OPTION_RADIUS_MOTION) * RING_SIZE_CONSTANT_MOTION, 1, _, _, _, i)
								}
							}
						}
					}
				}
			}
		}
		
		case NADE_TRIP:
		{
			if (get_trip_grenade_mode(ent) != TRIP_SCANNING)
				return HAM_IGNORED
			
			// We do this in order to make the trip nades be 10000% more accurate!
			entity_set_float(ent, EV_FL_nextthink, get_gametime() + 0.001)
			
			if (entity_get_float(ent, EV_FL_fuser4) <= gametime)
			{
				new Float:end[3]
				get_trip_grenade_end_origin(ent, end)
				
				if (get_option(OPTION_RESOURCE_USE) == 1)
				{
					if (!get_option(OPTION_TEAM_PLAY))
					{
						draw_line_from_entity_broadcast(ent, end, 5, _, _, _)
					}
					else
					{
						switch (cl_team[owner])
						{
							case CS_TEAM_T:
							{
								draw_line_from_entity_broadcast(ent, end, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR)
							}
							case CS_TEAM_CT:
							{
								draw_line_from_entity_broadcast(ent, end, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR)
							}
							default:
							{
								draw_line_from_entity_broadcast(ent, end, 5, _, _, _)
							}
						}
					}
					
					entity_set_float(ent, EV_FL_fuser4, gametime + 0.5)
					return HAM_IGNORED
				}
				
				static  Float:first[3], Float:second[3], Float:porigin[3], Float:anglefraction, Float:third[3], Float:fourth[3]
				
				xs_vec_sub(origin,end,first)
				
				anglefraction = 1.0 - calc_cone_angle_from_distance(xs_vec_len(first))
				
				if (xs_vec_len(first) <= SMART_DISTANCE_LINE_PVS)
				{
					get_trip_grenade_middle_origin(ent, first) 
					
					if (!get_option(OPTION_TEAM_PLAY))
					{
						draw_line_from_entity(ent, end, 5, _, _, _, 0, first)
					}
					else
					{
						switch (cl_team[owner])
						{
							case CS_TEAM_T:
							{
								draw_line_from_entity(ent, end, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR, 0, first)
							}
							case CS_TEAM_CT:
							{
								draw_line_from_entity(ent, end, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR, 0, first)
							}
							default:
							{
								draw_line_from_entity(ent, end, 5, _, _, _, 0, first)
							}
						}
					}
					
					entity_set_float(ent, EV_FL_fuser4, gametime + 0.5)
					return HAM_IGNORED
				}
				
				xs_vec_mul_scalar(first,EXTRALENGTH_VECTOR / xs_vec_len(first),first)
				xs_vec_sub(end,first,fourth)
				xs_vec_add(origin,first,first)
				
				static players[32],num,id
				get_players(players,num,"ac")
				
				for (new i=0;i<num;i++)
				{
					id = players[i]
					entity_get_vector(id, EV_VEC_origin, porigin)
					
					xs_vec_sub(porigin, fourth, second)
					xs_vec_normalize(second, second)
					
					xs_vec_sub(porigin, first, third)
					xs_vec_normalize(third, third)
					
					xs_vec_sub(first,fourth,first)
					xs_vec_normalize(first,first)
					
					if ( xs_vec_dot(first,second) <= CONE_DROP_ANGLE_COSINUS || (0 - xs_vec_dot(first,third)) <= CONE_DROP_ANGLE_COSINUS )
						continue
					
					if (bs_affected & (1<<(id-1)))
					{
						if ( xs_vec_dot(first, second) >= anglefraction )
						{
							if (!get_option(OPTION_TEAM_PLAY))
							{
								draw_line_from_entity(ent, end, 5, _, _, _, id)
							}
							else
							{
								switch (cl_team[owner])
								{
									case CS_TEAM_T:
									{
										draw_line_from_entity(ent, end, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR, id)
									}
									case CS_TEAM_CT:
									{
										draw_line_from_entity(ent, end, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR, id)
									}
									default:
									{
										draw_line_from_entity(ent, end, 5, _, _, _, id)
									}
								}
							}
						}
						else
						{
							if ( (0 - xs_vec_dot(first, third)) >= anglefraction )
							{
								if (!get_option(OPTION_TEAM_PLAY))
								{
									draw_line_from_entity(ent, end, 5, _, _, _, id)
								}
								else if (bs_affected & (1<<(id-1)))
								{
									switch (cl_team[owner])
									{
										case CS_TEAM_T:
										{
											draw_line_from_entity(ent, end, 5, TEAMTE_RGB_R_COLOR, TEAMTE_RGB_G_COLOR, TEAMTE_RGB_B_COLOR, id)
										}
										case CS_TEAM_CT:
										{
											draw_line_from_entity(ent, end, 5, TEAMCT_RGB_R_COLOR, TEAMCT_RGB_G_COLOR, TEAMCT_RGB_B_COLOR, id)
										}
										default:
										{
											draw_line_from_entity(ent, end, 5, _, _, _, id)
										}
									}
								}
							}
						}
					}
				}
				
				entity_set_float(ent, EV_FL_fuser4, gametime + 0.5)
				
			}
		}
		
		default : return HAM_IGNORED
	}
	
	return HAM_IGNORED
}

public fw_touch(toucher, touched)
{
	if (!(bs_forward_collection & FWD_TOUCH))
		return HAM_IGNORED
	
	switch (get_grenade_type(toucher))
	{
		case NADE_IMPACT:
		{
			if (is_solid(touched))
			{
				make_explode(toucher)
				
				entity_set_float(toucher, EV_FL_nextthink, get_gametime() + 0.001)
				
				if (NadeRace:get_grenade_race(toucher) == GRENADE_SMOKEGREN)
				{
					entity_set_int(toucher, EV_INT_flags, entity_get_int(toucher, EV_INT_flags) | FL_ONGROUND)
				}
			}
		}
		
		case NADE_TRIP:
		{
			static classname[10]
			entity_get_string(touched, EV_SZ_classname, classname, charsmax(classname))
			
			if (get_trip_grenade_mode(toucher) > TRIP_NOT_ATTACHED || is_user_connected(touched))
			{
				return HAM_IGNORED
			}
			else
			{
				if (is_solid(touched))
				{
					entity_set_int(toucher, EV_INT_movetype, MOVETYPE_NONE)
					set_trip_grenade_mode(toucher, TRIP_ATTACHED)
					return (containi(classname, "door") != -1) ? HAM_SUPERCEDE : HAM_IGNORED
				}
			}
		}
	}
	
	return HAM_IGNORED
}

public fw_takedamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!(bs_forward_collection & FWD_TAKEDAMAGE))
		return HAM_IGNORED
	
	static aclassname[7], iclassname[8]
	
	entity_get_string(attacker,  EV_SZ_classname, aclassname, charsmax(aclassname))
	entity_get_string(inflictor,  EV_SZ_classname, iclassname, charsmax(iclassname))
	
	if ((damagebits & DMG_BLAST))
		return HAM_IGNORED
	
	if (!equal(aclassname, "player") || !equal(iclassname, "grenade"))
		return HAM_IGNORED
	
	if (attacker == victim)
	{
		damage *= (get_option_float(OPTION_DMG_SELF) / 100.0)
	}
	else
	{
		if (cl_team[attacker] == cl_team[victim] && get_option(OPTION_FRIENDLY_FIRE))
		{
			damage *= 0.02 * get_option_float(OPTION_DMG_TEAMMATES)
		}
	}
	
	static Float:origin[3], Float:user_origin[3], Float:fraction
	
	entity_get_vector(victim, EV_VEC_origin, user_origin)
	entity_get_vector(inflictor, EV_VEC_origin, origin)
	origin[2] += 2.0
	engfunc(EngFunc_TraceLine, user_origin, origin, IGNORE_MONSTERS, victim, g_ptrace[TH_DMG])

	get_tr2(g_ptrace[TH_DMG], TR_flFraction, fraction)
	
	if (fraction < 1.0)
	{
		damage *= (get_option_float(OPTION_DMG_THROUGH_WALL) / 100.0)
	}
	
	if ( get_option(OPTION_DAMAGE_SYSTEM) == 1)
	{
		damage *= get_option_float(OPTION_DMG_NORMAL)
	}
	else
	{
		new type = _:get_grenade_type(inflictor)
		type &= ~NADE_DONT_COUNT
		
		switch ( type )
		{
			case NADE_NORMAL:
			{
				damage *= get_option_float(OPTION_DMG_NORMAL)
			}
			
			case NADE_PROXIMITY:
			{
				damage *= get_option_float(OPTION_DMG_PROXIMITY)
			}
			
			case NADE_IMPACT:
			{
				damage *= get_option_float(OPTION_DMG_IMPACT)
			}
			
			case NADE_TRIP:
			{
				damage *= get_option_float(OPTION_DMG_TRIP)
			}
			
			case NADE_MOTION:
			{
				damage *= get_option_float(OPTION_DMG_MOTION)
			}
			
			case NADE_SATCHEL:
			{
				damage *= get_option_float(OPTION_DMG_SATCHEL)
			}
			
			case NADE_HOMING:
			{
				damage *= get_option_float(OPTION_DMG_HOMING)
			}
			
			default:
			{
				damage *= get_option_float(OPTION_DMG_NORMAL)
			}
		}
	}
	
	SetHamParamFloat(4, damage)
	
	return HAM_HANDLED
}

public fw_monster_takedamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if (!(bs_forward_collection & FWD_TAKEDAMAGE) || !get_option(OPTION_MONSTERMOD_SUPPORT))
		return HAM_IGNORED
	
	static aclassname[7], iclassname[8]
	
	entity_get_string(attacker,  EV_SZ_classname, aclassname, charsmax(aclassname))
	entity_get_string(inflictor,  EV_SZ_classname, iclassname, charsmax(iclassname))
	
	if ((damagebits & DMG_BLAST))
		return HAM_IGNORED
	
	if (!equal(aclassname, "player") || !equal(iclassname, "grenade"))
		return HAM_IGNORED
	
	static Float:origin[3], Float:user_origin[3], Float:fraction
	
	entity_get_vector(victim, EV_VEC_origin, user_origin)
	entity_get_vector(inflictor, EV_VEC_origin, origin)
	origin[2] += 2.0
	engfunc(EngFunc_TraceLine, user_origin, origin, IGNORE_MONSTERS, victim, g_ptrace[TH_DMG])

	get_tr2(g_ptrace[TH_DMG], TR_flFraction, fraction)
	
	if (fraction < 1.0)
	{
		damage *= (get_option_float(OPTION_DMG_THROUGH_WALL) / 100.0)
	}
	
	if ( get_option(OPTION_DAMAGE_SYSTEM) == 1)
	{
		damage *= get_option_float(OPTION_DMG_NORMAL)
	}
	else
	{
		new type = _:get_grenade_type(inflictor)
		type &= ~NADE_DONT_COUNT
		
		switch ( type )
		{
			case NADE_NORMAL:
			{
				damage *= get_option_float(OPTION_DMG_NORMAL)
			}
			
			case NADE_PROXIMITY:
			{
				damage *= get_option_float(OPTION_DMG_PROXIMITY)
			}
			
			case NADE_IMPACT:
			{
				damage *= get_option_float(OPTION_DMG_IMPACT)
			}
			
			case NADE_TRIP:
			{
				damage *= get_option_float(OPTION_DMG_TRIP)
			}
			
			case NADE_MOTION:
			{
				damage *= get_option_float(OPTION_DMG_MOTION)
			}
			
			case NADE_SATCHEL:
			{
				damage *= get_option_float(OPTION_DMG_SATCHEL)
			}
			
			case NADE_HOMING:
			{
				damage *= get_option_float(OPTION_DMG_HOMING)
			}
			
			default:
			{
				damage *= get_option_float(OPTION_DMG_NORMAL)
			}
		}
	}
	
	SetHamParamFloat(4, damage)
	
	return HAM_HANDLED
}

public fw_grenade_takedamage(grenade, inflictor, attacker, Float:damage, bits)
{
	if (!(bs_forward_collection & FWD_HPSYSTEM))
		return HAM_IGNORED
	
	if (inflictor == grenade)
	{
		SetHamReturnInteger(0)
		return HAM_SUPERCEDE
	}
	
	new Float:health, Float:origin[3], ok = false
	health = entity_get_float(grenade, EV_FL_health)
	
	if (!(1 <= attacker <= g_maxplayers))
		return HAM_SUPERCEDE
	
	if ((entity_get_int(grenade, EV_INT_flags) & FL_GODMODE) || (entity_get_float(grenade, EV_FL_takedamage) == DAMAGE_NO))
		return HAM_SUPERCEDE
	
	entity_get_vector(grenade, EV_VEC_origin, origin)
	
	if (entity_get_edict(grenade, EV_ENT_owner) != attacker && cl_team[entity_get_edict(grenade, EV_ENT_owner)] == cl_team[attacker])
	{
		damage *= get_option_float(OPTION_HITPOINT_FF) / 100.0
		ok = true
	}
	
	new string[8]
	entity_get_string(inflictor, EV_SZ_classname, string, charsmax(string))
	
	if (equal(string,"grenade"))
	{
		damage *= get_option_float(OPTION_HITPOINT_INTER_DMG) / 100.0
		ok = true
	}
	
	play_sound2(grenade, SOUND_HIT[random_num(0,4)])
	
	if (floatcmp(damage,health) != -1)
	{
		static NadeType:type, owner
		owner = entity_get_edict(grenade, EV_ENT_owner)
		type = get_grenade_type(grenade)
		type &= ~NadeType:NADE_DONT_COUNT
		
		if (get_option(OPTION_HITPOINT_DEATH))
		{
			make_explode(grenade)
			
			if (NadeRace:get_grenade_race(grenade) == GRENADE_SMOKEGREN)
			{
				entity_set_int(grenade, EV_INT_flags, entity_get_int(grenade, EV_INT_flags) | FL_ONGROUND)
				dllfunc(DLLFunc_Think, grenade)
				clear_line(grenade)
			}
			
			return HAM_SUPERCEDE
		}
		
		entity_set_int(grenade, EV_INT_flags, entity_get_int(grenade, EV_INT_flags) | FL_KILLME)
		cl_counter[owner][NadeRace:get_grenade_race(grenade)][type] -= 1
		
		if (get_option(OPTION_RESOURCE_USE))
			metal_gibs(origin)
		
		clear_line(grenade)
		
		return HAM_SUPERCEDE
	}
	
	if (ok)
	{
		SetHamParamFloat(4, damage)
		return HAM_HANDLED
	}
	
	return HAM_IGNORED
}

public fw_traceline(Float:start[3], Float:end[3], conditions, id, trace)
{
	if (!(bs_forward_collection & FWD_HPSYSTEM))
		return FMRES_IGNORED
	
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	if (cl_weapon[id] != CSW_KNIFE)
		return FMRES_IGNORED
	
	if (pev_valid(get_tr2(trace,TR_pHit)))
		return FMRES_IGNORED
	
	static Float:vec_end[3], i
	i = g_maxplayers
	
	get_tr2(trace, TR_vecEndPos, vec_end)
	
	while ((i = find_ent_in_sphere(i, vec_end, SHOT_SECOND_TEST_RADIUS)))
	{
		if (is_grenade(i, true))
		{
			static Float:origin[3]
			pev(i,pev_origin,origin)
			xs_vec_sub(origin,vec_end,origin)
			if (xs_vec_len(origin) > SHOT_KNIFE_REAL_RADIUS)
				continue
			
			set_tr2(trace, TR_pHit, i)
			break
		}
	}
	
	return FMRES_HANDLED
}

public fw_global_traceattack(ent, attacker, Float:damage, Float:direction[3], tracehdl, damagebits)
{
	if (!(bs_forward_collection & FWD_HPSYSTEM))
		return FMRES_IGNORED
	
	if (attacker > g_maxplayers || attacker < 1)
		return HAM_IGNORED
	
	if (cl_weapon[attacker] == CSW_KNIFE)
		return HAM_IGNORED
	
	static Float:origin[3],Float:offs[3]
	pev(attacker,pev_origin,origin)
	pev(attacker,pev_view_ofs,offs)
	xs_vec_add(origin,offs,origin)
	
	static Float:end[3], Float:point[3], Float:origin_nade[3], Float:track[3]
	get_tr2(tracehdl,TR_vecEndPos,end)
	
	xs_vec_sub(end,origin,point)
	xs_vec_mul_scalar(point, SHOT_PENETRATION_DISTANCE / xs_vec_len(point), point)
	xs_vec_add(end, point, end)
	
	static grenade
	static bool:ok
	static bool:reset_queue
	
	grenade = -1
	reset_queue = false
	
	while ((grenade = find_ent_by_class(grenade,"grenade")))
	{
		if (entity_get_float(grenade, EV_FL_dmgtime) < get_gametime())
			continue
		
		ok = false
		entity_get_vector(grenade, EV_VEC_origin, origin_nade)
		
		for (new i=0;i<SHOT_ENTITY_QUEUE_LENGTH;i++)
		{
			if (grenade == cl_entity_queue[attacker][i])
			{
				cl_entity_queue[attacker][i] = 0;
				ok = true;
				reset_queue = true;
				break;
			}
		}
		
		if (ok)
		{
			continue;
		}
		
		engfunc(EngFunc_TraceModel,origin,end,HULL_POINT,grenade,g_ptrace[TH_DMG])
		
		if(get_tr2(g_ptrace[TH_DMG],TR_pHit) == grenade)
		{
			ExecuteHamB(Ham_TraceAttack, grenade, attacker, damage, direction, g_ptrace[TH_DMG], damagebits)
			
			insert_in_queue(attacker, grenade)
		}
		else
		{
			new times = 1
			
			xs_vec_sub(origin_nade, end, track)
			
			while (times != SHOT_PENETRATION_READD_TIMES + 1 && xs_vec_len(track) > SHOT_SECOND_TEST_RADIUS)
			{
				xs_vec_add(end, point, track)
				
				for (new i=1;i<=times;++i)
				{
					xs_vec_add(track, point, track)
				}
				
				xs_vec_sub(origin_nade, track, track)
				
				times++;
			}
			
			if ( xs_vec_len(track) <= SHOT_SECOND_TEST_RADIUS )
			{
				set_tr2(g_ptrace[TH_DMG], TR_pHit, grenade)
				
				xs_vec_add(origin_nade, track, track)
				set_tr2(g_ptrace[TH_DMG], TR_vecEndPos, track)
				
				ExecuteHamB(Ham_TraceAttack, grenade, attacker, (damage / 2), direction, g_ptrace[TH_DMG], damagebits)
				
				insert_in_queue(attacker, grenade)
			}
		}
	}
	
	if (reset_queue)
	{
		for (new i=0;i<SHOT_ENTITY_QUEUE_LENGTH;i++)
		{
			cl_entity_queue[attacker][i] = 0
		}
	}
	
	return HAM_IGNORED
}

/* -------------------------------
[Plugin Zombie Mod Compatibility Forwards]
------------------------------- */
public zp_user_infected_post(id, infector)
{
	// Reset the mode on infection
	mode[id][GRENADE_EXPLOSIVE] = FirstEnabledMode(GRENADE_EXPLOSIVE)
	mode[id][GRENADE_FLASHBANG] = FirstEnabledMode(GRENADE_FLASHBANG)
	mode[id][GRENADE_SMOKEGREN] = FirstEnabledMode(GRENADE_SMOKEGREN)
	
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_MOTION] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_TRIP] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_MOTION] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_TRIP] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_MOTION] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_TRIP] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_SATCHEL] = 0
	
	static ent
	ent = -1
	
	// Get all the grenade entities
	while ((ent = find_ent_by_class(ent, "grenade")))
	{
		if (entity_get_edict(ent, EV_ENT_owner) != id)
			continue
		
		// Set the remove property if they aren't normal nades
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			entity_set_int(ent, EV_INT_flags , entity_get_int(ent, EV_INT_flags) | FL_KILLME)
	}	
	
	return PLUGIN_CONTINUE
}

public event_infect(id, attacker)
{
	// Reset the mode on infection
	mode[id][GRENADE_EXPLOSIVE] = FirstEnabledMode(GRENADE_EXPLOSIVE)
	mode[id][GRENADE_FLASHBANG] = FirstEnabledMode(GRENADE_FLASHBANG)
	mode[id][GRENADE_SMOKEGREN] = FirstEnabledMode(GRENADE_SMOKEGREN)
	
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_MOTION] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_TRIP] = 0
	cl_counter[id][GRENADE_EXPLOSIVE][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_MOTION] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_TRIP] = 0
	cl_counter[id][GRENADE_FLASHBANG][NADE_SATCHEL] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_MOTION] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_PROXIMITY] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_TRIP] = 0
	cl_counter[id][GRENADE_SMOKEGREN][NADE_SATCHEL] = 0
	
	static ent
	ent = -1
	
	// Get all the grenade entities
	while ((ent = find_ent_by_class(ent, "grenade")))
	{
		if (entity_get_edict(ent, EV_ENT_owner) != id)
			continue
		
		// Set the remove property if they aren't normal nades
		if(is_grenade(ent) && get_grenade_type(ent) != NADE_NORMAL)
			entity_set_int(ent, EV_INT_flags , entity_get_int(ent, EV_INT_flags) | FL_KILLME)
	}	
	
	return PLUGIN_CONTINUE
}

/* -------------------------------
[Usefull Functions -> NadeMode Tolls]
------------------------------- */
stock is_nademodes_enabled()
{
	if (get_option(OPTION_ENABLE_NADE_MODES))
	{
		return ((get_option(OPTION_NORMAL_ENABLED)<<0) | (get_option(OPTION_PROXIMITY_ENABLED)<<1) | (get_option(OPTION_IMPACT_ENABLED)<<2) | (get_option(OPTION_TRIP_ENABLED)<<3) | (get_option(OPTION_MOTION_ENABLED)<<4) | (get_option(OPTION_SATCHEL_ENABLED)<<5) | (get_option(OPTION_HOMING_ENABLED)<<6))
	}
	
	return 0
}

stock NadeType:FirstEnabledMode(NadeRace:race)
{
	if (is_mode_cvarenabled(g_firstenabledmode[race], race))
		return g_firstenabledmode[race]
	
	for (new NadeType:i=NADE_NORMAL;i<=NADE_HOMING;i++)
	{
		if (is_mode_cvarenabled(i, race))
		{
			g_firstenabledmode[race] = i
			return i
		}
	}
	
	return NADE_NORMAL
}

public is_mode_cvarenabled(NadeType:type, NadeRace:nade)
{
	switch (type)
	{
		case NADE_NORMAL:
		{
			return get_option(OPTION_NORMAL_ENABLED)
		}
		
		case NADE_PROXIMITY:
		{
			return get_option(OPTION_PROXIMITY_ENABLED)
		}
		
		case NADE_IMPACT:
		{
			return get_option(OPTION_IMPACT_ENABLED)
		}
		
		case NADE_TRIP:
		{
			return get_option(OPTION_TRIP_ENABLED)
		}
		
		case NADE_MOTION:
		{
			return get_option(OPTION_MOTION_ENABLED)
		}
		
		case NADE_SATCHEL:
		{
			return get_option(OPTION_SATCHEL_ENABLED)
		}
		
		case NADE_HOMING:
		{
			return get_option(OPTION_HOMING_ENABLED)
		}
	}
	
	return 0
}

public is_mode_enabled(id, NadeType:type, NadeRace:nade)
{
	switch (type)
	{
		case NADE_NORMAL:
		{
			return get_option(OPTION_NORMAL_ENABLED)
		}
		
		case NADE_PROXIMITY:
		{
			if (!get_option(OPTION_PROXIMITY_ENABLED))
				return 0
			
			if (!get_option(OPTION_LIMIT_SYSTEM))
				return 1
			
			if (!get_option(OPTION_LIMIT_PROXIMITY))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 1 && cl_counter[id][nade][type] < get_option(OPTION_LIMIT_PROXIMITY))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 2 && (cl_counter[id][GRENADE_EXPLOSIVE][type] + cl_counter[id][GRENADE_SMOKEGREN][type] + cl_counter[id][GRENADE_FLASHBANG][type]) < get_option(OPTION_LIMIT_PROXIMITY))
				return 1
			
			return 0
		}
		
		case NADE_IMPACT:
		{
			return get_option(OPTION_IMPACT_ENABLED)
		}
		
		case NADE_TRIP:
		{
			if (!get_option(OPTION_TRIP_ENABLED))
				return 0
			
			if (!get_option(OPTION_LIMIT_SYSTEM))
				return 1
			
			if (!get_option(OPTION_LIMIT_TRIP))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 1 && cl_counter[id][nade][type] < get_option(OPTION_LIMIT_TRIP))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 2 && (cl_counter[id][GRENADE_EXPLOSIVE][type] + cl_counter[id][GRENADE_SMOKEGREN][type] + cl_counter[id][GRENADE_FLASHBANG][type]) < get_option(OPTION_LIMIT_TRIP))
				return 1
			
			return 0
		}
		
		case NADE_MOTION:
		{
			if (!get_option(OPTION_MOTION_ENABLED))
				return 0
			
			if (!get_option(OPTION_LIMIT_SYSTEM))
				return 1
			
			if (!get_option(OPTION_LIMIT_MOTION))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 1 && cl_counter[id][nade][type] < get_option(OPTION_LIMIT_MOTION))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 2 && (cl_counter[id][GRENADE_EXPLOSIVE][type] + cl_counter[id][GRENADE_SMOKEGREN][type] + cl_counter[id][GRENADE_FLASHBANG][type]) < get_option(OPTION_LIMIT_MOTION))
				return 1
			
			return 0
		}
		
		case NADE_SATCHEL:
		{
			if (!get_option(OPTION_SATCHEL_ENABLED))
				return 0
			
			if (!get_option(OPTION_LIMIT_SYSTEM))
				return 1
			
			if (!get_option(OPTION_LIMIT_SATCHEL))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 1 && cl_counter[id][nade][type] < get_option(OPTION_LIMIT_SATCHEL))
				return 1
			
			if (get_option(OPTION_LIMIT_SYSTEM) == 2 && (cl_counter[id][GRENADE_EXPLOSIVE][type] + cl_counter[id][GRENADE_SMOKEGREN][type] + cl_counter[id][GRENADE_FLASHBANG][type]) < get_option(OPTION_LIMIT_SATCHEL))
				return 1
			
			return 0
		}
		
		case NADE_HOMING:
		{
			return get_option(OPTION_HOMING_ENABLED)
		}
	}
	
	return 1
}

public changemode(id, NadeRace:NADE_TYPE)
{
	if (!(grenade_can_be_used(NADE_TYPE)))
	{
		return
	}
	
	if (!is_mode_enabled(id, ++mode[id][NADE_TYPE], NADE_TYPE))
	{
		changemode(id, NADE_TYPE)
		return
	}
	
	switch (mode[id][NADE_TYPE])
	{
		case NADE_NORMAL:
		{
			client_print(id, print_center, "Mode - Normal")
		}
		
		case NADE_PROXIMITY:
		{
			client_print(id, print_center, "Mode - Proximity")
		}
		
		case NADE_IMPACT:
		{
			client_print(id, print_center, "Mode - Impact")
		}
		
		case NADE_TRIP:
		{
			client_print(id, print_center, "Mode - Trip laser")
		}
		
		case NADE_MOTION:
		{
			client_print(id, print_center, "Mode - Motion sensor")
		}
		
		case NADE_SATCHEL:
		{
			client_print(id, print_center, "Mode - Satchel charge")
		}
		
		case NADE_HOMING:
		{
			client_print(id, print_center, "Mode - Homing")
		}
		
		default:
		{
			mode[id][NADE_TYPE] = NADE_NORMAL
			changemode(id, NADE_TYPE)
		}
	}
}

/* -------------------------------
[Usefull Functions -> Grenade Property Set/Get]
------------------------------- */
is_grenade(ent, bool:enforce = false)
{
	if (!is_valid_ent(ent))
	{
		return 0
	}
	
	if (enforce)
	{
		if (!is_classname(ent, "grenade"))
			return 0
	}
	
	static weapon_id
	weapon_id = cs_get_weapon_id(ent)
	
	for (new i=0;i<3;i++)
	{
		if (weapon_id == NADE_WPID[NadeRace:i])
			return 1
	}
	
	return 0
}

is_classname(ent, const string[])
{
	new classname[20]
	
	entity_get_string(ent, EV_SZ_classname, classname, charsmax(classname))
	
	return equali(string, classname, strlen(string))
}

public get_grenade_race(grenade)
{
	switch (cs_get_weapon_id(grenade))
	{
		case CSW_HEGRENADE: 	return _:GRENADE_EXPLOSIVE
		case CSW_FLASHBANG: 	return _:GRENADE_FLASHBANG
		case CSW_SMOKEGRENADE: 	return _:GRENADE_SMOKEGREN
	}
	
	return -1
}

set_grenade_type(grenade, NadeType:g_type, bool:property = true)
{
	if (!is_valid_ent(grenade)) return
	
	static NadeRace:nade
	static owner
	
	owner = entity_get_edict(grenade, EV_ENT_owner)
	
	nade = NadeRace:get_grenade_race(grenade)
	
	if (g_FW_property > 0 && g_type != NADE_DUD)
	{
		new ret
		ExecuteForward(g_FW_property, ret, grenade, g_type)
		
		if (ret > PLUGIN_CONTINUE)
			return
	}
	
	// Set grenade properties and empty the slots so we can put some info
	entity_set_int(grenade, EV_INT_iuser1, _:g_type)
	entity_set_int(grenade, EV_INT_iuser2, 0)
	entity_set_int(grenade, EV_INT_iuser3, 0)
	entity_set_int(grenade, EV_INT_iuser4, 0)
	
	entity_set_vector(grenade, EV_VEC_vuser1, Float:{0.0, 0.0, 0.0})
	entity_set_vector(grenade, EV_VEC_vuser2, Float:{0.0, 0.0, 0.0})
	entity_set_vector(grenade, EV_VEC_vuser3, Float:{0.0, 0.0, 0.0})
	entity_set_vector(grenade, EV_VEC_vuser4, Float:{0.0, 0.0, 0.0})
	
	if (property == true)
	{
		switch (g_type)
		{
			case NADE_DUD:
			{
				entity_set_int(grenade, EV_INT_movetype, MOVETYPE_BOUNCE)
				entity_set_vector(grenade, EV_VEC_velocity, Float:{0.0, 0.0, 0.0})
			}
			
			case NADE_NORMAL:
			{
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_NORMAL)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_NORMAL))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
			}
			
			case NADE_PROXIMITY:
			{
				delay_explosion(grenade)
				set_grenade_allow_explode(grenade, get_option_float(OPTION_ARM_TIME_PROXIMITY))
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_PROXIMITY)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_PROXIMITY))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
				
				cl_counter[owner][nade][NADE_PROXIMITY] += 1
			}
			
			case NADE_IMPACT:
			{
				delay_explosion(grenade)
				entity_set_int(grenade, EV_INT_movetype, MOVETYPE_BOUNCE)
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_IMPACT)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_IMPACT))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
			}
			
			// I don't recommend setting a grenade to trip if it was another type in the first place.
			case NADE_TRIP:
			{
				delay_explosion(grenade)
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_TRIP)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_TRIP))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
				
				cl_counter[owner][nade][NADE_TRIP] += 1
			}
			
			case NADE_MOTION:
			{
				delay_explosion(grenade)
				set_grenade_allow_explode(grenade, get_option_float(OPTION_ARM_TIME_MOTION))
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_MOTION)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_MOTION))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
				
				cl_counter[owner][nade][NADE_MOTION] += 1
			}
			
			case NADE_SATCHEL:
			{
				delay_explosion(grenade)
				set_grenade_allow_explode(grenade,  get_option_float(OPTION_ARM_TIME_SATCHEL))
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_SATCHEL)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_SATCHEL))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
				
				cl_counter[owner][nade][NADE_SATCHEL] += 1
			}
			
			case NADE_HOMING:
			{
				entity_set_float(grenade, EV_FL_dmgtime, entity_get_float(grenade, EV_FL_dmgtime) + get_option_float(OPTION_HOMING_EXTRATIME))
				
				entity_set_float(grenade, EV_FL_health, floatabs(get_option_float(OPTION_HITPOINT_HOMING)))
				
				if (get_option(OPTION_MATERIAL_SYSTEM) == 2 && get_option(OPTION_HITPOINT_HOMING))
				{
					entity_set_float(grenade, EV_FL_takedamage, DAMAGE_YES)
				}
			}
		}
	}
}

public get_trip_grenade_react_method(grenade)
{
	new NadeRace:grenade_race = NadeRace:get_grenade_race(grenade)
	
	switch (grenade_race)
	{
		case GRENADE_EXPLOSIVE: return get_option(OPTION_REACT_TRIP_G)
		case GRENADE_FLASHBANG: return get_option(OPTION_REACT_TRIP_F)
		case GRENADE_SMOKEGREN: return get_option(OPTION_REACT_TRIP_S)
	}
	
	return -1
}

/* -------------------------------
[Usefull Functions -> Surface and solid tests + line of sight]
------------------------------- */
public bool:is_ent_monster(ent)
{
	if (!pev_valid(ent))
		return false
	
	if (!is_classname(ent, "func_wall"))
		return false
	
	return !!(pev(ent, pev_flags) & FL_MONSTER)
}

public bool:is_solid(ent)
{
	// Here we account for ent = 0, where 0 means it's part of the map (and therefore is solid)
	return ( ent ? ( (entity_get_int(ent, EV_INT_solid) > SOLID_TRIGGER) ? true : false ) : true )
}

public bool:is_attachable_surface(entity)
{
	static Float:velocity[3]
	
	if (is_valid_ent(entity))
	{
		if (!is_solid(entity)) return false 									// This is for func_breakables. The entity technically exists, but isn't solid.
		entity_get_vector(entity, EV_VEC_velocity, velocity) 					// This is for func_doors. The grenade touches the door, causing it to move.
		return (xs_vec_equal(velocity, Float:{0.0, 0.0, 0.0}) ? true : false)
	}
	
	return true
}

public bool:is_in_los(grenade_ent, player)
{
	static Float:start[3], Float:end[3]
	entity_get_vector(grenade_ent, EV_VEC_origin, start)
	entity_get_vector(player, EV_VEC_origin, end)
	
	start[2] += 2.0
	
	engfunc(EngFunc_TraceLine, start, end, IGNORE_MONSTERS, grenade_ent, g_ptrace[TH_LOS])
	
	static Float:dist
	get_tr2(g_ptrace[TH_LOS], TR_flFraction, dist)
	
	return ((dist == 1.0) ? true : false)
}


// This function is limited, it returns the same values unter CONE_CALC_DISTANCE_MAX 
stock Float:calc_cone_angle_from_distance(Float:distance)
{
	// The angle is calculated from a formula that looks like this
	// angle = atan(A*(CONE_BASE_RADIUS/(distance-B)))
	static Float:A,Float:B;

	// The constants A and B need to be calculated first, this if will only happen once
	if (A == 0.0 && B == 0.0)
	{
		if (CONE_BASE_RADIUS == 0.0)
		{
			A = ((CONE_CALC_DISTANCE_MIN-CONE_CALC_DISTANCE_MAX)*floattan(CONE_CALC_ANGLE_MAX, degrees)*floattan(CONE_CALC_ANGLE_MIN, degrees))/(floattan(CONE_CALC_ANGLE_MAX, degrees)-floattan(CONE_CALC_ANGLE_MIN, degrees))
			B = (CONE_CALC_DISTANCE_MAX*floattan(CONE_CALC_ANGLE_MAX, degrees) - CONE_CALC_DISTANCE_MIN*floattan(CONE_CALC_ANGLE_MIN, degrees))/(floattan(CONE_CALC_ANGLE_MAX, degrees)-floattan(CONE_CALC_ANGLE_MIN, degrees))
		}
		else
		{
			A = CONE_BASE_RADIUS;
			B = CONE_CALC_DISTANCE_MAX - CONE_BASE_RADIUS/floattan(CONE_CALC_ANGLE_MAX, degrees)
		}
	}
	
	// Return the angle in radians that is checked
	return (distance < CONE_CALC_DISTANCE_MAX) ? floatatan(A/((CONE_CALC_DISTANCE_MIN)-B), radian) : floatatan(A/((distance)-B), radian)
}

public insert_in_queue(id, ent_id)
{
	for (new i=0;i<SHOT_ENTITY_QUEUE_LENGTH;i++)
	{
		if (cl_entity_queue[id][i] == 0)
		{
			cl_entity_queue[id][i] = ent_id
			break;
		}
		
		if (i == SHOT_ENTITY_QUEUE_LENGTH - 1)
		{
			server_print("[NDM] Error! Unable to save so much entities!")
			server_print("[NDM] Increase the value of the ^"SHOT_ENTITY_QUEUE_LENGTH^" define and recompile!")
			log_amx("[NDM] Error! Unable to save so much entities")
			log_amx("[NDM] Increase the value of the ^"SHOT_ENTITY_QUEUE_LENGTH^" define and recompile!")
		}
	}
}
/* -------------------------------
[Message Functions]
------------------------------- */
draw_line_from_entity(entid, Float:end[3], staytime, R = NOTEAM_RGB_R_COLOR, G = NOTEAM_RGB_G_COLOR, B = NOTEAM_RGB_B_COLOR, id = 0, Float:pvs[3] = {0.0, 0.0, 0.0})
{
	( id == 0 ) ? engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, pvs, 0) : engfunc(EngFunc_MessageBegin, get_option(OPTION_MSG_SVC_BAD) ? MSG_ONE : MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, pvs, id)
	write_byte(TE_BEAMENTPOINT)
	write_short(entid)	// start entity
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(staytime)
	write_byte(10)
	write_byte(0)
	write_byte(R)
	write_byte(G)
	write_byte(B)
	write_byte(127)
	write_byte(1)
	message_end()	
}

stock draw_line(Float:start[3], Float:end[3], staytime, R = NOTEAM_RGB_R_COLOR, G = NOTEAM_RGB_G_COLOR, B = NOTEAM_RGB_B_COLOR)
{
	engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, Float:{0.0,0.0,0.0}, 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, start[0])
	engfunc(EngFunc_WriteCoord, start[1])
	engfunc(EngFunc_WriteCoord, start[2])
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(staytime)
	write_byte(10)
	write_byte(0)
	write_byte(R)
	write_byte(G)
	write_byte(B)
	write_byte(127)
	write_byte(1)
	message_end()	
}

draw_line_from_entity_broadcast(entid, Float:end[3], staytime, R = NOTEAM_RGB_R_COLOR, G = NOTEAM_RGB_G_COLOR, B = NOTEAM_RGB_B_COLOR)
{
	engfunc(EngFunc_MessageBegin, get_option(OPTION_MSG_SVC_BAD) ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, 0)
	write_byte(TE_BEAMENTPOINT)
	write_short(entid)	// start entity
	engfunc(EngFunc_WriteCoord, end[0])
	engfunc(EngFunc_WriteCoord, end[1])
	engfunc(EngFunc_WriteCoord, end[2])
	write_short(beampoint)
	write_byte(0)
	write_byte(0)
	write_byte(staytime)
	write_byte(10)
	write_byte(0)
	write_byte(R)
	write_byte(G)
	write_byte(B)
	write_byte(127)
	write_byte(1)
	message_end()	
}

clear_line(entid)
{
	message_begin(MSG_ALL, SVC_TEMPENTITY)
	write_byte(TE_KILLBEAM)
	write_short(entid)
	message_end()
}

show_ring(Float:origin[3], Float:addict, staytime, R = NOTEAM_RGB_R_COLOR, G = NOTEAM_RGB_G_COLOR, B = NOTEAM_RGB_B_COLOR , id = 0)
{
	( id == 0 ) ? engfunc(EngFunc_MessageBegin, get_option(OPTION_MSG_SVC_BAD) ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY, {0.0, 0.0, 0.0}, 0) : engfunc(EngFunc_MessageBegin, get_option(OPTION_MSG_SVC_BAD) ? MSG_ONE : MSG_ONE_UNRELIABLE , SVC_TEMPENTITY, {0.0, 0.0, 0.0}, id)
	write_byte(TE_BEAMCYLINDER)										 			 // TE_BEAMCYLINDER
	engfunc(EngFunc_WriteCoord, origin[0])										 // start X
	engfunc(EngFunc_WriteCoord, origin[1])										 // start Y
	engfunc(EngFunc_WriteCoord, origin[2])										 // start Z
	engfunc(EngFunc_WriteCoord, origin[0])										 // something X
	engfunc(EngFunc_WriteCoord, origin[1])										 // something Y
	engfunc(EngFunc_WriteCoord, origin[2] + addict)								 // something Z
	write_short(shockwave) 														 // sprite
	write_byte(0) 																 // startframe
	write_byte(0) 																 // framerate
	write_byte(staytime) 														 // life
	write_byte(60) 																 // width
	write_byte(0) 																 // noise
	write_byte(R) 																 // red
	write_byte(G) 																 // green
	write_byte(B) 																 // blue
	write_byte(100) 															 // brightness
	write_byte(0)																 // speed
	message_end()
}

metal_gibs(const Float: origin[3])
{
	message_begin(get_option(OPTION_MSG_SVC_BAD) ? MSG_ALL : MSG_BROADCAST, SVC_TEMPENTITY, {0, 0, 0}, 0)
	write_byte(TE_BREAKMODEL)									 				 // TE_BREAKMODEL
	engfunc(EngFunc_WriteCoord,origin[0])						 				 // x
	engfunc(EngFunc_WriteCoord,origin[1])						 				 // y
	engfunc(EngFunc_WriteCoord,origin[2] + 24)					 				 // z
	engfunc(EngFunc_WriteCoord,20.0)											 // size x
	engfunc(EngFunc_WriteCoord,20.0)							 				 // size y
	engfunc(EngFunc_WriteCoord,20.0)											 // size z
	engfunc(EngFunc_WriteCoord,random_num(-50,50))				 				 // velocity x
	engfunc(EngFunc_WriteCoord,random_num(-50,50))								 // velocity y
	engfunc(EngFunc_WriteCoord,25.0)							 				 // velocity z
	write_byte(10)																 // random velocity
	write_short(nadebits) 										 				 // model
	write_byte(10) 												 				 // count
	write_byte(25) 																 // life
	write_byte(2)												 				 // flags: BREAK_METAL
	message_end()
}
