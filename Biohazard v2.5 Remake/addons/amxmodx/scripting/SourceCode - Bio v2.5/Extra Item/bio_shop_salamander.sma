#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <biohazard>
#include <bio_shop>
#include <cstrike>

new const fire_classname[] = "fire_salamander"
new const fire_spr_name[] = "sprites/biohazard/fire_salamander.spr"

new const v_model[] = "models/biohazard/v_salamander.mdl"
new const p_model[] = "models/biohazard/p_salamander.mdl"
new const w_model[] = "models/biohazard/w_salamander.mdl"

new const fire_sound[] = "weapons/flamegun-2.wav"

// HARD CODE
#define CSW_SALAMANDER CSW_M249
#define PEV_ENT_TIME pev_fuser1
#define TASK_FIRE 3123123
#define TASK_RELOAD 2342342
new g_had_salamander[33], bool:is_firing[33], bool:is_reloading[33], Float:g_last_fire[33],
bool:can_fire[33], g_reload_ammo[33], g_ammo[33]

enum
{
	IDLE_ANIM = 0,
	DRAW_ANIM = 4,
	RELOAD_ANIM = 3,
	SHOOT_ANIM = 1,
	SHOOT_END_ANIM = 2
}

new g_salamander
new cvar_dmgrd_start, cvar_dmgrd_end, cvar_fire_delay, cvar_max_clip

public plugin_init()
{
	register_plugin("[Bio] Extra Item: Salamander", "1.0", "Dias")
	
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	RegisterHam(Ham_Spawn, "player", "fw_spawn", 1)
	RegisterHam(Ham_Weapon_Reload, "weapon_m249", "fw_weapon_reload", 1)
	RegisterHam(Ham_Item_Deploy, "weapon_m249", "fw_weapon_deploy", 1)
	RegisterHam(Ham_Item_PostFrame, "weapon_m249", "fw_item_postframe", 1)
	RegisterHam(Ham_Item_AddToPlayer, "weapon_m249", "fw_item_addtoplayer", 1)
	register_forward(FM_CmdStart, "fw_cmdstart")
	register_touch(fire_classname, "*", "fw_touch")
	register_think(fire_classname, "fw_think")
	register_forward(FM_SetModel, "fw_SetModel")
	
	register_clcmd("lastinv", "check_lastinv")
	
	g_salamander = bio_register_item("Salamander", 16000, "A powerful Flamethrower", TEAM_HUMAN)
	
	cvar_dmgrd_start = register_cvar("bh_salamander_dmgrandom_start", "30.0")
	cvar_dmgrd_end = register_cvar("bh_salamander_dmgrandom_end", "60.0")
	cvar_fire_delay = register_cvar("bh_salamander_fire_delay", "0.1")
	cvar_max_clip = register_cvar("bh_salamander_max_clip", "100")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	
	precache_model(fire_spr_name)
	precache_sound(fire_sound)
	
	precache_sound("weapons/flamegun-1.wav")
	precache_sound("weapons/flamegun_clipin1.wav")
	precache_sound("weapons/flamegun_clipout1.wav")
	precache_sound("weapons/flamegun_clipout2.wav")
	precache_sound("weapons/flamegun_draw.wav")
}

public fw_spawn(id)
{
	if(g_had_salamander[id])
		g_had_salamander[id] = false
		
	if(task_exists(id+TASK_FIRE)) remove_task(id+TASK_FIRE)
	if(task_exists(id+TASK_RELOAD)) remove_task(id+TASK_RELOAD)
	
	remove_entity_name(fire_classname)
}

public bio_item_selected(id, itemid)
{
	if(itemid == g_salamander)
	{
		g_had_salamander[id] = true
		is_reloading[id] = false
		is_firing[id] = false
		can_fire[id] = true
		
		fm_give_item(id, "weapon_m249")
		g_ammo[id] = 100
		cs_set_user_bpammo(id, CSW_SALAMANDER, 200)
	}
}

