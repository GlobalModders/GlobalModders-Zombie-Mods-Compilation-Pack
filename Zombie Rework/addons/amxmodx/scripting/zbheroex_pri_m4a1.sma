#include <amxmodx>
#include <fakemeta_util>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: M4A1"
#define VERSION "1.0"
#define AUTHOR "Dias"

new g_M4A1

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_M4A1 = zbheroex_register_weapon("M4A1 Carbine", WEAPON_PRIMARY, CSW_M4A1, 0)
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_M4A1) fm_give_item(id, "weapon_m4a1")
}