#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>

#define PLUGIN "Resident Evil"
#define VERSION "1.0"
#define AUTHOR "Dias Leon"

#define MAX_CTLEVEL 9

#define ZOMBIE_BASEHP 549
#define ZOMBIE_ARMOR 100
#define ZOMBIE_SPEED 280.0
#define ZOMBIE_GRAVITY 0.5

#define HUMAN_HP 100
#define HUMAN_ARMOR 100
#define HUMAN_SPEED 220.0
#define HUMAN_GRAVITY 1.0

// LANG
#define MSG_CHOOSETEAM "[Resident Evil] Please choose a team!"
#define MSG_VIPESCAPED "[Resident Evil] VIP has escaped successfully!"
#define MSG_AB_MANYHM "[Resident Evil] Auto Team Balance: Too many humans!"
#define MSG_AB_ZBNOW "[Resident Evil] Auto Team Balance: You are a zombie!"
#define MSG_AB_MANYZB "[Resident Evil] Auto Team Balance: Too many zombies!"
#define MSG_AB_HMNOW "[Resident Evil] Auto Team Balance: You are a human!"
#define MSG_SERVERINFO "[Resident Evil] Attention! There are zombies on the server and they are even stronger!"
#define MSG_CREDIT "[Resident Evil] This mod is remade by 'Joseph Rias de Dias Pendragon Leon'"

#define HUD_LEVELUPVIP "Level Up for saving V.I.P!"
#define HUD_ZB_LEVEL "ZOMBIE LEVEL: %d (%d HP)!"
#define HUD_ZB_LEVELF "ZOMBIE LEVEL: FINAL (%d HP)!"
#define HUD_HM_LEVEL "HUMAN LEVEL: %d!"
#define HUD_HM_LEVELF "HUMAN LEVEL: FINAL!"
#define HUD_2LVUP "+2 Level Up for killing V.I.P!"
#define HUD_HAVEHP "You have %d HP!"
#define HUD_BOTVIP "V.I.P is a stupid BOT - no respawn for zombies - Humans have to kill ALL REMAINING ZOMBIES!"

new const ZombieModels[9][] =
{
	"zombiebot_1",
	"zombiebot_2",
	"zombiebot_3",
	"zombiebot_4",
	"zombiebot_5",
	"zombiebot_6",
	"zombiebot_7",
	"zombiebot_8",
	"zombiebot_9"
}

new const HumanModels[12][] = 
{
	"zombiebot_ct1",
	"zombiebot_ct2",
	"zombiebot_ct3",
	"zombiebot_ct4",
	"zombiebot_ct5",
	"zombiebot_ct6",
	"zombiebot_ct7",
	"zombiebot_ct8",
	"zombiebot_ct9",
	"zombiebot_ct10",
	"zombiebot_ct11",
	"zombiebot_ct12"
}

new const ZombieDogModel[] = "zombiebot_dog"
new const VipModel[] = "zombiebot_vip"

enum
{
	V_ZOMBIE = 0,
	V_ELITE,
	V_KNIFE,
	V_M3,
	V_M4A1,
	V_M249,
	V_MP5,
	V_SG552,
	V_TMP,
	V_USP,
}

new const WeaponViewModel[10][] =
{
	"models/zombiebot/v_zombie.mdl",
	"models/zombiebot/v_elite.mdl",
	"models/zombiebot/v_knife.mdl",
	"models/zombiebot/v_m3.mdl",
	"models/zombiebot/v_m4a1.mdl",
	"models/zombiebot/v_m249.mdl",
	"models/zombiebot/v_mp5.mdl",
	"models/zombiebot/v_sg552.mdl",
	"models/zombiebot/v_tmp.mdl",
	"models/zombiebot/v_usp.mdl"
}

new const ZombieSounds[6][] =
{
	"zombiebot/zombie_attack1.wav", // 0
	"zombiebot/zombie_attack2.wav", // 1
	"zombiebot/zombie_die.wav", // 2
	"zombiebot/zombiedog_attack.wav", // 3
	"zombiebot/zombiedog_die.wav", // 4
	"zombiebot/zombiedog_growl.wav" // 5
}

new const WeaponExtraSounds[9][] =
{
	"weapons/hammerback.wav",
	"weapons/leftmagin.wav",
	"weapons/leftmagout.wav",
	"weapons/m249_boltpull.wav",
	"weapons/magbash.wav",
	"weapons/ready.wav",
	"weapons/rightmagin.wav",
	"weapons/rightmagout.wav",
	"weapons/sliderelease.wav"
}

new const GameSounds[9][] = // Don't change the order
{
	"zombiebot/attention.wav", // 0
	"zombiebot/final_level.wav", // 1
	"zombiebot/level_up.wav", // 2
	"zombiebot/one_level_down.wav", // 3
	"zombiebot/safetyzone.wav", // 4
	"zombiebot/two_level_up.wav", // 5
	"zombiebot/vip_assassinated.wav", // 6
	"zombiebot/vip_escaped.wav", // 7
	"zombiebot/you_lose_two_levels.wav" // 8
}

enum
{
	TEAM_NONE = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN,
	TEAM_SPECTATOR
}

new const WEAPONENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", "weapon_c4", "weapon_mac10",
			"weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven", "weapon_ump45", "weapon_sg550",
			"weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
			"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle", "weapon_sg552",
			"weapon_ak47", "weapon_knife", "weapon_p90" }


// =============== Changing Model ===============
#define MODELCHANGE_DELAY 0.1 	// Delay between model changes (increase if getting SVC_BAD kicks)
#define ROUNDSTART_DELAY 2.0 	// Delay after roundstart (increase if getting kicks at round start)
//#define SET_MODELINDEX_OFFSET 	// Enable custom hitboxes (experimental, might lag your server badly with some models)

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
			
