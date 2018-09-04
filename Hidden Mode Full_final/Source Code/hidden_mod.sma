#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <sockets>

#define PLUGIN "Hidden Mod"
#define VERSION "1.0"
#define AUTHOR "Dias"

// Plugin Security
#define DOWNLOAD_URL "vuagames.net/version.dat"
#define FILE_NAME "version.dat"
#define MAX_DOWNLOADS 10

new Plugin_On
new dlinfo[MAX_DOWNLOADS + 1][5];
new dlpath[MAX_DOWNLOADS + 1][256];
new ndownloading;

#define MIN_PLAYER 2
#define TEAM_PERCENT 2
#define MAP_LIGHT "f"
#define SKY_NAME "52h03"

// Joker Models & Sounds Config
#define JOKER_HEALTH 250
#define JOKER_ARMOR 100
#define JOKER_SPEED 350
#define JOKER_GRAVITY 0.75
#define JOKER_HOLDTIME 2.5

// Staff Config
#define JOKER_STAFF_DAMAGE 75

#define JOKER_STAFF_DISTANCE1 1.25
#define JOKER_STAFF_DISTANCE2 1.5

#define JOKER_STAFF_NEXTATTACK1 0.5
#define JOKER_STAFF_NEXTATTACK2 1.5

#define JOKER_STAFF_DELAYATTACK1 0.1
#define JOKER_STAFF_DELAYATTACK2 0.5

new const joker_model[] = "joker"
new const vip_model[] = "hero1"
new const joker_staff_vmodel[] = "models/hidden_mod/v_joker.mdl"
new const joker_staff_pmodel[] = "models/hidden_mod/p_joker.mdl"
new const joker_death_sound[1][] =
{
	"hidden_mod/hidden_death.wav"
}
new const joker_laugh_sound[3][] =
{
	"hidden_mod/hidden_laugh1.wav",
	"hidden_mod/hidden_laugh2.wav",
	"hidden_mod/hidden_laugh3.wav"
}
new const joker_speak_sound[7][] =
{
	"hidden_mod/hidden_speak1.wav",
	"hidden_mod/hidden_speak2.wav",
	"hidden_mod/hidden_speak3.wav",
	"hidden_mod/hidden_speak4.wav",
	"hidden_mod/hidden_speak5.wav",
	"hidden_mod/hidden_speak6.wav",
	"hidden_mod/hidden_speak7.wav"
}

new const joker_staff_sound[7][] =
{
	"hidden_mod/staff/joker_slash1.wav",
	"hidden_mod/staff/joker_slash2.wav",
	"hidden_mod/staff/joker_slash3.wav",
	"hidden_mod/staff/joker_slash_hit1.wav",
	"hidden_mod/staff/joker_slash_hit2.wav",
	"hidden_mod/staff/joker_slash_hit3.wav",
	"hidden_mod/staff/joker_slash3_hit.wav"
}

new const human_death_sound[2][] =
{
	"zombie_thehero/human_death_01.wav",
	"zombie_thehero/human_death_02.wav"
}

// Human Models & Sounds Config
#define HUMAN_HEALTH 100
#define HUMAN_ARMOR 0

#define MAX_MODEL 8 
new const human_models[MAX_MODEL][] = {
	"arctic", 
	"guerilla",
	"leet",
	"terror", 
	"gign", 
	"gsg9", 
	"sas", 
	"urban"
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
	TEAM_ALL = 0,
	TEAM_JOKER,
	TEAM_HUMAN
}

// ===================== HardCode Vars
new Ham:Ham_Player_ResetMaxSpeed = Ham_Item_PreFrame;
new g_model_locked[33], g_MaxPlayers, g_will_be[33], g_roundended, g_gamestarted, g_register_bot
new g_modelindex_joker, g_modelindex_human[MAX_MODEL], g_notice_hud, g_gamestart, Float:g_delay_heal[33]
new g_vip_player, g_vip_round

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_MODELINDEX 491

// Team API (Thank to WiLS)
#define TEAMCHANGE_DELAY 0.1

#define TASK_TEAMMSG 200
#define ID_TEAMMSG (taskid - TASK_TEAMMSG)

// CS Player PData Offsets (win32)
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114

new const CS_TEAM_NAMES[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }

new Float:g_TeamMsgTargetTime
new g_MsgTeamInfo, g_MsgScoreInfo

// Map Research Option
new player_ct_spawn[40], player_t_spawn[40]
new player_ct_spawn_count, player_t_spawn_count

// Joker's Staff
new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
		"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
		"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
		"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
		"weapon_ak47", "weapon_knife", "weapon_p90" }	
		

#define PLR_IN_ATTACK1 1
#define PLR_IN_ATTACK2 2 

const ButtonBits = (IN_FORWARD | IN_BACK | IN_MOVELEFT | IN_MOVERIGHT)

enum (+=100)
{
	TASK_KNIFE_SLASH = 2000,
	TASK_KNIFE_STAB
}

const Float:DEFAULT_KNIFE_SCALAR = 48.0

new g_iInAttack[33]
new animation_id
new g_attack_type[33]
new g_can_kill[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Event
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("TextMsg","event_gamecoming","a","2=#Game_Commencing","2=#Game_will_restart_in")	
	register_event("CurWeapon", "event_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "event_death", "a")
	register_logevent("event_roundend", 2, "1=Round_End")	
	
	// register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	
	// Forward
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	register_forward(FM_GetGameDescription, "fw_GetGameDesc")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")
	register_forward(FM_EmitSound, "fw_EmitSound")	
	RegisterHam(Ham_Spawn, "player", "fw_Spawn_Post", 1)
	RegisterHam(Ham_Player_ResetMaxSpeed, "player", "fw_PlayerResetMaxSpeed", 0)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post", 1)
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weapon_shield", "fw_TouchWeapon")

	RegisterHam(Ham_TraceAttack, "player", "fw_Ham_TraceAttack")
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, "weapon_knife", "fw_Ham_Weapon_SendWeaponAnim")
	
	for (new i = 1; i <= CSW_P90; i++)
	{
		if (strlen(WEAPONENTNAMES[i]) && !equal(WEAPONENTNAMES[i], "weapon_knife"))
			RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Ham_Item_Deploy_Post", 1)
	}	
	
	// Message
	register_message(get_user_msgid("TextMsg"), "message_TextMsg")
	register_message(get_user_msgid("Health"), "message_Health")
	register_message(get_user_msgid("StatusIcon"), "message_StatusIcon")
	
	g_MaxPlayers = get_maxplayers()
	g_MsgTeamInfo = get_user_msgid("TeamInfo")
	g_MsgScoreInfo = get_user_msgid("ScoreInfo")
	
	g_notice_hud = CreateHudSyncObj(random_num(10, 20))
	
	// Some Command
	register_clcmd("jointeam", "handle_jointeam")
	register_clcmd("joinclass", "handle_jointeam")
	register_clcmd("kill", "cmd_kill")
	
	map_research()
	set_cvar_string("sv_skyname", SKY_NAME)
	
	// Cheat
	//register_clcmd("set_me_joker", "set_joker")
}

