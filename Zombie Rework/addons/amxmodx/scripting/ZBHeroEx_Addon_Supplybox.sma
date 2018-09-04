#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <hamsandwich>
#include <fun>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEX] Addon: Supplybox"
#define VERSION "1.0"
#define AUTHOR "Dias Leon"

#define GAME_LANG LANG_SERVER
#define LANG_FILE "zombie_theheroex.txt"

#define SUPPLY_CLASSNAME "tasukete"
#define SUPPLYBOX_TEAM CS_TEAM_CT
#define TASK_SUPPLYBOX 61296

// Spawn Points
#define MAX_SPAWN_POINT 16
new Float:g_SpawnPoint[MAX_SPAWN_POINT][3], g_SpawnPoint_Count
new const SpawnPoint_URL[] = "%s/supplybox/%s.sb"

new const Ar2_S_SupplyModel[] = "models/zombie_thehero/supplybox.mdl"
new const Ar2_S_Supplybox_Drop[] = "zombie_thehero/supplybox_drop.wav"
new const Ar2_S_Supplybox_Pick[] = "zombie_thehero/supplybox_pickup.wav"
new const g_Supplybox_IconSpr[] = "sprites/zombie_thehero/supplybox_icon.spr"

new g_SupplyIcon
new g_SupplyBox_Count, g_RoundEnt[64], g_RoundEnt_Count, Float:g_PlayerIcon[33], Float:g_PlayerIcon2[33]
new Float:g_PlayerSpawn_Point[64][3], g_PlayerSpawn_Count, g_Supplybox_IconSprID
new g_Cvar_SupplyOn, g_Cvar_SupplyDropTime, g_Cvar_SupplyPer, g_Cvar_SupplyMax, g_Cvar_SupplyIcon
new g_Cvar_OriSource
new g_MsgHostageAdd, g_MsgHostageDel

// Random Origin Generator
#define SS_VERSION	"1.0"
#define SS_MIN_DISTANCE	500.0
#define SS_MAX_LOOPS	100000

new Array:g_vecSsOrigins
new Array:g_vecSsSpawns
new Array:g_vecSsUsed
new Float:g_flSsMinDist
new g_iSsTime

new const g_szStarts[][] = { "info_player_start", "info_player_deathmatch" }
new const Float:g_flOffsets[] = { 3500.0, 3500.0, 1500.0 }

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_FILE)
	
	// R.O.G
	ROG_SsInit(3500.0);
	ROG_SsScan(); 
	ROG_SsDump();
	
	register_touch(SUPPLY_CLASSNAME, "player", "fw_SupplyTouch")
	
	// Collect Spawns Point
	collect_spawns_ent("info_player_start")
	collect_spawns_ent("info_player_deathmatch")
	
	// Supplybox
	g_Cvar_OriSource = register_cvar("zl_supplybox_origin", "0") // 0 - Player SPawn | 1 -Auto Detect | 2 - Select Point
	g_Cvar_SupplyOn = register_cvar("zl_supplybox_enable", "1")
	g_Cvar_SupplyDropTime = register_cvar("zl_supplybox_droptime", "30")
	g_Cvar_SupplyPer = register_cvar("zl_supplybox_droponce", "3")
	g_Cvar_SupplyMax = register_cvar("zl_supplybox_max", "5")
	g_Cvar_SupplyIcon = register_cvar("zl_supplybox_icon", "1")
	
	// MSG
	g_MsgHostageAdd = get_user_msgid("HostagePos")
	g_MsgHostageDel = get_user_msgid("HostageK")
	
	register_clcmd("SB_Panel", "Open_SpawnMenu", ADMIN_ADMIN)
}

public plugin_precache()
{
	Load_SpawnPoint()
	
	precache_model(Ar2_S_SupplyModel)
	precache_sound(Ar2_S_Supplybox_Drop)
	precache_sound(Ar2_S_Supplybox_Pick)
	
	g_Supplybox_IconSprID = precache_model(g_Supplybox_IconSpr)
}

