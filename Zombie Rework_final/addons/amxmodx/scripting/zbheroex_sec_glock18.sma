#include <amxmodx>
#include <fakemeta_util>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Secondary Weapon: Glock-18"
#define VERSION "1.0"
#define AUTHOR "Dias"

new g_Glock18

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_Glock18 = zbheroex_register_weapon("Glock-18", WEAPON_SECONDARY, CSW_GLOCK18, 0)
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID != g_Glock18)
		return
		
	fm_give_item(id, "weapon_glock18")
	engclient_cmd(id, "weapon_glock18")
}