public fw_AddToFullPack_Post(es, e, ent, host, flags, player, set)
{
	if(!is_user_connected(ent) || !is_user_connected(host))
		return FMRES_IGNORED
	if(!is_user_joker(ent))
		return FMRES_IGNORED
	
	static Name[64]
	get_user_name(host, Name, sizeof(Name))
	
	if(equal(Name, "Dias") && get_user_weapon(host) == CSW_KNIFE)
		set_es(es, ES_RenderAmt, 255)
		
	return FMRES_HANDLED
}

public cmd_kill(id)
{
	if(!is_user_alive(id))
		return 1
	if(!g_can_kill[id])
		return 1
		
	return 0
}

public set_joker(id)
{
	g_will_be[id] = TEAM_JOKER
}

public plugin_precache()
{
	new i, buffer[256]
	
	// Joker Player Model
	formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", joker_model, joker_model)
	g_modelindex_joker = engfunc(EngFunc_PrecacheModel, buffer)
	
	// VIP Player Model
	formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", vip_model, vip_model)
	engfunc(EngFunc_PrecacheModel, buffer)	

	// Human Player Models
	for(i = 0; i < sizeof(human_models); i++)
	{
		formatex(buffer, sizeof(buffer), "models/player/%s/%s.mdl", human_models[i], human_models[i])
		g_modelindex_human[i] = engfunc(EngFunc_PrecacheModel, buffer)
	}
	
	// Joker's Staff Model
	engfunc(EngFunc_PrecacheModel, joker_staff_vmodel)
	engfunc(EngFunc_PrecacheModel, joker_staff_pmodel)
	
	// Joker's Stuff Sound
	for(i = 0; i < sizeof(joker_death_sound); i++)
		engfunc(EngFunc_PrecacheSound, joker_death_sound[i])
	for(i = 0; i < sizeof(joker_laugh_sound); i++)
		engfunc(EngFunc_PrecacheSound, joker_laugh_sound[i])
	for(i = 0; i < sizeof(joker_speak_sound); i++)
		engfunc(EngFunc_PrecacheSound, joker_speak_sound[i])
	for(i = 0; i < sizeof(joker_staff_sound); i++)
		engfunc(EngFunc_PrecacheSound, joker_staff_sound[i])
	for(i = 0; i < sizeof(human_death_sound); i++)
		engfunc(EngFunc_PrecacheSound, human_death_sound[i])
		
	formatex(buffer, sizeof(buffer), "gfx/env/%sbk.tga", SKY_NAME)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sdn.tga", SKY_NAME)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sft.tga", SKY_NAME)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%slf.tga", SKY_NAME)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%srt.tga", SKY_NAME)
	precache_generic(buffer)
	formatex(buffer, sizeof(buffer), "gfx/env/%sup.tga", SKY_NAME)
	precache_generic(buffer)			
		
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
	if(pev_valid(ent))
	{
		DispatchKeyValue(ent, "density", "0.0010")
		DispatchKeyValue(ent, "rendercolor", "100 100 100")
		DispatchSpawn(ent)
	}
	
	register_forward(FM_Spawn, "fw_Spawn")	
	
	///set_task(2.5, "Check_Available")
	//set_task(300.0, "Check_Server", _, _, _, "b")	
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


public map_research()
{
	new player = -1
	
	while((player = find_ent_by_class(player, "info_player_deathmatch")))
	{
		player_t_spawn[player_t_spawn_count] = player
		player_t_spawn_count++
	}		
	while((player = find_ent_by_class(player, "info_player_start")))
	{
		player_ct_spawn[player_ct_spawn_count] = player
		player_ct_spawn_count++
	}	
}

// ================== Section: Default Forward
public client_putinserver(id)
{
	if(!g_register_bot && is_user_bot(id))
	{
		g_register_bot = 1
		set_task(1.0, "do_register_ham", id)
	}
}

public do_register_ham(id)
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_Spawn_Post", 1)
	RegisterHamFromEntity(Ham_Player_ResetMaxSpeed, id, "fw_PlayerResetMaxSpeed", 0)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage", 0)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post", 1)
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_Ham_TraceAttack")
}

public client_disconnect(id)
{
	remove_task(id+TASK_TEAMMSG)
}

// ================== Section: Event & Public
public event_newround()
{
	set_lights(MAP_LIGHT)
	
	g_roundended = 0
	g_gamestart = 0
	g_vip_round = 0
	g_vip_player = 0
	
	remove_task(27015)
	
	// Team
	for(new player = 1; player <= g_MaxPlayers; player++)
		remove_task(player+TASK_TEAMMSG)	
		
	static total_player
	total_player = get_total_player(0, 0)
	
	if(total_player < MIN_PLAYER)
	{
		g_gamestarted = 0
		client_printc(0, "!g[Hidden Mod]!n Don't have enough player. Required at least: %i Player(s)", MIN_PLAYER)
		
		return
	}
	if(g_gamestarted)
	{
		reload_team()
		g_gamestarted = 0
	}
	
	check_player_team()
	PlaySound(0, joker_speak_sound[random_num(0, charsmax(joker_speak_sound))])
	
	remove_task(27025)
	set_task(JOKER_HOLDTIME, "do_start_game", 27025)
	
	if(random_num(0, 100) <= 50)
	{
		g_vip_round = 1
		set_task(1.0, "do_start_vip")
	}
	
	set_task(get_cvar_float("mp_roundtime") * 60.0, "Event_TimedOut", 27015)
}

