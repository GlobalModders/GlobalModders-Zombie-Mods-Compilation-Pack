#include <amxmodx>
#include <fakemeta>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Addon: Dias's Skill"
#define VERSION "1.0"
#define AUTHOR "author"


public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_clcmd("Set_ClawDelay", "Set_ClawDelay")
}

public Set_ClawDelay(id)
{
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(!is_user_alive(i))
			continue
		if(!zbheroex_get_user_zombie(i))
			continue
			
		set_pdata_float(i, 83, 3.0, 5)
	}
}
