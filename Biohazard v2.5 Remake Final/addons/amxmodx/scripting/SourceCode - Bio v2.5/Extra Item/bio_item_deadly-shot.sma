#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <biohazard>
#include <bio_shop>
#include <cstrike>

#define TASK_HUD 5345634
#define TASK_REMOVE 2423423

new bool:has_item[33]
new bool:using_item[33]

new sync_hud1
new cvar_deadlyshot_cost
new cvar_deadlyshot_time

new g_deadlyshot

public plugin_init()
{
	register_plugin("[Bio] Extra Item: Deadly Shot (Human)", "1.0", "Dias")
	
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	RegisterHam(Ham_TraceAttack, "player", "fw_traceattack")
	
	cvar_deadlyshot_cost = register_cvar("bh_ds_cost", "10000")
	cvar_deadlyshot_time = register_cvar("bh_ds_time", "10.0")
	
	sync_hud1 = CreateHudSyncObj(random_num(1, 10))
	g_deadlyshot = bio_register_item("Deadly Shot", get_pcvar_num(cvar_deadlyshot_cost), "Make all damage to head", TEAM_HUMAN)
}

public event_newround(id)
{
	remove_ds(id)
}

public bio_item_selected(id, itemid)
{
	if(itemid != g_deadlyshot)
		return PLUGIN_HANDLED
		
	if(!has_item[id] || using_item[id])
	{
		has_item[id] = true
		using_item[id] = false
		
		set_task(0.1, "show_hud", id+TASK_HUD, _, _, "b")
	} else {
		color_saytext(id, "!g[Bio]!y You can't buy !rDeadly Shot!y at this time...")
		cs_set_user_money(id, cs_get_user_money(id) + get_pcvar_num(cvar_deadlyshot_cost))
	}
	
	return PLUGIN_CONTINUE
}

public event_infect(id)
{
	remove_ds(id)
}

public show_hud(id)
{
	id -= TASK_HUD

	set_hudmessage(0, 255, 0, -1.0, 0.88, 0, 2.0, 1.0)	
	
	if(has_item[id])
	{
		ShowSyncHudMsg(id, sync_hud1, "[E] -> Active Deadly Shot")
	} else if(using_item[id]) {
		ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Actived")		
	} else {
		set_hudmessage(0, 255, 0, -1.0, 0.88, 0, 2.0, 5.0)
		ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Disable")
		if(task_exists(id+TASK_HUD)) remove_task(id+TASK_HUD)
	}
}

public client_PostThink(id)
{
	static Button
	Button = get_user_button(id)
	
	if(Button & IN_USE)
	{
		if(has_item[id] && !using_item[id])
		{
			has_item[id] = false
			using_item[id] = true
			
			set_task(get_pcvar_float(cvar_deadlyshot_time), "remove_headshot_mode", id+TASK_REMOVE)
		}
	}
}

public fw_traceattack(victim, attacker, Float:damage, direction[3], traceresult, dmgbits)
{
	if(using_item[attacker])
	{
		set_tr2(traceresult, TR_iHitgroup, HIT_HEAD)
	}
}

public remove_ds(id)
{
	if(has_item[id] || using_item[id])
	{
		has_item[id] = false
		using_item[id] = false		
		
		if(task_exists(id+TASK_HUD)) remove_task(id+TASK_HUD)
		if(task_exists(id+TASK_REMOVE)) remove_task(id+TASK_REMOVE)
	}	
}

public remove_headshot_mode(id)
{
	id -= TASK_REMOVE
	
	has_item[id] = false
	using_item[id] = false
	
	if(task_exists(id+TASK_HUD)) remove_task(id+TASK_HUD)
	
	set_hudmessage(0, 255, 0, -1.0, 0.88, 0, 2.0, 5.0)
	ShowSyncHudMsg(id, sync_hud1, "Deadly Shot - Disable")	
}

color_saytext(player, const message[], any:...)
{
	new text[301]
	format(text, 300, "%s", message)

	new dest
	if (player) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, get_user_msgid("SayText"), {0,0,0}, player)
	write_byte(1)
	write_string(check_text(text))
	return message_end()
}

check_text(text1[])
{
	new text[301]
	format(text, 300, "%s", text1)
	replace(text, 300, "!g", "^x04")
	replace(text, 300, "!r", "^x03")
	replace(text, 300, "!y", "^x01")
	return text
}
