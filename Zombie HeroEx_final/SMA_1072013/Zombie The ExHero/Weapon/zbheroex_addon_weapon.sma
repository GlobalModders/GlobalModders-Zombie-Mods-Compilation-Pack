#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias"

// Config File
#define LANG_FILE "zombie_theheroex.txt"
#define SETTING_FILE "zombie_theheroex.ini"

#define GAMENAME "Zombie: ExHero"
#define LANG_OFFICIAL LANG_PLAYER

// Forward
#define MAX_FORWARD 2
enum
{
	FWD_WEAPON_BOUGHT = 0,
	FWD_WEAPON_REMOVE
}

new g_Forward[MAX_FORWARD], g_fwResult

// Array
new g_WeaponCount, g_WeaponPriCount, g_WeaponSecCount, g_WeaponMeleeCount
new Array:WeaponName, Array:WeaponType, Array:WeaponBasedOn, Array:WeaponCost

// Main Var
#define MAX_WEAPON 32
#define TASK_RESELECT_WEAPON 1972

new g_PriSelected, g_SecSelected, g_MeleeSelected
new g_UnlockedWeapon[33][MAX_WEAPON]

// Const
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

// Temp Cache
new MenuTitle[64], WeaponNameS[32], WeaponTypeS, WeaponBasedOnS, WeaponCostS, AddItemS[80], AddDescS[4]
new g_MaxPlayers, g_MsgSayText

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_Forward[FWD_WEAPON_BOUGHT] = CreateMultiForward("zbheroex_weapon_bought", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forward[FWD_WEAPON_REMOVE] = CreateMultiForward("zbheroex_weapon_remove", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgSayText = get_user_msgid("SayText")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	WeaponName = ArrayCreate(64, 1)
	WeaponType = ArrayCreate(1, 1)
	WeaponBasedOn = ArrayCreate(1, 1)
	WeaponCost = ArrayCreate(1, 1)
}

public plugin_natives()
{
	register_native("zbheroex_register_weapon", "Native_RegisterWeapon", 1)
}

public Native_RegisterWeapon(const Name[], Type, BasedOn, Cost)
{
	param_convert(1)
	
	ArrayPushString(WeaponName, Name)
	ArrayPushCell(WeaponType, Type)
	ArrayPushCell(WeaponBasedOn, BasedOn)
	ArrayPushCell(WeaponCost, Cost)
	
	g_WeaponCount++
	
	if(Type == WEAPON_PRIMARY) g_WeaponPriCount++
	else if(Type == WEAPON_SECONDARY) g_WeaponSecCount++
	else if(Type == WEAPON_MELEE) g_WeaponMeleeCount++
	
	return g_WeaponCount - 1
}

public client_putinserver(id)
{
	ResetWeapon(id, 1)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(Zombie) return
	
	ResetWeapon(id, 0)
	set_task(0.25, "Delay_Spawn", id+TASK_RESELECT_WEAPON)
}

public zbheroex_user_infect(id, Infector, Infection)
{
	ResetWeapon(id, 0)
}

public Delay_Spawn(id)
{
	id -= TASK_RESELECT_WEAPON
	if(!is_user_alive(id))
		return
		
	if(!is_user_bot(id)) 
	{
		Open_WeaponMenu(id)
		
		remove_task(id)
		set_task(30.0, "Task_ReOpen", id+TASK_RESELECT_WEAPON)
	}// else Bot_AutoSelectWeapon(id)
}

public Task_ReOpen(id)
{
	id -= TASK_RESELECT_WEAPON
	Open_WeaponMenu(id)
}

public Open_WeaponMenu(id)
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	
	if(pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
	
	if(!Get_BitVar(g_PriSelected, id) && g_WeaponPriCount)
	{
		Show_WeaponMenu(id, WEAPON_PRIMARY)
	} else if(!Get_BitVar(g_SecSelected, id) && g_WeaponSecCount) {
		Show_WeaponMenu(id, WEAPON_SECONDARY)
	} else if(!Get_BitVar(g_MeleeSelected, id) && g_WeaponMeleeCount) {
		Show_WeaponMenu(id, WEAPON_MELEE)
	}
}

public ResetWeapon(id, NewPlayer)
{
	if(NewPlayer)
	{
		for(new i = 0; i < MAX_WEAPON; i++)
			g_UnlockedWeapon[id][i] = 0
	}
	
	for(new i = 0; i < MAX_WEAPON; i++)
		ExecuteForward(g_Forward[FWD_WEAPON_REMOVE], g_fwResult, id, i)
	
	UnSet_BitVar(g_MeleeSelected, id)
	UnSet_BitVar(g_SecSelected, id)
	UnSet_BitVar(g_PriSelected, id)
}

public Show_WeaponMenu(id, Type)
{
	if(zbheroex_get_user_hero(id))
		return
	
	if(Type == WEAPON_PRIMARY) formatex(MenuTitle, sizeof(MenuTitle), "%L", LANG_OFFICIAL, "WEAPON_PRIMARY")
	else if(Type == WEAPON_SECONDARY) formatex(MenuTitle, sizeof(MenuTitle), "%L", LANG_OFFICIAL, "WEAPON_SECONDARY")
	else if(Type == WEAPON_MELEE) formatex(MenuTitle, sizeof(MenuTitle), "%L", LANG_OFFICIAL, "WEAPON_MELEE")
	
	static Menu; Menu = menu_create(MenuTitle, "MenuHandle_Weapon")
	for(new i = 0; i < g_WeaponCount; i++)
	{
		WeaponTypeS = ArrayGetCell(WeaponType, i)
		
		if(WeaponTypeS != Type)
			continue
			
		ArrayGetString(WeaponName, i, WeaponNameS, sizeof(WeaponNameS))
		WeaponCostS = ArrayGetCell(WeaponCost, i)
		
		if(g_UnlockedWeapon[id][i] || !WeaponCostS || is_user_admin(id))
		{
			formatex(AddItemS, sizeof(AddItemS), "%s", WeaponNameS)
		} else {
			if(cs_get_user_money(id) >= WeaponCostS) formatex(AddItemS, sizeof(AddItemS), "%s (\y$%i\w)", WeaponNameS, WeaponCostS)
			else formatex(AddItemS, sizeof(AddItemS), "\d%s\w (\r$%i\w)", WeaponNameS, WeaponCostS)
		}
	
		num_to_str(i, AddDescS, sizeof(AddDescS))
		menu_additem(Menu, AddItemS, AddDescS)
	}
	
	menu_display(id, Menu, 0)
}

public MenuHandle_Weapon(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	if(!is_user_alive(id) || zbheroex_get_user_zombie(id))
	{
		menu_destroy(Menu)
		return
	}
	if(zbheroex_get_user_hero(id))
	{
		menu_destroy(Menu)
		return
	}
	
	static Data[6], Name[64], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	static WeaponId; WeaponId = str_to_num(Data)
	
	ArrayGetString(WeaponName, WeaponId, WeaponNameS, sizeof(WeaponNameS))
	WeaponCostS = ArrayGetCell(WeaponCost, WeaponId)
	WeaponBasedOnS = ArrayGetCell(WeaponBasedOn, WeaponId)
	WeaponTypeS = ArrayGetCell(WeaponType, WeaponId)
	
	if(g_UnlockedWeapon[id][WeaponId] || !WeaponCostS || is_user_admin(id))
	{
		if(WeaponTypeS == WEAPON_MELEE) Set_BitVar(g_MeleeSelected, id)
		else if(WeaponTypeS == WEAPON_SECONDARY) 
		{
			drop_weapons(id, 2)
			Set_BitVar(g_SecSelected, id)
		} else if(WeaponTypeS == WEAPON_PRIMARY) {
			drop_weapons(id, 1)
			Set_BitVar(g_PriSelected, id)
		}	
		
		g_UnlockedWeapon[id][WeaponId] = 1
		ExecuteForward(g_Forward[FWD_WEAPON_BOUGHT], g_fwResult, id, WeaponId)
		if(WeaponTypeS != WEAPON_MELEE) Give_FuckingAmmo(id, WeaponBasedOnS)
		Open_WeaponMenu(id)

		menu_destroy(Menu)
		
		return
	} else {
		if(cs_get_user_money(id) >= WeaponCostS || is_user_admin(id)) 
		{
			if(WeaponTypeS == WEAPON_MELEE) Set_BitVar(g_MeleeSelected, id)
			else if(WeaponTypeS == WEAPON_SECONDARY) 
			{
				drop_weapons(id, 2)
				Set_BitVar(g_SecSelected, id)
			} else if(WeaponTypeS == WEAPON_PRIMARY) {
				drop_weapons(id, 1)
				Set_BitVar(g_PriSelected, id)
			}		
			
			g_UnlockedWeapon[id][WeaponId] = 1
			ExecuteForward(g_Forward[FWD_WEAPON_BOUGHT], g_fwResult, id, WeaponId)
			if(WeaponTypeS != WEAPON_MELEE) Give_FuckingAmmo(id, WeaponBasedOnS)
				
			cs_set_user_money(id, cs_get_user_money(id) - floatround(float(WeaponCostS) / 2.0))
				
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "WEAPON_UNLOCKED", WeaponNameS, WeaponCostS)
			menu_destroy(Menu)
			Open_WeaponMenu(id)
			
			return
		} else {
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "WEAPON_NOMONEY", WeaponNameS, WeaponCostS)
		
			menu_destroy(Menu)
			Show_WeaponMenu(id, WeaponTypeS)
			
			return
		}
	}	
}

