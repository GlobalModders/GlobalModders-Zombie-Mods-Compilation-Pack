#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <gamemaster>
#include <fun>
#include <xs>

#define PLUGIN "Zombie Giant (Limited Edition)"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define LANG_FILE "zombie_giant.txt"
#define LANG_DEFAULT LANG_SERVER
#define GAMENAME "Zombie Giant"

// Task
#define TASK_COUNTDOWN 15110
#define TASK_ROUNDTIME 15111

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// HUD
#define HUD_WIN_X -1.0
#define HUD_WIN_Y 0.20
#define HUD_NOTICE_X -1.0
#define HUD_NOTICE_Y 0.25
#define HUD_NOTICE2_X -1.0
#define HUD_NOTICE2_Y 0.70

// Environment
#define ENV_RAIN 0
#define ENV_SNOW 0
#define ENV_FOG 1
#define ENV_FOG_DENSITY "0.0005"
#define ENV_FOG_COLOR "255 212 85"

new const Env_Sky[1][] =
{
	"Des"
}

// Model Config
new const Model_Player[8][] =
{
	"gign",
	"gsg9",
	"urban",
	"sas",
	"arctic",
	"leet",
	"guerilla",
	"terror"
}

// Sound Config
new const Sound_RoundStart[1][] =
{
	"zombie_giant/zombie_select.wav"
}

new const Sound_GameStart[1][] =
{
	"zombie_giant/zombie_spawn.wav"
}

new const Sound_Ambience[3][] =
{
	"zombie_giant/ambience/Continuing_Suspense.mp3",
	"zombie_giant/ambience/L.O.T.B_The-Fiend.mp3",
	"zombie_giant/ambience/Luminous_Sword.mp3"
}

new const Sound_Result[1][] =
{
	"zombie_giant/zombie_result.wav"
}

new const Vox_Count[] = "zombie_giant/count/%i.wav"

new const Vox_WinHuman[] = "zombie_giant/win_human.wav"
new const Vox_WinBoss[] = "zombie_giant/win_zombie.wav"

// Next
const PDATA_SAFE = 2

enum
{
	TEAM_NONE = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN,
	TEAM_SPECTATOR
}

// Block Round Event
new g_BlockedObj_Forward
new g_BlockedObj[15][32] =
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

#define CAMERA_CLASSNAME "nikon_d810"
#define CAMERA_MODEL "models/winebottle.mdl"

// Cvars
new g_Cvar_MinPlayer, g_Cvar_MapLight, g_Cvar_CountTime
new g_Cvar_HumanHealth, g_Cvar_HumanArmor, g_Cvar_HumanGravity
new g_CvarPointer_RoundTime

// Main Cvars
new g_GameStarted, g_RoundStarted, g_GameEnded, g_MaxPlayers, g_Countdown, g_CountTime
new g_IsZombie, g_Joined, Float:g_PassedTime, Float:g_PassedTime2, g_MaxHealth[33], g_ViewCamera, 
g_MyCamera[33], Float:g_CameraOrigin[33][3], g_MyClass[33], g_Has_NightVision, g_UsingNVG
new g_MsgSayText, g_SyncHud_HP[2], g_SyncHud_MP, g_MsgScreenFade, g_TotalClass, g_MyMana[33]
new Float:g_PlayerSpawn_Point[64][3], g_PlayerSpawn_Count
new Float:g_BossSpawn_Point[64][3], g_BossSpawn_Count, g_BossSpawnCode

new Array:GiantBaseHP
new const SoundNVG[2][] = { "items/nvg_off.wav", "items/nvg_on.wav"}

// Forwards
#define MAX_FORWARD 8

enum
{
	FWD_ROUND_NEW = 0,
	FWD_ROUND_START,
	FWD_GAME_START,
	FWD_GAME_END,
	FWD_BECOME_GIANT,
	FWD_USER_KILL,
	FWD_RUNTIME,
	FWD_EQUIP
}

new g_Forwards[MAX_FORWARD], g_fwResult

// Safety
new g_HamBot
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

// =============== Changing Model ===============
#define MODELCHANGE_DELAY 0.1 	// Delay between model changes (increase if getting SVC_BAD kicks)
#define ROUNDSTART_DELAY 2.0 	// Delay after roundstart (increase if getting kicks at round start)
#define SET_MODELINDEX_OFFSET 	// Enable custom hitboxes (experimental, might lag your server badly with some models)

#define MODELNAME_MAXLENGTH 32
#define TASK_CHANGEMODEL 1962

new const DEFAULT_MODELINDEX_T[] = "models/player/terror/terror.mdl"
new const DEFAULT_MODELINDEX_CT[] = "models/player/urban/urban.mdl"

new g_HasCustomModel
new Float:g_ModelChangeTargetTime
new g_CustomPlayerModel[MAX_PLAYERS+1][MODELNAME_MAXLENGTH]
#if defined SET_MODELINDEX_OFFSET
new g_CustomModelIndex[MAX_PLAYERS+1]
#endif

#define OFFSET_CSTEAMS 114
#define OFFSET_MODELINDEX 491 // Orangutanz
// ==============================================

