#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <xs>

#define PLUGIN "Ghost Fury"
#define VERSION "BETA 1.0"
#define AUTHOR "Dias Pendragon"

#define GAME_FOLDER "GhostFury"
#define GAME_SETTINGFILE "GF_GameConfig.ini"
#define PLAYER_SETTINGFILE "GF_PlayerConfig.ini"
#define SOUND_SETTINGFILE "GF_SoundConfig.ini"
#define CONFIG_FILE "GF_Cvars.cfg"
#define LANG_FILE "GhostFury.txt"

#define GAME_LANG LANG_SERVER
new GameName[32] = "Ghost Fury"

// Round Management
new g_BlockedObj_Forward
new g_BlockedObj[9][] =
{
        "func_bomb_target",
        "info_bomb_target",
        "info_vip_start",
        "func_vip_safetyzone",
        "func_escapezone",
        "hostage_entity",
        "monster_scientist",
        "func_hostage_rescue",
        "info_hostage_rescue"
}

// ================== GameMaster ==================
// -- Model --
#define MODELCHANGE_DELAY 0.1 	// Delay between model changes (increase if getting SVC_BAD kicks)
#define ROUNDSTART_DELAY 2.0 	// Delay after roundstart (increase if getting kicks at round start)
#define SET_MODELINDEX_OFFSET 	// Enable custom hitboxes (experimental, might lag your server badly with some models)

#define MODELNAME_MAXLENGTH 32
#define TASK_CHANGEMODEL 1962

new const DEFAULT_MODELINDEX_T[] = "models/player/terror/terror.mdl"
new const DEFAULT_MODELINDEX_CT[] = "models/player/urban/urban.mdl"

new g_HasCustomModel
new Float:g_ModelChangeTargetTime
new g_CustomPlayerModel[33][MODELNAME_MAXLENGTH]
#if defined SET_MODELINDEX_OFFSET
new g_CustomModelIndex[33]
#endif

#define OFFSET_CSTEAMS 114
#define OFFSET_MODELINDEX 491 // Orangutanz

// -- Team --
#define TEAMCHANGE_DELAY 0.1

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }
new Float:g_TeamMsgTargetTime

// -- Changing Speed --
#define Ham_CS_Player_ResetMaxSpeed Ham_Item_PreFrame 
#define SV_MAXSPEED 999.0

new g_HasCustomSpeed

// Hud
#define HUD_WIN_X -1.0
#define HUD_WIN_Y 0.20
#define HUD_NOTICE_X -1.0
#define HUD_NOTICE_Y 0.25
#define HUD_NOTICE2_X -1.0
#define HUD_NOTICE2_Y 0.70
#define HUD_MESSAGE_X -1.0
#define HUD_MESSAGE_Y 0.32

// Task
#define TASK_COUNTDOWN 14801
#define TASK_KILL 14802
#define TASK_HELPHUD 14803

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

// Shared Code
#define PDATA_SAFE 2
const OFFSET_PLAYER_LINUX = 5
const OFFSET_WEAPON_LINUX = 4
const OFFSET_WEAPONOWNER = 41
const OFFSET_CSDEATHS = 444
const m_flVelocityModifier = 108
const m_flFallVelocity = 251
const m_iRadiosLeft = 192 

#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

// Weapon entity names
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }

new const SoundNVG[2][] = { "items/nvg_off.wav", "items/nvg_on.wav"}
			
// LIGHT
#define LIGHT_START "h"
#define LIGHT_GAME "c"
new const LIGHT_STARTCHANGE[6][2] = {"h", "g", "f", "e", "d", "c"}
new const LIGHT_ENDCHANGE[11][2] = {"c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m"}

#define FOG_START_STAGE 100
#define FALL_VELOCITY 350.0
#define TEAMCHANGE_MAXTIME 300

enum
{
	TEAM_NONE = 0,
	TEAM_GHOST,
	TEAM_HUMAN
}

enum
{
	MALE = 1,
	FEMALE
}

// Sound
#define LOOP_TIME 8.0
#define MAX_DISTANCE 512.0
#define STEP_DELAY 0.3
#define RADIO_MAXSEND 60

// Forwards
#define MAX_FORWARD 10
enum
{
	FW_TRANSGHOST_PRE = 0,
	FW_TRANSGHOST_POST,
	FW_USER_SPAWN,
	FW_USER_DIED,
	FW_USER_NVG,
	FW_ROUND_NEW,
	FW_ROUND_START,
	FW_GAME_START,
	FW_ROUND_END,
	FW_ROUND_TIME
}
new g_Forwards[MAX_FORWARD]

// Array & Loaded Vars
new Array:Ar_GameSky

new g_MinPlayer, g_CountDown_Time, g_KillReward, g_NVG_Alpha, g_NVG_HumanColor[3], g_NVG_GhostColor[3]
new g_HumanHP, g_HumanAP, Float:g_HumanGravity, Array:HumanModel_Male, Array:HumanModel_Female
new g_GhostOHP, g_GhostOAP, g_GhostHHP, g_GhostHAP, Float:g_GhostGravity, Float:g_GhostSpeed, Float:g_GhostSpeedNC,
g_GhostModel[64], g_GhostModelNC[64], g_GhostClawModel[64], g_GhostClawModelInv[64], g_GhostPainFree, g_GhostNoFallDamage, Float:g_GhostClawRad

// - Sound
new S_CountSound[64], Array:ArS_SoundStart, Array:ArS_Message
new Array:ArS_GhostWin, Array:ArS_HumanWin
new Array:ArS_MaleDeath, Array:ArS_FemaleDeath, Array:ArS_GhostComing, Array:ArS_GhostIdle, Array:ArS_GhostDeath
new Array:ArS_ClawDraw, Array:ArS_ClawSwing, Array:ArS_ClawSlash, Array:ArS_ClawStab, Array:ArS_ClawHit
new Array:ArS_FootstepRun, Array:ArS_FootstepJump, Array:ArS_FootstepLand

// Vars
new g_GameLight[2], g_GameStart, g_RoundEnd, g_HuntingStart
new g_Countdown, g_CountTime, Float:g_PlayerSpawn_Point[64][3], g_PlayerSpawn_Count, Float:g_PassedTime
new g_MaxPlayers, g_Joined, g_MsgTeamInfo, g_MsgScoreInfo, g_MsgSayText, g_MsgFog, g_MsgScreenFade,
g_MsgDeathMsg, g_MsgScoreAttrib, g_MsgFlashlight
new TempSound[64], g_Fog, Float:g_FogDensity, g_FogStage, g_GameLightChange, g_NextFemale, g_FemaleAvailable
new g_IsGhost, g_TeamScore[3], g_Has_NightVision, g_UsingNVG, g_MaxHealth[33], g_IsFemale, g_PlayerModel[33][24],
Float:SoundDelay_Notice, m_iBlood[2], g_Falling, g_WinTeam, g_Cvar_RoundTime, Float:g_RoundTimeLeft, 
Float:RoundTime, Float:g_PlayerSound[33], Float:g_PlayerStepSound[33], Float:g_PlayerStepSound2[33], 
Float:g_fNextStep[33], g_UsingKamui, Float:g_KamuiSwitchingDelay[33], g_IsInvisible, Float:g_ShrineDelay[33],
g_UsingFlashlight, g_HelpHud, g_SeenHelp, g_fwResult, g_IsOriginGhost, Float:g_TeamChange[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	
	// Register SafetyFunc
	Register_SafetyFunc()
	
	// Event
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")	
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")	
	
	// Forward
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	//register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	register_forward(FM_StartFrame, "fw_StartFrame")
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")
	register_forward(FM_AddToFullPack, "fw_WhatTheFuck_Post", 1)

	// Hamsandwich
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_WSTraceAttack_Post", 1)
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "fw_Ham_ResetMaxSpeed")
	RegisterHam(Ham_Player_Jump, "player", "fw_Ham_PlayerJump")
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
	for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
		if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
	
	// Message
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("TeamScore"), "Message_TeamScore")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
	register_message(get_user_msgid("TextMsg"), "Message_TextMsg")
	register_message(get_user_msgid("SendAudio"), "Message_SendAudio")

	// CMD ?
	register_impulse(100, "Impulse_100")
	register_clcmd("lastinv", "CMD_QButton")
	register_clcmd("nightvision", "CMD_NightVision")
	register_clcmd("radio1", "CMD_Radio") 
	register_clcmd("radio2", "CMD_Radio") 
	register_clcmd("radio3", "CMD_Radio") 
	
	// Team Mananger
	register_clcmd("chooseteam", "CMD_JoinTeam")
	register_clcmd("jointeam", "CMD_JoinTeam")
	register_clcmd("joinclass", "CMD_JoinTeam")	
	
	// Get Message
	g_MsgFog = get_user_msgid("Fog")
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	g_MsgSayText = get_user_msgid("SayText")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	g_MsgDeathMsg = get_user_msgid("DeathMsg")
	g_MsgScoreAttrib = get_user_msgid("ScoreAttrib")
	g_MsgFlashlight = get_user_msgid("Flashlight")
	g_MaxPlayers = get_maxplayers()
	
	// Forwards
	g_Forwards[FW_TRANSGHOST_PRE] = CreateMultiForward("gf_user_transghost_pre", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_TRANSGHOST_POST] = CreateMultiForward("gf_user_transghost_post", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_SPAWN] = CreateMultiForward("gf_user_spawn", ET_IGNORE, FP_CELL)
	g_Forwards[FW_USER_DIED] = CreateMultiForward("gf_user_died", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[FW_USER_NVG] = CreateMultiForward("gf_user_nvg", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FW_ROUND_NEW] = CreateMultiForward("gf_round_new", ET_IGNORE)
	g_Forwards[FW_ROUND_START] = CreateMultiForward("gf_round_start", ET_IGNORE)
	g_Forwards[FW_GAME_START] = CreateMultiForward("gf_game_start", ET_IGNORE)
	g_Forwards[FW_ROUND_END] = CreateMultiForward("gf_round_end", ET_IGNORE)
	g_Forwards[FW_ROUND_TIME] = CreateMultiForward("gf_round_time", ET_IGNORE, FP_CELL)
	
	// Collect Spawns Point
	collect_spawns_ent("info_player_start")
	collect_spawns_ent("info_player_deathmatch")

	// Check Sex
	if(ArraySize(HumanModel_Female)) g_FemaleAvailable = 1
	else g_FemaleAvailable = 0
	g_NextFemale = 0
	
	g_HelpHud = CreateHudSyncObj()
	g_Cvar_RoundTime = get_cvar_pointer("mp_roundtime")
	
	formatex(GameName, sizeof(GameName), "%L", GAME_LANG, "GAME_NAME")
}