public Give_FuckingAmmo(id, CSWID)
{
	static Amount, Max
	switch(CSWID)
	{
		case CSW_P228: {Amount = 10; Max = 104;}
		case CSW_SCOUT: {Amount = 6; Max = 180;}
		case CSW_XM1014: {Amount = 8; Max = 64;}
		case CSW_MAC10: {Amount = 16; Max = 200;}
		case CSW_AUG: {Amount = 6; Max = 180;}
		case CSW_ELITE: {Amount = 16; Max = 200;}
		case CSW_FIVESEVEN: {Amount = 4; Max = 200;}
		case CSW_UMP45: {Amount = 16; Max = 200;}
		case CSW_SG550: {Amount = 6; Max = 180;}
		case CSW_GALIL: {Amount = 6; Max = 180;}
		case CSW_FAMAS: {Amount = 6; Max = 180;}
		case CSW_USP: {Amount = 18; Max = 200;}
		case CSW_GLOCK18: {Amount = 16; Max = 200;}
		case CSW_AWP: {Amount = 6; Max = 60;}
		case CSW_MP5NAVY: {Amount = 16; Max = 200;}
		case CSW_M249: {Amount = 4; Max = 200;}
		case CSW_M3: {Amount = 8; Max = 64;}
		case CSW_M4A1: {Amount = 7; Max = 180;}
		case CSW_TMP: {Amount = 7; Max = 200;}
		case CSW_G3SG1: {Amount = 7; Max = 180;}
		case CSW_DEAGLE: {Amount = 10; Max = 70;}
		case CSW_SG552: {Amount = 7; Max = 180;}
		case CSW_AK47: {Amount = 7; Max = 180;}
		case CSW_P90: {Amount = 4; Max = 200;}
		default: {Amount = 3; Max = 200;}
	}

	for(new i = 0; i < Amount; i++) give_ammo(id, 0, CSWID, Max)
}