// =============== Changing Team ================
#define TEAMCHANGE_DELAY 0.1

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new Float:g_TeamMsgTargetTime
new g_MsgTeamInfo, g_MsgScoreInfo
// ==============================================

// =============== Changing Speed ===============
#define Ham_CS_Player_ResetMaxSpeed Ham_Item_PreFrame 
#define SV_MAXSPEED 999.0

new g_HasCustomSpeed
// ==============================================

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_dictionary(LANG_FILE)
	Register_SafetyFunc()
	
	// Event
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_will_restart_in")
	register_event("DeathMsg", "Event_Death", "a")
	register_logevent("Event_RoundStart", 2, "1=Round_Start")
	register_logevent("Event_RoundEnd", 2, "1=Round_End")	
	
	// Fakemeta
	unregister_forward(FM_Spawn, g_BlockedObj_Forward)
	register_forward(FM_StartFrame, "fw_StartFrame")
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	
	// Ham
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled_Post", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
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
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "fw_Ham_ResetMaxSpeed")
	
	// Message
	register_message(get_user_msgid("StatusIcon"), "Message_StatusIcon")
	register_message(get_user_msgid("Health"), "Message_Health")
	register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
	
	// Team Mananger
	register_clcmd("chooseteam", "CMD_JoinTeam")
	register_clcmd("jointeam", "CMD_JoinTeam")
	register_clcmd("joinclass", "CMD_JoinTeam")
	register_clcmd("nightvision", "CMD_NightVision")
	
	// Collect Spawns Point
	collect_spawns_ent("info_player_start")
	collect_spawns_ent2("info_player_deathmatch")
	
	// Forward
	g_Forwards[FWD_ROUND_NEW] = CreateMultiForward("zg_round_new", ET_IGNORE)
	g_Forwards[FWD_ROUND_START] = CreateMultiForward("zg_round_start", ET_IGNORE)
	g_Forwards[FWD_GAME_START] = CreateMultiForward("zg_game_start", ET_IGNORE)
	g_Forwards[FWD_GAME_END] = CreateMultiForward("zg_game_end", ET_IGNORE, FP_CELL)
	g_Forwards[FWD_BECOME_GIANT] = CreateMultiForward("zg_become_giant", ET_IGNORE, FP_CELL, FP_CELL, FP_FLOAT, FP_FLOAT, FP_FLOAT)
	g_Forwards[FWD_USER_KILL] = CreateMultiForward("zg_user_kill", ET_IGNORE, FP_CELL, FP_CELL, FP_CELL, FP_CELL)
	g_Forwards[FWD_RUNTIME] = CreateMultiForward("zg_runningtime", ET_IGNORE)
	g_Forwards[FWD_EQUIP] = CreateMultiForward("zg_equipment_menu", ET_IGNORE, FP_CELL)

	// Vars
	g_MaxPlayers = get_maxplayers()
	
	g_CvarPointer_RoundTime = get_cvar_pointer("mp_roundtime")
	g_Cvar_MinPlayer = register_cvar("zg_minplayer", "2")
	g_Cvar_MapLight = register_cvar("zb_maplight", "d")
	g_Cvar_CountTime = register_cvar("zg_counttime", "12")
	
	g_Cvar_HumanHealth = register_cvar("zg_human_health", "1000")
	g_Cvar_HumanArmor = register_cvar("zg_human_armor", "100")
	g_Cvar_HumanGravity = register_cvar("zg_human_gravity", "1.0")
	
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")	
	g_MsgSayText = get_user_msgid("SayText")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	
	g_SyncHud_HP[0] = CreateHudSyncObj(1)
	g_SyncHud_HP[1] = CreateHudSyncObj(2)
	g_SyncHud_MP = CreateHudSyncObj(3)
	
	// First Setting
	Round_Setting()
	
	// Patch Round Infinity
	GM_EndRound_Block(true)
}

public plugin_precache()
{
	GiantBaseHP = ArrayCreate(1, 1)
	
	// Register Forward
	g_BlockedObj_Forward = register_forward(FM_Spawn, "fw_BlockedObj_Spawn")	
	
	// Precache 
	new i, BufferB[128]
	
	precache_model(CAMERA_MODEL)
	
	for(i = 0; i < sizeof(Sound_RoundStart); i++)
		precache_sound(Sound_RoundStart[i])
	for(i = 0; i < sizeof(Sound_GameStart); i++)
		precache_sound(Sound_GameStart[i])
	for(i = 0; i < sizeof(Sound_Result); i++)
		precache_sound(Sound_Result[i])
	for(i = 0; i < sizeof(Sound_Ambience); i++)
		precache_sound(Sound_Ambience[i])
		
	for(i = 1; i <= 10; i++)
	{
		formatex(BufferB, charsmax(BufferB), Vox_Count, i); 
		engfunc(EngFunc_PrecacheSound, BufferB); 
	}		
		
	precache_sound(Vox_WinHuman)
	precache_sound(Vox_WinBoss)
	
	// Handle
	Environment_Setting()
}

