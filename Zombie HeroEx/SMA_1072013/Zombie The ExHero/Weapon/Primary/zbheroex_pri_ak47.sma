#include <amxmodx>
#include <fakemeta_util>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: AK47"
#define VERSION "1.0"
#define AUTHOR "Dias"

new g_AK47

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
}

public plugin_precache()
{
	g_AK47 = zbheroex_register_weapon("AK-47", WEAPON_PRIMARY, CSW_AK47, 0)
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_AK47) fm_give_item(id, "weapon_ak47")
}
