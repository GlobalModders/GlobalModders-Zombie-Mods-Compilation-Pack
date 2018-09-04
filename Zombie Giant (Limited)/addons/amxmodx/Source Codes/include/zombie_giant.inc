/* ============================================
Zombie Giant (Limited) API
by Dias Pendragon Leon
=============================================*/

enum
{
	WPN_PRIMARY = 1,
	WPN_SECONDARY,
	WPN_MELEE
}

// Zombie Giant
forward zg_round_new();
forward zg_round_start();
forward zg_game_start();
forward zg_game_end(CsTeams:WinTeam);
forward zg_become_giant(id, GiantCode, Float:X, Float:Y, Float:Z);
forward zg_user_kill(Victim, Attacker, Headshot, WeaponCSW);
forward zg_runningtime();
forward zg_equipment_menu(id)

native zg_is_giant(id);
native zg_get_giantclass(id);
native zg_get_maxhealth(id);
native zg_get_nightvision(id, Have, Enable);
native zg_set_nightvision(id, Give, Enable, Sound, IgnoreHadNVG);
native zg_get_mana(id);
native zg_set_mana(id, MP);
native zg_register_giantclass(BaseHealth);

// Weapon
native zg_weapon_register(const Name[], Type, BasedOn, Cost);
native zg_weapon_get_cswid(id, ItemID);

forward zg_weapon_bought(id, ItemID);
forward zg_weapon_remove(id, ItemID);
forward zg_weapon_addammo(id, ItemID);