public plugin_precache()
{
	// Initialize Arrays
	Ar_GameSky = ArrayCreate(32, 1)
	ArS_SoundStart = ArrayCreate(64, 1)
	ArS_Message = ArrayCreate(64, 1)
	
	ArS_GhostWin = ArrayCreate(64, 1)
	ArS_HumanWin = ArrayCreate(64, 1)
	
	ArS_MaleDeath = ArrayCreate(64, 1)
	ArS_FemaleDeath = ArrayCreate(64, 1)
	ArS_GhostComing = ArrayCreate(64, 1)
	ArS_GhostIdle = ArrayCreate(64, 1)
	ArS_GhostDeath = ArrayCreate(64, 1)
	
	ArS_ClawDraw = ArrayCreate(64, 1)
	ArS_ClawSwing = ArrayCreate(64, 1)
	ArS_ClawSlash = ArrayCreate(64, 1)
	ArS_ClawStab = ArrayCreate(64, 1)
	ArS_ClawHit = ArrayCreate(64, 1)
	
	ArS_FootstepRun = ArrayCreate(64, 1)
	ArS_FootstepJump = ArrayCreate(64, 1)
	ArS_FootstepLand = ArrayCreate(64, 1)

	HumanModel_Male = ArrayCreate(64, 1)
	HumanModel_Female = ArrayCreate(64, 1)
	
	// Load Game Config
	Load_GameConfig()
	Precache_GameFiles()
	Environment_Setting()
	
	// Cache
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")	
}

public plugin_natives()
{
	register_native("gf_get_user_ghost", "Native_GetGhost", 1)
	register_native("gf_get_user_originghost", "Native_GetOriginGhost", 1)
	register_native("gf_get_user_maxhealth", "Native_GetMaxHealth", 1)
	register_native("gf_set_user_nvg", "Native_SetNVG", 1)
	register_native("gf_get_user_nvg", "Native_GetNVG", 1)
	register_native("gf_get_user_infinitewalking", "Native_GetKamui", 1)
	register_native("gf_set_user_infinitewalking", "Native_SetKamui", 1)
	register_native("gf_set_user_speed", "Native_SetSpeed", 1)
	register_native("gf_get_round_timeleft", "Native_GetRTL", 1)
}

public Native_GetGhost(id)
{
	if(!is_connected(id))
		return 0
		
	return is_user_ghost(id)
}

public Native_GetOriginGhost(id)
{
	if(!is_connected(id))
		return 0
		
	return Get_BitVar(g_IsOriginGhost, id)
}

public Native_GetMaxHealth(id)
{
	if(!is_connected(id))
		return 0
		
	return g_MaxHealth[id]
}

public Native_SetNVG(id, Give, On, Sound, IgnoreHadNVG)
{
	if(!is_connected(id))
		return 0
		
	if(Give) Set_BitVar(g_Has_NightVision, id)
	set_user_nightvision(id, On, Sound, IgnoreHadNVG)
	
	return 1
}

