enum
{
	SYNCHUD_NOTICE = 2,
	SYNCHUD_HUMANZOMBIE_ITEM,
	SYNCHUD_ZBHM_SKILL1,
	SYNCHUD_ZBHM_SKILL2,
	SYNCHUD_ZBHM_SKILL3,
	SYCHUDD_EFFECTKILLER
}

enum
{
	SEX_MALE = 0,
	SEX_FEMALE
}

enum // Win Team
{
	WIN_ALL = 0,
	WIN_ZOMBIE,
	WIN_HUMAN
}

enum // This is Shop
{
	TEAM_ALL = 0,
	TEAM_ZOMBIE,
	TEAM_HUMAN
}

enum
{
	WEAPON_MELEE = 0,
	WEAPON_PRIMARY,
	WEAPON_SECONDARY
}

/* ============================
-- Zombie Class Secret Code
- Berserker: 1912
- Light: 1942
- Heal: 1957
- Deimos: 1962
- Banshee: 1975
- Stamper: 1986
- Sting Finger: 1996
==============================*/

// Get Native
native zbheroex_get_synchud_id(hudtype);
native zbheroex_get_user_zombie(id); // Return if User is A Zombie
native zbheroex_get_user_zombie_class(id); // Return id class of zombie
native zbheroex_get_user_hero(id);
native zbheroex_set_user_speed(id, Speed);
native zbheroex_reset_user_speed(id);
native zbheroex_set_user_health(id, Health, Full);
native zbheroex_get_maxhealth(id);
native zbheroex_set_user_rendering(id, fx, r, g, b, render, amount);
native zbheroex_get_user_time(id);
native zbheroex_set_user_time(id, Time);
native zbheroex_set_user_nvg(id, Give, On, Sound, IgnoreHadNVG);
native zbheroex_get_user_nvg(id, Have, On);
native zbheroex_get_user_female(id);
native zbheroex_set_user_female(id);
native zbheroex_get_user_level(id);
native zbheroex_set_user_level(id, Level);
native zbheroex_set_max_level(id, Level);
native zbheroex_get_zombiecode(ClassID);
native zbheroex_set_zombiecode(ClassID, Code);
native zbheroex_set_respawntime(id, Time);

// From Other
native zbheroex_show_attachment(id, const Sprite[], Float:Time, Float:Scale, Float:FrameRate, TotalFrame);

// Shop
native zbheroex_set_item_status(id, ItemID, Unlock);
native zbheroex_register_item(const Name[], const Desc[], Cost, Team);
forward zbheroex_shop_item_bought(id, ItemId);

// Register Zombie Class
native zbheroex_register_zombie_class(const Name[], const Desc[], Sex, LockCost, Float:Gravity, Float:Speed, Float:KnockBack);
native zbheroex_set_zombie_class_data1(const ModelHost[], const ModelOrigin[], const ClawsModel_Host[], const ClawsModel_Origin[]);
native zbheroex_set_zombie_class_data2(const DeathSound1[], const DeathSound2[], const HurtSound1[], const HurtSound2[], const HealSound[], const EvolSound[]);

// Shop
native zbheroex_register_weapon(const Name[], Type, BasedOn, Cost);
forward zbheroex_weapon_bought(id, ItemID);
forward zbheroex_weapon_remove(id, ItemID);

// Forward
forward zbheroex_user_infected(id, infector, infection);
forward zbheroex_user_spawned(id, Zombie);
forward zbheroex_user_died(id, attacker, headshot);
forward zbheroex_class_active(id, ClassID);
forward zbheroex_class_unactive(id, ClassID);
forward zbheroex_time_change();
forward zbheroex_skill_show(id, Zombie);
forward zbheroex_zombie_skill(id, ClassID);
forward zbheroex_user_evolved(id, Level);
forward zbheroex_user_hero(id, FemaleHero);
forward zbheroex_round_new();
forward zbheroex_round_start();
forward zbheroex_round_end(WinTeam);
forward zbheroex_game_start();
forward zbheroex_user_nvg(id, on, zombie);