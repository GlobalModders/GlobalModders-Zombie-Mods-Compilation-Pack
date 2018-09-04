#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <xs>

#if AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or later library required!
#endif

#include <hamsandwich>

/*================================================================================
 [Constants, Offsets, Macros]
=================================================================================*/

new const PLUGIN_VERSION[] = "1.8.8 RC2"

#define DODW_AMERKNIFE		1
#define DODW_GERKNIFE		2
#define DODW_SPADE			19

// do not change this
const MAX_RENDER_AMOUNT = 255
const SEMI_RENDER_AMOUNT = 200
const Float:SPEC_INTERVAL = 0.2
const Float:RANGE_INTERVAL = 0.1

enum
{
	MOD_CSTRIKE = 1,
	MOD_DOD
}
new g_iMod, g_iZombieMod

const PEV_SPEC_TARGET = pev_iuser2
enum (+= 1000)
{
	TASK_SPECTATOR = 3128,
	TASK_RANGE,
	TASK_DURATION
}

#define ID_SPECTATOR	(taskid - TASK_SPECTATOR)
#define ID_RANGE		(taskid - TASK_RANGE)

const OFFSET_CS_WEAPONOWNER = 41
const OFFSET_DOD_WEAPONOWNER = 89
const OFFSET_CS_WEAPONID = 43
const OFFSET_DOD_WEAPONID = 91
const OFFSET_LINUX = 5
const OFFSET_LINUX_WEAPONS = 4
const PDATA_SAFE = 2

new const WPN_CS_ENTNAMES[][] = { "", "weapon_p228", "", "weapon_scout", "weapon_hegrenade", "weapon_xm1014",
"weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", "weapon_fiveseven",
"weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", "weapon_usp", "weapon_glock18", "weapon_awp",
"weapon_mp5navy", "weapon_m249", "weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang",
"weapon_deagle", "weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" }

new const WPN_DOD_ENTNAMES[][] = { "", "weapon_amerknife", "weapon_gerknife", "weapon_colt", "weapon_luger",
"weapon_garand", "weapon_scopedkar", "weapon_thompson", "weapon_mp44", "weapon_spring", "weapon_kar",
"weapon_bar", "weapon_mp40", "weapon_mg42", "weapon_30cal", "weapon_spade", "weapon_m1carbine", "weapon_mg34",
"weapon_greasegun", "weapon_fg42", "weapon_k43", "weapon_enfield", "weapon_sten", "weapon_bren", "weapon_webley" }

new Float:random_own_place[][3] =
{
	{ 0.0, 0.0, 0.0 },
	{ -32.5, 0.0, 0.0 },
	{ 32.5, 0.0, 0.0 },
	{ 0.0, -32.5, 0.0 },
	{ 0.0, 32.5, 0.0 },
	{ -32.5, -32.5, 0.0 },
	{ -32.5, 32.5, 0.0 },
	{ 32.5, 32.5, 0.0 },
	{ 32.5, -32.5, 0.0 }
}

/*================================================================================
 [Global Variables]
=================================================================================*/

new cvar_iSemiClipRenderRadius, cvar_iSemiClipEnemies, cvar_iSemiClipButton,
cvar_flSemiClipUnstuckDelay, cvar_iSemiClipBlockTeams, cvar_iSemiClipUnstuck,
cvar_iSemiClipRenderMode, cvar_iSemiClipRenderAmt, cvar_iSemiClipRenderFade,
cvar_iSemiClipRenderFadeMin, cvar_iSemiClipRenderFadeSpec, cvar_iSemiClip,
cvar_iSemiClipRenderFx, cvar_iSemiClipKnifeTrace, cvar_flSemiClipDuration,
cvar_iSemiClipColorTeam1[3], cvar_iSemiClipColorTeam2[3], cvar_iSemiClipRender,
cvar_iSemiClipColorAdmin[3], cvar_szSemiClipColorFlag

new cvar_iBotQuota, cvar_iZombiePlague, cvar_iBiohazard, bool:g_bHamCzBots,
g_iMaxPlayers, bool:g_bPreparation, g_iAddToFullPack, g_iTraceLine, g_iCmdStart

new g_iSpawnCount, Float:g_flSpawns[32][3], g_iSpawnCount2, Float:g_flSpawns2[32][3],
g_iSpawnCount3, Float:g_flSpawns3[128][3]

new g_iCachedSemiClip, g_iCachedEnemies, g_iCachedBlockTeams, g_iCachedUnstuck,
Float:g_flCachedUnstuckDelay, g_iCachedFadeMin, g_iCachedFadeSpec,
g_iCachedMode, g_iCachedRadius, g_iCachedAmt, g_iCachedFx, g_iCachedRender,
g_iCachedFade, g_iCachedButton, g_iCachedKnifeTrace, g_iCachedColorTeam1[3],
g_iCachedColorTeam2[3], g_iCachedColorAdmin[3], g_iCachedColorFlag

new bs_IsAlive, bs_IsConnected, bs_IsBot, bs_IsSolid, bs_InSemiClip, bs_InButton, bs_IsAdmin
new g_iTeam[33], g_iSpectating[33], g_iSpectatingTeam[33], g_iCurrentWeapon[33],
g_iRange[33][33]

#define BugsyAddFlag(%1,%2)		(%1 |= (1<<(%2-1)))
#define BugsyRemoveFlag(%1,%2)	(%1 &= ~(1<<(%2-1)))
#define BugsyCheckFlag(%1,%2)	(%1 & (1<<(%2-1)))

#define is_user_valid_connected(%1)	(1 <= %1 <= g_iMaxPlayers && BugsyCheckFlag(bs_IsConnected, %1))
#define is_user_valid_alive(%1)		(1 <= %1 <= g_iMaxPlayers && BugsyCheckFlag(bs_IsAlive, %1))
#define is_same_team(%1,%2)			(g_iTeam[%1] == g_iTeam[%2])

