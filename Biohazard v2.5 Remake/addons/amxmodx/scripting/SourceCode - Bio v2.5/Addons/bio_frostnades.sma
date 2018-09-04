#include <amxmodx>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <biohazard>
#include <fun>
	
new const VERSION[] = "1.0 - Bio";

#define AMMO_FLASHBANG		11
#define AMMO_HEGRENADE		12
#define AMMO_SMOKEGRENADE	13
#define OFFSET_SHIELD		510
#define HAS_SHIELD		(1<<24)
#define USING_SHIELD		(1<<16)
#define DMG_GRENADE		(1<<24) // thanks arkshine
#define FFADE_IN			0x0000 // just here so we don't pass 0 into the function
#define BREAK_GLASS		0x01

#define GLOW_AMOUNT		1.0
#define FROST_RADIUS		240.0
#define NT_FLASHBANG		(1<<0) // 1; CSW:25
#define NT_HEGRENADE		(1<<1) // 2; CSW:4
#define NT_SMOKEGRENADE		(1<<2) // 4; CSW:9
#define ICON_HASNADE		1
#define ICON_ISCHILLED		2
#define TASK_REMOVE_CHILL	100
#define TASK_REMOVE_FREEZE	200
#define TASK_NADE_EXPLODE	300
	
new pcv_enabled, pcv_override, pcv_nadetypes, pcv_color, pcv_icon, pcv_hitself, pcv_los,
pcv_maxdamage, pcv_mindamage, pcv_chill_duration, pcv_chill_variance, pcv_chill_speed,
pcv_freeze_duration, pcv_freeze_variance

new maxPlayers, gmsgCurWeapon, gmsgSetFOV, gmsgScreenFade, gmsgStatusIcon,
glassGibs, trailSpr, smokeSpr, exploSpr, czero, bot_quota, czBotHams, fwdPPT, freezetime;

new isChilled[33], isFrozen[33], frostKilled[33], novaDisplay[33], Float:glowColor[33][3], Float:oldGravity[33], oldRenderFx[33], Float:chillySpeed[33],
Float:oldRenderColor[33][3], oldRenderMode[33], Float:oldRenderAmt[33], hasFrostNade[33], nadesBought[33], Float:flashOver[33], lastWeapon[33];

public plugin_init()
{
	register_plugin("[Bio] Addon: FrostNades",VERSION,"Avalanche");
	register_cvar("fn_version",VERSION,FCVAR_SERVER);

	pcv_enabled = register_cvar("fn_enabled","1");
	pcv_override = register_cvar("fn_override","1");
	pcv_nadetypes = register_cvar("fn_nadetypes","1"); // NT_SMOKEGRENADE
	pcv_color = register_cvar("fn_color","0 206 209");
	pcv_icon = register_cvar("fn_icon","1");

	pcv_hitself = register_cvar("fn_hitself","0");
	pcv_los = register_cvar("fn_los","1");
	pcv_maxdamage = register_cvar("fn_maxdamage","0.0");
	pcv_mindamage = register_cvar("fn_mindamage","0.0");
	pcv_chill_duration = register_cvar("fn_chill_duration","7.0");
	pcv_chill_variance = register_cvar("fn_chill_variance","1.0");
	pcv_chill_speed = register_cvar("fn_chill_speed","60.0");
	pcv_freeze_duration = register_cvar("fn_freeze_duration","4.0");
	pcv_freeze_variance = register_cvar("fn_freeze_variance","0.5");
	
	new mod[6];
	get_modname(mod,5);
	if(equal(mod,"czero"))
	{
		czero = 1;
		bot_quota = get_cvar_pointer("bot_quota");
	}
	
	maxPlayers = get_maxplayers();
	gmsgCurWeapon = get_user_msgid("CurWeapon");
	gmsgSetFOV = get_user_msgid("SetFOV");
	gmsgScreenFade = get_user_msgid("ScreenFade");
	gmsgStatusIcon = get_user_msgid("StatusIcon");

	register_event("ScreenFade","event_flashed","be","4=255","5=255","6=255","7>199"); // hit by a flashbang

	register_forward(FM_SetModel,"fw_setmodel",1);
	register_message(get_user_msgid("DeathMsg"),"msg_deathmsg");

	register_event("SetFOV","event_setfov","b");
	register_event("CurWeapon","event_curweapon","b","1=1");
	register_event("AmmoX","event_ammox","b","1=11","1=12","1=13"); // flash, HE, smoke
		
	register_event("HLTV","event_new_round","a","1=0","2=0");
	register_logevent("logevent_round_start",2,"1=Round_Start");

	RegisterHam(Ham_Spawn,"player","ham_player_spawn",1);
	RegisterHam(Ham_Killed,"player","ham_player_killed",1);
	RegisterHam(Ham_Think,"grenade","ham_grenade_think",0);
}

