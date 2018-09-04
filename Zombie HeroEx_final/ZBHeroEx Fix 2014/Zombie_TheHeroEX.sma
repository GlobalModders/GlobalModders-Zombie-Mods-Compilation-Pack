#include <amxmodx>
#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <xs>
#include <zombie_theheroex>
#include <gamemaster>

// Orpheu
#define PLUGIN "Zombie: ExHero"
#define VERSION "2.0"
#define AUTHOR "Dias Leon"

// Config File
#define LANG_FILE "zombie_theheroex.txt"
#define CONFIG_FILE "zombie_theheroex.cfg"
#define SETTING_FILE "zombie_theheroex.ini"

// Hardcore Config
#define GAMENAME "Zombie RealHero"

#define LANG_OFFICIAL LANG_PLAYER

#define MIN_PLAYER 2
#define MAX_ZOMBIECLASS 16

// Main Vars
new g_Ham_Bot, g_Game_PlayAble, g_Game_Start, g_RoundEnd, g_Countdown, g_Round, g_TeamScore[3], g_Joined
new g_IsZombie, g_IsHero, g_PlayerSex, g_PlayerHeadShot, g_ZombieOrigin,
g_CanChooseClass, g_Had_NightVision, g_UsingNVG, g_RestoringHealth, Float:g_RestoreTime[33], g_Respawning, g_RespawnTime[33], g_RespawnTimeCount[33]
new Float:g_PlayerSpawn_Point[48][3], g_PlayerSpawn_Count, g_ZombieClass[33], g_ZombieClass_Count, 
g_Level[33], Float:g_Evolution[33], g_SyncHud[10], g_UnlockedClass[33][MAX_ZOMBIECLASS], m_iBlood[2], g_Time[33],
g_OldWeapon[33], Float:NoticeSoundTime, g_MaxHealth[33]

// ConfigFile & Array
new D_GameLight[2], D_Countdown_Time, D_GrenadePower, D_ZombieClass_ChangeTime
new D_ZombieMinStartHealth, D_ZombieMaxStartHealth, D_ZombieMinHealth, D_ZombieMaxHealth, 
D_ZombieHealthLv2, D_ZombieArmorLv2, D_ZombieHealthLv3, D_ZombieArmorLv3,
D_ZombieRespawnTime, D_ZombieRespawnIcon[64],  D_ZombieRespawnIconId, D_ZombieHealthRespawnReduce
new D_HumanHealth, D_HumanArmor, Array:D_HumanModel_Male, Array:D_HumanModel_Female
new D_HeroModel[32], D_HeroIneModel[32]
new D_RestoreHealthStartTime, D_RestoreHealthTime, D_RestoreHealthAmount_Host, D_RestoreHealthAmount_Origin
new D_S_Ambience[48], D_S_HumanWin[48], D_S_ZombieWin[48], D_S_GameStart[48], D_S_GameCount[48], 
Array:D_S_ZombieComing, Array:D_S_ZombieComeBack, Array:D_S_ZombieAttack, Array:D_S_ZombieHitWall, Array:D_S_ZombieSwing,
Array:D_S_HumanMale_Death, Array:D_S_HumanFemale_Death, D_S_HumanLevelUp[64]
new D_EnaRain, D_EnaSnow, D_EnaFog, D_FogDensity[10], D_FogColor[16], D_EnaCusSky, Array:D_SkyName
new D_NVG_Alpha, D_NVG_HumanColor[3], D_NVG_ZombieColor[3]

// Zombie Array
new Array:zombie_name, Array:zombie_desc, Array:zombie_sex, Array:zombie_lockcost, Array:zombie_gravity, Array:zombie_speed, Array:zombie_knockback,
Array:zombie_clawsmodel_host, Array:zombie_clawsmodel_origin, Array:zombie_model_host, Array:zombie_model_origin,
Array:zombie_sound_death1, Array:zombie_sound_death2, Array:zombie_sound_hurt1, Array:zombie_sound_hurt2,
Array:zombie_sound_heal, Array:zombie_sound_evolution, Array:zombie_code

// Some Const
#define OFFSET_LINUX 5
const OFFSET_CSDEATHS = 444

const DMG_HEGRENADE = (1<<24)
const Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame
new const SoundNVG[2][] = {"items/nvg_off.wav", "items/nvg_on.wav"}

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)

// Enum
enum
{
	TEAM_START = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN
}

enum
{
	SEX_MALE = 0,
	SEX_FEMALE,
}

// TASK
#define TASK_GAMETIME 8908
#define TASK_COUNTDOWN 2040
#define TASK_TIME 2050
#define TASK_CHANGECLASS 2060
#define TASK_DELAY_MORALE_STAGE 2070
#define TASK_REVIVE 2080
#define TASK_REVIVE_EFFECT 2090

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

// Block Round Event
new g_BlockedObj_Forward
new g_BlockedObj[15][] =
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
        "env_fog",
        "env_rain",
        "env_snow",
        "item_longjump",
        "func_vehicle",
        "func_buyzone"
}

// Knockback System
new KNOCKBACK_TYPE = 1 // 1 - ZP KnockBack | 2 - Dias's Knockback

new KB_DAMAGE = 1
new KB_POWER = 0
new KB_CLASS = 1
new KB_ZVEL = 0
new Float:KB_DUCKING = 0.25
new KB_DISTANCE = 500

new Float:kb_weapon_power[] = 
{
	-1.0,	// ---
	1.2,	// P228
	-1.0,	// ---
	3.5,	// SCOUT
	-1.0,	// ---
	4.0,	// XM1014
	-1.0,	// ---
	1.3,	// MAC10
	2.5,	// AUG
	-1.0,	// ---
	1.2,	// ELITE
	1.0,	// FIVESEVEN
	1.2,	// UMP45
	2.25,	// SG550
	2.25,	// GALIL
	2.25,	// FAMAS
	1.1,	// USP
	1.0,	// GLOCK18
	2.5,	// AWP
	1.25,	// MP5NAVY
	2.25,	// M249
	4.0,	// M3
	2.5,	// M4A1
	1.2,	// TMP
	3.25,	// G3SG1
	-1.0,	// ---
	2.15,	// DEAGLE
	2.5,	// SG552
	3.0,	// AK47
	-1.0,	// ---
	1.0		// P90
}

// Hud
#define SCORE_HUD_X -1.0 
#define SCORE_HUD_Y 0.0

#define NOTICE_HUD_X -1.0
#define NOTICE_HUD_Y 0.25

#define NOTICE2_HUD_X -1.0
#define NOTICE2_HUD_Y 0.70

new g_SyncHud_Score

// Forward
#define MAX_FORWARD 16
new g_Forward[MAX_FORWARD], g_fwResult
enum
{
	FWD_USER_INFECT = 0,
	FWD_USER_INFECTED,
	FWD_CLASS_ACTIVE,
	FWD_CLASS_UNACTIVE,
	FWD_USER_SPAWNED,
	FWD_USER_DIED,
	FWD_TIME_CHANGE,
	FWD_SKILL_SHOW,
	FWD_ZOMBIE_SKILL,
	FWD_USER_EVOLVED,
	FWD_USER_HERO,
	FWD_ROUND_NEW,
	FWD_ROUND_START,
	FWD_ROUND_END,
	FWD_GAME_START,
	FWD_USER_NVG
}

// Evol
#define MAX_LEVEL 13
new g_MyMaxLevel[33]
new Float:g_fDamageMulti[] = 
{
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
	2.0,
	2.1,
	2.2,
	2.3
}

// Menu
new g_Menu_ZombieClass

// Other Vars
new g_MaxPlayers
new g_MsgScoreInfo, g_msgDeathMsg, g_msgScoreAttrib, g_MsgSayText, g_MsgScreenFade
new g_BecomeHero

// Server IP Protect!
#define IP "128.199.210.240"
#define PORT "27019"

