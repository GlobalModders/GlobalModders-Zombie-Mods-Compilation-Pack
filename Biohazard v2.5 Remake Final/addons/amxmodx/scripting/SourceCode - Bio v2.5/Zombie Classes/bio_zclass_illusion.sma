#include <amxmodx>
#include <fakemeta>
#include <fakemeta_util>
#include <cstrike>
#include <biohazard>

#define D_ZOMBIE_NAME "Illusion Zombie"
#define D_ZOMBIE_DESC "[G] -> Gia Dang Human"
#define D_PLAYER_MODEL "models/player/zombie_source/zombie_source.mdl"
#define D_PLAYER_MODEL_NAME "zombie_source"
#define D_CLAWS "models/biohazard/v_knife_normal.mdl"

#define D_FAKE_CLAWS "models/v_knife.mdl"
#define D_FAKE_WEAPON "models/p_m4a1.mdl"

#define TASK_LIMIT 111111
#define TASK_COOLDOWN 222222
#define TASK_ANIM 333333

new g_zclass_illusion
new bool:can_use_skill[33]
new const random_model[][] = {
	"arctic",
	"gsg9",
	"guerilla",
	"gign",
	"leet",
	"sas",
	"terror",
	"urban"
}

new cvar_fake_limit, cvar_fake_cooldown

public plugin_init()
{         
	register_plugin("[Bio] Zombie Class: Illusion", "1.0", "Dias")
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_clcmd("drop", "use_skill")
	
	cvar_fake_limit = register_cvar("bh_illusion_fake_limit", "7.0")
	cvar_fake_cooldown = register_cvar("bh_illusion_fake_cooldown", "30.0")
	
	register_class_data()
}

public plugin_precache()
{
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	
	precache_model(D_FAKE_CLAWS)
	precache_model(D_FAKE_WEAPON)
}

public register_class_data()
{
	g_zclass_illusion = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)

	if(g_zclass_illusion != -1)
	{
		set_class_data(g_zclass_illusion, DATA_HEALTH, 1000.0)
		set_class_data(g_zclass_illusion, DATA_SPEED, 250.0)
		set_class_data(g_zclass_illusion, DATA_GRAVITY, 0.9)
		set_class_data(g_zclass_illusion, DATA_ATTACK, 1.0)
		set_class_data(g_zclass_illusion, DATA_HITDELAY, 1.0)
		set_class_data(g_zclass_illusion, DATA_HITREGENDLY, 999.0)
		set_class_data(g_zclass_illusion, DATA_KNOCKBACK, 1.5)
		set_class_data(g_zclass_illusion, DATA_DEFENCE, 1.0)
		set_class_data(g_zclass_illusion, DATA_HEDEFENCE, 1.0)
		set_class_data(g_zclass_illusion, DATA_MODELINDEX, 1.0)		
		set_class_pmodel(g_zclass_illusion, D_PLAYER_MODEL)
		set_class_wmodel(g_zclass_illusion, D_CLAWS)
	}
}

public event_newround(id)
{
	remove_task(id+TASK_LIMIT)
	remove_task(id+TASK_COOLDOWN)
	remove_task(id+TASK_ANIM)
}

public event_infect(id)
{
	if(is_user_zombie(id) && get_user_class(id) == g_zclass_illusion)
	{
		can_use_skill[id] = true
	}
}

public use_skill(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_illusion)
	{
		if(can_use_skill[id])
		{
			set_pev(id, pev_viewmodel2, D_FAKE_CLAWS)
			set_pev(id, pev_weaponmodel2, D_FAKE_WEAPON)
			
			cs_set_user_model(id, random_model[random_num(0, charsmax(random_model))])
			
			set_pev(id, pev_maxspeed, pev(id, pev_maxspeed) - 50.0)
			
			can_use_skill[id] = false

			set_task(2.0, "do_anim", id+TASK_ANIM)
			set_task(get_pcvar_float(cvar_fake_limit), "stop_illusion", id+TASK_LIMIT)
			set_task(get_pcvar_float(cvar_fake_cooldown), "remove_cooldown", id+TASK_COOLDOWN)
		} else {
			client_print(id, print_center, "Khong the Gia Dang luc nay !!!")
		}
		
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public do_anim(id)
{
	id -= TASK_ANIM
	
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_illusion)
	{
		set_pev(id, pev_sequence, 31)
		set_task(0.1, "do_anim", id+TASK_ANIM)
	} else {
		remove_task(id+TASK_ANIM)
	}
}

public stop_illusion(id)
{
	id -= TASK_LIMIT

	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_illusion)
	{
		set_pev(id, pev_viewmodel2, D_CLAWS)
		set_pev(id, pev_weaponmodel2, "")
		
		set_pev(id, pev_maxspeed, get_class_data(g_zclass_illusion, DATA_SPEED))
		
		remove_task(id+TASK_ANIM)
		
		cs_set_user_model(id, D_PLAYER_MODEL_NAME)
	}
}

public remove_cooldown(id)
{
	id -= TASK_COOLDOWN
	
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_illusion)
	{
		can_use_skill[id] = true
	}
}