public fw_item_postframe(ent)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return HAM_IGNORED
	
	if(get_user_weapon(id) != CSW_SALAMANDER || !g_had_salamander[id])
		return HAM_IGNORED
		
	if(!is_reloading[id])
	{
		static iAnim
		iAnim = pev(id, pev_weaponanim)
		
		if(iAnim == RELOAD_ANIM)
			play_weapon_anim(id, IDLE_ANIM)
	}
		
	static salamander
	salamander = fm_find_ent_by_class(-1, "weapon_m249")
	
	set_pdata_int(salamander, 54, 0, 4)
	
	return HAM_HANDLED
}

public fw_item_addtoplayer(ent, id)
{
	if(!is_valid_ent(ent))
		return HAM_IGNORED
		
	if(is_user_zombie(id) || is_user_boss(id))
		return HAM_IGNORED
			
	if(entity_get_int(ent, EV_INT_impulse) == 701)
	{
		g_had_salamander[id] = true
		g_ammo[id] = pev(ent, pev_iuser3)
		entity_set_int(id, EV_INT_impulse, 0)
		
		play_weapon_anim(id, DRAW_ANIM)
		set_task(1.0, "make_wpn_canfire", id)
		
		return HAM_HANDLED
	}		

	return HAM_HANDLED
}

public check_lastinv(id)
{
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return PLUGIN_HANDLED
		
	if(get_user_weapon(id) == CSW_SALAMANDER && g_had_salamander[id])
	{
		set_task(0.5, "start_check_draw", id)
	}
	
	return PLUGIN_CONTINUE
}

public start_check_draw(id)
{
	if(can_fire[id])
		can_fire[id] = false
}

public event_curweapon(id)
{
	if(is_user_alive(id) && get_user_weapon(id) == CSW_SALAMANDER && g_had_salamander[id] && !is_user_zombie(id) && !is_user_boss(id))
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
	}
}

public fw_weapon_deploy(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return HAM_IGNORED
	
	if(!g_had_salamander[id])
		return HAM_IGNORED
		
	can_fire[id] = false
	
	play_weapon_anim(id, DRAW_ANIM)
	set_task(1.0, "make_wpn_canfire", id)
		
	return HAM_HANDLED
}

public make_wpn_canfire(id)
{
	can_fire[id] = true
}

public fw_weapon_reload(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return HAM_IGNORED
	
	if(get_user_weapon(id) != CSW_SALAMANDER && !g_had_salamander[id])
		return HAM_IGNORED
		
	return HAM_SUPERCEDE
}

public client_PostThink(id)
{
	if(is_user_alive(id) && is_user_connected(id) && !is_user_zombie(id) && !is_user_boss(id))
	{
		if(g_had_salamander[id] && get_user_weapon(id) != CSW_SALAMANDER)
		{
			if(can_fire[id])
				can_fire[id] = false
				
			if(is_reloading[id])
			{
				is_reloading[id] = false
				if(task_exists(id+TASK_RELOAD)) remove_task(id+TASK_RELOAD)
			}			
		} else if(g_had_salamander[id] && get_user_weapon(id) == CSW_SALAMANDER) {
			static salamander
			salamander = fm_get_user_weapon_entity(id, CSW_M249)
			
			cs_set_weapon_ammo(salamander, g_ammo[id])
		}
	}
}

