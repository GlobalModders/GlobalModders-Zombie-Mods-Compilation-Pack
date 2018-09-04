#include <amxmodx>
#include <fakemeta>
#include <xs>
#tryinclude <biohazard>

#if !defined _biohazard_included
        #assert Biohazard functions file required!
#endif

#define TASKID_CHECK 124
#define TASKID_RADAR 531

new cvar_radar, g_maxplayers
public plugin_init()
{
	register_plugin("zombie radar", "0.3", "cheap_suit")
	is_biomod_active() ? plugin_init2() : pause("ad")
}

public plugin_init2()
{
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("Damage", "event_damage", "b")
	cvar_radar = register_cvar("bh_zombie_radar", "1")
	g_maxplayers = get_maxplayers()
}

public event_newround() 
{
	remove_task(TASKID_CHECK)
	remove_task(TASKID_RADAR)
}

public client_disconnect(id)
{
	remove_task(TASKID_CHECK)
	set_task(1.0, "task_check", TASKID_CHECK)
}

public event_damage(id)
{
	if(get_user_health(id) < 1 && !is_user_zombie(id))
	{
		remove_task(TASKID_CHECK)
		set_task(1.0, "task_check", TASKID_CHECK)
	}
}

public event_infect(victim, attacker)
{
	if(get_pcvar_num(cvar_radar))
	{
		remove_task(TASKID_CHECK)
		set_task(1.0, "task_check", TASKID_CHECK)
	}
}

public task_check()
{
	static survivor; survivor = last_survivor()
	if(survivor) 
	{
		static params[1]; params[0] = survivor
		set_task(1.0, "task_radar", TASKID_RADAR, params, 1)
	}
}

public task_radar(params[])
{
	static id; id = params[0]
	if(!is_user_alive(id))
	{
		static msg_bombpickup
		if(!msg_bombpickup) msg_bombpickup = get_user_msgid("BombPickup")
		
		message_begin(MSG_ALL, msg_bombpickup)
		message_end()
		
		return
	}

	static origin[3]
	get_user_origin(id, origin)
	
	static msg_bombdrop
	if(!msg_bombdrop) msg_bombdrop = get_user_msgid("BombDrop")
	
	message_begin(MSG_ALL, msg_bombdrop)
	write_coord(origin[0])
	write_coord(origin[1])
	write_coord(origin[2])
	write_byte(0)
	message_end()
	
	set_task(0.5, "task_radar", TASKID_RADAR, params, 1)
}

stock last_survivor()
{
	static id, count, survivor[33]; count = 0
	for(id = 1; id <= g_maxplayers; id++) if(is_user_alive(id) && !is_user_zombie(id)) survivor[count++] = id
	return count == 1 ? survivor[0] : 0
}
