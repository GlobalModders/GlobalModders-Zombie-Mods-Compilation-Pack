#include <amxmodx>
#include <amxmisc>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <engine>

#define PLUGIN "Zombie United"
#define VERSION "1.0"
#define AUTHOR "NST"

// Setting File Name
new const SETTING_FILE[] = "zombie_united.ini"
new const CVAR_FILE[] = "zombie_united.cfg"
new const LANG_FILE[] = "zombie_united.txt"
new const ZOMBIE_MOD = 2

// Limiters for stuff not worth making dynamic arrays out of (increase if needed)
const MAX_STATS_SAVED = 64
const MAX_SUPPLYBOX = 100
const TOTAL_ITEMS = 16
const ITEM_SPWEAPON = 16
const MAX_SPAWNS = 128
new const SPAWNS_URL[] = "%s/csdm/%s.spawns.cfg"
new const SPAWNS_BOX_URL[] = "%s/zombie_united/%s.supplybox_spawns.cfg"

// Cvar
new cvar_lighting, cvar_thunder, cvar_randspawn, cvar_zombie_attack_damage, cvar_weapons_uclip,
cvar_nvg_zombie_give, cvar_nvg_zombie_color[3], cvar_nvg_zombie_alpha, cvar_nvg_zombie_size, cvar_damage_nade, cvar_damage_grenade,
cvar_icon_deplay, cvar_icon, cvar_icon_light, cvar_icon_size

// available spawn points counter
new g_spawnCount, g_spawnCount2
new Float:g_spawns[MAX_SPAWNS][3], Float:g_spawns2[MAX_SPAWNS][3] // spawn points data
new g_spawnCount_box, g_spawnCount2_box
new Float:g_spawns_box[MAX_SPAWNS][3], Float:g_spawns2_box[MAX_SPAWNS][3] // spawn points data

// Knock back
new cvar_knockback, cvar_knockbackdamage, cvar_knockbackpower, cvar_knockbackzvel,
Float:kb_weapon_power[31] = {-1.0, ... }

// Player
new g_zombie[33], g_zombieclass[33], g_restore_health[33], g_respawning[33], g_protection[33], g_nvg[33], g_class[33],
g_item[33][2], g_nouseitem[33], g_blind[33], g_damagedouble[33], g_fast[33], g_infgrenade[33], g_invincibility[33], g_jumpup[33],
g_shootingdown[33], g_shootingup[33], g_stone[33], g_supplybox_wait[33], Float:g_current_gravity[33], Float:g_icon_delay[33],
g_newround, g_endround, g_rount_count, g_score_ct, g_score_te, g_tickets_ct, g_tickets_te, g_maxplayers, g_fwSpawn, g_supplybox_num,
g_startcount, g_freezetime
 
// Msg
new g_msgBarTime, g_msgStatusIcon, g_HudMsg_Health,
g_msgScenario, g_msgDamage, g_HudMsg_ScoreMatch, g_msgHostagePos, g_msgHostageK, g_msgFlashBat, g_msgNVGToggle, g_msgHudTextArgs,
g_msgWeapPickup, g_msgHealth, g_msgAmmoPickup, g_msgTextMsg, g_msgSendAudio, g_msgTeamScore, g_msgScreenFade, g_msgClCorpse


// Customization vars
new g_tickets, Float:g_weapons_stay, g_human_health, g_human_ammo, g_money_start, Float:g_respawn_wait, Float:g_pro_time, Array:g_pro_color, g_zombie_armor,

restore_health_spr[64], restore_health_idspr, Float:restore_health_time, restore_health_dmg,

supplybox_max, supplybox_num, supplybox_total_in_time, Float:supplybox_time, Array:supplybox_models, supplybox_sound_pickup[64], Array:human_item, Array:zombie_item, Array:spweapon_item,
supplybox_sound_drop[64], supplybox_sound_use[64], supplybox_count, supplybox_ent[MAX_SUPPLYBOX], supplybox_ent_reset[MAX_SUPPLYBOX], SUPPLYBOX_CLASSNAME[] = "nst_zbu_supplybox",
supplybox_icon_spr[64],  supplybox_icon_idspr,
Float:item_blind_time, Float:item_curse_time, Float:item_damagedouble_time, Float:item_damagedouble_dmg, item_enemyhpdown_num, item_enemyhpdown_sound[64],
Float:item_fast_speed, Float:item_fast_time, item_fast_sound_start[64], item_fast_sound_heartbeat[64], Float:item_infgrenade_time,
Float:item_invincibility_time, Float:item_jumpup_time, Float:item_jumpup_gravity, Float:item_shootingdown_time, Float:item_shootingdown_recoil,
Float:item_shootingup_time, Float:item_shootingup_recoil, item_teamhprecovery_num, item_teamhprecovery_sound[64], Float:item_stone_time,

zombiebom_model[64], Float:zombiebom_radius, Float:zombiebom_power, zombiebom_sprites_exp[64], zombiebom_sound_exp[64],
zombiebom_idsprites_exp, zombiebom_model_p[64], zombiebom_model_w[64],

Array:sound_zombie_attack, Array:sound_zombie_hitwall, Array:sound_zombie_swing, Array:sound_thunder,

models_friend_ct[64], idmodels_friend_ct, models_friend_te[64], idmodels_friend_te,

Array:weapons_pri, Array:weapons_pri_name, Array:weapons_sec, Array:weapons_sec_name, Array:weapons_nade,

Array:lights_thunder, g_lights_i, g_lights_cycle[64], g_lights_cycle_len, g_ambience_rain, g_ambience_snow, g_ambience_fog,
g_fog_color[12], g_fog_density[10], g_sky_enable, Array:g_sky_names, Array:g_objective_ents, g_blockbuy

// class zombie var
new class_count, Array:zombie_name, Array:zombie_health, Array:zombie_gravity, Array:zombie_speed, Array:zombie_knockback, Array:zombie_modelindex,
Array:zombie_sound_death1, Array:zombie_sound_death2, Array:zombie_sound_hurt1, Array:zombie_sound_hurt2, Array:zombie_wpnmodel,
Array:zombie_modelindex_host, Array:zombie_modelindex_origin, Array:zombie_viewmodel_host, Array:zombie_viewmodel_origin, Array:zombiebom_viewmodel,
Array:zombie_sex, Array:zombie_sound_heal

// Customization file sections
enum
{
	SECTION_NONE = 0,
	SECTION_CONFIG_VALUE,
	SECTION_RESTORE_HEALTH,
	SECTION_SUPPLYBOX,
	SECTION_ZOMBIEBOM,
	SECTION_SOUNDS,
	SECTION_SPRITES,
	SECTION_MENUWEAPONS,
	SECTION_WEATHER_EFFECTS,
	SECTION_SKY,
	SECTION_LIGHTNING,
	SECTION_KNOCKBACK,
	SECTION_OBJECTIVE_ENTS,
	SECTION_MODELS
}
// Task offsets
enum (+= 100)
{
	TASK_WELLCOME = 2000,
	TASK_RESPAWN,
	TASK_MAKEPLAYER,
	TASK_MENUCLASS,
	TASK_PROTECTION,
	TASK_NVISION,
	TASK_THUNDER_PRE,
	TASK_THUNDER,
	TASK_SUPPLYBOX,
	TASK_SUPPLYBOX_MODEL,
	TASK_SUPPLYBOX_HELP,
	TASK_SUPPLYBOX_WAIT,
	TASK_BLIND,
	TASK_CURSE,
	TASK_DAMAGEDOUBLE,
	TASK_FAST,
	TASK_FAST_HEARTBEAT,
	TASK_INFGRENADE,
	TASK_INVINC,
	TASK_JUMPUP,
	TASK_SHOOTINGDOWN,
	TASK_SHOOTINGUP,
	TASK_STONE,
	TASK_ATTACKMENT
}
// IDs inside tasks
#define ID_RESPAWN (taskid - TASK_RESPAWN)
#define ID_MAKEPLAYER (taskid - TASK_MAKEPLAYER)
#define ID_MENUCLASS (taskid - TASK_MENUCLASS)
#define ID_PROTECTION (taskid - TASK_PROTECTION)
#define ID_NVISION (taskid - TASK_NVISION)
#define ID_SUPPLYBOX_WAIT (taskid - TASK_SUPPLYBOX_WAIT)
#define ID_BLIND (taskid - TASK_BLIND)
#define ID_CURSE (taskid - TASK_CURSE)
#define ID_DAMAGEDOUBLE (taskid - TASK_DAMAGEDOUBLE)
#define ID_FAST (taskid - TASK_FAST)
#define ID_FAST_HEARTBEAT (taskid - TASK_FAST_HEARTBEAT)
#define ID_INFGRENADE (taskid - TASK_INFGRENADE)
#define ID_INVINC (taskid - TASK_INVINC)
#define ID_JUMPUP (taskid - TASK_JUMPUP)
#define ID_SHOOTINGDOWN (taskid - TASK_SHOOTINGDOWN)
#define ID_SHOOTINGUP (taskid - TASK_SHOOTINGUP)
#define ID_STONE (taskid - TASK_STONE)
#define ID_ATTACKMENT (taskid - TASK_ATTACKMENT)


// CS Teams
enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

// CS Player PData Offsets (win32)
const OFFSET_PAINSHOCK = 108 // ConnorMcLeod
const OFFSET_CSTEAMS = 114
const OFFSET_LINUX = 5 // offsets 5 higher in Linux builds
const IMPULSE_FLASHLIGHT = 100
const OFFSET_FLASHLIGHT_BATTERY = 244
const DMG_HEGRENADE = (1<<24)

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))
const NOCLIP_WPN_BS = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))

// Max BP ammo for weapons
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
			30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }
			
// Max Clip for weapons
new const MAXCLIP[] = { -1, 13, -1, 10, -1, 7, -1, 30, 30, -1, 30, 20, 25, 30, 35, 25, 12, 20,
			10, 30, 100, 8, 30, 30, 20, -1, 7, 30, 30, -1, 50 }

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

// block cmd buy
#define MAXMENUPOS 34
new g_Aliases[MAXMENUPOS][] = {"usp","glock","deagle","p228","elites","fn57","m3","xm1014","mp5","tmp","p90","mac10","ump45","ak47","galil","famas","sg552","m4a1","aug","scout","awp","g3sg1","sg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"} 
new g_Aliases2[MAXMENUPOS][] = {"km45","9x19mm","nighthawk","228compact","elites","fiveseven","12gauge","autoshotgun","smg","mp","c90","mac10","ump45","cv47","defender","clarion","krieg552","m4a1","bullpup","scout","magnum","d3au1","krieg550","m249","vest","vesthelm","flash","hegren","sgren","defuser","nvgs","shield","primammo","secammo"}

// HACK: pev_ field used to store additional ammo on weapons
const PEV_ADDITIONAL_AMMO = pev_iuser1

// pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_INFECTION = 1111

new WpnName[32]
new Float:cl_pushangle[33][3]

// HUD messages
const Float:HUD_SCORE_X = -1.0
const Float:HUD_SCORE_Y = 0.01
const Float:HUD_HEALTH_X = 0.015
const Float:HUD_HEALTH_Y = 0.92