// tsc_set_user_rendering
enum
{
	SPECIAL_MODE = 0,
	SPECIAL_AMT,
	SPECIAL_FX,
	MAX_SPECIAL
}
new bs_IsSpecial
new g_iRenderSpecial[33][MAX_SPECIAL]
new g_iRenderSpecialColor[33][3]

/*================================================================================
 [Natives, Init and Cfg]
=================================================================================*/

public plugin_natives()
{
	register_native("tsc_set_user_rendering", "native_set_rendering", 1)
}

public plugin_init()
{
	register_plugin("Team Semiclip", PLUGIN_VERSION, "schmurgel1983")
	
	RegisterHam(Ham_Spawn, "player", "fwd_PlayerSpawn_Post", 1)
	RegisterHam(Ham_Killed, "player", "fwd_PlayerKilled")
	RegisterHam(Ham_Player_PreThink, "player", "fwd_Player_PreThink_Post", 1)
	RegisterHam(Ham_Player_PostThink, "player", "fwd_Player_PostThink")
	
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fwd_AddToFullPack_Post", 1)
	g_iTraceLine = register_forward(FM_TraceLine, "fwd_TraceLine_Post", 1)
	g_iCmdStart = register_forward(FM_CmdStart, "fwd_CmdStart")
	
	new mod[12]
	get_modname(mod, charsmax(mod))
	if (equal(mod, "cstrike") || equal(mod, "czero"))
	{
		g_iMod = MOD_CSTRIKE
		register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
		register_message(get_user_msgid("TeamInfo"), "message_TeamInfo")
		for (new i = 1; i < sizeof WPN_CS_ENTNAMES; i++)
			if (WPN_CS_ENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WPN_CS_ENTNAMES[i], "fwd_Item_Deploy_Post", 1)
	}
	else if (equal(mod, "dod"))
	{
		g_iMod = MOD_DOD
		register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
		register_message(get_user_msgid("PTeam"), "message_PTeam")
		for (new i = 1; i < sizeof WPN_DOD_ENTNAMES; i++)
			if (WPN_DOD_ENTNAMES[i][0]) RegisterHam(Ham_Item_Deploy, WPN_DOD_ENTNAMES[i], "fwd_Item_Deploy_Post", 1)
	}
	
	cvar_iSemiClip = register_cvar("semiclip", "1")
	cvar_iSemiClipBlockTeams = register_cvar("semiclip_blockteam", "0")
	cvar_iSemiClipEnemies = register_cvar("semiclip_enemies", "0")
	cvar_iSemiClipUnstuck = register_cvar("semiclip_unstuck", "1")
	cvar_flSemiClipUnstuckDelay = register_cvar("semiclip_unstuckdelay", "0.1")
	cvar_iSemiClipButton = register_cvar("semiclip_button", "0")
	cvar_iSemiClipKnifeTrace = register_cvar("semiclip_knife_trace", "0")
	cvar_flSemiClipDuration = register_cvar("semiclip_duration", "0")
	
	cvar_iSemiClipRender = register_cvar("semiclip_render", "1")
	cvar_iSemiClipRenderMode = register_cvar("semiclip_rendermode", "2")
	cvar_iSemiClipRenderAmt = register_cvar("semiclip_renderamt", "129")
	cvar_iSemiClipRenderFx = register_cvar("semiclip_renderfx", "0")
	cvar_iSemiClipRenderRadius = register_cvar("semiclip_renderradius", "250")
	cvar_iSemiClipRenderFade = register_cvar("semiclip_renderfade", "0")
	cvar_iSemiClipRenderFadeMin = register_cvar("semiclip_renderfademin", "25")
	cvar_iSemiClipRenderFadeSpec = register_cvar("semiclip_renderfadespec", "1")
	
	cvar_szSemiClipColorFlag = register_cvar("semiclip_color_admin_flag", "b")
	cvar_iSemiClipColorAdmin[0] = register_cvar("semiclip_color_admin_R", "0")
	cvar_iSemiClipColorAdmin[1] = register_cvar("semiclip_color_admin_G", "0")
	cvar_iSemiClipColorAdmin[2] = register_cvar("semiclip_color_admin_B", "0")
	cvar_iSemiClipColorTeam1[0] = register_cvar("semiclip_color_team1_R", "0")
	cvar_iSemiClipColorTeam1[1] = register_cvar("semiclip_color_team1_G", "0")
	cvar_iSemiClipColorTeam1[2] = register_cvar("semiclip_color_team1_B", "0")
	cvar_iSemiClipColorTeam2[0] = register_cvar("semiclip_color_team2_R", "0")
	cvar_iSemiClipColorTeam2[1] = register_cvar("semiclip_color_team2_G", "0")
	cvar_iSemiClipColorTeam2[2] = register_cvar("semiclip_color_team2_B", "0")
	
	register_cvar("Team_Semiclip_version", PLUGIN_VERSION, FCVAR_SERVER|FCVAR_SPONLY)
	set_cvar_string("Team_Semiclip_version", PLUGIN_VERSION)
	
	cvar_iBotQuota = get_cvar_pointer("bot_quota")
	cvar_iZombiePlague = get_cvar_pointer("zp_on")
	cvar_iBiohazard = get_cvar_pointer("bh_enabled")
	
	if (cvar_iZombiePlague) g_iZombieMod = get_pcvar_num(cvar_iZombiePlague)
	if (!g_iZombieMod && cvar_iBiohazard) g_iZombieMod = get_pcvar_num(cvar_iBiohazard)
	
	g_iMaxPlayers = get_maxplayers()
}

public plugin_cfg()
{
	new configsdir[32]
	get_configsdir(configsdir, charsmax(configsdir))
	server_cmd("exec %s/team_semiclip.cfg", configsdir)
	
	new ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	
	if (pev_valid(ent))
	{
		register_think("ent_cache_cvars", "cache_cvars_think")
		
		set_pev(ent, pev_classname, "ent_cache_cvars")
		set_pev(ent, pev_nextthink, get_gametime() + 1.0)
	}
	else
	{
		set_task(1.0, "cache_cvars")
		set_task(12.0, "cache_cvars", _, _, _, "b")
	}
	
	set_task(1.5, "load_spawns")
}

