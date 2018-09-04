#include <amxmodx>
#include <fakemeta>
#include <biohazard>
#include <bio_shop>
#include <cstrike>

#define IGNORE_MONSTERS                 1
#define IGNORE_GLASS                    0x100

#define ION_RADIUS 	500.0
#define ION_MAXDAMAGE 	3500.0

new const WPN_NAME[]	=	"Ion Cannon"

new const W_MODEL[]	=		"models/w_battery.mdl"

new SOUND_APPROACH[]	=	"biohazard/ion_canon/approaching.wav"
new SOUND_START_PLANT[]	=	"biohazard/ion_canon/beacon_set.wav"
new SOUND_STOP[]	=		"vox/_comma.wav"
new SOUND_BEEP[]	=		"biohazard/ion_canon/beacon_beep.wav"
new SOUND_ATTACK[]	=		"biohazard/ion_canon/attack.wav"
new SOUND_READY[]	=		"biohazard/ion_canon/ready.wav"

new g_Target[33], i_Pitch[33]
new Float:i_BeaconTime[33]
new Float:ion_mid_origin[33][3]
new Float:beam_origin[33][8][3]
new Float:g_degrees[33][8]
new Float:g_distance[33]
new Float:ROTATION_SPEED[33]
new IonBeam, BlueFire, Shockwave, ReadyFire, BlueFlare, IonShake, LaserFlame

//---------------------------------------
new gItemID
new bool:gHasIon[33]
new const gCost = 16000	// Item Cost
new bool:bInUse[33]
new g_msgDeathMsg
//---------------------------------------
public plugin_init ()
{
	register_plugin ( "[Bio] Shop: Ion Cannon", "1.91", "A.F./ Makzz / Shidla" )
	
	register_event("HLTV", "event_infect", "a", "1=0", "2=0")
	
	gItemID		= bio_register_item(WPN_NAME, gCost, "An Attack by Satellite", TEAM_HUMAN )
	
	IonShake	= get_user_msgid ( "ScreenShake" )
	g_msgDeathMsg	= get_user_msgid("DeathMsg")
	
	register_forward ( FM_PlayerPreThink, "fw_PlayerPreThink" )
}

public client_connect(id)
{
	g_Target[id] = 0
	gHasIon[id] = false
}

public plugin_precache ()
{
	precache_model ( W_MODEL )
	precache_sound ( SOUND_APPROACH )
	precache_sound ( SOUND_START_PLANT )
	precache_sound ( SOUND_BEEP )
	precache_sound ( SOUND_ATTACK )
	precache_sound ( SOUND_READY )
	precache_sound ( SOUND_STOP )
	
	
	IonBeam		= precache_model("sprites/biohazard/ion_canon/ionbeam.spr")
	BlueFlare	= precache_model("sprites/biohazard/ion_canon/bflare.spr")
	ReadyFire	= precache_model("sprites/biohazard/ion_canon/fire.spr")
	BlueFire	= precache_model("sprites/biohazard/ion_canon/blueflame.spr")
	LaserFlame	= precache_model("sprites/biohazard/ion_canon/ion_laserflame.spr")
	Shockwave	= precache_model("sprites/shockwave.spr")
}

public ion_planted ( id )
{
	id -= 5000
	client_printc(id, "!g[Bio]!n Ion Cannon beacon !tDeploy!n !!!" )
	
	g_Target[id] = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	if(!g_Target[id])
		return
	
	set_pev(g_Target[id],pev_classname,"info_target_ion")
	engfunc(EngFunc_SetModel,g_Target[id],W_MODEL)
	
	set_pev(g_Target[id],pev_owner, id)
	set_pev(g_Target[id],pev_movetype, MOVETYPE_TOSS)
	set_pev(g_Target[id],pev_solid, SOLID_TRIGGER)
	
	wpn_projectile_startpos(id,0,0,50,ion_mid_origin[id])
	set_pev(g_Target[id],pev_origin,ion_mid_origin[id])
	
	ion_beacon(id)
	//set_task(5.0,"ion_startup", id)
	set_task ( 25.0, "Trace_Ready", id )
}

public ion_beacon ( id )
{
	if ( !g_Target[id] )
		return
	
	i_Pitch[id] += 3
	i_BeaconTime[id] -= 0.03
	if(i_Pitch[id] > 255)
		i_Pitch[id] = 255
	
	if(i_BeaconTime[id] < 0.30)
		i_BeaconTime[id] = 0.30
	
	emit_sound(g_Target[id], CHAN_ITEM, SOUND_BEEP, VOL_NORM, ATTN_NORM, 0, i_Pitch[id])
	set_task(i_BeaconTime[id],"ion_beacon", id)
}