public plugin_precache()
{
	precache_model("models/frostnova.mdl");
	glassGibs = precache_model("models/glassgibs.mdl");

	precache_sound("warcraft3/frostnova.wav"); // grenade explodes
	precache_sound("warcraft3/impalehit.wav"); // player is frozen
	precache_sound("warcraft3/impalelaunch1.wav"); // frozen wears off
	precache_sound("player/pl_duct2.wav"); // player is chilled
	precache_sound("items/gunpickup2.wav"); // player buys frostnade

	trailSpr = precache_model("sprites/laserbeam.spr");
	smokeSpr = precache_model("sprites/steam1.spr");
	exploSpr = precache_model("sprites/shockwave.spr");
}

public client_putinserver(id)
{
	isChilled[id] = 0;
	isFrozen[id] = 0;
	frostKilled[id] = 0;
	novaDisplay[id] = 0;
	hasFrostNade[id] = 0;
	chillySpeed[id] = 0.0;
	
	if(czero && !czBotHams && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
		set_task(0.1,"czbot_hook_ham",id);
}

public client_disconnect(id)
{
	if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
}

// registering a ham hook for "player" won't register it for CZ bots,
// for some reason. so we have to register it by entity. 
public czbot_hook_ham(id)
{
	if(!czBotHams && is_user_connected(id) && is_user_bot(id) && get_pcvar_num(bot_quota) > 0)
	{
		RegisterHamFromEntity(Ham_Spawn,id,"ham_player_spawn",1);
		RegisterHamFromEntity(Ham_Killed,id,"ham_player_killed",1);
		czBotHams = 1;
	}
}

/****************************************
* PRIMARY FUNCTIONS AND SUCH
****************************************/
// the round ends or starts
public event_round_change()
{
	if(!get_pcvar_num(pcv_enabled)) return;

	for(new i=1;i<=maxPlayers;i++)
	{
		if(is_user_alive(i))
		{
			if(isChilled[i]) task_remove_chill(TASK_REMOVE_CHILL+i);
			if(isFrozen[i]) task_remove_freeze(TASK_REMOVE_FREEZE+i);
		}
	}
}

// the round ends
public event_round_end()
{
	if(!get_pcvar_num(pcv_enabled)) return;

	for(new i=1;i<=maxPlayers;i++)
	{
		if(is_user_alive(i))
		{
			if(isChilled[i]) task_remove_chill(TASK_REMOVE_CHILL+i);
			if(isFrozen[i]) task_remove_freeze(TASK_REMOVE_FREEZE+i);
		}
	}
}

// flashbanged
public event_flashed(id)
{
	// remember end of flashbang
	flashOver[id] = get_gametime() + (float(read_data(1)) / 4096.0);
}

public fw_setmodel(ent,model[])
{
	if(!get_pcvar_num(pcv_enabled)) return FMRES_IGNORED;

	new owner = pev(ent,pev_owner);
	if(!is_user_connected(owner)) return FMRES_IGNORED;
	
	// this isn't going to explode
	new Float:dmgtime;
	pev(ent,pev_dmgtime,dmgtime);
	if(dmgtime == 0.0) return FMRES_IGNORED;
	
	new type, csw;
	if(model[7] == 'w' && model[8] == '_')
	{
		switch(model[9])
		{
			case 'h': { type = NT_HEGRENADE; csw = CSW_HEGRENADE; }
			case 'f': { type = NT_FLASHBANG; csw = CSW_FLASHBANG; }
			case 's': { type = NT_SMOKEGRENADE; csw = CSW_SMOKEGRENADE; }
		}
	}
	if(!type) return FMRES_IGNORED;
	
	new team = _:cs_get_user_team(owner);

	// have a frostnade (override off) ;OR; override enabled, on valid team, using valid frostnade type
	if(hasFrostNade[owner] == csw ||
	(get_pcvar_num(pcv_override) && (get_pcvar_num(pcv_nadetypes) & type)))
	{
		hasFrostNade[owner] = 0;

		set_pev(ent,pev_team,team);
		set_pev(ent,pev_bInDuck,1); // flag it as a frostnade

		new Float:rgb[3];
		get_rgb_colors(team,rgb);
		
		// glowshell
		set_pev(ent,pev_rendermode,kRenderNormal);
		set_pev(ent,pev_renderfx,kRenderFxGlowShell);
		set_pev(ent,pev_rendercolor,rgb);
		set_pev(ent,pev_renderamt,16.0);

		set_beamfollow(ent,10,10,rgb,100);
	}

	return FMRES_IGNORED;
}

// freeze a player in place whilst he's frozen
public fw_playerprethink(id)
{
	if(isFrozen[id])
	{
		set_pev(id,pev_velocity,Float:{0.0,0.0,0.0}); // stop motion
		engfunc(EngFunc_SetClientMaxspeed,id,0.00001); // keep immobile
		
		new Float:gravity;
		pev(id,pev_gravity,gravity);
		
		// remember any gravity changes
		if(gravity != 0.000000001 && gravity != 999999999.9)
			oldGravity[id] = gravity;

		// if are on the ground and about to jump, set the gravity too high to really do so
		if((pev(id,pev_button) & IN_JUMP) && !(pev(id,pev_oldbuttons) & IN_JUMP) && (pev(id,pev_flags) & FL_ONGROUND))
			set_pev(id,pev_gravity,999999999.9);

		// otherwise, set the gravity so low that they don't fall
		else set_pev(id,pev_gravity,0.000000001);
	}
	
	return FMRES_IGNORED;
}

// override grenade kill message with skull and crossbones
public msg_deathmsg(msg_id,msg_dest,msg_entity)
{
	new victim = get_msg_arg_int(2);
	if(!is_user_connected(victim) || !frostKilled[victim]) return PLUGIN_CONTINUE;

	static weapon[8];
	get_msg_arg_string(4,weapon,7);
	if(equal(weapon,"grenade")) set_msg_arg_string(4,"frostgrenade");

	frostKilled[victim] = 0;
	return PLUGIN_CONTINUE;
}

// maintain speed on FOV changes
public event_setfov(id)
{
	if(get_pcvar_num(pcv_enabled) && is_user_alive(id) && isChilled[id] && !isFrozen[id])
	{
		new Float:maxspeed;
		pev(id,pev_maxspeed,maxspeed);
		if(maxspeed != chillySpeed[id]) engfunc(EngFunc_SetClientMaxspeed,id,chillySpeed[id]);
	}
}

// maintain speed on weapon changes
public event_curweapon(id)
{
	new weapon = read_data(2);

	if(get_pcvar_num(pcv_enabled) && is_user_alive(id))
	{
		if(isChilled[id] && weapon != lastWeapon[id])
		{
			new Float:maxspeed;
			pev(id,pev_maxspeed,maxspeed);
			chillySpeed[id] = maxspeed * get_pcvar_float(pcv_chill_speed) / 100.0;
			if(!isFrozen[id]) engfunc(EngFunc_SetClientMaxspeed,id,chillySpeed[id]);
		}

		if(isFrozen[id]) engfunc(EngFunc_SetClientMaxspeed,id,0.00001);

		if(get_pcvar_num(pcv_icon) == ICON_HASNADE) manage_icon(id,ICON_HASNADE);
	}

	lastWeapon[id] = weapon;
}

// a player's grenade ammo changes
public event_ammox(id)
{
	if(get_pcvar_num(pcv_enabled) && is_user_connected(id))
	{
		if(hasFrostNade[id] && !cs_get_user_bpammo(id,hasFrostNade[id])) hasFrostNade[id] = 0; // just lost my frost grenade
		if(get_pcvar_num(pcv_icon) == ICON_HASNADE) manage_icon(id,ICON_HASNADE);
	}
}

public event_new_round()
{
	freezetime = 1;
}

public logevent_round_start()
{
	freezetime = 0;
}

// rezzed
public ham_player_spawn(id)
{
	nadesBought[id] = 0;
	
	if(is_user_alive(id))
	{
		if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
		if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
	}
}

// killed to death
public ham_player_killed(id)
{
	// these two should technically be caught by ammox first
	hasFrostNade[id] = 0;
	if(get_pcvar_num(pcv_icon) == ICON_HASNADE) manage_icon(id,ICON_HASNADE);

	if(isChilled[id]) task_remove_chill(TASK_REMOVE_CHILL+id);
	if(isFrozen[id]) task_remove_freeze(TASK_REMOVE_FREEZE+id);
}

// grenade is ticking away
public ham_grenade_think(ent)
{
	if(!pev_valid(ent)) return FMRES_IGNORED
	
	// not a frostnade
	if(!pev(ent,pev_bInDuck)) return FMRES_IGNORED;
	
	new Float:dmgtime;
	pev(ent,pev_dmgtime,dmgtime);
	if(dmgtime > get_gametime()) return FMRES_IGNORED;
	
	// and boom goes the dynamite
	frostnade_explode(ent);

	return FMRES_SUPERCEDE;
}

// a frost grenade explodes
public frostnade_explode(ent)
{
	new nadeTeam = pev(ent,pev_team), owner = pev(ent,pev_owner), Float:nadeOrigin[3];
	pev(ent,pev_origin,nadeOrigin);
	
	// make the smoke
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_SMOKE);
	write_coord(floatround(nadeOrigin[0])); // x
	write_coord(floatround(nadeOrigin[1])); // y
	write_coord(floatround(nadeOrigin[2])); // z
	write_short(smokeSpr); // sprite
	write_byte(random_num(30,40)); // scale
	write_byte(5); // framerate
	message_end();
	
	// explosion
	create_blast(nadeTeam,nadeOrigin);
	emit_sound(ent,CHAN_BODY,"warcraft3/frostnova.wav",VOL_NORM,ATTN_NORM,0,PITCH_NORM);

	// cache our cvars
	new hitself = get_pcvar_num(pcv_hitself), los = get_pcvar_num(pcv_los), Float:maxdamage = get_pcvar_float(pcv_maxdamage),
	Float:mindamage = get_pcvar_float(pcv_mindamage)

	new ta, Float:targetOrigin[3], Float:distance, tr = create_tr2(), Float:fraction, Float:damage, gotFrozen;
	for(new target=1;target<=maxPlayers;target++)
	{
		// dead, invincible, or self attack that is not allowed
		if(!is_user_alive(target) || pev(target,pev_takedamage) == DAMAGE_NO
		|| (pev(target,pev_flags) & FL_GODMODE) ||(target == owner && !hitself))
			continue;
		
		if(!is_user_zombie(target))
			continue;
		
		pev(target,pev_origin,targetOrigin);
		distance = vector_distance(nadeOrigin,targetOrigin);
		
		// too far
		if(distance > FROST_RADIUS) continue;

		// check line of sight
		if(los)
		{
			nadeOrigin[2] += 2.0;
			engfunc(EngFunc_TraceLine,nadeOrigin,targetOrigin,DONT_IGNORE_MONSTERS,ent,tr);
			nadeOrigin[2] -= 2.0;

			get_tr2(tr,TR_flFraction,fraction);
			if(fraction != 1.0 && get_tr2(tr,TR_pHit) != target) continue;
		}

		// damaged
		if(maxdamage > 0.0)
		{
			damage = radius_calc(distance,FROST_RADIUS,maxdamage,mindamage);
			if(ta) damage /= 2.0; // half damage for friendlyfire

			if(damage > 0.0)
			{
				frostKilled[target] = 1;
				ExecuteHamB(Ham_TakeDamage,target,ent,owner,damage,DMG_GRENADE);
				if(!is_user_alive(target)) continue; // dead now
				frostKilled[target] = 0;
			}
		}

		// frozen
		gotFrozen = 1;

		chill_player(target,nadeTeam);
		freeze_player(target,nadeTeam);
		emit_sound(target,CHAN_BODY,"warcraft3/impalehit.wav",VOL_NORM,ATTN_NORM,0,PITCH_HIGH);

		if(!gotFrozen) emit_sound(target,CHAN_BODY,"player/pl_duct2.wav",VOL_NORM,ATTN_NORM,0,PITCH_LOW);
	}

	free_tr2(tr);
	set_pev(ent,pev_flags,pev(ent,pev_flags)|FL_KILLME);
}