public plugin_pause()
{
	unregister_forward(FM_AddToFullPack, g_iAddToFullPack, 1)
	unregister_forward(FM_TraceLine, g_iTraceLine, 1)
	unregister_forward(FM_CmdStart, g_iCmdStart)
	
	for (new i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, i) || !BugsyCheckFlag(bs_IsAlive, i)) continue
		
		if (BugsyCheckFlag(bs_InSemiClip, i))
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX)
			BugsyRemoveFlag(bs_InSemiClip, i);
		}
	}
}

public plugin_unpause()
{
	g_iAddToFullPack = register_forward(FM_AddToFullPack, "fwd_AddToFullPack_Post", 1)
	g_iTraceLine = register_forward(FM_TraceLine, "fwd_TraceLine_Post", 1)
	g_iCmdStart = register_forward(FM_CmdStart, "fwd_CmdStart")
}

public client_putinserver(id)
{
	BugsyAddFlag(bs_IsConnected, id);
	set_cvars(id)
	
	set_task(RANGE_INTERVAL, "range_check", id+TASK_RANGE, _, _, "b")
	
	if (is_user_bot(id))
	{
		BugsyAddFlag(bs_IsBot, id);
		BugsyAddFlag(bs_InButton, id);
		
		if(!g_bHamCzBots && cvar_iBotQuota)
			set_task(0.1, "register_ham_czbots", id)
	}
	else
	{
		set_task(SPEC_INTERVAL, "spec_check", id+TASK_SPECTATOR, _, _, "b")
	}
}

public client_disconnect(id)
{
	BugsyRemoveFlag(bs_IsConnected, id);
	set_cvars(id)
	remove_task(id+TASK_RANGE)
	remove_task(id+TASK_SPECTATOR)
}

/*================================================================================
 [Main Events]
=================================================================================*/

public event_round_start()
{
	if (g_iZombieMod)
		g_bPreparation = true
	else
	{
		remove_task(TASK_DURATION)
		
		if (get_pcvar_float(cvar_flSemiClipDuration) > 0.0)
		{
			set_pcvar_num(cvar_iSemiClip, 1)
			g_iCachedSemiClip = 1
			g_bPreparation = true
			
			set_task(get_pcvar_float(cvar_flSemiClipDuration), "duration_disable_plugin", TASK_DURATION)
		}
	}
}

/*================================================================================
 [Supporting Forwards]
=================================================================================*/

forward zp_round_started(gamemode, id)
public zp_round_started(gamemode, id)
{
	g_bPreparation = false
}

forward event_gamestart()
public event_gamestart()
{
	g_bPreparation = false
}

/*================================================================================
 [Main Forwards]
=================================================================================*/

public fwd_PlayerSpawn_Post(id)
{
	if (!is_user_alive(id) || !g_iTeam[id])
		return
	
	BugsyAddFlag(bs_IsAlive, id);
	remove_task(id+TASK_SPECTATOR)
	
	if (g_iMod != MOD_CSTRIKE)
		g_iTeam[id] = get_user_team(id)
}

public fwd_PlayerKilled(id)
{
	BugsyRemoveFlag(bs_IsAlive, id);
	BugsyRemoveFlag(bs_InSemiClip, id);
	g_iTeam[id] = 3
	
	if (!BugsyCheckFlag(bs_IsBot, id))
		set_task(SPEC_INTERVAL, "spec_check", id+TASK_SPECTATOR, _, _, "b")
}

public fwd_Player_PreThink_Post(id)
{
	if (!g_iCachedSemiClip || !BugsyCheckFlag(bs_IsAlive, id))
		return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, i) || !BugsyCheckFlag(bs_IsAlive, i)) continue
		
		if (!BugsyCheckFlag(bs_InSemiClip, i)) BugsyAddFlag(bs_IsSolid, i);
		else BugsyRemoveFlag(bs_IsSolid, i);
	}
	
	if (BugsyCheckFlag(bs_IsSolid, id))
		for (i = 1; i <= g_iMaxPlayers; i++)
		{
			if (!BugsyCheckFlag(bs_IsConnected, i) || !BugsyCheckFlag(bs_IsAlive, i) || !BugsyCheckFlag(bs_IsSolid, i)) continue
			if (g_bPreparation)
			{
				if (g_iRange[id][i] == MAX_RENDER_AMOUNT || i == id) continue
				
				set_pev(i, pev_solid, SOLID_NOT)
				BugsyAddFlag(bs_InSemiClip, i);
			}
			else
			{
				if (g_iRange[id][i] == MAX_RENDER_AMOUNT || i == id) continue
				
				switch (g_iCachedButton)
				{
					case 3: // both
					{
						if (BugsyCheckFlag(bs_InButton, id))
						{
							if (!g_iCachedEnemies && !is_same_team(i, id)) continue
						}
						else if (query_enemies(id, i)) continue
					}
					case 1, 2: // CT/Axis or Terror/Allies
					{
						if (BugsyCheckFlag(bs_InButton, id) && g_iCachedButton == g_iTeam[id] && g_iCachedButton == g_iTeam[i])
						{
							if (g_iCachedEnemies && !is_same_team(i, id)) continue
						}
						else if (query_enemies(id, i)) continue
					}
					default: if (query_enemies(id, i)) continue;
				}
				
				set_pev(i, pev_solid, SOLID_NOT)
				BugsyAddFlag(bs_InSemiClip, i);
			}
		}
	
	return FMRES_IGNORED
}

public fwd_Player_PostThink(id)
{
	if (!g_iCachedSemiClip || !BugsyCheckFlag(bs_IsAlive, id))
		return FMRES_IGNORED
	
	static i
	for (i = 1; i <= g_iMaxPlayers; i++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, i) || !BugsyCheckFlag(bs_IsAlive, i)) continue
		
		if (BugsyCheckFlag(bs_InSemiClip, i))
		{
			set_pev(i, pev_solid, SOLID_SLIDEBOX)
			BugsyRemoveFlag(bs_InSemiClip, i);
		}
	}
	
	return FMRES_IGNORED
}