public Trace_Ready(id)
{
	remove_task(id)
	// write origin of each
	new Float:mid_origin[33][3]
	pev(g_Target[id],pev_origin,mid_origin[id]) // Target contain entity id
	// 1st
	beam_origin[id][0][0] = mid_origin[id][0] + 300.0
	beam_origin[id][0][1] = mid_origin[id][1] + 150.0
	beam_origin[id][0][2] = mid_origin[id][2]
	g_degrees[id][0] = 0.0
	// 2nd
	beam_origin[id][1][0] = mid_origin[id][0] + 300.0
	beam_origin[id][1][1] = mid_origin[id][1] - 150.0
	beam_origin[id][1][2] = mid_origin[id][2]
	g_degrees[id][1] = 45.0
	// 3rd 
	beam_origin[id][2][0] = mid_origin[id][0] - 300.0
	beam_origin[id][2][1] = mid_origin[id][1] - 150.0
	beam_origin[id][2][2] = mid_origin[id][2]
	g_degrees[id][2] = 90.0
	// 4th 
	beam_origin[id][3][0] = mid_origin[id][0] - 300.0
	beam_origin[id][3][1] = mid_origin[id][1] + 150.0
	beam_origin[id][3][2] = mid_origin[id][2]
	g_degrees[id][3] = 135.0
	// 5th 
	beam_origin[id][4][0] = mid_origin[id][0] + 150.0
	beam_origin[id][4][1] = mid_origin[id][1] + 300.0
	beam_origin[id][4][2] = mid_origin[id][2]
	g_degrees[id][4] = 180.0
	// 6th 
	beam_origin[id][5][0] = mid_origin[id][0] + 150.0
	beam_origin[id][5][1] = mid_origin[id][1] - 300.0
	beam_origin[id][5][2] = mid_origin[id][2]
	g_degrees[id][5] = 225.0
	// 7th 
	beam_origin[id][6][0] = mid_origin[id][0] - 150.0
	beam_origin[id][6][1] = mid_origin[id][1] - 300.0
	beam_origin[id][6][2] = mid_origin[id][2]
	g_degrees[id][6] = 270.0
	// 8th 
	beam_origin[id][7][0] = mid_origin[id][0] - 150.0
	beam_origin[id][7][1] = mid_origin[id][1] + 300.0
	beam_origin[id][7][2] = mid_origin[id][2]
	g_degrees[id][7] = 315.0
	
	// set the mid to global
	ion_mid_origin[id] = mid_origin[id]

	new Float:addtime
	for(new i; i < 8; i++) {
		addtime = addtime + 0.3
		new param[3]
		param[0] = i
		param[1] = id
		set_task(0.0 + addtime, "Trace_Start", _,param, 2)
	}

	Laser_Rotate(id) //To fix the laserdraw
	
	emit_sound ( g_Target[id], CHAN_ITEM, SOUND_READY, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	for(new Float:i = 0.0; i < 7.5; i += 0.01) //Rotate for 7.5 secs.
		set_task(i+3.0, "Laser_Rotate", id)

	set_task(2.9,"AddSpeed", id)
	set_task(11.5,"CreateFire", id)
	set_task(12.5,"ClearLasers", id)
	set_task(15.2,"FireIonCannon", id)
	return PLUGIN_CONTINUE
}

public AddSpeed(id) {
	if(!g_Target[id]) return PLUGIN_CONTINUE
	
	if(ROTATION_SPEED[id] > 1.0) ROTATION_SPEED[id] = 1.0
	ROTATION_SPEED[id] += 0.1
	set_task(0.6,"AddSpeed", id)
	return PLUGIN_CONTINUE
}

public CreateFire(id) {
	if(!g_Target[id]) return PLUGIN_CONTINUE

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ion_mid_origin[id], 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0])
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1])
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2] + 100)
	write_short(ReadyFire)
	write_byte(30)
	write_byte(200)
	message_end()

	set_task(1.5,"CreateFire", id)
	return PLUGIN_CONTINUE
}