public plugin_natives()
{
	register_native("zg_is_giant", "Native_IsGiant", 1)
	register_native("zg_get_giantclass", "Native_GetClass", 1)
	register_native("zg_get_maxhealth", "Native_GetMaxHP", 1)
	register_native("zg_get_nightvision", "Native_GetNVG", 1)
	register_native("zg_set_nightvision", "Native_SetNVG", 1)
	register_native("zg_get_mana", "Native_GetMP", 1)
	register_native("zg_set_mana", "Native_SetMP", 1)
	
	register_native("zg_register_giantclass", "Native_RegisterClass", 1)
}

public plugin_cfg()
{
	server_cmd("mp_roundtime 5")
	server_cmd("mp_freezetime 3")
	server_cmd("mp_flashlight 1")
	server_cmd("mp_friendlyfire 0")
	server_cmd("mp_limitteams 0")
	server_cmd("mp_autoteambalance 0")
	
	set_cvar_num("sv_maxspeed", 999)
	set_cvar_num("sv_skycolor_r", 0)
	set_cvar_num("sv_skycolor_g", 0)
	set_cvar_num("sv_skycolor_b", 0)	
	
	// Sky
	set_cvar_string("sv_skyname", Env_Sky[random(sizeof(Env_Sky))])
	
	// New Round
	Event_NewRound()
}

public Native_IsGiant(id)
{
	if(!is_connected(id))
		return 0
		
	return Get_BitVar(g_IsZombie, id) ? 1 : 0
}

public Native_GetClass(id)
{
	if(!is_connected(id))
	{
		server_print("[ZG] Error: Get Class with unconnected User!")
		return -1
	}
	
	return g_MyClass[id]
}

public Native_GetMaxHP(id)
{
	if(!is_connected(id))
		return 0
		
	return g_MaxHealth[id]
}

public Native_GetNVG(id, Have, On)
{
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

public Native_SetNVG(id, Give, On, Sound, IgnoredHad)
{
	if(!is_connected(id))
		return
		
	if(Give) Set_BitVar(g_Has_NightVision, id)
	set_user_nightvision(id, On, Sound, IgnoredHad)
}

public Native_GetMP(id)
{
	if(!is_connected(id))
		return 0
		
	return g_MyMana[id]
}

public Native_SetMP(id, MP)
{
	if(!is_connected(id))
		return
	
	g_MyMana[id] = MP
}

public Native_RegisterClass(BaseHealth)
{
	ArrayPushCell(GiantBaseHP, BaseHealth)
	
	g_TotalClass++
	return g_TotalClass - 1
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

public Round_Setting()
{
	g_GameStarted = 0
	g_GameEnded = 0
	g_RoundStarted = 0
}

public client_putinserver(id)
{
	Safety_Connected(id)
	Reset_Player(id, 1)
	
	set_task(0.1, "Set_LightStart", id)
	set_task(0.25, "Set_NewTeam", id)
	
	remove_task(id+TASK_CHANGEMODEL)

	UnSet_BitVar(g_HasCustomModel, id)
	UnSet_BitVar(g_HasCustomSpeed, id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}
 
public Register_HamBot(id)
{
	Register_SafetyFuncBot(id)
	
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fw_PlayerKilled_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage")
}
 
public client_disconnect(id)
{
	Safety_Disconnected(id)
	
	if(pev_valid(g_MyCamera[id])) set_pev(g_MyCamera[id], pev_flags, FL_KILLME)
	
	remove_task(id+TASK_CHANGEMODEL)
	remove_task(id+TASK_TEAMMSG)
	
	UnSet_BitVar(g_HasCustomModel, id)
	UnSet_BitVar(g_HasCustomSpeed, id)
}

public Environment_Setting()
{
	new BufferB[128]
	new Enable
	
	// Weather & Sky
	Enable = ENV_RAIN; if(Enable) engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"))
	Enable = ENV_SNOW; if(Enable)engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_snow"))	
	Enable = ENV_FOG; 
	if(Enable)
	{
		remove_entity_name("env_fog")
		
		new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
		if (pev_valid(ent))
		{
			fm_set_kvd(ent, "density", ENV_FOG_DENSITY, "env_fog")
			fm_set_kvd(ent, "rendercolor", ENV_FOG_COLOR, "env_fog")
		}
	}
	
	// Sky
	for(new i = 0; i < sizeof(Env_Sky); i++)
	{
		// Preache custom sky files
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sbk.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sdn.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sft.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%slf.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%srt.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)
		formatex(BufferB, charsmax(BufferB), "gfx/env/%sup.tga", Env_Sky[i]); engfunc(EngFunc_PrecacheGeneric, BufferB)		
	}		
}

public Event_Time()
{
	if(!g_GameStarted) client_print(0, print_center, "%L", LANG_DEFAULT, "NOTICE_WAITFORPLAYER")
	if(g_GameStarted && (Get_TotalInPlayer(2) < get_pcvar_num(g_Cvar_MinPlayer)))
	{
		g_GameStarted = 0
		g_GameEnded = 0
		g_RoundStarted = 0
	}
	if(!g_GameStarted && (Get_TotalInPlayer(2) >= get_pcvar_num(g_Cvar_MinPlayer))) // START GAME NOW :D
	{
		g_GameStarted = 1
		g_RoundStarted = 0
		
		End_Round(5.0, 1, CS_TEAM_UNASSIGNED)
	}
	
	// Show HUD
	Show_ScoreHud()
	Show_PlayerHUD()
	
	// Check Gameplay
	Check_Gameplay()
	
	// Exe
	ExecuteForward(g_Forwards[FWD_RUNTIME], g_fwResult)
}

public Event_Time2()
{
	Show_StatusHud()
}

public Check_Gameplay()
{
	if(!g_GameStarted || g_GameEnded || !g_RoundStarted)
		return
		
	if(Get_PlayerCount(1, 2) <= 0) End_Round(5.0, 0, CS_TEAM_T)
	else if(Get_ZombieAlive() <= 0) End_Round(5.0, 0, CS_TEAM_CT)
}

public Set_NewTeam(id)
{
	if(!is_connected(id))
		return
	if(is_alive(id))
		return
		
	Set_PlayerTeam(id, CS_TEAM_CT)
}

public Show_ScoreHud()
{
	
}

public Show_PlayerHUD()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
		if(cs_get_user_team(i) != CS_TEAM_T)
			continue
		
		
	}
}