public Native_GetNVG(id, Have, On)
{
	if(!is_connected(id))
		return 0
		
	if(Have && !On)
	{
		if(Get_BitVar(g_Has_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && On) {
		if(!Get_BitVar(g_Has_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(Have && On) {
		if(Get_BitVar(g_Has_NightVision, id) && Get_BitVar(g_UsingNVG, id))
			return 1
	} else if(!Have && !On) {
		if(!Get_BitVar(g_Has_NightVision, id) && !Get_BitVar(g_UsingNVG, id))
			return 1
	}
	
	return 0	
}

public Native_GetKamui(id)
{
	if(!is_connected(id))
		return 0
		
	return Get_BitVar(g_UsingKamui, id)
}

public Native_SetKamui(id, On)
{
	if(!is_connected(id))
		return
	if(!is_alive(id))
		return
		
	if(On)
	{
		set_user_noclip(id, 1)
		Engine_SetModel(id, g_GhostModelNC)
		Engine_SetSpeed(id, g_GhostSpeedNC, 1)
		
		Set_BitVar(g_UsingKamui, id)
	} else {
		set_user_noclip(id, 0)
		Engine_SetModel(id, g_GhostModel)
		Engine_SetSpeed(id, g_GhostSpeed, 1)
		
		UnSet_BitVar(g_UsingKamui, id)
	}
}

public Native_SetSpeed(id, Float:Speed, BlockSpeed) Engine_SetSpeed(id, Speed, BlockSpeed)
public Native_GetRTL(id)
{
	return floatround(Get_RoundTimeLeft())
}

public plugin_cfg()
{
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("sv_maxspeed", 999)
	set_cvar_num("mp_playerid", 1)
	
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)	
	
	// Exec
	new FileUrl[128]
	
	get_configsdir(FileUrl, sizeof(FileUrl))
	formatex(FileUrl, sizeof(FileUrl), "%s/%s/%s", FileUrl, GAME_FOLDER, CONFIG_FILE)
	
	server_exec()
	server_cmd("exec %s", FileUrl)
	
	// Sky
	if(ArraySize(Ar_GameSky))
	{
		new Sky[64]; ArrayGetString(Ar_GameSky, Get_RandomArray(Ar_GameSky), Sky, sizeof(Sky))
		set_cvar_string("sv_skyname", Sky)
	}
	
	// New Round
	Event_NewRound()
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

public Environment_Setting()
{
	new BufferA[64], BufferB[128]
	
	// Weather & Sky
	if(Setting_Load_Int(GAME_SETTINGFILE, "Environment", "ENV_RAIN")) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	if(Setting_Load_Int(GAME_SETTINGFILE, "Environment", "ENV_SNOW")) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))	
	g_Fog = Setting_Load_Int(GAME_SETTINGFILE, "Environment", "ENV_FOG")
	
	// Sky
	Setting_Load_StringArray(GAME_SETTINGFILE, "Environment", "ENV_SKY", Ar_GameSky)
	
	for(new i = 0; i < ArraySize(Ar_GameSky); i++)
	{
		ArrayGetString(Ar_GameSky, i, BufferA, charsmax(BufferA)); 
		
		// Preache custom sky files
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sbk.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sdn.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sft.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%slf.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%srt.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sup.tga", BufferA); engfunc(EngFunc_PrecacheGeneric, BufferB)		
	}	
	
	Setting_Load_String(GAME_SETTINGFILE, "Environment", "ENV_FOG_DENSITY", BufferA, sizeof(BufferA))
	g_FogDensity = str_to_float(BufferA)
}

// ================== PUBLIC FORWARD =====================
// =======================================================
public client_putinserver(id)
{
	Safety_Connected(id)
	set_task(0.25, "Set_ConnectInfo", id)
	
	Reset_Player(id, 1)
	remove_task(id+TASK_CHANGEMODEL)

	UnSet_BitVar(g_HasCustomModel, id)
	UnSet_BitVar(g_HasCustomSpeed, id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
	
	if(g_FemaleAvailable)
	{
		if(g_NextFemale) 
		{
			Set_BitVar(g_IsFemale, id)
			g_NextFemale = 0
			
			ArrayGetString(HumanModel_Female, Get_RandomArray(HumanModel_Female), g_PlayerModel[id], 23)
		} else {
			UnSet_BitVar(g_IsFemale, id)
			g_NextFemale = 1
			
			ArrayGetString(HumanModel_Male, Get_RandomArray(HumanModel_Male), g_PlayerModel[id], 23)
		}
	} else {
		UnSet_BitVar(g_IsFemale, id)
		ArrayGetString(HumanModel_Male, Get_RandomArray(HumanModel_Male), g_PlayerModel[id], 23)
	}
}

public Set_ConnectInfo(id)
{
	if(!is_connected(id)) 
		return
		
	SetPlayerLight(id, g_GameLight)
	SetPlayerFog(id, g_FogStage, g_FogStage, g_FogStage, g_FogDensity)
}

public Register_HamBot(id) 
{
	Register_SafetyFuncBot(id)
	
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled")
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage_Post", 1)
	RegisterHamFromEntity(Ham_CS_Player_ResetMaxSpeed, id, "fw_Ham_ResetMaxSpeed")
	RegisterHamFromEntity(Ham_Player_Jump, id, "fw_Ham_PlayerJump")
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
	
	UnSet_BitVar(g_Joined, id)
	
	remove_task(id+TASK_CHANGEMODEL)
	remove_task(id+TASK_TEAMMSG)
	
	UnSet_BitVar(g_HasCustomModel, id)
	UnSet_BitVar(g_HasCustomSpeed, id)
}

public client_PreThink(id) 
{
	if(!is_alive(id))
		return
	if(!is_user_ghost(id))
		return
	
	// Step Sound
	if(g_fNextStep[id] < get_gametime())
	{
		static Float:Velocity[3]; pev(id, pev_velocity, Velocity)
		Velocity[2] = 0.0
		
		if(vector_length(Velocity) > 160.0 && (pev(id, pev_flags) & FL_ONGROUND))
		{
			static Right, Divide, Target; 
			
			Divide = Get_RandomArray(ArS_FootstepRun) / 2
			if(Right) 
			{
				Target = random_num(0, Divide)
				Right = 0
			} else {
				Target = random_num(Divide, Get_RandomArray(ArS_FootstepRun))
				Right = 1
			}
			
			ArrayGetString(ArS_FootstepRun, Target, TempSound, sizeof(TempSound))
			emit_sound(id, CHAN_BODY, TempSound, 0.5, ATTN_NORM, 0, PITCH_NORM)
		}
  
		g_fNextStep[id] = get_gametime() + STEP_DELAY
	}
	
	// No Fall Damage
	if(g_GhostNoFallDamage && entity_get_float(id, EV_FL_flFallVelocity) >= FALL_VELOCITY) Set_BitVar(g_Falling, id)
	else UnSet_BitVar(g_Falling, id)
}

public client_PostThink(id) 
{
	if(!is_alive(id))
		return
	if(is_user_ghost(id))
	{
		// No Fall Damage
		if(g_GhostNoFallDamage && Get_BitVar(g_Falling, id))
			entity_set_int(id, EV_INT_watertype, -3)
			
		// Landing Sound
		static Float:flFallVelocity; flFallVelocity = get_pdata_float(id, m_flFallVelocity, OFFSET_PLAYER_LINUX)
		if(flFallVelocity && pev(id, pev_flags) & FL_ONGROUND)
		{
			if(get_gametime() - 0.35 > g_PlayerStepSound[id])
			{
				ArrayGetString(ArS_FootstepLand, Get_RandomArray(ArS_FootstepLand), TempSound, sizeof(TempSound))
				EmitSound(id, CHAN_BODY, TempSound)
				
				g_PlayerStepSound[id] = get_gametime()
			}
		}
		
		// Shrine Delay
		if(get_gametime() - 0.5 > g_ShrineDelay[id])
		{
			static ModelName[64]
			pev(id, pev_viewmodel2, ModelName, sizeof(ModelName))
			if(!equal(ModelName, g_GhostClawModelInv))
				set_pev(id, pev_viewmodel2, g_GhostClawModelInv)
			
			Set_BitVar(g_IsInvisible, id)
			
			g_ShrineDelay[id] = get_gametime()
		}
	} else {
		// Ghost Detection
		static Effect; Effect = pev(id, pev_effects)
		if(Effect & EF_DIMLIGHT)
		{ // Using flashlight
			if(!Get_BitVar(g_UsingFlashlight, id)) Set_BitVar(g_UsingFlashlight, id)
			if(get_gametime() - 0.1 > g_ShrineDelay[id])
			{
				static Body, Target; 
				get_user_aiming(id, Target, Body, floatround(MAX_DISTANCE))
				
				if(is_alive(Target) && is_user_ghost(Target))
				{
					static ModelName[64]
					pev(Target, pev_viewmodel2, ModelName, sizeof(ModelName))
					if(!equal(ModelName, g_GhostClawModel))
						set_pev(Target, pev_viewmodel2, g_GhostClawModel)
					
					UnSet_BitVar(g_IsInvisible, Target)
					g_ShrineDelay[Target] = get_gametime()
				}
				
				g_ShrineDelay[id] = get_gametime()
			}
		} else { // Not using flashlight
			if(Get_BitVar(g_UsingFlashlight, id)) UnSet_BitVar(g_UsingFlashlight, id)
		}
	}
}

// ======================== EVENT ========================
// =======================================================
public Event_NewRound()
{
	// Reset Day & Light
	g_GameLight = LIGHT_START
	g_FogStage = FOG_START_STAGE
	g_WinTeam = TEAM_NONE
	
	g_RoundEnd = 0
	g_HuntingStart = 0
	g_Countdown = 0
	g_RoundTimeLeft = 0.0
	RoundTime = get_pcvar_float(g_Cvar_RoundTime)
	
	// Player Model
	g_ModelChangeTargetTime = get_gametime() + ROUNDSTART_DELAY
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		remove_task(i+TASK_TEAMMSG)
		
		if(task_exists(i+TASK_CHANGEMODEL))
		{
			remove_task(i+TASK_CHANGEMODEL)
			fm_cs_user_model_update(i+TASK_CHANGEMODEL)
		}
		
		UnSet_BitVar(g_HasCustomSpeed, i)
	}
	
	Balance_Teams()
	StopSound(0)
	
	if(!g_GameStart || g_RoundEnd)
		return
		
	if(ArraySize(ArS_SoundStart))
	{
		static Sound[64]; ArrayGetString(ArS_SoundStart, Get_RandomArray(ArS_SoundStart), Sound, sizeof(Sound))
		PlaySound(0, Sound)
	}
	
	Start_Countdown()
	
	ExecuteForward(g_Forwards[FW_ROUND_NEW], g_fwResult)
}

public Event_RoundStart()
{
	if(!g_GameStart || g_RoundEnd)
		return
	
	g_Countdown = 1
	
	// Calc Time
	if(RoundTime < 1.0 || RoundTime > 9.0) return
	
	g_PassedTime = get_gametime()
	g_RoundTimeLeft = get_gametime() + (RoundTime * 60.0)
	
	ExecuteForward(g_Forwards[FW_ROUND_START], g_fwResult)
}

public Event_RoundEnd()
{
	static Sound[64]
	switch(g_WinTeam)
	{
		case TEAM_GHOST:
		{
			g_TeamScore[TEAM_GHOST]++
			
			ArrayGetString(ArS_GhostWin, Get_RandomArray(ArS_GhostWin), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			set_dhudmessage(200, 0, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", GAME_LANG, "NOTICE_GHOSTWIN_B")
			
			set_dhudmessage(255, 85, 0, HUD_MESSAGE_X, HUD_MESSAGE_Y, 0, 6.0, 6.0, 0.5, 1.0)
			show_hudmessage(0, "%L", GAME_LANG, "NOTICE_GHOSTWIN_S")

			g_RoundTimeLeft = -1.0
		}
		case TEAM_HUMAN: 
		{
			g_TeamScore[TEAM_HUMAN]++
			
			ArrayGetString(ArS_HumanWin, Get_RandomArray(ArS_HumanWin), Sound, sizeof(Sound))
			PlaySound(0, Sound)
			
			set_dhudmessage(0, 200, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", GAME_LANG, "NOTICE_HUMANWIN_B")
			
			set_dhudmessage(0, 170, 255, HUD_MESSAGE_X, HUD_MESSAGE_Y, 0, 6.0, 6.0, 0.5, 1.0)
			show_hudmessage(0, "%L", GAME_LANG, "NOTICE_HUMANWIN_S")
		}
	}
	
	g_RoundEnd = 1
	Balance_Teams()
	
	ExecuteForward(g_Forwards[FW_ROUND_END], g_fwResult)
}

public Event_GameRestart()
{
	Event_RoundEnd()
}

public Event_Time()
{
	if(g_GameStart && Get_TotalPlayer(2) < g_MinPlayer)
	{
		g_GameStart = 0
		g_RoundEnd = 0
		g_HuntingStart = 0
	} else if(!g_GameStart && Get_TotalPlayer(2) >= g_MinPlayer) {
		g_GameStart = 1
		g_RoundEnd = 1
		g_HuntingStart = 0
	} else if(!g_GameStart  && Get_TotalPlayer(2) < g_MinPlayer) {
		client_print(0, print_center, "%L", GAME_LANG, "NOTICE_PLAYERREQUIRED")
	}
	
	Player_RunTime()
	Check_Gameplay()
	
	static TimeLeft; TimeLeft = floatround(Get_RoundTimeLeft())
	static Float:Density
	if(TimeLeft <= -1) return

	if(TimeLeft == 0)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_alive(i))
				continue
			if(!is_user_ghost(i))
				continue
			if(g_RoundEnd)
				continue
				
			set_user_noclip(i, 0)
			set_entity_visibility(i, 0)
			set_task(random_float(0.1, 0.5), "Kill_Ghosts", i+TASK_KILL)
		}
	} else if(TimeLeft == 11) {
		g_GameLightChange = 0
		Density = g_FogDensity
		
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_alive(i))
				continue
			if(!is_user_ghost(i))
				continue
				
			Set_PlayerNVG(i, 0, 0, 0, 1)
			UnSet_BitVar(g_Has_NightVision, i)
		}
	} else if(TimeLeft <= 10) {
		if(!g_GameStart)
			return
		
		static Sound[64]; format(Sound, charsmax(Sound), S_CountSound, TimeLeft-1)
		PlaySound(0, Sound)
		SetPlayerLight(0, LIGHT_ENDCHANGE[g_GameLightChange])

		g_GameLight = LIGHT_ENDCHANGE[g_GameLightChange]
		g_GameLightChange++
			
		SetPlayerFog(0, g_FogStage, g_FogStage, g_FogStage, Density)
		Density -= 0.0001
		g_FogStage += 15
	}
	
	ExecuteForward(g_Forwards[FW_ROUND_TIME], g_fwResult, floatround(Get_RoundTimeLeft()))
}

public Kill_Ghosts(id)
{
	id -= TASK_KILL
	
	if(!is_alive(id))
		return
	if(!is_user_ghost(id))
		return
		
	user_silentkill(id)
}

public Check_Gameplay()
{
	if(!g_GameStart || g_RoundEnd || !g_HuntingStart)
		return
		
	/*
	if(!Get_PlayerCount(1, 1) && !g_RoundEnd)
	{
		g_RoundEnd = 1
	} else if(!Get_PlayerCount(1, 2) && !g_RoundEnd) {
		g_RoundEnd = 1
	}*/
}

public Start_Countdown()
{
	g_CountTime = g_CountDown_Time
	g_GameLightChange = 0
	
	remove_task(TASK_COUNTDOWN)
	CountingDown()
}

public CountingDown()
{
	if(!g_GameStart || g_RoundEnd)
		return
	if(g_CountTime  <= 0)
	{
		SetPlayerLight(0, LIGHT_GAME)
		g_GameLight = LIGHT_GAME
		g_GameLightChange = 0
		
		set_task(0.1, "Start_Game_Now")

		return
	}
	
	static Changer
	client_print(0, print_center, "%L", GAME_LANG, "NOTICE_COUNTDOWN", g_CountTime)
	
	if(g_CountTime == 13)
	{
		ArrayGetString(ArS_Message, Get_RandomArray(ArS_Message), TempSound, sizeof(TempSound))
		PlaySound(0, TempSound)
		
		set_dhudmessage(0, 48, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
	
		static RandomNum; RandomNum = random_num(1, 3)
		if(RandomNum == 1) show_dhudmessage(0, "%L", GAME_LANG, "NOTICE_HUMAN_TIP1")
		else if(RandomNum == 2) show_dhudmessage(0, "%L", GAME_LANG, "NOTICE_HUMAN_TIP2")
		else if(RandomNum == 3) show_dhudmessage(0, "%L", GAME_LANG, "NOTICE_HUMAN_TIP3")
		
		Changer = 1
	}
	
	if(g_CountTime <= 10)
	{
		static Sound[64]; format(Sound, charsmax(Sound), S_CountSound, g_CountTime)
		PlaySound(0, Sound)
		
		if(Changer >= 1)
		{
			SetPlayerLight(0, LIGHT_STARTCHANGE[g_GameLightChange])
			g_GameLight = LIGHT_STARTCHANGE[g_GameLightChange]
			g_GameLightChange++
			
			Changer = 0
		} else {
			Changer++
		}
		
		SetPlayerFog(0, g_FogStage, g_FogStage, g_FogStage, g_FogDensity)
		g_FogStage -= 10
	} 
	
	if(g_Countdown) g_CountTime--
	set_task(1.0, "CountingDown", TASK_COUNTDOWN)
}

public Start_Game_Now()
{
	g_HuntingStart = 1
	
	// Make Ghost(s)
	static TotalPlayer; TotalPlayer = Get_TotalPlayer(1)
	static GhostNumber; GhostNumber = clamp(floatround(float(TotalPlayer) / 10.0, floatround_ceil), 1, 3)
	
	static PlayerList[32], PlayerNum; PlayerNum = 0
	for(new i = 0; i < GhostNumber; i++)
	{
		get_players(PlayerList, PlayerNum, "a")
		Set_PlayerGhost(PlayerList[random(PlayerNum)], -1, 1)
	}
	
	// Transfer all players to CT
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_connected(i))
			continue
		if(!is_alive(i))
			continue
		if(is_user_ghost(i))
			continue
			
		// Show Message
		set_dhudmessage(85, 255, 85, HUD_NOTICE2_X, HUD_NOTICE2_Y, 2, 0.1, 3.0, 0.01, 0.5)
		show_dhudmessage(i, "%L", GAME_LANG, "NOTICE_ALIVETIME")
			
		Engine_SetTeam(i, CS_TEAM_CT)
		TurnOn_Flashlight(i)
	}
	
	ExecuteForward(g_Forwards[FW_GAME_START], g_fwResult)
}