// (struct entity_state_s *state, int e, edict_t *ent, edict_t *host, int hostflags, int player, unsigned char *pSet)
public fwd_AddToFullPack_Post(es_handle, e, ent, host, flags, player, pSet)
{
	if (!g_iCachedSemiClip || !player)
		return FMRES_IGNORED
	
	if (g_iTeam[host] == 3)
	{
		if (BugsyCheckFlag(bs_IsBot, host) || !BugsyCheckFlag(bs_IsAlive, g_iSpectating[host]) || !BugsyCheckFlag(bs_IsAlive, ent)) return FMRES_IGNORED
		if (g_iRange[g_iSpectating[host]][ent] == MAX_RENDER_AMOUNT) return FMRES_IGNORED
		if (!g_iCachedFadeSpec && g_iSpectating[host] == ent) return FMRES_IGNORED
		if (g_bPreparation)
		{
			if (!g_iCachedRender) return FMRES_IGNORED
			
			if (BugsyCheckFlag(bs_IsSpecial, ent))
			{
				set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
				set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
				set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
				set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
			}
			else
			{
				set_es(es_handle, ES_RenderMode, g_iCachedMode)
				set_es(es_handle, ES_RenderAmt, g_iRange[g_iSpectating[host]][ent])
				set_es(es_handle, ES_RenderFx, g_iCachedFx)
				switch (g_iTeam[ent])
				{
					case 1: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam1);
					case 2: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam2);
				}
			}
			return FMRES_IGNORED
		}
		else
		{
			if (!g_iCachedRender) return FMRES_IGNORED
			
			switch (g_iCachedButton)
			{
				case 3: // both
				{
					if (BugsyCheckFlag(bs_InButton, g_iSpectating[host]))
					{
						if (!g_iCachedEnemies && !is_same_team(ent, g_iSpectating[host])) return FMRES_IGNORED
					}
					else if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED
				}
				case 1, 2: // CT/Axis or Terror/Allies
				{
					if (BugsyCheckFlag(bs_InButton, g_iSpectating[host]) && g_iCachedButton == g_iTeam[g_iSpectating[host]] && g_iCachedButton == g_iTeam[ent])
					{
						if (g_iCachedEnemies && !is_same_team(ent, g_iSpectating[host])) return FMRES_IGNORED
					}
					else if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED
				}
				default: if (query_enemies(g_iSpectating[host], ent)) return FMRES_IGNORED;
			}
			
			if (BugsyCheckFlag(bs_IsSpecial, ent))
			{
				set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
				set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
				set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
				set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
			}
			else
			{
				set_es(es_handle, ES_RenderMode, g_iCachedMode)
				set_es(es_handle, ES_RenderAmt, g_iRange[g_iSpectating[host]][ent])
				set_es(es_handle, ES_RenderFx, g_iCachedFx)
				switch (g_iTeam[ent])
				{
					case 1: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam1);
					case 2: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam2);
				}
			}
			return FMRES_IGNORED
		}
	}
	
	if (!BugsyCheckFlag(bs_IsAlive, host) || !BugsyCheckFlag(bs_IsAlive, ent) || !BugsyCheckFlag(bs_IsSolid, host) || !BugsyCheckFlag(bs_IsSolid, ent)) return FMRES_IGNORED
	if (g_iRange[host][ent] == MAX_RENDER_AMOUNT) return FMRES_IGNORED
	if (g_bPreparation)
	{
		set_es(es_handle, ES_Solid, SOLID_NOT)
		
		if (!g_iCachedRender) return FMRES_IGNORED
		
		if (BugsyCheckFlag(bs_IsSpecial, ent))
		{
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
		}
		else
		{
			set_es(es_handle, ES_RenderMode, g_iCachedMode)
			set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
			set_es(es_handle, ES_RenderFx, g_iCachedFx)
			switch (g_iTeam[ent])
			{
				case 1: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam1);
				case 2: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam2);
			}
		}
		return FMRES_IGNORED
	}
	else
	{
		switch (g_iCachedButton)
		{
			case 3: // both
			{
				if (BugsyCheckFlag(bs_InButton, host))
				{
					if (!g_iCachedEnemies && !is_same_team(ent, host)) return FMRES_IGNORED
				}
				else if (query_enemies(host, ent)) return FMRES_IGNORED
			}
			case 1, 2: // CT/Axis or Terror/Allies
			{
				if (BugsyCheckFlag(bs_InButton, host) && g_iCachedButton == g_iTeam[host] && g_iCachedButton == g_iTeam[ent])
				{
					if (g_iCachedEnemies && !is_same_team(ent, host)) return FMRES_IGNORED
				}
				else if (query_enemies(host, ent)) return FMRES_IGNORED
			}
			default: if (query_enemies(host, ent)) return FMRES_IGNORED;
		}
		
		set_es(es_handle, ES_Solid, SOLID_NOT)
		
		if (!g_iCachedRender) return FMRES_IGNORED
		
		if (BugsyCheckFlag(bs_IsSpecial, ent))
		{
			set_es(es_handle, ES_RenderMode, g_iRenderSpecial[ent][SPECIAL_MODE])
			set_es(es_handle, ES_RenderAmt, g_iRenderSpecial[ent][SPECIAL_AMT])
			set_es(es_handle, ES_RenderFx, g_iRenderSpecial[ent][SPECIAL_FX])
			set_es(es_handle, ES_RenderColor, g_iRenderSpecialColor[ent])
		}
		else
		{
			set_es(es_handle, ES_RenderMode, g_iCachedMode)
			set_es(es_handle, ES_RenderAmt, g_iRange[host][ent])
			set_es(es_handle, ES_RenderFx, g_iCachedFx)
			switch (g_iTeam[ent])
			{
				case 1: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam1);
				case 2: BugsyCheckFlag(bs_IsAdmin, ent) ? set_es(es_handle, ES_RenderColor, g_iCachedColorAdmin) : set_es(es_handle, ES_RenderColor, g_iCachedColorTeam2);
			}
		}
	}
	return FMRES_IGNORED
}