// CS Sound
new const sound_buyammo[] = "items/9mmclip1.wav"
new const sound_nvg[2][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

// Some constants
const FFADE_IN = 0x0000
const FFADE_STAYOUT = 0x0004
const UNIT_SECOND = (1<<12)

// Weapons Offsets (win32)
const OFFSET_flNextPrimaryAttack = 46
const OFFSET_flNextSecondaryAttack = 47
const OFFSET_flTimeWeaponIdle = 48
const OFFSET_flNextAttack = 83

// Linux diff's
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

new g_hamczbots, cvar_botquota
new g_default_model
new const g_human_model[][] = {
	"arctic",
	"gsg9",
	"guerilla",
	"gign",
	"leet",
	"sas",
	"terror",
	"urban"
}

/*================================================================================
 [Natives, Precache and Init]
=================================================================================*/
public plugin_natives()
{
	// Player natives
	register_native("nst_zb_get_mod", "native_get_mod", 1)
	register_native("nst_zb_get_user_zombie", "native_get_user_zombie", 1)
	register_native("nst_zb_get_user_zombie_class", "native_get_user_zombie_class", 1)
	register_native("nst_zb_color_saytext", "natives_color_saytext", 1)
	register_native("nst_zb_get_user_start_health", "native_get_user_start_health", 1)
	register_native("nst_zb_get_user_level", "native_get_user_level", 1)
	register_native("nst_zb_get_take_damage", "native_get_take_damage", 1)
	register_native("nst_zb_get_damage_nade", "native_get_damage_nade", 1)

	// External additions natives
	register_native("nst_zbu_register_zombie_class", "native_register_zombie_class", 1)
	
	// Fix Bug
	register_native("nst_zb_get_user_supplybox", "native_novalue", 1)
	register_native("nst_zb_remove_user_supplybox", "native_novalue", 1)
	register_native("nst_zb_get_user_hero", "native_novalue", 1)
	register_native("nst_zb_zombie_respawn", "native_novalue", 1)
	register_native("nst_zb_remove_weapons_newround", "native_novalue", 1)
	register_native("nst_zb_human_kill_zombie", "native_novalue", 1)
	register_native("nst_zb_get_user_damage_attack", "native_novalue", 1)
	register_native("nst_zb_set_user_damage_attack", "native_novalue", 1)
	register_native("nst_zb_get_maxlevel_human", "native_novalue", 1)
	register_native("nst_zb_get_weapons_ammo", "native_novalue", 1)

	register_native("nst_zb3_register_zombie_class", "native_novalue", 1)
	register_native("nst_zbs_register_zombie_class", "native_novalue", 1)

}
public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Language files
	register_dictionary(LANG_FILE)
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	register_event("CurWeapon","CurrentWeapon","be","1=1")
	register_event("DeathMsg", "Death", "a")

	// HAM Forwards
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	for(new i=1; i<=CSW_P90; i++)
	{
		if( !(NOCLIP_WPN_BS & (1<<i)) && get_weaponname(i, WpnName, charsmax(WpnName)) )
		{
			
			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fw_primary_attack")
			RegisterHam(Ham_Weapon_PrimaryAttack, WpnName, "fw_primary_attack_post",1) 
		}
	}
	
	// FM Forwards
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_GetGameDescription, "fw_gamedesc")
	unregister_forward(FM_Spawn, g_fwSpawn)
	
	// Admin commands
	register_concmd("nst_zbu_respawn", "cmd_respawn_player", _, "<target> - Respawn someone", 0)
	//register_concmd("nst_zbu_use","cmd_use_item")
	//register_concmd("qq", "qq")
	
	// clie ncommands
	register_clcmd("nightvision", "cmd_nightvision")

	// Message IDs
	g_msgBarTime = get_user_msgid("BarTime")
	g_msgStatusIcon = get_user_msgid("StatusIcon")
	g_msgScenario = get_user_msgid("Scenario")
	g_msgDamage = get_user_msgid("Damage")
	g_msgHostagePos = get_user_msgid("HostagePos")
	g_msgHostageK = get_user_msgid("HostageK")
	g_msgFlashBat = get_user_msgid("FlashBat")
	g_msgNVGToggle = get_user_msgid("NVGToggle")
	g_msgWeapPickup = get_user_msgid("WeapPickup")
	g_msgHealth = get_user_msgid("Health")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
	g_msgTextMsg = get_user_msgid("TextMsg")
	g_msgSendAudio = get_user_msgid("SendAudio")
	g_msgTeamScore = get_user_msgid("TeamScore")
	g_msgScreenFade = get_user_msgid("ScreenFade");
	g_msgHudTextArgs = get_user_msgid("HudTextArgs")
	g_msgClCorpse = get_user_msgid("ClCorpse")
	
	// Message hooks
	register_message(g_msgHealth, "message_health")
	register_message(g_msgFlashBat, "message_flashbat")
	register_message(g_msgNVGToggle, "message_nvgtoggle")
	register_message(g_msgWeapPickup, "message_weappickup")
	register_message(g_msgAmmoPickup, "message_ammopickup")
	register_message(g_msgScenario, "message_scenario")
	register_message(g_msgHostagePos, "message_hostagepos")
	register_message(g_msgTextMsg, "message_textmsg")
	register_message(g_msgSendAudio, "message_sendaudio")
	register_message(g_msgTeamScore, "message_teamscore")
	register_message(g_msgHudTextArgs, "message_hudtextargs")
	//register_message(g_msgStatusIcon, "message_statusicon")
	
	// Block msg
	set_msg_block(g_msgClCorpse, BLOCK_SET)
	
	// CVARS Game
	cvar_lighting = register_cvar("nst_zbu_light", "")
	cvar_thunder = register_cvar("nst_zbu_thunderclap", "90")
	cvar_randspawn = register_cvar("nst_zbu_random_spawn", "0")
	cvar_zombie_attack_damage = register_cvar("nst_zbu_zombie_attack_damage", "5.0")
	cvar_weapons_uclip = register_cvar("nst_zbu_weapons_uclip", "0")
	cvar_damage_nade = register_cvar("nst_zbu_damage_nade", "100")
	cvar_damage_grenade = register_cvar("nst_zbu_damage_grenade", "50")
	
	// CVARS - Flashlight and Nightvision
	cvar_nvg_zombie_give = register_cvar("nst_zbu_nvg_zombie_give", "1")
	cvar_nvg_zombie_alpha = register_cvar("nst_zbu_nvg_zombie_alpha", "70")
	cvar_nvg_zombie_size = register_cvar("nst_zbu_nvg_zombie_size", "150")
	cvar_nvg_zombie_color[0] = register_cvar("nst_zbu_nvg_zombie_color_r", "253")
	cvar_nvg_zombie_color[1] = register_cvar("nst_zbu_nvg_zombie_color_g", "110")
	cvar_nvg_zombie_color[2] = register_cvar("nst_zbu_nvg_zombie_color_b", "110")

	// CVARS - Knockback
	cvar_knockback = register_cvar("nst_zbu_knockback", "1")
	cvar_knockbackdamage = register_cvar("nst_zbu_knockback_damage", "0")
	cvar_knockbackpower = register_cvar("nst_zbu_knockback_power", "1")
	cvar_knockbackzvel = register_cvar("nst_zbu_knockback_zvel", "0")

	// CVARS - Other
	cvar_botquota = get_cvar_pointer("bot_quota")
	cvar_icon = register_cvar("nst_zbu_icon", "1")
	cvar_icon_deplay = register_cvar("nst_zbu_icon_deplay", "0.03")
	cvar_icon_light = register_cvar("nst_zbu_icon_light", "100")
	cvar_icon_size = register_cvar("nst_zbu_icon_size", "2")
	
	// Collect random spawn points
	load_spawns()
	load_spawns_box()
	
	// Set a random skybox?
	if (g_sky_enable)
	{
		new sky[32]
		ArrayGetString(g_sky_names, random_num(0, ArraySize(g_sky_names) - 1), sky, charsmax(sky))
		set_cvar_string("sv_skyname", sky)
	}
	
	// Disable sky lighting so it doesn't mess with our custom lighting
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)
	set_cvar_float("mp_roundtime", 10.0)
	
	// Create the HUD Sync Objects
	g_HudMsg_Health = CreateHudSyncObj()
	g_HudMsg_ScoreMatch = CreateHudSyncObj()
	
	// Get Max Players
	g_maxplayers = get_maxplayers()
	
	// Task
	set_task(2.0,"radar_scan",_,_,_,"b")
	set_task(1.0, "show_hud_client", _, _, _, "b")
}

public plugin_precache()
{
	// Initialize a few dynamically sized arrays (alright, maybe more than just a few...)
	g_pro_color = ArrayCreate(32, 1)
	supplybox_models = ArrayCreate(64, 1)
	human_item = ArrayCreate(64, 1)
	zombie_item = ArrayCreate(64, 1)
	spweapon_item = ArrayCreate(64, 1)
	sound_zombie_attack = ArrayCreate(64, 1)
	sound_zombie_hitwall = ArrayCreate(64, 1)
	sound_zombie_swing = ArrayCreate(64, 1)
	sound_thunder = ArrayCreate(64, 1)
	weapons_pri = ArrayCreate(64, 1)
	weapons_pri_name = ArrayCreate(64, 1)
	weapons_sec = ArrayCreate(64, 1)
	weapons_sec_name = ArrayCreate(64, 1)
	weapons_nade = ArrayCreate(64, 1)
	lights_thunder = ArrayCreate(32, 1)
	g_sky_names = ArrayCreate(32, 1)
	g_objective_ents = ArrayCreate(32, 1)

	// class zombie
	zombie_name = ArrayCreate(64, 1)
	zombie_health = ArrayCreate(1, 1)
	zombie_gravity = ArrayCreate(1, 1)
	zombie_speed = ArrayCreate(1, 1)
	zombie_knockback = ArrayCreate(1, 1)
	zombie_sex = ArrayCreate(1, 1)
	zombie_sound_death1 = ArrayCreate(64, 1)
	zombie_sound_death2 = ArrayCreate(64, 1)
	zombie_sound_hurt1 = ArrayCreate(64, 1)
	zombie_sound_hurt2 = ArrayCreate(64, 1)
	zombie_viewmodel_host = ArrayCreate(64, 1)
	zombie_viewmodel_origin = ArrayCreate(64, 1)
	zombie_modelindex = ArrayCreate(1, 1)
	zombie_modelindex_host = ArrayCreate(1, 1)
	zombie_modelindex_origin = ArrayCreate(1, 1)
	zombie_wpnmodel = ArrayCreate(64, 1)
	zombie_sound_heal = ArrayCreate(64, 1)
	zombiebom_viewmodel = ArrayCreate(64, 1)
	
	// Load customization data
	load_customization_from_files()
	
	// CS sounds (just in case)
	engfunc(EngFunc_PrecacheSound, sound_buyammo)
	g_default_model = engfunc(EngFunc_PrecacheModel, "models/player/gign/gign.mdl")
	
	new i, buffer[100]
	
	// Custom sounds
	for (i = 0; i < ArraySize(sound_thunder); i++)
	{
		ArrayGetString(sound_thunder, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_zombie_attack); i++)
	{
		ArrayGetString(sound_zombie_attack, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_zombie_hitwall); i++)
	{
		ArrayGetString(sound_zombie_hitwall, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	for (i = 0; i < ArraySize(sound_zombie_swing); i++)
	{
		ArrayGetString(sound_zombie_swing, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheSound, buffer)
	}
	precache_sound(supplybox_sound_drop)
	precache_sound(supplybox_sound_pickup)
	precache_sound(supplybox_sound_use)
	precache_sound(item_fast_sound_start)
	precache_sound(item_fast_sound_heartbeat)
	precache_sound(item_enemyhpdown_sound)
	precache_sound(item_teamhprecovery_sound)
	for(new i = 0; i < sizeof(g_human_model); i++)
	{
		static model[64]
		formatex(model, sizeof(model), "models/player/%s/%s.mdl", g_human_model[i], g_human_model[i])
		
		engfunc(EngFunc_PrecacheModel, model)
	}
	
	// Custom models
	for (i = 0; i < ArraySize(supplybox_models); i++)
	{
		ArrayGetString(supplybox_models, i, buffer, charsmax(buffer))
		engfunc(EngFunc_PrecacheModel, buffer)
	}
	
	// Custom sprites
	idmodels_friend_ct = engfunc(EngFunc_PrecacheModel, models_friend_ct)
	idmodels_friend_te = engfunc(EngFunc_PrecacheModel, models_friend_te)
	supplybox_icon_idspr = engfunc(EngFunc_PrecacheModel, supplybox_icon_spr)
	
	// zombie bomb
	engfunc(EngFunc_PrecacheModel, zombiebom_model_p)
	engfunc(EngFunc_PrecacheModel, zombiebom_model_w)
	zombiebom_idsprites_exp = engfunc(EngFunc_PrecacheModel, zombiebom_sprites_exp)
	engfunc(EngFunc_PrecacheSound, zombiebom_sound_exp)
	
	new ent
	// Fake Hostage (to force round ending)
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "hostage_entity"))
	if (pev_valid(ent))
	{
		engfunc(EngFunc_SetOrigin, ent, Float:{8192.0,8192.0,8192.0})
		dllfunc(DLLFunc_Spawn, ent)
	}

	// Weather/ambience effects
	if (g_ambience_fog)
	{
		ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", g_fog_density, "env_fog")
			fm_set_kvd(ent, "rendercolor", g_fog_color, "env_fog")
		}
	}
	if (g_ambience_rain) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if (g_ambience_snow) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))

	// Prevent some entities from spawning
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn")
	
}
public plugin_cfg()
{
	// Get configs dir
	new cfgdir[32]
	get_configsdir(cfgdir, charsmax(cfgdir))
	
	// Execute config file (zombieplague.cfg)
	server_cmd("exec %s/%s", cfgdir, CVAR_FILE)

	// Lighting task
	set_task(5.0, "lighting_effects", _, _, _, "b")
	
	// Cache CVARs after configs are loaded / call roundstart manually
	set_task(0.5, "event_round_start")
	set_task(0.5, "logevent_round_start")
}