public TurnOn_Flashlight(id)
{
	static Effect; Effect = pev(id, pev_effects)
	
	if(~Effect & EF_DIMLIGHT)
	{
		emit_sound(id, CHAN_ITEM, "items/flashlight1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_pev(id, pev_effects, Effect | EF_DIMLIGHT)
		
		message_begin(MSG_ONE_UNRELIABLE, g_MsgFlashlight, _, id)
		write_byte(1)
		write_byte(100)
		message_end()
		
		Set_BitVar(g_UsingFlashlight, id)
	}
} 

public TurnOff_Flashlight(id)
{
	static Effect; Effect = pev(id, pev_effects)
	
	if(Effect & EF_DIMLIGHT)
	{
		emit_sound(id, CHAN_WEAPON, "items/flashlight1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		set_pev(id, pev_effects, Effect & ~EF_DIMLIGHT)
		
		message_begin(MSG_ONE_UNRELIABLE, g_MsgFlashlight, _, id)
		write_byte(0)
		write_byte(100)
		message_end()
		
		UnSet_BitVar(g_UsingFlashlight, id)
	}
}

public Player_RunTime()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
			
		if(is_user_ghost(i))
		{
			if(get_gametime() - LOOP_TIME > g_PlayerSound[i])
			{
				static Sound[64]; ArrayGetString(ArS_GhostIdle, Get_RandomArray(ArS_GhostIdle), Sound, sizeof(Sound))
				PlaySound(i, Sound)

				for(new a = 0; a < g_MaxPlayers; a++)
				{
					if(!is_alive(a))
						continue
					if(is_user_ghost(a))
						continue
					if(entity_range(i, a) > MAX_DISTANCE)
						continue
						
					if(get_gametime() - (LOOP_TIME / 1.25) > g_PlayerSound[a])
					{	
						PlaySound(a, Sound)
						g_PlayerSound[a] = get_gametime()
					}
					
				}
				
				g_PlayerSound[i] = get_gametime()
			}
		}
	}
}
	
// ===================== MAIN FUNC =======================
// =======================================================
public Set_PlayerGhost(id, Attacker, Origin)
{
	if(!is_alive(id))
		return
		
	Reset_Player(id, 0)
	
	// Set Ghosts?
	Set_BitVar(g_IsGhost, id)
	
	ExecuteForward(g_Forwards[FW_TRANSGHOST_PRE], g_fwResult, id, Attacker, is_connected(Attacker) ? 1 : 0)
	
	if(is_connected(Attacker))
	{
		// Reward frags, deaths
		SendDeathMsg(Attacker, id)
		UpdateFrags(Attacker, id, 1, 1, 1)
	
		// Play Infection Sound
		static DeathSound[64]; 
		
		switch(get_player_sex(id))
		{
			case MALE: ArrayGetString(ArS_MaleDeath, Get_RandomArray(ArS_MaleDeath), DeathSound, sizeof(DeathSound))
			case FEMALE: ArrayGetString(ArS_FemaleDeath, Get_RandomArray(ArS_FemaleDeath), DeathSound, sizeof(DeathSound))
			default: ArrayGetString(ArS_MaleDeath, Get_RandomArray(ArS_MaleDeath), DeathSound, sizeof(DeathSound))
		}
		
		EmitSound(id, CHAN_STATIC, DeathSound)
		cs_set_user_money(Attacker, clamp(cs_get_user_money(Attacker) + g_KillReward, 0, 16000))
	}	
	
	set_pdata_int(id, m_iRadiosLeft, 0, OFFSET_PLAYER_LINUX)
	Set_Scoreboard_Attrib(id, 0)
	Set_BitVar(g_IsInvisible, id)
	
	// Set Classic Info
	Engine_SetTeam(id, CS_TEAM_T)
	Engine_SetSpeed(id, g_GhostSpeed, 1)
	set_pev(id, pev_gravity, g_GhostGravity)

	if(Origin)
	{
		Set_BitVar(g_IsOriginGhost, id)
		Set_PlayerHealth(id, g_GhostOHP, 1)
		cs_set_user_armor(id, g_GhostOAP, CS_ARMOR_KEVLAR)
	} else {
		UnSet_BitVar(g_IsOriginGhost, id)
		Set_PlayerHealth(id, g_GhostHHP, 1)
		cs_set_user_armor(id, g_GhostHAP, CS_ARMOR_KEVLAR)
	}
	
	// Notice Sound
	static Sound[64]
	if(get_gametime() - 0.5 > SoundDelay_Notice)
	{
		ArrayGetString(ArS_GhostComing, Get_RandomArray(ArS_GhostComing), Sound, sizeof(Sound))
		PlaySound(0, Sound)

		SoundDelay_Notice = get_gametime()
	}
	
	ArrayGetString(ArS_ClawDraw, Get_RandomArray(ArS_ClawDraw), Sound, sizeof(Sound))
	PlaySound(id, Sound)
	
	// Show Notice
	set_dhudmessage(255, 85, 0, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 6.0, 6.0, 0.5, 1.0)
	show_dhudmessage(id, "%L", GAME_LANG, "NOTICE_TRANS_GHOST_B")
	
	set_dhudmessage(255, 85, 0, HUD_MESSAGE_X, HUD_MESSAGE_Y, 0, 6.0, 6.0, 0.5, 1.0)
	show_hudmessage(id, "%L", GAME_LANG, "NOTICE_TRANS_GHOST_S")
	
	// Set Model
	Engine_SetModel(id, g_GhostModel)
	
	// Bug Fix
	cs_set_user_zoom(id, CS_RESET_ZOOM, 1)
	fm_set_user_rendering(id)
	
	// Make Some Blood
	if(!Origin)
	{
		static Float:Origin[3]; pev(id, pev_origin, Origin); Origin[2] += 16.0
		MakeBlood(Origin)
	}
	
	// Strip zombies from guns and give them a knife
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")	
	
	// Play Draw Animation
	Set_WeaponAnim(id, 3)
	Set_Player_NextAttack(id, 0.75)
	
	set_user_footsteps(id, 1)
	
	// Turn Off the FlashLight
	TurnOff_Flashlight(id)
	//if(pev(id, pev_effects) & EF_DIMLIGHT) set_pev(id, pev_impulse, 100)
	//else set_pev(id, pev_impulse, 0)	

	g_PlayerSound[id] = get_gametime() + random_num(3, 7)
	
	// Set NVG
	Set_PlayerNVG(id, 1, 1, 0, 1)
	
	// Check Gameplay
	Check_Gameplay()
	
	ExecuteForward(g_Forwards[FW_TRANSGHOST_POST], g_fwResult, id, Attacker, is_connected(Attacker) ? 1 : 0)
}

public Set_PlayerNVG(id, Give, On, OnSound, Ignored_HadNVG)
{
	if(Give) Set_BitVar(g_Has_NightVision, id)
	set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
}

public set_user_nightvision(id, On, OnSound, Ignored_HadNVG)
{
	if(!Ignored_HadNVG)
	{
		if(!Get_BitVar(g_Has_NightVision, id))
			return
	}

	if(On) Set_BitVar(g_UsingNVG, id)
	else UnSet_BitVar(g_UsingNVG, id)
	
	if(OnSound) PlaySound(id, SoundNVG[On])
	set_user_nvision(id)
	
	ExecuteForward(g_Forwards[FW_USER_NVG], g_fwResult, id, On, is_user_ghost(id))
	
	return
}

public set_user_nvision(id)
{	
	static Alpha
	if(Get_BitVar(g_UsingNVG, id)) Alpha = g_NVG_Alpha
	else Alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	if(is_user_ghost(id))
	{
		write_byte(g_NVG_GhostColor[0]) // r
		write_byte(g_NVG_GhostColor[1]) // g
		write_byte(g_NVG_GhostColor[2]) // b
	} else {
		write_byte(g_NVG_HumanColor[0]) // r
		write_byte(g_NVG_HumanColor[1]) // g
		write_byte(g_NVG_HumanColor[2]) // b
	}
	write_byte(Alpha) // alpha
	message_end()
	
	if(Get_BitVar(g_UsingNVG, id)) SetPlayerLight(id, "#")
	else SetPlayerLight(id, g_GameLight)
}

public Set_PlayerHealth(id, Health, FullHealth)
{
	set_user_health(id, Health)
	if(FullHealth) 
	{
		g_MaxHealth[id] = Health
		set_pev(id, pev_max_health, float(Health))
	}
}

public SendDeathMsg(attacker, victim)
{
	message_begin(MSG_BROADCAST, g_MsgDeathMsg)
	write_byte(attacker) // killer
	write_byte(victim) // victim
	write_byte(0) // headshot flag
	write_string("knife") // killer's weapon
	message_end()
}

