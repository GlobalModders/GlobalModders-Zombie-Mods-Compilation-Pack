#include < amxmodx >
#include < hamsandwich >
#include < fakemeta >

new const MESSAGE[ ] = "Cover me... I'm reloading!";

new const SOUNDS[ ][ ] = {
	"radio/reloading01.wav",
	"radio/reloading02.wav"
};

new const Float:g_iMaxClip[ CSW_P90 + 1 ] = {
	0.0, 13.0, 0.0, 10.0, 1.0,  7.0, 1.0, 30.0, 30.0, 1.0, 30.0, 
	20.0, 25.0, 30.0, 35.0, 25.0, 12.0, 20.0, 10.0, 30.0, 100.0, 
	8.0, 30.0, 30.0, 20.0, 2.0, 7.0, 30.0, 30.0, 0.0, 50.0 };

const m_iTeam            = 114;
const m_pPlayer          = 41;
const m_fInReload        = 54;
const m_fInSpecialReload = 55;
const m_flTimeWeaponIdle = 48;

new bool:g_bLocation, g_iMsgTextMsg/*, g_iMsgSendAudio*/, g_szLocation[ 33 ][ 32 ];
new g_pChat, g_pPercent;

public plugin_init( ) {
	register_plugin( "Reload radio", "1.0", "xPaw" );
	
	g_pChat    = register_cvar( "rr_chat",    "1" );
	g_pPercent = register_cvar( "rr_percent", "55" );
	
	g_iMsgTextMsg   = get_user_msgid( "TextMsg" );
	//g_iMsgSendAudio = get_user_msgid( "SendAudio" );
	
	// 2 = CSW_SHIELD = UNDEFINED | PUT SHOTGUNS HERE TO SKIP IN LOOP AND REGISTER MANUALLY
	new const NO_RELOAD = ( 1 << 2 ) | ( 1 << CSW_KNIFE ) | ( 1 << CSW_C4 ) | ( 1 << CSW_M3 ) |
		( 1 << CSW_XM1014 ) | ( 1 << CSW_HEGRENADE ) | ( 1 << CSW_FLASHBANG ) | ( 1 << CSW_SMOKEGRENADE );
	
	new szWeaponName[ 20 ];
	for( new i = CSW_P228; i <= CSW_P90; i++ ) {
		if( NO_RELOAD & ( 1 << i ) )
			continue;
		
		get_weaponname( i, szWeaponName, 19 );
		
		RegisterHam( Ham_Weapon_Reload, szWeaponName, "FwdHamWeaponReload", 1 );
	}
	
	//RegisterHam( Ham_Weapon_Reload, "weapon_m3",     "FwdHamShotgunReload", 1 );
	//RegisterHam( Ham_Weapon_Reload, "weapon_xm1014", "FwdHamShotgunReload", 1 );
	
	new szModName[ 6 ];
	get_modname( szModName, 5 );
	
	if( equal( szModName, "czero" ) )
		register_event( "Location", "EventLocation", "be" );
}

public plugin_precache( )
	for( new i; i < sizeof SOUNDS; i++ )
		precache_sound( SOUNDS[ i ] );

public EventLocation( const id ) { // Condition Zero
	if( !g_bLocation )
		g_bLocation = true;
	
	if( read_data( 1 ) == id )
		read_data( 2, g_szLocation[ id ], 31 );
}

public FwdHamWeaponReload( const iWeapon )
	if( get_pdata_int( iWeapon, m_fInReload, 4 ) ) // m_fInReload is set to TRUE in DefaultReload( )
		DoRadio( get_pdata_cbase( iWeapon, m_pPlayer, 4 ) );

public FwdHamShotgunReload( const iWeapon ) {
	if( get_pdata_int( iWeapon, m_fInSpecialReload, 4 ) != 1 )
		return;
	
	// The first set of m_fInSpecialReload to 1. m_flTimeWeaponIdle remains 0.55 set from Reload( )
	new Float:flTimeWeaponIdle = get_pdata_float( iWeapon, m_flTimeWeaponIdle, 4 );
	
	if( flTimeWeaponIdle != 0.55 )
		return;
	
	DoRadio( get_pdata_cbase( iWeapon, m_pPlayer, 4 ) );
}

DoRadio( const id ) {
	new iClip, iWeapon  = get_user_weapon( id, iClip );
	new Float:flPercent = floatmul( float( iClip ) / g_iMaxClip[ iWeapon ], 100.0 );
	new Float:flCvar    = get_pcvar_float( g_pPercent );
	
	if( flPercent > flCvar )
		return;
	
	new iPlayers[ 32 ], szId[ 3 ], szName[ 32 ], iNum, iPlayer, iTeam = get_pdata_int( id, m_iTeam, 5 );
	get_players( iPlayers, iNum, "c" );
	get_user_name( id, szName, 31 );
	num_to_str( id, szId, 2 );
	
	new szSound[ 32 ];
	copy( szSound, 31, SOUNDS[ random( sizeof( SOUNDS ) ) ] );
	
	new bool:bChat = bool:!!get_pcvar_num( g_pChat );
	
	for( new i; i < iNum; i++ ) {
		iPlayer = iPlayers[ i ];
		
		if( iTeam != get_pdata_int( iPlayer, m_iTeam, 5 ) )
			continue;
		
		if( bChat ) {
			emessage_begin( MSG_ONE_UNRELIABLE, g_iMsgTextMsg, _, iPlayer );
			ewrite_byte( 5 );
			ewrite_string( szId );
			ewrite_string( g_bLocation ? "#Game_radio_location" : "#Game_radio" );
			ewrite_string( szName );
			
			if( g_bLocation )
				ewrite_string( g_szLocation[ id ] );
			
			ewrite_string( MESSAGE );
			emessage_end( );
		}
		
		/*
		emessage_begin( MSG_ONE_UNRELIABLE, g_iMsgSendAudio, _, iPlayer );
		ewrite_byte( id );
		ewrite_string( szSound );
		ewrite_short( PITCH_NORM );
		emessage_end( );*/
	}
	
	emit_sound(id, CHAN_VOICE, szSound, 0.5, ATTN_NORM, 0, PITCH_NORM)
}
