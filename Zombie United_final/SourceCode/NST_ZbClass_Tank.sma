#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_united>

// Zombie Attributes
new const zclass_name[] = "Normal Zombie (Chay Nhanh)" // name
new const zclass_model[] = "tank_zombi" // model
const zclass_health = 2000 // health
const Float:zclass_speed = 280.0 // speed
const Float:zclass_gravity = 0.8 // gravity
const Float:zclass_knockback = 1.5 // knockback
const zclass_modelindex = 3
const zclass_sex = 1
new const zclass_hurt1[] = "zombie_united/zombi_hurt_01.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_02.wav"
new const zclass_death1[] = "zombie_united/zombi_death_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal.wav"
new const sound_fastrun_start[] = "zombie_united/zombi_pressure.wav"
new const sound_fastrun_heartbeat[][] = {
	"zombie_united/zombi_pre_idle_1.wav",
	"zombie_united/zombi_pre_idle_2.wav"
}

// Class IDs
new g_zclass_normal

// Cvar
new fastrun_dmg, fastrun_fov
new fastrun_time, fastrun_timewait, fastrun_speed
new fastrun_color_r, fastrun_color_g, fastrun_color_b

new g_fastrun[33], g_fastrun_wait[33], g_current_speed[33]

// Task offsets
enum (+= 100)
{
	TASK_FASTRUN = 2000,
	TASK_FASTRUN_HEARTBEAT,
	TASK_FASTRUN_WAIT,
	TASK_BOT_USE_SKILL
}

// IDs inside tasks
#define ID_FASTRUN (taskid - TASK_FASTRUN)
#define ID_FASTRUN_HEARTBEAT (taskid - TASK_FASTRUN_HEARTBEAT)
#define ID_FASTRUN_WAIT (taskid - TASK_FASTRUN_WAIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin("[ZBU] Zombie Class: Normal", "1.0", "Dias")
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Client Cmd
	register_clcmd("drop", "cmd_fastrun")
	
	// Main Cvar
	fastrun_time = register_cvar("zbu_znormal_fastrun_time", "10.0")
	fastrun_timewait = register_cvar("zbu_znormal_fastrun_timewait", "5.0")
	fastrun_speed = register_cvar("zbu_znormal_fastrun_speed", "350")
	
	fastrun_color_r = register_cvar("zbu_znormal_fastrun_r", "255")
	fastrun_color_g = register_cvar("zbu_znormal_fastrun_g", "3")
	fastrun_color_b = register_cvar("zbu_znormal_fastrun_b", "0")
	
	fastrun_dmg = register_cvar("zbu_znormal_fastrun_dmg", "350")
	fastrun_fov = register_cvar("zbu_znormal_fastrun_fov", "105")
}

public plugin_precache()
{
	new i
	
	for (i = 0; i < sizeof(sound_fastrun_heartbeat); i++)
	{
		engfunc(EngFunc_PrecacheSound, sound_fastrun_heartbeat[i])
	}
	engfunc(EngFunc_PrecacheSound, sound_fastrun_start)	
	
	g_zclass_normal = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
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
reset_value_player(id)
{
	if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)
	if (task_exists(id+TASK_FASTRUN_HEARTBEAT)) remove_task(id+TASK_FASTRUN_HEARTBEAT)
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	
	g_fastrun[id] = 0
	g_fastrun_wait[id] = 0
}
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_fastrun(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
// #################### FASTRUN PUBLIC ####################
// Cmd fast run
public cmd_fastrun(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	
	new health = get_user_health(id) - get_pcvar_num(fastrun_dmg)
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_normal && health > 0 && !g_fastrun[id] && !g_fastrun_wait[id])
	{
		// set current speed
		pev(id, pev_maxspeed, g_current_speed[id])
		
		// set fastrun
		g_fastrun[id] = 1
		
		// set glow shell
		new color[3]
		color[0] = get_pcvar_num(fastrun_color_r)
		color[1] = get_pcvar_num(fastrun_color_g)
		color[2] = get_pcvar_num(fastrun_color_b)
		fm_set_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 0)

		// set effect
		EffectFastrun(id, get_pcvar_num(fastrun_fov))
		
		// set health
		fm_set_user_health(id, health)
		
		// task fastrun
		new Float:timerun, level
		new Float:fastrun_time1 = get_pcvar_float(fastrun_time)
		level = nst_zb_get_user_level(id)
		
		if (level==1) timerun = fastrun_time1*0.5
		else timerun = fastrun_time1
		if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)
		set_task(timerun, "RemoveFastRun", id+TASK_FASTRUN)
		
		// play sound start
		PlayEmitSound(id, sound_fastrun_start)
		
		// task fastrun sound heartbeat
		if (task_exists(id+TASK_FASTRUN_HEARTBEAT)) remove_task(id+TASK_FASTRUN_HEARTBEAT)
		set_task(2.0, "FastRunHeartBeat", id+TASK_FASTRUN_HEARTBEAT, _, _, "b")

		return PLUGIN_HANDLED
	}

	return PLUGIN_CONTINUE
}
public RemoveFastRun(taskid)
{
	new id = ID_FASTRUN

	g_fastrun[id] = 0
	set_pev(id, pev_maxspeed, g_current_speed[id])
	fm_set_rendering(id)
	EffectFastrun(id)
	if (task_exists(taskid)) remove_task(taskid)
	
	new Float:timewait = get_pcvar_float(fastrun_timewait)
	if (nst_zb_get_user_level(id)>1) timewait = 0.5
	g_fastrun_wait[id] = 1
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)
	set_task(timewait, "RemoveWaitFastRun", id+TASK_FASTRUN_WAIT)
}
public RemoveWaitFastRun(taskid)
{
	new id = ID_FASTRUN_WAIT
	g_fastrun_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
public FastRunHeartBeat(taskid)
{
	new id = ID_FASTRUN_HEARTBEAT
	
	if (g_fastrun[id])
	{
		PlayEmitSound(id, sound_fastrun_heartbeat[random_num(0, charsmax(sound_fastrun_heartbeat))])
	}
	else if (task_exists(taskid)) remove_task(taskid)
}

// set speed
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id)) return;
	
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_normal && g_fastrun[id])
	{
		set_pev(id, pev_maxspeed, get_pcvar_float(fastrun_speed))
	}
}
// MAIN FUNCTION

PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}
fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16) 
{
	new Float:RenderColor[3];
	RenderColor[0] = float(r);
	RenderColor[1] = float(g);
	RenderColor[2] = float(b);

	set_pev(entity, pev_renderfx, fx);
	set_pev(entity, pev_rendercolor, RenderColor);
	set_pev(entity, pev_rendermode, render);
	set_pev(entity, pev_renderamt, float(amount));

	return 1;
}
EffectFastrun(id, num = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(num)
	message_end()
}
