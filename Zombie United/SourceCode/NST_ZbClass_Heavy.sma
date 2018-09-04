#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <zombie_united>

#define PLUGIN "NST Zombie Class Heavy"
#define VERSION "1.0"
#define AUTHOR "NST"

// Zombie Attributes
new const zclass_name[] = "Heavy Zombie (Dat Bay)" // name
new const zclass_model[] = "heavy_zombi" // model
const zclass_health = 3000 // health
const Float:zclass_speed = 270.0 // speed
const Float:zclass_gravity = 1.2 // gravity
const Float:zclass_knockback = 1.0 // knockback
const zclass_sex = 1
const zclass_modelindex = 3
new const zclass_hurt1[] = "zombie_united/zombi_hurt_heavy_1.wav"
new const zclass_hurt2[] = "zombie_united/zombi_hurt_heavy_2.wav"
new const zclass_death1[] = "zombie_united/zombi_death_1.wav"
new const zclass_death2[] = "zombie_united/zombi_death_2.wav"
new const zclass_heal[] = "zombie_united/zombi_heal_heavy.wav"

new const model_trap[] = "models/zombie_united/zombitrap.mdl"
new const sound_trapsetup[] = "zombie_united/zombi_trapsetup.wav"
new const sound_trapped[] = "zombie_united/zombi_trapped.wav"
new const sprites_trap[] = "sprites/zombie_united/trap.spr"

const MAX_TRAP = 30
new const trap_classname[] = "nst_zb_traps"

// Class IDs
new g_zclass_heavy

// Cvars
new trap_total, trap_timewait, trapped_time, trap_timesetup, trap_invisible

// Vars
new g_total_traps[33], g_msgScreenShake, g_trapping[33], g_player_trapped[33]
new g_waitsetup[33], TrapOrigins[33][MAX_TRAP][4], idsprites_trap
// Task offsets
enum (+= 100)
{
	TASK_TRAPSETUP = 2000,
	TASK_REMOVETRAP,
	TASK_REMOVE_TIMEWAIT,
	TASK_BOT_USE_SKILL
}
// IDs inside tasks
#define ID_TRAPSETUP (taskid - TASK_TRAPSETUP)
#define ID_REMOVETRAP (taskid - TASK_REMOVETRAP)
#define ID_REMOVE_TIMEWAIT (taskid - TASK_REMOVE_TIMEWAIT)
#define ID_BOT_USE_SKILL (taskid - TASK_BOT_USE_SKILL)

public plugin_init()
{
	register_plugin("[ZBU] Zombie Class: Heavy", "1.0", "Dias")
	
	// Msg
	g_msgScreenShake = get_user_msgid("ScreenShake")
	
	// Events
	register_logevent("logevent_round_start",2, "1=Round_Start")
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	register_forward(FM_CmdStart, "fw_CmdStart")
	
	// Cvars
	trap_total = register_cvar("nst_zb_zheavy_trap_total", "3")
	trap_timewait = register_cvar("nst_zb_zheavy_trap_timewait", "10.0")
	trap_timesetup = register_cvar("nst_zb_zheavy_trap_timesetup", "2.0")
	trap_invisible = register_cvar("nst_zb_zheavy_trap_invisible", "10")
	trapped_time = register_cvar("nst_zb_zheavy_trapped_time", "8.0")
	
	// Client Cmd
	register_clcmd("drop", "cmd_setuptrap")
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, model_trap)
	engfunc(EngFunc_PrecacheSound, sound_trapsetup)
	engfunc(EngFunc_PrecacheSound, sound_trapped)
	idsprites_trap = engfunc(EngFunc_PrecacheModel, sprites_trap)

	g_zclass_heavy = nst_zbu_register_zombie_class(zclass_name, zclass_model, zclass_health, 
	zclass_gravity, zclass_speed, zclass_knockback, zclass_death1, zclass_death2, 
	zclass_hurt1, zclass_hurt2, zclass_heal, zclass_sex, zclass_modelindex)
}

