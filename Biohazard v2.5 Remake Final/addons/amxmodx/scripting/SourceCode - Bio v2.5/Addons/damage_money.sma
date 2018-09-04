#include <amxmodx>
#include <hamsandwich>
#include <biohazard>
#include <cstrike>

public plugin_init()
{
	register_plugin("Damage Money", "1.0", "Dias")

	RegisterHam(Ham_TakeDamage, "player", "fw_take_damage")
}

public fw_take_damage(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(is_user_zombie(attacker) || !is_user_zombie(victim))
		return HAM_IGNORED
		
	if(damage == 0.0)
		return HAM_IGNORED
		
	cs_set_user_money(attacker, cs_get_user_money(attacker) + floatround(damage))
		
	return HAM_HANDLED
}