freeze_player(id,nadeTeam)
{
	if(!isFrozen[id])
	{
		//oldGravity[id] = 1.0;
		pev(id,pev_gravity, oldGravity[id]);

		// register our forward only when we need it
		if(!fwdPPT) fwdPPT = register_forward(FM_PlayerPreThink,"fw_playerprethink",0);
		
		if(!chillySpeed[id])
		{
			new Float:maxspeed;
			pev(id,pev_maxspeed,maxspeed);
			chillySpeed[id] = maxspeed * get_pcvar_float(pcv_chill_speed) / 100.0;
		}
	}

	isFrozen[id] = nadeTeam;
	
	set_pev(id,pev_velocity,Float:{0.0,0.0,0.0});
	engfunc(EngFunc_SetClientMaxspeed,id,0.00001);
	
	new Float:duration = get_pcvar_float(pcv_freeze_duration), Float:variance = get_pcvar_float(pcv_freeze_variance);
	duration += random_float(-variance,variance);

	remove_task(TASK_REMOVE_FREEZE+id);
	set_task(duration,"task_remove_freeze",TASK_REMOVE_FREEZE+id);
	
	if(!pev_valid(novaDisplay[id])) create_nova(id);
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED) manage_icon(id,ICON_ISCHILLED);
}

public task_remove_freeze(taskid)
{
	new id = taskid-TASK_REMOVE_FREEZE;
	
	if(pev_valid(novaDisplay[id]))
	{
		new origin[3], Float:originF[3];
		pev(novaDisplay[id],pev_origin,originF);
		FVecIVec(originF,origin);

		// add some tracers
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_IMPLOSION);
		write_coord(origin[0]); // x
		write_coord(origin[1]); // y
		write_coord(origin[2] + 8); // z
		write_byte(64); // radius
		write_byte(10); // count
		write_byte(3); // duration
		message_end();

		// add some sparks
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_SPARKS);
		write_coord(origin[0]); // x
		write_coord(origin[1]); // y
		write_coord(origin[2]); // z
		message_end();

		// add the shatter
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
		write_byte(TE_BREAKMODEL);
		write_coord(origin[0]); // x
		write_coord(origin[1]); // y
		write_coord(origin[2] + 24); // z
		write_coord(16); // size x
		write_coord(16); // size y
		write_coord(16); // size z
		write_coord(random_num(-50,50)); // velocity x
		write_coord(random_num(-50,50)); // velocity y
		write_coord(25); // velocity z
		write_byte(10); // random velocity
		write_short(glassGibs); // model
		write_byte(10); // count
		write_byte(25); // life
		write_byte(BREAK_GLASS); // flags
		message_end();

		emit_sound(novaDisplay[id],CHAN_BODY,"warcraft3/impalelaunch1.wav",VOL_NORM,ATTN_NORM,0,PITCH_LOW);
		set_pev(novaDisplay[id],pev_flags,pev(novaDisplay[id],pev_flags)|FL_KILLME);
	}

	isFrozen[id] = 0;
	novaDisplay[id] = 0;
	
	// unregister forward if we are no longer using it
	unregister_prethink();

	if(!is_user_connected(id)) return;
	
	restore_speed(id);
	set_pev(id,pev_gravity,oldGravity[id]);
	
	// sometimes trail fades during freeze, reapply
	if(isChilled[id])
	{
		new Float:rgb[3];
		get_rgb_colors(isChilled[id],rgb);
		set_beamfollow(id,30,8,rgb,100);
	}
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED) manage_icon(id,ICON_ISCHILLED);
}