public zbheroex_round_new() 
{
	remove_task(TASK_SUPPLYBOX)
	remove_entity_name(SUPPLY_CLASSNAME)
	g_SupplyIcon = get_pcvar_num(g_Cvar_SupplyIcon)
}

public zbheroex_game_start()
{
	remove_task(TASK_SUPPLYBOX)
	set_task(get_pcvar_float(g_Cvar_SupplyDropTime), "SupplyBox_Drop", TASK_SUPPLYBOX, _, _, "b")
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
	{
		if(g_SupplyIcon)
		{
			if((g_PlayerIcon[id] + 0.05) < get_gametime())
			{
				if(g_SupplyBox_Count)
				{
					for(new i = 0; i < g_RoundEnt_Count; i++)
						Show_OriginIcon(id, g_RoundEnt[i], g_Supplybox_IconSprID)
				}
				
				g_PlayerIcon[id] = get_gametime()
			}
			
			if(get_gametime() - 1.0 > g_PlayerIcon2[id])
			{
				if(g_SupplyBox_Count)
				{
					static i, Next; i = 1; Next = 0
					while(i <= g_RoundEnt_Count)
					{
						Next = g_RoundEnt[i]
						if(pev_valid(Next))
						{
							static Float:Origin[3]
							pev(Next, pev_origin, Origin)
							
							message_begin(MSG_ONE_UNRELIABLE, g_MsgHostageAdd, {0,0,0}, id)
							write_byte(id)
							write_byte(i)		
							write_coord(FloatToNum(Origin[0]))
							write_coord(FloatToNum(Origin[1]))
							write_coord(FloatToNum(Origin[2]))
							message_end()
						
							message_begin(MSG_ONE_UNRELIABLE, g_MsgHostageDel, {0,0,0}, id)
							write_byte(i)
							message_end()
						}
					
						i++
					}
	
				}
				
				g_PlayerIcon2[id] = get_gametime()
			}
		}
	}
}

public Show_OriginIcon(id, Ent, SpriteID) // By sontung0
{
	if (!pev_valid(Ent)) 
		return
	
	static Float:fMyOrigin[3]; pev(id, pev_origin, fMyOrigin)
	
	static Target; Target = Ent
	static Float:fTargetOrigin[3]; pev(Target, pev_origin, fTargetOrigin)
	fTargetOrigin[2] += 40.0
	
	if(!is_in_viewcone(id, fTargetOrigin)) 
		return

	static Float:fMiddle[3], Float:fHitPoint[3]
	xs_vec_sub(fTargetOrigin, fMyOrigin, fMiddle)
	trace_line(-1, fMyOrigin, fTargetOrigin, fHitPoint)
							
	static Float:fWallOffset[3], Float:fDistanceToWall
	fDistanceToWall = vector_distance(fMyOrigin, fHitPoint) - 10.0
	normalize(fMiddle, fWallOffset, fDistanceToWall)
	
	static Float:fSpriteOffset[3]; xs_vec_add(fWallOffset, fMyOrigin, fSpriteOffset)
	static Float:fScale; fScale = 0.01 * fDistanceToWall
	
	static scale; scale = floatround(fScale)
	scale = max(scale, 1)
	scale = min(scale, 2) // SIZE = 2
	scale = max(scale, 1)

	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, id)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, fSpriteOffset[0])
	engfunc(EngFunc_WriteCoord, fSpriteOffset[1])
	engfunc(EngFunc_WriteCoord, fSpriteOffset[2])
	write_short(SpriteID)
	write_byte(scale) 
	write_byte(250)
	message_end()
}

public SupplyBox_Drop()
{
	if(!get_pcvar_num(g_Cvar_SupplyOn))
	{
		remove_task(TASK_SUPPLYBOX)
		return
	}
	
	for(new i = 0; i < get_pcvar_num(g_Cvar_SupplyPer); i++)
	{
		if(g_SupplyBox_Count >= get_pcvar_num(g_Cvar_SupplyMax))
			return
		
		SupplyBox_Create()
	}
	
	// Play Sound
	for(new id = 0; id < get_maxplayers(); id++)
	{
		if(!is_user_alive(id))
			continue
		if(!(cs_get_user_team(id) & SUPPLYBOX_TEAM))
			continue
			
		PlaySound(id, Ar2_S_Supplybox_Drop)
		client_print(id, print_center, "Supplies have been dropped!")
	}
}

