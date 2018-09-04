#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <biohazard>
#include <bio_shop>

#define PLUGIN "[Bio] Shop: Hammer"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define is_user_valid_connected(%1) (1 <= %1 <= get_maxplayers() && is_user_connected(%1))

new const v_model[] = "models/biohazard/v_hammer.mdl"
new const p_model[] = "models/biohazard/p_hammer.mdl"

new bool:had_hammer[33]
new g_attacking[33]

new g_hammer

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "fw_hammer_deploy")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_knife", "fw_hammer_pri_attack")
	RegisterHam(Ham_TakeDamage, "player", "fw_hammer_takedmg")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack")
	RegisterHam(Ham_Weapon_SecondaryAttack, "weapon_knife", "fw_SecondaryAttack_Post", 1)	
	RegisterHam(Ham_Spawn, "player", "fw_spawn_post", 1)
	
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")	
	
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_clcmd("lastinv", "check_lastinv")
	
	g_hammer = bio_register_item("Hammer", 9500, "Attack far enemy and x5 dmg", TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
}

public bio_item_selected(id, item)
{
	if(item == g_hammer)
	{
		had_hammer[id] = true
		engclient_cmd(id, "weapon_knife")
	}
}

public fw_spawn_post(id)
{
	had_hammer[id] = false
}

public event_infect(id)
{
	had_hammer[id] = false
}

public fw_hammer_deploy(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(is_user_alive(id) && had_hammer[id])
		play_weapon_anim(id, 1)
}

public check_lastinv(id)
{
	if(get_user_weapon(id) == CSW_KNIFE && had_hammer[id])
		play_weapon_anim(id, 1)
}

public event_curweapon(id)
{
	if(!is_user_alive(id) || get_user_weapon(id) != CSW_KNIFE)
		return PLUGIN_HANDLED
		
	if(is_user_zombie(id))
		return PLUGIN_HANDLED
	
	if(!had_hammer[id])
		return PLUGIN_HANDLED
	
	set_pev(id, pev_viewmodel2, v_model)
	set_pev(id, pev_weaponmodel2, p_model)
	
	return PLUGIN_CONTINUE
}

public fw_hammer_pri_attack(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	if(!had_hammer[id])
		return HAM_IGNORED
	
	play_weapon_anim(id, 0)
	
	return HAM_SUPERCEDE
}

public fw_hammer_takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_alive(victim) || !is_user_alive(attacker))
		return HAM_IGNORED
		
	if(!is_user_zombie(victim))
		return HAM_IGNORED
		
	if(!had_hammer[attacker])
		return HAM_IGNORED
		
	SetHamParamFloat(4, damage * 5.0)
	
	return HAM_HANDLED
}

public fw_SecondaryAttack(weapon_ent)
{
	// Not valid
	if (!pev_valid(weapon_ent))
		return;
	
	// Get owner
	static owner
	owner = pev(weapon_ent, pev_owner)
	
	// Replace these for zombie only
	if (!is_user_valid_connected(owner))
		return;
	
	g_attacking[owner] = 2
}

public fw_SecondaryAttack_Post(weapon_ent)
{
	// Not valid
	if (!pev_valid(weapon_ent))
		return;
	
	// Get owner
	static owner
	owner = pev(weapon_ent, pev_owner)
	
	// Replace these for zombie only
	if (!is_user_valid_connected(owner))
		return;
	
	g_attacking[owner] = 0
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	// Replace these for zombie only
	if (!is_user_valid_connected(id))
		return FMRES_IGNORED;
	
	// Not alive
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	// Not using knife
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED;
		
	if(!had_hammer[id])
		return FMRES_IGNORED		
	
	// Not attacking
	if (!g_attacking[id])
		return FMRES_IGNORED;
	
	pev(id, pev_v_angle, vector_end)
	angle_vector(vector_end, ANGLEVECTOR_FORWARD, vector_end)
	
	if (g_attacking[id] == 1)
		xs_vec_mul_scalar(vector_end, 70.0, vector_end)
	else
		xs_vec_mul_scalar(vector_end, 85.0, vector_end)
	
	xs_vec_add(vector_start, vector_end, vector_end)
	engfunc(EngFunc_TraceLine, vector_start, vector_end, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE;
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	// Replace these for zombie only
	if (!is_user_valid_connected(id))
		return FMRES_IGNORED;
	
	// Not alive
	if (!is_user_alive(id))
		return FMRES_IGNORED;
	
	// Not using knife
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED;
		
	if(!had_hammer[id])
		return FMRES_IGNORED
	
	// Not attacking
	if (!g_attacking[id])
		return FMRES_IGNORED;
	
	pev(id, pev_v_angle, vector_end)
	angle_vector(vector_end, ANGLEVECTOR_FORWARD, vector_end)
	
	if (g_attacking[id] == 1)
		xs_vec_mul_scalar(vector_end, 70.0, vector_end)
	else
		xs_vec_mul_scalar(vector_end, 85.0, vector_end)
	
	xs_vec_add(vector_start, vector_end, vector_end)
	engfunc(EngFunc_TraceHull, vector_start, vector_end, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE;
}

stock play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}