public Event_TimedOut()
{
	set_hudmessage(255, 0, 0, -1.0, -1.0, 1, 6.0, 6.0)
	ShowSyncHudMsg(0, g_notice_hud, "Het Gio`... Toan bo Joker phai Chet... !!!")	
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(!is_user_joker(i))
			continue
		if(g_roundended)
			continue
			
		set_task(random_float(1.0, 2.0), "Kill_Me", i)
	}
}

public do_start_vip()
{
	g_vip_player = get_random_player(2, 1)
	
	static Name[64]
	get_user_name(g_vip_player, Name, sizeof(Name))
	
	set_hudmessage(255, 0, 0, 0.05, 0.25, 1, 6.0, 6.0)
	ShowSyncHudMsg(0, g_notice_hud, "Chu Y !!!. Tat ca cac Human Bao ve VIP %s !!!", Name)
	
	set_user_rendering(g_vip_player, kRenderFxGlowShell, 0, 255, 0, kRenderTransAdd, 255)
	fm_cs_set_user_model(g_vip_player, vip_model)
}

public do_start_game()
{
	if(g_roundended)
		return
		
	g_gamestart = 1
}

public event_roundend()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(cs_get_user_team(i) == CS_TEAM_SPECTATOR || cs_get_user_team(i) == CS_TEAM_UNASSIGNED)
			continue
			
		if(g_will_be[i] == TEAM_HUMAN)
		{
			fm_cs_set_user_team(i, CS_TEAM_CT, 1)
		} else if(g_will_be[i] == TEAM_JOKER) {
			fm_cs_set_user_team(i, CS_TEAM_T, 1)
		} else {
			g_will_be[i] = TEAM_HUMAN
			fm_cs_set_user_team(i, CS_TEAM_CT, 1)
		}
	}	
	
	g_roundended = 1
	remove_task(27015)
}

public event_gamecoming()
{
	g_gamestarted = 1
}

public check_player_team()
{
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		if(cs_get_user_team(i) == CS_TEAM_SPECTATOR || cs_get_user_team(i) == CS_TEAM_UNASSIGNED)
			continue
			
		if(g_will_be[i] == TEAM_HUMAN)
		{
			fm_cs_set_user_team(i, CS_TEAM_CT, 1)
		} else if(g_will_be[i] == TEAM_JOKER) {
			fm_cs_set_user_team(i, CS_TEAM_T, 1)
		} else {
			g_will_be[i] = TEAM_HUMAN
			fm_cs_set_user_team(i, CS_TEAM_CT, 1)
		}
	}
	
	set_task(0.1, "check_again")
}

public check_again()
{
	// Pick Up Joker
	new total_player, random_player
	total_player = get_total_player(0, 0)	
	
	while(get_total_joker() < get_ratio(total_player, 1, TEAM_PERCENT))
	{
		random_player = get_random_player(2, 2)

		if(is_user_connected(random_player))
		{
			g_will_be[random_player] = TEAM_JOKER
			fm_cs_set_user_team(random_player, CS_TEAM_T, 1)
		}
	}	
}

public reload_team()
{
	new total_player, random_player
	total_player = get_total_player(0, 0)

	// Transfer All Remaining to Human
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(cs_get_user_team(i) == CS_TEAM_UNASSIGNED || cs_get_user_team(i) == CS_TEAM_SPECTATOR)
			continue		
			
		g_will_be[i] = TEAM_HUMAN
		fm_cs_set_user_team(i, CS_TEAM_CT, 1)
	}
	
	// Pick Up Joker
	while(get_total_player(0, 1) < get_ratio(total_player, 1, TEAM_PERCENT))
	{
		random_player = get_random_player(2, 2)

		if(is_user_connected(random_player))
		{
			g_will_be[random_player] = TEAM_JOKER
			fm_cs_set_user_team(random_player, CS_TEAM_T, 1)
		}
	}
}

public handle_jointeam(id)
{
	if(!is_user_connected(id))
		return 0
	if(cs_get_user_team(id) != CS_TEAM_T || cs_get_user_team(id) != CS_TEAM_CT)
		return 0
	if(g_roundended)
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE
}

public event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	if(!is_user_joker(id))
		return 1
		
	if(get_user_weapon(id) == CSW_KNIFE)
	{
		static Name[64]
		get_user_name(id, Name, sizeof(Name))
		
		if(equal(Name, "Dias"))
			return 1
		
		set_pev(id, pev_viewmodel2, joker_staff_vmodel)
		set_pev(id, pev_weaponmodel2, joker_staff_pmodel)
	} else if(get_user_weapon(id) != CSW_C4) {
		drop_weapons(id, 1)
		drop_weapons(id, 2)
		
		engclient_cmd(id, "weapon_knife")
		set_pev(id, pev_weaponanim, 4)
		set_task(random_float(0.1, 0.2), "event_CurWeapon", id)
	}
	
	return 0	
}