// Drop primary/secondary weapons
stock drop_weapons(id, dropwhat)
{
	// Get user weapons
	static weapons[32], num, i, weaponid
	num = 0 // reset passed weapons count (bugfix)
	get_user_weapons(id, weapons, num)
	
	// Loop through them and drop primaries or secondaries
	for (i = 0; i < num; i++)
	{
		// Prevent re-indexing the array
		weaponid = weapons[i]
		
		if ((dropwhat == 1 && ((1<<weaponid) & PRIMARY_WEAPONS_BIT_SUM)) || (dropwhat == 2 && ((1<<weaponid) & SECONDARY_WEAPONS_BIT_SUM)))
		{
			// Get weapon entity
			static wname[32]; get_weaponname(weaponid, wname, charsmax(wname))
			engclient_cmd(id, "drop", wname)
		}
	}
}

public give_ammo(id, silent, CSWID, Max)
{
	static Amount, Name[32]
		
	switch(CSWID)
	{
		case CSW_P228: {Amount = 13; formatex(Name, sizeof(Name), "357sig");}
		case CSW_SCOUT: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_XM1014: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_MAC10: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_AUG: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_ELITE: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_FIVESEVEN: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
		case CSW_UMP45: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_SG550: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_GALIL: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_FAMAS: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_USP: {Amount = 12; formatex(Name, sizeof(Name), "45acp");}
		case CSW_GLOCK18: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_AWP: {Amount = 10; formatex(Name, sizeof(Name), "338magnum");}
		case CSW_MP5NAVY: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_M249: {Amount = 30; formatex(Name, sizeof(Name), "556natobox");}
		case CSW_M3: {Amount = 8; formatex(Name, sizeof(Name), "buckshot");}
		case CSW_M4A1: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_TMP: {Amount = 30; formatex(Name, sizeof(Name), "9mm");}
		case CSW_G3SG1: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_DEAGLE: {Amount = 7; formatex(Name, sizeof(Name), "50ae");}
		case CSW_SG552: {Amount = 30; formatex(Name, sizeof(Name), "556nato");}
		case CSW_AK47: {Amount = 30; formatex(Name, sizeof(Name), "762nato");}
		case CSW_P90: {Amount = 50; formatex(Name, sizeof(Name), "57mm");}
	}
	
	if(!silent) emit_sound(id, CHAN_ITEM, "items/9mmclip1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	ExecuteHamB(Ham_GiveAmmo, id, Amount, Name, Max)
}

stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")

	if(!index)
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_connected(i))
				continue
				
			message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, i);
			write_byte(i);
			write_string(szMsg);
			message_end();	
		}		
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3076\\ f0\\ fs16 \n\\ par }
*/