/*================================================================================
 [Main Events]
=================================================================================*/
// Event Round Start
public event_round_start()
{
	// set value
	g_freezetime = 1
	g_newround = 1
	g_endround = 0
	g_tickets_ct = 0
	g_tickets_te = 0
	supplybox_count = 0
	if (g_startcount) g_rount_count += 1
	
	if (g_rount_count)
	{
		// reset value
		for (new id = 1; id <= g_maxplayers; id++)
		{
			if (!is_user_alive(id)) continue;
			
			// reset value
			reset_value_death(id)
			
			// team player attackment
			if (task_exists(id+TASK_ATTACKMENT)) remove_task(id+TASK_ATTACKMENT)
			set_task (2.0, "team_player_attackment", id+TASK_ATTACKMENT, _, _, "b")
		}
		// wellcome
		if (task_exists(TASK_WELLCOME)) remove_task(TASK_WELLCOME)
		set_task(2.0, "wellcome", TASK_WELLCOME)
	}
}
// Log Event Round Start
public logevent_round_start()
{
	g_freezetime = 0
	g_newround = 0
	
	if (g_rount_count)
	{
		// make supply box
		if (task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
		set_task(supplybox_time, "create_supply_box", TASK_SUPPLYBOX)
	}
}
// Log Event Round End
public logevent_round_end()
{
	// set score team
	if (g_rount_count)
	{
		new message[64]
		if (g_tickets_ct > g_tickets_te)
		{
			g_score_ct += 1
			play_sound_endround("ctwin")
			format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_WIN_CT")
		}
		else if (g_tickets_ct < g_tickets_te)
		{
			g_score_te += 1
			play_sound_endround("terwin")
			format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_WIN_TE")
		}
		else
		{
			play_sound_endround("rounddraw")
			format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_DRAW")
		}
		
		// show hud msg
		SendCenterText(0, message)
	}
	
	// reset
	g_endround = 1
	remove_supplybox()
}
public wellcome()
{
	color_saytext(0, "^x03-=[^x04Zombie United (CSO-NST)^x03]=-")
	if (task_exists(TASK_WELLCOME)) remove_task(TASK_WELLCOME)
	set_task(60.0, "wellcome", TASK_WELLCOME)
}

/*================================================================================
 [Clien Public]
=================================================================================*/
// Client joins the game
public client_putinserver(id)
{
	// reset value
	reset_value(id)
	
	// Reg Ham Zbot
	if (is_user_bot(id) && !g_hamczbots && cvar_botquota)
	{
		set_task(0.1, "register_ham_czbots", id)
	}
	else
	{
	}
	
	// make player if match start
	if (!g_newround && !g_endround)
	{
		if (task_exists(id+TASK_RESPAWN)) remove_task(id+TASK_RESPAWN)
		set_task(g_respawn_wait, "player_respawn", id+TASK_RESPAWN)

	}
}
// Client leaving
public fw_ClientDisconnect(id)
{
	reset_value(id)
}
public client_command(id)
{
	new arg[13]
	if (read_argv(0, arg, 12) > 11)
	{
		return PLUGIN_CONTINUE 
	}
	
	// block cmd buy
	if (g_blockbuy)
	{
		new a = 0 
		do {
			if (equali(g_Aliases[a], arg) || equali(g_Aliases2[a], arg))
			{ 
				return PLUGIN_HANDLED 
			}
		} while(++a < MAXMENUPOS)
	}

	
	return PLUGIN_CONTINUE 
}
public Death()
{
	new killer = read_data(1) 
	new victim = read_data(2) 	
	//new headshot = read_data(3) 
	
	// reset value
	reset_value_death(victim)
	
	// off nvg and icon
	turn_off_nvg(victim)
	HideItemIcon(victim)
	
	// respawn victim
	g_respawning[victim] = 1
	if (task_exists(victim+TASK_RESPAWN)) remove_task(victim+TASK_RESPAWN)
	set_task(g_respawn_wait, "player_respawn", victim+TASK_RESPAWN)
	run_bartime(victim, fnFloatToNum(g_respawn_wait))

	// Update Score of Match
	new team_k = fm_cs_get_user_team(killer)
	new team_v = fm_cs_get_user_team(victim)
	if (team_k == FM_CS_TEAM_CT && team_v == FM_CS_TEAM_T) g_tickets_ct += 1
	else if (team_k == FM_CS_TEAM_T && team_v == FM_CS_TEAM_CT) g_tickets_te += 1
}

/*================================================================================
 [Main Forwards]
=================================================================================*/
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get classname
	new classname[32], objective[32], size = ArraySize(g_objective_ents)
	pev(entity, pev_classname, classname, charsmax(classname))
	
	// Check whether it needs to be removed
	for (new i = 0; i < size; i++)
	{
		ArrayGetString(g_objective_ents, i, objective, charsmax(objective))
		
		if (equal(classname, objective))
		{
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}
public fw_PlayerSpawn_Post(id)
{
	// Not alive or didn't join a team yet
	if (!is_user_alive(id) || !fm_cs_get_user_team(id))
		return;

	// Spawn at a random location?
	if (get_pcvar_num(cvar_randspawn)) do_random_spawn(id)

	// make player
	fm_cs_set_user_money(id, g_money_start)

	// protectio player
	set_protection(id)
	
	// make player
	if (task_exists(id+TASK_MAKEPLAYER)) remove_task(id+TASK_MAKEPLAYER)
	set_task(0.5, "make_player", id+TASK_MAKEPLAYER)
	
}
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	// Fix bug player not connect
	if (!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;

	// Remove Damage when Freetime
	if (g_newround || g_endround)
		return HAM_SUPERCEDE;
		
	// remove take damage when victim is protection
	if (g_protection[victim] || g_invincibility[victim])
		return HAM_SUPERCEDE;
	
	// Non-player damage or self damage
	if (victim == attacker)
		return HAM_IGNORED;
		
	// Damage Double
	if (g_damagedouble[attacker]) damage *= item_damagedouble_dmg

	// attacker is zombie
	if (g_zombie[attacker])
	{
		// Fix Bug zombie has weapons # knife
		if (get_user_weapon(attacker) != CSW_KNIFE) return HAM_SUPERCEDE;
		
		// take damage
		damage *= get_pcvar_float(cvar_zombie_attack_damage)
		SetHamParamFloat(4, damage)
		return HAM_IGNORED
	}
	
	// attacker is human
	else
	{
		// he xdamage
		if (damage_type & DMG_HEGRENADE)
		{
			new Float: hedmg = get_pcvar_float(cvar_damage_nade)+get_pcvar_float(cvar_damage_grenade)
			if (damage < hedmg) damage += hedmg
		}
		
		SetHamParamFloat(4, damage)
		return HAM_IGNORED
	}

	
	return HAM_IGNORED
}
public fw_TouchWeapon(weapon, id)
{
	// Not a player
	if (!is_user_connected(id))
		return HAM_IGNORED;
	
	// Dont pickup weapons if zombie or survivor (+PODBot MM fix)
	if (g_zombie[id])
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}
public fw_CmdStart(id, uc_handle, seed)
{			
	if (!is_user_alive(id)) return;

	// restore health
	restore_health(id)

	// inf grenade
	if (!g_zombie[id] && g_infgrenade[id])
	{
		give_weapon(id, CSW_HEGRENADE)
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}
	
	static buttons
	buttons = get_uc(uc_handle, UC_Buttons)	
	if (buttons & IN_USE) cmd_use_item(id)
	
	//client_print(id, print_chat, "L[%i] E[%i]", g_level[id], g_evolution[id])
}
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id) || g_freezetime) return;
	
	// Set Player MaxSpeed
	if (g_zombie[id])
	{
		new Float:maxspeed
		maxspeed = ArrayGetCell(zombie_speed, g_zombieclass[id])
		set_pev(id, pev_maxspeed, maxspeed)
	}
	
	// set fast run item
	if (g_fast[id]) set_pev(id, pev_maxspeed, item_fast_speed)

	// set fast run item
	if (g_stone[id])
	{
		set_pev(id, pev_maxspeed, 0.01)
		set_player_nextattack(id, 0.5)
	}
}
public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	// Fix bug player not connect
	if (!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;
		
	// New round starting or round end
	if (g_newround || g_endround)
		return HAM_SUPERCEDE;
		
	// self damage or victim is not zombie
	if (victim == attacker || !g_zombie[victim])
		return HAM_IGNORED;

	// remove knock back when victim is protection and invincibility or team
	if (g_protection[victim] || g_invincibility[victim] || (fm_cs_get_user_team(attacker) == fm_cs_get_user_team(victim)))
		return HAM_SUPERCEDE;
		
	// Knockback disabled, nothing else to do here
	if (!get_pcvar_num(cvar_knockback))
		return HAM_IGNORED;

	// Get distance between players
	static origin1[3], origin2[3]
	get_user_origin(victim, origin1)
	get_user_origin(attacker, origin2)
	
	// Get victim's velocity
	static Float:velocity[3]
	pev(victim, pev_velocity, velocity)

	// Use damage on knockback calculation
	if (get_pcvar_num(cvar_knockbackdamage))
		xs_vec_mul_scalar(direction, damage, direction)

	// Use weapon power on knockback calculation
	if (get_pcvar_num(cvar_knockbackpower))
	{
		new Float:weapon_knockback
		weapon_knockback = kb_weapon_power[get_user_weapon(attacker)]
		xs_vec_mul_scalar(direction, weapon_knockback, direction)
	}
		
	// Apply zombie class knockback multiplier
	if (g_zombie[victim])
	{
		new Float:classzb_knockback
		classzb_knockback = ArrayGetCell(zombie_knockback, g_zombieclass[victim])
		xs_vec_mul_scalar(direction, classzb_knockback, direction)
	}
		
	// Add up the new vector
	xs_vec_add(velocity, direction, direction)
	
	// Should knockback also affect vertical velocity?
	if (!get_pcvar_num(cvar_knockbackzvel))
		direction[2] = velocity[2]
	
	// Set the knockback'd victim's velocity
	set_pev(victim, pev_velocity, direction)
	
	//client_print(attacker, print_chat, "[%i][%i]", victim_kb, class_kb)
	return HAM_IGNORED;
}
// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	//client_print(id, print_chat, "[%s]", sample)
	
	// Block all those unneeeded hostage sounds
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	
	// Replace these next sounds for zombies only
	if (!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED;
	
	static sound[64], team
	team = fm_cs_get_user_team(id)
	
	// Zombie being hit
	if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't' ||
	sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a' && sample[10] == 'd')
	{
		if (team==FM_CS_TEAM_T) ArrayGetString(zombie_sound_hurt1, g_zombieclass[id], sound, charsmax(sound))
		else ArrayGetString(zombie_sound_hurt2, g_zombieclass[id], sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}
	
	// Zombie dies
	if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
	{
		if (team==FM_CS_TEAM_T) ArrayGetString(zombie_sound_death1, g_zombieclass[id], sound, charsmax(sound))
		else ArrayGetString(zombie_sound_death2, g_zombieclass[id], sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
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
		new sound[64]
		if (attack_type == 1) ArrayGetString(sound_zombie_hitwall, random(ArraySize(sound_zombie_hitwall)), sound, charsmax(sound))
		else if (attack_type == 2) ArrayGetString(sound_zombie_attack, random(ArraySize(sound_zombie_attack)), sound, charsmax(sound))
		else if (attack_type == 3) ArrayGetString(sound_zombie_swing, random(ArraySize(sound_zombie_swing)), sound, charsmax(sound))
		emit_sound(id, channel, sound, volume, attn, flags, pitch)
		return FMRES_SUPERCEDE;
	}

	
	return FMRES_IGNORED;
}
// Forward Set Model
public fw_SetModel(entity, const model[])
{
	// check valid ent
	if (!is_valid_ent(entity)) return FMRES_IGNORED

	// We don't care
	if (strlen(model) < 8) return FMRES_IGNORED;

// ######## Remove weapons
	new ent_classname[32]
	pev(entity, pev_classname, ent_classname, charsmax(ent_classname))
	if (equal(ent_classname, "weaponbox"))
	{
		set_pev(entity, pev_nextthink, get_gametime() + g_weapons_stay)
		return FMRES_IGNORED
	}

	
// ######## Zombie Bomb
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	// Get attacker
	static attacker
	attacker = pev(entity, pev_owner)
	
	// Get whether grenade's owner is a zombie
	if (g_zombie[attacker])
	{
		if (model[9] == 'h' && model[10] == 'e') // Zombie Bomb
		{
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_INFECTION)
			engfunc(EngFunc_SetModel, entity, zombiebom_model_w)
		
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
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
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_INFECTION:
		{
			zombiebom_explode(entity)
		}
		default: return HAM_IGNORED;
	}
	
	return HAM_SUPERCEDE;
}
public fw_primary_attack(ent)
{
	new id = pev(ent,pev_owner)
	pev(id,pev_punchangle,cl_pushangle[id])
	
	return HAM_IGNORED
}
public fw_primary_attack_post(ent)
{
	new id = pev(ent,pev_owner)
	if (g_shootingdown[id] || g_shootingup[id])
	{
		new Float:xrecoil, Float:push[3]
		if (g_shootingdown[id]) xrecoil = item_shootingdown_recoil
		else if (g_shootingup[id]) xrecoil = item_shootingup_recoil
		
		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)
		xs_vec_mul_scalar(push,xrecoil,push)
		xs_vec_add(push,cl_pushangle[id],push)
		set_pev(id,pev_punchangle,push)
	}
	
	return HAM_IGNORED
}

/*================================================================================
 [Main Public]
=================================================================================*/	

// team player attackment
public team_player_attackment(taskid)
{
	new id = ID_ATTACKMENT
	
	if (!is_user_connected(id)) return;
	
	new model_index
	if (fm_cs_get_user_team(id) == FM_CS_TEAM_T) model_index = idmodels_friend_te
	else if (fm_cs_get_user_team(id) == FM_CS_TEAM_CT) model_index = idmodels_friend_ct
	if (!model_index) return;
	
	for (new player = 1; player <= g_maxplayers; player++)
	{
		if (!is_user_connected(player)) continue;
		if (fm_cs_get_user_team(id) != fm_cs_get_user_team(player) || id == player) continue;
		create_player_attackment(id, player, model_index, 2, 0)
	}
}
create_player_attackment(id, player, model_index, life = 2000, origin_z = 0)
{
	message_begin(MSG_ONE, SVC_TEMPENTITY, {0, 0, 0}, id)
	write_byte(TE_PLAYERATTACHMENT)
	write_byte(player)
	write_coord(origin_z)
	write_short(model_index)
	write_short(life * 10 )
	message_end()
	
	//client_print(id, print_chat, "[%i]", player)
}


// Menu Weapons
public menu_wpn(id)
{
	if (!is_user_alive(id)) return;
	
	menu_wpn_item(id, 1)
}
public menu_wpn_item(id, type)
{
	if (g_zombie[id]) return PLUGIN_HANDLED
	
	// check size
	new size_id, size_name, fun_run[32]
	new size_pri = ArraySize(weapons_pri)
	new size_pri_name = ArraySize(weapons_pri_name)
	new size_sec = ArraySize(weapons_sec)
	new size_sec_name = ArraySize(weapons_sec_name)
	if (type == 1)
	{
		size_id = size_pri
		size_name = size_pri_name
		format(fun_run, 31, "menu_wpn_pri_handler")
	}
	else
	{
		size_id = size_sec
		size_name = size_sec_name
		format(fun_run, 31, "menu_wpn_sec_handler")
	}
	
	// create menu wpn
	new menuwpn_title[64]
	format(menuwpn_title, 63, "[Zombie United] %L:", LANG_PLAYER, "ZBU_MENU_WPN_TITLE")
	new mHandleID = menu_create(menuwpn_title, fun_run)
	new item_id[32], item_name[32]
	for (new i = 0; i < size_id && i < size_name; i++)
	{
		if (type == 1)
		{
			ArrayGetString(weapons_pri, i, item_id, charsmax(item_id))
			ArrayGetString(weapons_pri_name, i, item_name, charsmax(item_name))
		}
		else
		{
			ArrayGetString(weapons_sec, i, item_id, charsmax(item_id))
			ArrayGetString(weapons_sec_name, i, item_name, charsmax(item_name))
		}
		menu_additem(mHandleID, item_name, item_id, 0)
	}
	menu_display(id, mHandleID, 0)
	
	
	return PLUGIN_HANDLED
}
public menu_wpn_pri_handler(id, menu, item)
{
	// show menu wpn sec
	menu_wpn_item(id, 2)
	
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new idwpn[32], name[32], access
	menu_item_getinfo(menu, item, access, idwpn, 31, name, 31, access)

	new idweapon = GetIdWpn(idwpn)
	drop_weapons(id, 1)
	give_weapon(id, idweapon)
	
	menu_destroy(menu)
	
	return PLUGIN_HANDLED
}
public menu_wpn_sec_handler(id, menu, item)
{
	// give nade
	give_nade(id)

	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	new idwpn[32], name[32], access
	menu_item_getinfo(menu, item, access, idwpn, 31, name, 31, access)

	new idweapon = GetIdWpn(idwpn)
	drop_weapons(id, 2)
	give_weapon(id, idweapon)
	
	menu_destroy(menu)

	
	return PLUGIN_HANDLED
}
// Buy ammo
public buy_ammo(id)
{
	if (g_zombie[id]) return PLUGIN_HANDLED
	
	// Get user weapons
	new weapons[32], num, i, weapon
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		weapon = weapons[i]
		give_weapon(id, weapon)
		emit_sound(id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
	}
	
	return PLUGIN_HANDLED
}
// Current Weapon
public CurrentWeapon(id)
{
	if (!is_user_alive(id)) return;
	
	// check weapons
	CheckWeapon(id)
	
	// Uclip
	if (get_pcvar_num(cvar_weapons_uclip) && !g_zombie[id])
	{
		new WpnName[64]
		new idwpn = get_user_weapon(id)
		if ( idwpn && !(NOCLIP_WPN_BS & (1<<idwpn)) && get_weaponname(idwpn, WpnName, charsmax(WpnName)) )
		{
			new ent = get_weapon_ent(id, idwpn)
			new uclip = max(1, MAXCLIP[idwpn])
			if (ent) cs_set_weapon_ammo(ent, uclip)
			//client_print(0, print_chat, "[%i]", ent)
		}
	}
	
	return;
}
//get weapon ent
get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = fm_find_ent_by_owner(-1, wname, id)
	return weapon_ent
}
CheckWeapon(id)
{
	if (!is_user_alive(id)) return;
	
	// zombie weapons
	new current_weapon = get_user_weapon(id)
	if (g_zombie[id] && current_weapon)
	{
		// remove weapon # knife & he
		if (current_weapon != CSW_KNIFE && current_weapon != CSW_HEGRENADE)
		{
			drop_weapons(id, get_weapon_type(current_weapon), 1)
		}
		// set model zonbie bom
		else if (current_weapon == CSW_HEGRENADE)
		{
			new idclass, v_model[64]
			idclass = g_zombieclass[id]
			ArrayGetString(zombiebom_viewmodel, idclass, v_model, charsmax(v_model))
			set_pev(id, pev_viewmodel2, v_model)
			set_pev(id, pev_weaponmodel2, zombiebom_model_p)
		}
		// set model knife zombie
		else
		{
			new model_wpn[64], idclass
			idclass = g_zombieclass[id]
			ArrayGetString(zombie_wpnmodel, idclass, model_wpn, charsmax(model_wpn))

			set_pev(id, pev_viewmodel2, model_wpn)
			set_pev(id, pev_weaponmodel2, "")
		}

	}
}
public reset_wpnmodel(id)
{
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		set_pev(id, pev_viewmodel2, "models/v_knife.mdl")
		set_pev(id, pev_weaponmodel2, "models/p_knife.mdl")
	}
}
// menu class
public show_menu_class(taskid)
{
	new id = ID_MENUCLASS
	g_class[id] = 0
	
	// set freeze
	//set_freeze_user(id)
	
	// create menu wpn
	new menuwpn_title[64], item_human[64], item_zombie[64]
	format(menuwpn_title, charsmax(menuwpn_title), "[Zombie United] %L:", LANG_PLAYER, "ZBU_MENU_CLASS_TITLE")
	format(item_human, charsmax(item_human), "%L", LANG_PLAYER, "ZBU_MENU_CLASS_ITEM_HUMAN")
	format(item_zombie, charsmax(item_zombie), "%L", LANG_PLAYER, "ZBU_MENU_CLASS_ITEM_ZOMBIE")
	
	new mHandleID = menu_create(menuwpn_title, "select_class")	
	menu_additem(mHandleID, item_human, "1", 0)
	menu_additem(mHandleID, item_zombie, "2", 0)
	menu_display(id, mHandleID, 0)
}
public select_class(id, menu, item)
{
	// respawn player
	g_class[id] = 1
	player_spawn(id)
	
	// remove freeze
	//remove_freeze_user(id)
	
	// get value
	new class
	if (item == MENU_EXIT)
	{
		class = random_num(1, 2)
	}
	else 
	{
		new idclass[32], name[32], access
		menu_item_getinfo(menu, item, access, idclass, 31, name, 31, access)
		class = str_to_num(idclass)
		
	}
	menu_destroy(menu)
	
	// set class
	if (class==2)
	{
		make_zombie(id)
		show_menu_class_zombie(id)
	}
	else make_human(id)
	
	//client_print(id, print_chat, "item: %i - id: %s", name, idclass)
}
// menu class zombie
public show_menu_class_zombie(id)
{
	if (!g_zombie[id]) return PLUGIN_HANDLED
	
	// create menu wpn
	new menuwpn_title[64]
	format(menuwpn_title, 63, "[Zombie United] %L:", LANG_PLAYER, "ZBU_MENU_CLASSZOMBIE_TITLE")
	new mHandleID = menu_create(menuwpn_title, "select_class_zombie")
	new class_name[32], class_id[32]
	
	for (new i = 0; i < class_count; i++)
	{
		ArrayGetString(zombie_name, i, class_name, charsmax(class_name))
		formatex(class_id, charsmax(class_name), "%i", i)
		menu_additem(mHandleID, class_name, class_id, 0)
	}
	menu_display(id, mHandleID, 0)
	
	return PLUGIN_HANDLED
}
public select_class_zombie(id, menu, item)
{
	if (!g_zombie[id]) return PLUGIN_HANDLED
	
	if (item == MENU_EXIT)
	{
		menu_destroy(menu)
		give_zombiebom(id)
		return PLUGIN_HANDLED
	}
	new idclass[32], name[32], access
	menu_item_getinfo(menu, item, access, idclass, 31, name, 31, access)
	
	// set class zombie
	g_zombieclass[id] = str_to_num(idclass)
	make_zombie(id)
	give_zombiebom(id)
	
	menu_destroy(menu)
	//client_print(id, print_chat, "item: %i - id: %s", name, idclass)
	return PLUGIN_HANDLED
}