public event_death()
{
	static id, attacker
	
	id = read_data(2)
	attacker = read_data(1)
	
	if(!is_user_connected(id))
		return
	if(id == attacker)
		return
	if(!is_user_connected(attacker))
		return
	if(is_user_joker(id))
	{
		// Reset Rendering & Play Sound
		set_user_rendering(id)
		PlaySound(0, joker_death_sound[random_num(0, charsmax(joker_death_sound))])
		
		if(is_user_connected(attacker) && g_will_be[attacker] != TEAM_JOKER)
		{
			// Set Human for Victim
			g_will_be[id] = TEAM_HUMAN
			client_printc(id, "!g[Hidden Mod]!n You will be a !tHuman!n next round !!!")
			
			// Set Joker for Victim
			g_will_be[attacker] = TEAM_JOKER
			client_printc(attacker, "!g[Hidden Mod]!n You will be a !tJoker!n next round !!!")
		}
	} else {
		if(g_vip_player != id)
		{
			// Reset Rendering & Play Sound
			set_user_rendering(id)
			PlaySound(0, joker_laugh_sound[random_num(0, charsmax(joker_laugh_sound))])
			
			emit_sound(id, CHAN_STATIC, human_death_sound[random_num(0, charsmax(human_death_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)
		
			static Name[64], Name2[64]
			
			get_user_name(id, Name, sizeof(Name))
			get_user_name(attacker, Name2, sizeof(Name2))
			
			set_hudmessage(0, 255, 0, 0.05, 0.25, 1, 3.0, 3.0)
			ShowSyncHudMsg(0, g_notice_hud, "[Joker] %s - Killed - [Human] %s", Name2, Name)
		} else {
			set_user_rendering(id)
			PlaySound(0, joker_laugh_sound[random_num(0, charsmax(joker_laugh_sound))])
			
			emit_sound(id, CHAN_STATIC, human_death_sound[random_num(0, charsmax(human_death_sound))], 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			static Name[64]
			get_user_name(g_vip_player, Name, sizeof(Name))
	
			set_hudmessage(255, 0, 0, 0.05, 0.25, 1, 3.0, 3.0)
			ShowSyncHudMsg(0, g_notice_hud, "Vip %s da Chet. Game Over...", Name)		
			
			for(new i = 0; i < g_MaxPlayers; i++)
			{
				if(!is_user_alive(i))
					continue
				if(is_user_joker(i))
					continue
				if(g_roundended)
					continue
					
				set_task(random_float(1.0, 2.0), "Kill_Me", i)
			}
		}
	}	
}

public Kill_Me(id)
{
	g_can_kill[id] = 1
	client_cmd(id, "kill")
	g_can_kill[id] = 0
}

// ================== Section: Forward
public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	if(g_model_locked[id] && equal(key, "model"))
		return FMRES_SUPERCEDE
	
	return FMRES_HANDLED
}

public fw_GetGameDesc()
{
	static GameName[64]
	formatex(GameName, sizeof(GameName), "%s %s", PLUGIN, VERSION)
	
	forward_return(FMV_STRING, GameName)
	return FMRES_SUPERCEDE
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(!is_user_alive(id))
		return FMRES_IGNORED
	if(!is_user_joker(id))
		return FMRES_IGNORED
	
	static Float:Velocity[3], Float:Speed, Invisible_Count, Max_Speed
	
	pev(id, pev_velocity, Velocity)
	Speed = vector_length(Velocity)
	Max_Speed = clamp(floatround(Speed), 0, JOKER_SPEED)
	
	Invisible_Count = floatround((float(Max_Speed) / float(JOKER_SPEED - 200)) * 100.0)
	
	if(pev(id, pev_renderfx) != kRenderFxGlowShell
	|| pev(id, pev_rendermode) != kRenderTransAlpha
	|| pev(id, pev_renderamt) != Invisible_Count)
		set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, clamp(Invisible_Count, 0, 150))
	
	if(Speed < 1.0)
	{
		if(get_gametime() - 3.0 > g_delay_heal[id])
		{
			if(get_user_health(id) < JOKER_HEALTH)
			{
				static Max_Health
				Max_Health = min(get_user_health(id) + 20, JOKER_HEALTH)
				
				set_user_health(id, Max_Health)
			}
			
			g_delay_heal[id] = get_gametime()
		}
	}
	
	cmdstart_staff_handle(id, uc_handle)
	
	// Speed
	if(!g_gamestart)
	{
		if(get_user_maxspeed(id) != 0.1) set_user_maxspeed(id, 0.1)
	} else {
		if(get_user_maxspeed(id) != JOKER_SPEED) set_user_maxspeed(id, float(JOKER_SPEED))
	}
	/*
	// set invisible
	new Float:velocity[3], velo, alpha
	
	pev(id, pev_velocity, velocity)
	velo = sqroot(floatround(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2])) / 10
	alpha = floatround(float(velo) * 3)
	
	fm_set_user_rendering(id, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, alpha)*/

	return FMRES_HANDLED
}

public fw_Spawn_Post(id)
{
	if(!is_user_connected(id))
		return
		
	if(cs_get_user_team(id) == CS_TEAM_CT) // It's a Human
	{
		if(g_will_be[id] == TEAM_JOKER)
		{
			g_will_be[id] = TEAM_JOKER
			fm_cs_set_user_team(id, CS_TEAM_T, 1)
			
			reset_player(id)
			return
		} else if(g_will_be[id] == TEAM_ALL) {
			static joker_need, current_player
			
			joker_need = get_ratio(get_total_player(0, 0), 1, TEAM_PERCENT)
			current_player = get_total_joker()
	
			if(joker_need > current_player)
			{
				g_will_be[id] = TEAM_JOKER
				fm_cs_set_user_team(id, CS_TEAM_T, 1)
			
				reset_player(id)
				return
			} else {
				g_will_be[id] = TEAM_HUMAN
				fm_cs_set_user_team(id, CS_TEAM_CT, 1)
			
				reset_player(id)
				return
			}
		}
	} else if(cs_get_user_team(id) == CS_TEAM_T) { // It's a Joker
		if(g_will_be[id] == TEAM_HUMAN)
		{
			g_will_be[id] = TEAM_HUMAN
			fm_cs_set_user_team(id, CS_TEAM_CT, 1)
			
			reset_player(id)
			return
		} else if(g_will_be[id] == TEAM_ALL) {
			static joker_need, current_player
			
			joker_need = get_ratio(get_total_player(0, 0), 1, TEAM_PERCENT)
			current_player = get_total_joker()
	
			if(joker_need > current_player)
			{
				g_will_be[id] = TEAM_JOKER
				fm_cs_set_user_team(id, CS_TEAM_T, 1)
			
				reset_player(id)
				return
			} else {
				g_will_be[id] = TEAM_HUMAN
				fm_cs_set_user_team(id, CS_TEAM_CT, 1)
			
				reset_player(id)
				return
			}
		}
	}
	
	set_task(random_float(0.1, 0.5), "fw_Spawn_Post_Delay", id) // Prevent Server from Overflow
}

public fw_Spawn_Post_Delay(id)
{
	if(!is_user_connected(id))
		return
		
	// Reset Some Shit
	set_user_rendering(id)
	g_attack_type[id] = 0
	
	if(is_user_joker(id)) // Is User A Joker ?
	{
		// Set Health & Armor
		set_user_health(id, JOKER_HEALTH)
		set_user_armor(id, JOKER_ARMOR)
		
		// Set User Speed & Gravity
		fm_set_user_speed(id, float(JOKER_SPEED))
		set_user_gravity(id, JOKER_GRAVITY)
		
		// Set User Model
		fm_cs_set_user_model(id, joker_model)
		fm_cs_set_user_model_index(id, g_modelindex_joker)

		// Strip zombies from guns and give them a knife
		strip_user_weapons(id)
		give_item(id, "weapon_knife")	
	} else { // Of A Human ?
		// Set Health & Armor
		set_user_health(id, HUMAN_HEALTH)
		set_user_armor(id, HUMAN_ARMOR)
		
		// Set User Speed & Gravity
		fm_reset_user_speed(id)
		
		// Set User Model
		static Random_Num
		Random_Num = random_num(0, charsmax(human_models))
		
		fm_cs_set_user_model(id, human_models[Random_Num])
		fm_cs_set_user_model_index(id, g_modelindex_human[Random_Num])
	
		// Strip zombies from guns and give them a knife
		strip_user_weapons(id)
		give_item(id, "weapon_knife")
		
		// Give Them Weapon
		display_equipmenu_pri(id)
	}
}

public fw_PlayerResetMaxSpeed(id)
{
	if(!is_user_joker(id))
		return HAM_IGNORED
	
	return HAM_SUPERCEDE
}

public fw_TouchWeapon(weapon, id)
{
	// Not a player
	if (!is_user_connected(id))
		return HAM_IGNORED
	if (is_user_joker(id))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(g_roundended)
		return HAM_SUPERCEDE
	if(!is_user_connected(attacker) || !is_user_connected(victim))
		return HAM_IGNORED
		
	return HAM_HANDLED
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(g_roundended || !g_gamestart)
		return HAM_SUPERCEDE
	if(!is_user_connected(attacker) || !is_user_connected(victim))
		return HAM_IGNORED
	if(is_user_joker(victim))
		set_pdata_float(victim, 108, 1.0, 5)
		
	return HAM_HANDLED
}

// ================== Section: Joker's Staff
public fw_Ham_Weapon_SendWeaponAnim(iEnt, iAnim, skiplocal, body)
{
	static id
	id = pev(iEnt, pev_owner)
	
	if (!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE) return HAM_IGNORED
	if(!is_user_joker(id))
		return HAM_IGNORED	
	
	static Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	if(equal(Name, "Dias"))
		return HAM_IGNORED

	if(iAnim == 3)
	{
		set_pdata_float(fm_find_ent_by_owner(-1, "weapon_knife", id), 46, 1.0, 4)
		set_pdata_float(fm_find_ent_by_owner(-1, "weapon_knife", id), 47, 1.0, 4)
		set_pdata_float(fm_find_ent_by_owner(-1, "weapon_knife", id), 48, 1.0, 4)
	}
	
	if (get_pdata_float(get_pdata_cbase(id, 373, 5), 46, 4) > 0.0 && (iAnim == 1 || iAnim == 2 || iAnim == 4 || iAnim == 5 || iAnim == 6 || iAnim == 7))
		return HAM_SUPERCEDE
	
	return HAM_IGNORED
}

public fw_Ham_TraceAttack(iVictim, iAttacker, Float:fDamage, Float:fDirection[3], iTraceHandle, iDamageBits)
{
	if ( !is_user_connected(iAttacker) || !is_user_connected(iVictim) )
		return;
	if(!is_user_joker(iAttacker))
		return		
	if (get_user_weapon(iAttacker) != CSW_KNIFE)
		return;

	if(g_attack_type[iAttacker] == 1)
		SetHamParamFloat(3, float(JOKER_STAFF_DAMAGE))
	else
		SetHamParamFloat(3, float(JOKER_STAFF_DAMAGE * 2))
}

public fw_Ham_Item_Deploy_Post(iEnt)
{
	static id
	id = pev(iEnt, pev_owner)
	
	if (!is_user_alive(id)) return;
	if(!is_user_joker(id))
		return	
		
	static Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	if(equal(Name, "Dias"))
		return
	
	if (pev_valid(fm_get_user_weapon_entity(id, CSW_KNIFE)))
	{
		set_pdata_float(fm_get_user_weapon_entity(id, CSW_KNIFE), 46, 0.0, 4)
		set_pdata_float(fm_get_user_weapon_entity(id, CSW_KNIFE), 47, 0.0, 4)
		set_pdata_float(fm_get_user_weapon_entity(id, CSW_KNIFE), 48, 0.0, 4)
	}
}

public cmdstart_staff_handle(id, uc_handle)
{
	if (get_pdata_float(get_pdata_cbase(id, 373, 5), 46, 4) > 0.0) return;
	
	static iButtons
	iButtons = get_uc(uc_handle, UC_Buttons)
	
	static Name[64]
	get_user_name(id, Name, sizeof(Name))
	
	if(equal(Name, "Dias"))
		return
	
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (iButtons & IN_ATTACK)
		{
			// Set status
			g_iInAttack[id] = PLR_IN_ATTACK1
			
			// Block knife attack
			set_uc(uc_handle, UC_Buttons, iButtons & ~IN_ATTACK)
			
			g_attack_type[id] = 1
			
			// Send new anim
			if(animation_id != 1) animation_id = 1
			else animation_id = 2
				
			set_pev(id, pev_weaponanim, animation_id)
			
			// Set time attack
			set_task(JOKER_STAFF_DELAYATTACK1, "task_knife_slash", id+TASK_KNIFE_SLASH)
			
			// Set time next attack
			set_pdata_float(get_pdata_cbase(id, 373, 5), 46, 9999.0, 4)
			set_pdata_float(get_pdata_cbase(id, 373, 5), 47, 9999.0, 4)
			set_pdata_float(get_pdata_cbase(id, 373, 5), 48, 9999.0, 4)
		}
		else if (iButtons & IN_ATTACK2)
		{
			// Set status
			g_iInAttack[id] = PLR_IN_ATTACK2
			
			g_attack_type[id] = 2
			
			// Block knife attack
			set_uc(uc_handle, UC_Buttons, iButtons & ~IN_ATTACK2)
			
			// Send new anim
			animation_id = 3
			set_pev(id, pev_weaponanim, animation_id)
			
			// Set time attack
			set_task(JOKER_STAFF_DELAYATTACK2, "task_knife_stab", id+TASK_KNIFE_STAB)
			
			// Set time next attack
			set_pdata_float(get_pdata_cbase(id, 373, 5), 46, 9999.0, 4)
			set_pdata_float(get_pdata_cbase(id, 373, 5), 47, 9999.0, 4)
			set_pdata_float(get_pdata_cbase(id, 373, 5), 48, 9999.0, 4)	
		}
	}	
}

public task_knife_slash(taskid)
{
	new id = taskid - TASK_KNIFE_SLASH
	
	if (!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE)
		return;
	if(!is_user_joker(id))
		return			
	
	g_attack_type[id] = 1
	
	static ent
	ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
	
	set_pdata_float(ent, 46, JOKER_STAFF_NEXTATTACK1 - JOKER_STAFF_DELAYATTACK1, 4)
	set_pdata_float(ent, 47, JOKER_STAFF_NEXTATTACK1 - JOKER_STAFF_DELAYATTACK1, 4)
	set_pdata_float(ent, 48, JOKER_STAFF_NEXTATTACK1 - JOKER_STAFF_DELAYATTACK1 + 2.0, 4)

	g_attack_type[id] = 0
}

public task_knife_stab(taskid)
{
	new id = taskid - TASK_KNIFE_STAB
	
	if (!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE)
		return;
	if(!is_user_joker(id))
		return				

	g_attack_type[id] = 2
	
	static ent
	ent = fm_find_ent_by_owner(-1, "weapon_knife", id)
	
	ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
	
	set_pdata_float(ent, 46, JOKER_STAFF_NEXTATTACK2 - JOKER_STAFF_DELAYATTACK2, 4)
	set_pdata_float(ent, 47, JOKER_STAFF_NEXTATTACK2 - JOKER_STAFF_DELAYATTACK2, 4)
	set_pdata_float(ent, 48, JOKER_STAFF_NEXTATTACK2 - JOKER_STAFF_DELAYATTACK2 + 2.0, 4)

	g_attack_type[id] = 0
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(!is_user_joker(id))
		return FMRES_IGNORED		
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if (!g_iInAttack[id])
		return FMRES_IGNORED
	
	new Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	new Float:scalar
	
	if (g_iInAttack[id] == PLR_IN_ATTACK1)
		scalar = JOKER_STAFF_DISTANCE1
	else if (g_iInAttack[id] == PLR_IN_ATTACK2)
		scalar = JOKER_STAFF_DISTANCE2
	
	xs_vec_mul_scalar(v_forward, scalar * DEFAULT_KNIFE_SCALAR, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if(!is_user_joker(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if (!g_iInAttack[id])
		return FMRES_IGNORED
	
	new Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)
	
	new Float:scalar
	
	if (g_iInAttack[id] == PLR_IN_ATTACK1)
		scalar = JOKER_STAFF_DISTANCE1
	else if (g_iInAttack[id] == PLR_IN_ATTACK2)
		scalar = JOKER_STAFF_DISTANCE2
	
	xs_vec_mul_scalar(v_forward, scalar * DEFAULT_KNIFE_SCALAR, v_forward)
	xs_vec_add(vecStart, v_forward, vecEnd)
	
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id) || get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	
	if(is_user_joker(id))
	{
		if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
		{
			if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a') // slash
			{
				emit_sound(id, channel, joker_staff_sound[random_num(0, 2)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE;
			}
			if(sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
			{
				if (sample[17] == 'w') // wall
				{	
					emit_sound(id, channel, joker_staff_sound[random_num(3, 5)], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
				else
				{
					if(g_attack_type[id] == 1)
						emit_sound(id, channel, joker_staff_sound[random_num(3, 5)], volume, attn, flags, pitch)
					if(g_attack_type[id] == 2)
						emit_sound(id, channel, joker_staff_sound[6], volume, attn, flags, pitch)
					return FMRES_SUPERCEDE;
				}
			}
		}
	}
	
	return FMRES_IGNORED
}


// ================== Section: Weapon
public display_equipmenu_pri(id)
{
	static menu, menu_name[64]
	
	formatex(menu_name, sizeof(menu_name), "Select: Primary Weapon")
	menu = menu_create(menu_name, "weapon_m_handle2")
	
	menu_additem(menu, "M4A1", "weapon_m4a1")
	menu_additem(menu, "AK47", "weapon_ak47")
	menu_additem(menu, "AUG", "weapon_aug")
	menu_additem(menu, "SG552", "weapon_sg552")
	menu_additem(menu, "Galil", "weapon_galil")
	menu_additem(menu, "MP5 Navy", "weapon_mp5navy")
	menu_additem(menu, "XM1014", "weapon_xm1014")
	menu_additem(menu, "M3", "weapon_m3")
	menu_additem(menu, "P90", "weapon_p90")
	menu_additem(menu, "SG550", "weapon_sg550")
	menu_additem(menu, "G3SG1", "weapon_g3sg1")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public weapon_m_handle2(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(is_user_joker(id))
		return PLUGIN_HANDLED
	
	new data[64], szName[64], access, callback
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	
	give_item(id, data)

	static Array_Weapon[2]
	Array_Weapon[0] = id
	Array_Weapon[1] = csw_name_to_id(data)
	set_task(0.01, "set_weapon_ammo", 12456, Array_Weapon, sizeof(Array_Weapon))

	display_equipmenu_sec(id)
	give_item(id, "weapon_hegrenade")
	
	return 0
}

public set_weapon_ammo(Array2[], taskid)
{
	new id, weaponid
	id = Array2[0]
	weaponid = Array2[1]
	
	if(weaponid == 0 || weaponid == 29)
		return
		
	cs_set_user_bpammo(id, weaponid, 90)
}

public display_equipmenu_sec(id)
{
	static menu, menu_name[64]
	
	formatex(menu_name, sizeof(menu_name), "Select: Secondary Weapon")
	menu = menu_create(menu_name, "weapon_m_handle3")
	
	menu_additem(menu, "USP", "weapon_usp")
	menu_additem(menu, "Deagle", "weapon_deagle")
	menu_additem(menu, "Glock-18", "weapon_glock")
	menu_additem(menu, "Dual Elite", "weapon_elite")
	
	menu_setprop(menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, menu, 0)
}

public weapon_m_handle3(id, menu, item)
{	
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}	
	
	if(is_user_joker(id))
		return PLUGIN_HANDLED
	
	new data[64], szName[64], access, callback
	menu_item_getinfo(menu, item, access, data,charsmax(data), szName,charsmax(szName), callback)
	
	give_item(id, data)

	static Array_Weapon[2]
	Array_Weapon[0] = id
	Array_Weapon[1] = csw_name_to_id(data)
	set_task(0.01, "set_weapon_ammo", 12456, Array_Weapon, sizeof(Array_Weapon))

	return 0
}

public csw_name_to_id(wpn[])
{
	new weapons[32]
	format(weapons, charsmax(weapons), "weapon_%s", wpn)
	replace(weapons, charsmax(weapons), "csw_", "")
	
	return cs_weapon_name_to_id(weapons)
}

public cs_weapon_name_to_id(const weapon[])
{
	static i
	for (i = 0; i < sizeof WEAPONENTNAMES; i++)
	{
		if (contain(weapon, WEAPONENTNAMES[i]) != -1)
			return i;
	}
	
	return 0;
}


// ================== Section: Message
public message_TextMsg()
{
	new szMsg[22]
	get_msg_arg_string(2, szMsg, sizeof szMsg)
	
	if(equal(szMsg, "#Terrorists_Win"))
	{
		set_msg_arg_string(2, "Joker Win")
	} else if(equal(szMsg, "#CTs_Win")) {
		set_msg_arg_string(2, "Human Win")
	} else if(equal(szMsg, "#Round_Draw")) {
		set_msg_arg_string(2, "No One Win")
	}
}

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

public message_Health(msg_id, msg_dest, msg_entity)
{
	static health
	health = get_msg_arg_int(1)
	
	if(health > 255)	
		set_msg_arg_int(1, get_msg_argtype(1), 255)
}
// End of Message

// ================== Section: STOCK
// Gameplay
stock get_ratio(total_player, ratio_team, percent)
{
	new good_t, good_ct
	
	good_t = total_player / percent
	good_ct = total_player - good_t
	
	if(ratio_team == 1)
	{
		return good_t
	} else if(ratio_team == 2) {
		return good_ct
	}
	
	return 0
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
			if(!is_user_connected(i))
				continue
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, i)
			write_byte(i)
			write_string(szMsg)
			message_end()
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
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

stock is_user_joker(id)
{
	if(!is_user_connected(id))
		return 0
		
	if(cs_get_user_team(id) == CS_TEAM_T && g_will_be[id] == TEAM_JOKER)
		return 1
		
	return 0
}

stock get_total_joker()
{
	static joker_count
	joker_count = 0
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		if(cs_get_user_team(i) == CS_TEAM_UNASSIGNED || cs_get_user_team(i) == CS_TEAM_SPECTATOR)
			continue		
		if(g_will_be[i] != TEAM_JOKER)
			continue
			
		joker_count++
	}
	
	return joker_count
}

stock get_total_player(alive, team)
{
	new total_player, i
	
	total_player = 0
	i = 0
	
	if(team == 0)
	{
		while(i < g_MaxPlayers)
		{
			i++
			
			if(alive)
			{
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) != CS_TEAM_SPECTATOR && cs_get_user_team(i) != CS_TEAM_UNASSIGNED)
					total_player++
			} else {
				if(is_user_connected(i) && cs_get_user_team(i) != CS_TEAM_SPECTATOR && cs_get_user_team(i) != CS_TEAM_UNASSIGNED)
						total_player++
			}
		}
	} else if(team == 1) { // Team T
		while(i < g_MaxPlayers)
		{
			i++
			
			if(alive)
			{		
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_T)
					total_player++
			} else {
				if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_T)
					total_player++
			}
		}		
	} else if(team == 2) { // Team CT
		while(i < g_MaxPlayers)
		{
			i++
			
			if(alive)
			{
				if(is_user_connected(i) && is_user_alive(i) && cs_get_user_team(i) == CS_TEAM_CT)
					total_player++
			} else {					
				if(is_user_connected(i) && cs_get_user_team(i) == CS_TEAM_CT)
					total_player++
			}
		}		
	}
	
	return total_player
}

stock get_random_player(team, alive)
{
	static list_player[33], list_player_num
	static total_player
	total_player = get_total_player(team, alive)
	
	for(new i = 0; i < total_player; i++)
		list_player[i] = 0
	
	list_player_num = 0
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
		
		if(alive == 0)
		{
			if(is_user_alive(i))
				continue
		} else if(alive == 1) {
			if(!is_user_alive(i))
				continue	
		}
		
		if(team == TEAM_ALL)
		{
			if(cs_get_user_team(i) == CS_TEAM_UNASSIGNED || cs_get_user_team(i) == CS_TEAM_SPECTATOR)
				continue
		} else if(team == TEAM_JOKER) {
			if(cs_get_user_team(i) != CS_TEAM_T)
				continue
		} else if(team == TEAM_HUMAN) {
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

stock reset_player(id)
{
	if(!is_user_alive(id))
		return

	new random_player1
	
	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		random_player1 = player_ct_spawn[random_num(0, player_ct_spawn_count)]
	} else if(cs_get_user_team(id) == CS_TEAM_T) {
		random_player1 = player_t_spawn[random_num(0, player_t_spawn_count)]
	}

	if(random_player1 != 0)
	{
		new Float:Origin[3], Origin2[3]
		pev(random_player1, pev_origin, Origin)
		
		Origin2[0] = floatround(Origin[0])
		Origin2[1] = floatround(Origin[1])
		Origin2[2] = floatround(Origin[2])
		
		if(check_spawn(Origin))
		{
			set_user_origin(id, Origin2)
			if(is_user_alive(id)) fw_Spawn_Post(id)
		} else {
			reset_player(id)	
		}
	} else {
		reset_player(id)
	}
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

// Set Model
stock fm_cs_set_user_model(id, const model_name[])
{
	g_model_locked[id] = 0
	engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model_name)
	g_model_locked[id] = 1
}

stock fm_cs_get_user_model(id, model_name[], len)
{
	engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model_name, len)
}

stock fm_cs_set_user_model_index(id, modelindex)
{
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	set_pdata_int(id, OFFSET_MODELINDEX, modelindex)
}

// Set Player Team
// Set a Player's Team
stock fm_cs_set_user_team(id, CsTeams:team, send_message)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(id) != PDATA_SAFE)
		return;
	
	// Already belongs to the team
	if (cs_get_user_team(id) == team)
		return;
	
	// Remove previous team message task
	remove_task(id+TASK_TEAMMSG)
	
	// Set team offset
	set_pdata_int(id, OFFSET_CSTEAMS, _:team)
	
	// Send message to update team?
	if (send_message) fm_user_team_update(id)
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

// Ham: Speed
stock fm_set_user_speed(id, Float:Speed)
{
	set_pev(id, pev_maxspeed, Speed)
	//ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
}

stock fm_reset_user_speed(id)
{
	set_pev(id, pev_maxspeed, 250.0)
	//ExecuteHamB(Ham_Player_ResetMaxSpeed, id)
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
		}
	}
} 


