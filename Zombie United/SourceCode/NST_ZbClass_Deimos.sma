#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <engine>
#include <zombie_united>

// Zombie Attributes
new const zclass_name[] = "Deimos Zombie (Tuoc Vu Khi)" // name
new const zclass_model[] = "deimos_zombi" // model
const zclass_health = 2500 // health
const Float:zclass_speed = 280.0 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 2.5 // knockback
new const zclass_hurt1[] = "zombie_united/zombi_hurt_01.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_02.wav"
new const zclass_death1[] = "zombie_united/zombi_death_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal.wav"
const zclass_sex = 1
const zclass_modelindex = 3

new const sound_skill_start[] = "zombie_united/deimos_skill_start.wav"
new const sound_skill_hit[] = "zombie_united/deimos_skill_hit.wav"
new const sprites_exp[] = "sprites/zombie_united/deimosexp.spr"
new const sprites_trail[] = "sprites/zombie_united/trail.spr"

new const light_classname[] = "deimos_skill"

// Class ID
new g_zclass_deimos

// Cvars
new skill_dmg, skill_anim, skill_time_wait

// Vars
new sprites_exp_index, sprites_trail_index
new v_model_host[64], v_zombibomb_host[64]

new g_wait[33], g_useskill[33]

const WPN_NOT_DROP = ((1<<2)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG)|(1<<CSW_KNIFE)|(1<<CSW_C4))
enum (+= 100)
{
	TASK_WAIT = 2000,
	TASK_ATTACK,
	TASK_BOT_USE_SKILL,
	TASK_USE_SKILL
}
// IDs inside tasks
#define ID_WAIT (taskid - TASK_WAIT)
#define ID_ATTACK (taskid - TASK_ATTACK)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)
#define ID_USE_SKILL (taskid - TASK_USE_SKILL)

const m_flTimeWeaponIdle = 48
const m_flNextAttack = 83

public plugin_init()
{
	register_plugin("[ZBU] Class: Pc", "1.0", "Dias")

	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	
	// FM Forwards
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_Touch, "fw_Touch")
	
	// Cvars
	skill_time_wait = register_cvar("nst_zb_zdeimos_time_wait", "15.0")
	skill_dmg = register_cvar("nst_zb_zdeimos_skill_dmg", "100")
	skill_anim = register_cvar("nst_zb_zdeimos_anim", "10")
	
	// Client Cmd
	register_clcmd("drop", "use_skill")
}

public plugin_precache()
{
	format(v_model_host, charsmax(v_model_host), "models/zombie_united/v_knife_%s_host.mdl", zclass_model)
	format(v_zombibomb_host, charsmax(v_zombibomb_host), "models/zombie_united/v_zombibomb_%s_host.mdl", zclass_model)
	
	precache_model(v_model_host)
	precache_model(v_zombibomb_host)
	
	sprites_exp_index = precache_model(sprites_exp)
	sprites_trail_index = precache_model(sprites_trail)
	
	precache_sound(sound_skill_start)
	precache_sound(sound_skill_hit)

	g_zclass_deimos = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
	zclass_gravity, zclass_speed, zclass_knockback, zclass_death1, zclass_death2, 
	zclass_hurt1, zclass_hurt2, zclass_heal, zclass_sex, zclass_modelindex)
}