public Show_StatusHud()
{
	static TempText[61]; 
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
		if(cs_get_user_team(i) != CS_TEAM_T)
			continue
			
		if(g_MyMana[i] < 100)
			g_MyMana[i] = min(g_MyMana[i] + 5, 100)
			
		if(!g_MaxHealth[i])
			continue
			
		
		// HP
		set_hudmessage(255, 0, 0, 0.225, 0.10, 0, 0.0, 0.6, 0.0, 0.0)
		ShowSyncHudMsg(i, g_SyncHud_HP[0], "____________________________________________________________")

		formatex(TempText, 60, "____________________________________________________________")
		TempText[(60 * get_user_health(i)) / g_MaxHealth[i]] = EOS
		
		set_hudmessage(255, 255, 0, 0.225, 0.10, 0, 0.0, 0.6, 0.0, 0.0)
		ShowSyncHudMsg(i, g_SyncHud_HP[1], TempText)
		
		// MP
		formatex(TempText, 60, "____________________________________________________________")
		TempText[(60 * g_MyMana[i]) / 100] = EOS
	
		set_hudmessage(0, 255, 0, 0.225, 0.12, 0, 0.0, 0.6, 0.0, 0.0)
		ShowSyncHudMsg(i, g_SyncHud_MP, TempText)
	}
}

public client_PreThink(id)
{
	if(!is_user_alive(id))
		return
		
	// Handle Camera
	if(g_MyCamera[id] && Get_BitVar(g_ViewCamera, id))
	{
		static Float:Origin[3], Float:CamOrigin[3]
		pev(id, pev_origin, Origin)
		
		static Float:vAngle[3], Float:Angles[3]
		pev(id, pev_angles, Angles)
		pev(id, pev_v_angle, vAngle)
		
		static Float:i
		for(i = 256.0; i >= 0.0; i -= 0.1)
		{
			CamOrigin[0] = floatcos(vAngle[ 1 ], degrees) * -i
			CamOrigin[1] = floatsin(vAngle[ 1 ], degrees) * -i
			CamOrigin[2] = i - (i / 4)
			CamOrigin[0] += Origin[0]
			CamOrigin[1] += Origin[1]
			CamOrigin[2] += Origin[2]
			
			if(PointContents(CamOrigin) != CONTENTS_SOLID && PointContents(CamOrigin) != CONTENTS_SKY)
				break;
		}
		
		vAngle[0] = 20.0
		
		set_pev(g_MyCamera[id], pev_origin, CamOrigin)
		set_pev(g_MyCamera[id], pev_angles, vAngle)
		set_pev(g_MyCamera[id], pev_v_angle, vAngle)
	}
}
	