public UpdateFrags(attacker, victim, frags, deaths, scoreboard)
{
	if(is_connected(attacker) && is_connected(victim) && cs_get_user_team(attacker) != cs_get_user_team(victim))
	{
		if((pev(attacker, pev_frags) + frags) < 0)
			return
	}
	
	if(is_connected(attacker))
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
	
	if(is_connected(victim))
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

// ====================== FORWARD ========================
// =======================================================
/*
public fw_CmdStart(id, UcHandle, Seed)
{
	if(!is_alive(id))
		return
	if(!is_user_ghost(id))
		return
	if(!Get_BitVar(g_UsingKamui, id))
		return
		
	static CurButton; CurButton = get_uc(UcHandle, UC_Buttons)
	static Float:Velocity[3], Float:Velocity2[3]
	pev(id, pev_velocity, Velocity)
	
	if(CurButton & IN_JUMP)
	{
		Velocity[2] += 10.0
		set_pev(id, pev_velocity, Velocity)
	} else if(CurButton & IN_DUCK) {
		Velocity2[2] = -10.0
		xs_vec_add(Velocity, Velocity2, Velocity)
		
		set_pev(id, pev_velocity, Velocity)
	}
}*/

public fw_SetClientKeyValue(id, const infobuffer[], const key[], const value[])
{
	if (Get_BitVar(g_HasCustomModel, id) && equal(key, "model"))
	{
		static currentmodel[MODELNAME_MAXLENGTH]
		fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
		
		if (!equal(currentmodel, g_CustomPlayerModel[id]) && !task_exists(id+TASK_CHANGEMODEL))
			fm_cs_set_user_model(id+TASK_CHANGEMODEL)
		
#if defined SET_MODELINDEX_OFFSET
		fm_cs_set_user_model_index(id)
#endif
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public fw_StartFrame()
{
	static Float:Time; Time = get_gametime()
	
	if(Time - 1.0 > g_PassedTime)
	{
		Event_Time()
		g_PassedTime = Time
	}
}

public fw_GetGameDesc()
{
	forward_return(FMV_STRING, GameName)
	return FMRES_SUPERCEDE
}

// Emit Sound Forward
public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if (sample[0] == 'h' && sample[1] == 'o' && sample[2] == 's' && sample[3] == 't' && sample[4] == 'a' && sample[5] == 'g' && sample[6] == 'e')
		return FMRES_SUPERCEDE;
	if(is_user_ghost(id))
	{
		static sound[64]
		// Zombie being hit
		if (sample[7] == 'b' && sample[8] == 'h' && sample[9] == 'i' && sample[10] == 't')
		{
			//ArrayGetString(random_num(0, 1) ? ZombiePainSound1 : ZombiePainSound2, g_ZombieClass[id], sound, charsmax(sound))
			//emit_sound(id, channel, sound, volume, attn, flags, pitch)
	
			return FMRES_SUPERCEDE;
		}
		
		// Zombie attacks with knife
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				ArrayGetString(ArS_ClawSwing, Get_RandomArray(ArS_ClawSwing), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				
				return FMRES_SUPERCEDE;
			}
			
			if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{
					ArrayGetString(ArS_ClawSlash, Get_RandomArray(ArS_ClawSlash), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
		
					return FMRES_SUPERCEDE;
				} else {
					ArrayGetString(ArS_ClawSlash, Get_RandomArray(ArS_ClawSlash), sound, charsmax(sound))
					emit_sound(id, channel, sound, volume, attn, flags, pitch)
					
					return FMRES_SUPERCEDE;
				}
			}
			
			if (sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
			{
				ArrayGetString(ArS_ClawStab, Get_RandomArray(ArS_ClawStab), sound, charsmax(sound))
				emit_sound(id, channel, sound, volume, attn, flags, pitch)
				
				return FMRES_SUPERCEDE;
			}
		}
				
		// Zombie dies
		if (sample[7] == 'd' && ((sample[8] == 'i' && sample[9] == 'e') || (sample[8] == 'e' && sample[9] == 'a')))
		{
			ArrayGetString(ArS_GhostDeath, Get_RandomArray(ArS_GhostDeath), sound, charsmax(sound))
			emit_sound(id, channel, sound, volume, attn, flags, pitch)
			
			return FMRES_SUPERCEDE;
		}
	}

	return FMRES_IGNORED;
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(!is_user_ghost(id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	xs_vec_mul_scalar(v_forward, g_GhostClawRad, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if(!is_alive(id))
		return FMRES_IGNORED	
	if(!is_user_ghost(id))
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	xs_vec_mul_scalar(v_forward,  g_GhostClawRad, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_WhatTheFuck_Post(Es, E, Ent, Host, Hostflags, Player, pSet)
{
	if(!Player)
		return FMRES_IGNORED
	if(!is_connected(Host) || !is_connected(Ent))
		return FMRES_IGNORED
	if(!g_RoundEnd)
	{
		if(is_user_ghost(Host))
		{ // Player is a Ghost
			if(is_user_ghost(Ent)) // Show
				set_es(Es, ES_Effects, get_es(Es, ES_Effects) & ~EF_NODRAW)	
		} else { // Player is not a Ghost
			if(is_alive(Host))
			{
				if(is_user_ghost(Ent) && Get_BitVar(g_IsInvisible, Ent))
					set_es(Es, ES_Effects, get_es(Es, ES_Effects) | EF_NODRAW)
				else if(is_user_ghost(Ent) && !Get_BitVar(g_IsInvisible, Ent)) {
					if(Get_BitVar(g_UsingFlashlight, Host))
						set_es(Es, ES_Effects, get_es(Es, ES_Effects) & ~EF_NODRAW)
					else set_es(Es, ES_Effects, get_es(Es, ES_Effects) | EF_NODRAW)
				}
			} else {
				set_es(Es, ES_Effects, get_es(Es, ES_Effects) & ~EF_NODRAW)
			}
		}
	}
	
	return FMRES_HANDLED
}

// ================ MESSAGE + CMD ========================
// =======================================================
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
		case 'C': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_HUMAN])
		case 'T': set_msg_arg_int(2, get_msg_argtype(2), g_TeamScore[TEAM_GHOST])
	}
}

public Message_ClCorpse()
{
	static id
	id = get_msg_arg_int(12)
	
	set_msg_arg_string(1, g_CustomPlayerModel[id])

	return PLUGIN_CONTINUE
}

public Message_TextMsg()
{
	static textmsg[22];
	get_msg_arg_string(2, textmsg, charsmax(textmsg))
	
	if(equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public Message_SendAudio()
{
	static audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public Impulse_100(id)
{
	if(is_user_ghost(id))
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public CMD_NightVision(id)
{
	if(!Get_BitVar(g_Has_NightVision, id))
		return PLUGIN_HANDLED

	if(!Get_BitVar(g_UsingNVG, id)) set_user_nightvision(id, 1, 1, 0)
	else set_user_nightvision(id, 0, 1, 0)
	
	return PLUGIN_HANDLED;
}

public CMD_QButton(id)
{
	if(!is_alive(id))
		return PLUGIN_CONTINUE
	if(!is_user_ghost(id))
		return PLUGIN_CONTINUE
		
	if(get_gametime() - 0.25 > g_KamuiSwitchingDelay[id])
	{
		if(!Get_BitVar(g_UsingKamui, id))
		{
			set_user_noclip(id, 1)
			Engine_SetModel(id, g_GhostModelNC)
			Engine_SetSpeed(id, g_GhostSpeedNC, 1)
			
			Set_BitVar(g_UsingKamui, id)
		} else {
			set_user_noclip(id, 0)
			Engine_SetModel(id, g_GhostModel)
			Engine_SetSpeed(id, g_GhostSpeed, 1)
			
			UnSet_BitVar(g_UsingKamui, id)
		}
		
		g_KamuiSwitchingDelay[id] = get_gametime()
	}
		
	return PLUGIN_HANDLED
}

public CMD_Radio(id)
{
	if(!is_alive(id))
		return PLUGIN_CONTINUE
	if(is_user_ghost(id))
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public CMD_JoinTeam(id)
{
	if(!Get_BitVar(g_Joined, id))
		return PLUGIN_CONTINUE
		
	Open_GameMenu(id)
		
	return PLUGIN_HANDLED
}

public Open_GameMenu(id)
{
	static LangText[64]; formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "GAME_MENU_NAME")
	static Menu; Menu = menu_create(LangText, "MenuHandle_GameMenu")
	
	// 1. Equipment
	formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "GAME_MENU_EQUIP")
	menu_additem(Menu, LangText, "equip")
	
	// 2. Join Spectator
	formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "GAME_MENU_JOINSPEC")
	menu_additem(Menu, LangText, "joinspec")
	
	// 3. Help
	formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "GAME_MENU_HELP")
	menu_additem(Menu, LangText, "help")
	
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)
}

public MenuHandle_GameMenu(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	if(equal(Data, "equip"))
	{
		client_cmd(id, "ghostfury_equipment")
	} else if(equal(Data, "joinspec")) {
		if(get_gametime() >= g_TeamChange[id])
		{
			JoinSpectator(id)
			g_TeamChange[id] = get_gametime() + float(TEAMCHANGE_MAXTIME)
		} else {
			client_print(id, print_center, "%L", GAME_LANG, "GAME_NOTICE_JOINSPECTIME", floatround(g_TeamChange[id] - get_gametime()))
		}
	} else if(equal(Data, "help")) {
		Open_HelpMotd(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public JoinSpectator(id)
{
	if(is_alive(id)) dllfunc(DLLFunc_ClientKill, id)
	
	remove_task(id+TASK_KILL)
	remove_task(id+TASK_HELPHUD)
	
	UnSet_BitVar(g_Joined, id)
	Engine_SetTeam(id, CS_TEAM_SPECTATOR)
}

public Open_HelpMotd(id)
{
	static Motd[2048], Title[32]
	
	formatex(Title, sizeof(Title), "%L", GAME_LANG, "GAME_HELP_TITLE")
	formatex(Motd, sizeof(Motd), "%L", GAME_LANG, "GAME_HELP_MOTD")
	
	replace(Motd, sizeof(Motd), "#VERSION#", VERSION)
	replace(Motd, sizeof(Motd), "#AUTHOR#", AUTHOR)
	
	show_motd(id, Motd, Title)
}

// ==================== HAMSANDWICH ======================
// =======================================================
public fw_PlayerSpawn_Post(id)
{
	if(!is_connected(id)) return
	
	Set_BitVar(g_Joined, id)
	Set_BitVar(g_IsAlive, id)
	
	Reset_Player(id, 0)
	Spawn_PlayerRandom(id)
	
	// Set Human
	Set_PlayerNVG(id, 0, 0, 0, 1)
	fm_set_user_rendering(id)
	set_task(0.01, "Set_LightStart", id)
	SetPlayerFog(id, g_FogStage, g_FogStage, g_FogStage, g_FogDensity)
	
	if(!g_HuntingStart) 
	{
		/*
		if(!Get_BitVar(g_TeamSet, id))
		{
			static T, CT; T = Get_PlayerCount(1, 1); CT = Get_PlayerCount(1, 2)
			
			if(T > CT) Engine_SetTeam(id, CS_TEAM_CT)
			else if(CT > T) Engine_SetTeam(id, CS_TEAM_T)
			else Engine_SetTeam(id, CS_TEAM_CT)
		}*/
	} else {
		user_silentkill(id)
		return
	}
	
	set_user_noclip(id, 0)
	set_user_footsteps(id, 0)
	set_pdata_int(id, m_iRadiosLeft, RADIO_MAXSEND, OFFSET_PLAYER_LINUX)

	// Reset HelpHud
	if(g_HelpHud)
	{	
		set_hudmessage(255, 0, 0, -1.0, 0.85, 2, 30.0, 30.0)
		ShowSyncHudMsg(id, g_HelpHud, "")
	}
	
	Set_PlayerHealth(id, g_HumanHP, 1)
	set_pev(id, pev_gravity, g_HumanGravity)
	cs_set_user_armor(id, g_HumanAP, CS_ARMOR_KEVLAR)
	Engine_ResetSpeed(id)
	
	// Start Weapon
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	fm_give_item(id, "weapon_usp")
	give_ammo(id, 1, CSW_USP)
	give_ammo(id, 1, CSW_USP)

	Engine_SetModel(id, g_PlayerModel[id])
	
	// Fade Out
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, {0,0,0}, id)
	write_short(FixedUnsigned16(2.5, 1<<12))
	write_short(FixedUnsigned16(2.5, 1<<12))
	write_short((0x0000))
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	message_end()
	
	ExecuteForward(g_Forwards[FW_USER_SPAWN], g_fwResult, id)
	
	// Show Info
	static String[96]
	//formatex(String, sizeof(String), "!g%s (%s)!n By !t%s!n", GameName, VERSION, AUTHOR)
	//client_printc(id, String)
	formatex(String, sizeof(String), "!g[%s]!n %L", GameName, GAME_LANG, "GAME_NOTICE_REMINDHELP")
	client_printc(id, String)
	
	client_printc(id, "This is a trial version of Ghost Fury! (Dias Pendragon)")
}

public Reset_Player(id, NewPlayer)
{
	if(NewPlayer)
	{
		UnSet_BitVar(g_IsFemale, id)
		UnSet_BitVar(g_SeenHelp, id)
		
		g_TeamChange[id] = 0.0
	}
	
	remove_task(id+TASK_HELPHUD)
	remove_task(id+TASK_KILL)
	
	UnSet_BitVar(g_IsOriginGhost, id)
	UnSet_BitVar(g_IsInvisible, id)
	UnSet_BitVar(g_IsGhost, id)
	UnSet_BitVar(g_Has_NightVision, id)
	UnSet_BitVar(g_UsingNVG, id)
	UnSet_BitVar(g_UsingKamui, id)
	UnSet_BitVar(g_UsingFlashlight, id)
}

public Spawn_PlayerRandom(id)
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

public Set_LightStart(id) SetPlayerLight(id, g_GameLight)
public fw_PlayerKilled(Victim, Attacker)
{
	if(Get_PlayerCount(1, 1) <= 0) g_WinTeam = TEAM_HUMAN
	
	Check_Gameplay()
}

public fw_PlayerKilled_Post(Victim, Attacker)
{
	ExecuteForward(g_Forwards[FW_USER_DIED], g_fwResult, Victim, Attacker)
	if(!Get_BitVar(g_SeenHelp, Victim))
	{
		set_task(5.0, "Show_HelpHud", Victim+TASK_HELPHUD)
	}
}

public Show_HelpHud(id)
{
	id -= TASK_HELPHUD
	if(!is_connected(id))
		return
	if(is_alive(id))
		return
	if(!g_HelpHud)
		return
		
	static TotalText[256], TipA[96], TipB[96], TipC[96]
	
	formatex(TipA, sizeof(TipA), "%L", GAME_LANG, "LOADING_TIP1")
	formatex(TipB, sizeof(TipB), "%L", GAME_LANG, "LOADING_TIP2")
	formatex(TipC, sizeof(TipC), "%L", GAME_LANG, "LOADING_TIP3")
	formatex(TotalText, sizeof(TotalText), "%L^n- %s^n- %s^n- %s", GAME_LANG, "LOADING_HELP", TipA, TipB, TipC)

	set_hudmessage(255, 170, 0, -1.0, 0.70, 2, 30.0, 30.0)
	ShowSyncHudMsg(id, g_HelpHud, TotalText)
	
	set_task(20.0, "Reset_HelpHud", id+TASK_HELPHUD)
}

public Reset_HelpHud(id)
{
	id -= TASK_HELPHUD
	if(!is_connected(id))
		return
	if(is_alive(id))
		return
		
	Set_BitVar(g_SeenHelp, id)
}

public fw_PlayerTakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStart || g_RoundEnd || !g_HuntingStart)
		return HAM_SUPERCEDE
	if(Victim == Attacker)
		return HAM_SUPERCEDE
	if((is_alive(Attacker) && is_alive(Victim)) && (is_user_ghost(Attacker) && !is_user_ghost(Victim)))
	{
		// Ghost -> Human
		
		if(DamageBits & (1<<24)) return HAM_SUPERCEDE
		if(Damage <= 0.0) return HAM_IGNORED
		
		static Sound[64]
		ArrayGetString(ArS_ClawHit, Get_RandomArray(ArS_ClawHit), Sound, sizeof(Sound))
		
		EmitSound(Victim, CHAN_ITEM, Sound)
		
		if((get_user_health(Victim) - floatround(Damage)) <= 0)
		{ // Killed
			if(Get_PlayerCount(1, 2) > 1)
			{
				Set_PlayerGhost(Victim, Attacker, 0)
				return HAM_SUPERCEDE
			} else {
				g_WinTeam = TEAM_GHOST
				
				// Play Infection Sound
				static DeathSound[64]; 
				switch(get_player_sex(Victim))
				{
					case MALE: ArrayGetString(ArS_MaleDeath, Get_RandomArray(ArS_MaleDeath), DeathSound, sizeof(DeathSound))
					case FEMALE: ArrayGetString(ArS_FemaleDeath, Get_RandomArray(ArS_FemaleDeath), DeathSound, sizeof(DeathSound))
					default: ArrayGetString(ArS_MaleDeath, Get_RandomArray(ArS_MaleDeath), DeathSound, sizeof(DeathSound))
				}
				
				EmitSound(Victim, CHAN_STATIC, DeathSound)
				cs_set_user_money(Attacker, clamp(cs_get_user_money(Attacker) + g_KillReward, 0, 16000))
				
				Check_Gameplay()
				
				return HAM_IGNORED
			}
		}
	} else if((is_alive(Attacker) && is_alive(Victim)) && (is_user_ghost(Victim) && !is_user_ghost(Attacker))) {
		// Human -> Ghost
		if((get_user_health(Victim) - floatround(Damage)) <= 0)
		{ // Killed
			set_user_noclip(Victim, 0)
		}
	}

	return HAM_HANDLED
}

public fw_PlayerTakeDamage_Post(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStart || g_RoundEnd || !g_HuntingStart)
		return HAM_IGNORED
	if(Victim == Attacker)
		return HAM_IGNORED
		
	if((is_alive(Attacker) && is_alive(Victim)) && (is_user_ghost(Victim) && !is_user_ghost(Attacker)))
	{
		// Human -> Ghost
		if(g_GhostPainFree) set_pdata_float(Victim, m_flVelocityModifier, 1.0)
	}
		
	return HAM_HANDLED
}

public fw_WSTraceAttack_Post(Victim, Attacker, Float:Damage, Float:Direction[3], TraceHandle, DamageBits)
{
	if(!g_GameStart || g_RoundEnd || !g_HuntingStart)
		return HAM_IGNORED
	if(Victim == Attacker)
		return HAM_IGNORED
		
	if(is_alive(Attacker) && is_user_ghost(Attacker))
	{
		/*
		static Float:EndPoint[3]
		get_tr2(TraceHandle, TR_vecEndPos, EndPoint)
		
		engfunc(EngFunc_MessageBegin, MSG_ALL, SVC_TEMPENTITY, EndPoint)
		write_byte(TE_SPARKS) //TE_SPARKS
		engfunc(EngFunc_WriteCoord, EndPoint[0])
		engfunc(EngFunc_WriteCoord, EndPoint[1])
		engfunc(EngFunc_WriteCoord, EndPoint[2])
		message_end()*/
	}
		
	return HAM_IGNORED
}

public fw_Ham_ResetMaxSpeed(id)
{
	return (Get_BitVar(g_HasCustomSpeed, id)) ? HAM_SUPERCEDE : HAM_IGNORED
}  

public fw_Ham_PlayerJump(id)
{
	if(!is_alive(id))
		return HAM_IGNORED
	if(!is_user_ghost(id))
		return HAM_IGNORED
		
	if(entity_get_int(id, EV_INT_flags) & FL_ONGROUND) 
	{
		if(get_gametime() - 0.5 > g_PlayerStepSound2[id])
		{
			ArrayGetString(ArS_FootstepJump, Get_RandomArray(ArS_FootstepJump), TempSound, sizeof(TempSound))
			EmitSound(id, CHAN_BODY, TempSound)
			
			g_PlayerStepSound2[id] = get_gametime()
		}
	}
		
	return HAM_HANDLED
}

public fw_UseStationary(entity, caller, activator, use_type)
{
	if (use_type == 2 && is_connected(caller) && is_user_ghost(caller))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == 0 && is_connected(caller) && is_user_ghost(caller))
	{
		set_pev(caller, pev_viewmodel2, g_GhostClawModel)
		set_pev(caller, pev_weaponmodel2, "")	
	}
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_connected(id))
		return HAM_IGNORED
	if(is_user_ghost(id))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_Item_Deploy_Post(weapon_ent)
{
	new owner = fm_cs_get_weapon_ent_owner(weapon_ent)
	if (!is_alive(owner))
		return;
	
	new CSWID; CSWID = cs_get_weapon_id(weapon_ent)
	if(is_user_ghost(owner))
	{
		if(CSWID == CSW_KNIFE)
		{
			set_pev(owner, pev_viewmodel2, g_GhostClawModel)
			set_pev(owner, pev_weaponmodel2, "")
		} else {
			strip_user_weapons(owner)
			give_item(owner, "weapon_knife")
			
			engclient_cmd(owner, "weapon_knife")
		}
	}
}

public Balance_Teams()
{
	new players_count = Get_TotalPlayer(2)
	
	if (players_count < 1) return;
	
	// Split players evenly
	new iTerrors
	new iMaxTerrors = players_count / 2
	new id, CsTeams:team
	
	// First, set everyone to CT
	for (id = 1; id <= g_MaxPlayers; id++)
	{
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing
		if (team == CS_TEAM_SPECTATOR || team == CS_TEAM_UNASSIGNED)
			continue;
		
		// Set team
		Engine_SetTeam(id, CS_TEAM_CT)
	}
	
	// Then randomly move half of the players to Terrorists
	while (iTerrors < iMaxTerrors)
	{
		// Keep looping through all players
		if (++id > g_MaxPlayers) id = 1
		
		// Skip if not connected
		if (!is_user_connected(id))
			continue;
		
		team = cs_get_user_team(id)
		
		// Skip if not playing or already a Terrorist
		if (team != CS_TEAM_CT)
			continue;
		
		// Random chance
		if (random_num(0, 1))
		{
			Engine_SetTeam(id, CS_TEAM_T)
			iTerrors++
		}
	}
}

// ===================== GAMEMASTER ======================
// =======================================================
public Engine_SetModel(id, const Model[])
{
	if(!is_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[AL Engine] CM: Player is not in game (%d)", id)
		return false
	}
	
	remove_task(id+TASK_CHANGEMODEL)
	Set_BitVar(g_HasCustomModel, id)
	
	copy(g_CustomPlayerModel[id], charsmax(g_CustomPlayerModel[]), Model)
	
	#if defined SET_MODELINDEX_OFFSET	
	static modelpath[32+(2*MODELNAME_MAXLENGTH)]
	formatex(modelpath, charsmax(modelpath), "models/player/%s/%s.mdl", Model, Model)
	g_CustomModelIndex[id] = engfunc(EngFunc_ModelIndex, modelpath)
	
	fm_cs_set_user_model_index(id)
	#endif
	
	static currentmodel[MODELNAME_MAXLENGTH]
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
	
	if (!equal(currentmodel, Model))
	{
		fm_cs_user_model_update(id+TASK_CHANGEMODEL)
		fm_cs_set_user_model(id+TASK_CHANGEMODEL)
	}
		
	return true
}

public Engine_ResetModel(id)
{
	if(!is_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[AL Engine] CM: Player is not in game (%d)", id)
		return false;
	}
	
	// Player doesn't have a custom model, no need to reset
	if(!Get_BitVar(g_HasCustomModel, id))
		return true;
	
	remove_task(id+TASK_CHANGEMODEL)
	UnSet_BitVar(g_HasCustomModel, id)
	fm_cs_reset_user_model(id)
	
	return true;
}

public Engine_SetTeam(id, CsTeams:Team)
{
	if(!is_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[AL Engine] CT: Player is not in game (%d)", id)
		return
	}
	
	if(pev_valid(id) != PDATA_SAFE)
		return
	if(cs_get_user_team(id) == Team)
		return

	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Set team offset
	set_pdata_int(id, OFFSET_CSTEAMS, _:Team)
	
	// Send message to update team?
	fm_user_team_update(id)	
}

public Engine_SetSpeed(id, Float:Speed, BlockSpeed)
{
	if(!is_alive(id))
		return
		
	if(BlockSpeed) Set_BitVar(g_HasCustomSpeed, id)
	else UnSet_BitVar(g_HasCustomSpeed, id)
		
	set_pev(id, pev_maxspeed, Speed)
}

public Engine_ResetSpeed(id)
{
	if(!is_alive(id))
		return
		
	UnSet_BitVar(g_HasCustomSpeed, id)
	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)
}