public fwd_TraceLine_Post(Float:vStart[3], Float:vEnd[3], noMonsters, id, trace)
{
	if (!g_iCachedSemiClip || !g_iCachedKnifeTrace || !is_user_valid_alive(id))
		return FMRES_IGNORED
	
	switch (g_iMod)
	{
		case MOD_CSTRIKE: if (g_iCurrentWeapon[id] != CSW_KNIFE) return FMRES_IGNORED;
		case MOD_DOD:
		{
			switch (g_iCurrentWeapon[id])
			{
				case DODW_AMERKNIFE, DODW_GERKNIFE, DODW_SPADE: { /*lets trace*/ }
				default: return FMRES_IGNORED;
			}
		}
		default: return FMRES_IGNORED;
	}
	
	new Float:flFraction
	get_tr2(trace, TR_flFraction, flFraction)
	if (flFraction >= 1.0)
		return FMRES_IGNORED
	
	new pHit = get_tr2(trace, TR_pHit)
	if (!is_user_valid_alive(pHit) || !is_same_team(id, pHit) || entity_range(id, pHit) > 48.0)
		return FMRES_IGNORED
	
	new	Float:start[3], Float:view_ofs[3], Float:direction[3], Float:tlStart[3], Float:tlEnd[3]
	
	pev(id, pev_origin, start)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(start, view_ofs, start)
	
	velocity_by_aim(id, 22, direction)
	xs_vec_add(direction, start, tlStart)
	velocity_by_aim(id, 48, direction)
	xs_vec_add(direction, start, tlEnd)
	
	engfunc(EngFunc_TraceLine, tlStart, tlEnd, noMonsters|DONT_IGNORE_MONSTERS, pHit, 0)
	
	new tHit = get_tr2(0, TR_pHit)
	if (!is_user_valid_alive(tHit) || is_same_team(id, tHit))
		return FMRES_IGNORED
	
	set_tr2(trace, TR_AllSolid, get_tr2(0, TR_AllSolid))
	set_tr2(trace, TR_StartSolid, get_tr2(0, TR_StartSolid))
	set_tr2(trace, TR_InOpen, get_tr2(0, TR_InOpen))
	set_tr2(trace, TR_InWater, get_tr2(0, TR_InWater))
	set_tr2(trace, TR_iHitgroup, get_tr2(0, TR_iHitgroup))
	set_tr2(trace, TR_pHit, tHit)
	
	return FMRES_IGNORED
}

public fwd_CmdStart(id, handle)
{
	if (!g_iCachedSemiClip || !g_iCachedButton || !BugsyCheckFlag(bs_IsAlive, id) || BugsyCheckFlag(bs_IsBot, id))
		return
	
	(get_uc(handle, UC_Buttons) & IN_USE) ? BugsyAddFlag(bs_InButton, id) : BugsyRemoveFlag(bs_InButton, id)
}

public fwd_Item_Deploy_Post(ent)
{
	switch (g_iMod)
	{
		case MOD_CSTRIKE: g_iCurrentWeapon[ham_cs_get_weapon_ent_owner(ent)] = fm_cs_get_weapon_id(ent);
		case MOD_DOD: g_iCurrentWeapon[ham_dod_get_weapon_ent_owner(ent)] = fm_dod_get_weapon_id(ent);
	}
	
	return HAM_IGNORED
}

/*================================================================================
 [Other Functions and Tasks]
=================================================================================*/

// credits to MeRcyLeZZ
public register_ham_czbots(id)
{
	if (g_bHamCzBots || !is_user_connected(id) || !get_pcvar_num(cvar_iBotQuota))
		return
	
	RegisterHamFromEntity(Ham_Spawn, id, "fwd_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_Killed, id, "fwd_PlayerKilled")
	RegisterHamFromEntity(Ham_Player_PreThink, id, "fwd_Player_PreThink_Post", 1)
	RegisterHamFromEntity(Ham_Player_PostThink, id, "fwd_Player_PostThink")
	
	g_bHamCzBots = true
	
	if (is_user_alive(id))
		fwd_PlayerSpawn_Post(id)
}

public cache_cvars()
{
	g_iCachedSemiClip = !!get_pcvar_num(cvar_iSemiClip)
	g_iCachedEnemies = !!get_pcvar_num(cvar_iSemiClipEnemies)
	g_iCachedBlockTeams = clamp(get_pcvar_num(cvar_iSemiClipBlockTeams), 0, 3)
	g_iCachedUnstuck = clamp(get_pcvar_num(cvar_iSemiClipUnstuck), 0, 3)
	g_flCachedUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiClipUnstuckDelay), 0.0, 3.0)
	g_iCachedButton = clamp(get_pcvar_num(cvar_iSemiClipButton), 0, 3)
	g_iCachedKnifeTrace = !!get_pcvar_num(cvar_iSemiClipKnifeTrace)
	
	g_iCachedRender = !!get_pcvar_num(cvar_iSemiClipRender)
	g_iCachedMode = clamp(get_pcvar_num(cvar_iSemiClipRenderMode), 0, 5)
	g_iCachedAmt = clamp(get_pcvar_num(cvar_iSemiClipRenderAmt), 0, 255)
	g_iCachedFx = clamp(get_pcvar_num(cvar_iSemiClipRenderFx), 0, 20)
	g_iCachedFade = !!get_pcvar_num(cvar_iSemiClipRenderFade)
	g_iCachedFadeMin = clamp(get_pcvar_num(cvar_iSemiClipRenderFadeMin), 0, SEMI_RENDER_AMOUNT)
	g_iCachedFadeSpec = !!get_pcvar_num(cvar_iSemiClipRenderFadeSpec)
	g_iCachedRadius = clamp(get_pcvar_num(cvar_iSemiClipRenderRadius), SEMI_RENDER_AMOUNT - g_iCachedFadeMin, 4095)
	
	static szFlags[24] ; get_pcvar_string(cvar_szSemiClipColorFlag, szFlags, charsmax(szFlags))	
	g_iCachedColorFlag = read_flags(szFlags)
	g_iCachedColorTeam1[0] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[0]), 0, 255)
	g_iCachedColorTeam1[1] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[1]), 0, 255)
	g_iCachedColorTeam1[2] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[2]), 0, 255)
	g_iCachedColorTeam2[0] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[0]), 0, 255)
	g_iCachedColorTeam2[1] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[1]), 0, 255)
	g_iCachedColorTeam2[2] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[2]), 0, 255)
	g_iCachedColorAdmin[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[0]), 0, 255)
	g_iCachedColorAdmin[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[1]), 0, 255)
	g_iCachedColorAdmin[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[2]), 0, 255)
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, id)) continue
		
		(get_user_flags(id) & g_iCachedColorFlag) ? BugsyAddFlag(bs_IsAdmin, id) : BugsyRemoveFlag(bs_IsAdmin, id)
	}
}