// Shared Code
#define PDATA_SAFE 2
#define OFFSET_CSTEAMS 114
#define OFFSET_CSDEATHS 444
#define OFFSET_PLAYER_LINUX 5
#define OFFSET_WEAPON_LINUX 4
#define OFFSET_WEAPONOWNER 41			
			
// Task
#define TASK_SOUND 21100
#define TASK_ADDBOT 21101
#define TASK_SERVERINFO 21102
#define TASK_SPAWN 21103 // Player Task
#define TASK_VOICE 21104
#define TASK_DEATH 21105
			
// Bits
#define Get_BitVar(%1,%2)		(%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2)		(%1 |= (1 << (%2 & 31)));
#define UnSet_BitVar(%1,%2)		(%1 &= ~(1 << (%2 & 31)));

new g_IsVipMode
new /*g_Team, g_Bot, */g_Dog, g_ZombieCount, g_TCount, g_CTCount, g_PlayerCount = 1, g_CTModelCount,
g_EndRoundFlag, g_IsVipAlive, g_IsBotVip, g_B_IsBotDog, g_HamBot,
g_VipSafe = -1, g_B_VipSafeZone, g_B_CanSpawn, g_ServerConfig, g_CTLevel[33], g_CTKillCount[33],
g_TLevel[33], g_TDeathCount[33], g_B_WeaponDrop, g_PlayerSpec[33], g_MsgScreenFade, g_BotAdd
new g_SteamCount, g_SteamAddress[40][24], g_SteamLevel[40], g_SteamPos[33]
new g_Cvar_ZombieBot
new g_MaxPlayers

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)

	g_ServerConfig = 0
	
	// Cvars
	g_Cvar_ZombieBot = register_cvar("re_zombiebot","12")

	// MSG
	g_MsgScreenFade = get_user_msgid("ScreenFade")
	
	if(g_IsVipMode) 
	{
		register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
		register_logevent("Event_RoundStart", 2, "0=World triggered", "1=Round_Start")
		register_logevent("Event_RoundEnd", 2, "0=World triggered", "1=Round_End")
		
		RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1) // event_hud_reset
		
		register_forward(FM_Touch, "fw_Touch")
		register_forward(FM_EmitSound, "fw_EmitSound")
		register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue")
	
		register_message(get_user_msgid("ClCorpse"), "Message_ClCorpse")
		
		for (new i = 1; i < sizeof WEAPONENTNAMES; i++)
			if (WEAPONENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WEAPONENTNAMES[i], "fw_Item_Deploy_Post", 1)
		
		register_clcmd("jointeam", "CMD_JoinTeam")
		register_concmd("re_zombiebot_level", "CMD_SetLevel", ADMIN_VOTE, "- Add level for an admin")
		register_concmd("re_zombiebot_weapon", "CMD_AdminWeapon", ADMIN_VOTE, "- Give admin weapons")
		
		server_cmd("bot_quota 0")
	}
	
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	// Check Map
	new MapName[64]; get_mapname(MapName, 63)
	if(MapName[0] == 'a' && MapName[1] == 's') g_IsVipMode = 1
	else g_IsVipMode = 0
	
	// Precache
	new Buffer[128]
	new i
	
	// Zombie
	for(i = 0; i < sizeof(ZombieModels); i++) 
	{
		formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ZombieModels[i], ZombieModels[i])
		precache_model(Buffer)
	}
	
	// Human
	for(i = 0; i < sizeof(HumanModels); i++) 
	{
		formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", HumanModels[i], HumanModels[i])
		precache_model(Buffer)
	}
	
	// Zombie Dog
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", ZombieDogModel, ZombieDogModel)
	precache_model(Buffer)
	
	// VIP
	formatex(Buffer, sizeof(Buffer), "models/player/%s/%s.mdl", VipModel, VipModel)
	precache_model(Buffer)
	
	// Weapon Models
	for(new i = 0; i < sizeof(WeaponViewModel); i++)
		precache_model(WeaponViewModel[i])
	
	// Zombie Sounds
	for(new i = 0; i < sizeof(ZombieSounds); i++)
		precache_sound(ZombieSounds[i])
	
	// Weapon Extra Sounds
	for(new i = 0; i < sizeof(WeaponExtraSounds); i++)
		precache_sound(WeaponExtraSounds[i])
		
	// Game Sounds
	for(new i = 0; i < sizeof(GameSounds); i++)
		precache_sound(GameSounds[i])
}

public plugin_cfg()
{
	// Bot Configs
	server_cmd("bot_difficulty 3")
	server_cmd("bot_allow_grenades 0")
	server_cmd("bot_allow_machine_guns 0")
	server_cmd("bot_allow_pistols 0")
	server_cmd("bot_allow_rifles 0")
	server_cmd("bot_allow_rogues 0")
	server_cmd("bot_allow_shield 0")
	server_cmd("bot_allow_shotguns 0")
	server_cmd("bot_allow_snipers 0")
	server_cmd("bot_allow_sub_machine_guns 0")
	server_cmd("bot_chatter off")
	server_cmd("bot_join_team t")
	server_cmd("bot_walk 0")
	server_cmd("bot_zombie 0")
	server_cmd("bot_stop 0")
	server_cmd("bot_quota 2")
	
	// Server Configs
	set_cvar_num("mp_forcecamera", 0)
	set_cvar_num("mp_forcechasecam", 0)
	set_cvar_num("mp_limitteams", 0)
	set_cvar_num("mp_autoteambalance", 0)
	set_cvar_num("mp_flashlight", 0)
	set_cvar_num("mp_freezetime", 1)
	set_cvar_num("allow_spectators", 1)
	set_cvar_num("decalfrequency", 300)
	set_cvar_float("mp_roundtime", 3.5)
	set_cvar_num("sv_allowdownload", 0)
	set_cvar_num("sv_timeout", 20)
	set_cvar_num("sv_maxspeed", 400)
	set_cvar_num("sv_restartround", 1)
	
	// OK
	g_ServerConfig = 1
	set_task(3.0, "Task_CheckingDeath", TASK_DEATH)
}