public Create_Camera(id)
{
	if(pev_valid(g_MyCamera[id]))
		return
	
	static Float:vAngle[3], Float:Angles[3]
	
	pev(id, pev_origin, g_CameraOrigin[id])
	pev(id, pev_v_angle, vAngle)
	pev(id, pev_angles, Angles)

	static Ent; Ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if(!pev_valid(Ent)) return

	set_pev(Ent, pev_classname, CAMERA_CLASSNAME)

	set_pev(Ent, pev_solid, 0)
	set_pev(Ent, pev_movetype, MOVETYPE_NOCLIP)
	set_pev(Ent, pev_owner, id)
	
	engfunc(EngFunc_SetModel, Ent, CAMERA_MODEL)

	static Float:Mins[3], Float:Maxs[3]
	
	Mins[0] = -1.0
	Mins[1] = -1.0
	Mins[2] = -1.0
	Maxs[0] = 1.0
	Maxs[1] = 1.0
	Maxs[2] = 1.0

	entity_set_size(Ent, Mins, Maxs)

	set_pev(Ent, pev_origin, g_CameraOrigin[id])
	set_pev(Ent, pev_v_angle, vAngle)
	set_pev(Ent, pev_angles, Angles)

	fm_set_rendering(Ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	g_MyCamera[id] = Ent;
}

public View_Camera(id, Reset)
{
	if(!is_valid_ent(g_MyCamera[id]))
		Create_Camera(id)
	
	if(!Reset) 
	{
		attach_view(id, g_MyCamera[id])
		Set_BitVar(g_ViewCamera, id)
	} else {
		attach_view(id, id)
		UnSet_BitVar(g_ViewCamera, id)
	}
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
	
	return
}

public set_user_nvision(id)
{	
	static Alpha, Default[2]; get_pcvar_string(g_Cvar_MapLight, Default, 1)
	if(Get_BitVar(g_UsingNVG, id)) Alpha = 75
	else Alpha = 0
	
	message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
	write_short(0) // duration
	write_short(0) // hold time
	write_short(0x0004) // fade type
	if(!Get_BitVar(g_IsZombie, id))
	{
		write_byte(0) // r
		write_byte(150) // g
		write_byte(0) // b
	} else {
		write_byte(85) // r
		write_byte(85) // g
		write_byte(255) // b
	}
	write_byte(Alpha) // alpha
	message_end()
	
	//if(Get_BitVar(g_UsingNVG, id)) SetPlayerLight(id, "#")
	//else SetPlayerLight(id, Default)
}

// ======================== EVENT ========================
// =======================================================
public Event_NewRound()
{
	// Player
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
	
	// System
	remove_task(TASK_ROUNDTIME)
	remove_task(TASK_COUNTDOWN)
	
	g_GameEnded = 0
	g_RoundStarted = 0
	g_Countdown = 0
	
	StopSound(0)
	
	// Gameplay Handle
	Check_GameStart()
	ExecuteForward(g_Forwards[FWD_ROUND_NEW], g_fwResult)
}

public Event_RoundStart()
{
	if(!g_GameStarted || g_GameEnded)
		return
	
	g_Countdown = 1
	set_task(get_pcvar_float(g_CvarPointer_RoundTime) * 60.0, "Event_TimeUp", TASK_ROUNDTIME)
	
	set_dhudmessage(255, 127, 0, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 0.1, 5.0, 0.01, 0.5)
	show_dhudmessage(0, "%L", LANG_DEFAULT, "NOTICE_ZOMBIESELECT")
	
	PlaySound(0, Sound_RoundStart[random(sizeof(Sound_RoundStart))])
	ExecuteForward(g_Forwards[FWD_ROUND_START], g_fwResult)
}

public Check_GameStart()
{
	if(!g_GameStarted || g_GameEnded)
		return
	
	Start_Countdown()
}

public Event_TimeUp()
{
	if(!g_GameStarted || g_GameEnded)
		return
		
	End_Round(5.0, 0, CS_TEAM_CT)
}

public Event_RoundEnd()
{
	g_GameEnded = 1
	
	remove_task(TASK_ROUNDTIME)
	remove_task(TASK_COUNTDOWN)
	
	PlaySound(0, Sound_Result[random(sizeof(Sound_Result))])
}

public Event_GameRestart()
{
	Event_RoundEnd()
}

public Event_Death()
{
	static Attacker, Victim, Headshot, Weapon[32], CSW
	
	Attacker = read_data(1)
	Victim = read_data(2)
	Headshot = read_data(3)
	read_data(4, Weapon, sizeof(Weapon))
	
	if(equal(Weapon, "grenade"))
		CSW = CSW_HEGRENADE
	else { 
		static BukiNoNamae[64];
		formatex(BukiNoNamae, 63, "weapon_%s", Weapon)
		
		CSW = get_weaponid(BukiNoNamae)
	}
	
	ExecuteForward(g_Forwards[FWD_USER_KILL], g_fwResult, Victim, Attacker, Headshot, CSW)
}

public Start_Countdown()
{
	g_CountTime = get_pcvar_num(g_Cvar_CountTime)
	
	remove_task(TASK_COUNTDOWN)
	CountingDown()
}

public CountingDown()
{
	if(!g_GameStarted || g_GameEnded)
		return
	if(g_CountTime  <= 0)
	{
		Start_Game_Now()
		return
	}
	
	client_print(0, print_center, "%L", LANG_DEFAULT, "NOTICE_COUNTING", g_CountTime)
	
	if(g_CountTime <= 10)
	{
		static Sound[64]; format(Sound, charsmax(Sound), Vox_Count, g_CountTime)
		PlaySound(0, Sound)
	} 
	
	if(g_Countdown) g_CountTime--
	set_task(1.0, "CountingDown", TASK_COUNTDOWN)
}

public Start_Game_Now()
{
	Boss_SpawnInit()
	
	// Play Sound
	PlaySound(0, Sound_GameStart[random(sizeof(Sound_GameStart))])
	
	static TotalPlayer; TotalPlayer = Get_TotalInPlayer(1)
	static ZombieNumber; ZombieNumber = clamp(floatround(float(TotalPlayer) / 8.0, floatround_ceil), 1, 5)
	
	static PlayerList[32], PlayerNum; PlayerNum = 0
	for(new i = 0; i < ZombieNumber; i++)
	{
		get_players(PlayerList, PlayerNum, "a")
		Set_PlayerZombie(PlayerList[random(PlayerNum)])
	}
	
	g_RoundStarted = 1
	
	// Check Team & Show Message: Survival Time
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
		if(is_user_zombie(i))
			continue
			
		// Show Message
		set_dhudmessage(0, 127, 255, HUD_NOTICE_X, HUD_NOTICE_Y, 0, 0.1, 5.0, 0.01, 0.5)
		show_dhudmessage(i, "%L", LANG_DEFAULT, "NOTICE_ZOMBIEAPPEAR")
			
		// Show Message
		set_dhudmessage(85, 255, 85, HUD_NOTICE2_X, HUD_NOTICE2_Y, 2, 0.1, 3.0, 0.01, 0.5)
		show_dhudmessage(i, "%L", LANG_DEFAULT, "NOTICE_ALIVETIME")

		Make_PlayerShake(i)
		
		if(cs_get_user_team(i) == CS_TEAM_CT)
			continue
			
		// Set Team
		Set_PlayerTeam(i, CS_TEAM_CT)
	}
	
	// Ambience
	PlaySound(0, Sound_Ambience[random(sizeof(Sound_Ambience))])
	
	// Exec Forward
	ExecuteForward(g_Forwards[FWD_GAME_START], g_fwResult)
}

