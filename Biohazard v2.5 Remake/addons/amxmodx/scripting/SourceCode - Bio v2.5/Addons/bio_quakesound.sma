// Really needed?
//#pragma semicolon 1

#include < amxmodx >
#include <cstrike>

// Variable for check if the plugin is enabled
new g_iPluginEnabled;

// Variables for cache the onlykiller settings
new g_iHeadshotOnlyKiller, g_iRevengeOnlyKiller;

// Variables for check if the events are enabled
new g_iHeadshot, g_iSuicide, g_iNade, g_iTeamkill, g_iKnife, g_iFirstblood, g_iKillstreak, g_iRoundstart, g_iDoublekill, g_iHattrick, g_iFlawless, g_iRevenge;

// Variables for cache the colors you set
new g_iRed, g_iGreen, g_iBlue, g_iRandomRed, g_iRandomGreen, g_iRandomBlue;

// Variable for cache the minimum required frags for the `Hattrick` event
new g_iMinFragsForHattrick;

// The plugin arrays
new Array: g_aHeadshot, Array: g_aSuicide, Array: g_aNade, Array: g_aTeamkill, Array: g_aKnife, Array: g_aFirstblood, Array: g_aRoundstart, Array: g_aDoublekill,
Array: g_aHattrick, Array: g_aFlawless, Array: g_aRevenge, Array: g_aKillstreakSounds, Array: g_aKillstreakMessages, Array: g_aKillstreakRequiredKills;

// The arrays sizes
new g_iHeadshotSize, g_iSuicideSize, g_iNadeSize, g_iTeamkillSize, g_iKnifeSize, g_iFirstbloodSize, g_iRoundstartSize, g_iDoublekillSize, g_iHattrickSize, g_iFlawlessSize,
g_iRevengeSize, g_iKillstreakSoundsSize;

// The events strings
new g_szHeadshot[ 256 ], g_szSuicide[ 256 ], g_szNade[ 256 ], g_szTeamkill[ 256 ], g_szKnife[ 256 ], g_szFirstblood[ 256 ], g_szRoundstart[ 256 ], g_szDoublekill[ 256 ],
g_szHattrick[ 256 ], g_szFlawless[ 256 ], g_szRevenge[ 256 ], g_szRevenge2[ 256 ], g_szTEName[ 256 ], g_szCTName[ 256 ];

// Variables for check if there's the events messages enabled
new g_iHeadshotMessage, g_iSuicideMessage, g_iNadeMessage, g_iTeamkillMessage, g_iKnifeMessage, g_iFirstbloodMessage, g_iRoundstartMessage, g_iDoublekillMessage,
g_iHattrickMessage, g_iFlawlessMessage, g_iRevengeMessage, g_iRevenge2Message;

// The hudmessage handlers
new g_hHudmessage, g_hHudmessage2, g_hHudmessage3;

// The `Firstblood` event variable
new g_iFirstbloodVariable;

// Variables for cache the kills
new g_iKills[ 33 ];
new g_iKillsForHattrick[ 33 ];

// Variables for cache the `Doublekill` event weaponnames and the `Revenge` event playernames
new g_szDoublekillVariable[ 33 ][ 24 ];
new g_szRevengeKillVariable[ 33 ][ 32 ];