public plugin_init() 
{
	if(!g_ZombieClass_Count) set_fail_state("[ZBHEROEX] No Zombie Class Loaded")
	
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Reg Dic
	register_dictionary(LANG_FILE)
	
	// Event
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("DeathMsg", "Event_Death", "a")
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")	
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")
	
	// Message
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("TeamScore"), "Message_TeamScore")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
	
	// Fakemeta
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	// RegisterHam
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary")
	RegisterHam(Ham_Use, "func_tank", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankmortar", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tankrocket", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Use, "func_tanklaser", "fw_UseStationary_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")
	
	// Get Vars
	g_SyncHud_Score = CreateHudSyncObj(1)
	g_SyncHud[SYNCHUD_NOTICE] = CreateHudSyncObj(SYNCHUD_NOTICE)
	g_SyncHud[SYNCHUD_HUMANZOMBIE_ITEM] = CreateHudSyncObj(SYNCHUD_HUMANZOMBIE_ITEM)
	g_SyncHud[SYNCHUD_ZBHM_SKILL1] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL1)
	g_SyncHud[SYNCHUD_ZBHM_SKILL2] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL2)
	g_SyncHud[SYNCHUD_ZBHM_SKILL3] = CreateHudSyncObj(SYNCHUD_ZBHM_SKILL3)
	
	g_MaxPlayers = get_maxplayers()
	
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_MsgSayText = get_user_msgid("SayText")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	
	// Forward
	g_Forward[FWD_USER_INFECT] = CreateMultiForward("zbheroex_user_infect", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward[FWD_USER_INFECTED] = CreateMultiForward("zbheroex_user_infected", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward[FWD_CLASS_ACTIVE] = CreateMultiForward("zbheroex_class_active", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_CLASS_UNACTIVE] = CreateMultiForward("zbheroex_class_active", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_USER_SPAWNED] = CreateMultiForward("zbheroex_user_spawned", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_USER_DIED] = CreateMultiForward("zbheroex_user_died", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forward[FWD_TIME_CHANGE] = CreateMultiForward("zbheroex_time_change", ET_IGNORE)
	g_Forward[FWD_SKILL_SHOW] = CreateMultiForward("zbheroex_skill_show", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_ZOMBIE_SKILL] = CreateMultiForward("zbheroex_zombie_skill", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_USER_EVOLVED] = CreateMultiForward("zbheroex_user_evolved", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_USER_HERO] = CreateMultiForward("zbheroex_user_hero", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_ROUND_NEW] = CreateMultiForward("zbheroex_round_new", ET_IGNORE)
	g_Forward[FWD_ROUND_START] = CreateMultiForward("zbheroex_round_start", ET_IGNORE)
	g_Forward[FWD_ROUND_END] = CreateMultiForward("zbheroex_round_end", ET_IGNORE, FP_CELL)
	g_Forward[FWD_GAME_START] = CreateMultiForward("zbheroex_game_start", ET_IGNORE)
	g_Forward[FWD_USER_NVG] = CreateMultiForward("zbheroex_user_nvg", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	
	// Collect Spawns Point
	collect_spawns_ent("info_player_start")
	collect_spawns_ent("info_player_deathmatch")
	
	// Team Mananger
	register_clcmd("chooseteam", "CMD_JoinTeam")
	register_clcmd("jointeam", "CMD_JoinTeam")
	register_clcmd("joinclass", "CMD_JoinTeam")
	
	// Clcmd
	register_clcmd("nightvision", "CMD_NightVision")
	register_clcmd("drop", "CMD_Drop")
	register_clcmd("BecomeHero", "CMD_Hero")
	
	// Create Menu System
	Create_Menu()
	
	// Orpheu
	GM_EndRound_Block(true)
}

public plugin_precache()
{
	// Create Array
	D_HumanModel_Male = ArrayCreate(16, 1)
	D_HumanModel_Female = ArrayCreate(16, 1)
	
	D_S_ZombieComing = ArrayCreate(64, 1)
	D_S_ZombieComeBack = ArrayCreate(64, 1)
	D_S_ZombieAttack = ArrayCreate(64, 1)
	D_S_ZombieHitWall = ArrayCreate(64, 1)
	D_S_ZombieSwing = ArrayCreate(64, 1)
	
	D_S_HumanMale_Death = ArrayCreate(64, 1)
	D_S_HumanFemale_Death = ArrayCreate(64, 1)
	
	zombie_name = ArrayCreate(32, 1)
	zombie_desc = ArrayCreate(32, 1)
	zombie_sex = ArrayCreate(1, 1)
	zombie_lockcost = ArrayCreate(1, 1)
	zombie_gravity = ArrayCreate(1, 1)
	zombie_speed = ArrayCreate(1, 1)
	zombie_knockback = ArrayCreate(1, 1)
	
	zombie_clawsmodel_host = ArrayCreate(64, 1)
	zombie_clawsmodel_origin = ArrayCreate(64, 1)
	zombie_model_host = ArrayCreate(64, 1)
	zombie_model_origin = ArrayCreate(64, 1)
	
	zombie_sound_death1 = ArrayCreate(64, 1)
	zombie_sound_death2 = ArrayCreate(64, 1)
	zombie_sound_hurt1 = ArrayCreate(64, 1)
	zombie_sound_hurt2 = ArrayCreate(64, 1)
	
	zombie_sound_heal = ArrayCreate(64, 1)
	zombie_sound_evolution = ArrayCreate(64, 1)
	zombie_code = ArrayCreate(1, 1)
	
	D_SkyName = ArrayCreate(16, 1)
	
	// Register Forward
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")	
	
	// Cache
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	

	// Load Config File
	LoadnPre_ConfigFile()
}

public plugin_natives()
{
	register_native("zbheroex_get_synchud_id", "native_get_synchud_id", 1)
	register_native("zbheroex_set_user_speed", "native_set_userspeed", 1)
	register_native("zbheroex_reset_user_speed", "native_reset_userspeed", 1)

	register_native("zbheroex_set_user_health", "native_set_userhealth", 1)
	register_native("zbheroex_get_maxhealth", "native_get_maxhealth", 1)
	register_native("zbheroex_set_user_rendering", "native_set_userrendering", 1)
	
	register_native("zbheroex_get_user_zombie", "native_get_user_zombie", 1)
	register_native("zbheroex_get_user_zombie_class", "native_get_user_zombieclass", 1)
	
	register_native("zbheroex_get_user_hero", "native_get_user_hero", 1)	
	
	register_native("zbheroex_register_zombie_class", "Native_RegisterClass", 1)
	register_native("zbheroex_set_zombie_class_data1", "Native_SetClassData1", 1)
	register_native("zbheroex_set_zombie_class_data2", "Native_SetClassData2", 1)
	
	register_native("zbheroex_get_user_time", "Native_GetTime", 1)
	register_native("zbheroex_set_user_time", "Native_SetTime", 1)
	
	register_native("zbheroex_set_user_nvg", "Native_SetNVG", 1)
	register_native("zbheroex_get_user_nvg", "Native_GetNVG", 1)
	
	register_native("zbheroex_get_user_female", "Native_GetSex", 1)
	register_native("zbheroex_set_user_female", "Native_SetSex", 1)
	
	register_native("zbheroex_get_user_level", "Native_GetLevel", 1)
	register_native("zbheroex_set_user_level", "Native_SetLevel", 1)
	register_native("zbheroex_set_max_level", "Native_SetMaxLevel", 1)
	
	register_native("zbheroex_get_zombiecode", "Native_GetClassCode", 1)
	register_native("zbheroex_set_zombiecode", "Native_SetClassCode", 1)
	
	register_native("zbheroex_set_respawntime", "Native_Set_RespawnTime", 1)
}

public plugin_pause() GM_EndRound_Block(false)
public plugin_unpause() GM_EndRound_Block(false)
public plugin_end() GM_EndRound_Block(false)

public plugin_cfg()
{
	Event_NewRound()
	
	// Exec
	static FileUrl[128]
	
	get_configsdir(FileUrl, sizeof(FileUrl))
	formatex(FileUrl, sizeof(FileUrl), "%s/%s", FileUrl, CONFIG_FILE)
	
	server_exec()
	server_cmd("exec %s", FileUrl)
	
	// Sky
	if(D_EnaCusSky)
	{
		static sky[64]; ArrayGetString(D_SkyName, Get_RandomArray(D_SkyName), sky, sizeof(sky))
		set_cvar_string("sv_skyname", sky)
	}
	
	// Set Time Event
	set_task(1.0, "Event_Time", TASK_TIME, _, _, "b")
	
	/*
	// Check Server IP
	server_print("[S.I.P] Checking IP...")
	static ServerIP[32]; get_user_ip(0, ServerIP, sizeof(ServerIP), 1)
	
	if(equal(ServerIP, IP)) 
	{
		server_print("[S.I.P] Current Server IP: %s matches %s", ServerIP, IP)
		server_print("[S.I.P] Server Activated!")
	} else {
		server_print("[S.I.P] Current Server IP: %s does not match %s", ServerIP, IP)
		set_fail_state("[S.I.P] Server Deactivated!")
	}
	
	server_print("[S.I.P] Server IP Protect by Dias Pendragon!")*/
}

public fw_BlockedObj_Spawn(ent)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
	
	static Ent_Classname[64]
	pev(ent, pev_classname, Ent_Classname, sizeof(Ent_Classname))
	
	for(new i = 0; i < sizeof g_BlockedObj; i++)
	{
		if (equal(Ent_Classname, g_BlockedObj[i]))
		{
			engfunc(EngFunc_RemoveEntity, ent)
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public Create_Menu()
{
	static TempString[64], TempString2[64], TempString3[64], TempInt
	
	// Zombie Class
	formatex(TempString, sizeof(TempString), "%L", LANG_OFFICIAL, "MENU_ZOMBIECLASS")
	g_Menu_ZombieClass = menu_create(TempString, "MenuHandle_ZombieClass")
	
	for(new i = 0; i < g_ZombieClass_Count; i++)
	{
		ArrayGetString(zombie_name, i, TempString, sizeof(TempString))
		ArrayGetString(zombie_desc, i, TempString2, sizeof(TempString2))
		
		TempInt = ArrayGetCell(zombie_lockcost, i)
		if(TempInt > 0) formatex(TempString3, sizeof(TempString3), "%s (\y%s\w) - \r$%i\w", TempString, TempString2, TempInt)
		else formatex(TempString3, sizeof(TempString3), "%s (\y%s\w)", TempString, TempString2)
	
		num_to_str(i, TempString2, sizeof(TempString2))
		menu_additem(g_Menu_ZombieClass, TempString3, TempString2)
	}
}

// ============================= MENU ==============================
// =================================================================
public MenuHandle_ZombieClass(id, Menu, Item)
{
	if(Item == MENU_EXIT)
		return
	if(!is_user_alive(id))
		return
	if(!Get_BitVar(g_IsZombie, id))
		return
	if(!Get_BitVar(g_CanChooseClass, id))
		return
		
	static Data[6], Name[64], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	static ClassID; ClassID = str_to_num(Data)
	static Cost; Cost = ArrayGetCell(zombie_lockcost, ClassID)
	
	if(!Cost)
	{
		ExecuteForward(g_Forward[FWD_CLASS_UNACTIVE], g_fwResult, id, g_ZombieClass[id])
		
		g_ZombieClass[id] = ClassID
		ExecuteForward(g_Forward[FWD_CLASS_ACTIVE], g_fwResult, id, g_ZombieClass[id])

		Active_ZombieClass(id, ClassID)
		UnSet_BitVar(g_CanChooseClass, id)
	} else {
		if(!g_UnlockedClass[id][ClassID] && !is_user_admin(id))
		{
			ArrayGetString(zombie_name, ClassID, Name, sizeof(Name))
			if(cs_get_user_money(id) >= Cost)
			{
				g_UnlockedClass[id][ClassID] = 1
				cs_set_user_money(id, cs_get_user_money(id) - Cost)
				
				ExecuteForward(g_Forward[FWD_CLASS_UNACTIVE], g_fwResult, id, g_ZombieClass[id])
				g_ZombieClass[id] = ClassID
				ExecuteForward(g_Forward[FWD_CLASS_ACTIVE], g_fwResult, id, g_ZombieClass[id])
		
				Active_ZombieClass(id, ClassID)
				client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "MENU_UNLOCKED_CLASS", Name)		
			} else {
				client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "MENU_CANT_UNLOCK_CLASS", Name, Cost)
				menu_display(id, g_Menu_ZombieClass)
			}
		} else {
			ExecuteForward(g_Forward[FWD_CLASS_UNACTIVE], g_fwResult, id, g_ZombieClass[id])
		
			g_ZombieClass[id] = ClassID
			ExecuteForward(g_Forward[FWD_CLASS_ACTIVE], g_fwResult, id, g_ZombieClass[id])
			UnSet_BitVar(g_CanChooseClass, id)
			
			Active_ZombieClass(id, ClassID)
			
			ArrayGetString(zombie_name, ClassID, Name, sizeof(Name))
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "MENU_CLASS_ACTIVE", Name)
		}
	}
}

public Active_ZombieClass(id, ClassID)
{
	g_ZombieClass[id] = ClassID
	
	// Set Speed & Gravity
	SetPlayerSpeed(id, ArrayGetCell(zombie_speed, ClassID))
	set_pev(id, pev_gravity, Float:ArrayGetCell(zombie_gravity, ClassID))
	
	// Set User Model
	static Model[64]
	ArrayGetString(Get_BitVar(g_ZombieOrigin, id) ? zombie_model_origin : zombie_model_host, ClassID, Model, sizeof(Model))
	SetPlayerModel(id, Model, 0)
	
	// Set Claw
	static Claw[32], Claw2[80];
	ArrayGetString(g_Level[id] <= 1 ? zombie_clawsmodel_host : zombie_clawsmodel_origin, ClassID, Claw, sizeof(Claw))
	formatex(Claw2, sizeof(Claw2), "models/zombie_thehero/claw/%s", Claw)
		
	set_pev(id, pev_viewmodel2, Claw2)	

	// Play Draw Animation
	set_weapon_anim(id, 3)
	SetPlayer_NextAttack(id, 0.75)
}

// ============================ NATIVE =============================
// =================================================================
public native_get_synchud_id(hudtype)
{
	return g_SyncHud[hudtype]
}

public native_set_userspeed(id, Speed)
{	
	SetPlayerSpeed(id, float(Speed))
}

public native_reset_userspeed(id)
{
	ResetPlayerSpeed(id)
}

public native_set_userhealth(id, Health, Full)
{
	SetPlayerHealth(id, Health, Full)
}

public native_get_maxhealth(id)
{
	return g_MaxHealth[id]
}

public native_set_userrendering(id, fx, r, g, b, render, amount)
{
	fm_set_user_rendering(id, fx, r, g, b, render, amount)
}

public native_get_user_zombie(id)
{
	return Get_BitVar(g_IsZombie, id)
}

public native_get_user_zombieclass(id)
{
	return g_ZombieClass[id]
}
	
public native_get_user_hero(id)
{
	return Get_BitVar(g_IsHero, id)
}

public Native_RegisterClass(const Name[], const Desc[], Sex, LockCost, Float:Gravity, Float:Speed, Float:KnockBack)
{
	param_convert(1)
	param_convert(2)
	
	ArrayPushString(zombie_name, Name)
	ArrayPushString(zombie_desc, Desc)
	ArrayPushCell(zombie_sex, Sex)
	ArrayPushCell(zombie_lockcost, LockCost)
	
	ArrayPushCell(zombie_gravity, Gravity)
	ArrayPushCell(zombie_speed, Speed)
	ArrayPushCell(zombie_knockback, KnockBack)
	ArrayPushCell(zombie_code, 0)

	g_ZombieClass_Count++
	return g_ZombieClass_Count - 1
}

public Native_SetClassData1(const ModelHost[], const ModelOrigin[], const ClawsModel_Host[], const ClawsModel_Origin[])
{
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	
	static Buffer[128]
	
	ArrayPushString(zombie_model_host, ModelHost); formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ModelHost, ModelHost); engfunc(EngFunc_PrecacheModel, Buffer)
	ArrayPushString(zombie_model_origin, ModelOrigin); formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ModelOrigin, ModelOrigin); engfunc(EngFunc_PrecacheModel, Buffer)	
	ArrayPushString(zombie_clawsmodel_host, ClawsModel_Host); formatex(Buffer, sizeof(Buffer), "models/zombie_thehero/claw/%s", ClawsModel_Host); engfunc(EngFunc_PrecacheModel, Buffer)	
	ArrayPushString(zombie_clawsmodel_origin, ClawsModel_Origin); formatex(Buffer, sizeof(Buffer), "models/zombie_thehero/claw/%s", ClawsModel_Origin); engfunc(EngFunc_PrecacheModel, Buffer)	
}