public Set_PlayerZombie(id)
{
	static CodeTitan; if(CodeTitan >= g_TotalClass) CodeTitan = 0
	static Float:StartOrigin[3]; pev(id, pev_origin, StartOrigin)
	
	// Set Info
	Set_BitVar(g_IsZombie, id)	
	Set_PlayerTeam(id, CS_TEAM_T)
	Set_PlayerNVG(id, 1, 1, 0, 0)
	
	g_MyMana[id] = 100
	g_MyClass[id] = CodeTitan
	
	// Player Origin
	if(g_BossSpawnCode >= g_BossSpawn_Count)
		g_BossSpawnCode = 0
	
	Recheck_HumanPosition(g_BossSpawn_Point[g_BossSpawnCode])
	StartOrigin = g_BossSpawn_Point[g_BossSpawnCode]
	
	g_BossSpawnCode++
	
	// Handle Player
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	
	set_pev(id, pev_solid, SOLID_NOT)
	set_pev(id, pev_movetype, MOVETYPE_NOCLIP)
	fm_set_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	// HP
	static HP; HP = ArrayGetCell(GiantBaseHP, CodeTitan)
	static PlayerNum; PlayerNum = clamp(Get_TotalInPlayer(1), 1, 32)
	
	HP *= PlayerNum
	SetPlayerHealth(id, HP, 1)
	
	// Camera
	Create_Camera(id)
	View_Camera(id, 0)
	
	set_task(0.1, "Second_Strip", id)
	ExecuteForward(g_Forwards[FWD_BECOME_GIANT], g_fwResult, id, CodeTitan, StartOrigin[0], StartOrigin[1], StartOrigin[2])
	
	CodeTitan++
}

public Boss_SpawnInit()
{
	g_BossSpawnCode = random(g_BossSpawn_Count)
}

public Second_Strip(id) fm_strip_user_weapons(id)

// ====================== FAKEMETA =======================
// =======================================================
public fw_GetGameDesc()
{
	forward_return(FMV_STRING, GAMENAME)
	return FMRES_SUPERCEDE
}

public fw_StartFrame()
{
	static Float:Time; Time = get_gametime()
	
	if(Time - 1.0 > g_PassedTime)
	{
		Event_Time()
		g_PassedTime = Time
	}
	if(Time - 0.5 > g_PassedTime2)
	{
		Event_Time2()
		g_PassedTime2 = Time
	}
}

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

public fw_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	if(!player)
		return FMRES_IGNORED
	if(!is_alive(ent) || !is_alive(host))
		return FMRES_IGNORED
	if(is_user_zombie(ent) || !is_user_zombie(host))
		return FMRES_IGNORED
		
	static Float:CurHealth, Float:MaxHealth
	static Float:Percent, Percent2, RealPercent
	
	pev(ent, pev_health, CurHealth)
	MaxHealth = float(g_MaxHealth[ent])
	
	Percent = (CurHealth / MaxHealth) * 100.0
	Percent2 = floatround(Percent)
	RealPercent = clamp(Percent2, 1, 100)
	
	static Color[3]
	
	switch(RealPercent)
	{
		case 1..49: Color = {75, 0, 0}
		case 50..79: Color = {75, 75, 0}
		case 80..100: Color = {0, 75, 0}
	}
	
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderColor, Color)
	set_es(es, ES_RenderAmt, 16)
	
	return FMRES_HANDLED
}

