#include <amxmodx>
#include <engine>
#include <biohazard>
#include <bio_shop>
#include <fakemeta_util>
#include <hamsandwich>

#define PLUGIN "[Bio] Item: Force Field Grenade"
#define VERSION "v2.1"
#define AUTHOR "lucas_7_94" // Thanks To Users in credits too!.

#define CAMPO_TIME_NAME "Force Shield Grenade"
#define ValidTouch(%1) (is_user_alive(%1) && (is_user_zombie(%1) || is_user_boss(%1)))

/*=============================[Plugin Customization]=============================*/
#define CAMPO_TASK

#define RANDOM_COLOR
//#define ONE_COLOR

new const NADE_TYPE_CAMPO = 3679

#if defined ONE_COLOR
new Float:CampoColors[3] = { 
	255.0 , // r
	0.0 ,   // g
	0.0     // b
}
#endif

new const model_grenade[] = "models/biohazard/v_ffg.mdl"
new const model[] = "models/biohazard/ffg_god.mdl"
new const w_model[] = "models/biohazard/w_ffg.mdl"
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const entclas[] = "campo_grenade_forze"

new g_trailSpr, cvar_push, g_SayText, g_itemID
new bool:g_bomb[33]
const item_cost = 9500
/*=============================[End Customization]=============================*/

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Item_Deploy, "weapon_smokegrenade", "shield_deploy", 1)
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_forward(FM_Touch, "fw_touch")

	cvar_push = register_cvar("bh_force_push", "7.5")
	
	g_SayText = get_user_msgid("SayText")
	g_itemID = bio_register_item(CAMPO_TIME_NAME, item_cost, "Defense Zombies", TEAM_HUMAN)
	
}

public event_round_start()
{
	arrayset(g_bomb, false, 33)
	remove_entity_name(entclas)
}

public plugin_precache() 
{
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)
	
	engfunc(EngFunc_PrecacheModel, model_grenade)
	engfunc(EngFunc_PrecacheModel, model)
	engfunc(EngFunc_PrecacheModel, w_model)
}

public client_disconnect(id) 
{
	arrayset(g_bomb, false, 33)
}

public bio_item_selected(player, itemid) 
{
	if(itemid == g_itemID)
	{
		if(g_bomb[player]) 
		{
			Color(player, "!g[Bio]!y You already have a !tForce Field!y !!!")
		} else {
			arrayset(g_bomb, true, player)
			
			fm_give_item(player, "weapon_smokegrenade")
			Color(player, "!g[Bio]!y You Bought a !tForce Field!y !!!. This, lasts very little!")
		}
	}
	
}
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	arrayset(g_bomb, false, 33)
}

public fw_ThinkGrenade(entity)
{   
	if(!pev_valid(entity)) 
		return HAM_IGNORED
	
	static Float:dmgtime   
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime != 0.0)
		return HAM_IGNORED   
	
	if(pev(entity, pev_flTimeStepSound) == NADE_TYPE_CAMPO)
	{
		crear_ent(entity)
		new owner = pev(entity, pev_owner)
		client_print(owner, print_chat, "OK")
	}
	
	return HAM_SUPERCEDE
}

public fw_SetModel(entity, const model[]) 
{	
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	if (dmgtime != 0.0)
		return FMRES_IGNORED
	
	if (equal(model[7], "w_sm", 4))
	{		
		new owner = pev(entity, pev_owner)	

		if(is_user_alive(owner) && !is_user_zombie(owner) && g_bomb[owner]) 
		{
			client_print(owner, print_chat, "Not OK")
			
			fm_set_rendering(entity, kRenderFxGlowShell, 000, 255, 255, kRenderNormal, 16)
			
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_BEAMFOLLOW) // TE id
			write_short(entity) // entity
			write_short(g_trailSpr) // sprite
			write_byte(10) // life
			write_byte(10) // width
			write_byte(000) // r
			write_byte(255) // g
			write_byte(255) // b
			write_byte(500) // brightness
			message_end()
			
			set_pev(entity, pev_flTimeStepSound, NADE_TYPE_CAMPO)
			
			set_task(6.0, "DeleteEntityGrenade", entity)
			entity_set_model(entity, w_model)
			
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
	
}

public DeleteEntityGrenade(entity)
{
	remove_entity(entity)
}

public crear_ent(id) 
{
	arrayset(g_bomb, false, id)
	
	// Create entitity
	new iEntity = create_entity("info_target")
	
	if(!is_valid_ent(iEntity))
		return PLUGIN_HANDLED
	
	new Float: Origin[3] 
	entity_get_vector(id, EV_VEC_origin, Origin) 
	
	entity_set_string(iEntity, EV_SZ_classname, entclas)
	
	entity_set_vector(iEntity,EV_VEC_origin, Origin)
	entity_set_model(iEntity,model)
	entity_set_int(iEntity, EV_INT_solid, SOLID_TRIGGER)
	entity_set_size(iEntity, Float: {-100.0, -100.0, -100.0}, Float: {100.0, 100.0, 100.0})
	entity_set_int(iEntity, EV_INT_renderfx, kRenderFxGlowShell)
	entity_set_int(iEntity, EV_INT_rendermode, kRenderTransAlpha)
	entity_set_float(iEntity, EV_FL_renderamt, 50.0)
	
	#if defined RANDOM_COLOR
	if(is_valid_ent(iEntity))
	{
		new Float:vColor[3]
		
		for(new i; i < 3; i++)
			vColor[i] = random_float(0.0, 255.0)
		
		entity_set_vector(iEntity, EV_VEC_rendercolor, vColor)
	}
	#endif
	
	#if defined CAMPO_TASK
	set_task(15.0, "DeleteEntity", iEntity)
	#endif
	
	return PLUGIN_CONTINUE;
}

public event_infect(infected, infector) 
{
	if (g_bomb[infected]) 
	{
		arrayset(g_bomb, false, infected)
	}
}

public fw_touch(ent, touched)
{
	if (!pev_valid(ent))
		return FMRES_IGNORED
		
	static entclass[32]
	pev(ent, pev_classname, entclass, 31)
	
	if (equali(entclass, entclas))
	{	
		if(ValidTouch(touched))
		{
			new Float:pos_ptr[3], Float:pos_ptd[3], Float:push_power = get_pcvar_float(cvar_push)
			
			pev(ent, pev_origin, pos_ptr)
			pev(touched, pev_origin, pos_ptd)
			
			for(new i = 0; i < 3; i++)
			{
				pos_ptd[i] -= pos_ptr[i]
				pos_ptd[i] *= push_power
			}
			
			set_pev(touched, pev_velocity, pos_ptd)
			set_pev(touched, pev_impulse, pos_ptd)
		}
	}
	return PLUGIN_HANDLED
}

public remove_ent() 
{
	remove_entity_name(entclas)
}  

public DeleteEntity(entity)
{
	if(is_valid_ent(entity)) 
		remove_entity(entity)
}

stock Color(const id, const input[], any:...)
{
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	
	message_begin(MSG_ONE_UNRELIABLE, g_SayText, _, id)
	write_byte(id)
	write_string(msg)
	message_end()
}

public shield_deploy(shield_ent)
{
	if(pev_valid( shield_ent ) != 2)
		return HAM_IGNORED;
	
	new id = get_pdata_cbase(shield_ent, 41, 4)
	
	if(g_bomb[id] && !is_user_zombie(id))
		set_pev(id, pev_viewmodel2, model_grenade)
	
	return HAM_IGNORED
}