// Spawn a player [admin cmd]
public cmd_respawn_player(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED

	// Retrieve arguments
	static arg[32], player
	read_argv(1, arg, charsmax(arg))
	player = cmd_target(id, arg, CMDTARGET_ALLOW_SELF)
	
	// Remove Respawn when Freetime
	if (g_newround || g_endround || !is_user_connected(player)) return PLUGIN_HANDLED

	reset_value_death(player)
	player_respawn(player+TASK_RESPAWN)

	return PLUGIN_HANDLED
}
// Player Respawn
public player_respawn(taskid)
{
	new id = ID_RESPAWN
	
	// Remove Respawn when Freetime
	if (g_newround || g_endround || !is_user_connected(id)) return;
	
	// remove respawn
	g_respawning[id] = 0

	// make player
	if (is_user_bot(id)) player_spawn(id)
	else show_menu_class(id+TASK_MENUCLASS)

	// remove task
	if (task_exists(taskid)) remove_task(taskid)
}
public make_player(taskid)
{
	new id = ID_MAKEPLAYER

	if (is_user_bot(id))
	{
		new class = random_num(1, 2)
		if (class == 1) make_human(id)
		else if (class == 2) make_zombie(id)
	}
	else
	{
		if (!g_class[id]) show_menu_class(id+TASK_MENUCLASS)
	}
	
	if (task_exists(id+TASK_MAKEPLAYER)) remove_task(id+TASK_MAKEPLAYER)
}
// Remove Protection
player_spawn(id)
{
	// respawn player
	if (!is_user_alive(id)) respawn_player_manually(id)
}
// Set Protection
set_protection(id)
{
	g_protection[id] = 1
	new color[3]
	color[0] = ArrayGetCell(g_pro_color, 0)
	color[1] = ArrayGetCell(g_pro_color, 1)
	color[2] = ArrayGetCell(g_pro_color, 2)
	fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 10)
	if (task_exists(id+TASK_PROTECTION)) remove_task(id+TASK_PROTECTION)
	set_task(g_pro_time, "remove_protection", id+TASK_PROTECTION)
}
// Remove Protection
public remove_protection(taskid)
{
	new id = ID_PROTECTION
	
	// Remove when not connection
	if (!is_user_connected(id)) return;
	
	// respawn
	g_protection[id] = 0
	fm_set_rendering(id)
	
	// Fix bug
	CurrentWeapon(id)
}
// Show hud client
public show_hud_client()
{
	new message[64]
	
	// score match
	new ct[32], te[32], tickets[32]
	format(ct, 31, "%s", FixNumber(g_tickets_ct))
	format(te, 31, "%s", FixNumber(g_tickets_te))
	format(tickets, 31, "%s", FixNumber(g_tickets))
	format(message, 100, "%L", LANG_PLAYER, "ZBU_HUD_SCORE_MATCH", ct, tickets, te)
	set_hudmessage(255, 255, 255, HUD_SCORE_X, HUD_SCORE_Y, 0, 6.0, 1.1, 0.0, 0.0, -1)
	ShowSyncHudMsg(0, g_HudMsg_ScoreMatch, "%s", message)
	
	// health
	for (new id = 1; id <= g_maxplayers; id++)
	{
		if (!is_user_alive(id)) continue;
		
		if (g_zombie[id]) format(message, 63, "%L", LANG_PLAYER, "ZBU_HUD_ZOMBIE_HEALTH", get_user_health(id))
		else format(message, 63, "%L", LANG_PLAYER, "ZBU_HUD_HUMAN_HEALTH", get_user_health(id))
		set_hudmessage(0, 125, 0, HUD_HEALTH_X, HUD_HEALTH_Y, 0, 6.0, 2.0, 0.0, 0.0, -1)
		ShowSyncHudMsg(id, g_HudMsg_Health, "%s", message)
	}
}
// Other
public qq(id)
{

}


// Nightvision toggle
public cmd_nightvision(id)
{
	if (!is_user_alive(id) || g_blind[id]) return PLUGIN_HANDLED;

	if (!g_nvg[id])
	{
		g_nvg[id] = 1
		if (g_zombie[id])
		{
			remove_task(id+TASK_NVISION)
			set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
		}
		else  set_user_gnvision(id, g_nvg[id])
		PlaySound(id, sound_nvg[1])
	}
	else
	{
		g_nvg[id] = 0
		if (g_zombie[id])
		{
			remove_task(id+TASK_NVISION)
			set_user_screen_fade(id)
		}
		else  set_user_gnvision(id, g_nvg[id])
		PlaySound(id, sound_nvg[0])
	}
	
	return PLUGIN_HANDLED;
}
turn_off_nvg(id)
{
	if (!is_user_connected(id)) return;
	
	g_nvg[id] = 0
	remove_task(id+TASK_NVISION)
	set_user_screen_fade(id)
	set_user_gnvision(id, 0)
}


// Custom Night Vision
public set_user_nvision(taskid)
{
	new id = ID_NVISION
	
	if (!is_user_alive(id)) return;

	// Get player's origin
	static origin[3]
	get_user_origin(id, origin)
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(get_pcvar_num(cvar_nvg_zombie_size)) // radius
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[0])) // r
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[1])) // g
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[2])) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()

	// screen_fade
	set_user_screen_fade(id)
}
set_user_gnvision(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}
set_user_screen_fade(id)
{
	if (!is_user_connected(id)) return;
	
	new alpha
	if (g_nvg[id]) alpha = get_pcvar_num(cvar_nvg_zombie_alpha)
	else alpha = 0
	
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(FFADE_STAYOUT) // fade type
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[0])) // r
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[1])) // g
	write_byte(get_pcvar_num(cvar_nvg_zombie_color[2])) // b
	write_byte(alpha) // alpha
	message_end()
}

// ##################### Hud Item Supplybox #####################
public client_PostThink(id)
{
	if (!get_pcvar_num(cvar_icon) || !is_user_alive(id)) return PLUGIN_CONTINUE
	
	if ((g_icon_delay[id] + get_pcvar_float(cvar_icon_deplay)) > get_gametime()) return PLUGIN_CONTINUE
	g_icon_delay[id] = get_gametime()
	
	// Hud Icon Suppplybox
	if (supplybox_count)
	{
		new i = 1, box_ent
		while (i<=supplybox_count)
		{
			box_ent = supplybox_ent[i]
			create_icon_origin(id, box_ent, supplybox_icon_idspr)
			i++
		}
	}

	return PLUGIN_CONTINUE
}
stock create_icon_origin(id, ent, sprite)
{
	if (!pev_valid(ent)) return;
	
	new Float:fMyOrigin[3]
	entity_get_vector(id, EV_VEC_origin, fMyOrigin)
	
	new target = ent
	new Float:fTargetOrigin[3]
	entity_get_vector(target, EV_VEC_origin, fTargetOrigin)
	fTargetOrigin[2] += 60.0
	
	if (!is_in_viewcone(id, fTargetOrigin)) return;

	new Float:fMiddle[3], Float:fHitPoint[3]
	xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
	trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
							
	new Float:fWallOffset[3], Float:fDistanceToWall
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
	normalize(fMiddle, fWallOffset, fDistanceToWall)
	
	new Float:fSpriteOffset[3]
	xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
	new Float:fScale
	fScale = 0.01 * fDistanceToWall
	
	new scale = floatround(fScale)
	scale = max(scale, 1)
	scale = min(scale, get_pcvar_num(cvar_icon_size))
	scale = max(scale, 1)

	te_sprite(id, fSpriteOffset, sprite, scale, get_pcvar_num(cvar_icon_light))
	
	//client_print(id, print_chat, "W[%i]P[%i]S[%i]", floatround(fDistanceToWall), floatround(fDistanceToTarget), scale)
}
stock te_sprite(id, Float:origin[3], sprite, scale, brightness)
{	
	message_begin(MSG_ONE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	write_coord(floatround(origin[0]))
	write_coord(floatround(origin[1]))
	write_coord(floatround(origin[2]))
	write_short(sprite)
	write_byte(scale) 
	write_byte(brightness)
	message_end()
}
stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul)
{
	new Float:fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
}