public cache_cvars_think(ent)
{
	if (!pev_valid(ent)) return;
	
	g_iCachedSemiClip = !!get_pcvar_num(cvar_iSemiClip)
	g_iCachedEnemies = !!get_pcvar_num(cvar_iSemiClipEnemies)
	g_iCachedBlockTeams = clamp(get_pcvar_num(cvar_iSemiClipBlockTeams), 0, 3)
	g_iCachedUnstuck = clamp(get_pcvar_num(cvar_iSemiClipUnstuck), 0, 3)
	g_flCachedUnstuckDelay = floatclamp(get_pcvar_float(cvar_flSemiClipUnstuckDelay), 0.0, 3.0)
	g_iCachedButton = clamp(get_pcvar_num(cvar_iSemiClipButton), 0, 3)
	g_iCachedKnifeTrace = !!get_pcvar_num(cvar_iSemiClipKnifeTrace)
	
	g_iCachedRender = !!get_pcvar_num(cvar_iSemiClipRender)
	g_iCachedMode = clamp(get_pcvar_num(cvar_iSemiClipRenderMode), 0, 5)
	g_iCachedAmt = clamp(get_pcvar_num(cvar_iSemiClipRenderAmt), 0, 255)
	g_iCachedFx = clamp(get_pcvar_num(cvar_iSemiClipRenderFx), 0, 20)
	g_iCachedFade = !!get_pcvar_num(cvar_iSemiClipRenderFade)
	g_iCachedFadeMin = clamp(get_pcvar_num(cvar_iSemiClipRenderFadeMin), 0, SEMI_RENDER_AMOUNT)
	g_iCachedFadeSpec = !!get_pcvar_num(cvar_iSemiClipRenderFadeSpec)
	g_iCachedRadius = clamp(get_pcvar_num(cvar_iSemiClipRenderRadius), SEMI_RENDER_AMOUNT - g_iCachedFadeMin, 4095)
	
	static szFlags[24] ; get_pcvar_string(cvar_szSemiClipColorFlag, szFlags, charsmax(szFlags))	
	g_iCachedColorFlag = read_flags(szFlags)
	g_iCachedColorTeam1[0] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[0]), 0, 255)
	g_iCachedColorTeam1[1] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[1]), 0, 255)
	g_iCachedColorTeam1[2] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam1[2]), 0, 255)
	g_iCachedColorTeam2[0] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[0]), 0, 255)
	g_iCachedColorTeam2[1] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[1]), 0, 255)
	g_iCachedColorTeam2[2] = clamp(get_pcvar_num(cvar_iSemiClipColorTeam2[2]), 0, 255)
	g_iCachedColorAdmin[0] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[0]), 0, 255)
	g_iCachedColorAdmin[1] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[1]), 0, 255)
	g_iCachedColorAdmin[2] = clamp(get_pcvar_num(cvar_iSemiClipColorAdmin[2]), 0, 255)
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, id)) continue
		
		(get_user_flags(id) & g_iCachedColorFlag) ? BugsyAddFlag(bs_IsAdmin, id) : BugsyRemoveFlag(bs_IsAdmin, id)
	}
	
	set_pev(ent, pev_nextthink, get_gametime() + 12.0)
}

public load_spawns()
{
	switch (g_iMod)
	{
		case MOD_CSTRIKE:
		{
			new cfgdir[32], mapname[32], filepath[100], linedata[64]
			get_configsdir(cfgdir, charsmax(cfgdir))
			get_mapname(mapname, charsmax(mapname))
			formatex(filepath, charsmax(filepath), "%s/csdm/%s.spawns.cfg", cfgdir, mapname)
			
			if (file_exists(filepath))
			{
				new csdmdata[10][6], file
				if ((file = fopen(filepath,"rt")) != 0)
				{
					while (!feof(file))
					{
						fgets(file, linedata, charsmax(linedata))
						
						if(!linedata[0] || str_count(linedata,' ') < 2) continue;
						
						parse(linedata,csdmdata[0],5,csdmdata[1],5,csdmdata[2],5,csdmdata[3],5,csdmdata[4],5,csdmdata[5],5,csdmdata[6],5,csdmdata[7],5,csdmdata[8],5,csdmdata[9],5)
						
						g_flSpawns3[g_iSpawnCount3][0] = floatstr(csdmdata[0])
						g_flSpawns3[g_iSpawnCount3][1] = floatstr(csdmdata[1])
						g_flSpawns3[g_iSpawnCount3][2] = floatstr(csdmdata[2])
						
						g_iSpawnCount3++
						if (g_iSpawnCount3 >= sizeof g_flSpawns3) break;
					}
					fclose(file)
				}
			}
			else if (g_iCachedUnstuck == 2)
			{
				set_pcvar_num(cvar_iSemiClipUnstuck, 1)
				g_iCachedUnstuck = 1
			}
			
			collect_spawns_ent("info_player_start") // CT
			collect_spawns_ent2("info_player_deathmatch") // TERRORIST
		}
		case MOD_DOD:
		{
			if (g_iCachedUnstuck == 2)
			{
				set_pcvar_num(cvar_iSemiClipUnstuck, 1)
				g_iCachedUnstuck = 1
			}
			
			collect_spawns_ent("info_player_axis") // AXIS
			collect_spawns_ent2("info_player_allies") // ALLIES
		}
		default:
		{
			if (g_iCachedUnstuck == 1 || g_iCachedUnstuck == 2)
			{
				set_pcvar_num(cvar_iSemiClipUnstuck, 0)
				g_iCachedUnstuck = 0
			}
		}
	}
}

