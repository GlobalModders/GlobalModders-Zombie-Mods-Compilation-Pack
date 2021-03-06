/* Plugin generated by AMXX-Studio */

#include <amxmodx>
#include <fakemeta_util>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Secondary Weapon: USP"
#define VERSION "1.0"
#define AUTHOR "Dias"

new g_USP

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_USP = zbheroex_register_weapon("USP", WEAPON_SECONDARY, CSW_USP, 0)
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID != g_USP)
		return
		
	fm_give_item(id, "weapon_usp")
	engclient_cmd(id, "weapon_usp")
}