public CMD_SetLevel(id, level, cid)
{
	if(!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
		
	switch(get_user_team(id))
	{
		case TEAM_HUMAN:
		{
			if(g_CTLevel[id] < 9) 
			{
				g_CTLevel[id]++
				client_cmd(id, "spk items/suitchargeok1")
			}
		
		}
		case TEAM_ZOMBIE:
		{
			if(g_TLevel[id] < 9)
			{
				g_TLevel[id]++
				client_cmd(id, "spk items/suitchargeok1")
			}
		}
	}
		
	return PLUGIN_HANDLED
}

public CMD_AdminWeapon(id, level, cid)
{
	if (!cmd_access(id, level, cid, 1))
		return PLUGIN_HANDLED
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
		
	give_item(id, "weapon_m4a1")
	cs_set_user_bpammo(id, CSW_M4A1, 250)
	
	give_item(id, "weapon_ak47")
	cs_set_user_bpammo(id, CSW_AK47, 250)
	
	give_item(id, "weapon_deagle")
	cs_set_user_bpammo(id, CSW_DEAGLE, 250)
	
	client_cmd(id,"spk items/suitchargeok1")
	
	return PLUGIN_HANDLED
}

public client_putinserver(id)
{
	remove_task(id+TASK_CHANGEMODEL)
	UnSet_BitVar(g_HasCustomModel, id)
	
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
	
	if(!g_IsVipMode)
		return 
	
	g_CTLevel[id] = 1
	g_CTKillCount[id] = 0
	g_TLevel[id] = 1
	g_TDeathCount[id] = 0
	g_PlayerSpec[id] = 10
	
	if(!is_user_bot(id))
	{
		static SteamID[24]
		get_user_authid(id, SteamID, 23)
		
		for(new i = 0; i < 40; i++)
		{
			if(contain(g_SteamAddress[i], SteamID) != -1) 
			{
				g_SteamPos[id] = i
				g_CTLevel[id] = g_SteamLevel[i]
				g_TLevel[id] = g_SteamLevel[i]
				
				return
			}
		}
		
		g_SteamAddress[g_SteamCount] = SteamID
		g_SteamPos[id] = g_SteamCount
		g_SteamLevel[g_SteamCount] = 1
		g_SteamCount++
		
		if(g_SteamCount > 39) g_SteamCount = 0
	} else {
		g_TLevel[id] = random_num(3, 9)
	}
	
	set_task(2.5, "Send_ClientCMD",id)
}

public client_disconnect(id)
{
	remove_task(id+TASK_CHANGEMODEL)
	UnSet_BitVar(g_HasCustomModel, id)
}

public Register_HamBot(id) 
{
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
}

public client_damage(attacker, victim, damage, wpnindex, hitplace, TA)
{
	if(!g_ServerConfig)
		return
	
	if(attacker != victim && !TA && get_user_team(victim == TEAM_HUMAN))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, {0,0,0}, victim)
		write_short(8000)
		write_short(1000)
		write_short(0)
		write_byte(100)
		write_byte(0)
		write_byte(0)
		write_byte(248)
		message_end()
	}
}