chill_player(id,nadeTeam)
{
	// we aren't already been chilled
	if(!isChilled[id])
	{
		oldRenderFx[id] = pev(id,pev_renderfx);
		pev(id,pev_rendercolor,oldRenderColor[id]);
		oldRenderMode[id] = pev(id,pev_rendermode);
		pev(id,pev_renderamt,oldRenderAmt[id]);

		isChilled[id] = nadeTeam; // fix -- thanks Exolent

		if(!isFrozen[id])
		{
			new Float:maxspeed;
			pev(id,pev_maxspeed,maxspeed);
			chillySpeed[id] = maxspeed * get_pcvar_float(pcv_chill_speed) / 100.0;
			engfunc(EngFunc_SetClientMaxspeed,id,chillySpeed[id]);
		}

		// register our forward only when we need it
		//if(!fwdPPT) fwdPPT = register_forward(FM_PlayerPreThink,"fw_playerprethink",0);
	}
	
	isChilled[id] = nadeTeam;
	
	new Float:duration = get_pcvar_float(pcv_chill_duration), Float:variance = get_pcvar_float(pcv_chill_variance);
	duration += random_float(-variance,variance);

	remove_task(TASK_REMOVE_CHILL+id);
	set_task(duration,"task_remove_chill",TASK_REMOVE_CHILL+id);

	new Float:rgb[3];
	get_rgb_colors(nadeTeam,rgb);
	
	glowColor[id] = rgb;
	
	// glowshell
	set_pev(id,pev_rendermode,kRenderNormal);
	set_pev(id,pev_renderfx,kRenderFxGlowShell);
	set_pev(id,pev_rendercolor,rgb);
	set_pev(id,pev_renderamt,GLOW_AMOUNT);

	set_beamfollow(id,30,8,rgb,100);

	// I decided to let the frostnade tint override a flashbang,
	// because if you are frozen, then you have much bigger problems.

	// add a blue tint to their screen
	message_begin(MSG_ONE,gmsgScreenFade,_,id);
	write_short(floatround(4096.0 * duration)); // duration
	write_short(floatround(3072.0 * duration)); // hold time (4096.0 * 0.75)
	write_short(FFADE_IN); // flags
	write_byte(floatround(rgb[0])); // red
	write_byte(floatround(rgb[1])); // green
	write_byte(floatround(rgb[2])); // blue
	write_byte(100); // alpha
	message_end();
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED) manage_icon(id,ICON_ISCHILLED);
}

