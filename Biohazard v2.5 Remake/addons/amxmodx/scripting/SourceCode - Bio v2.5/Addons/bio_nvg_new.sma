#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <engine>
#include <biohazard>

#define PLUGIN	"[Bio] Addon: Custom NVG"
#define AUTHOR	"Dias"
#define VERSION	"0.1"

#define TASK_NVISION 1310  
#define ID_NVISION (taskid - TASK_NVISION)

//const HAS_NVGOGGLES = (1<<0)
new g_nvision[33] // has night vision
new g_nvisionenabled[33] // has night vision turned on
new g_msgNVGToggle
new cvar_nvggive,cvar_cnvg,cvar_nvgsize,cvar_nvgcolor[3]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("nightvision", "clcmd_nightvision")
	
	cvar_nvggive = register_cvar("nvg_give", "2")
	cvar_cnvg = register_cvar("nvg_custom", "1")
	cvar_nvgsize = register_cvar("bio_nvg_size", "70")
	cvar_nvgcolor[0] = register_cvar("nvg_color_R", "100")
	cvar_nvgcolor[1] = register_cvar("nvg_color_G", "100")
	cvar_nvgcolor[2] = register_cvar("nvg_color_B", "100")
	register_event("HLTV", "event_roundnew", "a", "1=0", "2=0")
	g_msgNVGToggle = get_user_msgid("NVGToggle")
	
}
public client_disconnect(id)
{
	remove_task(id+TASK_NVISION)
}

public event_roundnew()
{
	for(new id; id <= get_maxplayers() ; ++id)
		if(g_nvision[id] || g_nvisionenabled[id] )
	{
		g_nvision[id] = false
		g_nvisionenabled[id] = false
	}
}
public bacon_player_killed(victim,attacker,shouldgib)
{
	// Get nightvision give setting
	static nvggive
	nvggive = get_pcvar_num(cvar_nvggive)	
	
	// Disable nightvision when killed (bugfix)
	if (nvggive == 0 && g_nvision[victim])
	{
		if (g_nvisionenabled[victim] && !get_pcvar_num(cvar_cnvg)) set_user_gnvision(victim, 0)
		g_nvision[victim] = false
		g_nvisionenabled[victim] = false
	}
	
	// Turn off nightvision when killed (bugfix)
	if (nvggive == 2 && g_nvision[victim] && g_nvisionenabled[victim])
	{
		if (!get_pcvar_num(cvar_cnvg)) set_user_gnvision(victim, 0)
		g_nvisionenabled[victim] = false
	}
}

// Nightvision toggle
public clcmd_nightvision(id)
{
	if (g_nvision[id])
	{
		// Enable-disable
		g_nvisionenabled[id] = !(g_nvisionenabled[id])
		
		// Custom nvg?
		if (get_pcvar_num(cvar_cnvg))
		{
			remove_task(id+TASK_NVISION);
			set_task(0.1, "set_user_nvision", id+TASK_NVISION, _, _, "b")
		}
		else
			set_user_gnvision(id, g_nvisionenabled[id])
	}
	
	return PLUGIN_HANDLED;
}
public event_infect(victim,attacker)
{
	// Get nightvision give setting
	static nvggive
	nvggive = get_pcvar_num(cvar_nvggive)	
	
	client_printc(victim, "!g[Bio] !nPress !t(N) !nto Use NightVision")
	
	// Give Zombies Night Vision?
	if (nvggive)
	{
		g_nvision[victim] = true
		
		// Turn on Night Vision automatically?
		if (nvggive == 1)
		{
			g_nvisionenabled[victim] = true
			
			// Custom nvg?
			if (get_pcvar_num(cvar_cnvg))
			{
				remove_task(victim+TASK_NVISION)
				set_task(0.1, "set_user_nvision", victim+TASK_NVISION, _, _, "b")
			}
			else
				set_user_gnvision(victim, 1)
		}		
	}
}
// Custom Night Vision
public set_user_nvision(taskid)
{
	// Not meant to have nvision or not enabled
	if (!g_nvision[ID_NVISION] || !g_nvisionenabled[ID_NVISION] || !is_user_alive(ID_NVISION))
	{
		// Task not needed anymore
		remove_task(taskid);
		return;
	}
	
	// Get player origin and alive status
	static Float:originF[3]
	pev(ID_NVISION, pev_origin, originF)
	
	
	// Nightvision message
	message_begin(MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, ID_NVISION)
	write_byte(TE_DLIGHT) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	write_byte(get_pcvar_num(cvar_nvgsize)) // radius	
	write_byte(get_pcvar_num(cvar_nvgcolor[0])) // r
	write_byte(get_pcvar_num(cvar_nvgcolor[1])) // g
	write_byte(get_pcvar_num(cvar_nvgcolor[2])) // b	
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}
// Game Nightvision
set_user_gnvision(id, toggle)
{
	// Toggle NVG message
	message_begin(MSG_ONE, g_msgNVGToggle, _, id)
	write_byte(toggle) // toggle
	message_end()
}

// Colour Chat
client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
	write_byte(index);
	write_string(szMsg);
	message_end();
}  