public fw_SetModel(entity, model[])
{
	if(!is_valid_ent(entity))
		return FMRES_IGNORED;
	
	static szClassName[33]
	entity_get_string(entity, EV_SZ_classname, szClassName, charsmax(szClassName))
	
	if(!equal(szClassName, "weaponbox"))
		return FMRES_IGNORED;
	
	static iOwner
	iOwner = entity_get_edict(entity, EV_ENT_owner)
	
	if(equal(model, "models/w_m249.mdl"))
	{
		static iStoredAugID
		iStoredAugID = find_ent_by_owner(-1, "weapon_m249", entity)
		
		if(!is_valid_ent(iStoredAugID))
			return FMRES_IGNORED;
		
		if(g_had_salamander[iOwner])
		{
			entity_set_int(iStoredAugID, EV_INT_impulse, 701)
			g_had_salamander[iOwner] = false
			set_pev(iStoredAugID, pev_iuser3, g_ammo[iOwner])
			entity_set_model(entity, w_model)
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return FMRES_IGNORED
	
	if(get_user_weapon(id) != CSW_SALAMANDER || !g_had_salamander[id])
		return FMRES_IGNORED
		
	set_cd(cd_handle, CD_flNextAttack, halflife_time() + 0.001)  

	return FMRES_HANDLED
}

public fw_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id) || is_user_zombie(id) || is_user_boss(id))
		return FMRES_IGNORED
	
	if(get_user_weapon(id) != CSW_SALAMANDER || !g_had_salamander[id])
		return FMRES_IGNORED
	
	static Button
	Button = get_uc(uc_handle, UC_Buttons)
	
	if(Button & IN_ATTACK)
	{
		if((get_gametime() - get_pcvar_float(cvar_fire_delay) > g_last_fire[id]))
		{
			if(can_fire[id] && !is_reloading[id])
			{
				if(g_ammo[id] > 0)
				{
					if(pev(id, pev_weaponanim) != SHOOT_ANIM)
						play_weapon_anim(id, SHOOT_ANIM)
					
					if(task_exists(id+TASK_FIRE)) remove_task(id+TASK_FIRE)
					is_firing[id] = true
					throw_fire(id)
					emit_sound(id, CHAN_WEAPON, "weapons/flamegun-2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_ammo[id]--
				}

			}
			g_last_fire[id] = get_gametime()
		}
	} else {
		if(is_firing[id])
		{
			if(!task_exists(id+TASK_FIRE))
			{
				set_task(0.1, "stop_fire", id+TASK_FIRE)
				emit_sound(id, CHAN_WEAPON, "weapons/flamegun-2.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
		}
		
	}
	
	if(Button & IN_RELOAD)
	{
		if(!is_reloading[id] && !is_firing[id])
		{
			static curammo, require_ammo, bpammo
			
			curammo = g_ammo[id]
			bpammo = cs_get_user_bpammo(id, CSW_SALAMANDER)
			require_ammo = get_pcvar_num(cvar_max_clip) - curammo
			
			if(bpammo > require_ammo)
			{
				g_reload_ammo[id] = require_ammo
			} else {
				g_reload_ammo[id] = bpammo
			}
			
			if(g_ammo[id] < get_pcvar_num(cvar_max_clip) && bpammo > 0)
			{
				is_reloading[id] = true
				play_weapon_anim(id, RELOAD_ANIM)
			
				set_task(5.0, "finish_reload", id+TASK_RELOAD)
			}
		}
	}
	
	Button &= ~IN_ATTACK
	set_uc(uc_handle, UC_Buttons, Button)
	
	Button &= ~IN_RELOAD
	set_uc(uc_handle, UC_Buttons, Button)
	
	return FMRES_HANDLED
}

public finish_reload(id)
{
	id -= TASK_RELOAD

	g_ammo[id] += g_reload_ammo[id]
	cs_set_user_bpammo(id, CSW_SALAMANDER, cs_get_user_bpammo(id, CSW_SALAMANDER) - g_reload_ammo[id])
	is_reloading[id] = false
}

public stop_fire(id)
{
	id -= TASK_FIRE
	
	is_firing[id] = false
	if(pev(id, pev_weaponanim) != SHOOT_END_ANIM)
		play_weapon_anim(id, SHOOT_END_ANIM)	
}

public throw_fire(id)
{
	new iEnt = create_entity("env_sprite")
	new Float:vfVelocity[3]
	
	velocity_by_aim(id, 500, vfVelocity)
	xs_vec_mul_scalar(vfVelocity, 0.4, vfVelocity)
	
	// add velocity of Owner for ent
	new Float:fOwnerVel[3], Float:vfAttack[3], Float:vfAngle[3]
	pev(id, pev_angles, vfAngle)
	//pev(id, pev_origin, vfAttack)
	get_weapon_attackment(id, vfAttack, 20.0)
	vfAttack[2] -= 7.0
	//vfAttack[1] += 7.0
	pev(id, pev_velocity, fOwnerVel)
	fOwnerVel[2] = 0.0
	xs_vec_add(vfVelocity, fOwnerVel, vfVelocity)
	
	// set info for ent
	set_pev(iEnt, pev_movetype, MOVETYPE_FLY)
	set_pev(iEnt, pev_rendermode, kRenderTransAdd)
	set_pev(iEnt, pev_renderamt, 150.0)
	set_pev(iEnt, PEV_ENT_TIME, get_gametime() + 1.5)	// time remove
	set_pev(iEnt, pev_scale, 0.2)
	set_pev(iEnt, pev_nextthink, halflife_time() + 0.05)
	
	set_pev(iEnt, pev_classname, fire_classname)
	engfunc(EngFunc_SetModel, iEnt, fire_spr_name)
	set_pev(iEnt, pev_mins, Float:{-1.0, -1.0, -1.0})
	set_pev(iEnt, pev_maxs, Float:{1.0, 1.0, 1.0})
	set_pev(iEnt, pev_origin, vfAttack)
	set_pev(iEnt, pev_gravity, 0.01)
	set_pev(iEnt, pev_velocity, vfVelocity)
	vfAngle[1] += 30.0
	set_pev(iEnt, pev_angles, vfAngle)
	set_pev(iEnt, pev_solid, SOLID_BBOX)
	set_pev(iEnt, pev_owner, id)
	set_pev(iEnt, pev_iuser2, 1)
}

public fw_think(iEnt)
{
	if ( !pev_valid(iEnt) ) return;
	
	new Float:fFrame, Float:fScale, Float:fNextThink
	pev(iEnt, pev_frame, fFrame)
	pev(iEnt, pev_scale, fScale)
	
	// effect exp
	new iMoveType = pev(iEnt, pev_movetype)
	if (iMoveType == MOVETYPE_NONE)
	{
		fNextThink = 0.015
		fFrame += 1.0
		
		if (fFrame > 21.0)
		{
			engfunc(EngFunc_RemoveEntity, iEnt)
			return
		}
	}
	
	// effect normal
	else
	{
		fNextThink = 0.045
		fFrame += 1.0
		fFrame = floatmin(21.0, fFrame)
	}
	
	fScale = (entity_range(iEnt, pev(iEnt, pev_owner)) / 500) * 3.0
	
	set_pev(iEnt, pev_frame, fFrame)
	set_pev(iEnt, pev_scale, fScale)
	set_pev(iEnt, pev_nextthink, halflife_time() + fNextThink)
	
	
	// time remove
	new Float:fTimeRemove
	pev(iEnt, PEV_ENT_TIME, fTimeRemove)
	if (get_gametime() >= fTimeRemove)
	{
		engfunc(EngFunc_RemoveEntity, iEnt)
		return;
	}
}

public fw_touch(ent, id)
{
	set_pev(ent, pev_movetype, MOVETYPE_NONE)
	set_pev(ent, pev_solid, SOLID_NOT)	
	
	if(!is_valid_ent(id))
		return FMRES_IGNORED
	
	if(!is_user_alive(id) || !is_user_connected(id) || !is_user_zombie(id))
		return FMRES_IGNORED
	
	if(pev(ent, pev_iuser2) == 1)
	{
		set_pev(ent, pev_iuser2, 0)
		
		static attacker, ent_kill
		
		attacker = pev(ent, pev_owner)
		ent_kill = fm_get_user_weapon_entity(id, CSW_KNIFE)
		
		
		ExecuteHam(Ham_TakeDamage, id, ent_kill, attacker, random_float(get_pcvar_float(cvar_dmgrd_start), get_pcvar_float(cvar_dmgrd_end)), DMG_BULLET)		
	}
	return FMRES_HANDLED
}

stock play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock get_weapon_attackment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}