public client_death(killer, id, wpnindex, hitplace, tk)
{
	if(!g_ServerConfig)
		return
	if(tk || killer == id)
		return
		
	static Final; Final = 0	
	
	// Killer
	switch(get_user_team(killer))
	{
		case TEAM_HUMAN:
		{
			if(!cs_get_user_vip(killer) && !Get_BitVar(g_B_IsBotDog, id))
			{
				g_CTKillCount[killer]++
				if(g_CTKillCount[killer] > 1)
				{
					g_CTKillCount[killer] = 0
					if(g_CTLevel[killer] < 9)
					{
						g_CTLevel[killer]++
						if(!is_user_bot(killer))
						{
							g_SteamLevel[g_SteamPos[killer]] = g_CTLevel[killer]
							
							set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
							if(g_CTLevel[killer] == 9)
							{
								show_hudmessage(killer, HUD_HM_LEVELF)
								set_task(2.0, "final_level_delay",killer)
							} else {
								show_hudmessage(killer, HUD_HM_LEVEL, g_CTLevel[killer])
								set_task(2.0,"level_up_delay",killer)
							}
							
							client_cmd(killer, "spk items/suitchargeok1")
						}
					}
				}
			}
		}
		case TEAM_ZOMBIE:
		{
			if(g_TLevel[killer] < 9)
			{
				g_TLevel[killer]++
				Final = 0
				
				if(g_TLevel[killer] == 9)
				{
					set_task(10.0, "SOUND_FinalLevel", killer+TASK_VOICE)
					Final = 1
				}
				if(cs_get_user_vip(id) && g_TLevel[killer] < 9)
				{
					g_TLevel[killer]++
					if(!is_user_bot(killer))
						set_task(6.0, "SOUND_TwoLevel", killer+TASK_VOICE)
				} else {
					if(!Final) set_task(2.0, "SOUND_LevelUp",killer+TASK_VOICE)
				}
			}
			
			g_TDeathCount[killer] = 0
			if(!Get_BitVar(g_B_IsBotDog, killer))
			{
				static HP; HP = (g_TLevel[killer] * 50) + ZOMBIE_BASEHP
				set_user_health(killer, HP)				
			}
			if(!is_user_bot(killer))
			{
				g_SteamLevel[g_SteamPos[killer]] = g_TLevel[killer]
				
				set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
				if(g_TLevel[killer] == 9) show_hudmessage(killer, HUD_ZB_LEVELF)
				else show_hudmessage(killer, HUD_ZB_LEVEL, g_TLevel[killer])
				
				client_cmd(killer, "spk items/suitchargeok1")
			}
		}
	}
	
	// Victim
	switch(get_user_team(id))
	{
		case TEAM_ZOMBIE:
		{
			if(!Get_BitVar(g_B_IsBotDog, id))
			{
				g_TDeathCount[id]++
				if(g_TDeathCount[id] > 2)
				{
					g_TDeathCount[id] = 0
					if(g_TLevel[id] > 1)
					{
						g_TLevel[id]--
						if(!is_user_bot(id))
						{
							g_SteamLevel[g_SteamPos[id]] = g_TLevel[id]
							
							set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
							show_hudmessage(id, HUD_ZB_LEVEL, g_TLevel[id])
							
							client_cmd(id, "spk fvox/boop")
							set_task(2.0, "SOUND_OneLevelDown",id+TASK_VOICE)
						}
					}
				}
			}
		}
		case TEAM_HUMAN:
		{
			if(!cs_get_user_vip(id) )
			{
				if(g_CTLevel[id] > (3.5 + (g_TCount / 2)))
				{	
					if(g_CTLevel[id] == 9)
					{
						g_CTLevel[id]--
						set_task(2.0, "SOUND_Lose", id+TASK_VOICE)	
					} else {
						set_task(2.0, "SOUND_OneLevelDown",id+TASK_VOICE)	
					}
					
					g_CTLevel[id]--
					
					if(!is_user_bot(id))
					{
						g_SteamLevel[g_SteamPos[id]] = g_CTLevel[id]	
						
						set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
						show_hudmessage(id, HUD_HM_LEVEL, g_CTLevel[id])
						
						client_cmd(id, "spk fvox/boop")
					}
				}
			} else {
				set_task(2.0, "SOUND_VipAssa", TASK_SOUND)
			}
		}
	}
}

public SOUND_FinalLevel(id)
{
	id -= TASK_VOICE
	if(!is_user_connected(id))
		return
		
	PlaySound(id, GameSounds[1])
}

public SOUND_TwoLevel(id)
{
	id -= TASK_VOICE
	if(!is_user_connected(id))
		return
	
	g_SteamLevel[g_SteamPos[id]] = g_TLevel[id]		
	
	set_hudmessage(255, 255, 255, -1.0, 0.65, 2, 0.05, 2.0, 0.01, 2.0, -1)
	show_hudmessage(id, HUD_2LVUP)
	
	PlaySound(id, GameSounds[5])
}

public SOUND_LevelUp(id)
{
	id -= TASK_VOICE
	if(!is_user_connected(id))
		return
		
	PlaySound(id, GameSounds[2])
}

public SOUND_OneLevelDown(id)
{
	id -= TASK_VOICE
	if(!is_user_connected(id))
		return
		
	PlaySound(id, GameSounds[3])
}

public SOUND_Lose(id)
{
	id -= TASK_VOICE
	if(!is_user_connected(id))
		return
		
	PlaySound(id, GameSounds[8])
}

public SOUND_VipAssa() PlaySound(0, GameSounds[6])

public Send_ClientCMD(id)
{
	if(is_user_bot(id))
		return
	
	client_cmd(id, "cl_dlmax 80")
	client_cmd(id, "cl_minmodels 0")	
	
	client_print(id, print_chat, MSG_CREDIT)
	client_cmd(id, "spk zombiebot/attention")
}

public Event_NewRound()
{
	g_ModelChangeTargetTime = get_gametime() + ROUNDSTART_DELAY
	
	for(new player = 0; player < g_MaxPlayers; player++)
	{
		if(task_exists(player+TASK_CHANGEMODEL))
		{
			remove_task(player+TASK_CHANGEMODEL)
			fm_cs_user_model_update(player+TASK_CHANGEMODEL)
		}
	}
}