public task_remove_chill(taskid)
{
	new id = taskid-TASK_REMOVE_CHILL;

	isChilled[id] = 0;
	
	// unregister forward if we are no longer using it
	//unregister_prethink();

	if(!is_user_connected(id)) return;

	if(!isFrozen[id]) restore_speed(id);
	chillySpeed[id] = 0.0;

	// reset rendering
	set_pev(id,pev_renderfx,oldRenderFx[id]);
	set_pev(id,pev_rendercolor,oldRenderColor[id]);
	set_pev(id,pev_rendermode,oldRenderMode[id]);
	set_pev(id,pev_renderamt,oldRenderAmt[id]);

	clear_beamfollow(id);
	
	// not blinded
	if(get_gametime() >= flashOver[id])
	{
		// clear tint
		message_begin(MSG_ONE,gmsgScreenFade,_,id);
		write_short(0); // duration
		write_short(0); // hold time
		write_short(FFADE_IN); // flags
		write_byte(0); // red
		write_byte(0); // green
		write_byte(0); // blue
		write_byte(255); // alpha
		message_end();
	}
	
	if(get_pcvar_num(pcv_icon) == ICON_ISCHILLED) manage_icon(id,ICON_ISCHILLED);
}

// set maxspeed back to regular
restore_speed(id)
{
	if(freezetime) return;

	engfunc(EngFunc_SetClientMaxspeed,id,get_class_data(get_user_class(id), DATA_SPEED));

	lastWeapon[id] = 0;

	new clip, weapon = get_user_weapon(id,clip);
	emessage_begin(MSG_ONE,gmsgCurWeapon,_,id);
	ewrite_byte(1); // is current
	ewrite_byte(weapon); // weapon id
	ewrite_byte(clip); // clip ammo
	emessage_end();

	new Float:fov;
	pev(id,pev_fov,fov);
	emessage_begin(MSG_ONE,gmsgSetFOV,_,id);
	ewrite_byte(floatround(fov));
	emessage_end();
}

