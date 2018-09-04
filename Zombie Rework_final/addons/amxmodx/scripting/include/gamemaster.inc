/* ======================================
This module is written by 
Dias Pendragon and Kungfulon

Version: 1.0
======================================= */

#if defined _gamemaster_included
	#endinput
#endif
#define _gamemaster_included

#if AMXX_VERSION_NUM >= 175
 #pragma reqlib gamemaster
 #if !defined AMXMODX_NOAUTOLOAD
  #pragma loadlib gamemaster
 #endif
#else
 #pragma library gamemaster
#endif

enum
{
	WINSTATUS_CT = 1,
	WINSTATUS_TERRORIST,
	WINSTATUS_DRAW
}

// Round Mangement
native GM_EndRound_Block(bool:Enabled); // true or false only (set only when server starts, except precache)
native GM_TerminateRound(Float:DelayTime, WinningStatus); 

// Changing Model
native GM_Set_PlayerModel(id, const Model[]);
native GM_Reset_PlayerModel(id);
	
// Changing Team
native GM_Set_PlayerTeam(id, CsTeams:Team);
	
// Changing Speed
native GM_Set_PlayerSpeed(id, Float:Speed, BlockSpeed);
native GM_Reset_PlayerSpeed(id);

// Running Time
forward GM_Time();