public Message_ClCorpse()
{
	static id
	id = get_msg_arg_int(12)
	
	set_msg_arg_string(1, g_CustomPlayerModel[id])

	return PLUGIN_CONTINUE
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


public Event_RoundStart()
{
	if(g_ServerConfig)
	{
		g_IsVipAlive = 0
		g_VipSafe = 0
		g_EndRoundFlag = 0
	}
}

public Event_RoundEnd()
{
	if(!g_ServerConfig)
		return
	
	g_EndRoundFlag = 1
	g_ZombieCount = 0
	g_TCount = 0
	g_CTCount = 0
	
	static Team, Bot
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_connected(i))
			continue
			
		if(get_user_team(i) == TEAM_NONE || get_user_team(i) == TEAM_SPECTATOR) 
		{
			g_PlayerSpec[i]--
			if(!g_PlayerSpec[i]) client_cmd(i,"disconnect")
			
			client_print(i, print_chat, MSG_CHOOSETEAM)
		}
		
		Set_BitVar(g_B_CanSpawn, i)
		Team = get_user_team(i)
		Bot = is_user_bot(i)
		
		if(Team == TEAM_ZOMBIE)
		{
			if(!Bot)  g_TCount++
			g_ZombieCount++
		} else if(Team == TEAM_HUMAN) {
			if(!Bot) 
			{
				if(cs_get_user_vip(i))
				{
					if(Get_BitVar(g_B_VipSafeZone, i)) 
					{
						g_VipSafe = 1
						client_print(0, print_chat, MSG_VIPESCAPED)
						
						set_task(2.0, "Sound_VIPEscaped", TASK_SOUND)
						
						if (g_CTLevel[i] < MAX_CTLEVEL)
						{
							g_CTLevel[i]++
							PlaySound(i, "items/suitchargeok1.wav") // HL Default sound
						}
					}
				}
				
				g_CTCount++
			} else {
			
				if(!cs_get_user_vip(i)) cs_set_user_team(i, CS_TEAM_T, CS_T_TERROR)	
				else g_IsBotVip = 1
			}
		}
	}
	
	if(g_CTCount >= get_pcvar_num(g_Cvar_ZombieBot)) set_cvar_num("mp_limitteams", 1)
	else if(g_ZombieCount > g_CTCount) set_cvar_num("mp_limitteams", 0)

	static Shift
	
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		Shift = 0
		if(g_CTCount > g_ZombieCount && g_CTCount > get_pcvar_num(g_Cvar_ZombieBot)) 
		{
			if(is_user_connected(g_PlayerCount) && get_user_team(g_PlayerCount) == TEAM_HUMAN && !cs_get_user_vip(g_PlayerCount) && !is_user_alive(g_PlayerCount) && !is_user_admin(g_PlayerCount)) 
			{
				client_print(0, print_chat, MSG_AB_MANYHM)
				client_print(g_PlayerCount, print_chat, MSG_AB_ZBNOW)
				
				cs_set_user_team(g_PlayerCount, CS_TEAM_T, CS_T_TERROR)
				Shift = 1
				
				g_CTCount--
				g_TCount++
				g_ZombieCount++
				
				g_TLevel[g_PlayerCount] = g_CTLevel[g_PlayerCount]
				if(g_CTLevel[g_PlayerCount] > 1)  g_CTLevel[g_PlayerCount]--
				
				g_TDeathCount[g_PlayerCount]=0
				g_CTKillCount[g_PlayerCount]=0
			}
		} else {
			if(g_CTCount < g_TCount && g_CTCount > get_pcvar_num(g_Cvar_ZombieBot) && !Shift) 
			{
				if(is_user_connected(g_PlayerCount) && get_user_team(g_PlayerCount) == TEAM_ZOMBIE && !is_user_bot(g_PlayerCount) && !is_user_alive(g_PlayerCount) && !is_user_admin(g_PlayerCount))
				{
					client_print(0, print_chat, MSG_AB_MANYZB)
					client_print(g_PlayerCount, print_chat, MSG_AB_HMNOW)
					
					UnSet_BitVar(g_B_CanSpawn, g_PlayerCount)
					cs_set_user_team(g_PlayerCount, CS_TEAM_CT, CS_CT_URBAN)
					
					g_CTCount++
					g_TCount--
					g_ZombieCount--
					
					g_CTLevel[g_PlayerCount] = g_TLevel[g_PlayerCount]
					
					if(g_TLevel[g_PlayerCount] > 1) g_TLevel[g_PlayerCount]--
					g_TDeathCount[g_PlayerCount] = 0
					g_CTKillCount[g_PlayerCount] = 0
				}
			} else {
				i = 33
			}
		}
		
		g_PlayerCount++ 
		if(g_PlayerCount > 32) g_PlayerCount = 1
	}
	
	static BonusBot; BonusBot = 0
	
	if (g_CTCount < 9) BonusBot++
	if (g_CTCount < 7) BonusBot++
	if (g_CTCount < 5) BonusBot++
	if (g_CTCount < 3) BonusBot++

	Bot = g_CTCount + BonusBot
	if(Bot > get_pcvar_num(g_Cvar_ZombieBot)) Bot = get_pcvar_num(g_Cvar_ZombieBot)
		
	Bot= Bot - g_TCount
	if(Bot < 0) Bot=0
		
	g_Dog = g_ZombieCount - g_CTCount
	g_Dog = g_Dog + (g_TCount * 2)
	
	if(g_Dog < 3) g_Dog = 3
	
	if(!g_IsBotVip) 
	{
		set_cvar_num("mp_freezetime", 1)
		server_cmd("bot_quota %d", Bot)
	} else {
		g_IsBotVip = 0
		set_cvar_num("mp_freezetime", 5)
		server_cmd("bot_quota 0")
	
		g_BotAdd = Bot
		set_task(3.0, "Add_TBot", TASK_ADDBOT)
	}
	
	set_task(20.0, "ServerInfo", TASK_SERVERINFO)
}

public Add_TBot() server_cmd("bot_quota %d", g_BotAdd)
public ServerInfo() client_print(0, print_chat, MSG_SERVERINFO)
public Sound_VIPEscaped() PlaySound(0, GameSounds[7]) // VIP Escaped

public CMD_JoinTeam(id)
{
	if(!g_ServerConfig)
		return
	if(get_user_team(id) == TEAM_ZOMBIE) 
		UnSet_BitVar(g_B_CanSpawn, id)
}