// make a frost nova at a player's feet
create_nova(id)
{
	new nova = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));

	engfunc(EngFunc_SetSize,nova,Float:{-8.0,-8.0,-4.0},Float:{8.0,8.0,4.0});
	engfunc(EngFunc_SetModel,nova,"models/frostnova.mdl");

	// random orientation
	new Float:angles[3];
	angles[1] = random_float(0.0,360.0);
	set_pev(nova,pev_angles,angles);

	// put it at their feet
	new Float:playerMins[3], Float:novaOrigin[3];
	pev(id,pev_mins,playerMins);
	pev(id,pev_origin,novaOrigin);
	novaOrigin[2] += playerMins[2];
	engfunc(EngFunc_SetOrigin,nova,novaOrigin);

	// make it translucent
	get_rgb_colors(isFrozen[id],angles); // let's just use angles
	set_pev(nova,pev_rendercolor,angles); // ^
	set_pev(nova,pev_rendermode,kRenderTransColor);
	set_pev(nova,pev_renderamt,100.0);

	novaDisplay[id] = nova;
}

// manage our snowflake (show it, hide it, flash it?)
manage_icon(id,mode)
{
	new status, team = _:cs_get_user_team(id);
	
	if(get_pcvar_num(pcv_enabled))
	{
		// so if I have it, status = 1; if I also have it out, status = 2
		if(mode == ICON_HASNADE)
		{
			if(hasFrostNade[id])
			{
				status = 1;
				if(get_user_weapon(id) == hasFrostNade[id]) status = 2;
			}
			else if(get_pcvar_num(pcv_override))
			{
				new weapon = get_user_weapon(id), types = get_pcvar_num(pcv_nadetypes);

				if(types & NT_HEGRENADE)
				{
					if(cs_get_user_bpammo(id,CSW_HEGRENADE))
					{
						status = 1;
						if(weapon == CSW_HEGRENADE) status = 2;
					}
				}
				if(status != 2 && (types & NT_SMOKEGRENADE))
				{
					if(cs_get_user_bpammo(id,CSW_SMOKEGRENADE))
					{
						status = 1;
						if(weapon == CSW_SMOKEGRENADE) status = 2;
					}
				}
				if(status != 2 && (types & NT_FLASHBANG))
				{
					if(cs_get_user_bpammo(id,CSW_FLASHBANG))
					{
						status = 1;
						if(weapon == CSW_FLASHBANG) status = 2;
					}
				}
			}
		}
		else // ICON_ISCHILLED
		{
			if(isFrozen[id]) status = 2;
			else if(isChilled[id]) status = 1;
		}
	}
	
	new Float:rgb[3];
	if(status) get_rgb_colors(team,rgb); // only get colors if we need to
	
	message_begin(MSG_ONE_UNRELIABLE,gmsgStatusIcon,_,id);
	write_byte(status); // status (0=hide, 1=show, 2=flash)
	write_string("dmg_cold"); // sprite name
	write_byte(floatround(rgb[0])); // red
	write_byte(floatround(rgb[1])); // green
	write_byte(floatround(rgb[2])); // blue
	message_end();
}

