/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Melee Weapon: Seal Knife"
#define VERSION "1.0"
#define AUTHOR "Dias"


public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	zbheroex_register_weapon("Seal Knife", WEAPON_MELEE, CSW_KNIFE, 0)
}