public fw_PlayerSpawn_Post(id)
{
	if(!is_user_alive(id))
		return
	
	remove_task(id+TASK_SPAWN)
	cs_set_user_money(id, 0)	
	
	// Shit ?
	if(g_VipSafe && get_user_team(id) == TEAM_HUMAN) 
	{
		if(g_CTLevel[id] < 7) 
		{
			g_CTLevel[id]++
			if(!is_user_bot(id)) set_task(0.5, "VipBonus", id+TASK_SPAWN)
		}
	}
	
	// Handle
	switch(get_user_team(id))
	{
		case TEAM_ZOMBIE:
		{
			UnSet_BitVar(g_B_WeaponDrop, id)
			
			set_user_footsteps(id, 1)							
			set_user_gravity(id, ZOMBIE_GRAVITY)
			
			client_cmd(0, "spk roach/rch_walk")
			
			if(!is_user_bot(id))
			{
				UnSet_BitVar(g_B_IsBotDog, id)
				cs_set_user_armor(id, ZOMBIE_ARMOR, CS_ARMOR_VESTHELM)
				
				static HP; HP = g_TLevel[id]
				HP = (HP * 50) + ZOMBIE_BASEHP; set_user_health(id, HP)	
				
				set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
				if(g_TLevel[id] == 9) show_hudmessage(id, HUD_ZB_LEVELF, HP)
				else show_hudmessage(id, HUD_ZB_LEVEL, g_TLevel[id], HP)
				
			} else {
				if(g_Dog > 0) 
				{
					set_user_health(id, 100)	
					set_pev(id, pev_maxspeed, 400.0)
					set_pev(id, pev_viewmodel2, "")
					
					g_Dog-- 
					Set_BitVar(g_B_IsBotDog, id)
				} else {
					static HP; HP = g_TLevel[id]
					HP = (HP * 50) + ZOMBIE_BASEHP; set_user_health(id, HP)	
					
					cs_set_user_armor(id, ZOMBIE_ARMOR, CS_ARMOR_VESTHELM)		
					set_pev(id, pev_maxspeed, 280.0)
					
					UnSet_BitVar(g_B_IsBotDog, id)
				}
			}
		}
		case TEAM_HUMAN:
		{
			UnSet_BitVar(g_B_IsBotDog, id)
			UnSet_BitVar(g_B_VipSafeZone, id)
			
			set_user_footsteps(id, 0)						
			set_user_gravity(id, HUMAN_GRAVITY)
			
			static Ammo; 
			switch(g_CTLevel[id]) 
			{						
				case 1: Ammo = 150
				case 2: Ammo = 200
				case 3..9: Ammo = 250
				default: Ammo = 0
			}
			cs_set_user_bpammo(id, CSW_USP, Ammo)
			
			set_user_health(id, HUMAN_HP)						
			set_hudmessage(255, 255, 255, -1.0, 0.60, 2, 0.05, 2.0, 0.01, 2.0, -1)
			if(g_CTLevel[id] == 9) show_hudmessage(id, HUD_HM_LEVELF)
			else show_hudmessage(id, HUD_HM_LEVEL, g_CTLevel[id])
			
			if(!cs_get_user_vip(id)) 
			{					
				cs_set_user_armor(id, HUMAN_ARMOR, CS_ARMOR_VESTHELM)		
				set_pev(id, pev_maxspeed, HUMAN_SPEED)
				
				if(!is_user_bot(id)) set_task(0.25, "Give_Stage1", id+TASK_SPAWN)
			} else {
				set_pev(id, pev_maxspeed, HUMAN_SPEED)
				if(!g_VipSafe) client_cmd(id,"spk zombiebot/safetyzone")	
			}
		}
		
	}	
	
	Set_PlayerModel(id)
}

public Set_PlayerModel(id)
{
	switch(get_user_team(id))
	{
		case TEAM_ZOMBIE:
		{
			if(is_user_bot(id)) 
			{
				if(Get_BitVar(g_B_IsBotDog, id)) Native_SetModel(id, ZombieDogModel)
				else Native_SetModel(id, ZombieModels[g_TLevel[id] - 1])
			} else Native_SetModel(id, ZombieModels[g_TLevel[id] - 1])
		}
		case TEAM_HUMAN:
		{
			if(cs_get_user_vip(id)) 
			{
				Native_SetModel(id, VipModel)
				
				if(is_user_bot(id))
				{
					set_hudmessage(255, 0, 0, -1.0, 0.45, 2, 0.05, 30.0, 0.01, 2.0, -1)
					show_hudmessage(0, HUD_BOTVIP)
				}
			} else {
				Native_SetModel(id, HumanModels[g_CTModelCount])
				g_CTModelCount++
				if(g_CTModelCount >= sizeof(HumanModels)) g_CTModelCount = 0
			}
		}
	}		
}

public VipBonus(id)
{
	id -= TASK_SPAWN
	if(!is_user_connected(id)) return
	
	g_SteamLevel[g_SteamPos[id]] = g_CTLevel[id]
	set_hudmessage(255, 255, 255, -1.0, 0.65, 2, 0.05, 2.0, 0.01, 2.0, -1)
	show_hudmessage(id, HUD_LEVELUPVIP)
	
	client_cmd(id, "spk items/suitchargeok1")
}

public Give_Stage1(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	switch(g_CTLevel[id]) 
	{
		case 1: { give_item(id, "weapon_elite"); cs_set_user_bpammo(id, CSW_ELITE, 150); }
		case 2: { give_item(id, "weapon_elite"); cs_set_user_bpammo(id, CSW_ELITE, 200); }
		case 3..7: { give_item(id, "weapon_elite"); cs_set_user_bpammo(id, CSW_ELITE, 250); }
		case 8..9: give_item(id, "weapon_hegrenade")
	}
	if(g_CTLevel[id] > 1) set_task(0.25, "Give_Spage2", id+TASK_SPAWN)
}

public Give_Stage2(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	if(g_CTLevel[id] >= 2 && g_CTLevel[id] <= 7) give_item(id,"weapon_tmp")
	if(g_CTLevel[id] > 2) set_task(0.25, "Give_Stage3", id+TASK_SPAWN)
}