public random_spawn_delay(id)
{
	do_random_spawn(id, g_iCachedUnstuck)
}

// credits to MeRcyLeZZ
do_random_spawn(id, mode)
{
	if (!BugsyCheckFlag(bs_IsConnected, id) || !BugsyCheckFlag(bs_IsAlive, id))
		return
	
	static hull, sp_index, i
	hull = (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN
	
	switch (mode)
	{
		case 1: // Specified team
		{
			switch (g_iTeam[id])
			{
				case 1: // TERRORIST - ALLIES
				{
					if (!g_iSpawnCount2)
						return
					
					sp_index = random_num(0, g_iSpawnCount2 - 1)
					for (i = sp_index + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCount2) i = 0
						
						if (is_hull_vacant(g_flSpawns2[i], hull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawns2[i])
							break
						}
						
						if (i == sp_index)
							break
					}
				}
				case 2: // CT - AXIS
				{
					if (!g_iSpawnCount)
						return
					
					sp_index = random_num(0, g_iSpawnCount - 1)
					for (i = sp_index + 1; /*no condition*/; i++)
					{
						if (i >= g_iSpawnCount) i = 0
						
						if (is_hull_vacant(g_flSpawns[i], hull))
						{
							engfunc(EngFunc_SetOrigin, id, g_flSpawns[i])
							break
						}
						
						if (i == sp_index)
							break
					}
				}
			}
		}
		case 2: // CSDM
		{
			if (!g_iSpawnCount3)
				return
			
			sp_index = random_num(0, g_iSpawnCount3 - 1)
			for (i = sp_index + 1; /*no condition*/; i++)
			{
				if (i >= g_iSpawnCount3) i = 0
				
				if (is_hull_vacant(g_flSpawns3[i], hull))
				{
					engfunc(EngFunc_SetOrigin, id, g_flSpawns3[i])
					break
				}
				
				if (i == sp_index)
					break
			}
		}
		case 3: // Random around own place
		{
			new Float:origin[3], Float:new_origin[3], Float:final[3], size
			pev(id, pev_origin, origin)
			size = sizeof(random_own_place)
			
			for (new test = 0; test < size; test++)
			{
				final[0] = new_origin[0] = (origin[0] + random_own_place[test][0])
				final[1] = new_origin[1] = (origin[1] + random_own_place[test][1])
				final[2] = new_origin[2] = (origin[2] + random_own_place[test][2])
				
				new z
				do
				{
					if (is_hull_vacant(final, hull))
					{
						test = size
						engfunc(EngFunc_SetOrigin, id, final)
						break
					}
					
					final[2] = new_origin[2] + (++z*20)
				}
				while (z < 5)
			}
		}
	}
}

public range_check(taskid)
{
	if (!g_iCachedSemiClip)
		return
	
	static id
	for (id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, id) || !BugsyCheckFlag(bs_IsAlive, id)) continue
		
		g_iRange[ID_RANGE][id] = calc_fade(ID_RANGE, id, g_iCachedFade)
	}
}

public spec_check(taskid)
{
	if (!g_iCachedSemiClip || BugsyCheckFlag(bs_IsAlive, ID_SPECTATOR))
		return
	
	static spec
	spec = pev(ID_SPECTATOR, PEV_SPEC_TARGET)
	
	if (BugsyCheckFlag(bs_IsAlive, spec))
	{
		g_iSpectating[ID_SPECTATOR] = spec
		g_iSpectatingTeam[ID_SPECTATOR] = g_iTeam[spec]
	}
}

public duration_disable_plugin()
{
	set_pcvar_num(cvar_iSemiClip, 0)
	g_iCachedSemiClip = 0
	g_bPreparation = false
	
	for (new id = 1; id <= g_iMaxPlayers; id++)
	{
		if (!BugsyCheckFlag(bs_IsConnected, id) || !BugsyCheckFlag(bs_IsAlive, id)) continue
		
		if (BugsyCheckFlag(bs_InSemiClip, id))
		{
			set_pev(id, pev_solid, SOLID_SLIDEBOX)
			BugsyRemoveFlag(bs_InSemiClip, id);
		}
		
		if (g_iCachedUnstuck && is_player_stuck(id))
			do_random_spawn(id, g_iCachedUnstuck)
	}
}

calc_fade(host, ent, mode)
{
	if (mode)
	{
		if (g_iCachedFadeMin > g_iCachedRadius)
			return MAX_RENDER_AMOUNT;
		
		new range = floatround(entity_range(host, ent))
		
		if (range >= g_iCachedRadius)
			return MAX_RENDER_AMOUNT;
		
		new amount
		amount = SEMI_RENDER_AMOUNT - g_iCachedFadeMin
		amount = g_iCachedRadius / amount
		amount = range / amount + g_iCachedFadeMin
		
		return amount;
	}
	else
	{
		new range = floatround(entity_range(host, ent))
		
		if (range < g_iCachedRadius)
			return g_iCachedAmt;
	}
	
	return MAX_RENDER_AMOUNT;
}

query_enemies(host, ent)
{
	if (g_iCachedBlockTeams == 3) return 1;
	
	switch (g_iCachedEnemies)
	{
		case 0: if (!is_same_team(ent, host) || g_iCachedBlockTeams == g_iTeam[ent]) return 1;
		case 1: if (g_iCachedBlockTeams == g_iTeam[ent] && is_same_team(ent, host)) return 1;
	}
	
	return 0;
}