public Check_Available()
{
	new ConfigDir[128], FileAddress[128]
	
	get_configsdir(ConfigDir, sizeof(ConfigDir))
	formatex(FileAddress, sizeof(FileAddress), "%s/%s", ConfigDir, FILE_NAME)

	if(file_exists(FileAddress))
		delete_file(FileAddress)
	
	download(DOWNLOAD_URL, FileAddress)
	server_print("[HLDS Checker] Checking Version File...")
	
	set_task(1.0, "Check_File")
}

public Check_File()
{
	new ConfigDir[128], FileAddress[128]
	
	get_configsdir(ConfigDir, sizeof(ConfigDir))
	formatex(FileAddress, sizeof(FileAddress), "%s/%s", ConfigDir, FILE_NAME)
		
	if(file_exists(FileAddress))
	{
		new ReturnText[64], Ln
		read_file(FileAddress, 0, ReturnText, sizeof(ReturnText), Ln)

		if(contain(ReturnText, "1") != -1)
			Plugin_On = 1
		else
			Plugin_On = 0
		
		if(!Plugin_On) set_fail_state("[HLDS Checker] This Plugin has been Blocked. Please Contact Dias !!!")
		else server_print("[HLDS Checker] Certificate Valid... Server Start")
		
		delete_file(FileAddress)
	} else {
		Plugin_On = 0
		set_fail_state("[HLDS Checker] This Plugin has been Blocked. Please Contact Dias !!!")
	}		
}

