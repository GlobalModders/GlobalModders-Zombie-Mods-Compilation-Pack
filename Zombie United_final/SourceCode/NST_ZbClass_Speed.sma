#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <zombie_united>

#define PLUGIN "NST Zombie Class Speed"
#define VERSION "1.0"
#define AUTHOR "NST"

// Zombie Attributes
new const zclass_name[] = "Speed Zombie (Tang Hinh)" // name
new const zclass_model[] = "speed_zombi" // model
const zclass_health = 800 // health
const Float:zclass_speed = 295.0 // speed
const Float:zclass_gravity = 0.725 // gravity
const Float:zclass_knockback = 6.0 // knockback
const zclass_modelindex = 3
const zclass_sex = 1
new const zclass_hurt1[] = "zombie_united/zombi_hurt_female_1.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_female_2.wav"
new const zclass_death1[] = "zombie_united/zombi_death_female_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_female_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal_female.wav"
new const zombie_sound_invisible[] = "zombie_united/zombi_pressure_female.wav"

// Class IDs
new g_zclass_speed

// Cvar
new invisible_dmg, invisible_speed, invisible_gravity, invisible_alpha
new invisible_time, invisible_timewait

// Vars
new g_invisible[33], g_invisible_wait[33], g_modelwpn[64], g_modelwpn_invisible[64]

// Task offsets
enum (+= 100)
{
	TASK_INVISIBLE = 2000,
	TASK_WAIT_INVISIBLE,
	TASK_INVISIBLE_SOUND,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_INVISIBLE (taskid - TASK_INVISIBLE)
#define ID_WAIT_INVISIBLE (taskid - TASK_WAIT_INVISIBLE)
#define ID_INVISIBLE_SOUND (taskid - TASK_INVISIBLE_SOUND)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Language files
	register_dictionary(LANG_FILE)
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	// Cvars
	invisible_time = register_cvar("nst_zb_zspeed_inv_time", "10.0")
	invisible_timewait = register_cvar("nst_zb_zspeed_inv_timewait", "10.0")
	invisible_dmg = register_cvar("nst_zb_zspeed_inv_dmg", "100")
	invisible_speed = register_cvar("nst_zb_zspeed_inv_speed", "215.0")
	invisible_gravity = register_cvar("nst_zb_zspeed_inv_gravity", "0.9")
	invisible_alpha = register_cvar("nst_zb_zspeed_inv_alpha", "2.0")
	
	// clien cmd
	//register_concmd("ww", "ww")
	register_clcmd("drop", "cmd_invisible")
}
public plugin_precache()
{
	// wpn model
	formatex(g_modelwpn, charsmax(g_modelwpn), "models/zombie_united/v_knife_%s.mdl", zclass_model)
	formatex(g_modelwpn_invisible, charsmax(g_modelwpn_invisible), "models/zombie_united/v_knife_%s_invisible.mdl", zclass_model)
	engfunc(EngFunc_PrecacheModel, g_modelwpn)
	engfunc(EngFunc_PrecacheModel, g_modelwpn_invisible)
	engfunc(EngFunc_PrecacheSound, zombie_sound_invisible)
	
	// register zombie class
	g_zclass_speed = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
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
	if (task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
	if (task_exists(id+TASK_WAIT_INVISIBLE)) remove_task(id+TASK_WAIT_INVISIBLE)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)

	g_invisible[id] = 0
	g_invisible_wait[id] = 0
}

// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_invisible(id)
	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}

// #################### INVISIBLE PUBLIC ####################
// cmd invisible
public cmd_invisible(id)
{
	if (!is_user_alive(id) || !nst_zb_get_take_damage()) return PLUGIN_CONTINUE

	new health = get_user_health(id) - get_pcvar_num(invisible_dmg)
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_speed && health > 0 && !g_invisible[id] && !g_invisible_wait[id])
	{
		// set invisible
		g_invisible[id] = 1
		set_wpnmodel(id)
		
		// set task
		new Float:time_invi, level
		new Float:invisible_time1 = get_pcvar_float(invisible_time)
		level = nst_zb_get_user_level(id)
		if (level==1) time_invi = invisible_time1*0.5
		else time_invi = invisible_time1
		if (task_exists(id+TASK_INVISIBLE)) remove_task(id+TASK_INVISIBLE)
		set_task(time_invi, "RemoveInvisible", id+TASK_INVISIBLE)
		
		// set health when invisible
		fm_set_user_health(id, health)
		
		// play sound
		PlayEmitSound(id, zombie_sound_invisible)

		// send msg
		new message[100]
		format(message, charsmax(message), "^x04[Zombie United]^x01 %L", LANG_PLAYER, "CLASS_NOTICE_INVISIBLE", fnFloatToNum(time_invi))
		nst_zb_color_saytext(id, message)

		//client_print(id, print_chat, "[%i]", fnFloatToNum(time_invi))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
public RemoveInvisible(taskid)
{
	new id = ID_INVISIBLE
	
	// remove invisible
	g_invisible[id] = 0
	set_wpnmodel(id)
	fm_set_rendering(id)
	if (task_exists(taskid)) remove_task(taskid)
	
	// send msg
	new message[100]
	format(message, charsmax(message), "^x04[Zombie United]^x01 %L", LANG_PLAYER, "CLASS_NOTICE_INVISIBLE_OVER")
	nst_zb_color_saytext(id, message)

	// set speed & gravity
	set_pev(id, pev_maxspeed, zclass_speed)
	set_pev(id, pev_gravity, zclass_gravity)
	
	// set time wait
	g_invisible_wait[id] = 1
	if (task_exists(id+TASK_WAIT_INVISIBLE)) remove_task(id+TASK_WAIT_INVISIBLE)
	set_task(get_pcvar_float(invisible_timewait), "RemoveWaitInvisible", id+TASK_WAIT_INVISIBLE)
}
public RemoveWaitInvisible(taskid)
{
	new id = ID_WAIT_INVISIBLE
	g_invisible_wait[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return;
	
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_speed)
	{
		// check invisible
		if (g_invisible[id] && !g_invisible_wait[id])
		{
			// set invisible
			new Float:velocity[3], velo, alpha
			pev(id, pev_velocity, velocity)
			velo = sqroot(floatround(velocity[0] * velocity[0] + velocity[1] * velocity[1] + velocity[2] * velocity[2]))/10
			alpha = floatround(float(velo)*get_pcvar_float(invisible_alpha))
			fm_set_rendering(id,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, alpha)	
		}

	}
	
	return;
}
// set speed
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id)) return;
	
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_speed && g_invisible[id])
	{
		// set gravity speed when invisible
		set_pev(id, pev_maxspeed, get_pcvar_float(invisible_speed))
		set_pev(id, pev_gravity, get_pcvar_float(invisible_gravity))
	}
}
set_wpnmodel(id)
{
	if (!is_user_alive(id)) return;
	
	// set model wpn invisible
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		if (g_invisible[id]) set_pev(id, pev_viewmodel2, g_modelwpn_invisible)
		else set_pev(id, pev_viewmodel2, g_modelwpn)
	}
	
}
PlayEmitSound(id, const sound[])
{
	emit_sound(id, CHAN_VOICE, sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
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
fnFloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}
fm_set_user_health(id, health)
{
	(health > 0) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
}