public fm_cs_set_user_model(taskid)
{
	static id; id = taskid - TASK_CHANGEMODEL
	set_user_info(id, "model", g_CustomPlayerModel[id])
}

stock fm_cs_set_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MODELINDEX, g_CustomModelIndex[id])
}

stock fm_cs_reset_user_model_index(id)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	switch(cs_get_user_team(id))
	{
		case CS_TEAM_T: set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_T))
		case CS_TEAM_CT: set_pdata_int(id, OFFSET_MODELINDEX, engfunc(EngFunc_ModelIndex, DEFAULT_MODELINDEX_CT))
	}
}

stock fm_cs_get_user_model(id, model[], len)
{
	get_user_info(id, "model", model, len)
}

stock fm_cs_reset_user_model(id)
{
	// Set some generic model and let CS automatically reset player model to default
	copy(g_CustomPlayerModel[id], charsmax(g_CustomPlayerModel[]), "gordon")
	fm_cs_user_model_update(id+TASK_CHANGEMODEL)
#if defined SET_MODELINDEX_OFFSET
	fm_cs_reset_user_model_index(id)
#endif
}

stock fm_cs_user_model_update(taskid)
{
	new Float:current_time
	current_time = get_gametime()
	
	if(current_time - g_ModelChangeTargetTime >= MODELCHANGE_DELAY)
	{
		fm_cs_set_user_model(taskid)
		g_ModelChangeTargetTime = current_time
	} else {
		set_task((g_ModelChangeTargetTime + MODELCHANGE_DELAY) - current_time, "fm_cs_set_user_model", taskid)
		g_ModelChangeTargetTime = g_ModelChangeTargetTime + MODELCHANGE_DELAY
	}
}