public event_infect(id)
{
	//ResetAll(id)
	
	gHasIon[id] = false
	bInUse[id] = false
	emit_sound(g_Target[id], CHAN_WEAPON, SOUND_STOP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ProgressBar(id, 0, 0)
	remove_task(id+5000)
}

public ClearLasers(id)
	remove_task(1018+id)

public Laser_Rotate(id)
{
	g_distance[id] -= 0.467
	for(new i; i < 8; i++) {
		// Calculate new alpha
		g_degrees[id][i] += ROTATION_SPEED[id]
		if(g_degrees[id][i] > 360.0)
			g_degrees[id][i] -= 360.0

		// calcul the next origin
		new Float:tmp[33][3]
		tmp[id] = ion_mid_origin[id]

		tmp[id][0] += floatsin(g_degrees[id][i], degrees) * g_distance[id]
		tmp[id][1] += floatcos(g_degrees[id][i], degrees) * g_distance[id]
		tmp[id][2] += 0.0 // -.-
		beam_origin[id][i] = tmp[id]
	}
}

public Trace_Start(param[]) {
	new i = param[0]
	new id = param[1]

	new Float:get_random_z,Float:SkyOrigin[33][3]
	SkyOrigin[id] = tlx_distance_to_sky(g_Target[id])
	get_random_z = random_float(300.0,SkyOrigin[id][2])

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, beam_origin[id][i], 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][0])
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][1])
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][2] + get_random_z)
	write_short(BlueFire)
	write_byte(10)
	write_byte(100)
	message_end()
	
	TraceAll(param)
}

public TraceAll(param[]) {
	new i = param[0]
	new id = param[1]

	new Float:SkyOrigin[33][3]
	SkyOrigin[id] = tlx_distance_to_sky(g_Target[id])
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, beam_origin[id][i], 0)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][0])		//start point (x)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][1])		//start point (y)
	engfunc(EngFunc_WriteCoord, SkyOrigin[id][2])			//start point (z)

	engfunc(EngFunc_WriteCoord, beam_origin[id][i][0])		//end point (x)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][1])		//end point (y)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][2])		//end point (z)
	write_short(IonBeam)	//model
	write_byte(0)		//startframe
	write_byte(0)		//framerate
	write_byte(1)		//life
	write_byte(50)		//width
	write_byte(0)		//noise
	write_byte(255)		//r
	write_byte(255)		//g
	write_byte(255)		//b
	write_byte(255)		//brightness
	write_byte(0)		//speed
	message_end()
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, beam_origin[id][i], 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][0])
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][1])
	engfunc(EngFunc_WriteCoord, beam_origin[id][i][2])
	write_short(LaserFlame)
	write_byte(5)
	write_byte(200)
	message_end()
	
	set_task(0.08,"TraceAll", 1018+id, param, 2)
}

public FireIonCannon(id) {
	new i = -1
	while((i = engfunc(EngFunc_FindEntityInSphere, i, ion_mid_origin[id], ION_RADIUS + 8000)) != 0)
	{
		if(pev_valid(i) && pev(i, pev_flags) & (FL_CLIENT | FL_FAKECLIENT)) {
			message_begin(MSG_ONE_UNRELIABLE, IonShake, {0,0,0}, i)
			write_short(255<<14) //ammount
			write_short(10<<14) //lasts this long
			write_short(255<<14) //frequency
			message_end()
		}
		//next player in spehre.
		continue
	}

	new Float:skyOrigin[33][3]
	skyOrigin[id] = tlx_distance_to_sky(g_Target[id])

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ion_mid_origin[id], 0)
	write_byte(TE_BEAMPOINTS) 
	engfunc(EngFunc_WriteCoord, skyOrigin[id][0])	//start point (x)
	engfunc(EngFunc_WriteCoord, skyOrigin[id][1])	//start point (y)
	engfunc(EngFunc_WriteCoord, skyOrigin[id][2])	//start point (z)

	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0])		//end point (x)
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1])		//end point (y)
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2])		//end point (z)
	write_short(IonBeam)	//model
	write_byte(0)		//startframe
	write_byte(0)		//framerate
	write_byte(15)		//life
	write_byte(255)		//width
	write_byte(0)		//noise
	write_byte(255)		//r
	write_byte(255)		//g
	write_byte(255)		//b
	write_byte(255)		//brightness
	write_byte(0)		//speed
	message_end()

	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ion_mid_origin, 0)
	write_byte(TE_BEAMCYLINDER)
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0]) // start X
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1]) // start Y
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2]) // start Z

	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0]) // something X
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1]) // something Y
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2] + ION_RADIUS - 1000.0) // something Z
	write_short(Shockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(100) // life
	write_byte(150) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(100) // green
	write_byte(250) // blue
	write_byte(150) // brightness
	write_byte(0) // speed
	message_end()

	for(new i = 1; i < 6; i++) {
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ion_mid_origin[id], 0)
		write_byte(TE_SPRITETRAIL)	// line of moving glow sprites with gravity, fadeout, and collisions
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0])
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1])
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2])
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0])
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1])
		engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2] + 200)
		write_short(BlueFlare) // (sprite index)
		write_byte(50) // (count)
		write_byte(random_num(27,30)) // (life in 0.1's)
		write_byte(10) // byte (scale in 0.1's)
		write_byte(random_num(30,70)) // (velocity along vector in 10's)
		write_byte(40) // (randomness of velocity in 10's)
		message_end()
	}
	
	// A ring effect
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, ion_mid_origin[id], 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0]) // x
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1]) // y
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2]) // z
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][0]) // x axis
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][1]) // y axis
	engfunc(EngFunc_WriteCoord, ion_mid_origin[id][2] + ION_RADIUS) // z axis
	write_short(Shockwave) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(10) // life
	write_byte(25) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(206) // green
	write_byte(209) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	wpn_radius_damage(g_Target[id], ION_RADIUS, ION_MAXDAMAGE )
		
	emit_sound (g_Target[id], CHAN_ITEM, SOUND_ATTACK, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
	
	ResetAll(id)
}