public nst_zb_user_infected(id, infector)
{
	// remove trap
	remove_trapped_when_infected(id)
}
public event_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
	}
	
	// remove trap
	remove_traps()
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
	
	// remove trap
	remove_trapped_when_infected(victim)
	
	// set speed for player
	//set_pev(victim, pev_flags, (pev(victim, pev_flags) & ~FL_FROZEN))
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
	if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	if (task_exists(id+TASK_REMOVE_TIMEWAIT)) remove_task(id+TASK_REMOVE_TIMEWAIT)
	if (task_exists(id+TASK_BOT_USE_SKILL)) remove_task(id+TASK_BOT_USE_SKILL)
	
	g_total_traps[id] = 0
	g_trapping[id] = 0
	g_player_trapped[id] = 0
	
	remove_traps_player(id)
}
// bot use skill
public bot_use_skill(taskid)
{
	new id = ID_BOT_USE_SKILL
	if (!is_user_bot(id)) return;

	cmd_setuptrap(id)

	if (task_exists(taskid)) remove_task(taskid)
	set_task(float(random_num(5,15)), "bot_use_skill", id+TASK_BOT_USE_SKILL)
}
public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) return;
	
	// icon help
	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_heavy)
	{
		// check trapping
		if (g_trapping[id])
		{
			// remove setup trap if player move
			static Float:velocity[3]
			pev(id, pev_velocity, velocity)
			if (velocity[0] || velocity[1] || velocity[2])
			{
				remove_setuptrap(id)
			}
		}

	}
	
	// player pickup trap
	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap))
	{
		// sequence of trap model
		static classname[32]
		pev(ent_trap, pev_classname, classname, charsmax(classname))
		if (equal(classname, classname))
		{
			if (pev(ent_trap, pev_sequence) != 1)
			{
				set_pev(ent_trap, pev_sequence, 1)
				set_pev(ent_trap, pev_frame, 0.0)
			}
			else
			{
				if (pev(ent_trap, pev_frame) > 230)
					set_pev(ent_trap, pev_frame, 20.0)
				else
					set_pev(ent_trap, pev_frame, pev(ent_trap, pev_frame) + 1.0)
			}
			//client_print(0, print_chat, "[%i][%i]", pev(ent_trap, pev_sequence), pev(ent_trap, pev_frame))
		}
		//client_print(0, print_chat, "[%s]", classname)
	}
	
	return;
}
// don't move when traped
public fw_PlayerPreThink(id)
{
	if (!is_user_alive(id)) return;
	
	new ent_trap = g_player_trapped[id]
	if (ent_trap && pev_valid(ent_trap))
	{
		set_pev(id, pev_maxspeed, 0.01)
	}
}
// trapped
public pfn_touch(ptr, ptd)
{
	if(pev_valid(ptr))
	{
		new classname[32]
		pev(ptr, pev_classname, classname, charsmax(classname))
		//client_print(ptd, print_chat, "[%s][%i]", classname, ptr)
		
		if(equal(classname, trap_classname))
		{
			new victim = ptd
			new attacker = pev(ptr, pev_owner)
			if (is_user_alive(victim) && (get_user_team(attacker) != get_user_team(victim)) && victim != attacker && !g_player_trapped[victim])
			//if (is_user_alive(victim) && !nst_zb_get_user_zombie(victim) && g_player_trapped[victim] != ptr)
			{
				Trapped(victim, ptr)
			}
		}
	}
}
// #################### TRAP PUBLIC ####################
// show icon drap
public client_PostThink(id)
{
	if (!is_user_alive(id) || !nst_zb_get_user_zombie(id) || !g_total_traps[id]) return;

	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		DrawSprite(id, i)
	}

	return;
}

