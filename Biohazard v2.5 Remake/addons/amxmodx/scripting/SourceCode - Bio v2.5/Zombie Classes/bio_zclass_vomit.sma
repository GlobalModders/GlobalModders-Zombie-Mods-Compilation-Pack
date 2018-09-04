#include <amxmodx>
#include <engine>
#include <biohazard>
#include <cstrike>

#define D_ZOMBIE_NAME "Vomit Zombie"
#define D_ZOMBIE_DESC "[G] -> Lam Human Bi Mu"
#define D_PLAYER_MODEL "models/player/zombie_vomit/zombie_vomit.mdl"
#define D_CLAWS "models/biohazard/v_knife_vomit.mdl"

new const vomit_sprite[] = "sprites/poison.spr"
new const vomit_sounds[3][] = { 
	"biohazard/male_boomer_vomit_01.wav",
	"biohazard/male_boomer_vomit_03.wav",
	"biohazard/male_boomer_vomit_04.wav" 
}
new const explode_sounds[3][] = { 
	"biohazard/explo_medium_09.wav",
	"biohazard/explo_medium_10.wav",
	"biohazard/explo_medium_14.wav"
}

new g_zclass_vomit, g_msgid_ScreenFade, g_iMaxPlayers, vomit
new cvar_vomitdist, cvar_explodedist, cvar_wakeuptime
new cvar_vomitcooldown, cvar_victimrender, cvar_vomit_reward

// Cooldown hook
new Float:g_iLastVomit[33]

// Stupid spam when using IN_USE button
new bool:g_iHateSpam[33]

public plugin_init()
{
	register_plugin("[Bio] Class: Vomit", "1.2 BETA", "Excalibur.007")
	
	register_clcmd("drop", "do_skill")
	register_event("DeathMsg", "event_DeathMsg", "a")
	
	cvar_vomitdist = register_cvar("bh_vomit_distance", "300")
	cvar_explodedist = register_cvar("bh_vomit_explode_distance", "300")
	cvar_wakeuptime = register_cvar("bh_vomit_blind_time", "5")
	cvar_vomitcooldown = register_cvar("bh_vomit_cooldown", "10.0")
	cvar_victimrender = register_cvar("bh_vomit_victim_render", "1")
	cvar_vomit_reward = register_cvar("bh_vomit_reward", "2000")
	
	g_msgid_ScreenFade = get_user_msgid( "ScreenFade")
	g_iMaxPlayers = get_maxplayers()
	
	register_zombie_class()
}

public plugin_precache()
{
	vomit = precache_model( vomit_sprite )
	
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	
	for( new i = 0; i < sizeof vomit_sounds; i ++ )
		precache_sound( vomit_sounds[ i ] )
		
	for( new i = 0; i < sizeof explode_sounds; i ++ )
		precache_sound( explode_sounds[ i ] )
}

public register_zombie_class()
{
	g_zclass_vomit = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)

	if(g_zclass_vomit != -1)
	{
		set_class_data(g_zclass_vomit, DATA_HEALTH, 3000.0)
		set_class_data(g_zclass_vomit, DATA_SPEED, 270.0)
		set_class_data(g_zclass_vomit, DATA_GRAVITY, 0.725)
		set_class_data(g_zclass_vomit, DATA_ATTACK, 1.0)
		set_class_data(g_zclass_vomit, DATA_HITDELAY, 0.1)
		set_class_data(g_zclass_vomit, DATA_HITREGENDLY, 2.0)
		set_class_data(g_zclass_vomit, DATA_KNOCKBACK, 1.0)
		set_class_data(g_zclass_vomit, DATA_DEFENCE, 0.85)
		set_class_data(g_zclass_vomit, DATA_HEDEFENCE, 0.85)
		set_class_pmodel(g_zclass_vomit, D_PLAYER_MODEL)
		set_class_wmodel(g_zclass_vomit, D_CLAWS)
	}		
}

public event_infect(id, attacker)
{
	if(is_user_zombie(id) && get_user_class(id) == g_zclass_vomit)
		client_print(id, print_center, D_ZOMBIE_DESC)
}

public do_skill(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_vomit)
		clcmd_vomit(id)
}

