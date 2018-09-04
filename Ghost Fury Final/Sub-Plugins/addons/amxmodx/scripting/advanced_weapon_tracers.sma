/*	Formatright © 2009, ConnorMcLeod

	TraceAttack is free software;
	you can redistribute it and/or modify it under the terms of the
	GNU General Public License as published by the Free Software Foundation.

	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with TraceAttack; if not, write to the
	Free Software Foundation, Inc., 59 Temple Place - Suite 330,
	Boston, MA 02111-1307, USA.
*/

/************** CUSTOMIZATION AREA ***************/

#define TMP_IS_A_SILENCED_WEAPON
//#define PER_PLAYER_SETTINGS

/*********** END OF CUSTOMIZATION AREA ***********/

#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>

#define VERSION "1.3.0"

#define MAX_PLAYERS	32
#define IsPlayer(%1)	( 1 <= %1 <= g_iMaxPlayers )
#define write_coord_f(%1)	engfunc(EngFunc_WriteCoord,%1) 

#define m_pActiveItem	373

const GUNS_BITSUM  = ((1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE))
const SHOTGUNS_BITSUM = ((1<<CSW_XM1014)|(1<<CSW_M3))
const SMGS_BITSUM  = ((1<<CSW_MAC10)|(1<<CSW_UMP45)|(1<<CSW_MP5NAVY)|(1<<CSW_TMP)|(1<<CSW_P90))
const RIFFLES_BITSUM  = ((1<<CSW_AUG)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_M249)|(1<<CSW_M4A1)|(1<<CSW_SG552)|(1<<CSW_AK47))
const SNIPERS_BITSUM  = ((1<<CSW_SCOUT)|(1<<CSW_SG550)|(1<<CSW_AWP)|(1<<CSW_G3SG1))

const SILEN_BITSUM	= ((1<<CSW_USP)|(1<<CSW_M4A1))

enum _:PcvarsNum {
	HandGuns = 0,
	ShotGuns,
	SmgGuns,
	RiffleGuns,
	SnipeGuns
}

new const g_iWeaponBitSumList[] = { GUNS_BITSUM , SHOTGUNS_BITSUM , SMGS_BITSUM , RIFFLES_BITSUM , SNIPERS_BITSUM }

new g_iMaxPlayers
new Trie:g_tClassNames

new g_pCvar[PcvarsNum], g_pCvarTraceEnabled, g_pCvarTraceHideSilen

#if defined PER_PLAYER_SETTINGS
new g_bHltv[MAX_PLAYERS+1], g_bSeeTracers[MAX_PLAYERS+1]
new g_pCvarTraceHltv
#endif

public plugin_precache()
{
	g_tClassNames = TrieCreate()

	RegisterHam(Ham_TraceAttack, "worldspawn", "TraceAttack", 1)
	TrieSetCell(g_tClassNames, "worldspawn", 1)
	RegisterHam(Ham_TraceAttack, "player", "TraceAttack", 1)
	TrieSetCell(g_tClassNames, "player", 1)

	register_forward(FM_Spawn, "Spawn", 1)
}

public Spawn( iEnt )
{
	if( pev_valid(iEnt) )
	{
		static szClassName[32]
		pev(iEnt, pev_classname, szClassName, charsmax(szClassName))
		if( !TrieKeyExists(g_tClassNames, szClassName) )
		{
			RegisterHam(Ham_TraceAttack, szClassName, "TraceAttack", 1)
			TrieSetCell(g_tClassNames, szClassName, 1)
		}
	}
}

public plugin_end()
{
	TrieDestroy(g_tClassNames)
}

public plugin_init()
{
	register_plugin("Advanced Weapon Tracers", VERSION, "ConnorMcLeod")
	register_cvar("awt_version", VERSION, FCVAR_SERVER|FCVAR_EXTDLL|FCVAR_SPONLY)

	g_pCvarTraceEnabled = register_cvar("amx_tracers", "1")

	g_pCvar[HandGuns] = register_cvar("amx_trace_handguns", "1")
	g_pCvar[ShotGuns] = register_cvar("amx_trace_shotguns", "1")
	g_pCvar[SmgGuns] = register_cvar("amx_trace_smgguns", "1")
	g_pCvar[RiffleGuns] = register_cvar("amx_trace_riffleguns", "1")
	g_pCvar[SnipeGuns] = register_cvar("amx_trace_snipeguns", "1")

	g_pCvarTraceHideSilen = register_cvar("amx_trace_hide_silen", "1")

#if defined PER_PLAYER_SETTINGS
	g_pCvarTraceHltv = register_cvar("amx_trace_hltv", "1")
	register_clcmd("say /tracers", "ClientCommand_Tracers")
#endif

	g_iMaxPlayers = get_maxplayers()
}