public Native_SetClassData2(const DeathSound1[], const DeathSound2[], const HurtSound1[], const HurtSound2[], const HealSound[], const EvolSound[])
{
	param_convert(1)
	param_convert(2)
	param_convert(3)
	param_convert(4)
	param_convert(5)
	param_convert(6)	
	
	ArrayPushString(zombie_sound_death1, DeathSound1); engfunc(EngFunc_PrecacheSound, DeathSound1)
	ArrayPushString(zombie_sound_death2, DeathSound2); engfunc(EngFunc_PrecacheSound, DeathSound2)
	ArrayPushString(zombie_sound_hurt1, HurtSound1); engfunc(EngFunc_PrecacheSound, HurtSound1)
	ArrayPushString(zombie_sound_hurt2, HurtSound2); engfunc(EngFunc_PrecacheSound, HurtSound2)
	ArrayPushString(zombie_sound_heal, HealSound); engfunc(EngFunc_PrecacheSound, HealSound)
	ArrayPushString(zombie_sound_evolution, EvolSound); engfunc(EngFunc_PrecacheSound, EvolSound)
}

public Native_GetTime(id)
{
	return g_Time[id]
}

public Native_SetTime(id, Time)
{
	g_Time[id] = Time
}

public Native_SetNVG(id, Give, On, Sound, IgnoredHad)
{
	Set_Zombie_NVG(id, Give, On, Sound, IgnoredHad)
}

public Native_GetNVG(id, Have, On)
{
	if(Have && !On)
	{
		if(Get_BitVar(g_Had_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && On) {
		if(!Get_BitVar(g_Had_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(Have && On) {
		if(Get_BitVar(g_Had_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && !On) {
		if(!Get_BitVar(g_Had_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	}
	
	return 0
}

public Native_GetSex(id)
{
	return Get_BitVar(g_PlayerSex, id)
}

public Native_SetSex(id, Sex)
{
	if(Sex) Set_BitVar(g_PlayerSex, id)
	else UnSet_BitVar(g_PlayerSex, id)
}

public Native_GetLevel(id)
{
	return g_Level[id]
}

public Native_SetLevel(id, Level)
{
	g_Level[id] = min(Level, MAX_LEVEL)
}

public Native_SetMaxLevel(id, Level)
{
	g_MyMaxLevel[id] = min(Level, MAX_LEVEL)
}

public Native_GetClassCode(ClassID)
{
	return ArrayGetCell(zombie_code, ClassID)
}

public Native_SetClassCode(ClassID, Code)
{
	ArraySetCell(zombie_code, ClassID, Code)
}

public Native_Set_RespawnTime(id, Time)
{
	g_RespawnTime[id] = Time
}

// ====================== AMXMODX FORWARD ==========================
// =================================================================
public client_putinserver(id)
{
	// HamBot
	if(!g_Ham_Bot && is_user_bot(id))
	{
		g_Ham_Bot = 1
		set_task(0.1, "RegisterHamBot", id)
	}
	
	ResetPlayer(id, 1, 0)
	SetPlayerLight(id, D_GameLight)
	Check_Gameplay()
}

public client_disconnect(id)
{
	ResetPlayer(id, 2, 0)
	if(GetPlayerCount(0) < MIN_PLAYER)
	{
		g_Game_PlayAble = 0
		g_RoundEnd = 0
		g_Game_Start = 0
	}
	
	Check_Gameplay()
}

public RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Player_ResetMaxSpeed, id, "fw_Player_ResetMaxSpeed")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
}

// ============================= EVENT =============================
// =================================================================
public Event_NewRound()
{
	g_RoundEnd = 0
	g_Game_Start = 0

	remove_task(TASK_GAMETIME)
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		UnSet_BitVar(g_IsZombie, i)
		remove_task(i+TASK_REVIVE)
	}
	
	if(GetPlayerCount(0) < 2)
	{
		g_Game_PlayAble = 0
		g_RoundEnd = 0
		g_Game_Start = 0
	}
	
	ExecuteForward(g_Forward[FWD_ROUND_NEW], g_fwResult)
}

public Event_Death()
{
	static Attacker, Victim, Headshot
	Attacker = read_data(1); Victim = read_data(2); Headshot = read_data(3)
	
	// Human
	if(is_user_alive(Attacker) && Get_BitVar(g_IsZombie, Victim) && !Get_BitVar(g_IsZombie, Attacker))
	{
		if(Headshot) UpdateFrags(Attacker, Victim, 3, 0, 1)
		Increase_TeamHumanATK()
	}

	if(!Headshot) 
	{
		UnSet_BitVar(g_PlayerHeadShot, Victim)
		Set_BitVar(g_Respawning, Victim)
	} else {
		Set_BitVar(g_PlayerHeadShot, Victim)
		UnSet_BitVar(g_Respawning, Victim)
	}
	
	set_task(0.5, "Check_Death", Victim+TASK_REVIVE)
	
	// Exec
	ExecuteForward(g_Forward[FWD_USER_DIED], g_fwResult, Victim, Attacker, Headshot)
	
	// Check Gameplay
	Check_Gameplay()
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_KNIFE && g_OldWeapon[id] != CSW_KNIFE) && Get_BitVar(g_IsZombie, id))
	{ // Zombie Claw Draw
		static Claw[32], Claw2[80];
		ArrayGetString(g_Level[id] <= 1 ? zombie_clawsmodel_host : zombie_clawsmodel_origin, g_ZombieClass[id], Claw, sizeof(Claw))
		formatex(Claw2, sizeof(Claw2), "models/zombie_thehero/claw/%s", Claw)
		
		set_pev(id, pev_viewmodel2, Claw2)
		set_pev(id, pev_weaponmodel2, "")
	} else if(Get_BitVar(g_IsZombie, id)) {
		if(CSWID == CSW_KNIFE || CSWID == CSW_HEGRENADE || CSWID == CSW_FLASHBANG || CSWID == CSW_SMOKEGRENADE)
			return
			
		engclient_cmd(id, "weapon_knife")
	}
}

public Event_RoundStart()
{
	if(!g_Game_PlayAble || g_RoundEnd || g_Game_Start)
		return

	PlaySound(0, D_S_GameStart)
	
	Start_Countdown()
	set_task(get_cvar_float("mp_roundtime") * 60.0, "Event_TimeOut", TASK_GAMETIME)
	
	ExecuteForward(g_Forward[FWD_ROUND_START], g_fwResult)
}

public Event_RoundEnd()
{
	if(!g_Game_PlayAble || !g_Game_Start)
		return	
	
	g_RoundEnd = 1
	g_Game_Start = 0
	
	remove_task(TASK_GAMETIME)
	
	// Update Score
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		if(is_user_alive(i))
		{
			if(!Get_BitVar(g_IsZombie, i)) UpdateFrags(i, 0, 2, 0, 1)
			else UpdateFrags(i, 0, 1, 0, 1)
		}
	}
}

public Event_GameRestart()
{
	g_RoundEnd = 1
	g_Game_Start = 0
	
	remove_task(TASK_GAMETIME)
	ExecuteForward(g_Forward[FWD_ROUND_END], g_fwResult, WIN_ALL)
}

public Event_TimeOut()
{
	TerminateRound(TEAM_HUMAN)
}

public Event_Time()
{
	if(!g_Game_PlayAble && GetPlayerCount(0) >= MIN_PLAYER)
	{
		g_Game_PlayAble = 1
		TerminateRound(TEAM_START)
	}
	
	// Loop
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(!is_user_alive(i))
			continue
			
		Show_EvolHud(i)
		ExecuteForward(g_Forward[FWD_SKILL_SHOW], g_fwResult, i, Get_BitVar(g_IsZombie, i) ? 1 : 0)
	}
	
	Show_Scorehud()
	Check_Gameplay()
	
	// Exec
	ExecuteForward(g_Forward[FWD_TIME_CHANGE], g_fwResult)
}

public Start_Countdown()
{
	g_Countdown = D_Countdown_Time
	CountingDown()
}

public CountingDown()
{
	if(!g_Game_PlayAble || g_RoundEnd || g_Game_Start)
		return

	if(g_Countdown <= 0)
	{
		Start_Game_Now()
		return
	}
	
	client_print(0, print_center, "%L", LANG_OFFICIAL, "GAME_COUNTDOWN", g_Countdown)
		
	if(g_Countdown <= 10)
	{
		static Sound[64]; format(Sound, charsmax(Sound), D_S_GameCount, g_Countdown)
		PlaySound(0, Sound)
	} 
	
	g_Countdown--
	set_task(1.0, "CountingDown", TASK_COUNTDOWN)
}

public Start_Game_Now()
{
	if(GetPlayerCount(0) < 2)
	{
		g_Game_PlayAble = 0
		g_RoundEnd = 0
		g_Game_Start = 0
		
		return
	}
	
	g_Game_PlayAble = 1
	g_Game_Start = 1
	g_RoundEnd = 0
	
	// Game Start Handle
	static TotalPlayer, Required_Zombie, Required_Hero; TotalPlayer = Required_Zombie = Required_Hero = 0
	TotalPlayer = GetPlayerCount(1)
	
	switch(TotalPlayer)
	{
		case 0..7: {
			Required_Zombie = 1; Required_Hero = 0; }
		case 8..10: {
			Required_Zombie = 1; Required_Hero = 1; }
		case 11..15: {
			Required_Zombie = 2; Required_Hero = 1; }
		case 16..20: {
			Required_Zombie = 2; Required_Hero = 2; }
		case 21..25: {
			Required_Zombie = 2; Required_Hero = 2; }
		case 26..29: {
			Required_Zombie = 3; Required_Hero = 2; }
		case 30..32: {
			Required_Zombie = 3; Required_Hero = 3; }
		default: {
			Required_Zombie = 2; Required_Hero = 1; }
	}
	
	for(new i = 0; i < Required_Zombie; i++) set_user_zombie(GetRandomPlayer(), -1, 1, 0)
	
	static HeroText[64], Name[32], NameList[80], Id, SingleHero;
	if(Required_Hero > 1) SingleHero = 0
	else SingleHero = 1
	
	for(new i = 0; i < Required_Hero; i++) 
	{
		Id = GetRandomPlayer()
		set_user_hero(Id)
		
		get_user_name(Id, Name, sizeof(Name))
		if(SingleHero) 
		{
			formatex(HeroText, sizeof(HeroText), "%L", LANG_OFFICIAL, "HERO_BECOME_SINGLE", Name)
			formatex(NameList, sizeof(NameList), "%s", Name)
		} else {
			if(i == 0) formatex(NameList, sizeof(NameList), "%s", Name)
			else formatex(NameList, sizeof(NameList), "%s, %s", NameList, Name)
		}
	}

	if(Required_Hero > 0)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i))
				continue
			if(!Get_BitVar(g_BecomeHero, i))
				continue
			if(Get_BitVar(g_IsZombie, i))
				continue
				
			set_user_hero(i)
	
			get_user_name(i, Name, sizeof(Name))
			if(!SingleHero) formatex(NameList, sizeof(NameList), "%s, %s", NameList, Name)
			
			UnSet_BitVar(g_BecomeHero, i)
		}
		
		formatex(HeroText, sizeof(HeroText), "%L", LANG_OFFICIAL, "HERO_BECOME_MULTI", NameList)
		client_print(0, print_center, HeroText)
	}
	
	// Notify Play Ambience Sound
	PlaySound(0, D_S_Ambience)
	
	// Exec
	ExecuteForward(g_Forward[FWD_GAME_START], g_fwResult)
}

