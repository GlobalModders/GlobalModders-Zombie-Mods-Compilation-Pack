#include <amxmodx>
#include <fakemeta>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Addon: Infect Effect"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define EFFECT_SPR "sprites/zombie_thehero/ef_infect.spr"
#define TASK_REMOVE_HUD 1896

new g_PlayerHud[33]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
}

public plugin_precache() engfunc(EngFunc_PrecacheModel, EFFECT_SPR)

public zbheroex_user_infected(id, Infector, Infection)
{
	if(!Infection) return
	show_hud(id, EFFECT_SPR, 0.06, 12, 0.5)
}

public fw_AddToFullPack_Post(es, e, Ent, host, host_flags, player, p_set)
{
	if(Ent != g_PlayerHud[host])
		return
	
	static Float:origin[3], Float:forvec[3], Float:voffsets[3]
	
	pev(host, pev_origin, origin)
	pev(host, pev_view_ofs, voffsets)
	xs_vec_add(origin, voffsets, origin)
	
	velocity_by_aim(host, pev(g_PlayerHud[host], pev_iuser3), forvec)
	
	xs_vec_add(origin, forvec, origin)
	engfunc(EngFunc_SetOrigin, Ent, origin)
	set_es(es, ES_Origin, origin)
	
	set_es(es, ES_RenderMode, kRenderTransAdd)
	set_es(es, ES_RenderAmt, 255)
}

public show_hud(id, const sprite[], Float:size, distance, Float:RemoveTime)
{
	remove_task(id+TASK_REMOVE_HUD)
		
	if(!pev_valid(g_PlayerHud[id])) g_PlayerHud[id] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	set_pev(g_PlayerHud[id], pev_takedamage, 0.0)
	set_pev(g_PlayerHud[id], pev_solid, SOLID_NOT)
	set_pev(g_PlayerHud[id], pev_movetype, MOVETYPE_NONE)
	
	engfunc(EngFunc_SetModel, g_PlayerHud[id], sprite)

	set_pev(g_PlayerHud[id], pev_rendermode, kRenderTransAdd)
	set_pev(g_PlayerHud[id], pev_renderamt, 0.0)
	set_pev(g_PlayerHud[id], pev_scale, size)
	set_pev(g_PlayerHud[id], pev_iuser3, distance)
	
	set_task(RemoveTime, "remove_hud", id+TASK_REMOVE_HUD)
}

public remove_hud(id)
{
	id -= TASK_REMOVE_HUD
	if(!is_user_connected(id))
		return
	
	reset_hud(id)
}

public reset_hud(id)
{
	if(pev_valid(g_PlayerHud[id]))
	{
		engfunc(EngFunc_RemoveEntity, g_PlayerHud[id])
		g_PlayerHud[id] = 0
		
		remove_task(id+TASK_REMOVE_HUD)
	} else {
		g_PlayerHud[id] = 0
		
		remove_task(id+TASK_REMOVE_HUD)
	}
}

