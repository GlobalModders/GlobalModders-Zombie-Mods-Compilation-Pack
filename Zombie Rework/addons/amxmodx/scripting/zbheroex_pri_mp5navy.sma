#include <amxmodx>
#include <fakemeta_util>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: MP5NAVY"
#define VERSION "1.0"
#define AUTHOR "Dias"

new g_MP5

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_MP5 = zbheroex_register_weapon("MP5 Navy", WEAPON_PRIMARY, CSW_MP5NAVY, 0)
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_MP5) fm_give_item(id, "weapon_mp5navy")
}