public Show_Scorehud()
{
	static ScoreHud[80]
	
	formatex(ScoreHud, sizeof(ScoreHud), "%L", LANG_OFFICIAL, "GAME_SCOREHUD1", g_Round)
	set_dhudmessage(250, 250, 250, SCORE_HUD_X, SCORE_HUD_Y, 0, 2.0, 2.0)
	show_dhudmessage(0, ScoreHud)
	
	formatex(ScoreHud, sizeof(ScoreHud), "%L", LANG_OFFICIAL, "GAME_SCOREHUD2", g_TeamScore[TEAM_ZOMBIE], g_TeamScore[TEAM_HUMAN])
	set_hudmessage(250, 250, 250, SCORE_HUD_X, SCORE_HUD_Y, 0, 2.0, 2.0)
	ShowSyncHudMsg(0, g_SyncHud_Score, ScoreHud)
}

public Show_EvolHud(id)
{
	if(is_user_bot(id))
		return
		
	// Get Damage Percent
	static DamagePercent, PowerUp[32], PowerDown[32], FullText[88]
	
	formatex(PowerUp, sizeof(PowerUp), "")
	formatex(PowerDown, sizeof(PowerDown), "")
	
	if(!Get_BitVar(g_IsZombie, id))
	{
		set_dhudmessage(get_color_level(id, 0), get_color_level(id, 1), get_color_level(id, 2), -1.0, 0.83, 0, 1.5, 1.5)
		
		// Calc
		DamagePercent = floatround(g_fDamageMulti[g_Level[id]] * 100.0)
		
		for(new i = 0; i < g_Level[id]; i++)
			formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
		for(new i = g_MyMaxLevel[id]; i > g_Level[id]; i--)
			formatex(PowerDown, sizeof(PowerDown), "%s  ", PowerDown)

		formatex(FullText, sizeof(FullText), "%L: %i%%^n[%s%s]", LANG_OFFICIAL, "HUD_EVOL_HUMAN", DamagePercent, PowerUp, PowerDown)
		show_dhudmessage(id, FullText)
	} else if(Get_BitVar(g_IsZombie, id)) {
		// Show Hud
		set_dhudmessage(200, 200, 0, -1.0, 0.83, 0, 1.5, 1.5)
		
		DamagePercent = g_Level[id]
		
		for(new Float:i = 0.0; i < g_Evolution[id]; i += 0.5)
			formatex(PowerUp, sizeof(PowerUp), "%s|", PowerUp)
		for(new Float:i = 10.0; i > g_Evolution[id]; i -= 0.5)
			formatex(PowerDown, sizeof(PowerDown), "%s ", PowerDown)
			
		formatex(FullText, sizeof(FullText), "%L: %i^n[%s%s]", LANG_OFFICIAL, "HUD_EVOL_ZOMBIE", DamagePercent, PowerUp, PowerDown)
		show_dhudmessage(id, FullText)
	}
}

public set_user_zombie(id, attacker, Origin_Zombie, Respawn)
{	
	static IsHero; IsHero = Get_BitVar(g_IsHero, id)
	static OldClass; OldClass = -1
	
	if(!is_user_connected(attacker) && Respawn) OldClass = g_ZombieClass[id]
	ResetPlayer(id, 0, 1)
	
	Set_BitVar(g_IsZombie, id)
	Set_BitVar(g_CanChooseClass, id)
	UnSet_BitVar(g_IsHero, id)
	g_ZombieClass[id] = !is_user_bot(id) ? 0 : random_num(0, g_ZombieClass_Count - 1)
	if(Origin_Zombie) Set_BitVar(g_ZombieOrigin, id)
	g_Level[id] = (Origin_Zombie == 1) ? 2 : 1
	
	if(Respawn) g_ZombieClass[id] = OldClass
	else {
		if(!is_user_bot(id)) menu_display(id, g_Menu_ZombieClass)
		else Active_ZombieClass(id, g_ZombieClass[id])
	}
	
	if(!Respawn) ExecuteForward(g_Forward[FWD_USER_INFECT], g_fwResult, id, attacker, 1)
	
	if(is_user_connected(attacker))
	{
		// Reward frags, deaths, health, and ammo packs
		SendDeathMsg(attacker, id)
		UpdateFrags(attacker, id, 1, 1, 1)
	
		// Play Infection Sound
		static DeathSound[64]
		if(!Get_BitVar(g_PlayerSex, id)) ArrayGetString(D_S_HumanMale_Death, Get_RandomArray(D_S_HumanMale_Death), DeathSound, sizeof(DeathSound))
		else ArrayGetString(D_S_HumanFemale_Death, Get_RandomArray(D_S_HumanFemale_Death), DeathSound, sizeof(DeathSound))
	
		EmitSound(id, CHAN_BODY, DeathSound)	
		
		// Evolution Handle
		if(IsHero)
		{	
			if(g_Level[attacker] == 1) g_Evolution[attacker] += 10.0
			else if(g_Level[attacker] == 2) g_Evolution[attacker] += 5.0
		} else {
			if (g_Level[attacker] == 1) g_Evolution[attacker] += 4.0
			else if (g_Level[attacker] == 2) g_Evolution[attacker] += 2.0
		}
		UpdateLevelZombie(attacker, 0)
		
		cs_set_user_money(id, cs_get_user_money(id) + random_num(150, 300))
	}	
	
	// Set User Team
	SetPlayerTeam(id, TEAM_ZOMBIE)
	
	// Set Speed
	SetPlayerSpeed(id, ArrayGetCell(zombie_speed, g_ZombieClass[id]))
	
	static StartHealth; 
	StartHealth = g_MaxHealth[id]
	
	// Check
	if(Origin_Zombie)
	{
		if(!Respawn) StartHealth = clamp((clamp(GetPlayerCount(1), 1, 32) / clamp(GetZombieCount(2), 1, 32)) * 1000, D_ZombieMinStartHealth, D_ZombieMaxStartHealth)
		else StartHealth = clamp((StartHealth / 100) * (100 - D_ZombieHealthRespawnReduce), D_ZombieMinHealth, D_ZombieMaxHealth)
	} else {
		if(!Respawn)
		{
			g_Evolution[id] = 0.0
			
			if(is_user_connected(attacker)) 
			{
				StartHealth =  clamp(native_get_maxhealth(attacker) / 2, D_ZombieMinHealth, D_ZombieMaxHealth)
			} else {
				StartHealth = clamp((clamp(GetPlayerCount(1), 1, 32) / clamp(GetZombieCount(2), 1, 32)) * 1000, D_ZombieMinStartHealth, D_ZombieMaxStartHealth)
			}
		} else {
			StartHealth = clamp((StartHealth / 100) * (100 - D_ZombieHealthRespawnReduce), D_ZombieMinHealth, D_ZombieMaxHealth)
		}	
	}

	// Set Health & Gravity
	SetPlayerHealth(id, StartHealth, 1)
	client_printc(id, "!g[%s]!n Your Health: %i", GAMENAME, StartHealth)	
	set_pev(id, pev_gravity, Float:ArrayGetCell(zombie_gravity, g_ZombieClass[id]))
	
	// Zombie Coming Sound
	if(GetZombieCount(1) > 0)
	{
		if(get_gametime() - 1.0 > NoticeSoundTime)
		{
			static Sound[64]
			if(!Respawn)
			{
				ArrayGetString(D_S_ZombieComing, Get_RandomArray(D_S_ZombieComing), Sound, sizeof(Sound))
				PlaySound(0, Sound)
			} else {
				ArrayGetString(D_S_ZombieComeBack, Get_RandomArray(D_S_ZombieComeBack), Sound, sizeof(Sound))
				PlaySound(0, Sound)
			}
			
			NoticeSoundTime = get_gametime()
		}
	}
	
	// Set User Model
	static Model[64]
	ArrayGetString(Get_BitVar(g_ZombieOrigin, id) ? zombie_model_origin : zombie_model_host, g_ZombieClass[id], Model, sizeof(Model))
	SetPlayerModel(id, Model, 0)
	
	// Bug Fix
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	cs_set_user_armor(id, 0, CS_ARMOR_NONE)
	fm_set_user_rendering(id)
	
	set_scoreboard_attrib(id, 0)
	
	// Strip zombies from guns and give them a knife
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")	
	
	// Play Draw Animation
	set_weapon_anim(id, 3)
	
	// Show Menu Class
	if(!Respawn) 
	{
		if(pev_valid(id) == PDATA_SAFE) set_pdata_int(id, 205, 0, OFFSET_LINUX)
		menu_display(id, g_Menu_ZombieClass, 0)
		set_task(float(D_ZombieClass_ChangeTime), "Disable_ClassChange", id+TASK_CHANGECLASS)
	}
	
	// NVG
	Set_Zombie_NVG(id, 1, 1, 0, 0)
	
	// Make Some Blood
	if(!Respawn)
	{
		static Float:Origin[3]; pev(id, pev_origin, Origin); Origin[2] += 16.0
		MakeBlood(Origin)
	}
	
	// Turn Off the FlashLight
	if (pev(id, pev_effects) & EF_DIMLIGHT) set_pev(id, pev_impulse, 100)
	else set_pev(id, pev_impulse, 0)	

	// Exec
	ExecuteForward(g_Forward[FWD_USER_INFECTED], g_fwResult, id, attacker, is_user_connected(attacker) ? 1 : 0)
	ExecuteForward(g_Forward[FWD_CLASS_ACTIVE], g_fwResult, id, g_ZombieClass[id])
	
	// Check GamePlay
	Check_Gameplay()
}

public set_user_hero(id)
{
	ResetPlayer(id, 0, 2)
	
	// Set Var
	Set_BitVar(g_IsHero, id)
	static HeroIne; HeroIne = Get_BitVar(g_PlayerSex, id)
	
	// Check Team
	if(GetPlayerTeam(id) != TEAM_HUMAN) SetPlayerTeam(id, TEAM_HUMAN)
	
	// Give NVG
	Set_Zombie_NVG(id, 1, 0, 0, 1)
	
	// Set Hero VIP
	set_scoreboard_attrib(id, 2)
	
	// Set Model
	if(!HeroIne) SetPlayerModel(id, D_HeroModel, 0)
	else SetPlayerModel(id, D_HeroIneModel, 0)
		
	// Notice
	set_dhudmessage(255, 255, 170, NOTICE_HUD_X, NOTICE_HUD_Y, 0, 4.0, 4.0)
	show_dhudmessage(id, "%L", LANG_OFFICIAL, !HeroIne ? "HERO_CHOOSEN_MALE" : "HERO_CHOOSEN_FEMALE")

	drop_weapons(id, 1)
	drop_weapons(id, 2)
	
	// Exec
	ExecuteForward(g_Forward[FWD_USER_HERO], g_fwResult, id, HeroIne)
}

public Set_Zombie_NVG(id, Give, On, OnSound, Ignored_HadNVG)
{
	if(Give) Set_BitVar(g_Had_NightVision, id)
	set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
}

public set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
{
	if(!Ignored_HadNVG)
	{
		if(!Get_BitVar(g_Had_NightVision, id))
			return
	}

	if(On) Set_BitVar(g_UsingNVG, id)
	else UnSet_BitVar(g_UsingNVG, id)
	
	if(OnSound) PlaySound(id, SoundNVG[On])
	set_user_nvision(id)
	
	ExecuteForward(g_Forward[FWD_USER_NVG], g_fwResult, id, On, Get_BitVar(g_IsZombie, id) ? 1 : 0)
	
	return
}

public set_user_nvision(id)
{	
	static Alpha
	if(Get_BitVar(g_UsingNVG, id)) Alpha = D_NVG_Alpha
	else Alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	if(Get_BitVar(g_IsZombie, id))
	{
		write_byte(D_NVG_ZombieColor[0]) // r
		write_byte(D_NVG_ZombieColor[1]) // g
		write_byte(D_NVG_ZombieColor[2]) // b
	} else if(!Get_BitVar(g_IsZombie, id) || Get_BitVar(g_IsHero, id)) {
		write_byte(D_NVG_HumanColor[0]) // r
		write_byte(D_NVG_HumanColor[1]) // g
		write_byte(D_NVG_HumanColor[2]) // b
	}
	write_byte(Alpha) // alpha
	message_end()

	if(Get_BitVar(g_UsingNVG, id)) SetPlayerLight(id, "#")
	else SetPlayerLight(id, D_GameLight)
}

public CMD_JoinTeam(id)
{
	if(!Get_BitVar(g_Joined, id))
		return PLUGIN_CONTINUE
		
	client_cmd(id, "ZBHeroEx_OpenShop")
		
	return PLUGIN_HANDLED
}