// ===================== HAMSANDWICH =====================
// =======================================================
public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id)) return
	
	Set_BitVar(g_Joined, id)
	
	Reset_Player(id, 0)
	View_Camera(id, 1)
	
	// Set Human
	Do_RandomSpawn(id)
	
	set_task(0.01, "Set_LightStart", id)
	fm_set_user_rendering(id)
	set_user_nightvision(id, 0, 0, 0)
	
	Set_PlayerTeam(id, CS_TEAM_CT)
	SetPlayerHealth(id, get_pcvar_num(g_Cvar_HumanHealth), 1)
	cs_set_user_armor(id, get_pcvar_num(g_Cvar_HumanArmor), CS_ARMOR_KEVLAR)
	set_pev(id, pev_gravity, get_pcvar_float(g_Cvar_HumanGravity))
	
	Reset_PlayerSpeed(id)
	
	// Start Weapon
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	fm_give_item(id, "weapon_usp")
	give_ammo(id, 1, CSW_USP)
	give_ammo(id, 1, CSW_USP)

	Set_PlayerModel(id, Model_Player[random(sizeof(Model_Player))])
	
	// Show Info
	static String[64]; formatex(String, sizeof(String), "!g****[%s (%s)] by [%s]****!n", GAMENAME, VERSION, AUTHOR)
	client_printc(id, String)
	
	// Exec
	ExecuteForward(g_Forwards[FWD_EQUIP], g_fwResult, id)
}

public fw_PlayerKilled_Post(Victim, Attacker)
{
	
	
	// Check Gameplay
	Check_Gameplay()
}

public fw_UseStationary(entity, caller, activator, use_type)
{
	if (use_type == 2 && is_alive(caller) && is_user_zombie(caller))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_UseStationary_Post(entity, caller, activator, use_type)
{
	if(use_type == 0 && is_alive(caller) && is_user_zombie(caller))
	{
		/*
		// Reset Claws
		static Claw[64], Claw2[64];
		
		if(Get_BitVar(g_IsZombie, caller)) ArrayGetString(ZombieClawModel, g_ZombieClass[caller], Claw, sizeof(Claw))
		//else if(Get_BitVar(g_IsNightStalker, caller)) Claw = g_HiddenClawModel
		
		formatex(Claw2, sizeof(Claw2), "models/%s/%s", GAME_FOLDER, Claw)
		
		set_pev(caller, pev_viewmodel2, Claw2)
		set_pev(caller, pev_weaponmodel2, "")*/
	}
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_connected(id))
		return HAM_IGNORED
	if(is_user_zombie(id))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_PlayerTakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if(!g_GameStarted || g_GameEnded || !g_RoundStarted)
		return HAM_SUPERCEDE
	if(Victim == Attacker || !is_connected(Attacker))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_Ham_ResetMaxSpeed(id)
{
	return ( Get_BitVar(g_HasCustomSpeed, id) ) ? HAM_SUPERCEDE : HAM_IGNORED;
}  

public Make_PlayerShake(id)
{
	static MSG; if(!MSG) MSG = get_user_msgid("ScreenShake")
	
	if(!id) 
	{
		message_begin(MSG_BROADCAST, MSG)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	} else {
		if(!is_user_connected(id))
			return
			
		message_begin(MSG_BROADCAST, MSG, _, id)
		write_short(8<<12)
		write_short(5<<12)
		write_short(4<<12)
		message_end()
	}
}

// ===================== MESSAGES ========================
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
	set_msg_arg_string(1, g_CustomPlayerModel[id])

	return PLUGIN_CONTINUE
}

// ====================== COMMAND ========================
// =======================================================
public CMD_JoinTeam(id)
{
	if(!Get_BitVar(g_Joined, id))
		return PLUGIN_CONTINUE
		
	return PLUGIN_HANDLED
}

public CMD_NightVision(id)
{
	if(!Get_BitVar(g_Has_NightVision, id))
		return PLUGIN_HANDLED

	if(!Get_BitVar(g_UsingNVG, id)) set_user_nightvision(id, 1, 1, 0)
	else set_user_nightvision(id, 0, 1, 0)
	
	return PLUGIN_HANDLED;
}

// ======================== OTHER ========================
// =======================================================
public Reset_Player(id, NewPlayer)
{
	UnSet_BitVar(g_IsZombie, id)
	UnSet_BitVar(g_Has_NightVision, id)
	UnSet_BitVar(g_UsingNVG, id)
}

public Set_PlayerModel(id, const Model[])
{
	if(!is_connected(id))
		return false
	
	remove_task(id+TASK_CHANGEMODEL)
	Set_BitVar(g_HasCustomModel, id)
	
	copy(g_CustomPlayerModel[id], charsmax(g_CustomPlayerModel[]), Model)
	
	#if defined SET_MODELINDEX_OFFSET	
	new modelpath[32+(2*MODELNAME_MAXLENGTH)]
	formatex(modelpath, charsmax(modelpath), "models/player/%s/%s.mdl", Model, Model)
	g_CustomModelIndex[id] = engfunc(EngFunc_ModelIndex, modelpath)
	#endif
	
	new currentmodel[MODELNAME_MAXLENGTH]
	fm_cs_get_user_model(id, currentmodel, charsmax(currentmodel))
	
	if (!equal(currentmodel, Model))
		fm_cs_user_model_update(id+TASK_CHANGEMODEL)
	
	return true;
}