// Send User Team Message (Note: this next message can be received by other plugins)
public fm_cs_set_user_team_msg(taskid)
{
	// Tell everyone my new team
	emessage_begin(MSG_ALL, g_MsgTeamInfo)
	ewrite_byte(ID_TEAMMSG) // player
	ewrite_string(CS_TEAM_NAMES[_:cs_get_user_team(ID_TEAMMSG)]) // team
	emessage_end()
	
	// Fix for AMXX/CZ bots which update team paramater from ScoreInfo message
	emessage_begin(MSG_BROADCAST, g_MsgScoreInfo)
	ewrite_byte(ID_TEAMMSG) // id
	ewrite_short(pev(ID_TEAMMSG, pev_frags)) // frags
	ewrite_short(cs_get_user_deaths(ID_TEAMMSG)) // deaths
	ewrite_short(0) // class?
	ewrite_short(_:cs_get_user_team(ID_TEAMMSG)) // team
	emessage_end()
}

// Update Player's Team on all clients (adding needed delays)
stock fm_user_team_update(id)
{	
	new Float:current_time
	current_time = get_gametime()
	
	if (current_time - g_TeamMsgTargetTime >= TEAMCHANGE_DELAY)
	{
		set_task(0.1, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = current_time + TEAMCHANGE_DELAY
	}
	else
	{
		set_task((g_TeamMsgTargetTime + TEAMCHANGE_DELAY) - current_time, "fm_cs_set_user_team_msg", id+TASK_TEAMMSG)
		g_TeamMsgTargetTime = g_TeamMsgTargetTime + TEAMCHANGE_DELAY
	}
}

/* ===============================
------------- SAFETY -------------
=================================*/
public Register_SafetyFunc()
{
	register_event("CurWeapon", "Safety_CurWeapon", "be", "1=1")
	
	RegisterHam(Ham_Spawn, "player", "fw_Safety_Spawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_Safety_Killed_Post", 1)
}

public Register_SafetyFuncBot(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Safety_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_Safety_Killed_Post", 1)
}

public Safety_Connected(id)
{
	Set_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_Disconnected(id)
{
	UnSet_BitVar(g_IsConnected, id)
	UnSet_BitVar(g_IsAlive, id)
	
	g_PlayerWeapon[id] = 0
}

public Safety_CurWeapon(id)
{
	if(!is_alive(id))
		return
		
	static CSW; CSW = read_data(2)
	if(g_PlayerWeapon[id] != CSW) g_PlayerWeapon[id] = CSW
}

public fw_Safety_Spawn_Post(id)
{
	if(!is_user_alive(id))
		return
		
	Set_BitVar(g_IsAlive, id)
}

public fw_Safety_Killed_Post(id)
{
	UnSet_BitVar(g_IsAlive, id)
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0

	return 1
}

public is_alive(id)
{
	if(!is_connected(id))
		return 0
	if(!Get_BitVar(g_IsAlive, id))
		return 0
		
	return 1
}

public get_player_weapon(id)
{
	if(!is_alive(id))
		return 0
	
	return g_PlayerWeapon[id]
}

// ===================== DATA LOAD =======================
// =======================================================
public Load_GameConfig()
{
	static Buffer[64], Buffer2[3][8]
	
	// Gameplay
	g_MinPlayer = Setting_Load_Int(GAME_SETTINGFILE, "Gameplay", "MIN_PLAYER")
	g_CountDown_Time = Setting_Load_Int(GAME_SETTINGFILE, "Gameplay", "COUNTDOWN_TIME")
	g_KillReward = Setting_Load_Int(GAME_SETTINGFILE, "Gameplay", "KILL_REWARD")
	
	// Night Vision
	g_NVG_Alpha = Setting_Load_Int(GAME_SETTINGFILE, "Night Vision", "NVG_ALPHA")

	Setting_Load_String(GAME_SETTINGFILE, "Night Vision", "NVG_HUMAN_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], 7, Buffer2[1], 7, Buffer2[2], 7)
	g_NVG_HumanColor[0] = str_to_num(Buffer2[0])
	g_NVG_HumanColor[1] = str_to_num(Buffer2[1])
	g_NVG_HumanColor[2] = str_to_num(Buffer2[2])
	
	Setting_Load_String(GAME_SETTINGFILE, "Night Vision", "NVG_GHOST_COLOR", Buffer, sizeof(Buffer))
	parse(Buffer, Buffer2[0], 7, Buffer2[1], 7, Buffer2[2], 7)
	g_NVG_GhostColor[0] = str_to_num(Buffer2[0])
	g_NVG_GhostColor[1] = str_to_num(Buffer2[1])
	g_NVG_GhostColor[2] = str_to_num(Buffer2[2])	
	
	// Human
	g_HumanHP = Setting_Load_Int(PLAYER_SETTINGFILE, "Human", "HUMAN_HP")
	g_HumanAP = Setting_Load_Int(PLAYER_SETTINGFILE, "Human", "HUMAN_AP")
	
	Setting_Load_String(PLAYER_SETTINGFILE, "Human", "HUMAN_GRAVITY", Buffer, sizeof(Buffer));  g_HumanGravity = str_to_float(Buffer)
	Setting_Load_StringArray(PLAYER_SETTINGFILE, "Human", "HUMAN_MODEL_MALE", HumanModel_Male)
	Setting_Load_StringArray(PLAYER_SETTINGFILE, "Human", "HUMAN_MODEL_FEMALE", HumanModel_Female)
	
	// Ghost
	g_GhostOHP = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_ORIGIN_HP")
	g_GhostOAP = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_ORIGIN_AP")
	g_GhostHHP = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_HOST_HP")
	g_GhostHAP = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_HOST_AP")
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_GRAVITY", Buffer, sizeof(Buffer)); g_GhostGravity = str_to_float(Buffer)
	g_GhostSpeed = float(Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_SPEED"))
	g_GhostSpeedNC = float(Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_SPEED_NOCLIP"))
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_MODEL", g_GhostModel, sizeof(g_GhostModel))
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_MODEL_NOCLIP", g_GhostModelNC, sizeof(g_GhostModelNC))
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_CLAW_MODEL", g_GhostClawModel, sizeof(g_GhostClawModel))
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_CLAW_MODEL_INV", g_GhostClawModelInv, sizeof(g_GhostClawModelInv))
	g_GhostPainFree = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_PAINFREE")
	g_GhostNoFallDamage = Setting_Load_Int(PLAYER_SETTINGFILE, "Ghost", "GHOST_NOFALLDAMAGE")
	Setting_Load_String(PLAYER_SETTINGFILE, "Ghost", "GHOST_CLAWRADIUS", Buffer, sizeof(Buffer)); g_GhostClawRad = str_to_float(Buffer)
	
	// Sounds
	Setting_Load_String(SOUND_SETTINGFILE, "Sound", "SOUND_COUNTING", S_CountSound, sizeof(S_CountSound))
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_GAMESTART", ArS_SoundStart)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_MESSAGE", ArS_Message)
	
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_GHOSTWIN", ArS_GhostWin)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_HUMANWIN", ArS_HumanWin)
	
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_MALE_DEATH", ArS_MaleDeath)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_FEMALE_DEATH", ArS_FemaleDeath)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_GHOST_COMING", ArS_GhostComing)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_GHOST_IDLE", ArS_GhostIdle)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_GHOST_DEATH", ArS_GhostDeath)
	
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_CLAW_DRAW", ArS_ClawDraw)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_CLAW_SWING", ArS_ClawSwing)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_CLAW_SLASH", ArS_ClawSlash)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_CLAW_STAB", ArS_ClawStab)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_CLAW_HIT", ArS_ClawHit)
	
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_FOOTSTEP_RUN", ArS_FootstepRun)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_FOOTSTEP_JUMP", ArS_FootstepJump)
	Setting_Load_StringArray(SOUND_SETTINGFILE, "Sound", "SOUND_FOOTSTEP_LAND", ArS_FootstepLand)
}