// cmd use skill
public cmd_setuptrap(id)
{
	if (!is_user_alive(id) || !nst_zb_get_take_damage()) return PLUGIN_CONTINUE

	if (nst_zb_get_user_zombie(id) && nst_zb_get_user_zombie_class(id) == g_zclass_heavy)
	{
		// check setupping
		if (g_trapping[id] || g_waitsetup[id]) return PLUGIN_HANDLED
		
		// check total trap
		new level = nst_zb_get_user_level(id)
		new max_traps = get_pcvar_num(trap_total)
		if (level==1) max_traps = max_traps/2
		if (g_total_traps[id]>=max_traps)
		{
			new message[100]
			format(message, charsmax(message), "^x04[Zombie United]^x01 %L", LANG_PLAYER, "CLASS_NOTICE_MAXTRAP", max_traps)
			nst_zb_color_saytext(id, message)
			return PLUGIN_HANDLED
		}
		 
		// set trapping
		g_trapping[id] = 1
		bartime(id, FloatToNum(get_pcvar_float(trap_timesetup)))
		
		// set task
		if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
		set_task(get_pcvar_float(trap_timesetup), "TrapSetup", id+TASK_TRAPSETUP)
		
		//client_print(id, print_chat, "[%i]", fnFloatToNum(time_invi))
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}
public TrapSetup(taskid)
{
	new id = ID_TRAPSETUP
	
	// remove setup trap
	remove_setuptrap(id)

	// create model trap
	create_w_class(id)

	// play sound
	PlayEmitSound(id, sound_trapsetup)
	
	// remove task TrapSetup
	if (task_exists(taskid)) remove_task(taskid)

	// set wait time
	g_waitsetup[id] = 1
	if (task_exists(id+TASK_REMOVE_TIMEWAIT)) remove_task(id+TASK_REMOVE_TIMEWAIT)
	set_task(get_pcvar_float(trap_timewait), "RemoveTimeWait", id+TASK_REMOVE_TIMEWAIT)
}
public RemoveTimeWait(taskid)
{
	new id = ID_REMOVE_TIMEWAIT
	g_waitsetup[id] = 0
	if (task_exists(taskid)) remove_task(taskid)
}
remove_setuptrap(id)
{
	g_trapping[id] = 0
	bartime(id, 0)
	if (task_exists(id+TASK_TRAPSETUP)) remove_task(id+TASK_TRAPSETUP)
}
Trapped(id, ent_trap)
{
	// check trapped
	for (new i=1; i<33; i++)
	{
		if (is_user_connected(i) && g_player_trapped[i]==ent_trap) return;
	}
	
	// set ent trapped of player
	g_player_trapped[id] = ent_trap
	
	// set screen shake
	user_screen_shake(id, 4, 2, 5)

	// stop move
	//if (!(user_flags & FL_FROZEN)) set_pev(id, pev_flags, (user_flags | FL_FROZEN))
			
	// play sound
	PlayEmitSound(id, sound_trapped)
	
	// reset invisible model trapped
	fm_set_rendering(ent_trap)

	// set task remove trap
	if (task_exists(id+TASK_REMOVETRAP)) remove_task(id+TASK_REMOVETRAP)
	set_task(get_pcvar_float(trapped_time), "RemoveTrap", id+TASK_REMOVETRAP)
	
	// update TrapOrigins
	UpdateTrap(ent_trap)
}
UpdateTrap(ent_trap)
{
	//new id = entity_get_int(ent_trap, EV_INT_iuser1)
	new id = pev(ent_trap, pev_owner)

	new total, TrapOrigins_new[MAX_TRAP][4]
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		if (TrapOrigins[id][i][0] != ent_trap)
		{
			total += 1
			TrapOrigins_new[total][0] = TrapOrigins[id][i][0]
			TrapOrigins_new[total][1] = TrapOrigins[id][i][1]
			TrapOrigins_new[total][2] = TrapOrigins[id][i][2]
			TrapOrigins_new[total][3] = TrapOrigins[id][i][3]
		}
	}
	TrapOrigins[id] = TrapOrigins_new
	g_total_traps[id] = total
}
public RemoveTrap(taskid)
{
	new id = ID_REMOVETRAP
	
	// set speed for player
	//set_pev(id, pev_flags, (pev(id, pev_flags) & ~FL_FROZEN))
	
	// remove trap
	remove_trapped_when_infected(id)
	
	if (task_exists(taskid)) remove_task(taskid)
}
remove_trapped_when_infected(id)
{
	new p_trapped = g_player_trapped[id]
	if (p_trapped)
	{
		// remove trap
		if (pev_valid(p_trapped)) engfunc(EngFunc_RemoveEntity, p_trapped)
		
		// reset value of player
		g_player_trapped[id] = 0
	}
}
create_w_class(id)
{
	if (!nst_zb_get_user_zombie(id)) return -1;

	new user_flags = pev(id, pev_flags)
	if (!(user_flags & FL_ONGROUND))
	{
		return 0;
	}
	
	// get origin
	new Float:origin[3]
	pev(id, pev_origin, origin)

	new ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
	if (!ent) return -1;
	
	// Set trap data
	set_pev(ent, pev_classname, trap_classname)
	set_pev(ent, pev_solid, SOLID_TRIGGER)
	set_pev(ent, pev_movetype, 6)
	set_pev(ent, pev_sequence, 0)
	set_pev(ent, pev_frame, 0.0)
	set_pev(ent, pev_owner, id)
	//set_pev(ent, pev_iuser1, id)
	
	// Set trap size
	new Float:mins[3] = { -20.0, -20.0, 0.0 }
	new Float:maxs[3] = { 20.0, 20.0, 30.0 }
	engfunc(EngFunc_SetSize, ent, mins, maxs)
	
	// Set trap model
	engfunc(EngFunc_SetModel, ent, model_trap)

	// Set trap position
	set_pev(ent, pev_origin, origin)
	
	
	// set invisible
	fm_set_rendering(ent,kRenderFxGlowShell,0,0,0,kRenderTransAlpha, trap_invisible)
	
	// trap counter
	g_total_traps[id] += 1
	TrapOrigins[id][g_total_traps[id]][0] = ent
	TrapOrigins[id][g_total_traps[id]][1] = FloatToNum(origin[0])
	TrapOrigins[id][g_total_traps[id]][2] = FloatToNum(origin[1])
	TrapOrigins[id][g_total_traps[id]][3] = FloatToNum(origin[2])
	
	return -1;
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

FloatToNum(Float:floatn)
{
	new str[64], num
	float_to_str(floatn, str, 63)
	num = str_to_num(str)
	
	return num
}
bartime(id, time_run)
{
	message_begin(MSG_ONE, get_user_msgid("BarTime"), _, id)
	write_short(time_run)
	message_end()
}
DrawSprite(id, idtrap)
{
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, {0, 0, 0}, id)
	write_byte(TE_SPRITE) // additive sprite, plays 1 cycle
	write_coord(TrapOrigins[id][idtrap][1]) // xpos
	write_coord(TrapOrigins[id][idtrap][2]) // ypos
	write_coord(TrapOrigins[id][idtrap][3]) // zpos
	write_short(idsprites_trap) // spr index
	write_byte(2) // (scale in 0.1's)
	write_byte(30) //brightness
	message_end()
}
remove_traps()
{
	// reset model
	new nextitem  = find_ent_by_class(-1, trap_classname)
	while(nextitem)
	{
		remove_entity(nextitem)
		nextitem = find_ent_by_class(-1, trap_classname)
	}
	
	// reset oringin
	//new TrapOrigins_reset[33][MAX_TRAP][4]
	//TrapOrigins = TrapOrigins_reset
}
remove_traps_player(id)
{
	// remove model trap in map
	for (new i = 1; i <= g_total_traps[id]; i++)
	{
		new trap_ent = TrapOrigins[id][i][0]
		if (is_valid_ent(trap_ent)) engfunc(EngFunc_RemoveEntity, trap_ent)
	}
	
	// reset oringin
	new TrapOrigins_pl[MAX_TRAP][4]
	TrapOrigins[id] = TrapOrigins_pl
}
user_screen_shake(id, amplitude = 4, duration = 2, frequency = 10)
{
	message_begin(MSG_ONE_UNRELIABLE, g_msgScreenShake, _, id)
	write_short((1<<12)*amplitude) // ??
	write_short((1<<12)*duration) // ??
	write_short((1<<12)*frequency) // ??
	message_end()
}