/****************************************
* UTILITY FUNCTIONS
****************************************/

// check if prethink is still being used, if not, unhook it
unregister_prethink()
{
	if(fwdPPT)
	{
		new i;
		for(i=1;i<=maxPlayers;i++) if(isChilled[i] || isFrozen[i]) break;
		if(i > maxPlayers)
		{
			unregister_forward(FM_PlayerPreThink,fwdPPT,0);
			fwdPPT = 0;
		}
	}
}

// make the explosion effects
create_blast(team,Float:originF[3])
{
	new origin[3];
	FVecIVec(originF,origin);

	new Float:rgbF[3], rgb[3];
	get_rgb_colors(team,rgbF);
	FVecIVec(rgbF,rgb);

	// smallest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_coord(origin[0]); // x axis
	write_coord(origin[1]); // y axis
	write_coord(origin[2] + 385); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// medium ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_coord(origin[0]); // x axis
	write_coord(origin[1]); // y axis
	write_coord(origin[2] + 470); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// largest ring
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMCYLINDER);
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_coord(origin[0]); // x axis
	write_coord(origin[1]); // y axis
	write_coord(origin[2] + 555); // z axis
	write_short(exploSpr); // sprite
	write_byte(0); // start frame
	write_byte(0); // framerate
	write_byte(4); // life
	write_byte(60); // width
	write_byte(0); // noise
	write_byte(rgb[0]); // red
	write_byte(rgb[1]); // green
	write_byte(rgb[2]); // blue
	write_byte(100); // brightness
	write_byte(0); // speed
	message_end();

	// light effect
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_DLIGHT);
	write_coord(origin[0]); // x
	write_coord(origin[1]); // y
	write_coord(origin[2]); // z
	write_byte(floatround(FROST_RADIUS/5.0)); // radius
	write_byte(rgb[0]); // r
	write_byte(rgb[1]); // g
	write_byte(rgb[2]); // b
	write_byte(8); // life
	write_byte(60); // decay rate
	message_end();
}