set_cvars(id)
{
	BugsyRemoveFlag(bs_IsAlive, id);
	BugsyRemoveFlag(bs_IsBot, id);
	BugsyRemoveFlag(bs_IsSolid, id);
	BugsyRemoveFlag(bs_InSemiClip, id);
	BugsyRemoveFlag(bs_IsSpecial, id);
	g_iTeam[id] = 0
}

/*================================================================================
 [Message Hooks]
=================================================================================*/

/*
	TeamInfo:
	read_data(1)	byte	EventEntity
	read_data(2)	string	TeamName
	
	type |                   name |      calls | time     / min      / max
	   p |       message_TeamInfo |        629 | 0.000116 / 0.000000 / 0.000002
	
	fast enough!
*/
public message_TeamInfo(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL && msg_dest != MSG_BROADCAST)
		return
	
	static id, team[2]
	id = get_msg_arg_int(1)
	get_msg_arg_string(2, team, charsmax(team))
	
	switch (team[0])
	{
		case 'T': g_iTeam[id] = 1; // TERRORIST
		case 'C': g_iTeam[id] = 2; // CT
		case 'S': g_iTeam[id] = 3; // SPECTATOR
		default: g_iTeam[id] = 0;
	}
	
	if (g_iCachedUnstuck && BugsyCheckFlag(bs_IsAlive, id) && g_iCachedBlockTeams == g_iTeam[id])
	{
		if (!is_player_stuck(id))
			return
		
		if (g_flCachedUnstuckDelay > 0.0)
			set_task(g_flCachedUnstuckDelay, "random_spawn_delay", id)
		else
			do_random_spawn(id, g_iCachedUnstuck)
	}
}

/*
	PTeam:
	read_data(1)	byte	EventEntity
	read_data(2)	byte	TeamIndex
*/
public message_PTeam(msg_id, msg_dest)
{
	if (msg_dest != MSG_ALL) return
	
	static id
	id = get_msg_arg_int(1)
	g_iTeam[id] = get_msg_arg_int(2) // 0 - UNASSIGNED | 1 - ALLIES | 2 - AXIS | 3 - SPECTATOR
	
	if (g_iCachedUnstuck && BugsyCheckFlag(bs_IsAlive, id) && g_iCachedBlockTeams == g_iTeam[id])
	{
		if (!is_player_stuck(id))
			return
		
		if (g_flCachedUnstuckDelay > 0.0)
			set_task(g_flCachedUnstuckDelay, "random_spawn_delay", id)
		else
			do_random_spawn(id, g_iCachedUnstuck)
	}
}

/*================================================================================
 [Custom Natives]
=================================================================================*/

// tsc_set_rendering(id, special = 0, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
public native_set_rendering(id, special, fx, r, g, b, render, amount)
{
	if (!is_user_valid_connected(id))
	{
		log_error(AMX_ERR_NATIVE, "[Team Semiclip] Invalid Player (%d)", id)
		return -1;
	}
	
	switch (special)
	{
		case 0:
		{
			BugsyRemoveFlag(bs_IsSpecial, id)
			
			return 1;
		}
		case 1:
		{
			BugsyAddFlag(bs_IsSpecial, id)
			
			g_iRenderSpecial[id][SPECIAL_MODE] = render
			g_iRenderSpecial[id][SPECIAL_AMT] = amount
			g_iRenderSpecial[id][SPECIAL_FX] = fx
			
			g_iRenderSpecialColor[id][0] = r
			g_iRenderSpecialColor[id][1] = g
			g_iRenderSpecialColor[id][2] = b
			
			return 1;
		}
	}
	
	return 0;
}

/*================================================================================
 [Stocks]
=================================================================================*/

// credits to VEN
stock is_player_stuck(id)
{
	static Float:originF[3]
	pev(id, pev_origin, originF)
	
	engfunc(EngFunc_TraceHull, originF, originF, 0, (pev(id, pev_flags) & FL_DUCKING) ? HULL_HEAD : HULL_HUMAN, id, 0)
	
	if (get_tr2(0, TR_StartSolid) || get_tr2(0, TR_AllSolid) || !get_tr2(0, TR_InOpen))
		return true;
	
	return false;
}

// credits to VEN
stock is_hull_vacant(Float:origin[3], hull)
{
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true;
	
	return false;
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

// credits to MeRcyLeZZ
stock collect_spawns_ent(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_flSpawns[g_iSpawnCount][0] = originF[0]
		g_flSpawns[g_iSpawnCount][1] = originF[1]
		g_flSpawns[g_iSpawnCount][2] = originF[2]
		
		g_iSpawnCount++
		if (g_iSpawnCount >= sizeof g_flSpawns) break
	}
}

// credits to MeRcyLeZZ
stock collect_spawns_ent2(const classname[])
{
	new ent = -1
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", classname)) != 0)
	{
		new Float:originF[3]
		pev(ent, pev_origin, originF)
		g_flSpawns2[g_iSpawnCount2][0] = originF[0]
		g_flSpawns2[g_iSpawnCount2][1] = originF[1]
		g_flSpawns2[g_iSpawnCount2][2] = originF[2]
		
		g_iSpawnCount2++
		if (g_iSpawnCount2 >= sizeof g_flSpawns2) break
	}
}

// credits to Exolent[jNr]
stock fm_cs_get_weapon_id(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return 0;
	
	return get_pdata_int(ent, OFFSET_CS_WEAPONID, OFFSET_LINUX_WEAPONS);
}

// credits to me :D
stock fm_dod_get_weapon_id(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return 0;
	
	return get_pdata_int(ent, OFFSET_DOD_WEAPONID, OFFSET_LINUX_WEAPONS);
}

// credits to MeRcyLeZZ
stock ham_cs_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_CS_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// credits to me :D
stock ham_dod_get_weapon_ent_owner(ent)
{
	// Prevent server crash if entity's private data not initalized
	if (pev_valid(ent) != PDATA_SAFE)
		return -1;
	
	return get_pdata_cbase(ent, OFFSET_DOD_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// amxmisc.inc
stock get_configsdir(name[], len)
{
	return get_localinfo("amxx_configsdir", name, len);
}