// ##################### Use Item Supplybox #####################
public cmd_use_item(id)
{
	if (!is_user_alive(id) || g_nouseitem[id] || !g_item[id][0]) return;
	
	// use item
	new item = g_item[id][0]
	switch (item)
	{
		case 1: use_blind(id)
		case 2: use_curse(id)
		case 3: 
		{
			if (g_damagedouble[id]) return;
			else use_damagedouble(id)
		}
		case 4: use_enemyhpdown(id)
		case 5: 
		{
			if (g_fast[id]) return;
			else use_fast(id)
		}
		case 6: 
		{
			if (g_infgrenade[id]) return;
			else use_infgrenade(id)
		}
		case 7: 
		{
			if (g_invincibility[id]) return;
			else use_invincibility(id)
		}
		case 8: 
		{
			if (g_jumpup[id]) return;
			else use_jumpup(id)
		}
		//case 9: use_landmine(id)
		//case 10: use_nuclearhe(id)
		//case 11: use_reverse(id)
		case 12: use_shootingdown(id)
		case 13: 
		{
			if (g_shootingup[id]) return;
			else use_shootingup(id)
		}
		case 14: use_stone(id)
		case 15: use_teamhprecovery(id)
		default: return;
	}
	
	// remove item used
	give_item_supplybox(id, 0)
	
	// play sound
	PlayEmitSound(id, CHAN_VOICE, supplybox_sound_use)

	// after 1s then can use item next
	if (!is_user_bot(id))
	{
		g_nouseitem[id] = 1
		if (task_exists(id+TASK_CURSE)) remove_task(id+TASK_CURSE)
		set_task(1.0, "remove_curse", id+TASK_CURSE)
	}
}
// ##################### Item Supplybox #####################
// blind
use_blind(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) == fm_cs_get_user_team(i)) continue;
		
		g_blind[i] = 1
		message_begin(MSG_ONE, g_msgScreenFade, _, i)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(FFADE_STAYOUT) // fade type
		write_byte(255) // red
		write_byte(255) // green
		write_byte(255) // blue
		write_byte(255) // alpha
		message_end()
		
		if (task_exists(i+TASK_BLIND)) remove_task(i+TASK_BLIND)
		set_task(item_blind_time, "remove_blind", i+TASK_BLIND)
	}
}
public remove_blind(taskid)
{
	new id = ID_BLIND
	if (task_exists(taskid)) remove_task(taskid)
	
	if(!is_user_connected(id)) return;
	
	g_blind[id] = 0
	message_begin(MSG_ONE, g_msgScreenFade, _, id)
	write_short((1<<15)) // duration
	write_short(0) // hold time
	write_short(FFADE_IN) // fade type
	write_byte(255) // red
	write_byte(255) // green
	write_byte(255) // blue
	write_byte(255) // alpha
	message_end()
}
// curse
use_curse(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) == fm_cs_get_user_team(i)) continue;
		
		g_nouseitem[i] = 1
		if (task_exists(i+TASK_CURSE)) remove_task(i+TASK_CURSE)
		set_task(item_curse_time, "remove_curse", i+TASK_CURSE)
	}
}
public remove_curse(taskid)
{
	new id = ID_CURSE
	g_nouseitem[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
// damagedouble
use_damagedouble(id)
{
	if (g_damagedouble[id]) return;
	
	g_damagedouble[id] = 1
	if (task_exists(id+TASK_DAMAGEDOUBLE)) remove_task(id+TASK_DAMAGEDOUBLE)
	set_task(item_damagedouble_time, "remove_damagedouble", id+TASK_DAMAGEDOUBLE)	
}
public remove_damagedouble(taskid)
{
	new id = ID_DAMAGEDOUBLE
	g_damagedouble[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
// enemyhpdown
use_enemyhpdown(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) == fm_cs_get_user_team(i)) continue;
		
		new health = max(1, (get_user_health(i)/item_enemyhpdown_num))
		fm_set_user_health(i, health)
		
		// sound
		PlaySound(i, item_enemyhpdown_sound)
		
		// effect
		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade , _, i);
		write_short(1<<10);
		write_short(1<<10);
		write_short(0x0000);
		write_byte(255);//r
		write_byte(0);  //g
		write_byte(0);  //b
		write_byte(75);
		message_end();
	}
}
// fast run
use_fast(id)
{
	if (g_fast[id]) return;
	
	g_fast[id] = 1
	PlaySound(id, item_fast_sound_start)

	if (task_exists(id+TASK_FAST)) remove_task(id+TASK_FAST)
	set_task(item_fast_time, "remove_fast", id+TASK_FAST)
	
	// task fastrun sound heartbeat
	if (task_exists(id+TASK_FAST_HEARTBEAT)) remove_task(id+TASK_FAST_HEARTBEAT)
	set_task(2.0, "fast_hear_beat", id+TASK_FAST_HEARTBEAT, _, _, "b", fnFloatToNum(item_fast_time))
}
public remove_fast(taskid)
{
	new id = ID_FAST
	g_fast[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
public fast_hear_beat(taskid)
{
	new id = ID_FAST_HEARTBEAT
	if (g_fast[id]) PlaySound(id, item_fast_sound_heartbeat)
	else if (task_exists(taskid)) remove_task(taskid)
}
// infgrenade
use_infgrenade(id)
{
	if (g_infgrenade[id]) return;
	
	g_infgrenade[id] = 1
	
	give_weapon(id, CSW_HEGRENADE)
	cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	
	if (task_exists(id+TASK_INFGRENADE)) remove_task(id+TASK_INFGRENADE)
	set_task(item_infgrenade_time, "remove_infgrenade", id+TASK_INFGRENADE)
}
public remove_infgrenade(taskid)
{
	new id = ID_INFGRENADE
	
	g_infgrenade[id] = 0

	if (is_user_alive(id))
	{
		give_weapon(id, CSW_HEGRENADE)
		cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
	}

	if (task_exists(taskid)) remove_task(taskid)
}
// invincibility
use_invincibility(id)
{
	if (g_invincibility[id]) return;
	
	g_invincibility[id] = 1
	if (task_exists(id+TASK_INVINC)) remove_task(id+TASK_INVINC)
	set_task(item_invincibility_time, "remove_invincibility", id+TASK_INVINC)	
}
public remove_invincibility(taskid)
{
	new id = ID_INVINC
	g_invincibility[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
// jumpup 
use_jumpup(id)
{
	if (g_jumpup[id]) return;
	
	g_jumpup[id] = 1
	
	pev(id, pev_gravity, g_current_gravity[id])
	set_pev(id, pev_gravity, item_jumpup_gravity)

	if (task_exists(id+TASK_JUMPUP)) remove_task(id+TASK_JUMPUP)
	set_task(item_jumpup_time, "remove_jumpup", id+TASK_JUMPUP)
}
public remove_jumpup(taskid)
{
	new id = ID_JUMPUP
	g_jumpup[id] = 0
	set_pev(id, pev_gravity, g_current_gravity[id])
	if (task_exists(taskid)) remove_task(taskid)
}
// shootingdown
use_shootingdown(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) == fm_cs_get_user_team(i)) continue;

		g_shootingdown[i] = 1
		
		if (task_exists(i+TASK_SHOOTINGDOWN)) remove_task(i+TASK_SHOOTINGDOWN)
		set_task(item_shootingdown_time, "remove_shootingdown", i+TASK_SHOOTINGDOWN)
	}
}
public remove_shootingdown(taskid)
{
	new id = ID_SHOOTINGDOWN
	g_shootingdown[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
// shootingup
use_shootingup(id)
{
	if (g_shootingup[id]) return;
	
	g_shootingup[id] = 1
	if (task_exists(id+TASK_SHOOTINGUP)) remove_task(id+TASK_SHOOTINGUP)
	set_task(item_shootingup_time, "remove_shootingup", id+TASK_SHOOTINGUP)	
}
public remove_shootingup(taskid)
{
	new id = ID_SHOOTINGUP
	g_shootingup[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
// teamhprecovery
use_teamhprecovery(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) != fm_cs_get_user_team(i)) continue;
		
		new health = min(native_get_user_start_health(i), (get_user_health(i)*item_teamhprecovery_num))
		fm_set_user_health(i, health)
		
		// sound
		PlaySound(i, item_teamhprecovery_sound)
		
		// effect
		message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade , _, i);
		write_short(1<<10);
		write_short(1<<10);
		write_short(0x0000);
		write_byte(255);//r
		write_byte(0);  //g
		write_byte(0);  //b
		write_byte(75);
		message_end();
	}
}
// stone
use_stone(id)
{
	for (new i = 1; i <= g_maxplayers; i++)
	{
		if (!is_user_alive(i)) continue;
		if (fm_cs_get_user_team(id) == fm_cs_get_user_team(i)) continue;
		
		g_stone[i] = 1
		if (task_exists(i+TASK_STONE)) remove_task(i+TASK_STONE)
		set_task(item_stone_time, "remove_stone", i+TASK_STONE)
	}
}
public remove_stone(taskid)
{
	new id = ID_STONE
	g_stone[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}

public fw_gamedesc()
{
	forward_return(FMV_STRING, PLUGIN)
	
	return FMRES_SUPERCEDE
}

// ##################### SupplyBox #####################
// SupplyBox Pickup
public fw_Touch(ent, id)
{
	if (!pev_valid(ent) || !is_user_alive(id) || g_supplybox_wait[id]) return FMRES_IGNORED
	
	new classname[32]
	entity_get_string(ent,EV_SZ_classname,classname,31)
	//client_print(id, print_chat, "[%s][%i]", classname, ent)
	
	if (equal(classname, SUPPLYBOX_CLASSNAME))
	{
		// check has
		if (g_item[id][0] && g_item[id][1]) return FMRES_IGNORED
		
		// get item from supply pickup
		new item_id
		item_id = get_item_supplybox(id)
		
		// give item for player
		give_item_supplybox(id, item_id)

		// text msg
		new message[200]
		format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_NOTICE_SUPPLYBOX_PICKUP", get_lang_item(item_id))
		SendCenterText(id, message)
		color_saytext(0, "^x04[Zombie United]^x01 Bam (E) de su dung Item !!!")
		
		// play sound
		PlayEmitSound(id, CHAN_VOICE, supplybox_sound_pickup)

		// remove ent in supplybox_ent
		new num_box = entity_get_int(ent, EV_INT_iuser2)
		supplybox_ent[num_box] = 0
		remove_entity(ent)
		
		// bot use item
		if (is_user_bot(id)) cmd_use_item(id)
		
		// waiting
		g_supplybox_wait[id] = 1
		if (task_exists(id+TASK_SUPPLYBOX_WAIT)) remove_task(id+TASK_SUPPLYBOX_WAIT)
		set_task(2.0, "remove_supplybox_wait", id+TASK_SUPPLYBOX_WAIT)
	}
	
	return FMRES_IGNORED
}
public remove_supplybox_wait(taskid)
{
	new id = ID_SUPPLYBOX_WAIT
	g_supplybox_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
get_lang_item(item)
{
	new message[200], lang_item[64], item_name[64]
	format(item_name, charsmax(item_name), "%s", GetItemIconName(item, 3))
	format(lang_item, charsmax(lang_item), "ZBU_ITEM_%s", item_name)
	format(message, charsmax(message), "%L", LANG_PLAYER,  lang_item)
	
	return message;
}
get_item_supplybox(id)
{
	new item_name[64], item
	if (g_zombie[id]) ArrayGetString(zombie_item, random(ArraySize(zombie_item)), item_name, charsmax(item_name))
	else ArrayGetString(human_item, random(ArraySize(human_item)), item_name, charsmax(item_name))
	item = get_id_item(item_name)
	//client_print(id, print_chat, "[%i][%s]", item, item_name)
	
	return item;	
}
get_id_item(item_name[])
{
	for (new i = 1; i <= TOTAL_ITEMS; i++)
	{
		if (equal(item_name, GetItemIconName(i, 0))) return i;
	}
	
	return 0;
}
give_item_supplybox(id, item)
{
	// update item when use
	if (!item)
	{
		g_item[id][0] = g_item[id][1]
		g_item[id][1] = 0
	}
	// give spweapons
	else if (item==ITEM_SPWEAPON) give_spweapon_for_player(id)
	// add item
	else
	{
		if (!g_item[id][0])
		{
			g_item[id][0] = item
			g_item[id][1] = 0
		}
		else if (!g_item[id][1]) g_item[id][1] = item
		else return;
	}
	
	// show icon
	show_icon_item(id)
}
give_spweapon_for_player(id)
{
	new weapon_name[64]
	ArrayGetString(spweapon_item, random(ArraySize(spweapon_item)), weapon_name, charsmax(weapon_name))
	fm_give_item(id, weapon_name)
	//client_print(id, print_chat, "[%s]", weapon_name)
}
show_icon_item(id)
{
	if (!is_user_alive(id)) return;
	
	HideItemIcon(id)
	ShowItemIcon(id, g_item[id][1], 2)
	ShowItemIcon(id, g_item[id][0], 1)
}
// Create SupplyBox
public create_supply_box()
{
	// check max supplybox
	if (supplybox_count>=supplybox_max || g_newround || g_endround) return;

	// continue create supply
	if (task_exists(TASK_SUPPLYBOX)) remove_task(TASK_SUPPLYBOX)
	set_task(supplybox_time, "create_supply_box", TASK_SUPPLYBOX)
	
	if (get_total_supplybox()>=supplybox_total_in_time) return;
	
	// create model
	g_supplybox_num = 0
	create_supply_box_model()
	
	// show hudtext
	new message[100]
	format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_NOTICE_SUPPLYBOX")
	SendCenterText(0, message)
	
	// show text help
	if (task_exists(TASK_SUPPLYBOX_HELP)) remove_task(TASK_SUPPLYBOX_HELP)
	set_task(2.0, "supply_box_help", TASK_SUPPLYBOX_HELP)

	// create multi supply box
	if (task_exists(TASK_SUPPLYBOX_MODEL)) remove_task(TASK_SUPPLYBOX_MODEL)
	set_task(0.5, "create_supply_box_model", TASK_SUPPLYBOX_MODEL, _, _, "b")
}
get_total_supplybox()
{
	new total
	for (new i=1; i<=supplybox_count; i++)
	{
		if (supplybox_ent[i]) total += 1
	}
	return total;
}
public create_supply_box_model()
{
	// check max supplybox
	if (supplybox_count>=supplybox_max || get_total_supplybox()>=supplybox_total_in_time || g_newround || g_endround)
	{
		remove_task(TASK_SUPPLYBOX_MODEL)
		return;
	}
	
	// supply box count
	supplybox_count += 1
	g_supplybox_num += 1

	// get random model supplybox
	static model_w[64]
	ArrayGetString(supplybox_models, random(ArraySize(supplybox_models)), model_w, charsmax(model_w))

	// create supply box
	new ent_box = create_entity("info_target")
	entity_set_string(ent_box, EV_SZ_classname, SUPPLYBOX_CLASSNAME)
	entity_set_model(ent_box,model_w)	
	entity_set_size(ent_box,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
	entity_set_int(ent_box,EV_INT_solid,1)
	entity_set_int(ent_box,EV_INT_movetype,6)
	//entity_set_int(ent_box, EV_INT_iuser1, item)
	entity_set_int(ent_box, EV_INT_iuser2, supplybox_count)
	//entity_set_vector(ent_box,EV_VEC_origin,origin)
	
	// set origin
	if (g_spawnCount_box) do_random_spawn_box(ent_box)
	else if (g_spawnCount) do_random_spawn(ent_box)
	
	// give ent SupplyBox
	supplybox_ent[supplybox_count] = ent_box

	// play sound
	PlayEmitSound(ent_box, CHAN_VOICE, supplybox_sound_drop)
	
	// remove task
	if (g_supplybox_num==supplybox_num) remove_task(TASK_SUPPLYBOX_MODEL)
}
// SupplyBox Help
public supply_box_help()
{
	new message[100]
	format(message, charsmax(message), "%L", LANG_PLAYER, "ZBU_NOTICE_SUPPLYBOX_HELP")
	SendCenterText(0, message)
}
// Remove SupplyBox
remove_supplybox()
{
	remove_ent_by_class(SUPPLYBOX_CLASSNAME)
	supplybox_ent = supplybox_ent_reset
}

// ##################### RADAR SCAN #####################
public radar_scan()
{	
	for (new id=1; id<=g_maxplayers; id++)
	{
		if (!is_user_alive(id)) continue;
		
		// scan supply box
		if (!supplybox_count) continue;
		
		new i = 1, next_ent
		while(i<=supplybox_count)
		{
			next_ent = supplybox_ent[i]
			if (next_ent)
			{
				static Float:origin[3]
				pev(next_ent, pev_origin, origin)
				
				message_begin(MSG_ONE_UNRELIABLE, g_msgHostagePos, {0,0,0}, id)
				write_byte(id)
				write_byte(i)		
				write_coord(fnFloatToNum(origin[0]))
				write_coord(fnFloatToNum(origin[1]))
				write_coord(fnFloatToNum(origin[2]))
				message_end()
			
				message_begin(MSG_ONE_UNRELIABLE, g_msgHostageK, {0,0,0}, id)
				write_byte(i)
				message_end()
				//client_print(id, print_chat, "[%i] [%i] [%i] [%i]", next_ent, origin[0], origin[1], origin[2])
			}

			i++
		}
		//client_print(id, print_chat, "[%i][%i]", supplybox_count, i)
	}
}
// Register Ham Forwards for CZ bots
public register_ham_czbots(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (g_hamczbots || !is_user_connected(id) || !get_pcvar_num(cvar_botquota))
		return;
		
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	
	// Ham forwards for CZ bots succesfully registered
	g_hamczbots = true
	
	// If the bot has already spawned, call the forward manually for him
	if (is_user_alive(id)) fw_PlayerSpawn_Post(id)
}


/*================================================================================
 [Main Function]
=================================================================================*/
// Make Human Function
make_human(id)
{
	if (!is_user_alive(id)) return;
	
	// set value
	g_zombie[id] = 0
	fm_set_user_health(id, g_human_health)
	fm_set_user_armor(id, g_human_ammo)
	
	// set model
	set_model_for_player(id)
	
	
	/* give wpn for bot
	if (is_user_bot(id))
	{
		fm_strip_user_weapons(id)
		fm_give_item(id, "weapon_knife")
		
		new wpn_pri[32], wpn_sec[32]
		ArrayGetString(weapons_pri, random(ArraySize(weapons_pri)), wpn_pri, charsmax(wpn_pri))
		ArrayGetString(weapons_sec, random(ArraySize(weapons_sec)), wpn_sec, charsmax(wpn_sec))
		new idwpn_pri = GetIdWpn(wpn_pri)
		new idwpn_sec = GetIdWpn(wpn_sec)
		give_weapon(id, idwpn_pri)
		give_weapon(id, idwpn_sec)
	}
	// show menu wpn for player
	else */menu_wpn(id)
	
	// give nade
	give_nade(id)
	
	// off nvg
	turn_off_nvg(id)
}
// Make Zombie Function
make_zombie(id)
{
	if (!is_user_alive(id)) return;

	// set value
	g_zombie[id] = 1

	// Strip off from weapons
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")

	// random class for bot
	if (is_user_bot(id))
	{
		g_zombieclass[id] = random(class_count)
		give_zombiebom(id)
	}
	
	// Remove survivor's aura (bugfix)
	set_pev(id, pev_effects, pev(id, pev_effects) &~ EF_BRIGHTLIGHT)
		
	// Remove spawn protection (bugfix)
	set_pev(id, pev_effects, pev(id, pev_effects) &~ EF_NODRAW)

	// Remove any zoom (bugfix)
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
		
	// Remove armor
	set_pev(id, pev_armorvalue, 0.0)

	// give info zombie
	new Float:gravity, Float:speed, health
	gravity = ArrayGetCell(zombie_gravity, g_zombieclass[id])
	speed = ArrayGetCell(zombie_speed, g_zombieclass[id])
	health = ArrayGetCell(zombie_health, g_zombieclass[id])
	set_pev(id, pev_gravity, gravity)
	set_pev(id, pev_maxspeed, speed)
	fm_set_user_health(id, health)
	fm_set_user_armor(id, g_zombie_armor)
	
	// set model
	set_model_for_player(id)
	
	// check model
	CurrentWeapon(id)
	color_saytext(id, "^x04[Zombie United]^x01 Bam (G) de su dung tuyet chieu !!!")
	
	// turn off flashlight nvg
	turn_off_flashlight(id)
	turn_off_nvg(id)
	if (get_pcvar_num(cvar_nvg_zombie_give)) cmd_nightvision(id)
}
set_model_for_player(id)
{	
	if (!is_user_connected(id)) return;
	
	if (g_zombie[id])
	{
		// set model player
		new model_view[64], model_index, idclass, team
		idclass = g_zombieclass[id]
		team = fm_cs_get_user_team(id)
		if (team==FM_CS_TEAM_T)
		{
			ArrayGetString(zombie_viewmodel_host, idclass, model_view, charsmax(model_view))
			model_index = ArrayGetCell(zombie_modelindex_host, idclass)
		}
		else if (team==FM_CS_TEAM_CT)
		{
			ArrayGetString(zombie_viewmodel_origin, idclass, model_view, charsmax(model_view))
			model_index = ArrayGetCell(zombie_modelindex_origin, idclass)
		}
		cs_set_user_model(id, model_view)
		if (get_zombie_set_modelindex(id)) fm_cs_set_user_model_index(id, model_index)
		else fm_reset_user_model_index(id)
		
		//client_print(id, print_chat, "[%s][%s]", model_view, model_wpn)
	}
	else
	{
		fm_reset_user_model(id)
	}
}
get_zombie_set_modelindex(id)
{
	if (!g_zombie[id]) return 0;
	
	new team = fm_cs_get_user_team(id)
	new modelindex = ArrayGetCell(zombie_modelindex, g_zombieclass[id])
	if ( (modelindex==3) || (modelindex==2 && team==FM_CS_TEAM_CT) || (modelindex==1 && team==FM_CS_TEAM_T) ) return 1;
	else return 0;
	
	return 0;
}
// reset value of player
reset_value(id)
{
	reset_value_death(id)
	g_zombie[id] = 0
	g_zombieclass[id] = 0

}
reset_value_death(id)
{
	if (task_exists(id+TASK_RESPAWN)) remove_task(id+TASK_RESPAWN)
	if (task_exists(id+TASK_MENUCLASS)) remove_task(id+TASK_MENUCLASS)
	if (task_exists(id+TASK_PROTECTION)) remove_task(id+TASK_PROTECTION)
	if (task_exists(id+TASK_NVISION)) remove_task(id+TASK_NVISION)
	if (task_exists(id+TASK_BLIND)) remove_task(id+TASK_BLIND)
	if (task_exists(id+TASK_CURSE)) remove_task(id+TASK_CURSE)
	if (task_exists(id+TASK_DAMAGEDOUBLE)) remove_task(id+TASK_DAMAGEDOUBLE)
	if (task_exists(id+TASK_FAST)) remove_task(id+TASK_FAST)
	if (task_exists(id+TASK_FAST_HEARTBEAT)) remove_task(id+TASK_FAST_HEARTBEAT)
	if (task_exists(id+TASK_INFGRENADE)) remove_task(id+TASK_INFGRENADE)
	if (task_exists(id+TASK_INVINC)) remove_task(id+TASK_INVINC)
	if (task_exists(id+TASK_JUMPUP)) remove_task(id+TASK_JUMPUP)
	if (task_exists(id+TASK_SHOOTINGDOWN)) remove_task(id+TASK_SHOOTINGDOWN)
	if (task_exists(id+TASK_SHOOTINGUP)) remove_task(id+TASK_SHOOTINGUP)

	g_class[id] = 0
	g_restore_health[id] = 0
	g_respawning[id] = 0
	g_protection[id] = 0
	g_nvg[id] = 0
	g_item[id][0] = 0
	g_item[id][1] = 0
	g_blind[id] = 0
	g_nouseitem[id] = 0
	g_damagedouble[id] = 0
	g_fast[id] = 0
	g_infgrenade[id] = 0
	g_invincibility[id] = 0
	g_jumpup[id] = 0
	g_shootingdown[id] = 0
	g_shootingup[id] = 0
	g_stone[id] = 0
	
	if (is_user_connected(id)) fm_set_rendering(id)
}
// Restore health for zombie
restore_health(id)
{
	if (!g_zombie[id] || g_newround || g_endround) return;
	
	static Float:velocity[3]
	pev(id, pev_velocity, velocity)
	
	if (!velocity[0] && !velocity[1] && !velocity[2])
	{
		if (!g_restore_health[id]) g_restore_health[id] = get_systime()
	}
	else g_restore_health[id] = 0
	
	if (g_restore_health[id])
	{
		new rh_time = get_systime() - g_restore_health[id]
		new health = ArrayGetCell(zombie_health, g_zombieclass[id])
		if (rh_time == restore_health_time+1 && get_user_health(id) < health)
		{
			// get health add
			new health_add
			health_add = restore_health_dmg
			
			// get health new
			new health_new = get_user_health(id)+health_add
			health_new = min(health_new, health)
			
			// set health
			fm_set_user_health(id, health_new)
			g_restore_health[id] += 1
			
			// effect
			SendMsgDamage(id)
			EffectRestoreHealth(id)
			
			// play sound heal
			new sound_heal[64]
			ArrayGetString(zombie_sound_heal, g_zombieclass[id], sound_heal, charsmax(sound_heal))
			PlaySound(id, sound_heal)
		}
	}
}
// ZombieBom Grenade Explosion
zombiebom_explode(ent)
{
	// Round ended (bugfix)
	if (g_newround || g_endround) return;
	
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Make the explosion
	EffectZombieBomExp(ent)
	
	// explode sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, zombiebom_sound_exp, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get attacker
	//static attacker
	//attacker = pev(ent, pev_owner)
	
	// Collisions
	static victim
	victim = -1
	
	new Float:fOrigin[3],Float:fDistance,Float:fDamage
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, zombiebom_radius)) != 0)
	{
		// Only effect alive non-spawnprotected humans
		if (!is_user_alive(victim))
			continue;
		
		// get value
		pev(victim, pev_origin, fOrigin)
		fDistance = get_distance_f(fOrigin, originF)
		fDamage = zombiebom_power - floatmul(zombiebom_power, floatdiv(fDistance, zombiebom_radius))//get the damage value
		fDamage *= estimate_take_hurt(originF, victim, 0)//adjust
		if ( fDamage < 0 )
			continue

		// create effect
		manage_effect_action(victim, fOrigin, originF, fDistance, fDamage * 8.0)
		continue;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
	
	//client_print(0, print_chat, "AT[%i]", attacker)
}
EffectZombieBomExp(id)
{
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(zombiebom_idsprites_exp); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
}
manage_effect_action(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	//return 1
	new Float:Velocity[3]
	pev(iEnt, pev_velocity, Velocity)
	
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime) + Velocity[0]*0.5
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime) + Velocity[1]*0.5
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime) + Velocity[2]*0.5
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}