// give an entity a beam trail
set_beamfollow(ent,life,width,Float:rgb[3],brightness)
{
	clear_beamfollow(ent);

	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMFOLLOW);
	write_short(ent); // entity
	write_short(trailSpr); // sprite
	write_byte(life); // life
	write_byte(width); // width
	write_byte(floatround(rgb[0])); // red
	write_byte(floatround(rgb[1])); // green
	write_byte(floatround(rgb[2])); // blue
	write_byte(brightness); // brightness
	message_end();
}

// removes beam trails from an entity
clear_beamfollow(ent)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_KILLBEAM);
	write_short(ent); // entity
	message_end();
}	

// gets RGB colors from the cvar
get_rgb_colors(team,Float:rgb[3])
{
	static color[12], parts[3][4];
	get_pcvar_string(pcv_color,color,11);
	
	// if cvar is set to "team", use colors based on the given team
	if(equali(color,"team",4))
	{
		if(team == 1)
		{
			rgb[0] = 150.0;
			rgb[1] = 0.0;
			rgb[2] = 0.0;
		}
		else
		{
			rgb[0] = 0.0;
			rgb[1] = 0.0;
			rgb[2] = 150.0;
		}
	}
	else
	{
		parse(color,parts[0],3,parts[1],3,parts[2],3);
		rgb[0] = floatstr(parts[0]);
		rgb[1] = floatstr(parts[1]);
		rgb[2] = floatstr(parts[2]);
	}
}

// scale a value equally (inversely?) with the distance that something
// is from the center of another thing. that makes pretty much no sense,
// so basically, the closer we are to the center of a ring, the higher
// our value gets.
//
// EXAMPLE: distance = 60.0, radius = 240.0, maxVal = 100.0, minVal = 20.0
// we are 0.75 (1.0-(60.0/240.0)) of the way to the radius, so scaled with our
// values, it comes out to 80.0 (20.0 + (0.75 * (100.0 - 20.0)))
Float:radius_calc(Float:distance,Float:radius,Float:maxVal,Float:minVal)
{
	if(maxVal <= 0.0) return 0.0;
	if(minVal >= maxVal) return minVal;
	return minVal + ((1.0 - (distance / radius)) * (maxVal - minVal));
}

// gives a player a weapon efficiently
stock ham_give_weapon(id,weapon[])
{
	if(!equal(weapon,"weapon_",7)) return 0;

	new wEnt = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,weapon));
	if(!pev_valid(wEnt)) return 0;

 	set_pev(wEnt,pev_spawnflags,SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn,wEnt);
	
	if(!ExecuteHamB(Ham_AddPlayerItem,id,wEnt))
	{
		if(pev_valid(wEnt)) set_pev(wEnt,pev_flags,pev(wEnt,pev_flags) | FL_KILLME);
		return 0;
	}

	ExecuteHamB(Ham_Item_AttachToPlayer,wEnt,id)
	return 1;
}
