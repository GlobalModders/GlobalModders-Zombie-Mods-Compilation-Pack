#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_united>

// Zombie Attributes
new const zclass_name[] = "Heal Zombie (Hoi Mau)" // name
new const zclass_model[] = "heal_zombi" // model
const zclass_health = 1500 // health
const Float:zclass_speed = 280.0 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 2.5 // knockback
const zclass_sex = 1
const zclass_modelindex = 3
new const zclass_hurt1[] = "zombie_united/zombi_hurt_01.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_02.wav"
new const zclass_death1[] = "zombie_united/zombi_death_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal.wav"

new const sprites_heal[] = "sprites/zombie_united/zb_restore_health.spr"
new const sound_healteam[] = "zombie_united/td_heal.wav"

// Class IDs
new g_zclass_heal

// Cvars
new heal_timewait, heal_dmg, heal_dmg_team

// Vars
new idsprites_heal
new g_heal_wait[33], g_msgDamage, g_msgScreenFade

// Task offsets
enum (+= 100)
{
	TASK_WAIT_HEAL = 2000,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_WAIT_HEAL (taskid - TASK_WAIT_HEAL)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin("[ZBU] Zombie Class: Heal", "1.0", "Dias")

	// Msg
	g_msgDamage = get_user_msgid("Damage")
	g_msgScreenFade = get_user_msgid("ScreenFade")
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	
	// Cvars
	heal_timewait = register_cvar("nst_zb_zheal_timewait", "10.0")
	heal_dmg = register_cvar("nst_zb_zheal_dmg", "0.3")
	heal_dmg_team = register_cvar("nst_zb_zheal_dmgteam", "350")
	
	// Client Cmd
	register_clcmd("drop", "cmd_heal")
}

public plugin_precache()
{
	idsprites_heal = engfunc(EngFunc_PrecacheModel, sprites_heal)
	engfunc(EngFunc_PrecacheSound, sound_healteam)

	g_zclass_heal = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
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
	if (task_exists(id+TASK_WAIT_HEAL)) remove_task(id+TASK_WAIT_HEAL)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_heal_wait[id] = 0
}
// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_heal(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### INVISIBLE PUBLIC ####################
// cmd invisible
public cmd_heal(id)
{
	if (!is_user_alive(id) || !nst_zb_get_take_damage()) return PLUGIN_CONTINUE

	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_heal && !g_heal_wait[id])
	{
		// check health
		new start_health = nst_zb_get_user_start_health(id)
		if (get_user_health(id) >= start_health) return PLUGIN_CONTINUE
		
		// set health
		new level, Float:health, Float:heath_up, health_set
		level = nst_zb_get_user_level(id)
		health = float(get_user_health(id))
		new Float:heal_dmg1 = get_pcvar_float(heal_dmg)
		
		if (level==1) heath_up = health*heal_dmg1*0.5
		else heath_up = health*heal_dmg1
		health_set = floatround(health) + max(get_pcvar_num(heal_dmg_team), floatround(heath_up))
		health_set = min(start_health, health_set)
		fm_set_user_health(id, health_set)
		
		// up health zombie team
		if (level == 3) UpdateHealthZombieTeam(id)
		
		// effect
		PlaySound(id, zclass_heal)
		EffectRestoreHealth(id)
		
		// set time wait
		g_heal_wait[id] = 1
		if (task_exists(id+TASK_WAIT_HEAL)) remove_task(id+TASK_WAIT_HEAL)
		set_task(get_pcvar_float(heal_timewait), "RemoveWaitSmoke", id+TASK_WAIT_HEAL)
		
		//client_print(id, print_chat, "[%i][%s]", FloatToNum(heath_up), zombie_sound_heal)
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
public RemoveWaitSmoke(taskid)
{
	new id = ID_WAIT_HEAL
	g_heal_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
UpdateHealthZombieTeam(id)
{
	for (new i = 1; i <= 32; i++)
	{
		if (is_user_alive(i) && (get_user_team(id)==get_user_team(i)) && i != id)
		{
			new start_health = nst_zb_get_user_start_health(i)
			if (get_user_health(i) < start_health)
			{
				new health_new
				health_new = min(start_health, (get_user_health(i)+get_pcvar_num(heal_dmg_team)))
				fm_set_user_health(i, health_new)
				EffectRestoreHealth(i)
				PlaySound(i, sound_healteam)
			}
		}
	}
}
PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
EffectRestoreHealth(id)
{
	if (!is_user_alive(id)) return;
	
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(idsprites_heal); // sprites
	write_byte(15); // scale in 0.1's
	write_byte(12); // framerate
	write_byte(14); // flags 
	message_end(); // message end
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenFade , _, id);
	write_short(1<<10);
	write_short(1<<10);
	write_short(0x0000);
	write_byte(255);//r
	write_byte(0);  //g
	write_byte(0);  //b
	write_byte(75);
	message_end();
	
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, id)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_NERVEGAS) // damage type - DMG_RADIATION
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
}