public Precache_GameFiles()
{
	new BufferA[128], BufferB[128], i
	
	// Human
	for(i = 0; i < ArraySize(HumanModel_Male); i++) 
	{
		ArrayGetString(HumanModel_Male, i, BufferA, sizeof(BufferA)); formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", BufferA, BufferA)
		engfunc(EngFunc_PrecacheModel, BufferB); 
	}
	for(i = 0; i < ArraySize(HumanModel_Female); i++) 
	{
		ArrayGetString(HumanModel_Female, i, BufferA, sizeof(BufferA)); formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", BufferA, BufferA)
		engfunc(EngFunc_PrecacheModel, BufferB); 
	}	
	
	// Ghost
	formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", g_GhostModel, g_GhostModel); engfunc(EngFunc_PrecacheModel, BufferB)
	formatex(BufferB, sizeof(BufferB), "models/player/%s/%s.mdl", g_GhostModelNC, g_GhostModelNC); engfunc(EngFunc_PrecacheModel, BufferB)
	engfunc(EngFunc_PrecacheModel, g_GhostClawModel)
	engfunc(EngFunc_PrecacheModel, g_GhostClawModelInv)
	
	// Sounds
	for (new i = 1; i <= 10; i++) { formatex(BufferB, charsmax(BufferB), S_CountSound, i); engfunc(EngFunc_PrecacheSound, BufferB); }	
	
	for(i = 0; i < ArraySize(ArS_SoundStart); i++) { ArrayGetString(ArS_SoundStart, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_Message); i++) { ArrayGetString(ArS_Message, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	
	for(i = 0; i < ArraySize(ArS_GhostWin); i++) { ArrayGetString(ArS_GhostWin, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_HumanWin); i++) { ArrayGetString(ArS_HumanWin, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }

	for(i = 0; i < ArraySize(ArS_GhostIdle); i++) { ArrayGetString(ArS_GhostIdle, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_GhostComing); i++) { ArrayGetString(ArS_GhostComing, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_GhostDeath); i++) { ArrayGetString(ArS_GhostDeath, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_FemaleDeath); i++) { ArrayGetString(ArS_FemaleDeath, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_MaleDeath); i++) { ArrayGetString(ArS_MaleDeath, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	
	for(i = 0; i < ArraySize(ArS_ClawDraw); i++) { ArrayGetString(ArS_ClawDraw, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_ClawSwing); i++) { ArrayGetString(ArS_ClawSwing, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_ClawSlash); i++) { ArrayGetString(ArS_ClawSlash, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_ClawStab); i++) { ArrayGetString(ArS_ClawStab, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_ClawHit); i++) { ArrayGetString(ArS_ClawHit, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	
	for(i = 0; i < ArraySize(ArS_FootstepRun); i++) { ArrayGetString(ArS_FootstepRun, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_FootstepJump); i++) { ArrayGetString(ArS_FootstepJump, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
	for(i = 0; i < ArraySize(ArS_FootstepLand); i++) { ArrayGetString(ArS_FootstepLand, i, BufferA, sizeof(BufferA)); engfunc(EngFunc_PrecacheSound, BufferA); }
}

stock Setting_Load_Int(const filename[], const setting_section[], setting_key[])
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty filename")
		return false;
	}
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[AL] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
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

stock Setting_Load_StringArray(const filename[], const setting_section[], setting_key[], Array:array_handle)
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty filename")
		return false;
	}

	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty section/key")
		return false;
	}
	
	if (array_handle == Invalid_Array)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Array not initialized")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[AL] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
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

stock Setting_Load_String(const filename[], const setting_section[], setting_key[], return_string[], string_size)
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty filename")
		return false;
	}

	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[AL] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[128]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s/%s", path, GAME_FOLDER, filename)
	
	// File not present
	if (!file_exists(path))
	{
		static DataA[128]; formatex(DataA, sizeof(DataA), "[AL] Can't load: %s", path)
		set_fail_state(DataA)
		
		return false;
	}
	
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

// ======================== OTHER ========================
// =======================================================
stock is_hull_vacant(Float:Origin[3], hull)
{
	engfunc(EngFunc_TraceHull, Origin, Origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
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

stock SetPlayerFog( const index = 0, const red = 127, const green = 127, const blue = 127, const Float:density_f = 0.001, bool:clear = false)
{
	if(!g_Fog) return
	
	static density; density = _:floatclamp( density_f, 0.0001, 0.25 ) * _:!clear;
        
	message_begin( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST, g_MsgFog, .player = index );
	write_byte( clamp( red  , 0, 255 ) );
	write_byte( clamp( green, 0, 255 ) );
	write_byte( clamp( blue , 0, 255 ) );
	write_long( _:density );
	message_end();
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

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock StopSound(id) client_cmd(id, "mp3 stop; stopsound")
stock EmitSound(id, Channel, const Sound[]) emit_sound(id, Channel, Sound, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
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
			if(!is_connected(i))
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

stock Get_PlayerCount(Alive, Team)
// Alive: 0 - Dead | 1 - Alive | 2 - Both
// Team: 1 - T | 2 - CT
{
	new Flag[4], Flag2[12]
	new Players[32], PlayerNum

	if(!Alive) formatex(Flag, sizeof(Flag), "%sb", Flag)
	else if(Alive == 1) formatex(Flag, sizeof(Flag), "%sa", Flag)
	
	if(Team == 1) 
	{
		formatex(Flag, sizeof(Flag), "%se", Flag)
		formatex(Flag2, sizeof(Flag2), "TERRORIST", Flag)
	} else if(Team == 2) 
	{
		formatex(Flag, sizeof(Flag), "%se", Flag)
		formatex(Flag2, sizeof(Flag2), "CT", Flag)
	}
	
	get_players(Players, PlayerNum, Flag, Flag2)
	
	return PlayerNum
}

stock Get_TotalPlayer(Alive)
{
	return Get_PlayerCount(Alive, 1) + Get_PlayerCount(Alive, 2)
}

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
}

public is_user_ghost(id) return Get_BitVar(g_IsGhost, id)
stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_WEAPON_LINUX);
}

stock get_player_sex(id)
{
	if(!is_connected(id))
		return 0	
	if(Get_BitVar(g_IsFemale, id))
		return FEMALE
		
	return MALE
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

stock FixedUnsigned16(Float:flValue, iScale)
{
	new iOutput;

	iOutput = floatround(flValue * iScale);

	if ( iOutput < 0 )
		iOutput = 0;

	if ( iOutput > 0xFFFF )
		iOutput = 0xFFFF;

	return iOutput;
}

stock fm_cs_get_user_team(id)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return 0;
	
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_PLAYER_LINUX)
}

stock fm_cs_set_user_deaths(id, value)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_CSDEATHS, value, OFFSET_PLAYER_LINUX)
}

public Set_Scoreboard_Attrib(id, Attrib) // 0 - Nothing; 1 - Dead; 2 - VIP
{
	message_begin(MSG_BROADCAST, g_MsgScoreAttrib)
	write_byte(id) // id
	switch(Attrib)
	{
		case 1: write_byte(1<<0)
		case 2: write_byte(1<<2)
		default: write_byte(0)
	}
	message_end()	
}

stock MakeBlood(const Float:Origin[3])
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

stock Set_WeaponAnim(id, anim)
{
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock Set_Player_NextAttack(id, Float:Time)
{
	if(pev_valid(id) != PDATA_SAFE)
		return
		
	set_pdata_float(id, 83, Time, 5)
}

stock Float:Get_RoundTimeLeft()
{
	return (g_RoundTimeLeft > 0.0) ? (g_RoundTimeLeft - get_gametime()) : -1.0
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