public clcmd_vomit(id)
{
	if(get_gametime( ) - g_iLastVomit[id] < get_pcvar_float( cvar_vomitcooldown ) )
	{
		static buffer[64]
		format(buffer, sizeof(buffer), "^x04[Bio]^x01 You need to wait for^x03 %.f0 ^x01seconds to ^x03Vomit^x01 again !!!", get_pcvar_float( cvar_vomitcooldown ) - ( get_gametime( ) - g_iLastVomit[ id ] ) )
		
		color_saytext(id, buffer)
		return PLUGIN_HANDLED
	}
	
	g_iLastVomit[ id ] = get_gametime( )
	
	new target, body, dist = get_pcvar_num( cvar_vomitdist )
	get_user_aiming( id, target, body, dist )
		
	new vec[ 3 ], aimvec[ 3 ], velocityvec[ 3 ]
	new length
	
	get_user_origin( id, vec )
	get_user_origin( id, aimvec, 2 )
	
	velocityvec[ 0 ] = aimvec[ 0 ] - vec[ 0 ]
	velocityvec[ 1 ] = aimvec[ 1 ] - vec[ 1 ]
	velocityvec[ 2 ] = aimvec[ 2 ] - vec[ 2 ]
	length = sqrt( velocityvec[ 0 ] * velocityvec[ 0 ] + velocityvec[ 1 ] * velocityvec[ 1 ] + velocityvec[ 2 ] * velocityvec[ 2 ] )
	velocityvec[ 0 ] = velocityvec[ 0 ] * 10 / length
	velocityvec[ 1 ] = velocityvec[ 1 ] * 10 / length
	velocityvec[ 2 ] = velocityvec[ 2 ] * 10 / length
	
	new args[ 8 ]
	args[ 0 ] = vec[ 0 ]
	args[ 1 ] = vec[ 1 ]
	args[ 2 ] = vec[ 2 ]
	args[ 3 ] = velocityvec[ 0 ]
	args[ 4 ] = velocityvec[ 1 ]
	args[ 5 ] = velocityvec[ 2 ]
	
	set_task( 0.1, "create_sprite", 0, args, 8, "a", 3 )
	
	emit_sound( id, CHAN_STREAM, vomit_sounds[ random_num( 0, 2 ) ], 1.0, ATTN_NORM, 0, PITCH_HIGH )
	
	if( is_valid_ent( target ) && is_user_alive( target ) && is_user_connected( target ) && !is_user_zombie(target) && get_entity_distance( id, target ) <= dist )
	{
		message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, target )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( 0x0004 )
		write_byte( 79 )
		write_byte( 180 )
		write_byte( 61 )
		write_byte( 255 )
		message_end( )
		
		if( get_pcvar_num( cvar_victimrender ) )
		{
			set_rendering( target, kRenderFxGlowShell, 79, 180, 61, kRenderNormal, 25 ) 
		}
		set_task( get_pcvar_float( cvar_wakeuptime ), "victim_wakeup", target )
		
		if( !get_pcvar_num(cvar_vomit_reward ) )
			return PLUGIN_HANDLED
			
		cs_set_user_money(id, cs_get_user_money(id) + get_pcvar_num(cvar_vomit_reward))
		
		static buffer[64]
		format(buffer, sizeof(buffer), "^x04[Bio]^x01 You've earned^x03 %i$^x01 for^x03 Vomiting^x01 on a human!", get_pcvar_num(cvar_vomit_reward))
		color_saytext(id, buffer)
	}
	return PLUGIN_HANDLED
}

public create_sprite( args[ ] )
{
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte( 120 )
	write_coord( args[ 0 ] )
	write_coord( args[ 1 ] )
	write_coord( args[ 2 ] )
	write_coord( args[ 3 ] )
	write_coord( args[ 4 ] )
	write_coord( args[ 5 ] )
	write_short( vomit )
	write_byte( 8 )
	write_byte( 70 )
	write_byte( 100 )
	write_byte( 5 )
	message_end( )
	
	return PLUGIN_CONTINUE
}

public victim_wakeup( id )
{
	if( !is_user_connected( id ) )
		return PLUGIN_HANDLED
	
	message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, id )
	write_short( ( 1<<12 ) )
	write_short( 0 )
	write_short( 0x0000 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 0 )
	write_byte( 255 )
	message_end( )
	
	if( get_pcvar_num( cvar_victimrender ) )
	{
		set_rendering( id )
	}
	return PLUGIN_HANDLED
}

public StopSpam_XD( id )
{
	if( is_user_connected( id ) )
	{	
		g_iHateSpam[ id ] = false
	}
}
public event_DeathMsg( )
{
	new id = read_data( 2 )
	
	if( !is_user_connected( id ) || !is_user_zombie( id ) || get_user_class( id ) != g_zclass_vomit )
		return PLUGIN_HANDLED
		
	emit_sound( id, CHAN_STREAM, explode_sounds[ random_num( 0, 2 ) ], 1.0, ATTN_NORM, 0, PITCH_HIGH )
	
	for( new i = 1; i <= g_iMaxPlayers; i ++ )
	{
		if( !is_valid_ent( i ) || !is_user_alive( i ) || !is_user_connected( i ) || is_user_zombie( i ) || get_entity_distance( id, i ) > get_pcvar_num( cvar_explodedist ) )
			return PLUGIN_HANDLED
			
		message_begin( MSG_ONE_UNRELIABLE, g_msgid_ScreenFade, _, i )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( get_pcvar_num( cvar_wakeuptime ) )
		write_short( 0x0004 )
		write_byte( 79 )
		write_byte( 180 )
		write_byte( 61 )
		write_byte( 255 )
		message_end( )
		
		if( get_pcvar_num( cvar_victimrender ) )
		{
			set_rendering( i, kRenderFxGlowShell, 79, 180, 61, kRenderNormal, 25 )
		}
		
		set_task( get_pcvar_float( cvar_wakeuptime ), "victim_wakeup", i )
		
		if( !get_pcvar_num( cvar_vomit_reward ) )
			return PLUGIN_HANDLED
			
		cs_set_user_money(id, cs_get_user_money(id) + (get_pcvar_num(cvar_vomit_reward) * i))
		
		static buffer[64]
		format(buffer, sizeof(buffer), "^x04[Bio]^x01 You've earned^x03 %i$^x01 for^x03 Exploding^x01 on^x03 %i ^x01humans!", ( get_pcvar_num( cvar_vomit_reward ) * i ), i )
		color_saytext(id, buffer)
	}
	return PLUGIN_HANDLED
}

public sqrt( num )
{
	new div = num
	new result = 1
	while( div > result )
	{
		div = ( div + result ) / 2
		result = num / div
	}
	return div
}


color_saytext(player, const message[], any:...)
{
	new text[301]
	format(text, 300, "%s", message)

	new dest
	if (player) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, get_user_msgid("SayText"), {0,0,0}, player)
	write_byte(1)
	write_string(check_text(text))
	return message_end()
}

check_text(text1[])
{
	new text[301]
	format(text, 300, "%s", text1)
	replace(text, 300, "/g", "^x04")
	replace(text, 300, "/r", "^x03")
	replace(text, 300, "/y", "^x01")
	return text
}