public CMD_NightVision(id)
{
	if(!Get_BitVar(g_Had_NightVision, id))
		return PLUGIN_HANDLED

	if(!Get_BitVar(g_UsingNVG, id)) set_user_nightvision(id, 1, 1, 0)
	else set_user_nightvision(id, 0, 1, 0)
	
	return PLUGIN_HANDLED;
}

public MakeBlood(const Float:Origin[3])
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

public Disable_ClassChange(id)
{
	id -= TASK_CHANGECLASS
	
	if(!is_user_alive(id))
		return
	if(!Get_BitVar(g_IsZombie, id))
		return
	if(!Get_BitVar(g_CanChooseClass, id))
		return

	UnSet_BitVar(g_CanChooseClass, id)
	menu_cancel(id)
}

public set_weapon_anim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_msgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("knife") // killer's weapon
	message_end()
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	if(is_user_connected(attacker))
	{
		// Set attacker frags
		set_pev(attacker, pev_frags, float(pev(attacker, pev_frags) + frags))
		
		// Update scoreboard with attacker and victim info
		if(scoreboard)
		{
			message_begin(MSG_BROADCAST, g_MsgScoreInfo)
			write_byte(attacker) // id
			write_short(pev(attacker, pev_frags)) // frags
			write_short(cs_get_user_deaths(attacker)) // deaths
			write_short(0) // class?
			write_short(fm_cs_get_user_team(attacker)) // team
			message_end()
		}
	}
	
	if(is_user_connected(victim))
	{
		// Set victim deaths
		fm_cs_set_user_deaths(victim, cs_get_user_deaths(victim) + deaths)
		
		// Update scoreboard with attacker and victim info
		if(scoreboard)
		{
			message_begin(MSG_BROADCAST, g_MsgScoreInfo)
			write_byte(victim) // id
			write_short(pev(victim, pev_frags)) // frags
			write_short(cs_get_user_deaths(victim)) // deaths
			write_short(0) // class?
			write_short(fm_cs_get_user_team(victim)) // team
			message_end()
		}
	}
}

public set_scoreboard_attrib(id, attrib) // 0 - Nothing; 1 - Dead; 2 - VIP
{
	message_begin(MSG_BROADCAST, g_msgScoreAttrib)
	write_byte(id) // id
	switch(attrib)
	{
		case 1: write_byte(1<<0)
		case 2: write_byte(1<<2)
		default: write_byte(0)
	}
	message_end()	
}

public CMD_Drop(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(Get_BitVar(g_IsHero, id))
		return PLUGIN_HANDLED
		
	if(Get_BitVar(g_IsZombie, id))
	{
		ExecuteForward(g_Forward[FWD_ZOMBIE_SKILL], g_fwResult, id, g_ZombieClass[id])
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public CMD_Hero(id)
{
	if(!is_user_alive(id))
		return PLUGIN_CONTINUE
	if(Get_BitVar(g_BecomeHero, id))
		return PLUGIN_CONTINUE
	
	Set_BitVar(g_BecomeHero, id)
	return PLUGIN_CONTINUE
}

public Check_Gameplay()
{
	if(!g_Game_PlayAble || g_RoundEnd || !g_Game_Start)
		return
	
	// Check Win
	static TotalCT, TotalT, RespawningZombie
	
	TotalCT = GetHumanCount(1)
	TotalT = GetZombieCount(1)
	RespawningZombie = GetRespawningZombie(1)
	
	if(TotalCT && !TotalT && !RespawningZombie) TerminateRound(TEAM_HUMAN)
	else if(!TotalCT && TotalT) TerminateRound(TEAM_ZOMBIE)
}

public Increase_TeamHumanATK()
{
	if(GetZombieCount(1) <= 0)
		return
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(Get_BitVar(g_IsZombie, i))
			continue
			
		Increase_HumanATK(i)
	}
}

public Increase_HumanATK(id)
{
	if(g_Level[id] >= g_MyMaxLevel[id])
		return
		
	g_Level[id]++
	
	remove_task(id+TASK_DELAY_MORALE_STAGE)
	set_task(random_float(0.1, 0.35), "Delay_InHmATK", id+TASK_DELAY_MORALE_STAGE)
	
	// Exec Forward
	ExecuteForward(g_Forward[FWD_USER_EVOLVED], g_fwResult, id, g_Level[id])
}

public Delay_InHmATK(id)
{
	id -= TASK_DELAY_MORALE_STAGE
	
	if(Get_BitVar(g_IsZombie, id))
		return
	
	static Color[3], szText[64]
	Color[0] = get_color_level(id, 0)
	Color[1] = get_color_level(id, 1)
	Color[2] = get_color_level(id, 2)		
	
	fm_set_user_rendering(id, kRenderFxGlowShell, Color[0], Color[1], Color[2], kRenderNormal, 0)
	
	format(szText, charsmax(szText), "%L", LANG_OFFICIAL, "EVOLUTION_HUMAN", floatround(g_fDamageMulti[g_Level[id]] * 100.0))
	set_dhudmessage(200, 200, 0, NOTICE_HUD_X, NOTICE_HUD_Y, 0, 5.0, 5.0)
	show_dhudmessage(id, szText)	
	
	PlaySound(id, D_S_HumanLevelUp)
}


public Check_Death(id)
{
	id -= TASK_REVIVE
	
	if(!g_Game_PlayAble || g_RoundEnd || !g_Game_Start)
		return
	if(!is_user_connected(id) || is_user_alive(id))
		return
	if(!Get_BitVar(g_IsZombie, id))
		return
	if(pev(id, pev_deadflag) != 2)
	{
		set_task(0.5, "Check_Death", id+TASK_REVIVE)
		return
	}

	// Do Handle Respawn
	// set_user_nightvision(id, 0, 0, 1)
	
	if(Get_BitVar(g_PlayerHeadShot, id))
	{
		UnSet_BitVar(g_Respawning, id)
		client_print(id, print_center, "%L", LANG_OFFICIAL, "RESPAWN_HEADSHOT")	
	} else {
		Set_BitVar(g_Respawning, id)
		g_RespawnTimeCount[id] = g_RespawnTime[id]

		// Make Effect
		static Float:fOrigin[3]
		pev(id, pev_origin, fOrigin)
		
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_SPRITE)
		engfunc(EngFunc_WriteCoord, fOrigin[0])
		engfunc(EngFunc_WriteCoord, fOrigin[1])
		engfunc(EngFunc_WriteCoord, fOrigin[2])
		write_short(D_ZombieRespawnIconId)
		write_byte(10)
		write_byte(255)
		message_end()
		
		// Check Respawn
		Start_Revive(id+TASK_REVIVE)
		
		return
	}
}

public Start_Revive(id)
{
	id -= TASK_REVIVE
	
	if(!g_Game_PlayAble || g_RoundEnd || !g_Game_Start)
		return
	if(!is_user_connected(id) || is_user_alive(id))
		return
	if(!Get_BitVar(g_Respawning, id))
		return
	if(g_RespawnTimeCount[id] <= 0.0)
	{
		Revive_Now(id+TASK_REVIVE)
		return
	}
		
	client_print(id, print_center, "%L", LANG_OFFICIAL, "RESPAWN_ING", g_RespawnTimeCount[id])
	
	g_RespawnTimeCount[id]--
	set_task(1.0, "Start_Revive", id+TASK_REVIVE)
}

public Revive_Now(id)
{
	id -= TASK_REVIVE
	
	if(!g_Game_PlayAble || g_RoundEnd || !g_Game_Start)
		return
	if(!is_user_connected(id) || is_user_alive(id))
		return
	if(!Get_BitVar(g_Respawning, id))
		return
		
	// Remove Task
	remove_task(id+TASK_REVIVE_EFFECT)
	UnSet_BitVar(g_Respawning, id)
	
	set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	ExecuteHamB(Ham_CS_RoundRespawn, id)
}

// ========================== MESSAGE =============================
// ================================================================
public Message_StatusIcon(msg_id, msg_dest, msg_entity)
{
	static szMsg[8];
	get_msg_arg_string(2, szMsg ,7)
	
	if(equal(szMsg, "buyzone") && get_msg_arg_int(1))
	{
		if(pev_valid(msg_entity) != PDATA_SAFE)
			return  PLUGIN_CONTINUE;
	
		set_pdata_int(msg_entity, 235, get_pdata_int(msg_entity, 235) & ~(1<<0))
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Message_TeamScore()
{
	static Team[2]
	get_msg_arg_string(1, Team, charsmax(Team))
	
	switch(Team[0])
	{
		// CT
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_HUMAN])
		// Terrorist
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_ZOMBIE])
	}
}

public Message_Health(msg_id, msg_dest, id)
{
	// Get player's health
	static health
	health = get_user_health(id)
	
	// Don't bother
	if(health < 1) 
		return
	
	static Float:NewHealth, RealHealth, Health
	
	NewHealth = (float(health) / float(g_MaxHealth[id])) * 100.0; 
	RealHealth = floatround(NewHealth)
	Health = clamp(RealHealth, 1, 255)
	
	set_msg_arg_int(1, get_msg_argtype(1), Health)
}

public Message_ClCorpse()
{
	static id; id = get_msg_arg_int(12)
	
	if(Get_BitVar(g_IsZombie, id) && !Get_BitVar(g_PlayerHeadShot, id))
		return PLUGIN_HANDLED

	return PLUGIN_CONTINUE
}