// Give Nade for player
give_nade(id)
{
	// Get user weapons
	new weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		new idnade_str[32], idnade_num
		for (new i = 0; i < ArraySize(weapons_nade); i++)
		{
			ArrayGetString(weapons_nade, i, idnade_str, charsmax(idnade_str))
			idnade_num = GetIdWpn(idnade_str)
			if (weaponid != idnade_num) give_weapon(id, idnade_num)
		}
	}
}
give_zombiebom(id)
{
	if (!g_zombie[id]) return;
	
	// Get user weapons
	new weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		weaponid = weapons[i]
		if (weaponid != CSW_HEGRENADE) fm_give_item(id, WEAPONENTNAMES[CSW_HEGRENADE])
	}
}
// StatusIcon
ShowItemIcon(id, idspr, type)
{	
	StatusIcon(id, GetItemIconName(idspr, type), 1)
}
HideItemIcon(id)
{	
	for (new i = 0; i <= TOTAL_ITEMS; i++)
	{
		StatusIcon(id, GetItemIconName(i, 1), 0)
		StatusIcon(id, GetItemIconName(i, 2), 0)
	}

}
StatusIcon(id, sprite_name[], run)
{	
	message_begin(MSG_ONE, g_msgStatusIcon, {0,0,0}, id);
	write_byte(run); // status (0=hide, 1=show, 2=flash)
	write_string(sprite_name); // sprite name
	message_end();

}
GetItemIconName(item, type)
{
	new item_name[64]
	switch (item)
	{
		case 1: item_name = "blind"
		case 2: item_name = "curse"
		case 3: item_name = "damagedouble"
		case 4: item_name = "enemyhpdown"
		case 5: item_name = "fast"
		case 6: item_name = "infgrenade"
		case 7: item_name = "invincibility"
		case 8: item_name = "jumpup"
		case 9: item_name = "landmine"
		case 10: item_name = "nuclearhe"
		case 11: item_name = "reverse"
		case 12: item_name = "shootingdown"
		case 13: item_name = "shootingup"
		case 14: item_name = "stone"
		case 15: item_name = "teamhprecovery"
		case 16: item_name = "spweapon"
		default: item_name = "no"
	}
	
	if (type==1) format(item_name, charsmax(item_name), "zbu_%s", item_name)
	else if (type==2) format(item_name, charsmax(item_name), "zbu_s_%s", item_name)
	else if (type==3) strtoupper(item_name)
	
	return item_name
}

// Respawn Player Manually (called after respawn checks are done)
respawn_player_manually(id)
{
	if (is_user_connected(id))
	{
		ExecuteHamB(Ham_CS_RoundRespawn, id)
	}	
}
// bartime
run_bartime(id, wait_time)
{
	message_begin(MSG_ONE, g_msgBarTime, _, id)
	write_short(wait_time)
	message_end()
}
// Plays a sound on clients
PlaySound(id, const sound[])
{
	if (equal(sound[strlen(sound)-4], ".mp3"))
		client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else
		client_cmd(id, "spk ^"%s^"", sound)
}
// Plays Emit sound
PlayEmitSound(id, type, const sound[])
{
	emit_sound(id, type, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
// Effect
EffectRestoreHealth(id)
{
	if (!is_user_alive(id)) return;
	
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(restore_health_idspr); // sprites
	write_byte(15); // scale in 0.1's
	write_byte(12); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade , _, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(255);//r
	write_byte(0);  //g
	write_byte(0);  //b
	write_byte(75);
	message_end();
}
// Place user at a random spawn
do_random_spawn(id, regularspawns = 0)
{
	static hull, sp_index, i
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// Use regular spawns?
	if (!regularspawns)
	{
		// No spawns?
		if (!g_spawnCount)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
	else
	{
		// No spawns?
		if (!g_spawnCount2)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount2 - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount2) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns2[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns2[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
}
do_random_spawn_box(id, regularspawns = 0)
{
	static hull, sp_index, i
	
	// Get whether the player is crouching
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	// Use regular spawns?
	if (!regularspawns)
	{
		// No spawns?
		if (!g_spawnCount_box)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount_box - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount_box) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns_box[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns_box[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
	else
	{
		// No spawns?
		if (!g_spawnCount2_box)
			return;
		
		// Choose random spawn to start looping at
		sp_index = random_num(0, g_spawnCount2_box - 1)
		
		// Try to find a clear spawn
		for (i = sp_index + 1; /*no condition*/; i++)
		{
			// Start over when we reach the end
			if (i >= g_spawnCount2_box) i = 0
			
			// Free spawn space?
			if (is_hull_vacant(g_spawns2[i], hull))
			{
				// Engfunc_SetOrigin is used so ent's mins and maxs get updated instantly
				engfunc(EngFunc_SetOrigin, id, g_spawns2[i])
				break;
			}
			
			// Loop completed, no free space found
			if (i == sp_index) break;
		}
	}
}

fm_reset_user_model(id)
{
	cs_set_user_model(id, g_human_model[random_num(0, charsmax(g_human_model))])
}

GetIdWpn(wpn[])
{
	new idwpn
	if (equali(wpn,"CSW_P228")) idwpn = 1
	else if (equali(wpn,"CSW_SCOUT")) idwpn = 3
	else if (equali(wpn,"CSW_HEGRENADE")) idwpn = 4
	else if (equali(wpn,"CSW_XM1014")) idwpn = 5
	else if (equali(wpn,"CSW_C4")) idwpn = 6
	else if (equali(wpn,"CSW_MAC10")) idwpn = 7
	else if (equali(wpn,"CSW_AUG")) idwpn = 8
	else if (equali(wpn,"CSW_SMOKEGRENADE")) idwpn = 9
	else if (equali(wpn,"CSW_ELITE")) idwpn = 10
	else if (equali(wpn,"CSW_FIVESEVEN")) idwpn = 11
	else if (equali(wpn,"CSW_UMP45")) idwpn = 12
	else if (equali(wpn,"CSW_SG550")) idwpn = 13
	else if (equali(wpn,"CSW_GALI")) idwpn = 14
	else if (equali(wpn,"CSW_GALIL")) idwpn = 14
	else if (equali(wpn,"CSW_FAMAS")) idwpn = 15
	else if (equali(wpn,"CSW_USP")) idwpn = 16
	else if (equali(wpn,"CSW_GLOCK18")) idwpn = 17
	else if (equali(wpn,"CSW_AWP")) idwpn = 18
	else if (equali(wpn,"CSW_MP5NAVY")) idwpn = 19
	else if (equali(wpn,"CSW_M249")) idwpn = 20
	else if (equali(wpn,"CSW_M3")) idwpn = 21
	else if (equali(wpn,"CSW_M4A1")) idwpn = 22
	else if (equali(wpn,"CSW_TMP")) idwpn = 23
	else if (equali(wpn,"CSW_G3SG1")) idwpn = 24
	else if (equali(wpn,"CSW_FLASHBANG")) idwpn = 25
	else if (equali(wpn,"CSW_DEAGLE")) idwpn = 26
	else if (equali(wpn,"CSW_SG552")) idwpn = 27
	else if (equali(wpn,"CSW_AK47")) idwpn = 28
	else if (equali(wpn,"CSW_KNIFE")) idwpn = 29
	else if (equali(wpn,"CSW_P90")) idwpn = 30
	else if (equali(wpn,"CSW_VEST")) idwpn = 31
	else if (equali(wpn,"CSW_VESTHELM")) idwpn = 32
	
	return idwpn
}
give_weapon(id, idwpn)
{
	if (g_zombie[id]) return;
	
	fm_give_item(id, WEAPONENTNAMES[idwpn])
	new ammo = MAXBPAMMO[idwpn]
	if (ammo > 2) cs_set_user_bpammo(id, idwpn, ammo)
}
SendMsgDamage(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
}
get_weapon_type(weaponid)
{
	new type_wpn = 0
	if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) type_wpn = 1
	else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) type_wpn = 2
	else if ((1<<weaponid) & NADE_WEAPONS_BIT_SUM) type_wpn = 4
	return type_wpn
}
FixNumber(number)
{
	new numstr[32]
	if (number<0) format(numstr, 31, "0")
	else if (number<10) format(numstr, 31, "0%i", number)
	else format(numstr, 31, "%i", number)
	
	return numstr
}
fnFloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}
// Turn Off Flashlight and Restore Batteries
turn_off_flashlight(id)
{
	// Restore batteries for the next use
	fm_cs_set_user_batteries(id, 100)
	
	// Check if flashlight is on
	if (pev(id, pev_effects) & EF_DIMLIGHT)
	{
		// Turn it off
		set_pev(id, pev_impulse, IMPULSE_FLASHLIGHT)
	}
	else
	{
		// Clear any stored flashlight impulse (bugfix)
		set_pev(id, pev_impulse, 0)
	}
	
	// Update flashlight HUD
	message_begin(MSG_ONE, get_user_msgid("Flashlight"), _, id)
	write_byte(0) // toggle
	write_byte(100) // battery
	message_end()
}
color_saytext(player, const message[], any:...)
{
	new text[301]
	format(text, 300, "%s", message)

	new dest
	if (player) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, get_user_msgid("SayText"), {0,0,0}, player)
	write_byte(1)
	write_string(check_text(text))
	return message_end()
}
check_text(text1[])
{
	new text[301]
	format(text, 300, "%s", text1)
	replace(text, 300, ">x04", "^x04")
	replace(text, 300, ">x03", "^x03")
	replace(text, 300, ">x01", "^x01")
	return text
}
SendCenterText(id, message[])
{
	new dest
	if (id) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, g_msgTextMsg, {0,0,0}, id)
	write_byte(4)
	write_string(message)
	message_end()
}
remove_ent_by_class(classname[])
{
	new nextitem  = find_ent_by_class(-1, classname)
	while(nextitem)
	{
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, classname)
	}
}
play_sound_endround(filename[])
{
	new RADIO_FOLDER[4][] = {"", "/woman", "/zombi", "/zombi_f"}
	new audio[64], sex
	for (new id = 1; id < 33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		if (g_zombie[id])
		{
			sex = 2
		}
		else
		{
			sex = 0
		}
		format(audio, charsmax(audio), "radio%s/%s.wav", RADIO_FOLDER[sex], filename)
		PlaySound(id, audio)
	}
}
set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, OFFSET_flNextAttack, nexttime, 4)
}


