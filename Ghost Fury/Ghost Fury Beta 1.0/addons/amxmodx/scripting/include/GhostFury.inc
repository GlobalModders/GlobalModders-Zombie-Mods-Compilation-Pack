/* ===========================================
Name: Ghost Fury
Type: Gameplay API
Author: Dias Pendragon
============================================ */

enum
{
	WPN_PRIMARY = 1,
	WPN_SECONDARY,
	WPN_MELEE
}

// Normal Natives
native gf_get_user_ghost(id); 
native gf_get_user_originghost(id);
native gf_get_user_maxhealth(id);
native gf_set_user_nvg(id, Give, On, Sound, IgnoreHadNVG);
native gf_get_user_nvg(id, Have, On);
native gf_get_user_infinitewalking(id);
native gf_set_user_infinitewalking(id, On);
native gf_set_user_speed(id, Float:Speed, BlockSpeed);
native gf_get_round_timeleft(id);

// Forward
forward gf_user_transghost_pre(id, killer, transformation);
forward gf_user_transghost_post(id, killer, transformation);
forward gf_user_spawn(id);
forward gf_user_died(id, killer);
forward gf_user_nvg(id, on, Ghost);
forward gf_round_new();
forward gf_round_start();
forward gf_game_start();
forward gf_round_end(CsTeams:WinTeam);
forward gf_round_time(TimeLeft);

// Weapon
native gf_weapon_register(const Name[], Type, BasedOn, Cost);
native gf_weapon_get_cswid(id, ItemID);

forward gf_weapon_bought(id, ItemID);
forward gf_weapon_remove(id, ItemID);
forward gf_weapon_addammo(id, ItemID);

/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
