/* #####################################################	---------------------------------------	-*- Zombie Escape Mod - Native -*-	---------------------------------------###################################################### */ 
enum{	
	START_TYPE_NEW = 0,	
	START_ZOMBIE_APPEAR,	
	START_ZOMBIE_RELEASE
}


enum{	ZE_TEAM_ZOMBIE = 1,	
	ZE_TEAM_HUMAN = 2,	
	ZE_TEAM_ALL = 5,	
	ZE_TEAM_START = 6
}

enum
{	ZOMBIE_TYPE_HOST = 0,	
	ZOMBIE_TYPE_ORIGIN
}
forward ze_user_infected(id, infector);forward ze_user_humanized(id);forward ze_gamestart(starttype);
forward ze_roundend(winteam);forward ze_extraitem_selected(id, itemid);native ze_is_user_zombie(id);native ze_get_zombie_type(id);native ze_set_user_zombie(id, zombietype);
native ze_set_user_human(id);
native ze_register_extraitem(const Name[], Cost, const Desc[], Team);native ze_set_stopgame(stop_type, onoff);native ze_reset_gameplay(restart);