// ##################### Lighting Effects #####################
// Lighting Effects Task
public lighting_effects()
{
	// Get lighting style
	static lighting[2]
	get_pcvar_string(cvar_lighting, lighting, charsmax(lighting))
	strtolower(lighting)
	
	// Lighting disabled? ["0"]
	if (lighting[0] == '0')
		return;
	
	// Darkest light settings?
	if (lighting[0] >= 'a' && lighting[0] <= 'd')
	{
		static thunderclap_in_progress, Float:thunder
		thunderclap_in_progress = task_exists(TASK_THUNDER)
		thunder = get_pcvar_float(cvar_thunder)
		
		// Set thunderclap tasks if not existant
		if (thunder > 0.0 && !task_exists(TASK_THUNDER_PRE) && !thunderclap_in_progress)
		{
			g_lights_i = 0
			ArrayGetString(lights_thunder, random_num(0, ArraySize(lights_thunder) - 1), g_lights_cycle, charsmax(g_lights_cycle))
			g_lights_cycle_len = strlen(g_lights_cycle)
			//set_task(thunder, "thunderclap", TASK_THUNDER_PRE)
		}
		
		// Set lighting only when no thunderclaps are going on
		if (!thunderclap_in_progress) engfunc(EngFunc_LightStyle, 0, lighting)
	}
	else
	{
		// Remove thunderclap tasks
		if (task_exists(TASK_THUNDER_PRE)) remove_task(TASK_THUNDER_PRE)
		if (task_exists(TASK_THUNDER)) remove_task(TASK_THUNDER)
		
		// Set lighting
		engfunc(EngFunc_LightStyle, 0, lighting)
	}
}
// Thunderclap task
public thunderclap()
{
	// Play thunder sound
	if (g_lights_i == 0)
	{
		static sound[64]
		ArrayGetString(sound_thunder, random_num(0, ArraySize(sound_thunder) - 1), sound, charsmax(sound))
		PlaySound(0, sound)
	}
	
	// Set lighting
	static light[2]
	light[0] = g_lights_cycle[g_lights_i]
	engfunc(EngFunc_LightStyle, 0, light)
	
	g_lights_i++
	
	// Lighting cycle end?
	if (g_lights_i >= g_lights_cycle_len)
	{
		if (task_exists(TASK_THUNDER)) remove_task(TASK_THUNDER)
		lighting_effects()
	}
	// Lighting cycle start?
	else if (!task_exists(TASK_THUNDER))
		set_task(0.1, "thunderclap", TASK_THUNDER, _, _, "b")
}


/*================================================================================
 [Message Hooks]
=================================================================================*/
// Fix for the HL engine bug when HP is multiples of 256
public message_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		fm_set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)
	
	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}
// Block flashlight battery messages if custom flashlight is enabled instead
public message_flashbat()
{
	return PLUGIN_HANDLED;
}
// Prevent spectators' nightvision from being turned off when switching targets, etc.
public message_nvgtoggle()
{
	return PLUGIN_HANDLED;
}
// Prevent zombies from seeing any weapon pickup icon
public message_weappickup(msg_id, msg_dest, msg_entity)
{
	if (g_zombie[msg_entity])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
// Prevent zombies from seeing any ammo pickup icon
public message_ammopickup(msg_id, msg_dest, msg_entity)
{
	if (g_zombie[msg_entity])
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
// Block hostage HUD display
public message_scenario()
{
	if (get_msg_args() > 1)
	{
		static sprite[8]
		get_msg_arg_string(2, sprite, charsmax(sprite))
		
		if (equal(sprite, "hostage"))
			return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}
// Block hostages from appearing on radar
public message_hostagepos()
{
	return PLUGIN_HANDLED;
}
// Block some text messages
public message_textmsg()
{
	static textmsg[22]
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	// Game restarting, reset scores and call round end to balance the teams
	if (equal(textmsg, "#Game_will_restart_in"))
	{
		g_tickets_ct = 0
		g_tickets_te = 0
		g_score_ct = 0
		g_score_te = 0
		logevent_round_end()
	}
	else if (equal(textmsg, "#Game_Commencing"))
	{
		g_startcount = 1
	}
	// Block round end related messages
	else if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
	{
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}
// Block CS round win audio messages, since we're playing our own instead
public message_sendaudio()
{
	static audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}
// Send actual team scores (T = zombies // CT = humans)
public message_teamscore()
{
	static team[2]
	get_msg_arg_string(1, team, charsmax(team))
	
	switch (team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_score_ct)
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_score_te)
	}
}
public message_hudtextargs()
{
	return PLUGIN_HANDLED;
}
public message_statusicon()
{
	return PLUGIN_HANDLED;
}	

/*================================================================================
 [Main Stock]
=================================================================================*/

// Set a Player's Team
stock fm_cs_set_user_team(id, team)
{
	cs_set_user_team(id, team, 0)
}
// Set user money
stock fm_cs_set_user_money(id, money)
{
	cs_set_user_money(id, money, 1)
}
// Set player's health (from fakemeta_util)
stock fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat, type=0)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if (get_weapon_type(weaponid) == dropwhat)
		{
			if (type==1)
			{
				fm_strip_user_gun(id, weaponid)
			}
			else
			{
				// Get weapon entity
				static wname[32], weapon_ent
				get_weaponname(weaponid, wname, charsmax(wname))
				weapon_ent = fm_find_ent_by_owner(-1, wname, id)
				
				// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
				set_pev(weapon_ent, PEV_ADDITIONAL_AMMO, cs_get_user_bpammo(id, weaponid))
				
				// Player drops the weapon and looses his bpammo
				engclient_cmd(id, "drop", wname)
			}
		}
	}
}
// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}
// Get User Team
stock fm_set_user_armor(id, armor)
{
	set_pev(id, pev_armorvalue, float(min(armor, 999)))
}
// Get User Team
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}
// Set entity's rendering type (from fakemeta_util)
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
// only weapon index or its name can be passed, if neither is passed then the current gun will be stripped
stock fm_strip_user_gun(index, wid = 0, const wname[] = "") {
	new ent_class[32];
	if (!wid && wname[0])
		copy(ent_class, sizeof ent_class - 1, wname);
	else {
		new weapon = wid, clip, ammo;
		if (!weapon && !(weapon = get_user_weapon(index, clip, ammo)))
			return false;
		
		get_weaponname(weapon, ent_class, sizeof ent_class - 1);
	}

	new ent_weap = fm_find_ent_by_owner(-1, ent_class, index);
	if (!ent_weap)
		return false;

	engclient_cmd(index, "drop", ent_class);

	new ent_box = pev(ent_weap, pev_owner);
	if (!ent_box || ent_box == index)
		return false;

	dllfunc(DLLFunc_Think, ent_box);

	return true;
}

// Simplified get_weaponid (CS only)
stock cs_weapon_name_to_id(const weapon[])
{
	static i
	for (i = 0; i < sizeof WEAPONENTNAMES; i++)
	{
		if (equal(weapon, WEAPONENTNAMES[i]))
			return i;
	}
	
	return 0;
}

// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}
// Set an entity's key value (from fakemeta_util)
stock fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}
// Checks if a space is vacant (credits to VEN)
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

stock load_spawns()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), SPAWNS_URL, cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns[g_spawnCount][0] = floatstr(csdmdata[0])
			g_spawns[g_spawnCount][1] = floatstr(csdmdata[1])
			g_spawns[g_spawnCount][2] = floatstr(csdmdata[2])
			
			// increase spawn count
			g_spawnCount++
			if (g_spawnCount >= sizeof g_spawns) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
	
	// Collect regular spawns for non-random spawning unstuck
	collect_spawns_ent2("info_player_start")
	collect_spawns_ent2("info_player_deathmatch")
}

// Collect spawn points from entity origins
stock collect_spawns_ent(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns[g_spawnCount][0] = originF[0]
		g_spawns[g_spawnCount][1] = originF[1]
		g_spawns[g_spawnCount][2] = originF[2]
		
		// increase spawn count
		g_spawnCount++
		if (g_spawnCount >= sizeof g_spawns) break;
	}
}

// Collect spawn points from entity origins
stock collect_spawns_ent2(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns2[g_spawnCount2][0] = originF[0]
		g_spawns2[g_spawnCount2][1] = originF[1]
		g_spawns2[g_spawnCount2][2] = originF[2]
		
		// increase spawn count
		g_spawnCount2++
		if (g_spawnCount2 >= sizeof g_spawns2) break;
	}
}
// Collect random spawn points
stock load_spawns_box()
{
	// Check for CSDM spawns of the current map
	new cfgdir[32], mapname[32], filepath[100], linedata[64]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), SPAWNS_BOX_URL, cfgdir, mapname)
	
	// Load CSDM spawns if present
	if (file_exists(filepath))
	{
		new csdmdata[10][6], file = fopen(filepath,"rt")
		
		while (file && !feof(file))
		{
			fgets(file, linedata, charsmax(linedata))
			
			// invalid spawn
			if(!linedata[0] || str_count(linedata,' ') < 2) continue;
			
			// get spawn point data
			parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
			
			// origin
			g_spawns_box[g_spawnCount_box][0] = floatstr(csdmdata[0])
			g_spawns_box[g_spawnCount_box][1] = floatstr(csdmdata[1])
			g_spawns_box[g_spawnCount_box][2] = floatstr(csdmdata[2])
			
			// increase spawn count
			g_spawnCount_box++
			if (g_spawnCount_box >= sizeof g_spawns) break;
		}
		if (file) fclose(file)
	}
	else
	{
		// Collect regular spawns
		collect_spawns_ent("info_player_start")
		collect_spawns_ent("info_player_deathmatch")
	}
	
	// Collect regular spawns for non-random spawning unstuck
	collect_spawns_ent2("info_player_start")
	collect_spawns_ent2("info_player_deathmatch")
}

// Collect spawn points from entity origins
stock collect_spawns_ent_box(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns_box[g_spawnCount_box][0] = originF[0]
		g_spawns_box[g_spawnCount_box][1] = originF[1]
		g_spawns_box[g_spawnCount_box][2] = originF[2]
		
		// increase spawn count
		g_spawnCount_box++
		if (g_spawnCount_box >= sizeof g_spawns) break;
	}
}