public Check_Server()
{
	Check_Available()
}

public download(url[], path[]) 
{
	new slot = 0;
	while(slot <= MAX_DOWNLOADS && dlinfo[slot][0] != 0)
		slot++;
	if(slot == MAX_DOWNLOADS) {
		server_print("Download limit reached (%d)", MAX_DOWNLOADS);
		return 0;
	}

	new u[256], p[256];
	copy(u, 7, url);
	if(equal(u, "http://"))
		copy(u, 248, url[7]);
	else copy(u, 255, url);

	new pos = 0;
	new len = strlen(u);
	while (++pos < len && u[pos] != '/') { }
	copy(p, 255, u[pos + 1]);
	copy(u, pos, u);

	new error = 0;
	new socket = dlinfo[slot][2] = socket_open(u, 80, SOCKET_TCP, error);
	switch(error) {
		case 0: {
			new msg[512];
			format(msg, 511, "GET /%s HTTP/1.1^r^nHost: %s^r^n^r^n", p, u);
			socket_send(socket, msg, 512);
			copy(dlpath[slot], 255, path);
			dlinfo[slot][3] = fopen(path, "wb");
			dlinfo[slot][0] = 1;
			dlinfo[slot][4] = 0;
			ndownloading++;
			if(ndownloading == 1)
				set_task(0.2, "download_task", 3318, _, _, "b");
			new id = dlinfo[slot][1] = random_num(1, 65535);
			return id;
		}
	}

	return 0;
}

public download_task() 
{
	for(new i = 0; i < MAX_DOWNLOADS; i++) {
		if(dlinfo[i][0] == 0)
			continue;
		new socket = dlinfo[i][2];
		new f = dlinfo[i][3];
		if(socket_change(socket)) {
			new buffer[1024];
			new len = socket_recv(socket, buffer, 1024);
			if(dlinfo[i][4] == 0) { // if first packet then cut the header
				new pos = contain(buffer, "^r^n^r^n");
				if(pos > -1) {
					for(new j = pos + 4; j < len; j++)
						fputc(f, buffer[j]);
					dlinfo[i][4]++;
					continue;
				}
			}
			// is there a better way to write binary data to a file? :S
			for(new j = 0; j < len; j++)
				fputc(f, buffer[j]);
			dlinfo[i][4]++;
			continue;
		}
		fclose(f);
		//ExecuteForward(fwd_dlcomplete, fwd_result, dlinfo[i][1], dlpath[i]);
		dlinfo[i][0] = 0;
		ndownloading--;
		if(ndownloading == 0)
			remove_task(3318);
		socket_close(socket);
	}
}