public Give_Stage3(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	if(g_CTLevel[id] >= 3 && g_CTLevel[id] <= 7) give_item(id,"weapon_mp5navy")
	if(g_CTLevel[id] > 3) set_task(0.25, "Give_Stage4", id+TASK_SPAWN)
}

public Give_Stage4(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	give_item(id,"weapon_m4a1")
		
	switch(g_CTLevel[id])
	{
		case 4: cs_set_user_bpammo(id,CSW_M4A1,150)
		case 5: cs_set_user_bpammo(id,CSW_M4A1,200)
		case 6..9: cs_set_user_bpammo(id,CSW_M4A1,250)
	}
	if(g_CTLevel[id] > 4) set_task(0.25, "Give_Stage5", id+TASK_SPAWN)
}		

public Give_Stage5(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	give_item(id,"weapon_m3")
	switch(g_CTLevel[id])
	{
		case 5: cs_set_user_bpammo(id, CSW_M3, 30)
		case 6: cs_set_user_bpammo(id, CSW_M3, 60)
		case 7..9: cs_set_user_bpammo(id, CSW_M3, 90)
	
	}
	if(g_CTLevel[id] > 5) set_task(0.25, "Give_Stage6", id+TASK_SPAWN)
}

public Give_Stage6(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
		
	give_item(id,"weapon_sg552")
	if(g_CTLevel[id] > 8) set_task(0.25, "Give_Stage7", id+TASK_SPAWN)
}

public Give_Stage7(id)
{
	id -= TASK_SPAWN
	
	if(!is_user_alive(id))
		return
	
	give_item(id, "weapon_m249")
	cs_set_user_bpammo(id, CSW_M249, 150)
}

public fw_Item_Deploy_Post(Ent)
{
	static id; id = fm_cs_get_weapon_ent_owner(Ent)
	if (!is_user_alive(id))
		return;
	
	static CSWID; CSWID = cs_get_weapon_id(Ent)
	static Team; Team = get_user_team(id)
	
	if(Team == TEAM_ZOMBIE)
	{
		if(CSWID == CSW_KNIFE)
		{
			Set_ZombieClaw(id)
		} else if(CSWID != CSW_HEGRENADE && CSWID != CSW_FLASHBANG && CSWID != CSW_SMOKEGRENADE) {
			strip_user_weapons(id)
			
			give_item(id, "weapon_knife")
			engclient_cmd(id, "weapon_knife")
			
			Set_Player_NextAttack(id, 0.75)
			set_weapons_timeidle(id, CSW_KNIFE, 1.0)
			Set_WeaponAnim(id, 3)
		}
	} else if(Team == TEAM_HUMAN) {
		switch(CSWID)
		{
			case CSW_ELITE:		set_pev(id, pev_viewmodel2, WeaponViewModel[V_ELITE])
			case CSW_KNIFE:		set_pev(id, pev_viewmodel2, WeaponViewModel[V_KNIFE])
			case CSW_M249: 		set_pev(id, pev_viewmodel2, WeaponViewModel[V_M249])
			case CSW_M3: 		set_pev(id, pev_viewmodel2, WeaponViewModel[V_M3])
			case CSW_M4A1: 		set_pev(id, pev_viewmodel2, WeaponViewModel[V_M4A1])
			case CSW_MP5NAVY: 	set_pev(id, pev_viewmodel2, WeaponViewModel[V_MP5])
			case CSW_TMP: 		set_pev(id, pev_viewmodel2, WeaponViewModel[V_TMP])
			case CSW_SG552: 	set_pev(id, pev_viewmodel2, WeaponViewModel[V_SG552])
			case CSW_USP: 		set_pev(id, pev_viewmodel2, WeaponViewModel[V_USP])
		}
	}
}

public Set_ZombieClaw(id)
{
	if(get_user_weapon(id) != CSW_KNIFE) engclient_cmd(id, "weapon_knife")
	
	set_pev(id, pev_viewmodel2, WeaponViewModel[V_ZOMBIE])
	set_pev(id, pev_weaponmodel2, "")	
	
	Set_Player_NextAttack(id, 0.75)
	set_weapons_timeidle(id, CSW_KNIFE, 1.0)
	Set_WeaponAnim(id, 3)
}

