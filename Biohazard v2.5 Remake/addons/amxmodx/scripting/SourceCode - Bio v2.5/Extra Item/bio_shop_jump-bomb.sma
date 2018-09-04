#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <biohazard>
#include <bio_shop>

#define PLUGIN "[Bio] Extra Item: Jump Bomb"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define PEV_NADE_TYPE pev_flTimeStepSound
#define NADE_TYPE_KNOCK 1111

new g_jump_bomb
new g_has_jump_bomb[33]
new g_knockbomb_spr_id

new const knockbomb_sound_exp[] = "biohazard/zombi_bomb_exp.wav"
new const knockbomb_spr_exp[] = "sprites/biohazard/zombiebomb_exp.spr"

new const v_model[] = "models/biohazard/v_zombibomb.mdl"
new const p_model[] = "models/biohazard/p_zombibomb.mdl"
new const w_model[] = "models/biohazard/w_zombibomb.mdl"

new cvar_radius, cvar_power

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	register_forward(FM_SetModel, "fw_SetModel")
	register_event("DeathMsg", "event_death", "a")
	register_event("CurWeapon", "event_weapon", "be", "1=1")
	
	cvar_radius = register_cvar("bh_knockbomb_radius", "250.0")
	cvar_power = register_cvar("bh_knockbomb_power", "100.0")
	
	g_jump_bomb = bio_register_item("Knock Bomb", 5000, "Make Human KnockBack", TEAM_ZOMBIE)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheSound, knockbomb_sound_exp)
	
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	engfunc(EngFunc_PrecacheModel, w_model)
	
	g_knockbomb_spr_id = engfunc(EngFunc_PrecacheModel, knockbomb_spr_exp)
}

public bio_item_selected(id, item)
{
	if(item != g_jump_bomb)
		return PLUGIN_HANDLED
		
	g_has_jump_bomb[id] = true
	fm_give_item(id, "weapon_hegrenade")
	
	return PLUGIN_CONTINUE
}

public event_weapon(id)
{
	static curweapon
	curweapon = get_user_weapon(id)
	
	if (is_user_zombie(id) && curweapon)
	{
		// set model zonbie bom
		if (g_has_jump_bomb[id] && curweapon == CSW_HEGRENADE)
		{
			set_pev(id, pev_viewmodel2, v_model)
			set_pev(id, pev_weaponmodel2, p_model)
		}
	}
}

public fw_SetModel(entity, const model[])
{
	// check valid ent
	if (!is_valid_ent(entity)) return FMRES_IGNORED

	// We don't care
	if (strlen(model) < 8) return FMRES_IGNORED;

// ######## Zombie Bomb
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	// Get attacker
	static attacker
	attacker = pev(entity, pev_owner)
	
	if(!g_has_jump_bomb[attacker])
		return FMRES_IGNORED
	
	// Get whether grenade's owner is a zombie
	if (is_user_zombie(attacker))
	{
		if (model[9] == 'h' && model[10] == 'e') // Zombie Bomb
		{
			// Set grenade type on the thrown grenade entity
			set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_KNOCK)
			engfunc(EngFunc_SetModel, entity, w_model)
		
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED
}

public event_death()
{
	static victim
	victim = read_data(2)
	
	if(g_has_jump_bomb[victim])
		g_has_jump_bomb[victim] = false
}

public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
		
	static owner
	owner = pev(entity, pev_owner)
	
	if(!g_has_jump_bomb[owner])
		return HAM_IGNORED
	
	// Check if it's one of our custom nades
	switch (pev(entity, PEV_NADE_TYPE))
	{
		case NADE_TYPE_KNOCK:
		{
			knockbomb_explode(entity)
		}
		default: return HAM_IGNORED;
	}
	
	return HAM_SUPERCEDE;
}

public knockbomb_explode(ent)
{
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Make the explosion
	EffectZombieBomExp(ent)
	
	// explode sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, knockbomb_sound_exp, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Get attacker
	static attacker
	attacker = pev(ent, pev_owner)
	
	// Collisions
	static victim
	victim = -1
	
	new Float:fOrigin[3],Float:fDistance,Float:fDamage
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, get_pcvar_float(cvar_radius))) != 0)
	{
		// Only effect alive non-spawnprotected humans
		if (!is_user_alive(victim))
			continue;
		
		// get value
		pev(victim, pev_origin, fOrigin)
		fDistance = get_distance_f(fOrigin, originF)
		fDamage = get_pcvar_float(cvar_power) - floatmul(get_pcvar_float(cvar_power), floatdiv(fDistance, get_pcvar_float(cvar_radius)))//get the damage value
		fDamage *= estimate_take_hurt(originF, victim, 0)//adjust
		if ( fDamage < 0 )
			continue

		// create effect
		manage_effect_action(victim, fOrigin, originF, fDistance, fDamage * 35.0)
		ExecuteHam(Ham_TakeDamage, victim, attacker, attacker, 0, DMG_BULLET)
	}
	
	g_has_jump_bomb[attacker] = false
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, ent)
}
public EffectZombieBomExp(id)
{
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(g_knockbomb_spr_id); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
}
public manage_effect_action(iEnt, Float:fEntOrigin[3], Float:fPoint[3], Float:fDistance, Float:fDamage)
{
	//return 1
	new Float:Velocity[3]
	pev(iEnt, pev_velocity, Velocity)
	
	new Float:fTime = floatdiv(fDistance, fDamage)
	new Float:fVelocity[3]
	fVelocity[0] = floatdiv((fEntOrigin[0] - fPoint[0]), fTime)
	fVelocity[1] = floatdiv((fEntOrigin[1] - fPoint[1]), fTime)
	fVelocity[2] = floatdiv((fEntOrigin[2] - fPoint[2]), fTime)
	set_pev(iEnt, pev_velocity, fVelocity)
	return 1
}

stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}

stock Float:estimate_take_hurt(Float:fPoint[3], ent, ignored) 
{
	new Float:fOrigin[3]
	new tr
	new Float:fFraction
	pev(ent, pev_origin, fOrigin)
	//UTIL_TraceLine ( vecSpot, vecSpot + Vector ( 0, 0, -40 ),  ignore_monsters, ENT(pev), & tr)
	engfunc(EngFunc_TraceLine, fPoint, fOrigin, DONT_IGNORE_MONSTERS, ignored, tr)
	get_tr2(tr, TR_flFraction, fFraction)
	if ( fFraction == 1.0 || get_tr2( tr, TR_pHit ) == ent )//no valid enity between the explode point & player
		return 1.0
	return 0.6//if has fraise, lessen blast hurt
}