public SupplyBox_Create()
{
	static Float:Origin[3]

	switch(get_pcvar_num(g_Cvar_OriSource))
	{
		case 1:
		{
			if(ROG_SsGetOrigin(Origin))
			{
				static Supply; Supply = create_entity("info_target")
				
				set_pev(Supply, pev_classname, SUPPLY_CLASSNAME)
				engfunc(EngFunc_SetModel, Supply, Ar2_S_SupplyModel)
			
				engfunc(EngFunc_SetSize, Supply, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,6.0})
				
				set_pev(Supply, pev_solid, SOLID_TRIGGER)
				set_pev(Supply, pev_movetype, MOVETYPE_TOSS)
			
				Origin[2] += 8.0
				engfunc(EngFunc_SetOrigin, Supply, Origin)
				
				g_SupplyBox_Count++
				g_RoundEnt[g_RoundEnt_Count] = Supply
				g_RoundEnt_Count++
			}
		}
		case 2:
		{
			static Supply; Supply = create_entity("info_target")
			
			set_pev(Supply, pev_classname, SUPPLY_CLASSNAME)
			engfunc(EngFunc_SetModel, Supply, Ar2_S_SupplyModel)
		
			engfunc(EngFunc_SetSize, Supply, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,6.0})
			
			set_pev(Supply, pev_solid, SOLID_TRIGGER)
			set_pev(Supply, pev_movetype, MOVETYPE_TOSS)
		
			static RETURN; RETURN = Do_Random_Spawn(Supply)
			if(!RETURN)
			{
				remove_entity(Supply)
				return
			}
		
			pev(Supply, pev_origin, Origin)
			Origin[2] += 8.0
			engfunc(EngFunc_SetOrigin, Supply, Origin)
			
			g_SupplyBox_Count++
			g_RoundEnt[g_RoundEnt_Count] = Supply
			g_RoundEnt_Count++
		}
		default:
		{
			static Supply; Supply = create_entity("info_target")
			
			set_pev(Supply, pev_classname, SUPPLY_CLASSNAME)
			engfunc(EngFunc_SetModel, Supply, Ar2_S_SupplyModel)
		
			engfunc(EngFunc_SetSize, Supply, Float:{-10.0,-10.0,0.0}, Float:{10.0,10.0,6.0})
			
			set_pev(Supply, pev_solid, SOLID_TRIGGER)
			set_pev(Supply, pev_movetype, MOVETYPE_TOSS)
		
			Origin[2] += 8.0
			engfunc(EngFunc_SetOrigin, Supply, Origin)
			
			g_SupplyBox_Count++
			g_RoundEnt[g_RoundEnt_Count] = Supply
			g_RoundEnt_Count++
			
			Ent_SpawnRandom(Supply)
		}
	}
}

