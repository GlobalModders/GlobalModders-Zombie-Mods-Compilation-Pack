#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <fun>
#include <fakemeta_util>
#include <biohazard>
#include <engine>
#include <hamsandwich>

new Float:cl_pushangle[33][3]
new g_svd[33]
new g_m203_loaded[33]
new g_ammo[33]
/// new MaxPlayers
new g_MaxPlayers

//cvar for plugin
new cvar_knockback, cvar_speed, cvar_recoil, cvar_dmg_multi,cvar_trail, cvar_radius, cvar_damage, cvar_bonus, cvar_reload, cvar_remove, cvar_zoom
new cvar_m203_nade
//message :D
new g_msgDeathMsg
new g_msgScoreInfo
new gMsgID
new g_hasZoom[33]
// Explode spr
new m_iTrail;
// TRail of Grenade
new xplode;
new Float:zoom_delay[33]

//weapon model
new V_MODEL[64] = "models/biohazard/v_svdex.mdl"
new P_MODEL[64] = "models/biohazard/p_svdex.mdl"
new W_MODEL[64] = "models/biohazard/w_svdex.mdl"
new W_NADE[64] = "models/grenade.mdl"


#define ICON_HIDE 0
#define ICON_SHOW 1

// Weapon bitsums
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

const m_fInReload = 54

public plugin_init() {
	
	//register plugin ...
	register_plugin("[Bio] HERO Weapon: SvDex","1.13","Teobrvt1995")
	register_event("DeathMsg","player_die","abd")  
	register_event("CurWeapon","checkWeapon","be","1=1")
	register_event("HLTV", "event_newround", "1=0", "2=0")
	RegisterHam(Ham_Spawn, "player", "player_spawn", 1)
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage")
	
	//register m203 nade touch:D
	register_touch("m203_nade", "*", "m203_touch")
	
	//register forawrd
	register_forward(FM_CmdStart, "forward_CmdStart")
	register_forward(FM_SetModel, "forward_setmodel") 
	
	
	//nax player
	g_MaxPlayers = get_maxplayers()
	//register the cvar
	cvar_knockback = register_cvar("bh_svd_knock", "2")
	cvar_speed = register_cvar("bh_svd_speed", "3.0")
	cvar_recoil = register_cvar("bh_svd_recoil", "0.2")
	cvar_dmg_multi = register_cvar("bh_svd_dmg_multi", "2.5") 
	cvar_trail = register_cvar("bh_svd_trail","1") 
	cvar_radius = register_cvar("bh_svd_rad","300")  
	cvar_damage = register_cvar("bh_svd_dmg","1500") 
	cvar_bonus = register_cvar("bh_svd_bonus","2") 
	cvar_reload = register_cvar("bh_svd_reloadtime","3.0") 
	cvar_remove = register_cvar("bh_svd_remove","1") 
	cvar_zoom = register_cvar("bh_svd_zoom", "1")
	cvar_m203_nade = register_cvar("bh_svd_m203_amount", "5")
	//message for weapon
	g_msgDeathMsg = get_user_msgid("DeathMsg")
	g_msgScoreInfo = get_user_msgid ( "ScoreInfo" )
	gMsgID = get_user_msgid("StatusIcon")
	
	// for recoil and sound weapon :D
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_primary_attack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_primary_attack_post",1) 
	//when player are reloading...
	RegisterHam(Ham_Weapon_Reload, "weapon_ak47", "fw_weapon_reload")
	//enable pick up the weapon
	//RegisterHam(Ham_Item_AddToPlayer, "weapon_ak47", "fw_weapon_pickup")
	
}
//precache sound and model...
public plugin_precache()          
{
	m_iTrail = precache_model("sprites/smoke.spr")
	xplode = precache_model("sprites/biohazard/explode_nade.spr")
	precache_sound("weapons/svdex_shoot2.wav")
	precache_sound("weapons/svdex_exp.wav")
	precache_sound("weapons/svdex_shoot1.wav")
	precache_model(V_MODEL)
	precache_model(P_MODEL)
	precache_model(W_MODEL)
	precache_model(W_NADE)
	
}

public event_infect(id)   /// Forward when user is infected
{	
	if(g_svd[id])
		ammo_hud(id,0)
	g_svd[id] = false
	g_ammo[id] = 0
}

