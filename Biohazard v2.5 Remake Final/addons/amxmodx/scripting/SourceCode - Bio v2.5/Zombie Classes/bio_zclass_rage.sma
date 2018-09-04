#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <biohazard>
#include <fun>

#define PLUGIN "[Bio] Class: Rage"
#define VERSION "1.0"
#define AUTHOR "Dias" // Original: Sontung0

#define D_ZOMBIE_NAME "Rage Zombie"
#define D_ZOMBIE_DESC "[G] -> Chay Nhanh"
#define D_PLAYER_MODEL "models/player/tank_zombi_host/tank_zombi_host.mdl"
#define D_CLAWS "models/biohazard/v_knife_normal.mdl"

new g_zclass_rage
new cvar_fastrun_time, cvar_fastrun_timewait, cvar_fastrun_speed, cvar_fastrun_dmg, cvar_fastrun_fov
new cvar_fastrun_glow_r, cvar_fastrun_glow_g, cvar_fastrun_glow_b
new const sound_fastrun_start[] = "biohazard/zombi_pressure.wav"
new const sound_fastrun_heartbeat[][] = {
	"biohazard/zombi_pre_idle_1.wav",
	"biohazard/zombi_pre_idle_2.wav"
}

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
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Client Cmd
	register_clcmd("drop", "cmd_fastrun")
	
	// Register Cvars
	cvar_fastrun_time = register_cvar("bh_fastrun_time", "10.0")
	cvar_fastrun_timewait = register_cvar("bh_fastrun_timewait", "10.0")
	cvar_fastrun_dmg = register_cvar("bh_fastrun_dmg", "250")
	cvar_fastrun_speed = register_cvar("bh_fastrun_speed", "340.0")
	cvar_fastrun_fov = register_cvar("bh_fastrun_fov", "105")
	
	cvar_fastrun_glow_r = register_cvar("bh_fastrun_glow_r", "255")
	cvar_fastrun_glow_g = register_cvar("bh_fastrun_glow_g", "3")
	cvar_fastrun_glow_b = register_cvar("bh_fastrun_glow_b", "0")
	
	// Register Class
	register_class_zombie()
}

public plugin_precache()
{
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	
	engfunc(EngFunc_PrecacheSound, sound_fastrun_start)
	
	for(new i = 0; i < sizeof(sound_fastrun_heartbeat); i++)
		engfunc(EngFunc_PrecacheSound, sound_fastrun_heartbeat[i])
}

public register_class_zombie()
{
	g_zclass_rage = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)

	if(g_zclass_rage != -1)
	{
		set_class_data(g_zclass_rage, DATA_HEALTH, 3000.0)
		set_class_data(g_zclass_rage, DATA_SPEED, 270.0)
		set_class_data(g_zclass_rage, DATA_GRAVITY, 1.0)
		set_class_data(g_zclass_rage, DATA_ATTACK, 1.0)
		set_class_data(g_zclass_rage, DATA_HITDELAY, 1.0)
		set_class_data(g_zclass_rage, DATA_HITREGENDLY, 2.0)
		set_class_data(g_zclass_rage, DATA_KNOCKBACK, 1.0)
		set_class_data(g_zclass_rage, DATA_DEFENCE, 0.75)
		set_class_data(g_zclass_rage, DATA_HEDEFENCE, 0.75)
		set_class_data(g_zclass_rage, DATA_MODELINDEX, 1.0)
		set_class_pmodel(g_zclass_rage, D_PLAYER_MODEL)
		set_class_wmodel(g_zclass_rage, D_CLAWS)
	}	
}

public event_round_start()
{
	for (new id = 0; id < get_maxplayers(); id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
}
public logevent_round_start()
{
	for (new id = 0; id < get_maxplayers(); id++)
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

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_fastrun(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

public event_infect(victim)
{
	if(is_user_zombie(victim) && get_user_class(victim) == g_zclass_rage)
		client_print(victim, print_center, D_ZOMBIE_DESC)
}

// #################### FASTRUN PUBLIC ####################
// Cmd fast run
public cmd_fastrun(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE
	
	if(is_user_zombie(id))
	{
		client_print(id, print_center, "")
		
		new health = get_user_health(id) - get_pcvar_num(cvar_fastrun_dmg)
		if (get_user_class(id) == g_zclass_rage && health > 0 && !g_fastrun[id] && !g_fastrun_wait[id])
		{
			// set current speed
			pev(id, pev_maxspeed, g_current_speed[id])
			
			// set fastrun
			g_fastrun[id] = 1
			
			// set glow shell
			new color[3]
			color[0] = get_pcvar_num(cvar_fastrun_glow_r)
			color[1] = get_pcvar_num(cvar_fastrun_glow_g)
			color[2] = get_pcvar_num(cvar_fastrun_glow_b)
			set_user_rendering(id, kRenderFxGlowShell, color[0], color[1], color[2], kRenderNormal, 0)
	
			// set effect
			EffectFastrun(id, get_pcvar_num(cvar_fastrun_fov))
			speed_aura(id)
			
			// set health
			fm_set_user_health(id, health)
			
			// task fastrun
			if (task_exists(id+TASK_FASTRUN)) remove_task(id+TASK_FASTRUN)
			set_task(get_pcvar_float(cvar_fastrun_time), "RemoveFastRun", id+TASK_FASTRUN)
			
			// play sound start
			PlayEmitSound(id, sound_fastrun_start)
			
			// task fastrun sound heartbeat
			if (task_exists(id+TASK_FASTRUN_HEARTBEAT)) remove_task(id+TASK_FASTRUN_HEARTBEAT)
			set_task(2.0, "FastRunHeartBeat", id+TASK_FASTRUN_HEARTBEAT, _, _, "b")
	
			return PLUGIN_HANDLED
		}
	}
	
	return PLUGIN_CONTINUE
}
public speed_aura(id)
{
	if(g_fastrun[id])
	{
		// Get player origin
		static Float:originF[3]
		pev(id, pev_origin, originF)
		
		// Colored Aura
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_DLIGHT) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]) // z
		write_byte(7) // radius
		write_byte(get_pcvar_num(cvar_fastrun_glow_r)) // r
		write_byte(get_pcvar_num(cvar_fastrun_glow_g)) // g
		write_byte(get_pcvar_num(cvar_fastrun_glow_b)) // b
		write_byte(10) // life
		write_byte(0) // decay rate
		message_end()
		
		// Keep sending aura messages
		set_task(0.1, "speed_aura", id)
	}
}
public RemoveFastRun(taskid)
{
	new id = ID_FASTRUN

	g_fastrun[id] = 0
	set_pev(id, pev_maxspeed, g_current_speed[id])
	set_user_rendering(id)
	EffectFastrun(id)
	if (task_exists(taskid)) remove_task(taskid)
	
	g_fastrun_wait[id] = 1
	if (task_exists(id+TASK_FASTRUN_WAIT)) remove_task(id+TASK_FASTRUN_WAIT)
	set_task(get_pcvar_float(cvar_fastrun_timewait), "RemoveWaitFastRun", id+TASK_FASTRUN_WAIT)
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
	
	if (is_user_zombie(id) && get_user_class(id) == g_zclass_rage && g_fastrun[id])
	{
		set_pev(id, pev_maxspeed, get_pcvar_float(cvar_fastrun_speed))
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

EffectFastrun(id, num = 90)
{
	message_begin(MSG_ONE, get_user_msgid("SetFOV"), {0,0,0}, id)
	write_byte(num)
	message_end()
}
