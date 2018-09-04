#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_united>

#define PLUGIN "NST Zombie Class Pc"
#define VERSION "1.0"
#define AUTHOR "NST"
// Zombie Attributes
new const zclass_name[] = "Pc Zombie (Xa Khoi)" // name
new const zclass_model[] = "pc_zombi" // model
const zclass_health = 2000 // health
const Float:zclass_speed = 280.0 // speed
const Float:zclass_gravity = 1.0 // gravity
const Float:zclass_knockback = 2.5 // knockback
const zclass_sex = 1
const zclass_modelindex = 2
new const zclass_hurt1[] = "zombie_united/zombi_hurt_01.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_02.wav"
new const zclass_death1[] = "zombie_united/zombi_death_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal.wav"

new const sound_smoke[] = "zombie_united/zombi_smoke.wav"
new const sprites_smoke[] = "sprites/zombie_united/zb_smoke.spr"

// Class IDs
new g_zclass_pc

// Main Cvars
new smoke_time, smoke_timewait, smoke_size, smoke_dmg

// Main Vars
new id_smoke1
new g_smoke[33], g_smoke_wait[33], Float:g_smoke_origin[33][3]
// Task offsets
enum (+= 100)
{
	TASK_SMOKE = 2000,
	TASK_SMOKE_EXP,
	TASK_WAIT_SMOKE,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_SMOKE (taskid - TASK_SMOKE)
#define ID_SMOKE_EXP (taskid - TASK_SMOKE_EXP)
#define ID_WAIT_SMOKE (taskid - TASK_WAIT_SMOKE)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin("[ZBU] Class: Pyscho", "1.0", "Dias")

	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	
	smoke_time = register_cvar("nst_zb_zpc_smoke_time", "10.0")
	smoke_timewait = register_cvar("nst_zb_zpc_smoke_timewait", "10.0")
	smoke_size = register_cvar("nst_zb_zpc_smoke_size", "4")
	smoke_dmg = register_cvar("nst_zb_zpc_smoke_dmg", "10")

	// Client Cmd
	register_clcmd("drop", "cmd_smoke")
}

public plugin_precache()
{
	id_smoke1 = precache_model(sprites_smoke)
	engfunc(EngFunc_PrecacheSound, sound_smoke)
	
	g_zclass_pc = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
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
	if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_smoke[id] = 0
	g_smoke_wait[id] = 0
}

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_smoke(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### MAIN PUBLIC ####################
// cmd smoke
public cmd_smoke(id)
{
	if (!is_user_alive(id) || !nst_zb_get_take_damage()) return PLUGIN_CONTINUE

	new health = get_user_health(id) - get_pcvar_num(smoke_dmg)
	if (is_user_alive(id) && nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_pc && health>0 && !g_smoke[id] && !g_smoke_wait[id])
	{
		// set smoke
		g_smoke[id] = 1
		
		// task smoke exp
		pev(id,pev_origin,g_smoke_origin[id])
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		set_task(0.1, "SmokeExplode", id+TASK_SMOKE_EXP)
		
		// task remove smoke
		new Float:time_s, level
		new Float:cur_smoke_time = get_pcvar_float(smoke_time)
		level = nst_zb_get_user_level(id)
		if (level==1) time_s = cur_smoke_time*0.5
		else time_s = cur_smoke_time
		if (task_exists(id+TASK_SMOKE)) remove_task(id+TASK_SMOKE)
		set_task(time_s, "RemoveSmoke", id+TASK_SMOKE)
		
		// play sound
		PlaySound(id, sound_smoke)
		
		// set speed & gravity & health when invisible
		fm_set_user_health(id, health)
		
		//client_print(id, print_chat, "[%i]", fnFloatToNum(time_invi))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
public SmokeExplode(taskid)
{
	new id = ID_SMOKE_EXP
	
	// remove smoke
	if (!g_smoke[id])
	{
		if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
		return;
	}
	
	new Float:origin[3]
	origin[0] = g_smoke_origin[id][0]// + random_num(-75,75)
	origin[1] = g_smoke_origin[id][1]// + random_num(-75,75)
	origin[2] = g_smoke_origin[id][2]// + random_num(0,65)
	
	new flags = pev(id, pev_flags)
	if (!((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
		origin[2] -= 36.0
	
	Create_Smoke_Group(origin)
	
	// task smoke exp
	if (task_exists(id+TASK_SMOKE_EXP)) remove_task(id+TASK_SMOKE_EXP)
	set_task(1.0, "SmokeExplode", id+TASK_SMOKE_EXP)
	
	return;
}
public RemoveSmoke(taskid)
{
	new id = ID_SMOKE
	
	// remove smoke
	g_smoke[id] = 0
	if (task_exists(taskid)) remove_task(taskid)

	// set time wait
	g_smoke_wait[id] = 1
	if (task_exists(id+TASK_WAIT_SMOKE)) remove_task(id+TASK_WAIT_SMOKE)
	set_task(get_pcvar_float(smoke_timewait), "RemoveWaitSmoke", id+TASK_WAIT_SMOKE)
}
public RemoveWaitSmoke(taskid)
{
	new id = ID_WAIT_SMOKE
	g_smoke_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
PlaySound(id, const sound[])
{
	client_cmd(id, "spk ^"%s^"", sound)
}
fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
Create_Smoke_Group(Float:position[3])
{
	new Float:origin[12][3]
	get_spherical_coord(position, 40.0, 0.0, 0.0, origin[0])
	get_spherical_coord(position, 40.0, 90.0, 0.0, origin[1])
	get_spherical_coord(position, 40.0, 180.0, 0.0, origin[2])
	get_spherical_coord(position, 40.0, 270.0, 0.0, origin[3])
	get_spherical_coord(position, 100.0, 0.0, 0.0, origin[4])
	get_spherical_coord(position, 100.0, 45.0, 0.0, origin[5])
	get_spherical_coord(position, 100.0, 90.0, 0.0, origin[6])
	get_spherical_coord(position, 100.0, 135.0, 0.0, origin[7])
	get_spherical_coord(position, 100.0, 180.0, 0.0, origin[8])
	get_spherical_coord(position, 100.0, 225.0, 0.0, origin[9])
	get_spherical_coord(position, 100.0, 270.0, 0.0, origin[10])
	get_spherical_coord(position, 100.0, 315.0, 0.0, origin[11])
	
	for (new i = 0; i < get_pcvar_num(smoke_size); i++)
	{
			create_Smoke(origin[i], id_smoke1, 100, 0)
	}
}
create_Smoke(const Float:position[3], sprite_index, life, framerate)
{
	// Alphablend sprite, move vertically 30 pps
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_SMOKE) // TE_SMOKE (5)
	engfunc(EngFunc_WriteCoord, position[0]) // position.x
	engfunc(EngFunc_WriteCoord, position[1]) // position.y
	engfunc(EngFunc_WriteCoord, position[2]) // position.z
	write_short(sprite_index) // sprite index
	write_byte(life) // scale in 0.1's
	write_byte(framerate) // framerate
	message_end()
}
get_spherical_coord(const Float:ent_origin[3], Float:redius, Float:level_angle, Float:vertical_angle, Float:origin[3])
{
	new Float:length
	length  = redius * floatcos(vertical_angle, degrees)
	origin[0] = ent_origin[0] + length * floatcos(level_angle, degrees)
	origin[1] = ent_origin[1] + length * floatsin(level_angle, degrees)
	origin[2] = ent_origin[2] + redius * floatsin(vertical_angle, degrees)
}