public event_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}
public logevent_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		if (is_user_bot(id))
		{
			if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
			set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
		}
	}
}
public Death()
{
	new victim = read_data(2) 

	reset_value_player(victim)
}
public client_connect(id)
{
	reset_value_player(id)
}
public client_disconnect(id)
{
	reset_value_player(id)
}
reset_value_player(id)
{
	if (task_exists(id+TASK_WAIT)) remove_task(id+TASK_WAIT)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_wait[id] = 0
	g_useskill[id] = 0
}

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	use_skill(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### USE SKILL PUBLIC ####################
public use_skill(id)
{
	if (!is_user_alive(id) || !nst_zb_get_take_damage()) return PLUGIN_CONTINUE
	
	new health = get_user_health(id) - get_pcvar_num(skill_dmg)
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_deimos && !g_wait[id] && health>0 && get_user_weapon(id)==CSW_KNIFE)
	{
		g_useskill[id] = 1
		
		// set health
		fm_set_user_health(id, health)
		
		// set time wait
		new Float:skill_time_wait2 = get_pcvar_float(skill_time_wait)
		new Float:timewait = skill_time_wait2
		if (nst_zb_get_user_level(id)==1) timewait = skill_time_wait2*2
		
		g_wait[id] = 1
		if (task_exists(id+TASK_WAIT)) remove_task(id+TASK_WAIT)
		set_task(timewait, "RemoveWait", id+TASK_WAIT)
		
		//client_print(id, print_chat, "[%i][%s]", FloatToNum(heath_up), zombie_sound_heal)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
public task_use_skill(taskid)
{
	new id = ID_USE_SKILL
	
	// play anim & sound
	play_weapon_anim(id, 8)
	set_weapons_timeidle(id, get_pcvar_float(skill_time_wait))
	set_player_nextattack(id, 0.5)
	PlayEmitSound(id, sound_skill_start)
	entity_set_int(id, EV_INT_sequence, get_pcvar_num(skill_anim))
	
	// attack
	if (task_exists(id+TASK_ATTACK)) remove_task(id+TASK_ATTACK)
	set_task(0.5, "launch_light", id+TASK_ATTACK)
}
public launch_light(taskid)
{
	new id = ID_ATTACK
	if (task_exists(id+TASK_ATTACK)) remove_task(id+TASK_ATTACK)
	
	if (!is_user_alive(id)) return;
	
	// check
	new Float: fOrigin[3], Float:fAngle[3],Float: fVelocity[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, fAngle)
	fm_velocity_by_aim(id, 2.0, fVelocity, fAngle)
	fAngle[0] *= -1.0
	
	// create ent
	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	set_pev(ent, pev_classname, light_classname)
	engfunc(EngFunc_SetModel, ent, "models/w_hegrenade.mdl")
	set_pev(ent, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(ent, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(ent, pev_origin, fOrigin)
	fOrigin[0] += fVelocity[0]
	fOrigin[1] += fVelocity[1]
	fOrigin[2] += fVelocity[2]
	set_pev(ent, pev_movetype, MOVETYPE_BOUNCE)
	set_pev(ent, pev_gravity, 0.01)
	fVelocity[0] *= 1000
	fVelocity[1] *= 1000
	fVelocity[2] *= 1000
	set_pev(ent, pev_velocity, fVelocity)
	set_pev(ent, pev_owner, id)
	set_pev(ent, pev_angles, fAngle)
	set_pev(ent, pev_solid, SOLID_BBOX)						//store the enitty id
	
	// invisible ent
	fm_set_rendering(ent, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0)
	
	// show trail	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(ent)				//entity
	write_short(sprites_trail_index)		//model
	write_byte(5)		//10)//life
	write_byte(3)		//5)//width
	write_byte(209)					//r, hegrenade
	write_byte(120)					//g, gas-grenade
	write_byte(9)					//b
	write_byte(200)		//brightness
	message_end()					//move PHS/PVS data sending into here (SEND_ALL, SEND_PVS, SEND_PHS)
	
	//client_print(0, print_chat, "phong")
	return;
}
public fw_Touch(ent, victim)
{
	if (!pev_valid(ent)) return FMRES_IGNORED
	
	new EntClassName[32]
	entity_get_string(ent, EV_SZ_classname, EntClassName, charsmax(EntClassName))
	
	if (equal(EntClassName, light_classname)) 
	{
		light_exp(ent, victim)
		remove_entity(ent)
		return FMRES_IGNORED
	}
	
	return FMRES_IGNORED
}
light_exp(ent, victim)
{
	if (!pev_valid(ent)) return;
	
	// drop current wpn of victim
	new attacker = pev(ent, pev_owner)
	if (is_user_alive(victim) && !nst_zb_get_user_hero(victim) && get_user_team(attacker)!=get_user_team(victim))
	{
		new wpn, wpnname[32]
		wpn = get_user_weapon(victim)
		if( !(WPN_NOT_DROP & (1<<wpn)) && get_weaponname(wpn, wpnname, charsmax(wpnname)) )
		{
			engclient_cmd(victim, "drop", wpnname)
		}
	}
	
	// create effect
	static Float:origin[3];
	pev(ent, pev_origin, origin);
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(sprites_exp_index); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	// play sound exp
	PlayEmitSound(ent, sound_skill_hit)
}
public RemoveWait(taskid)
{
	new id = ID_WAIT
	g_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}


// #################### MAIN PUBLIC ####################
public CurrentWeapon(id)
{
	if (!is_user_alive(id)) return;
	
	// zombie weapons
	new current_weapon = get_user_weapon(id)
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_deimos && current_weapon)
	{
		new level = nst_zb_get_user_level(id)
		if (level == 1 && get_user_team(id)==1)
		{
			// set model zonbie bom
			if (current_weapon == CSW_HEGRENADE)
				set_pev(id, pev_viewmodel2, v_zombibomb_host)
			// set model knife zombie
			else if (current_weapon == CSW_KNIFE)
				set_pev(id, pev_viewmodel2, v_model_host)
		}
	}
	
	return;
}
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return FMRES_IGNORED
	
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_deimos)
	{
		// use skill
		if (g_useskill[id])
		{
			set_uc(uc_handle, UC_Buttons, IN_ATTACK2)
			g_useskill[id] = 0
			entity_set_int(id, EV_INT_sequence, get_pcvar_num(skill_anim))
			
			if (task_exists(id+TASK_USE_SKILL)) remove_task(id+TASK_USE_SKILL)
			set_task(0.0, "task_use_skill", id+TASK_USE_SKILL)
		}
	}
	
	//client_print(id, print_chat, "[%i]", set_animation(id))
	return FMRES_IGNORED
}
PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_WEAPON, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}
fm_velocity_by_aim(iIndex, Float:fDistance, Float:fVelocity[3], Float:fViewAngle[3])
{
	//new Float:fViewAngle[3]
	pev(iIndex, pev_v_angle, fViewAngle)
	fVelocity[0] = floatcos(fViewAngle[1], degrees) * fDistance
	fVelocity[1] = floatsin(fViewAngle[1], degrees) * fDistance
	fVelocity[2] = floatcos(fViewAngle[0]+90.0, degrees) * fDistance
	return 1
}
get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = fm_find_ent_by_owner(-1, wname, id)
	return weapon_ent
}
set_weapons_timeidle(id, Float:timeidle)
{
	new entwpn = get_weapon_ent(id, get_user_weapon(id))
	if (pev_valid(entwpn)) set_pdata_float(entwpn, m_flTimeWeaponIdle, timeidle+3.0, 4)
}
set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, m_flNextAttack, nexttime, 4)
}

// ################### STOCK ###################
// Set player's health (from fakemeta_util)
stock fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}
// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) { /* keep looping */ }
	return entity;
}