ResetAll(id)
{
	set_pev(g_Target[id], pev_flags, FL_KILLME )
	g_Target[id] = 0
	gHasIon[id] = false
}

/******************** Stocks ********************/
stock Float:tlx_distance_to_sky(id) // Get entity above sky.
{
	new Float:TraceEnd[3]
	pev(id, pev_origin, TraceEnd)

	new Float:f_dest[3]
	f_dest[0] = TraceEnd[0]
	f_dest[1] = TraceEnd[1]
	f_dest[2] = TraceEnd[2] + 8192.0

	new res, Float:SkyOrigin[3]
	engfunc(EngFunc_TraceLine, TraceEnd, f_dest, IGNORE_MONSTERS + IGNORE_GLASS, id, res)
	get_tr2(res, TR_vecEndPos, SkyOrigin)

	return SkyOrigin
}
//return distance above us to sky
stock Float:is_user_outside(id) {
	new Float:origin[3], Float:dist

	pev(id, pev_origin, origin)
	dist = origin[2]

	while(engfunc(EngFunc_PointContents, origin) == CONTENTS_EMPTY)
		origin[2] += 5.0 
	if(engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY)
		return (origin[2] - dist)

	return 0.0
}

stock ProgressBar(id, seconds, position)
{
	message_begin(MSG_ONE, get_user_msgid("BarTime"), {0, 0, 0}, id)
	write_byte(seconds)
	write_byte(position)
	message_end()
}