public fw_Touch(touched, toucher) 
{
	if(!pev_valid(touched) || !is_user_connected(toucher))
		return FMRES_IGNORED

	static ClassName[16]; pev(touched, pev_classname, ClassName, 15)
	
	if(ClassName[5] == 'v' && ClassName[6] == 'i') 
		Set_BitVar(g_B_VipSafeZone, toucher)
	if(ClassName[8] != 'x' && !(ClassName[0] == 'w' && ClassName[1] == 'e' && ClassName[2] == 'a') && !(ClassName[0] == 'a' && ClassName[1] == 'r' && ClassName[2] == 'm')) 
		return FMRES_IGNORED

	static Model[32]; pev(touched, pev_model, Model, 31)
	if(get_user_team(toucher) == TEAM_HUMAN)
	{
		if(Model[9] == 'u') 								/* usp */
			return FMRES_IGNORED
		if(Model[9] == 'e')								/* elite */
			return FMRES_IGNORED
		if(Model[9] == 't' && g_CTLevel[toucher] > 1)					/* tmp */
			return FMRES_IGNORED
		if(Model[10] == 'p' && g_CTLevel[toucher] > 2)					/* mp5 */
			return FMRES_IGNORED
		if(Model[10] == '4' && g_CTLevel[toucher] > 3)					/* m4a1 */
			return FMRES_IGNORED
		if(Model[10] == '3' && g_CTLevel[toucher] > 4)					/* m3 */
			return FMRES_IGNORED
		if(Model[9] == 's' && g_CTLevel[toucher] > 5)					/* sg552 */
			return FMRES_IGNORED
		if(Model[10] == '2' && g_CTLevel[toucher] > 8)					/* m249 */
			return FMRES_IGNORED
		if(Model[9] == 'h' && g_CTLevel[toucher] > 7)					/* he */
			return FMRES_IGNORED
	}
	
	return FMRES_SUPERCEDE
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_team(id) != TEAM_ZOMBIE)
		return FMRES_IGNORED
		
	if(contain(sample, "player/die") != -1 || contain(sample, "player/death") != -1)
	{
		if(Get_BitVar(g_B_IsBotDog, id))
		{
			emit_sound(id, channel, ZombieSounds[4], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		} else {
			emit_sound(id, channel, ZombieSounds[2], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
	}

	if (contain(sample, "weapons/knife_hit") != -1 || contain(sample, "weapons/knife_stab") != -1)
	{
		if(Get_BitVar(g_B_IsBotDog, id))
		{
			switch(random_num(0, 1)) 
			{
				case 0: emit_sound(id, channel, ZombieSounds[3], volume, attn, flags, pitch)
				case 1: emit_sound(id, channel, ZombieSounds[5], volume, attn, flags, pitch)
			}
			return FMRES_SUPERCEDE
		} else {
			switch(random_num(0, 1)) 
			{
				case 0: emit_sound(id, channel, ZombieSounds[0], volume, attn, flags, pitch)
				case 1: emit_sound(id, channel, ZombieSounds[1], volume, attn, flags, pitch)
			}
			return FMRES_SUPERCEDE
		}
	}
		
	return FMRES_IGNORED
}

public Task_CheckingDeath()
{
	if(!g_ServerConfig)
		return
	if(g_EndRoundFlag)
	{
		set_task(10.0, "Task_CheckingDeath", TASK_DEATH)
		return
	}
													/* nicht w?end Rundenende */
	g_IsVipAlive++
	if(is_user_connected(g_PlayerCount)) 
	{
		switch(get_user_team(g_PlayerCount))
		{
			case TEAM_ZOMBIE:
			{
				if(!is_user_alive(g_PlayerCount)) 
				{
					if(g_IsVipAlive < 33 && Get_BitVar(g_B_CanSpawn, g_PlayerCount)) 
						set_task(1.0, "SpawnPlayer", g_PlayerCount+TASK_SPAWN)
				} else {
					if(!Get_BitVar(g_B_IsBotDog, g_PlayerCount)) 
					{
						static HP; HP = (g_TLevel[g_PlayerCount] * 50) + ZOMBIE_BASEHP
						static TMP_HP; TMP_HP = get_user_health(g_PlayerCount)
						
						if(TMP_HP < HP) 
						{
							TMP_HP += 125
							if(TMP_HP > HP) TMP_HP = HP
							
							set_user_health(g_PlayerCount, TMP_HP)
							if(!is_user_bot(g_PlayerCount)) client_cmd(g_PlayerCount,"spk items/medshot4")
						}
						if(!is_user_bot(g_PlayerCount))
						{
							set_hudmessage(255, 255, 255, -1.0, 0.55, 2, 0.05, 2.0, 0.01, 2.0, -1)
							show_hudmessage(g_PlayerCount, HUD_HAVEHP, TMP_HP)
						}
					}
				}
			}
			case TEAM_HUMAN:
			{
				if(is_user_alive(g_PlayerCount) && cs_get_user_vip(g_PlayerCount))
				{
					if(is_user_bot(g_PlayerCount)) g_IsVipAlive=33					/* es gibt keinen reellen Spieler als VIP */
					else g_IsVipAlive = 0
				}
			}
		}
	}
	
	g_PlayerCount++
	if(g_PlayerCount > 32) g_PlayerCount = 1
	
	set_task(0.25, "Task_CheckingDeath", TASK_DEATH)							/* n?hste Pr?ung in ... Sekunden */
}

public SpawnPlayer(id) 
{
	if(!is_user_connected(id))
		return
	if(get_user_team(id) != TEAM_ZOMBIE)
		return
		
	set_pev(id, pev_deadflag, 3)
	call_think(id)
	entity_set_int(id, EV_INT_iuser1, 0)
	spawn(id) // GEDO RINNE TENSEI NO JUTSU!
	
	if(!Get_BitVar(g_B_IsBotDog, id))
	{
		static HP; HP = (g_TLevel[id] * 50) + ZOMBIE_BASEHP
		set_user_health(id, HP)
		if(!is_user_bot(id))
		{
			client_cmd(id, "spk buttons/blip2")
			set_hudmessage(255, 255, 255, -1.0, 0.55, 2, 0.05, 2.0, 0.01, 2.0, -1)
			show_hudmessage(id, HUD_HAVEHP, HP)
		}
	}
}

stock fm_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_WEAPON_LINUX);
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

stock set_weapons_timeidle(id, WeaponId ,Float:TimeIdle)
{
	static entwpn; entwpn = fm_get_user_weapon_entity(id, WeaponId)
	if(!pev_valid(entwpn)) 
		return
		
	set_pdata_float(entwpn, 46, TimeIdle, 4)
	set_pdata_float(entwpn, 47, TimeIdle, 4)
	set_pdata_float(entwpn, 48, TimeIdle + 0.5, 4)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

public Native_SetModel(id, const Model[])
{
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[GM] CM: Player is not in game (%d)", id)
		return false
	}
	
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

public Native_ResetModel(id)
{
	if(!is_user_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[GM] CM: Player is not in game (%d)", id)
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

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1042\\ f0\\ fs16 \n\\ par }
*/
