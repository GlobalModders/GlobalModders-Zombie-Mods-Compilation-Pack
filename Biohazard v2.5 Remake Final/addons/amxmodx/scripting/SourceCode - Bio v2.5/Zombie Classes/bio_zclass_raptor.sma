#include <amxmodx>
#include <biohazard>
#include <hamsandwich>
#include <fakemeta_util>

#define STR_T 32
#define MAX_PLAYERS 32

#define D_ZOMBIE_NAME "Raptor Zombie"
#define D_ZOMBIE_DESC "Chem Vao Tuong De Leo"
#define D_PLAYER_MODEL "models/player/raptor/raptor.mdl"
#define D_CLAWS "models/biohazard/v_knife_flesh.mdl"

new g_class	
new cvar_speed, cvar_delay

new Float:g_wallorigin[33][3]
new Float:g_nextdmg[33]
new Float:g_shoottime[33]

public plugin_init()
{         
	register_plugin("bio_raptor","1.2b","bipbip")
	is_biomod_active() ? plugin_init2() : pause("ad")
}
public plugin_precache()
{
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
}

public plugin_init2()
{
	g_class = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)

	if(g_class != -1)
	{
		set_class_data(g_class, DATA_HEALTH, 2000.0)
		set_class_data(g_class, DATA_SPEED, 275.0)
		set_class_data(g_class, DATA_GRAVITY, 0.9)
		set_class_data(g_class, DATA_ATTACK, 0.1)
		set_class_data(g_class, DATA_HITDELAY, 0.1)
		set_class_data(g_class, DATA_HITREGENDLY, 999.0)
		set_class_data(g_class, DATA_KNOCKBACK, 1.5)
		set_class_data(g_class, DATA_DEFENCE, 0.8)
		set_class_data(g_class, DATA_HEDEFENCE, 0.8)
		set_class_pmodel(g_class, D_PLAYER_MODEL)
		set_class_wmodel(g_class, D_CLAWS)
	}
	
	cvar_speed = register_cvar("bh_climbingspeed", "150")
	cvar_delay = register_cvar("bh_climbdelay", "0.1")

	RegisterHam(Ham_Touch, "player", "cheese_player_touch", 1)
	RegisterHam(Ham_Player_PreThink, "player", "cheese_player_prethink", 1)
	RegisterHam(Ham_TakeDamage, "player", "cheese_takedamage", 1)
}


public cheese_player_touch(id, world) {
	
	if(!is_user_alive(id) || g_class != get_user_class(id))
		return HAM_IGNORED
	
	new classname[STR_T]
	pev(world, pev_classname, classname, (STR_T-1))
	
	if(equal(classname, "worldspawn") || equal(classname, "func_wall") || equal(classname, "func_breakable"))
		pev(id, pev_origin, g_wallorigin[id])

	return HAM_IGNORED	
	
}

public cheese_player_prethink(id) {

	// Player not alive or not zombie
	if(!is_user_alive(id) || !is_user_zombie(id)) {
		return HAM_IGNORED
	}

	// Player has not our zombie class
	if(g_class != get_user_class(id)) {
		return HAM_IGNORED
	}

	static Float:origin[3]
	pev(id, pev_origin, origin)
	
	// from Cheap_Suit's  Upgrades Mod eXtended
	static button ; button = pev(id, pev_button)

	if(button & IN_ATTACK)
	{
		if(get_distance_f(origin, g_wallorigin[id]) > 10.0)
			return HAM_IGNORED
		
		if(pev(id, pev_flags) & FL_ONGROUND)
			return HAM_IGNORED
		
		if (get_gametime() < g_shoottime[id]) {
			return HAM_IGNORED
		}
		
		if(button & IN_FORWARD)
		{
			static Float:velocity[3]
			velocity_by_aim(id, get_pcvar_num(cvar_speed), velocity)
			fm_set_user_velocity(id, velocity)
		}
		else if(button & IN_BACK)
		{
			static Float:velocity[3]
			velocity_by_aim(id, -get_pcvar_num(cvar_speed), velocity)
			fm_set_user_velocity(id, velocity)
		}
	}	


	

	return HAM_IGNORED
}

public event_infect(victim, attacker) 
{
	if(is_user_alive(victim) && get_user_class(victim) == g_class)
	{
		g_nextdmg[victim] = 0.0
		g_shoottime[victim] = 0.0	
		
		client_print(victim, print_center, D_ZOMBIE_DESC)
	}
}

public cheese_takedamage(victim, inflictor, attacker, Float:damage, damagetype)
{
	if (is_user_alive(victim)) {
		if (g_class == get_user_class(victim)) {
			g_shoottime[victim] = get_gametime() + get_pcvar_float(cvar_delay);
		}
	}
	return HAM_IGNORED
}