public event_last_human(id)
{
	drop_weapons(id, 1)
	drop_weapons(id, 2)
	
	get_svdex(id)
}

public event_newround(id)
{
	if(g_svd[id])
		ammo_hud(id,0)
		
	if(get_user_weapon(id) == CSW_AK47)
		drop_weapons(id, 1)
		
	g_svd[id] = false
	g_ammo[id] = 0
}

public client_connect(id)      
{
	g_svd[id] = 0
	g_m203_loaded[id] = 1
	g_ammo[id] = 0     
}

//death/...
public player_die(id)        
{
	if(g_svd[id])
		ammo_hud(id,0)
	g_ammo[id] = 0
	g_svd[id] = 0
	return PLUGIN_CONTINUE
}

//for recoil and sound...
public fw_primary_attack(ent)
{
	new id = pev(ent,pev_owner)
	pev(id,pev_punchangle,cl_pushangle[id])
	return HAM_IGNORED
}
public fw_primary_attack_post(ent)
{
	new id = pev(ent,pev_owner)
	new clip, ammo
	new weap = get_user_weapon( id, clip, ammo )
	if( weap == CSW_AK47 && g_svd[id])
	{
		new Float:push[3]
		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil),push)
		xs_vec_add(push,cl_pushangle[id],push)
		set_pev(id,pev_punchangle,push)
		if( clip > 0)
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, ent)
			emit_sound(id, CHAN_AUTO, "weapons/svdex_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}	
	
	return HAM_IGNORED
}

//when player reload ...
public fw_weapon_reload(ent)
{
	new id = pev(ent, pev_owner)
	new button = pev(id, pev_button)
	
	if(g_svd[id] && g_hasZoom[id] && button&IN_RELOAD)
	{
		g_hasZoom[id] = false
		cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
		
	}
	return HAM_IGNORED
}
//player pick up the weapon...
public fw_weapon_pickup(svd, id)
{
	if( is_valid_ent(svd) && is_user_connected(id) && entity_get_int(svd, EV_INT_impulse) == 1995)
	{
		// Update
		g_svd[id] = true
		ammo_hud(id, 1)
		
		// BP ammo
		cs_set_user_bpammo(id, CSW_AK47, 200)
		
		// Reset weapon options
		entity_set_int(svd, EV_INT_impulse, 0)
		
		return HAM_HANDLED
	}
	
	return HAM_IGNORED
}	

public player_spawn(id)    // When player is respawn (But it the same when roudn start...So I :P )
{
	if ( get_pcvar_num(cvar_remove) == 1 &&  g_svd[id] )
	{
		ammo_hud(id,0)
		g_svd[id] = false
		g_ammo[id] = 0		       
	}      	     
}
//set P and W model
public checkModel(id)
{
	if ( is_user_zombie(id) )
		return PLUGIN_HANDLED
	
	new g_weapon = read_data(2)
	
	if ( g_weapon == CSW_AK47 && g_svd[id])
	{
		set_pev(id, pev_viewmodel2, V_MODEL)
		set_pev(id, pev_weaponmodel2, P_MODEL)
	}
	return PLUGIN_HANDLED
}
public checkWeapon(id)
{
	new plrClip, plrAmmo, plrWeapId
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	
	if (plrWeapId == CSW_AK47 && g_svd[id])
	{
		checkModel(id)
		
		
		new Ent = get_weapon_ent(id,plrWeapId)
		new Float:N_Speed
		if(Ent) 
		{
			N_Speed = get_pcvar_float(cvar_speed)
			new Float:Delay = get_pdata_float( Ent, 46, 4) * N_Speed	
			if (Delay > 0.0) {
				set_pdata_float( Ent, 46, Delay, 4)
			}
		}
	}
	else 
	{
		return PLUGIN_CONTINUE
	}
	
	
	
	return PLUGIN_HANDLED
}