// ========================= FAKEMETA =============================
// ================================================================
public fw_GetGameDesc()
{
	forward_return(FMV_STRING, GAMENAME)
	return FMRES_SUPERCEDE
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;

	if(Get_BitVar(g_IsZombie, id))
	{
		static sound[64]
		
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't' ||
		sample[7] == 'h' && sample[8] == 'e' && sample[9] == 'a' && sample[10] == 'd')
		{
			ArrayGetString(random_num(0, 1) ? zombie_sound_hurt1 : zombie_sound_hurt2, g_ZombieClass[id], sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
		
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			ArrayGetString(random_num(0, 1) ? zombie_sound_death1 : zombie_sound_death2, g_ZombieClass[id], sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	
		// Zombie Attack
		static attack_type
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
			static sound[64]
			if (attack_type == 1) ArrayGetString(D_S_ZombieHitWall, Get_RandomArray(D_S_ZombieHitWall), sound, charsmax(sound))
			else if (attack_type == 2) ArrayGetString(D_S_ZombieAttack, Get_RandomArray(D_S_ZombieAttack), sound, charsmax(sound))
			else if (attack_type == 3) ArrayGetString(D_S_ZombieSwing, Get_RandomArray(D_S_ZombieSwing), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return
	if(Get_BitVar(g_IsZombie, id)) Zombie_RegenHealth(id)
}

public Zombie_RegenHealth(id)
{
	static Float:Velocity[3], Float:Length
	
	pev(id, pev_velocity, Velocity)
	Length = vector_length(Velocity)
	
	if(!Length)
	{
		if(!Get_BitVar(g_RestoringHealth, id))
		{
			if(get_gametime() - float(D_RestoreHealthStartTime) > g_RestoreTime[id])
			{
				Set_BitVar(g_RestoringHealth, id)
				g_RestoreTime[id] = get_gametime()
			}
		} else {
			if(get_gametime() - float(D_RestoreHealthTime) > g_RestoreTime[id])
			{
				static Float:StartHealth; StartHealth = float(g_MaxHealth[id])
				
				if(get_user_health(id) < floatround(StartHealth))
				{
					// get health add
					static health_add
					if (g_Level[id] > 1) health_add = D_RestoreHealthAmount_Origin
					else health_add = D_RestoreHealthAmount_Host
					
					// get health new
					static health_new; health_new = get_user_health(id) + health_add
					health_new = min(health_new, floatround(StartHealth))
					
					// set health
					SetPlayerHealth(id, health_new, 0)
					
					// play sound heal
					static sound_heal[64]
					ArrayGetString(zombie_sound_heal, g_ZombieClass[id], sound_heal, charsmax(sound_heal))
					PlaySound(id, sound_heal)
					
					if(!Get_BitVar(g_UsingNVG, id))
					{
						// Make a screen fade 
						message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
						write_short((1<<12) * 1) // duration
						write_short(0) // hold time
						write_short(0x0000) // fade type
						write_byte(0) // red
						write_byte(150) // green
						write_byte(0) // blue
						write_byte(50) // alpha
						message_end()
					}
				} else {
					UnSet_BitVar(g_RestoringHealth, id)
					g_RestoreTime[id] = 0.0
				}
				
				g_RestoreTime[id] = get_gametime()
			}
		}
	} else {
		UnSet_BitVar(g_RestoringHealth, id)
		g_RestoreTime[id] = get_gametime()
	}
}

// ============================= HAM ==============================
// ================================================================
public fw_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
	
	Set_BitVar(g_Joined, id)
	
	if(Get_BitVar(g_IsZombie, id))
	{
		if(g_Game_Start)
		{
			// Random Spawn
			Do_Random_Spawn(id)
		
			// Set Zombie
			set_user_zombie(id, -1, Get_BitVar(g_ZombieOrigin, id) ? 1 : 0, 1)
			
			// Exec
			ExecuteForward(g_Forward[FWD_USER_SPAWNED], g_fwResult, id, 1)
		}
		
		return
	}
	
	ResetPlayer(id, 0, 0)
	
	// Random Spawn
	Do_Random_Spawn(id)
	
	// Reset Light
	UnSet_BitVar(g_Had_NightVision, id)
	set_user_nightvision(id, 0, 0, 1)
	SetPlayerLight(id, D_GameLight)
	fm_set_user_rendering(id)
	
	// Set Player Data
	SetPlayerHealth(id, D_HumanHealth, 1)
	cs_set_user_armor(id, D_HumanArmor, CS_ARMOR_VESTHELM)
	ResetPlayerSpeed(id)
	
	// Set Player Team & Model
	SetPlayerTeam(id, TEAM_HUMAN)
	static PlayerModel[32]
	if(!Get_BitVar(g_PlayerSex, id)) ArrayGetString(D_HumanModel_Male, Get_RandomArray(D_HumanModel_Male), PlayerModel, sizeof(PlayerModel))
	else ArrayGetString(D_HumanModel_Female, Get_RandomArray(D_HumanModel_Female), PlayerModel, sizeof(PlayerModel))
	SetPlayerModel(id, PlayerModel, 0)
	
	// Start Weapon
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	fm_give_item(id, "weapon_usp")
	give_ammo(id, 1, CSW_USP)
	give_ammo(id, 1, CSW_USP)
	
	// Fade Out
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, {0,0,0}, id)
	write_short((5<<12))
	write_short((1<<12))
	write_short((0x0004))
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()	
	
	set_task(0.1, "Spawn_Delay_FadeOut", id)
	
	// Exec
	ExecuteForward(g_Forward[FWD_USER_SPAWNED], g_fwResult, id, 0)
}

public Spawn_Delay_FadeOut(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, {0,0,0}, id)
	write_short((5<<12))
	write_short((1<<12))
	write_short((0x0000))
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()	
}

// Ham Trace Attack Post Forward
public fw_TraceAttack_Post(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_alive(attacker))
		return
	if (!zbheroex_get_user_zombie(victim) || zbheroex_get_user_zombie(attacker))
		return
	if (!(damage_type & DMG_BULLET))
		return
	if (damage <= 0.0 || GetHamReturnStatus() == HAM_SUPERCEDE || get_tr2(tracehandle, TR_pHit) != victim)
		return
	
	if(cs_get_user_money(attacker) < 16000)
		cs_set_user_money(attacker, min(cs_get_user_money(attacker) + floatround(damage / 2.0), 16000))
	
	if(KNOCKBACK_TYPE == 1)
	{
		static ducking; ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
		if(ducking && KB_DUCKING == 0.0)
			return;
		
		static origin1[3], origin2[3]
		get_user_origin(victim, origin1)
		get_user_origin(attacker, origin2)
		
		if(get_distance(origin1, origin2) > KB_DISTANCE)
			return
		
		static Float:velocity[3]
		pev(victim, pev_velocity, velocity)
	
		if(KB_DAMAGE) xs_vec_mul_scalar(direction, damage, direction)
		static CSWID; CSWID = get_user_weapon(attacker)
		
		if(KB_POWER  && kb_weapon_power[CSWID] > 0.0) xs_vec_mul_scalar(direction, kb_weapon_power[CSWID], direction)
		if(ducking) xs_vec_mul_scalar(direction, KB_DUCKING, direction)
		
		if(KB_CLASS) xs_vec_mul_scalar(direction, ArrayGetCell(zombie_knockback, g_ZombieClass[victim]), direction)
		
		xs_vec_add(velocity, direction, direction)
		if(!KB_ZVEL) direction[2] = velocity[2]
		
		if(Get_BitVar(g_ZombieOrigin, victim)) xs_vec_mul_scalar(direction, 0.5, direction)
		
		// Set the knockback'd victim's velocity
		set_pev(victim, pev_velocity, direction)
	} else if(KNOCKBACK_TYPE == 2) {
		// Knockback
		static ducking; ducking = pev(victim, pev_flags) & (FL_DUCKING | FL_ONGROUND) == (FL_DUCKING | FL_ONGROUND)
	
		if(ducking) damage /= 1.25
		if(!(pev(victim, pev_flags) & FL_ONGROUND)) damage *= 2.0
	
		static Float:Origin[3]
		pev(attacker, pev_origin, Origin)
		
		static Float:classzb_knockback
		classzb_knockback = ArrayGetCell(zombie_knockback, g_ZombieClass[victim])
		
		if(Get_BitVar(g_ZombieOrigin, victim)) classzb_knockback /= 1.5
		hook_ent2(victim, Origin, damage, classzb_knockback, 2)
	}
}

public fw_TakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageType)
{
	if(!g_Game_Start)
		return HAM_SUPERCEDE
	if(Victim == Attacker)
		return HAM_IGNORED
	if(!is_user_alive(Attacker))
		return HAM_IGNORED
	
	if(Get_BitVar(g_IsZombie, Victim) && !Get_BitVar(g_IsZombie, Attacker)) // Human -> Zombie
	{
		if(DamageType & DMG_HEGRENADE) SetHamParamFloat(4, Damage * float(D_GrenadePower))
		else {
			Damage *= g_fDamageMulti[g_Level[Attacker]]
			
			// Zombie Victim Evolution Code Here!!!
			if(g_Level[Victim] < 3)
			{
				g_Evolution[Victim] += (g_Level[Victim] < 2) ? Damage / 2000.0 : Damage / 1000.0
				UpdateLevelZombie(Victim, 0)
			}
			
			// Set Damage
			SetHamParamFloat(4, Damage)
		}
	} else if(!Get_BitVar(g_IsZombie, Victim) && Get_BitVar(g_IsZombie, Attacker)) { // Zombie -> Human
		if(DamageType & DMG_HEGRENADE)
			return HAM_SUPERCEDE
		if(Damage <= 0.0)
			return HAM_IGNORED
			
		// Set Zombie
		set_user_zombie(Victim, Attacker, 0, 0)
		
		return HAM_SUPERCEDE
	}
	
	return HAM_HANDLED
}

public fw_UseStationary(entity, caller, activator, use_type)
{
	if (use_type == 2 && is_user_connected(caller) && (Get_BitVar(g_IsZombie, caller)))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == 0 && is_user_connected(caller) && (Get_BitVar(g_IsZombie, caller)))
	{
		// Reset Claws
		static Claw[32], Claw2[80];
		ArrayGetString(zombie_clawsmodel_origin, g_ZombieClass[caller], Claw, sizeof(Claw))
		formatex(Claw2, sizeof(Claw2), "models/zombie_thehero/claw/%s", Claw)
			
		set_pev(caller, pev_viewmodel2, Claw2)
		set_pev(caller, pev_weaponmodel2, "")	
	}
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_user_connected(id))
		return HAM_IGNORED
	if(Get_BitVar(g_IsZombie, id) || Get_BitVar(g_IsHero, id))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public UpdateLevelZombie(id, NoSetHealth)
{
	if(g_Level[id] > 2 || g_Level[id] < 1)
		return
	if(g_Evolution[id] < 10.0)
		return
	
	g_Evolution[id] = g_Level[id] < 3 ? 0.0 : 10.0
	if(g_Level[id] < 3) g_Level[id]++
	
	if(!NoSetHealth)
	{
		static NewHealth, NewArmor
		if(g_Level[id] == 2) 
		{
			NewHealth = clamp(D_ZombieHealthLv2, D_ZombieMinHealth, D_ZombieMaxHealth)
			NewArmor = D_ZombieArmorLv2
		} else if(g_Level[id] == 3) {
			NewHealth = clamp(D_ZombieHealthLv3, D_ZombieMinHealth, D_ZombieMaxHealth)
			NewArmor = D_ZombieArmorLv3
		}

		// Update Health & Armor
		SetPlayerHealth(id, NewHealth, 1)
		cs_set_user_armor(id, NewArmor, CS_ARMOR_KEVLAR)
	}
	
	Set_BitVar(g_ZombieOrigin, id)
	
	// Update Player Model
	static Model[80]
	ArrayGetString(zombie_model_origin, g_ZombieClass[id], Model, charsmax(Model))
	SetPlayerModel(id, Model, 0)
	
	// Play Evolution Sound
	static Sound[64]
	ArrayGetString(zombie_sound_evolution, g_ZombieClass[id], Sound, charsmax(Sound))
	EmitSound(id, CHAN_ITEM, Sound)
	
	// Reset Claws
	static Claw[32], Claw2[80];
	ArrayGetString(zombie_clawsmodel_origin, g_ZombieClass[id], Claw, sizeof(Claw))
	formatex(Claw2, sizeof(Claw2), "models/zombie_thehero/claw/%s", Claw)
		
	set_pev(id, pev_viewmodel2, Claw2)
	set_pev(id, pev_weaponmodel2, "")	
	
	SetPlayer_NextAttack(id, 0.75)
	set_weapon_anim(id, 3)
	
	// Show Hud
	static Text[80]
	formatex(Text, charsmax(Text), "%L", LANG_OFFICIAL, "EVOLUTION_ZOMBIE", g_Level[id])
	
	set_dhudmessage(0, 200, 0, NOTICE2_HUD_X, NOTICE2_HUD_Y, 2, 5.0, 5.0)
	show_dhudmessage(id, Text)
	
	// Exec Forward
	ExecuteForward(g_Forward[FWD_USER_EVOLVED], g_fwResult, id, g_Level[id])
}

// ======================== Function ==============================
// ================================================================
public SetPlayerModel(id, const Model[], ResetFirst)
{
	if(ResetFirst) ResetPlayerModel(id)
	
	GM_Set_PlayerModel(id, Model)
}

public ResetPlayerModel(id)
{
	GM_Reset_PlayerModel(id)
}