public Ent_SpawnRandom(id)
{
	if (!g_PlayerSpawn_Count)
		return;	
	
	static hull, sp_index, i
	
	hull = HULL_HUMAN
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

public fw_SupplyTouch(Ent, id)
{
	if(!pev_valid(Ent))
		return
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
		
	// Effect & Sound
	emit_sound(id, CHAN_ITEM, Ar2_S_Supplybox_Pick, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	SupplyBox_GiveItem(id)
		
	for(new i = 0; i < g_RoundEnt_Count; i++)
	{
		if(g_RoundEnt[i] == Ent)
			g_RoundEnt[i] = -1
	}
		
	g_SupplyBox_Count--
	set_pev(Ent, pev_flags, FL_KILLME)
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01)
}

public SupplyBox_GiveItem(id)
{
	if(!cs_get_user_bpammo(id, CSW_HEGRENADE)) fm_give_item(id, "weapon_hegrenade")
	if(!cs_get_user_bpammo(id, CSW_FLASHBANG)) fm_give_item(id, "weapon_flashbang")
	if(!cs_get_user_bpammo(id, CSW_SMOKEGRENADE)) fm_give_item(id, "weapon_smokegrenade")
	
	cs_set_user_bpammo(id, get_user_weapon(id), 255)
}

stock normalize(Float:fIn[3], Float:fOut[3], Float:fMul) // By sontung0
{
	static Float:fLen; fLen = xs_vec_len(fIn)
	xs_vec_copy(fIn, fOut)
	
	fOut[0] /= fLen, fOut[1] /= fLen, fOut[2] /= fLen
	fOut[0] *= fMul, fOut[1] *= fMul, fOut[2] *= fMul
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

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock is_hull_vacant(Float:Origin[3], hull)
{
	engfunc(EngFunc_TraceHull, Origin, Origin, 0, hull, 0, 0)
	
	if (!get_tr2(0, TR_StartSolid) && !get_tr2(0, TR_AllSolid) && get_tr2(0, TR_InOpen))
		return true
	
	return false
}

stock FloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}

// =========================== Random Origin Generator =============================
// =================================================================================
public ROG_SsInit(Float:mindist)
{
	new cmd[32]
	format(cmd, 15, "_ss_dump%c%c%c%c", random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z'), random_num('A', 'Z'))
	register_cvar("sv_rog", SS_VERSION, (FCVAR_SERVER|FCVAR_SPONLY))
	register_concmd(cmd, "ROG_SsDump")

	g_flSsMinDist = mindist
	g_vecSsOrigins = ArrayCreate(3, 1)
	g_vecSsSpawns = ArrayCreate(3, 1)
	g_vecSsUsed = ArrayCreate(3, 1)
}

stock ROG_SsClean()
{
	g_flSsMinDist = 0.0
	ArrayClear(g_vecSsOrigins)
	ArrayClear(g_vecSsSpawns)
	ArrayClear(g_vecSsUsed)
}

stock ROG_SsGetOrigin(Float:origin[3])
{
	new Float:data[3], size
	new ok = 1

	while((size = ArraySize(g_vecSsOrigins)))
	{
		new idx = random_num(0, size - 1)

		ArrayGetArray(g_vecSsOrigins, idx, origin)

		new used = ArraySize(g_vecSsUsed)
		for(new i = 0; i < used; i++)
		{
			ok = 0
			ArrayGetArray(g_vecSsUsed, i, data)
			if(get_distance_f(data, origin) >= g_flSsMinDist)
			{
				ok = 1
				break
			}
		}

		ArrayDeleteItem(g_vecSsOrigins, idx)
		if(ok)
		{
			ArrayPushArray(g_vecSsUsed, origin)
			return true
		}
	}
	return false
}

public ROG_SsDump()
{
	new count = ArraySize(g_vecSsOrigins)
	server_print("Thanatos System: Found %i Origin(s)!", count)
	server_print("Thanatos System: Scanning Time %i", g_iSsTime)
}

public ROG_SsScan()
{
	new start, Float:origin[3], starttime
	starttime = get_systime()
	for(start = 0; start < sizeof(g_szStarts); start++)
	{
		server_print("Thanatos System: Searching for %s", g_szStarts[start])
		new ent
		if((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", g_szStarts[start])))
		{
			new counter
			pev(ent, pev_origin, origin)
			ArrayPushArray(g_vecSsSpawns, origin)
			while(counter < SS_MAX_LOOPS)
			{
				counter = ROG_GetLocation(origin, counter)
			}
		}
	}
	g_iSsTime = get_systime()
	g_iSsTime -= starttime
}

ROG_GetLocation(Float:start[3], &counter)
{
	new Float:end[3]
	for(new i = 0; i < 3; i++)
	{
		end[i] += random_float(0.0 - g_flOffsets[i], g_flOffsets[i])
	}

	if(ROG_IsValid(start, end))
	{
		start[0] = end[0]
		start[1] = end[1]
		start[2] = end[2]
		ArrayPushArray(g_vecSsOrigins, end)
	}
	counter++
	return counter
}

ROG_IsValid(Float:start[3], Float:end[3])
{
	ROG_SetFloor(end)
	end[2] += 36.0
	new point = engfunc(EngFunc_PointContents, end)
	if(point == CONTENTS_EMPTY)
	{
		if(ROG_CheckPoints(end) && ROG_CheckDistance(end) && ROG_CheckVisibility(start, end))
		{
			if(!trace_hull(end, HULL_LARGE, -1))
			{
				return true
			}
		}
	}
	return false
}

ROG_CheckVisibility(Float:start[3], Float:end[3])
{
	new tr
	engfunc(EngFunc_TraceLine, start, end, IGNORE_GLASS, -1, tr)
	return (get_tr2(tr, TR_pHit) < 0)
}

ROG_SetFloor(Float:start[3])
{
	new tr, Float:end[3]
	end[0] = start[0]
	end[1] = start[1]
	end[2] = -99999.9
	engfunc(EngFunc_TraceLine, start, end, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, start)
}

ROG_CheckPoints(Float:origin[3])
{
	new Float:data[3], tr, point
	data[0] = origin[0]
	data[1] = origin[1]
	data[2] = 99999.9
	engfunc(EngFunc_TraceLine, origin, data, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, data)
	point = engfunc(EngFunc_PointContents, data)
	if(point == CONTENTS_SKY && get_distance_f(origin, data) < 250.0)
	{
		return false
	}
	data[2] = -99999.9
	engfunc(EngFunc_TraceLine, origin, data, DONT_IGNORE_MONSTERS, -1, tr)
	get_tr2(tr, TR_vecEndPos, data)
	point = engfunc(EngFunc_PointContents, data)
	if(point < CONTENTS_SOLID)
		return false
	
	return true
}

ROG_CheckDistance(Float:origin[3])
{
	new Float:dist, Float:data[3]
	new count = ArraySize(g_vecSsSpawns)
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_vecSsSpawns, i, data)
		dist = get_distance_f(origin, data)
		if(dist < SS_MIN_DISTANCE)
			return false
	}

	count = ArraySize(g_vecSsOrigins)
	for(new i = 0; i < count; i++)
	{
		ArrayGetArray(g_vecSsOrigins, i, data)
		dist = get_distance_f(origin, data)
		if(dist < SS_MIN_DISTANCE)
			return false
	}

	return true
}


// =================== Make SpawnPoint =========================
// =============================================================
public Do_Random_Spawn(id)
{
	if (!g_SpawnPoint_Count)
		return 0	
	
	//static Spawn; Spawn = random_num(0, g_SpawnPoint_Count - 1)
	//engfunc(EngFunc_SetOrigin, id, g_SpawnPoint[Spawn])

	static sp_index, i, Float:Origin[3], Yes; Yes = 0
	sp_index = random_num(0, g_SpawnPoint_Count - 1)
	
	for (i = sp_index + 1; /*no condition*/; i++)
	{
		if(i >= g_SpawnPoint_Count) i = 0
		Origin = g_SpawnPoint[i]
	
		Origin[2] += 36.0
		
		if(is_hull_vacant(Origin, HULL_HUMAN))
		{
			engfunc(EngFunc_SetOrigin, id, Origin)
			Yes = 1
			break
		}

		if (i == sp_index) break
	}
	
	
	return Yes
}

public Open_SpawnMenu(id)
{
	if(!is_user_connected(id))
		return
		
	// create menu
	static Menu; Menu = menu_create("[Supplybox] Spawn Point", "MenuHandle_ZSConfig")
	
	menu_additem(Menu, "Add", "Add", 0)
	menu_additem(Menu, "Save", "Save", 0)
	
	menu_display(id, Menu, 0)
}

public MenuHandle_ZSConfig(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	
	static itemid[32], itemname[32], Access
	menu_item_getinfo(Menu, Item, Access, itemid, charsmax(itemid), itemname, charsmax(itemname), Access)
	
	if(equal(itemid, "Add"))
	{
		if(g_SpawnPoint_Count >= MAX_SPAWN_POINT)
		{
			client_print(id, print_chat, "[RZ] Error: Max Trader Point")
			Open_SpawnMenu(id)
			return;
		}
		
		static Float:Origin[3]; pev(id, pev_origin, Origin)
		
		g_SpawnPoint[g_SpawnPoint_Count] = Origin
		g_SpawnPoint_Count++
		
		client_print(id, print_chat, "[RL] Notice: Added !!!")
	} else if (equal(itemid, "Save")) {
		if (!g_SpawnPoint_Count)
		{
			client_print(id, print_chat, "[RL] Error: There is no SpawnPoint")
			Open_SpawnMenu(id)
			return;
		}
	
		// get url file
		static cfgdir[32], mapname[32], urlfile[128]
		
		get_configsdir(cfgdir, charsmax(cfgdir))
		get_mapname(mapname, charsmax(mapname))
		formatex(urlfile, charsmax(urlfile), SpawnPoint_URL, cfgdir, mapname)
	
		// save file
		if(file_exists(urlfile)) delete_file(urlfile)
		static lineset[128]
		
		for(new i = 0; i < g_SpawnPoint_Count; i++)
		{
			if(!g_SpawnPoint[i][0] && !g_SpawnPoint[i][1] && !g_SpawnPoint[i][2]) break;
			
			format(lineset, charsmax(lineset), "%f %f %f", g_SpawnPoint[i][0], g_SpawnPoint[i][1], g_SpawnPoint[i][2])
			write_file(urlfile, lineset, i)
		}
		
		client_print(id, print_chat, "[RL] Notice: Saved !!!")
	}
	
	// show main menu
	Open_SpawnMenu(id)
}

public Load_SpawnPoint()
{
	// Check for spawns points of the current map
	static cfgdir[32], mapname[32], filepath[100], linedata[64], Float:point[3]
	get_configsdir(cfgdir, charsmax(cfgdir))
	get_mapname(mapname, charsmax(mapname))
	formatex(filepath, charsmax(filepath), SpawnPoint_URL, cfgdir, mapname)
	
	// check file exit
	if (!file_exists(filepath))
	{
		server_print("[RL] Warning: Spawn File Not Found (%s)...", filepath)
		return;
	}
	
	g_SpawnPoint_Count = 0
	
	// Load spawns points
	static file, row[3][6]; file = fopen(filepath,"rt")
	while (file && !feof(file))
	{
		fgets(file, linedata, charsmax(linedata))
		
		// invalid spawn
		if(!linedata[0] || str_count(linedata,' ') < 2) continue;
		
		// get spawn point data
		parse(linedata,row[0],5,row[1],5,row[2])
		
		// set spawnst
		point[0] = str_to_float(row[0])
		point[1] = str_to_float(row[1])
		point[2] = str_to_float(row[2])
		
		if(is_point(point))
		{
			g_SpawnPoint[g_SpawnPoint_Count][0] = point[0]
			g_SpawnPoint[g_SpawnPoint_Count][1] = point[1]
			g_SpawnPoint[g_SpawnPoint_Count][2] = point[2]

			// increase spawn count
			g_SpawnPoint_Count ++
			
			if(g_SpawnPoint_Count >= MAX_SPAWN_POINT) break;
		}
	}
	if (file) fclose(file)
}

str_count(const str[], searchchar)
{
	new count, i, len = strlen(str)
	
	for (i = 0; i <= len; i++)
	{
		if(str[i] == searchchar)
			count++
	}
	
	return count;
}

is_point(Float:point[3])
{
	if (!point[0] && !point[1] && !point[2]) return 0
	return 1
}

stock get_can_see(Float:start[3], Float:end[3])
{
	static ptr; ptr = create_tr2()
	engfunc(EngFunc_TraceLine, start, end, IGNORE_GLASS | IGNORE_MONSTERS | IGNORE_MISSILE, -1, ptr)
	    
	static fraction
	get_tr2(ptr, TR_flFraction, fraction)
	    
	// Free the trace handle (don't forget to do this!)
	free_tr2(ptr)
	    
	// If = 1.0 then it didn't hit anything!
	return (fraction != 1.0) 
}