// Collect spawn points from entity origins
stock collect_spawns_ent2_box(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_spawns2_box[g_spawnCount2_box][0] = originF[0]
		g_spawns2_box[g_spawnCount2_box][1] = originF[1]
		g_spawns2_box[g_spawnCount2_box][2] = originF[2]
		
		// increase spawn count
		g_spawnCount2_box++
		if (g_spawnCount2_box >= sizeof g_spawns2) break;
	}
}
// Stock by (probably) Twilight Suzuka -counts number of chars in a string
stock str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}
// Strip user weapons (from fakemeta_util)
stock fm_strip_user_weapons(id)
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "player_weaponstrip"))
	if (!pev_valid(ent)) return;
	
	dllfunc(DLLFunc_Spawn, ent)
	dllfunc(DLLFunc_Use, ent, id)
	if (pev_valid(ent)) engfunc(EngFunc_RemoveEntity, ent)
}
// Set User Flashlight Batteries
stock fm_cs_set_user_batteries(id, value)
{
	set_pdata_int(id, OFFSET_FLASHLIGHT_BATTERY, value, OFFSET_LINUX)
}
stock Float:estimate_take_hurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	//UTIL_TraceLine ( vecSpot, vecSpot + Vector ( 0, 0, -40 ),  ignore_monsters, ENT(pev), & tr)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent )//no valid enity between the explode point & player
		return 1.0
	return 0.6//if has fraise, lessen blast hurt
}
stock Float:get_weapon_next_pri_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextPrimaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_pri_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextPrimaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_next_sec_attack(entity)
{
	return get_pdata_float(entity, OFFSET_flNextSecondaryAttack, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_next_sec_attack(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flNextSecondaryAttack, time, OFFSET_LINUX_WEAPONS)
}

stock Float:get_weapon_idle_time(entity)
{
	return get_pdata_float(entity, OFFSET_flTimeWeaponIdle, OFFSET_LINUX_WEAPONS)
}

stock set_weapon_idle_time(entity, Float:time)
{
	set_pdata_float(entity, OFFSET_flTimeWeaponIdle, time, OFFSET_LINUX_WEAPONS)
}


/*================================================================================
 [Get Config]
=================================================================================*/
load_customization_from_files()
{
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, SETTING_FILE)
	
	// File not present
	if (!file_exists(path))
	{
		new error[100]
		formatex(error, charsmax(error), "Cannot load customization file %s!", path)
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
			case SECTION_CONFIG_VALUE:
			{
				if (equal(key, "TICKETS"))
					g_tickets = str_to_num(value)
				else if (equal(key, "WEAPONS_STAY"))
					g_weapons_stay = str_to_float(value)
				else if (equal(key, "HUMAN_HEALTH"))
					g_human_health = str_to_num(value)
				else if (equal(key, "HUMAN_ARMOR"))
					g_human_ammo = str_to_num(value)
				else if (equal(key, "ZOMBIE_ARMOR"))
					g_zombie_armor = str_to_num(value)
				else if (equal(key, "MONEY_START"))
					g_money_start = str_to_num(value)
				else if (equal(key, "RESPAWN_WAIT"))
					g_respawn_wait = str_to_float(value)
				else if (equal(key, "PROTECTION_TIME"))
					g_pro_time = str_to_float(value)
				else if (equal(key, "PROTECTION_COLOR"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushCell(g_pro_color, str_to_num(key))
					}
				}
			}
			case SECTION_RESTORE_HEALTH:
			{
				if (equal(key, "RESTORE_HEALTH_TIME"))
					restore_health_time = str_to_float(value)
				else if (equal(key, "RESTORE_HEALTH_DMG"))
					restore_health_dmg = str_to_num(value)
				else if (equal(key, "RESTORE_HEALTH_SPRITES"))
					format(restore_health_spr, charsmax(restore_health_spr), "%s", value)
			}
			case SECTION_SUPPLYBOX:
			{
				if (equal(key, "SUPPLYBOX_MAX"))
					supplybox_max = min(MAX_SUPPLYBOX, str_to_num(value))
				else if (equal(key, "SUPPLYBOX_NUM"))
					supplybox_num = min(MAX_SUPPLYBOX, str_to_num(value))
				else if (equal(key, "SUPPLYBOX_TOTAL_IN_TIME"))
					supplybox_total_in_time = str_to_num(value)
				else if (equal(key, "SUPPLYBOX_TIME"))
					supplybox_time = str_to_float(value)
				else if (equal(key, "SUPPLYBOX_MODEL"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(supplybox_models, key)
					}
				}
				else if (equal(key, "HUMAN_ITEM"))
				{
					strtolower(value)
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(human_item, key)
					}
				}
				else if (equal(key, "ZOMBIE_ITEM"))
				{
					strtolower(value)
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(zombie_item, key)
					}
				}
				else if (equal(key, "SPWEAPON_ITEM"))
				{
					strtolower(value)
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(spweapon_item, key)
					}
				}
				else if (equal(key, "SUPPLYBOX_SOUND_DROP"))
					format(supplybox_sound_drop, charsmax(supplybox_sound_drop), "%s", value)
				else if (equal(key, "SUPPLYBOX_SOUND_PICKUP"))
					format(supplybox_sound_pickup, charsmax(supplybox_sound_pickup), "%s", value)
				else if (equal(key, "SUPPLYBOX_SOUND_USE"))
					format(supplybox_sound_use, charsmax(supplybox_sound_use), "%s", value)
				else if (equal(key, "SUPPLYBOX_ICON"))
					format(supplybox_icon_spr, charsmax(supplybox_icon_spr), "%s", value)
					
				else if (equal(key, "BLIND_TIME"))
					item_blind_time = str_to_float(value)
				else if (equal(key, "CURSE_TIME"))
					item_curse_time = str_to_float(value)
				else if (equal(key, "DAMAGEDOUBLE_TIME"))
					item_damagedouble_time = str_to_float(value)
				else if (equal(key, "DAMAGEDOUBLE_DMG"))
					item_damagedouble_dmg = str_to_float(value)
				else if (equal(key, "ENEMYHODOWN_NUM"))
					item_enemyhpdown_num = str_to_num(value)
				else if (equal(key, "ENEMYHODOWN_SOUND"))
					format(item_enemyhpdown_sound, charsmax(item_enemyhpdown_sound), "%s", value)
				else if (equal(key, "FAST_TIME"))
					item_fast_time = str_to_float(value)
				else if (equal(key, "FAST_SPEED"))
					item_fast_speed = str_to_float(value)
				else if (equal(key, "FAST_SOUND_START"))
					format(item_fast_sound_start, charsmax(item_fast_sound_start), "%s", value)
				else if (equal(key, "FAST_SOUND_HEARTBEAT"))
					format(item_fast_sound_heartbeat, charsmax(item_fast_sound_heartbeat), "%s", value)
				else if (equal(key, "INFGRENADE_TIME"))
					item_infgrenade_time = str_to_float(value)
				else if (equal(key, "INVINCIBILITI_TIME"))
					item_invincibility_time = str_to_float(value)
				else if (equal(key, "JUMPUP_TIME"))
					item_jumpup_time = str_to_float(value)
				else if (equal(key, "JUMPUP_GRAVITY"))
					item_jumpup_gravity = str_to_float(value)
				else if (equal(key, "SHOOTINGDOWN_TIME"))
					item_shootingdown_time = str_to_float(value)
				else if (equal(key, "SHOOTINGDOWN_RECOIL"))
					item_shootingdown_recoil = str_to_float(value)
				else if (equal(key, "SHOOTINGUP_TIME"))
					item_shootingup_time = str_to_float(value)
				else if (equal(key, "SHOOTINGUP_RECOIL"))
					item_shootingup_recoil = str_to_float(value)
				else if (equal(key, "TEAMHPRECOVERY_NUM"))
					item_teamhprecovery_num = str_to_num(value)
				else if (equal(key, "TEAMHPRECOVERY_SOUND"))
					format(item_teamhprecovery_sound, charsmax(item_teamhprecovery_sound), "%s", value)
				else if (equal(key, "STONE_TIME"))
					item_stone_time = str_to_float(value)
			}
			case SECTION_ZOMBIEBOM:
			{
				if (equal(key, "MODEL"))
				{
					format(zombiebom_model, charsmax(zombiebom_model), "%s", value)
					format(zombiebom_model_p, charsmax(zombiebom_model_p), "models/zombie_united/p_%s.mdl", value)
					format(zombiebom_model_w, charsmax(zombiebom_model_w), "models/zombie_united/w_%s.mdl", value)
				}
				else if (equal(key, "RADIUS"))
					zombiebom_radius = str_to_float(value)
				else if (equal(key, "POWER"))
					zombiebom_power = str_to_float(value)
				else if (equal(key, "SPRITES_EXP"))
					format(zombiebom_sprites_exp, charsmax(zombiebom_sprites_exp), "%s", value)
				else if (equal(key, "SOUND_EXP"))
					format(zombiebom_sound_exp, charsmax(zombiebom_sound_exp), "%s", value)

			}
			case SECTION_SOUNDS:
			{
				if (equal(key, "THUNDER"))
				{
					// Parse sounds
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to sounds array
						ArrayPushString(sound_thunder, key)
					}
				}
				else if (equal(key, "ZOMBIE_ATTACK"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(sound_zombie_attack, key)
					}
				}
				else if (equal(key, "ZOMBIE_HITWALL"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(sound_zombie_hitwall, key)
					}
				}
				else if (equal(key, "ZOMBIE_SWING"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						trim(key)
						trim(value)
						ArrayPushString(sound_zombie_swing, key)
					}
				}
			}
			case SECTION_SPRITES:
			{
				if (equal(key, "FRIEND_CT"))
					format(models_friend_ct, charsmax(models_friend_ct), "%s", value)
				else if (equal(key, "FRIEND_TE"))
					format(models_friend_te, charsmax(models_friend_te), "%s", value)
			}
			case SECTION_MENUWEAPONS:
			{
				if (equal(key, "PRIMARY"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Add to lightning array
						ArrayPushString(weapons_pri, key)
					}
				}
				else if (equal(key, "PRIMARY_NAME"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Add to lightning array
						ArrayPushString(weapons_pri_name, key)
					}
				}
				else if (equal(key, "SECONDARY"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Add to lightning array
						ArrayPushString(weapons_sec, key)
					}
				}
				else if (equal(key, "SECONDARY_NAME"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Add to lightning array
						ArrayPushString(weapons_sec_name, key)
					}
				}
				else if (equal(key, "NADE"))
				{
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Add to lightning array
						ArrayPushString(weapons_nade, key)
					}
				}
			}
			case SECTION_WEATHER_EFFECTS:
			{
				if (equal(key, "RAIN"))
					g_ambience_rain = str_to_num(value)
				else if (equal(key, "SNOW"))
					g_ambience_snow = str_to_num(value)
				else if (equal(key, "FOG"))
					g_ambience_fog = str_to_num(value)
				else if (equal(key, "FOG DENSITY"))
					copy(g_fog_density, charsmax(g_fog_density), value)
				else if (equal(key, "FOG COLOR"))
					copy(g_fog_color, charsmax(g_fog_color), value)
			}
			case SECTION_SKY:
			{
				if (equal(key, "ENABLE"))
					g_sky_enable = str_to_num(value)
				else if (equal(key, "SKY NAMES"))
				{
					// Parse sky names
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to skies array
						ArrayPushString(g_sky_names, key)
						
						// Preache custom sky files
						formatex(linedata, charsmax(linedata), "gfx/env/%sbk.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sdn.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sft.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%slf.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%srt.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
						formatex(linedata, charsmax(linedata), "gfx/env/%sup.tga", key)
						engfunc(EngFunc_PrecacheGeneric, linedata)
					}
				}
			}
			case SECTION_LIGHTNING:
			{
				if (equal(key, "LIGHTS"))
				{
					// Parse lights
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to lightning array
						ArrayPushString(lights_thunder, key)
					}
				}
			}
			case SECTION_KNOCKBACK:
			{
				// Format weapon entity name
				strtolower(key)
				format(key, charsmax(key), "weapon_%s", key)
				
				// Add value to knockback power array
				kb_weapon_power[cs_weapon_name_to_id(key)] = str_to_float(value)
			}
			case SECTION_OBJECTIVE_ENTS:
			{
				if (equal(key, "CLASSNAMES"))
				{
					// Parse classnames
					while (value[0] != 0 && strtok(value, key, charsmax(key), value, charsmax(value), ','))
					{
						// Trim spaces
						trim(key)
						trim(value)
						
						// Add to objective ents array
						ArrayPushString(g_objective_ents, key)
					}
				}
				else if (equal(key, "BLOCK_BUY"))
					g_blockbuy = str_to_num(value)

			}
		}
	}
	if (file) fclose(file)
}


/*================================================================================
 [Custom Natives]
=================================================================================*/
public native_register_zombie_class(const name[], const model[], health, Float:gravity, Float:speed, Float:knockback, const sound_death1[], const sound_death2[], const sound_hurt1[], const sound_hurt2[], const sound_heal[], sex, modelindex)
{
	// Strings passed byref
	param_convert(1)
	param_convert(2)
	param_convert(6)
	param_convert(7)
	param_convert(8)
	param_convert(9)
	param_convert(10)
	param_convert(11)
	
	// Add the class
	ArrayPushString(zombie_name, name)
	ArrayPushCell(zombie_health, health)
	ArrayPushCell(zombie_gravity, gravity)
	ArrayPushCell(zombie_speed, speed)
	ArrayPushCell(zombie_knockback, knockback)
	ArrayPushCell(zombie_sex, sex)
	ArrayPushCell(zombie_modelindex, modelindex)
	ArrayPushString(zombie_sound_death1, sound_death1)
	ArrayPushString(zombie_sound_death2, sound_death2)
	ArrayPushString(zombie_sound_hurt1, sound_hurt1)
	ArrayPushString(zombie_sound_hurt2, sound_hurt2)
	ArrayPushString(zombie_sound_heal, sound_heal)
	
	new viewmodel_host[64], viewmodel_origin[64], viewmodel_host_url[64], viewmodel_origin_url[64], wpnmodel[64], v_zombiebom[64]
	formatex(viewmodel_host, charsmax(viewmodel_host), "%s_host", model)
	formatex(viewmodel_origin, charsmax(viewmodel_origin), "%s_origin", model)
	formatex(viewmodel_host_url, charsmax(viewmodel_host_url), "models/player/%s/%s.mdl", viewmodel_host, viewmodel_host)
	formatex(viewmodel_origin_url, charsmax(viewmodel_origin_url), "models/player/%s/%s.mdl", viewmodel_origin, viewmodel_origin)
	formatex(wpnmodel, charsmax(wpnmodel), "models/zombie_united/v_knife_%s.mdl", model)
	formatex(v_zombiebom, charsmax(v_zombiebom), "models/zombie_united/v_zombibomb_%s.mdl", model)
	
	ArrayPushString(zombie_viewmodel_host, viewmodel_host)
	ArrayPushString(zombie_viewmodel_origin, viewmodel_origin)
	ArrayPushString(zombie_wpnmodel, wpnmodel)
	ArrayPushString(zombiebom_viewmodel, v_zombiebom)
	
	ArrayPushCell(zombie_modelindex_host, engfunc(EngFunc_PrecacheModel, viewmodel_host_url))
	ArrayPushCell(zombie_modelindex_origin, engfunc(EngFunc_PrecacheModel, viewmodel_origin_url))
	engfunc(EngFunc_PrecacheModel, wpnmodel)
	engfunc(EngFunc_PrecacheModel, v_zombiebom)
	engfunc(EngFunc_PrecacheSound, sound_death1)
	engfunc(EngFunc_PrecacheSound, sound_death2)
	engfunc(EngFunc_PrecacheSound, sound_hurt1)
	engfunc(EngFunc_PrecacheSound, sound_hurt2)
	engfunc(EngFunc_PrecacheSound, sound_heal)
	
	// Increase registered classes counter
	class_count++
	
	// Return id under which we registered the class
	return class_count-1;
}
public native_get_user_zombie(id)
{
	return g_zombie[id];
}
public native_get_user_zombie_class(id)
{
	return g_zombieclass[id];
}
public natives_color_saytext(player, const message[], any:...)
{
	param_convert(2)
	color_saytext(player, message)
	return 1
}
public native_get_user_start_health(id)
{
	new health
	if (g_zombie[id]) health = ArrayGetCell(zombie_health, g_zombieclass[id])
	else health = g_human_health
	
	return health;
}
public native_get_user_level(id)
{
	return 3
}
public native_get_mod()
{
	return ZOMBIE_MOD;
}
public native_get_take_damage()
{
	new take_dmg
	if (!g_newround && !g_endround && !g_freezetime) take_dmg = 1
	
	return take_dmg
}
public native_get_damage_nade()
{
	return get_pcvar_num(cvar_damage_nade)
}
// native bug fix
public native_novalue(id)
{
	return 0
}

stock fm_cs_set_user_model_index(id, value)
{
	if (!value) return;
	set_pdata_int(id, 491, value, 5)
}

stock fm_reset_user_model_index(id)
{
	set_pdata_int(id, 491, g_default_model, 5)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1066\\ f0\\ fs16 \n\\ par }
*/