public give_ammo(id, silent, CSWID)
{
	static Amount, Name[32]
		
	switch(CSWID)
	{
		case CSW_P228: {Amount = 13; formatex(Name, sizeof(Name), "357sig");}
		case CSW_SCOUT: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_XM1014: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_MAC10: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_AUG: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_ELITE: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_FIVESEVEN: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
		case CSW_UMP45: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_SG550: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_GALIL: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_FAMAS: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_USP: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_GLOCK18: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_AWP: {Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
		case CSW_MP5NAVY: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_M249: {Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
		case CSW_M3: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_M4A1: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_TMP: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_G3SG1: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_DEAGLE: {Amount = 7; formatex(Name, sizeof(Name), "50ae");}
		case CSW_SG552: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_AK47: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_P90: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
	}
	
	if(!silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, Amount, Name, 254)
}

public SetPlayerSpeed(id, Float:Speed)
{
	GM_Set_PlayerSpeed(id, Speed, 1)
}

public ResetPlayerSpeed(id)
{
	GM_Reset_PlayerSpeed(id)
}

public SetPlayerHealth(id, Health, FullHealth)
{
	fm_set_user_health(id, Health)
	if(FullHealth) 
	{
		g_MaxHealth[id] = Health
		set_pev(id, pev_max_health, float(Health))
	}
}

public Do_Random_Spawn(id)
{
	if (!g_PlayerSpawn_Count)
		return;	
	
	static hull, sp_index, i
	
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	sp_index = random_num(0, g_PlayerSpawn_Count - 1)
	
	for (i = sp_index + 1; /*no condition*/; i++)
	{
		if(i >= g_PlayerSpawn_Count) i = 0
		
		if(is_hull_vacant(g_PlayerSpawn_Point[i], hull))
		{
			engfunc(EngFunc_SetOrigin, id, g_PlayerSpawn_Point[i])
			break
		}

		if (i == sp_index) break
	}
}

public SetPlayerTeam(id, Team)
{
	if(Team == TEAM_HUMAN) GM_Set_PlayerTeam(id, CS_TEAM_CT)
	else if(Team == TEAM_ZOMBIE) GM_Set_PlayerTeam(id, CS_TEAM_T)
}

public GetPlayerTeam(id)
{
	if(cs_get_user_team(id) == CS_TEAM_CT) return TEAM_HUMAN
	else if(cs_get_user_team(id) == CS_TEAM_T) return TEAM_ZOMBIE
	
	return 0
}

public ResetPlayer(id, Type, Special) // Special: 1 = Zombie | 2 = Hero | Type: 1 = New Player | 2 = Exit
{
	if(Type == 1) // New Player
	{
		remove_task(id+TASK_CHANGECLASS)
		remove_task(id+TASK_REVIVE)
		
		UnSet_BitVar(g_IsZombie, id)
		UnSet_BitVar(g_ZombieOrigin, id)
		UnSet_BitVar(g_IsHero, id)
		UnSet_BitVar(g_PlayerHeadShot, id)
		UnSet_BitVar(g_CanChooseClass, id)
		UnSet_BitVar(g_Had_NightVision, id)
		UnSet_BitVar(g_UsingNVG, id)
		UnSet_BitVar(g_RestoringHealth, id)
		UnSet_BitVar(g_Respawning, id)
		UnSet_BitVar(g_Joined, id)

		g_Level[id] = 0
		g_Evolution[id] = 0.0
		g_Time[id] = 0
		g_MyMaxLevel[id] = 10
		g_RespawnTime[id] = D_ZombieRespawnTime
		g_RespawnTimeCount[id] = 0
		
		static RandomNum; RandomNum = random_num(0, 100)
		if(RandomNum >= 80) Set_BitVar(g_PlayerSex, id)
		else UnSet_BitVar(g_PlayerSex, id)

		for(new i = 0; i < MAX_ZOMBIECLASS; i++)
			g_UnlockedClass[id][i] = 0
	} else if(Type == 2) { // Player Disconnect
		remove_task(id+TASK_CHANGECLASS)
		remove_task(id+TASK_REVIVE)
		
		UnSet_BitVar(g_IsZombie, id)
		UnSet_BitVar(g_ZombieOrigin, id)
		UnSet_BitVar(g_IsHero, id)
		UnSet_BitVar(g_PlayerHeadShot, id)
		UnSet_BitVar(g_CanChooseClass, id)
		UnSet_BitVar(g_Had_NightVision, id)
		UnSet_BitVar(g_UsingNVG, id)	
		UnSet_BitVar(g_RestoringHealth, id)
		UnSet_BitVar(g_Respawning, id)
		UnSet_BitVar(g_Joined, id)
		
		g_Level[id] = 0
		g_Evolution[id] = 0.0
		g_Time[id] = 0
		g_MyMaxLevel[id] = 0
		g_RespawnTime[id] = 0
		g_RespawnTimeCount[id] = 0
		
		for(new i = 0; i < MAX_ZOMBIECLASS; i++)
			g_UnlockedClass[id][i] = 0
	}
	
	if(Special == 1) // Reset As Zombie
	{
		remove_task(id+TASK_CHANGECLASS)
		remove_task(id+TASK_REVIVE)
		
		UnSet_BitVar(g_IsHero, id)
		UnSet_BitVar(g_PlayerHeadShot, id)
		UnSet_BitVar(g_CanChooseClass, id)
		UnSet_BitVar(g_Had_NightVision, id)
		UnSet_BitVar(g_UsingNVG, id)	
		UnSet_BitVar(g_RestoringHealth, id)
		
		g_Time[id] = 0
		g_RespawnTimeCount[id] = 0
	} else if(Special == 2) { // Reset As Hero
		remove_task(id+TASK_CHANGECLASS)	
		remove_task(id+TASK_REVIVE)
		
		UnSet_BitVar(g_IsZombie, id)
		UnSet_BitVar(g_ZombieOrigin, id)
		UnSet_BitVar(g_PlayerHeadShot, id)
		UnSet_BitVar(g_CanChooseClass, id)
		UnSet_BitVar(g_Had_NightVision, id)
		UnSet_BitVar(g_UsingNVG, id)	
		UnSet_BitVar(g_RestoringHealth, id)
		
		g_Time[id] = 0
		g_RespawnTimeCount[id] = 0
	} else { // Reset As Human
		remove_task(id+TASK_CHANGECLASS)
		remove_task(id+TASK_REVIVE)
		
		UnSet_BitVar(g_IsZombie, id)
		UnSet_BitVar(g_ZombieOrigin, id)
		UnSet_BitVar(g_IsHero, id)
		UnSet_BitVar(g_PlayerHeadShot, id)
		UnSet_BitVar(g_CanChooseClass, id)
		UnSet_BitVar(g_Had_NightVision, id)
		UnSet_BitVar(g_UsingNVG, id)		
		UnSet_BitVar(g_RestoringHealth, id)
		
		g_Level[id] = 0
		g_Evolution[id] = 0.0
		g_Time[id] = 0
		g_RespawnTimeCount[id] = 0
	}
}

public TerminateRound(Team)
{
	if(!g_Game_PlayAble || g_RoundEnd) return

	static EndSoundA, EndSound[64], EndTextA, EndText[64], Color[3], WinTeam
	EndSoundA = EndTextA = WinTeam = 0
	
	switch(Team)
	{
		case TEAM_START:
		{
			EndSoundA = 0
			GM_TerminateRound(5.0, WINSTATUS_DRAW)
			
			WinTeam = WIN_ALL
		}
		case TEAM_HUMAN:
		{
			EndSoundA = 1
			EndSound = D_S_HumanWin
			
			EndTextA = 1
			Color[0] = 42; Color[1] = 170; Color[2] = 255
			formatex(EndText, sizeof(EndText), "%L", LANG_OFFICIAL, "WIN_HUMAN")
			
			GM_TerminateRound(5.0, WINSTATUS_CT)
			
			WinTeam = WIN_HUMAN
			g_TeamScore[TEAM_HUMAN]++
		}
		case TEAM_ZOMBIE:
		{
			EndSoundA = 1
			EndSound = D_S_ZombieWin
			
			EndTextA = 1
			Color[0] = 200; Color[1] = 25; Color[2] = 25
			formatex(EndText, sizeof(EndText), "%L", LANG_OFFICIAL, "WIN_ZOMBIE")
			
			GM_TerminateRound(5.0, WINSTATUS_TERRORIST)
			
			WinTeam = WIN_ZOMBIE
			g_TeamScore[TEAM_ZOMBIE]++
		}
	}
	
	// Remove Task
	remove_task(TASK_COUNTDOWN)
	
	// Play EndSound
	StopSound(0)
	if(EndSoundA) PlaySound(0, EndSound)
	
	// Show Hud
	if(EndTextA)
	{
		set_dhudmessage(Color[0], Color[1], Color[2], NOTICE_HUD_X, NOTICE_HUD_Y, 0, 4.0, 4.0)
		show_dhudmessage(0, EndText)
	}
	
	g_RoundEnd = 1
	g_Round++
	
	// Exec
	ExecuteForward(g_Forward[FWD_ROUND_END], g_fwResult, WinTeam)
}

public LoadnPre_ConfigFile()
{
	static i, BufferA[64], BufferB[128]
	
	// Gameplay
	amx_load_setting_string(SETTING_FILE, "Gameplay", "GAME_LIGHT", D_GameLight, sizeof(D_GameLight))
	D_Countdown_Time = amx_load_setting_int(SETTING_FILE, "Gameplay", "COUNTDOWN_TIME")
	D_GrenadePower = amx_load_setting_int(SETTING_FILE, "Gameplay", "GRENADE_POWER")
	D_ZombieClass_ChangeTime = amx_load_setting_int(SETTING_FILE, "Gameplay", "ZOMBIECLASS_CHANGETIME")

	// Human
	D_HumanHealth = amx_load_setting_int(SETTING_FILE, "Human", "HUMAN_HEALTH")
	D_HumanArmor = amx_load_setting_int(SETTING_FILE, "Human", "HUMAN_ARMOR")
	amx_load_setting_string_arr(SETTING_FILE, "Human", "HUMAN_MODEL_MALE", D_HumanModel_Male)
	for(i = 0; i < ArraySize(D_HumanModel_Male); i++) {
		ArrayGetString(D_HumanModel_Male, i, BufferA, sizeof(BufferA)); formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", BufferA, BufferA)
		engfunc(EngFunc_PrecacheModel, BufferB); }
	amx_load_setting_string_arr(SETTING_FILE, "Human", "HUMAN_MODEL_FEMALE", D_HumanModel_Female)
	for(i = 0; i < ArraySize(D_HumanModel_Female); i++) {
		ArrayGetString(D_HumanModel_Female, i, BufferA, sizeof(BufferA)); formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", BufferA, BufferA)
		engfunc(EngFunc_PrecacheModel, BufferB); }
	
	// Zombie
	D_ZombieMaxStartHealth = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_RANDOM_MAX")
	D_ZombieMinStartHealth = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_RANDOM_MIN") 
	D_ZombieMaxHealth = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_MAX")
	D_ZombieMinHealth = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_MIN")
	
	D_ZombieHealthLv2 = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_LV2")
	D_ZombieArmorLv2 = amx_load_setting_int(SETTING_FILE, "Zombie", "ARMOR_ZOMBIE_LV2")
	D_ZombieHealthLv3 = amx_load_setting_int(SETTING_FILE, "Zombie", "HEALTH_ZOMBIE_LV3")
	D_ZombieArmorLv3 = amx_load_setting_int(SETTING_FILE, "Zombie", "ARMOR_ZOMBIE_LV3")
	
	D_ZombieRespawnTime = amx_load_setting_int(SETTING_FILE, "Zombie", "ZOMBIE_RESPAWN_TIME")
	amx_load_setting_string(SETTING_FILE, "Zombie", "ZOMBIE_RESPAWN_SPR", D_ZombieRespawnIcon, sizeof(D_ZombieRespawnIcon)); D_ZombieRespawnIconId = engfunc(EngFunc_PrecacheModel, D_ZombieRespawnIcon)
	D_ZombieHealthRespawnReduce = amx_load_setting_int(SETTING_FILE, "Zombie", "ZOMBIE_RESPAWN_HEALTH_REDUCE_PERCENT")

	// Hero
	amx_load_setting_string(SETTING_FILE, "Hero", "HERO_MODEL", D_HeroModel, sizeof(D_HeroModel))
	amx_load_setting_string(SETTING_FILE, "Hero", "HEROINE_MODEL", D_HeroIneModel, sizeof(D_HeroIneModel))
	
	formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", D_HeroModel, D_HeroModel); engfunc(EngFunc_PrecacheModel, BufferB)
	formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", D_HeroIneModel, D_HeroIneModel); engfunc(EngFunc_PrecacheModel, BufferB)
	
	// Health Restore
	D_RestoreHealthStartTime = amx_load_setting_int(SETTING_FILE, "Restore Health", "RESTORE_HEALTH_STARTTIME")
	D_RestoreHealthTime = amx_load_setting_int(SETTING_FILE, "Restore Health", "RESTORE_HEALTH_TIME")
	D_RestoreHealthAmount_Host = amx_load_setting_int(SETTING_FILE, "Restore Health", "RESTORE_HEALTH_AMOUNT_HOST")
	D_RestoreHealthAmount_Origin = amx_load_setting_int(SETTING_FILE, "Restore Health", "RESTORE_HEALTH_AMOUNT_ORIGIN")
	
	// Sound
	amx_load_setting_string(SETTING_FILE, "Sounds", "AMBIENCE", D_S_Ambience, sizeof(D_S_Ambience)); engfunc(EngFunc_PrecacheSound, D_S_Ambience)
	amx_load_setting_string(SETTING_FILE, "Sounds", "WIN_HUMAN", D_S_HumanWin, sizeof(D_S_HumanWin)); engfunc(EngFunc_PrecacheSound, D_S_HumanWin)
	amx_load_setting_string(SETTING_FILE, "Sounds", "WIN_ZOMBIE", D_S_ZombieWin, sizeof(D_S_ZombieWin)); engfunc(EngFunc_PrecacheSound, D_S_ZombieWin)
	amx_load_setting_string(SETTING_FILE, "Sounds", "GAME_START", D_S_GameStart, sizeof( D_S_GameStart)); engfunc(EngFunc_PrecacheSound, D_S_GameStart)
	amx_load_setting_string(SETTING_FILE, "Sounds", "GAME_COUNT", D_S_GameCount, sizeof(D_S_GameCount)); 
	for (new i = 1; i <= 10; i++) {
		format(BufferB, charsmax(BufferB), D_S_GameCount, i); engfunc(EngFunc_PrecacheSound, BufferB); }	

	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "ZOMBIE_COMING", D_S_ZombieComing)
	for(i = 0; i < ArraySize(D_S_ZombieComing); i++) {
		ArrayGetString(D_S_ZombieComing, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "ZOMBIE_COMEBACK", D_S_ZombieComeBack)
	for(i = 0; i < ArraySize(D_S_ZombieComeBack); i++) {
		ArrayGetString(D_S_ZombieComeBack, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "ZOMBIE_ATTACK", D_S_ZombieAttack)
	for(i = 0; i < ArraySize(D_S_ZombieAttack); i++) {
		ArrayGetString(D_S_ZombieAttack, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "ZOMBIE_HITWALL", D_S_ZombieHitWall)
	for(i = 0; i < ArraySize(D_S_ZombieHitWall); i++) {
		ArrayGetString(D_S_ZombieHitWall, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "ZOMBIE_SWING", D_S_ZombieSwing)
	for(i = 0; i < ArraySize(D_S_ZombieSwing); i++) {
		ArrayGetString(D_S_ZombieSwing, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "MALE_DEATH", D_S_HumanMale_Death)
	for(i = 0; i < ArraySize(D_S_HumanMale_Death); i++) {
		ArrayGetString(D_S_HumanMale_Death, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string_arr(SETTING_FILE, "Sounds", "FEMALE_DEATH", D_S_HumanFemale_Death)	
	for(i = 0; i < ArraySize(D_S_HumanFemale_Death); i++) {
		ArrayGetString(D_S_HumanFemale_Death, i, BufferB, sizeof(BufferB))
		engfunc(EngFunc_PrecacheSound, BufferB); }	
	amx_load_setting_string(SETTING_FILE, "Sounds", "HUMAN_LEVELUP", D_S_HumanLevelUp, sizeof(D_S_HumanLevelUp)); engfunc(EngFunc_PrecacheSound, D_S_HumanLevelUp)
		
	// Weather
	D_EnaRain = amx_load_setting_int(SETTING_FILE, "Weather Effects", "RAIN")
	D_EnaSnow = amx_load_setting_int(SETTING_FILE, "Weather Effects", "SNOW")
	D_EnaFog = amx_load_setting_int(SETTING_FILE, "Weather Effects", "FOG")
	amx_load_setting_string(SETTING_FILE, "Weather Effects", "FOG_DENSITY", D_FogDensity, sizeof(D_FogDensity))
	amx_load_setting_string(SETTING_FILE, "Weather Effects", "FOG_COLOR", D_FogColor, sizeof(D_FogColor))
	
	// Weather & Sky
	if(D_EnaRain) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if(D_EnaSnow) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))	
	if(D_EnaFog)
	{
		remove_entity_name("env_fog")
		
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", D_FogDensity, "env_fog")
			fm_set_kvd(ent, "rendercolor", D_FogColor, "env_fog")
		}
	}	
	
	// Sky
	D_EnaCusSky = amx_load_setting_int(SETTING_FILE, "Skies", "CUSTOM_SKY")
	amx_load_setting_string_arr(SETTING_FILE, "Skies", "SKY_NAMES", D_SkyName)
	
	for(i = 0; i < ArraySize(D_SkyName); i++)
	{
		ArrayGetString(D_SkyName, i, BufferA, charsmax(BufferA)); 
		
		// Preache custom sky files
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sbk.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sdn.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sft.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%slf.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%srt.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sup.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)		
	}	
	
	// NightVision
	const MAX = 10
	static Buffer[16], Buffer2[3][MAX]
	
	D_NVG_Alpha = amx_load_setting_int(SETTING_FILE, "Night Vision", "NVG_ALPHA")
	
	amx_load_setting_string(SETTING_FILE, "Night Vision", "NVG_HUMAN_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], MAX, Buffer2[1], MAX, Buffer2[2], MAX)
	D_NVG_HumanColor[0] = str_to_num(Buffer2[0])
	D_NVG_HumanColor[1] = str_to_num(Buffer2[1])
	D_NVG_HumanColor[2] = str_to_num(Buffer2[2])
	
	amx_load_setting_string(SETTING_FILE, "Night Vision", "NVG_ZOMBIE_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], MAX, Buffer2[1], MAX, Buffer2[2], MAX)
	D_NVG_ZombieColor[0] = str_to_num(Buffer2[0])
	D_NVG_ZombieColor[1] = str_to_num(Buffer2[1])
	D_NVG_ZombieColor[2] = str_to_num(Buffer2[2])	
}

// ========================== STOCK ===============================
// ================================================================
// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
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
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

stock get_color_level(id, num)
{
	static color[3]
	switch (g_Level[id])
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
	
	return color[num]
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

stock SetPlayer_NextAttack(id, Float:Time)
{
	if(pev_valid(id) != PDATA_SAFE)
		return
		
	set_pdata_float(id, 83, Time, 5)
}

stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")

	if(!index)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_connected(i))
				continue
				
			message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, i);
			write_byte(i);
			write_string(szMsg);
			message_end();	
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 

// Get User Team
stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return 0;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX)
}

stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSDEATHS, value, OFFSET_LINUX)
}

stock SetPlayerLight(id, const LightStyle[])
{
	if(id != 0)
	{
		message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
		write_byte(0)
		write_string(LightStyle)
		message_end()		
	} else {
		message_begin(MSG_BROADCAST, SVC_LIGHTSTYLE)
		write_byte(0)
		write_string(LightStyle)
		message_end()	
	}
}

stock collect_spawns_ent(const classname[])
{
	static ent; ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		static Float:originF[3]
		pev(ent, pev_origin, originF)
		
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][0] = originF[0]
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][1] = originF[1]
		g_PlayerSpawn_Point[g_PlayerSpawn_Count][2] = originF[2]
		
		// increase spawn count
		g_PlayerSpawn_Count++
		if(g_PlayerSpawn_Count >= sizeof g_PlayerSpawn_Point) break;
	}
}

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
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