// Executed when map start
public plugin_precache( )
{
	g_aHeadshot = ArrayCreate( 64 );
	g_aSuicide = ArrayCreate( 64 );
	g_aNade = ArrayCreate( 64 );
	g_aTeamkill = ArrayCreate( 64 );
	g_aKnife = ArrayCreate( 64 );
	g_aFirstblood = ArrayCreate( 64 );
	g_aRoundstart = ArrayCreate( 64 );
	g_aDoublekill = ArrayCreate( 64 );
	g_aHattrick = ArrayCreate( 64 );
	g_aFlawless = ArrayCreate( 64 );
	g_aRevenge = ArrayCreate( 64 );
	g_aKillstreakSounds = ArrayCreate( 64 );
	g_aKillstreakMessages = ArrayCreate( 192 );
	g_aKillstreakRequiredKills = ArrayCreate( 3 );
	
	Func_LoadCustomizationsFromFile( );
	
	// Precache nothing
	if( !g_iPluginEnabled )
		return;
	
	g_iHeadshotSize = ArraySize( g_aHeadshot );
	g_iSuicideSize = ArraySize( g_aSuicide );
	g_iNadeSize = ArraySize( g_aNade );
	g_iTeamkillSize = ArraySize( g_aTeamkill );
	g_iKnifeSize = ArraySize( g_aKnife );
	g_iFirstbloodSize = ArraySize( g_aFirstblood );
	g_iRoundstartSize = ArraySize( g_aRoundstart );
	g_iDoublekillSize = ArraySize( g_aDoublekill );
	g_iHattrickSize = ArraySize( g_aHattrick );
	g_iFlawlessSize = ArraySize( g_aFlawless );
	g_iRevengeSize = ArraySize( g_aRevenge );
	g_iKillstreakSoundsSize = ArraySize( g_aKillstreakSounds );
	
	new i, szSound[ 64 ];
	
	if( g_iHeadshot )
	{
		for( i = 0; i < g_iHeadshotSize; i++ )
		{
			ArrayGetString( g_aHeadshot, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iSuicide )
	{
		for( i = 0; i < g_iSuicideSize; i++ )
		{
			ArrayGetString( g_aSuicide, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iNade )
	{
		for( i = 0; i < g_iNadeSize; i++ )
		{
			ArrayGetString( g_aNade, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iTeamkill )
	{
		for( i = 0; i < g_iTeamkillSize; i++ )
		{
			ArrayGetString( g_aTeamkill, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iKnife )
	{
		for( i = 0; i < g_iKnifeSize; i++ )
		{
			ArrayGetString( g_aKnife, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iFirstblood )
	{
		for( i = 0; i < g_iFirstbloodSize; i++ )
		{
			ArrayGetString( g_aFirstblood, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iRoundstart )
	{
		for( i = 0; i < g_iRoundstartSize; i++ )
		{
			ArrayGetString( g_aRoundstart, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iDoublekill )
	{
		for( i = 0; i < g_iDoublekillSize; i++ )
		{
			ArrayGetString( g_aDoublekill, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iHattrick )
	{
		for( i = 0; i < g_iHattrickSize; i++ )
		{
			ArrayGetString( g_aHattrick, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iFlawless )
	{
		for( i = 0; i < g_iFlawlessSize; i++ )
		{
			ArrayGetString( g_aFlawless, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iRevenge )
	{
		for( i = 0; i < g_iRevengeSize; i++ )
		{
			ArrayGetString( g_aRevenge, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
	
	if( g_iKillstreak )
	{
		for( i = 0; i < g_iKillstreakSoundsSize; i++ )
		{
			ArrayGetString( g_aKillstreakSounds, i, szSound, charsmax( szSound ) );
			
			precache_sound( szSound );
		}
	}
}

// Executed after the `plugin_precache` forward
public plugin_init( )
{
	register_plugin( "Quake Sounds", "4.0", "Hattrick" );
	
	register_cvar( "advanced_quake_sounds", "4.0", FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );
	set_cvar_float( "advanced_quake_sounds", 4.0 );
	
	// Stop here if the plugin isn't enabled
	if( !g_iPluginEnabled )
		return;
	
	// This event for all games, I hooked it because I need to know if there's a headshot or not
	// read_data( 1 ) == KillerIndex;
	// read_data( 2 ) == VictimIndex;
	// read_data( 3 ) == Headshot;		( return 1 if there's a headshot, return 0 if there's not a headshot )
	// read_data( 4 ) == WeaponName;	( use as: read_data( 4, szWeaponName, charsmax( szWeaponName ) ) )
	register_event( "DeathMsg", "PlayerKilled", "a" );
	
	new szModName[ 32 ];
	get_modname( szModName, charsmax( szModName ) );
	
	if( equali( szModName, "cstrike" ) || equali( szModName, "czero" ) || equali( szModName, "csv15" ) || equali( szModName, "cs13" ) )
	{
		// This logevents are only for Counter-Strike
		register_logevent( "RoundStart", 2, "1=Round_Start" );
		register_logevent( "RoundEnd", 2, "1=Round_End" );
	}
	
	else if( equali( szModName, "dod" ) )
	{
		// I think this is only for Day of Defeat (I can't make sure)
		register_event( "RoundState", "RoundStart", "a", "1=1" );
		register_event( "RoundState", "RoundEnd", "a", "1=3", "1=4" );
		
		// Disable the `Flawless` event
		g_iFlawless = 0;
	}
	
	else
	{
		// If there's no roundstate events, disable the next features:
		g_iTeamkill = 0;
		g_iHattrick = 0;
		g_iFlawless = 0;
		g_iRoundstart = 0;
		g_iFirstblood = 0;
	}
	
	// Hudmessage handlers
	g_hHudmessage = CreateHudSyncObj( );
	g_hHudmessage2 = CreateHudSyncObj( );
	g_hHudmessage3 = CreateHudSyncObj( );
}

// Executed after `plugin_init` forward
public plugin_cfg( )
{
	g_iHeadshotMessage = g_szHeadshot[ 0 ] ? 1 : 0;
	g_iSuicideMessage = g_szSuicide[ 0 ] ? 1 : 0;
	g_iNadeMessage = g_szNade[ 0 ] ? 1 : 0;
	g_iTeamkillMessage = g_szTeamkill[ 0 ] ? 1 : 0;
	g_iKnifeMessage = g_szKnife[ 0 ] ? 1 : 0;
	g_iFirstbloodMessage = g_szFirstblood[ 0 ] ? 1 : 0;
	g_iRoundstartMessage = g_szRoundstart[ 0 ] ? 1 : 0;
	g_iDoublekillMessage = g_szDoublekill[ 0 ] ? 1 : 0;
	g_iHattrickMessage = g_szHattrick[ 0 ] ? 1 : 0;
	g_iFlawlessMessage = g_szFlawless[ 0 ] ? 1 : 0;
	g_iRevengeMessage = g_szRevenge[ 0 ] ? 1 : 0;
	g_iRevenge2Message = g_szRevenge2[ 0 ] ? 1 : 0;
}

// Executed when client disconnect
public client_disconnect( iPlayer )
{
	g_iKills[ iPlayer ] = 0;
	g_iKillsForHattrick[ iPlayer ] = 0;
	
	g_szRevengeKillVariable[ iPlayer ] = "";
	g_szDoublekillVariable[ iPlayer ] = "";
}

// Executed when a player is killed
// This is not a forward. Is the `DeathMsg` event registered in `plugin_init`
public PlayerKilled( )
{
	static iKiller, iVictim, iHeadshot, szWeapon[ 24 ], szName[ 32 ], szVictimName[ 32 ], i, szReq[ 100 ], szSound[ 64 ], szMessage[ 256 ];
	iKiller = read_data( 1 );
	iVictim = read_data( 2 );
	
	g_iKills[ iVictim ] = 0;
	
	if( !iKiller )
		return;
	
	iHeadshot = read_data( 3 );
	read_data( 4, szWeapon, charsmax( szWeapon ) );
	get_user_name( iKiller, szName, charsmax( szName ) );
	get_user_name( iVictim, szVictimName, charsmax( szVictimName ) );
	
	if( g_iRandomRed )
		g_iRed = random_num( 0, 255 );
	
	if( g_iRandomGreen )
		g_iGreen = random_num( 0, 255 );
	
	if( g_iRandomBlue )
		g_iBlue = random_num( 0, 255 );
	
	set_hudmessage( g_iRed, g_iGreen, g_iBlue, -1.0, 0.24, 0, 6.0, 5.0 );
	
	g_iKills[ iKiller ]++;
	g_iKillsForHattrick[ iKiller ]++;
	
	g_szRevengeKillVariable[ iVictim ] = szName;
	
	if( iVictim == iKiller )
	{
		if( g_iSuicide )
		{
			if( g_iSuicideMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szSuicide, szName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aSuicide, random_num( 0, g_iSuicideSize - 1 ) ) );
		}
		
		if( g_iHattrick )
			g_iKillsForHattrick[ iVictim ]--;
	}
	
	else
	{
		if( equal( szVictimName, g_szRevengeKillVariable[ iKiller ] ) && g_iRevenge )
		{
			g_szRevengeKillVariable[ iKiller ] = "";
			
			if( g_iRevengeMessage )
				ShowSyncHudMsg( iKiller, g_hHudmessage2, g_szRevenge, szVictimName );
			
			if( g_iRevenge2Message && !g_iRevengeOnlyKiller )
				ShowSyncHudMsg( iVictim, g_hHudmessage2, g_szRevenge2, szName );
			
			client_cmd( iKiller, "spk ^"%a^"", ArrayGetStringHandle( g_aRevenge, random_num( 0, g_iRevengeSize - 1 ) ) );
			
			if( !g_iRevengeOnlyKiller )
				client_cmd( iVictim, "spk ^"%a^"", ArrayGetStringHandle( g_aRevenge, random_num( 0, g_iRevengeSize - 1 ) ) );
		}
		
		if( iHeadshot && g_iHeadshot )
		{
			if( g_iHeadshotMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szHeadshot, szName, szVictimName );
			
			client_cmd( g_iHeadshotOnlyKiller ? iKiller : 0, "spk ^"%a^"", ArrayGetStringHandle( g_aHeadshot, random_num( 0, g_iHeadshotSize - 1 ) ) );
		}
		
		g_iFirstbloodVariable++;
		
		if( g_iFirstbloodVariable == 1 && g_iFirstblood )
		{
			if( g_iFirstbloodMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szFirstblood, szName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aFirstblood, random_num( 0, g_iFirstbloodSize - 1 ) ) );
		}
		
		if( cs_get_user_team( iVictim ) == cs_get_user_team( iKiller ) && g_iTeamkill )
		{
			if( g_iTeamkillMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szTeamkill, szName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aTeamkill, random_num( 0, g_iTeamkillSize - 1 ) ) );
		}
		
		if( szWeapon[ 1 ] == 'r' && g_iNade )
		{
			if( g_iNadeMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szNade, szName, szVictimName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aNade, random_num( 0, g_iNadeSize - 1 ) ) );
		}
		
		if( szWeapon[ 0 ] == 'k' && g_iKnife )
		{
			if( g_iKnifeMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szKnife, szName, szVictimName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aKnife, random_num( 0, g_iKnifeSize - 1 ) ) );
		}
		
		if( equal( g_szDoublekillVariable[ iKiller ], szWeapon ) && g_iDoublekill )
		{
			if( g_iDoublekillMessage )
				ShowSyncHudMsg( 0, g_hHudmessage2, g_szDoublekill, szName, szVictimName );
			
			client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aDoublekill, random_num( 0, g_iDoublekillSize - 1 ) ) );
			
			g_szDoublekillVariable[ iKiller ] = "";
		}
		
		else
		{
			g_szDoublekillVariable[ iKiller ] = szWeapon;
			set_task( 0.1, "Task_ClearKill", iKiller + 69113 );
		}
		
		if( g_iKillstreak )
		{
			for( i = 0; i < g_iKillstreakSoundsSize; i++ )
			{
				ArrayGetString( g_aKillstreakRequiredKills, i, szReq, charsmax( szReq ) );
				
				if( g_iKills[ iKiller ] == str_to_num( szReq ) )
				{
					ArrayGetString( g_aKillstreakMessages, i, szMessage, charsmax( szMessage ) );
					ArrayGetString( g_aKillstreakSounds, i, szSound, charsmax( szSound ) );
					
					Func_StreakDisplay( iKiller, szMessage, szSound );
					
					break;
				}
			}
		}
	}
}

public RoundStart( )
{
	if( g_iFirstblood )
		g_iFirstbloodVariable = 0;
	
	if( g_iRoundstart )
	{
		if( g_iRandomRed )
			g_iRed = random_num( 0, 255 );
		
		if( g_iRandomGreen )
			g_iGreen = random_num( 0, 255 );
		
		if( g_iRandomBlue )
			g_iBlue = random_num( 0, 255 );
		
		set_hudmessage( g_iRed, g_iGreen, g_iBlue, -1.0, 0.27, 0, 6.0, 5.0 );
		
		if( g_iRoundstartMessage )
			ShowSyncHudMsg( 0, g_hHudmessage, g_szRoundstart );
		
		client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aRoundstart, random_num( 0, g_iRoundstartSize - 1 ) ) );
	}
	
	if( g_iHattrick )
	{
		static iPlayer;
		
		for( iPlayer = 1; iPlayer < 33; iPlayer++ )
			g_iKillsForHattrick[ iPlayer ] = 0;
	}
}

public RoundEnd( )
{
	if( g_iHattrick )
		set_task( 2.8, "Task_Hattrick" );
	
	if( g_iFlawless )
		set_task( 1.2, "Task_Flawless" );
}

public Task_Hattrick( )
{
	static iPlayer, szName[ 32 ];
	iPlayer = Func_GetThisRoundLeader( );
	
	if( g_iRandomRed )
		g_iRed = random_num( 0, 255 );
	
	if( g_iRandomGreen )
		g_iGreen = random_num( 0, 255 );
	
	if( g_iRandomBlue )
		g_iBlue = random_num( 0, 255 );
	
	set_hudmessage( g_iRed, g_iGreen, g_iBlue, -1.0, 0.21, 0, 6.0, 5.0 );
	
	get_user_name( iPlayer, szName, charsmax( szName ) )
	
	if( g_iKillsForHattrick[ iPlayer ] >= g_iMinFragsForHattrick )
	{
		if( g_iHattrickMessage )
			ShowSyncHudMsg( 0, g_hHudmessage3, g_szHattrick, szName );
		
		client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aHattrick, random_num( 0, g_iHattrickSize - 1 ) ) );
	}
}

public Task_Flawless( )
{
	if( g_iRandomRed )
		g_iRed = random_num( 0, 255 );
	
	if( g_iRandomGreen )
		g_iGreen = random_num( 0, 255 );
	
	if( g_iRandomBlue )
		g_iBlue = random_num( 0, 255 );
	
	set_hudmessage( g_iRed, g_iGreen, g_iBlue, -1.0, 0.21, 0, 6.0, 5.0 );
	
	if( Func_GetCounterTerrorists( ) == Func_GetDeadCounterTerrorists( ) && Func_GetTerrorists( ) == Func_GetAliveTerrorists( ) )
	{
		if( g_iFlawlessMessage )
			ShowSyncHudMsg( 0, g_hHudmessage3, g_szFlawless, "TERRORIST" );
		
		client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aFlawless, random_num( 0, g_iFlawlessSize - 1 ) ) );
	}
	
	else if( Func_GetTerrorists( ) == Func_GetDeadTerrorists( ) && Func_GetCounterTerrorists( ) == Func_GetAliveCounterTerrorists( ) )
	{
		if( g_iFlawlessMessage )
			ShowSyncHudMsg( 0, g_hHudmessage3, g_szFlawless, "COUNTER-TERRORIST" );
		
		client_cmd( 0, "spk ^"%a^"", ArrayGetStringHandle( g_aFlawless, random_num( 0, g_iFlawlessSize - 1 ) ) );
	}
}

public Task_ClearKill( iTask )
	g_szDoublekillVariable[ iTask - 69113 ] = "";

Func_LoadCustomizationsFromFile( )
{
	new szConfigsDir[ 64 ], szFileName[ 128 ], szLineData[ 360 ], szKey[ 64 ], szValue[ 256 ], hFile, szNum[ 100 ], szType[ 32 ], \
		szMessage[ 256 ], szDummy[ 2 ], szReq[ 100 ], szSound[ 64 ];
	
	get_localinfo( "amxx_configsdir", szConfigsDir, charsmax( szConfigsDir ) );
	format( szFileName, charsmax( szFileName ), "%s/quakesounds.ini", szConfigsDir );
	hFile = fopen( szFileName, "rt" );
	
	while( hFile && !feof( hFile ) )
	{
		fgets( hFile, szLineData, charsmax( szLineData ) );
		replace( szLineData, charsmax( szLineData), "^n", "" );
		
		if( !szLineData[ 0 ] || szLineData[ 0 ] == ';' )
			continue;
		
		strtok( szLineData, szKey, charsmax( szKey ), szValue, charsmax( szValue ), '=' );
		
		trim( szKey );
		trim( szValue );
		
		if( equal( szKey, "ENABLE/DISABLE PLUGIN" ) )
			g_iPluginEnabled = str_to_num( szValue );
		
		else if( equal( szKey, "HEADSHOT ONLY KILLER" ) )
			g_iHeadshotOnlyKiller = str_to_num( szValue );
		
		else if( equal( szKey, "MIN FRAGS FOR HATTRICK" ) )
			g_iMinFragsForHattrick = str_to_num( szValue );
		
		else if( equal( szKey, "REVENGE ONLY FOR KILLER" ) )
			g_iRevengeOnlyKiller = str_to_num( szValue );
		
		else if( equal( szKey, "HUDMSG RED" ) )
		{
			if( equal( szValue, "_" ) )
				g_iRandomRed = 1;
			
			else
				g_iRed = str_to_num( szValue );
		}
		
		else if( equal( szKey, "HUDMSG GREEN" ) )
		{
			if( equal( szValue, "_" ) )
				g_iRandomGreen = 1;
			
			else
				g_iGreen = str_to_num( szValue );
		}
		
		else if( equal( szKey, "HUDMSG BLUE" ) )
		{
			if( equal( szValue, "_" ) )
				g_iRandomBlue = 1;
			
			else
				g_iBlue = str_to_num( szValue );
		}
		
		else if( equal( szKey, "SOUND" ) )
		{
			parse( szValue, szNum, charsmax( szNum ), szType, charsmax( szType ) );
			
			if( equal( szType, "REQUIREDKILLS" ) )
			{
				parse( szValue, szNum, charsmax( szNum ), szType, charsmax( szType ), szReq, charsmax( szReq ), \
					szDummy, charsmax( szDummy ), szSound, charsmax( szSound ) );
				
				ArrayPushString( g_aKillstreakSounds, szSound );
				ArrayPushString( g_aKillstreakRequiredKills, szReq );
			}
			
			else if( equal( szType, "MESSAGE" ) ) {
				strtok( szValue, szType, charsmax( szType ), szMessage, charsmax( szMessage ), '@' );
				
				trim( szType );
				trim( szMessage );
				
				ArrayPushString( g_aKillstreakMessages, szMessage );
			}
		}
		
		else if( equal( szKey, "KILLSTREAK EVENT" ) )
			g_iKillstreak = str_to_num( szValue );
		
		else if( equal( szKey, "REVENGE EVENT" ) )
			g_iRevenge = str_to_num( szValue );
		
		else if( equal( szKey, "HEADSHOT EVENT" ) )
			g_iHeadshot = str_to_num( szValue );
		
		else if( equal( szKey, "SUICIDE EVENT" ) )
			g_iSuicide = str_to_num( szValue );
		
		else if( equal( szKey, "NADE EVENT" ) )
			g_iNade = str_to_num( szValue );
		
		else if( equal( szKey, "TEAMKILL EVENT" ) )
			g_iTeamkill = str_to_num( szValue );
		
		else if( equal( szKey, "KNIFE EVENT" ) )
			g_iKnife = str_to_num( szValue );
		
		else if( equal( szKey, "FIRSTBLOOD EVENT" ) )
			g_iFirstblood = str_to_num( szValue );
		
		else if( equal( szKey, "ROUNDSTART EVENT" ) )
			g_iRoundstart = str_to_num( szValue );
		
		else if( equal( szKey, "DOUBLEKILL EVENT" ) )
			g_iDoublekill = str_to_num( szValue );
		
		else if( equal( szKey, "HATTRICK EVENT" ) )
			g_iHattrick = str_to_num( szValue );
		
		else if( equal( szKey, "FLAWLESS VICTORY" ) )
			g_iFlawless = str_to_num( szValue );
		
		else if( equal( szKey, "HEADSHOT SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aHeadshot, szKey );
			}
		}
		
		else if( equal( szKey, "REVENGE SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aRevenge, szKey );
			}
		}
		
		else if( equal( szKey, "SUICIDE SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aSuicide, szKey );
			}
		}
		
		else if( equal( szKey, "NADE SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aNade, szKey );
			}
		}
		
		else if( equal( szKey, "TEAMKILL SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aTeamkill, szKey );
			}
		}
		
		else if( equal( szKey, "KNIFE SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aKnife, szKey );
			}
		}
		
		else if( equal( szKey, "FIRSTBLOOD SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aFirstblood, szKey );
			}
		}
		
		else if( equal( szKey, "ROUNDSTART SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aRoundstart, szKey );
			}
		}
		
		else if( equal( szKey, "DOUBLEKILL SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aDoublekill, szKey );
			}
		}
		
		else if( equal( szKey, "HATTRICK SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aHattrick, szKey );
			}
		}
		
		else if( equal( szKey, "FLAWLESS SOUNDS" ) )
		{
			while( szValue[ 0 ] != 0 && strtok( szValue, szKey, charsmax( szKey ), szValue, charsmax( szValue ), ',' ) )
			{
				trim( szKey );
				trim( szValue );
				ArrayPushString( g_aFlawless, szKey );
			}
		}
		
		else if( equal( szKey, "HEADSHOT HUDMSG" ) )
			g_szHeadshot = szValue;
		
		else if( equal( szKey, "SUICIDE HUDMSG" ) )
			g_szSuicide = szValue;
		
		else if( equal( szKey, "NADE HUDMSG" ) )
			g_szNade = szValue;
		
		else if( equal( szKey, "TEAMKILL HUDMSG" ) )
			g_szTeamkill = szValue;
		
		else if( equal( szKey, "KNIFE HUDMSG" ) )
			g_szKnife = szValue;
		
		else if( equal( szKey, "FIRSTBLOOD HUDMSG" ) )
			g_szFirstblood = szValue;
		
		else if( equal( szKey, "ROUNDSTART HUDMSG" ) )
			g_szRoundstart = szValue;
		
		else if( equal( szKey, "DOUBLEKILL HUDMSG" ) )
			g_szDoublekill = szValue;
		
		else if( equal( szKey, "HATTRICK HUDMSG" ) )
			g_szHattrick = szValue;
		
		else if( equal( szKey, "FLAWLESS VICTORY HUDMSG" ) )
			g_szFlawless = szValue;
		
		else if( equal( szKey, "REVENGE KILLER MESSAGE" ) )
			g_szRevenge = szValue;
		
		else if( equal( szKey, "REVENGE VICTIM MESSAGE" ) )
			g_szRevenge2 = szValue;
		
		else if( equal( szKey, "TERRO TEAM NAME" ) )
			g_szTEName = szValue;
		
		else if( equal( szKey, "CT TEAM NAME" ) )
			g_szCTName = szValue;
	}
	
	if( hFile )
		fclose( hFile );
}

Func_StreakDisplay( iKiller, szMessage[ ], szSound[ ] )
{
	static szName[ 32 ];
	get_user_name( iKiller, szName, charsmax( szName ) );
	
	if( g_iRandomRed )
		g_iRed = random_num( 0, 255 );
	
	if( g_iRandomGreen )
		g_iGreen = random_num( 0, 255 );
	
	if( g_iRandomBlue )
		g_iBlue = random_num( 0, 255 );
	
	set_hudmessage( g_iRed, g_iGreen, g_iBlue, -1.0, 0.27, 0, 6.0, 5.0 );
	ShowSyncHudMsg( 0, g_hHudmessage, szMessage, szName );
	
	client_cmd( 0, "spk ^"%s^"", szSound )
}

Func_GetCounterTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "e", "CT" );
	
	return iNum;
}

Func_GetDeadCounterTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "be", "CT" );
	
	return iNum;
}

Func_GetAliveCounterTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	return iNum;
}

Func_GetTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "e", "TERRORIST" );
	
	return iNum;
}

Func_GetDeadTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "be", "TERRORIST" );
	
	return iNum;
}

Func_GetAliveTerrorists( )
{
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	return iNum;
}

Func_GetThisRoundLeader( )
{
	static iPlayers[ 32 ], iNum, i, iPlayer, iLeader, iFrags, iMax;
	get_players( iPlayers, iNum );
	iMax = 0;
	
	for( i = 0; i < iNum; i++ )
	{
		iPlayer = iPlayers[ i ];
		iFrags = g_iKillsForHattrick[ iPlayer ];
		
		if( iFrags > iMax )
		{
			iMax = iFrags;
			iLeader = iPlayer;
		}
	}
	
	return iLeader;
}
