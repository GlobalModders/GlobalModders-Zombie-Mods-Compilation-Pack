#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <hamsandwich>
#include <GhostFury>

#define PLUGIN "[GF] Addon: Human Radar Scanner"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define SCAN_LOOP 2.0
new Float:ScanTime[33], g_MaxPlayers, g_msgHostageAdd, g_msgHostageDel

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Safety
new g_IsConnected, g_IsAlive, g_PlayerWeapon[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	Register_SafetyFunc()
	
	g_msgHostageAdd = get_user_msgid("HostagePos")
	g_msgHostageDel = get_user_msgid("HostageK")
	g_MaxPlayers = get_maxplayers()
}

public client_putinserver(id)
{
	Safety_Connected(id)
}

public client_disconnect(id)
{
	Safety_Disconnected(id)
}

public client_PostThink(id)
{
	if(!is_alive(id))
		return
	if(!gf_get_user_ghost(id))
		return
		
	if(get_gametime() - SCAN_LOOP > ScanTime[id])
	{
		static PlayerOrigin[3];
		
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_alive(i))
				continue
			if(gf_get_user_ghost(i))
				continue
				
			get_user_origin(i, PlayerOrigin)
			
			message_begin(MSG_ONE_UNRELIABLE, g_msgHostageAdd, {0,0,0}, id)
			write_byte(id)
			write_byte(i)		
			write_coord(PlayerOrigin[0])
			write_coord(PlayerOrigin[1])
			write_coord(PlayerOrigin[2])
			message_end()
		
			message_begin(MSG_ONE_UNRELIABLE, g_msgHostageDel, {0,0,0}, id)
			write_byte(i)
			message_end()
		}
		
		ScanTime[id] = get_gametime()
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

public is_alive(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
		return 0
	if(!Get_BitVar(g_IsAlive, id)) 
		return 0
		
	return 1
}

public is_connected(id)
{
	if(!(1 <= id <= 32))
		return 0
	if(!Get_BitVar(g_IsConnected, id))
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
--------- End of SAFETY ----------
=================================*/