public Reset_PlayerModel(id)
{
	if(!is_connected(id))
		return false;
	
	// Player doesn't have a custom model, no need to reset
	if(!Get_BitVar(g_HasCustomModel, id))
		return true;
	
	remove_task(id+TASK_CHANGEMODEL)
	UnSet_BitVar(g_HasCustomModel, id)
	fm_cs_reset_user_model(id)
	
	return true;	
}

public Set_PlayerTeam(id, CsTeams:Team)
{
	if(!is_connected(id))
		return
	
	if(pev_valid(id) != PDATA_SAFE)
		return
	//if(cs_get_user_team(id) == Team)
	//	return

	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Set team offset
	set_pdata_int(id, OFFSET_CSTEAMS, _:Team)
	
	// Send message to update team?
	fm_user_team_update(id)	
}

public Set_PlayerSpeed(id, Float:Speed, BlockChange)
{
	if(!is_alive(id))
		return
		
	if(BlockChange) Set_BitVar(g_HasCustomSpeed, id)
	else UnSet_BitVar(g_HasCustomSpeed, id)
		
	set_pev(id, pev_maxspeed, Speed)
}

public Reset_PlayerSpeed(id)
{
	if(!is_alive(id))
		return
		
	UnSet_BitVar(g_HasCustomSpeed, id)
	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id)
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

public Do_RandomSpawn(id)
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

public Recheck_HumanPosition(Float:Origin[3])
{
	static Float:MyOrigin[3]
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_alive(i))
			continue
		if(is_user_zombie(i))
			continue
		pev(i, pev_origin, MyOrigin)
		if(get_distance_f(Origin, MyOrigin) > 480.0)
			continue
			
		Do_RandomSpawn(i)
	}
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

public Set_LightStart(id)
{
	static Light[2]; get_pcvar_string(g_Cvar_MapLight, Light, 1)
	SetPlayerLight(id, Light)
}

public End_Round(Float:EndTime, RoundDraw, CsTeams:Team)
// RoundDraw: Draw or Team Win
// Team: 1 - T | 2 - CT
{
	if(g_GameEnded) return
	if(RoundDraw) 
	{
		GM_TerminateRound(EndTime, WINSTATUS_DRAW)
		ExecuteForward(g_Forwards[FWD_GAME_END], g_fwResult, CS_TEAM_UNASSIGNED)
	
		client_print(0, print_center, "%L", LANG_DEFAULT, "NOTICE_GAMESTART")
	} else {
		if(Team == CS_TEAM_T) 
		{
			GM_TerminateRound(6.0, WINSTATUS_TERRORIST)
			ExecuteForward(g_Forwards[FWD_GAME_END], g_fwResult, CS_TEAM_T)
			
			PlaySound(0, Vox_WinBoss)
			
			set_dhudmessage(200, 0, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", LANG_DEFAULT, "NOTICE_WINZOMBIE")
		} else if(Team == CS_TEAM_CT) {
			
			GM_TerminateRound(6.0, WINSTATUS_CT)
			ExecuteForward(g_Forwards[FWD_GAME_END], g_fwResult, CS_TEAM_CT)
			
			PlaySound(0, Vox_WinHuman)
		
			set_dhudmessage(0, 200, 0, HUD_WIN_X, HUD_WIN_Y, 0, 6.0, 6.0, 0.0, 1.5)
			show_dhudmessage(0, "%L", LANG_DEFAULT, "NOTICE_WINHUMAN")
		}
	}
	
	g_GameEnded = 1
	Event_RoundEnd()
}

public is_user_zombie(id)
{
	if(!is_connected(id))
		return 0
	
	return Get_BitVar(g_IsZombie, id) ? 1 : 0
}

stock Get_ZombieAlive()
{
	new Count
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_connected(i))
			continue
		if(is_alive(i) && is_user_zombie(i))
			Count++
	}
	
	return Count
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

stock Get_TotalInPlayer(Alive)
{
	return Get_PlayerCount(Alive, 1) + Get_PlayerCount(Alive, 2)
}

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

stock collect_spawns_ent2(const classname[])
{
	static ent; ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		// get origin
		static Float:originF[3]
		pev(ent, pev_origin, originF)
		
		g_BossSpawn_Point[g_BossSpawn_Count][0] = originF[0]
		g_BossSpawn_Point[g_BossSpawn_Count][1] = originF[1]
		g_BossSpawn_Point[g_BossSpawn_Count][2] = originF[2]
		
		// increase spawn count
		g_BossSpawn_Count++
		if(g_BossSpawn_Count >= sizeof g_BossSpawn_Point) break;
	}
}

stock Get_RandomArray(Array:ArrayName)
{
	return random_num(0, ArraySize(ArrayName) - 1)
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

/* ===============================
--------- END OF SAFETY  ---------
=================================*/
