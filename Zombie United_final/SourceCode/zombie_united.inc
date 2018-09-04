/* #####################################################
	---------------------------------------
	-*- NST Zombie Includes File -*-
	---------------------------------------
###################################################### */ 

// define value
#define LANG_FILE "zombie_united.txt"
#define CLASS_FILE "zombie_united_class.ini"

enum
{
	NSTZB_ZB3 = 1,
	NSTZB_ZBU,
	NSTZB_ZBS
}

// get mod running
native nst_zb_get_mod()

// kiem tra xem player co plai la zombie khong
native nst_zb_get_user_zombie(id)

// tra ve level cua player
native nst_zb_get_user_level(id)

// tra ve level cua player
native nst_zb_get_user_zombie_class(id)

// kiem tra xem player co phai la hero khong
native nst_zb_get_user_hero(id)

// get start health
native nst_zb_get_user_start_health(id)

// get sex of player
native nst_zb_get_user_sex(id)

// respawn zombie
native nst_zb_zombie_respawn(id)

// remove weapons in new round? 1 is remove - 2 is no
native nst_zb_remove_weapons_newround()

// Human kill Zombie
native nst_zb_human_kill_zombie(killer, victim, headshot)

// show chat text
native nst_zb_color_saytext(player, const message[], any:...)

// get max level human
native nst_zb_get_maxlevel_human()

// get weapons ammo
native nst_zb_get_weapons_ammo(idwpn)

// get damage attack
native nst_zb_get_user_damage_attack(id)

// set damage attack
native nst_zb_set_user_damage_attack(id, damage)

// get can take damage
native nst_zb_get_take_damage()

// get he take damage
native nst_zb_get_damage_nade()

// register zombie class of Zombie Mod3
native nst_zb3_register_zombie_class(const name[], const model[], Float:gravity, Float:speed, Float:knockback, const sound_death1[], const sound_death2[], const sound_hurt1[], const sound_hurt2[], const sound_heal[], const sound_evolution[], sex, modelindex)

// register zombie class of Zombie United
native nst_zbu_register_zombie_class(const name[], const model[], health, Float:gravity, Float:speed, Float:knockback, const sound_death1[], const sound_death2[], const sound_hurt1[], const sound_hurt2[], const sound_heal[], sex, modelindex)

// register zombie class of Zombie Scenario
native nst_zbs_register_zombie_class(const name[], const model[], health, Float:gravity, Float:speed, Float:knockback, const sound_death1[], const sound_death2[], const sound_hurt1[], const sound_hurt2[], const sound_heal[], sex, modelindex, boss)

/**
 * Called when a human attack zombie
 *
 * @param attacker	Player index who was attack
 * @param damage	damage fire
 */
forward nst_zb_human_damage(attacker, damage, type)

/**
 * Called when a player gets infected.
 *
 * @param id		Player index who was infected.
 * @param infector	Player index who infected him (if applicable).
 */
forward nst_zb_user_infected(id, infector)




/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1034\\ f0\\ fs16 \n\\ par }
*/