#if defined PER_PLAYER_SETTINGS
public client_putinserver(id)
{
	g_bSeeTracers[id] = !is_user_bot(id)
	g_bHltv[id] = is_user_hltv(id)
	set_task(35.0, "TaskAnnouncement", id)
}

public ClientCommand_Tracers(id)
{
	client_print(id, print_chat, "** [Advanced Weapon Tracers] Tracers are now %s", 
						(g_bSeeTracers[id] = !g_bSeeTracers[id]) ? "ON" : "OFF")
	return PLUGIN_HANDLED
}

public TaskAnnouncement(id)
{
	client_print(id, print_chat, "** [Advanced Weapon Tracers] You can [en/dis]able tracers by typing /tracers in chat")
}
#endif

public TraceAttack(iEnt, iAttacker, Float:flDamage, Float:fDir[3], ptr, iDamageType)
{
	if( !IsPlayer(iAttacker) || get_pcvar_num(g_pCvarTraceEnabled) == 0 )
	{
		return
	}

	new iWeapon = get_user_weapon(iAttacker)
	if( iWeapon == CSW_KNIFE )
	{
		return
	}

	new bWeapon = (1<<iWeapon)
	for(new a; a<sizeof(g_iWeaponBitSumList); a++)
	{
		if( bWeapon & g_iWeaponBitSumList[a] )
		{
			if( get_pcvar_num(g_pCvar[a]) )
			{
				break
			}
			else
			{
				return
			}
		}
	}
		
	if( SILEN_BITSUM & bWeapon )
	{
		if( get_pcvar_num(g_pCvarTraceHideSilen) )
		{
			if( cs_get_weapon_silen(get_pdata_cbase(iAttacker, m_pActiveItem)) )
			{
				return
			}
		}
	}
	#if defined TMP_IS_A_SILENCED_WEAPON
	else if( iWeapon == CSW_TMP && get_pcvar_num(g_pCvarTraceHideSilen) )
	{
		return
	}
	#endif

	new iOrigin[3], Float:flEnd[3]

	get_user_origin(iAttacker, iOrigin, 1)
	get_tr2(ptr, TR_vecEndPos, flEnd)

#if defined PER_PLAYER_SETTINGS
	new iPlayers[MAX_PLAYERS], iNum, iPlayer, bHltv
	new x = iOrigin[0], y = iOrigin[1], z = iOrigin[2]
	new Float:fX = flEnd[0], Float:fY = flEnd[1], Float:fZ = flEnd[2]
	get_players(iPlayers, iNum)
	for(new i; i<iNum; i++)
	{
		iPlayer = iPlayers[i]
		if( g_bHltv[iPlayer] )
		{
			if( !bHltv && get_pcvar_num(g_pCvarTraceHltv) == 1 )
			{
				bHltv = true
				message_begin(MSG_SPEC, SVC_TEMPENTITY)
				write_byte(TE_TRACER)
				write_coord(x)
				write_coord(y)
				write_coord(z) 
				write_coord_f(fX) 
				write_coord_f(fY) 
				write_coord_f(fZ) 
				message_end()
			}
		}
		else if( g_bSeeTracers[iPlayer] )
		{
			message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, iPlayer)
			write_byte(TE_TRACER)
			write_coord(x)
			write_coord(y)
			write_coord(z)
			write_coord_f(fX) 
			write_coord_f(fY) 
			write_coord_f(fZ) 
			message_end()
		}
	}
#else
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_TRACER)
	write_coord(iOrigin[0])
	write_coord(iOrigin[1])
	write_coord(iOrigin[2])
	write_coord_f(flEnd[0]) 
	write_coord_f(flEnd[1]) 
	write_coord_f(flEnd[2]) 
	message_end()
#endif
}