public bio_item_selected( id, itemid )
{
	if ( itemid == gItemID )
	{
		if ( gHasIon[id] ) // Уже есть это оружие
		{ // Так что надо деньжат вернуть
			cs_set_user_money( id, cs_get_user_money ( id ) + gCost )
			client_printc(id, "!g[Bio]!n You already have a !t%s!n !!!", WPN_NAME )
		}
		else 
		{
			gHasIon[id] = true
			
			emit_sound ( id, CHAN_WEAPON, "items/gunpickup2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM )
			
			client_printc(id, "!g[Bio]!n You now have a !t%s!n !!!", WPN_NAME )
			client_printc(id, "!g[Bio]!n Press !t(E)!n to !tDeploy!n it !!!")
		}
	}
}

public fw_PlayerPreThink ( id )
{
	if ( !gHasIon[id] || !is_user_alive ( id ) )
		return FMRES_IGNORED
	
	if ( pev ( id, pev_button ) & IN_USE )
	{
		if ( !bInUse[id] )
		{
			bInUse[id] = true
			if ( g_Target[id] ) // Уже поставил
			{
				client_printc(id, "!g[Bio]!n You already !tPlanted a Beacon!n !!!" )
				return FMRES_IGNORED
			}
			else if ( is_user_outside ( id ) ) // Вне помещения
			{
				g_Target[id] = 0
				i_Pitch[id] = 97
				i_BeaconTime[id] = 1.12
				g_distance[id] = 350.0
				ROTATION_SPEED[id] = 0.0
				
				emit_sound ( id, CHAN_WEAPON, SOUND_START_PLANT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM )
				
				ProgressBar ( id, 5, 0 )
				set_task ( 5.0,"ion_planted", id+5000 )
			}
			else
			{
				client_printc(id, "!g[Bio]!n You need to be !tOutside!n to !tFire!n with an !tIon Cannon!n !!!" )
			}
		}
	}
	else if ( bInUse[id] )
	{
		bInUse[id] = false
		emit_sound(g_Target[id], CHAN_WEAPON, SOUND_STOP, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		ProgressBar ( id, 0, 0 )
		remove_task(id+5000)
	}
	return FMRES_IGNORED
}

wpn_projectile_startpos ( player, forw, right, up, Float:out[3] )
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3],
	Float:vRight[3], Float:vUp[3]//, Float:vSrc[3]
	
	pev(player, pev_origin, vOrigin)
	pev(player, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	out[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	out[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	out[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
	
	//set_array_f(5, vSrc, 3)
}

stock wpn_radius_damage ( inflictor, Float:radius, Float:damage )
{
	new Float:vecSrc[3]
	pev(inflictor, pev_origin, vecSrc)
	
	new ent = -1
	new Float:tmpdmg = damage
	new hitCount = 0
	new Float:kickback = 1.0
	
	new Float:Tabsmin[3], Float:Tabsmax[3], Float:vecSpot[3],
	Float:Aabsmin[3], Float:Aabsmax[3], Float:vecSee[3]
	new trRes
	new Float:flFraction
	new Float:vecEndPos[3]
	new Float:distance
	new Float:origin[3], Float:vecPush[3]
	new Float:invlen
	new Float:velocity[3]
	
	// Calculate falloff
	new Float:falloff
	if (radius > 0.0)
		falloff = damage / radius
	else
		falloff = 1.0
	
	// Find monsters and players inside a specifiec radius
	while((ent = engfunc(EngFunc_FindEntityInSphere, ent, vecSrc, radius)) != 0)
	{
		if(!pev_valid(ent))
			continue
		if(!(pev(ent, pev_flags) & (FL_CLIENT | FL_FAKECLIENT | FL_MONSTER)))
			continue // Entity is not a player or monster, ignore it
		
		tmpdmg = damage
		
		// The following calculations are provided by Orangutanz, THANKS!
		// We use absmin and absmax for the most accurate information
		pev(ent, pev_absmin, Tabsmin)
		pev(ent, pev_absmax, Tabsmax)
		vecSpot[0] = (Tabsmin[0] + Tabsmax[0]) * 0.5
		vecSpot[1] = (Tabsmin[1] + Tabsmax[1]) * 0.5
		vecSpot[2] = (Tabsmin[2] + Tabsmax[2]) * 0.5
		
		pev(inflictor, pev_absmin, Aabsmin)
		pev(inflictor, pev_absmax, Aabsmax)
		vecSee[0] = (Aabsmin[0] + Aabsmax[0]) * 0.5
		vecSee[1] = (Aabsmin[1] + Aabsmax[1]) * 0.5
		vecSee[2] = (Aabsmin[2] + Aabsmax[2]) * 0.5
		
		engfunc(EngFunc_TraceLine, vecSee, vecSpot, 0, inflictor, trRes)
		get_tr2(trRes, TR_flFraction, flFraction)
		// Explosion can 'see' this entity, so hurt them! (or impact through objects has been enabled xD)
		if (flFraction >= 0.9 || get_tr2(trRes, TR_pHit) == ent)
		{
			// Work out the distance between impact and entity
			get_tr2(trRes, TR_vecEndPos, vecEndPos)

			distance = get_distance_f(vecSrc, vecEndPos) * falloff
			tmpdmg -= distance
			if (tmpdmg < 0.0)
				tmpdmg = 0.0
			
			origin[0] = vecSpot[0] - vecSee[0]
			origin[1] = vecSpot[1] - vecSee[1]
			origin[2] = vecSpot[2] - vecSee[2]
			
			invlen = 1.0/get_distance_f(vecSpot, vecSee)
			vecPush[0] = origin[0] * invlen
			vecPush[1] = origin[1] * invlen
			vecPush[2] = origin[2] * invlen

			pev(ent, pev_velocity, velocity)
			velocity[0] = velocity[0] + vecPush[0] * tmpdmg * kickback
			velocity[1] = velocity[1] + vecPush[1] * tmpdmg * kickback
			velocity[2] = velocity[2] + vecPush[2] * tmpdmg * kickback

			if (tmpdmg < 60.0)
			{
				velocity[0] *= 12.0
				velocity[1] *= 12.0
				velocity[2] *= 12.0
			}
			else
			{
				velocity[0] *= 4.0
				velocity[1] *= 4.0
				velocity[2] *= 4.0
			}
			set_pev(ent, pev_velocity, velocity)
		}
		// Send info to Damage system
		if(damage_user(ent, inflictor, floatround(tmpdmg)))
		{
			hitCount++
		}
	}
	
	return hitCount
}

damage_user(victim, attacker, dmg_take)
{
	if(!is_user_zombie(victim))
		return PLUGIN_HANDLED
	
	new flags = pev(victim, pev_flags)
	new Float:takeDamage
	pev(victim, pev_takedamage, takeDamage)
	
	
	if(flags & FL_GODMODE || takeDamage == 0.0)
		return 0 // Player/Monster got godmode, ignore it
	
	if(flags & (FL_CLIENT | FL_FAKECLIENT))
	{ // The victim's definetely a player, do a check for team attack
		if(is_team_attack(attacker, victim))
		{
			// User's attacking someone from the same team, friendlyfire's disabled
			// and it's a templay game. So don't do any damage :)
			return 0
		}
		else if(!is_user_alive(victim))
			return 0 // Victim is not alive, ignore him
	}
	// Calculate remaining health after causing the damage
	new Float:health
	pev(victim, pev_health, health)
	if(health <= 0.0)
		return 0 // No more health, player or monster's already dead, ignore it
	
	health -= float(dmg_take)
	
	set_pev(victim, pev_dmg_inflictor, attacker) // Let other things (e.g. plugins) know, who attacked this player
	
	if(health > 0) // Player or monster doesn't die after causing the damage, so just decrease his health
		set_pev(victim, pev_health, health)
	else
	{
		kill_user(victim, attacker) // Player or monster dies after causing damage, so kill him 8)
		dmg_take = -1
	}
	
	return dmg_take
}

kill_user(victim, attacker)
{
	new flags = pev(victim, pev_flags)
	new bool:isVictimMonster = (flags & FL_MONSTER) ? true : false
	new Float:takeDamage
	pev(victim, pev_takedamage, takeDamage)
	
	if(flags & FL_GODMODE || takeDamage == 0.0) // We do not cause any damage if the victim has godemode
		return 0
	
	if(!isVictimMonster)
	{
		if(is_team_attack(attacker, victim)) // Team attack with disabled friendly fire on a teamplay game, what the hell we're doing here?
			return 0
	}
	
	new weapon[11] = "ion_cannon"
	
	// Kill Victim
	if(isVictimMonster)
	{
		// Monster
		// set_pev(victim, pev_flags, FL_KILLME)
		set_pev(victim, pev_health, -1)
	}
	else
	{ // Player
		set_msg_block(g_msgDeathMsg, BLOCK_ONCE)
		user_kill(victim, 1)
	}
	
	new Float:frags
	pev(attacker, pev_frags, frags)
	frags++
	
	set_pev(attacker, pev_frags, frags)
	
	if(isVictimMonster)
		return 1 // If the player killed a monster, we shouldn't continue on here
	
	new aname[32], aauthid[32], ateam[10]
	get_user_name(attacker, aname, 31)
	get_user_team(attacker, ateam, 9)
	get_user_authid(attacker, aauthid, 31)
	
 	if(attacker != victim) 
	{
 		new vname[32], vauthid[32], vteam[10]
		get_user_name(victim, vname, 31)
		get_user_team(victim, vteam, 9)
		get_user_authid(victim, vauthid, 31)
		
		// Log the kill information
		log_message("^"%s<%d><%s><%s>^" killed ^"%s<%d><%s><%s>^" with ^"%s^"", 
			aname, get_user_userid(attacker), aauthid, ateam, 
		 	vname, get_user_userid(victim), vauthid, vteam, weapon)
	} else {
		// User killed himself xD
		log_message("^"%s<%d><%s><%s>^" committed suicide with ^"%s^"", 
			aname, get_user_userid(attacker), aauthid, ateam, weapon)
	}
	return 1
}

bool:is_team_attack(attacker, victim)
{
	if(!(pev(victim, pev_flags) & (FL_CLIENT | FL_FAKECLIENT)))
		return false // Victim is a monster, so definetely no team attack ;)
	
	if(get_user_team(victim) == get_user_team(attacker))
		return true // Team attack
	
	return false // No team attack or friendlyfire is disabled
}

client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
	write_byte(index);
	write_string(szMsg);
	message_end();
}  