// Create W class for weapon :D
public forward_setmodel(Entity, const Model [])
{
	// Entity is not valid
	if (!is_valid_ent(Entity))
		return FMRES_IGNORED
	
	// Not ak47
	if(!equal(Model, "models/w_ak47.mdl")) 
		return FMRES_IGNORED;
	
	// Get classname
	static szClassName[33]
	entity_get_string(Entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	// Not a Weapon box
	if ( !equal ( szClassName, "weaponbox" ) )
		return FMRES_IGNORED
	
	// Some vars
	static iOwner, iStoredAkID
	
	// Get owner
	iOwner = entity_get_edict(Entity, EV_ENT_owner)
	
	// Get drop weapon index
	iStoredAkID = find_ent_by_owner(-1, "weapon_ak47", Entity)
	
	// Entity classname is weaponbox, and ak47 was founded
	if(g_svd[iOwner] && is_valid_ent(iStoredAkID))
	{
		// Setting weapon options
		entity_set_int(iStoredAkID, EV_INT_impulse, 1995)
		
		
		
		// Reset user vars
		g_svd [ iOwner ] = false
		ammo_hud(iOwner, 0)
		
		
		entity_set_model(Entity, W_MODEL)
		
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

//someone has bought our extra item...

public get_svdex(player)
{
	fm_give_item(player, "weapon_ak47")
	client_print(player, print_chat,"[BIO] You are HERO. You has got a SvDex")
	client_print(player, print_chat, "[BIO] Press key E to zoom and ATTACK2 to Launch m203 nade")
	g_svd[player] = true
	g_ammo[player] = get_pcvar_num(cvar_m203_nade)
	ammo_hud(player,1)
		
	cs_set_user_bpammo(player, CSW_AK47, 200)			 
}  

//when player press key Attack2 or E
public forward_CmdStart(id, uc_handle, seed)
{
	if(is_user_alive(id) && !is_user_zombie(id) && get_user_weapon(id) == CSW_AK47 && g_svd[id])
	{
		//set button , entity,...
		new button = get_uc(uc_handle, UC_Buttons)
		new ent = find_ent_by_owner(-1, "weapon_ak47", id)
		new fInReload = get_pdata_int(ent, m_fInReload, 4)
		//if player press Attack2...
		if(entity_get_int(id, EV_INT_button) & IN_ATTACK2)
		{
			//lauch it...
			launch_nade(id)
			return FMRES_IGNORED
		}
		//when player press key E 
		if (button & IN_USE)
		{
			set_pev(id, pev_button, button &~ IN_USE)
			//set zoom delay 
			if (get_gametime() - zoom_delay[id] >= 0.5  && !fInReload && get_pcvar_num(cvar_zoom))
			{
				//is zooming...
				if (g_hasZoom[id])
				{
					//erser it...
					g_hasZoom[id] = false
					cs_set_user_zoom(id, CS_RESET_ZOOM, 0)
				}
				else
				{
					g_hasZoom[id] = true
					cs_set_user_zoom(id, CS_SET_AUGSG552_ZOOM, 0)
				}
				zoom_delay[id] = get_gametime()
			}
		}
	}
	return FMRES_IGNORED
}

//dmg multipler
public fw_TakeDamage(victim, inflictor, attacker, Float:damage)
{
	if ( is_user_alive( attacker ) && get_user_weapon(attacker) == CSW_AK47 && g_svd[attacker] )
	{
		SetHamParamFloat(4, damage * get_pcvar_float( cvar_dmg_multi ) )
	}
}


//m203 fire...
public launch_nade(id)
{
	if(g_svd[id] == 0 || g_m203_loaded[id] == 0 || !(is_user_alive(id)))
		return PLUGIN_CONTINUE
	
	if(g_ammo[id] == 0)
	{
		client_print(id, print_center, "Out of Ammo !!!")
		return PLUGIN_CONTINUE
	}
	
	entity_set_int(id, EV_INT_weaponanim, 3)
	
	new Float: Origin[3], Float: Velocity[3], Float: vAngle[3], Ent
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	
	Origin[2] = Origin[2] + 10
	
	Ent = create_entity("info_target")
	
	if (!Ent) return PLUGIN_HANDLED
	
	//set weapon classname
	entity_set_string(Ent, EV_SZ_classname, "m203_nade")
	//set Nade model for weapon:D
	entity_set_model(Ent, W_NADE)
	
	//set size
	new Float:MinBox[3] = {-1.0, -1.0, -1.0}
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	//size
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)
	
	//set origin & vector...
	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)
	
	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 10)
	entity_set_edict(Ent, EV_ENT_owner, id)
	
	VelocityByAim(id, 2500 , Velocity)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	//sound when lauch...
	emit_sound(id,CHAN_VOICE,"weapons/svdex_shoot2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
	
	g_m203_loaded[id] = 0
	
	ammo_hud(id,0)
	g_ammo[id]--
	ammo_hud(id,1)
	
	new parm[1]
	parm[0] = Ent
	
	if(get_pcvar_num(cvar_trail))
		set_task(0.2, "grentrail",id,parm,1)
	
	parm[0] = id
	
	set_task(get_pcvar_float(cvar_reload), "m203_reload",id+9910,parm,1)
	client_print(id, print_center, "Reloading...")
	
	return PLUGIN_CONTINUE
}

public m203_reload(parm[])
{  
	g_m203_loaded[parm[0]] = 1
}
//when m203 nade touch something...
public m203_touch(Nade, Other)
{
	if(!pev_valid(Nade))
		return
	
	// Get it's origin
	static Float:origin[3]
	pev(Nade, pev_origin, origin)
	
	// Explosion
	engfunc ( EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, origin, 0)
	write_byte (TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, origin[0]) // Position X
	engfunc(EngFunc_WriteCoord, origin[1]) // Position Y
	engfunc(EngFunc_WriteCoord, origin[2]) // Position Z
	write_short (xplode) // Sprite index
	write_byte (40) // Scale
	write_byte (30) // Frame rate
	write_byte (0) // Flags
	message_end ()
	
	
	
	// Owner
	static owner  ; owner = pev(Nade, pev_owner)	
	
	// Make a loop
	for(new i = 1; i < g_MaxPlayers;i++)
	{
		//not alive
		if (!is_user_alive(i))
			continue
		
		// Godmode
		if (get_user_godmode(i) == 1)
			continue
		
		// Human/Survivor
		if (!is_user_zombie(i))
			continue
		
		// Get victims origin
		static Float:origin2 [3]
		pev(i, pev_origin, origin2)
		
		// Get distance between those origins
		static Float:distance_f ; distance_f = get_distance_f(origin, origin2)
		
		// Convert distnace to non-float
		static distance ; distance = floatround(distance_f)
		
		// Radius
		static radius ; radius = get_pcvar_num(cvar_radius)
		
		// We are in damage radius
		if ( distance <= radius )
		{
			
			// Max damage
			static maxdmg ; maxdmg = get_pcvar_num(cvar_damage)
			
			// Normal dmg
			new Damage
			Damage = maxdmg - floatround(floatmul(float(maxdmg), floatdiv(float(distance), float(radius))))
			
			//set damage when touch buy Ham ExecuteHamB(Ham_TakeDamage, victim, inflictor, attacker, Float:damage, damagebits)
			ExecuteHamB(Ham_TakeDamage, i, "grenade", owner,Damage, DMG_BLAST)
			//explode sound
			emit_sound(owner,CHAN_VOICE,"weapons/svdex_exp.wav", 1.0, ATTN_NORM, 0, PITCH_NORM) 
			
			// Calculate health
			new health = get_user_health(i)
			
			// We have at least 1 hp
			if(health - Damage >= 1)
			{
				// New health
				set_user_health(i, health - Damage) 
				make_knockback(i, origin, get_pcvar_float(cvar_knockback) * Damage)
			}
			else
			{
				// We must die
				death_message(owner,i,"grenade",1)
				
				// I hope they'll not find the bodies....
				origin2 [ 2 ] -= 45.0
			}
		}
	}
	
	// Breakable
	static ClassName[32]
	pev(Other, pev_classname, ClassName, charsmax(ClassName))
	if(equal(ClassName,"func_breakable"))
	{
		// Entity health
		static Float:health
		health = entity_get_float(Other, EV_FL_health)
		
		if (health <= get_pcvar_num(cvar_damage))
		{
			// Break it
			force_use(owner, Other)
		}
	}
	
	// Remove grenade
	engfunc(EngFunc_RemoveEntity, Nade)
}

// Death message
public death_message(Killer, Victim, const Weapon[], ScoreBoard)
{
	// Block death msg
	set_msg_block(g_msgDeathMsg, BLOCK_SET)
	ExecuteHamB(Ham_Killed, Victim, Killer, 2)
	set_msg_block(g_msgDeathMsg, BLOCK_NOT)
	
	// Death
	make_deathmsg(Killer, Victim, 0, Weapon)
	
	// Ammo packs
	cs_set_user_money(Killer, cs_get_user_money(Killer) + get_pcvar_num(cvar_bonus))
	
	// Update score board
	if ( ScoreBoard )
	{
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte( Killer ) // id
		write_short(pev(Killer, pev_frags)) // frags
		write_short(cs_get_user_deaths(Killer)) // deaths
		write_short(0) // class?
		write_short(get_user_team(Killer)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, g_msgScoreInfo)
		write_byte(Victim) // id
		write_short(pev(Victim, pev_frags)) // frags
		write_short(cs_get_user_deaths(Victim)) // deaths
		write_short(0) // class?
		write_short(get_user_team(Victim)) // team
		message_end()
	}
}

ammo_hud(id, sw)
{
	new s_sprite[33]
	format(s_sprite,32,"number_%d",g_ammo[id])

	if(sw)
	{		
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( ICON_SHOW ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 0 ) // red
		write_byte( 150 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
	else
	{
		message_begin( MSG_ONE, gMsgID, {0,0,0}, id )
		write_byte( ICON_HIDE ) // status
		write_string( s_sprite ) // sprite name
		write_byte( 0 ) // red
		write_byte( 150 ) // green
		write_byte( 0 ) // blue
		message_end()
	}
}

public grentrail(parm[])
{
	new gid = parm[0]
	
	if (gid) 
	{
		message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
		write_byte( TE_BEAMFOLLOW )
		write_short(gid) // entity
		write_short(m_iTrail)  // model
		write_byte( 10 )       // life
		write_byte( 5 )        // width
		write_byte( 255 )      // r, g, b
		write_byte( 255 )    // r, g, b
		write_byte( 255 )      // r, g, b
		write_byte( 100 ) // brightness
		
		message_end() // move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)
	}
}
//knock back...
public make_knockback ( Victim, Float:origin [ 3 ], Float:maxspeed )
{
	// Get and set velocity
	new Float:fVelocity[3];
	kickback ( Victim, origin, maxspeed, fVelocity)
	entity_set_vector( Victim, EV_VEC_velocity, fVelocity);
	
	return (1);
}

//stock...

stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	// who knows what wpnName will be
	static newName[24];
	
	// need to find the name
	if(wpnid) get_weaponname(wpnid,newName,23);
	
	// go with what we were told
	else formatex(newName,23,"%s",wpnName);
	
	// prefix it if we need to
	if(!equal(newName,"weapon_",7))
		format(newName,23,"weapon_%s",newName);
		
	return fm_find_ent_by_owner(get_maxplayers(),newName,id);
} 

stock kickback( ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3])
{
	// Find origin
	new Float:fEntOrigin[3];
	entity_get_vector( ent, EV_VEC_origin, fEntOrigin );
	
	// Do some calculations
	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0];
	fDistance[1] = fEntOrigin[1] - fOrigin[1];
	fDistance[2] = fEntOrigin[2] - fOrigin[2];
	new Float:fTime = (vector_distance( fEntOrigin,fOrigin ) / fSpeed);
	fVelocity[0] = fDistance[0] / fTime;
	fVelocity[1] = fDistance[1] / fTime;
	fVelocity[2] = fDistance[2] / fTime;
	
	return (fVelocity[0] && fVelocity[1] && fVelocity[2]);
}

stock drop_weapons(id, dropwhat, type=0)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if (get_weapon_type(weaponid) == dropwhat)
		{
			if (type==1)
			{
				fm_strip_user_gun(id, weaponid)
			}
			else
			{
				// Get weapon entity
				static wname[32], weapon_ent
				get_weaponname(weaponid, wname, charsmax(wname))
				weapon_ent = fm_find_ent_by_owner(-1, wname, id)
				
				// Hack: store weapon bpammo on PEV_ADDITIONAL_AMMO
				set_pev(weapon_ent, pev_iuser1, cs_get_user_bpammo(id, weaponid))
				
				// Player drops the weapon and looses his bpammo
				engclient_cmd(id, "drop", wname)
			}
		}
	}
}
get_weapon_type(weaponid)
{
	new type_wpn = 0
	if ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM) type_wpn = 1
	else if ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM) type_wpn = 2
	else if ((1<<weaponid) & NADE_WEAPONS_BIT_SUM) type_wpn = 4
	return type_wpn
}