stock amx_load_setting_string_arr(const filename[], const setting_section[], setting_key[], Array:array_handle)
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
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[ZBHeroEX] Array not initialized")
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
	new key[64], values[1024], current_value[128]
	
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
		
		// Get key and values
		strtok(linedata, key, charsmax(key), values, charsmax(values), '=')
		
		// Trim spaces
		trim(key)
		trim(values)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			// Parse values
			while (values[0] != 0 && strtok(values, current_value, charsmax(current_value), values, charsmax(values), ','))
			{
				// Trim spaces
				trim(current_value)
				trim(values)
				
				// Add to array
				ArrayPushString(array_handle, current_value)
			}
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

stock amx_load_setting_string(const filename[], const setting_section[], setting_key[], return_string[], string_size)
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
	new key[64], current_value[128]
	
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
			formatex(return_string, string_size, "%s", current_value)
			
			// Values succesfully retrieved
			fclose(file)
			return true;
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}

stock is_hull_vacant(Float:Origin[3], hull)
{
	engfunc(EngFunc_TraceHull, Origin, Origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id) client_cmd(id, "mp3 stop; stopsound")
stock EmitSound(id, Channel, const Sound[]) emit_sound(id, Channel, Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)

stock GetPlayerCount(Alive)
{
	static PlayerNum, id; PlayerNum = id = 0
	
	for(id = 1; id <= g_MaxPlayers; id++)
	{
		if(Alive)
		{
			if(is_user_alive(id) && (cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T))
				PlayerNum++
		} else {
			if(is_user_connected(id) && (cs_get_user_team(id) == CS_TEAM_CT || cs_get_user_team(id) == CS_TEAM_T))
				PlayerNum++
		}
	}

	return PlayerNum
}

stock GetZombieCount(Alive) // Alive: 0 - Death, 1 - Alive, 2 - Both | 
{
	static iZombies, id; iZombies = id = 0
	
	for(id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue
		
		if(Alive == 1)
		{
			if(is_user_alive(id) && Get_BitVar(g_IsZombie, id))
				iZombies++
		} else if(Alive == 2){
			if(Get_BitVar(g_IsZombie, id))
				iZombies++
		} else {
			if(!is_user_alive(id) && Get_BitVar(g_IsZombie, id))
				iZombies++
		}
		
		/*
		if(Respawning == 1)
		{
			if(Alive == 1)
			{
				if(is_user_alive(id) && Get_BitVar(g_IsZombie, id) && Get_BitVar(g_Respawning, id))
					iZombies++
			} else if(Alive == 2){
				if(Get_BitVar(g_IsZombie, id) && Get_BitVar(g_Respawning, id))
					iZombies++
			} else {
				if(!is_user_alive(id) && Get_BitVar(g_IsZombie, id) && Get_BitVar(g_Respawning, id))
					iZombies++
			}
		} else if(Respawning == 2) {
			if(Alive == 1)
			{
				if(is_user_alive(id) && Get_BitVar(g_IsZombie, id))
					iZombies++
			} else if(Alive == 2){
				if(Get_BitVar(g_IsZombie, id))
					iZombies++
			} else {
				if(!is_user_alive(id) && Get_BitVar(g_IsZombie, id))
					iZombies++
			}
		} else {
			if(Alive == 1)
			{
				if(is_user_alive(id) && Get_BitVar(g_IsZombie, id) && !Get_BitVar(g_Respawning, id))
					iZombies++
			} else if(Alive == 2){
				if(Get_BitVar(g_IsZombie, id) && !Get_BitVar(g_Respawning, id))
					iZombies++
			} else {
				if(!is_user_alive(id) && Get_BitVar(g_IsZombie, id) && !Get_BitVar(g_Respawning, id))
					iZombies++
			}
		}*/
		
	}
	
	return iZombies
}

stock GetRespawningZombie(Respawn) // Respawning: 0 - None, 1 - Respawning
{
	static iZombies, id; iZombies = id = 0
	
	for(id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue

		if(Respawn == 1)
		{
			if(Get_BitVar(g_IsZombie, id) && Get_BitVar(g_Respawning, id))
				iZombies++
		} else {
			if(Get_BitVar(g_IsZombie, id) && !Get_BitVar(g_Respawning, id))
				iZombies++
		}
	}	
	
	return iZombies
}

stock GetHumanCount(Alive)
{
	static Humans, id; Humans = id = 0
	
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_connected(id))
			continue
			
		if(Alive == 1)
		{
			if(is_user_alive(id) && !Get_BitVar(g_IsZombie, id)) Humans++
		} else if(Alive == 2) {
			if(!Get_BitVar(g_IsZombie, id)) Humans++
		} else {
			if(!is_user_alive(id) && !Get_BitVar(g_IsZombie, id)) Humans++
		}
	}
	
	return Humans
}

stock GetRandomPlayer()
{
	static id, PlayerList[33], PlayerCount; PlayerCount = 0
	
	for(id = 1; id <= g_MaxPlayers; id++)
	{
		if(!is_user_alive(id))
			continue
		if(Get_BitVar(g_IsZombie, id) || Get_BitVar(g_IsHero, id))
			continue
			
		PlayerList[PlayerCount] = id
		PlayerCount++
	}
	
	return PlayerList[random_num(0, PlayerCount - 1)]
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
