#include <amxmodx>
#include <biohazard>
#include <hamsandwich>

#define TASK_RESPAWN 123543

new cvar_respawn, cvar_timerespawn

public plugin_init()
{
	register_plugin("[Bio] Addon: Zombie Spawn", "1.0", "Dias")
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	
	cvar_respawn = register_cvar("bh_zombie_respawn", "1")
	cvar_timerespawn = register_cvar("bh_time_respawn", "10.0")
}

public event_death()
{
	new victim = read_data(2)
	
	if(is_user_zombie(victim) && get_pcvar_num(cvar_respawn))
	{
		set_task(get_pcvar_float(cvar_timerespawn), "do_respawn", victim+TASK_RESPAWN)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, victim)
		write_short(get_pcvar_num(cvar_timerespawn))
		message_end()
		
		client_print(victim, print_center, "You will be respawned after: %i seconds", get_pcvar_num(cvar_timerespawn))
	}
}

public event_newround(id)
{
	if(task_exists(id+TASK_RESPAWN)) 
	{
		remove_task(id+TASK_RESPAWN)
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("BarTime"), _, id)
		write_short(0)
		message_end()
	}
}

public do_respawn(taskid)
{
	static id
	id = taskid - TASK_RESPAWN
	
	if(is_user_zombie(id))
	{
		ExecuteHam(Ham_CS_RoundRespawn, id)
		client_print(id, print_center, "You have been respawned")
	}
}
