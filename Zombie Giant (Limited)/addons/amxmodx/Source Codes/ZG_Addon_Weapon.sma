#include <amxmodx>
#include <amxmisc>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_giant>

#define PLUGIN "[ZG] Addon: Weapon"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

#define LANG_FILE "zombie_giant.txt"
#define GAME_LANG LANG_SERVER

#define VIP_FLAG ADMIN_LEVEL_H

#define MAX_WEAPON 46
#define MAX_TYPE 3
#define MAX_FORWARD 3
enum
{
	WPN_BOUGHT = 0,
	WPN_REMOVE,
	WPN_ADDAMMO
}

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

// Const
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

new g_Forwards[MAX_FORWARD], GameName[32], g_GotWeapon
new g_WeaponList[4][MAX_WEAPON], g_WeaponListCount[4]
new g_WeaponCount[4], g_PreWeapon[33][4], g_FirstWeapon[4], g_TotalWeaponCount, g_UnlockedWeapon[33][MAX_WEAPON]
new Array:ArWeaponName, Array:ArWeaponType, Array:ArWeaponBasedOn, Array:ArWeaponCost
new g_MaxPlayers, g_fwResult, g_MsgSayText

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_FILE)
	
	g_Forwards[WPN_BOUGHT] = CreateMultiForward("zg_weapon_bought", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_REMOVE] = CreateMultiForward("zg_weapon_remove", ET_IGNORE, FP_CELL, FP_CELL)
	g_Forwards[WPN_ADDAMMO] = CreateMultiForward("zg_weapon_addammo", ET_IGNORE, FP_CELL, FP_CELL)
	
	g_MsgSayText = get_user_msgid("SayText")
	g_MaxPlayers = get_maxplayers()
}

public plugin_precache()
{
	ArWeaponName = ArrayCreate(32, 1)
	ArWeaponType = ArrayCreate(1, 1)
	ArWeaponBasedOn = ArrayCreate(1, 1)
	ArWeaponCost = ArrayCreate(1, 1)
	
	// Initialize
	g_FirstWeapon[WPN_PRIMARY] = -1
	g_FirstWeapon[WPN_SECONDARY] = -1
	g_FirstWeapon[WPN_MELEE] = -1
}

public plugin_cfg()
{
	static WpnType
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WpnType = ArrayGetCell(ArWeaponType, i)
		
		if(g_FirstWeapon[WpnType] == -1)
			g_FirstWeapon[WpnType] = i
	}
	
	// Initialize 2
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		g_PreWeapon[i][WPN_PRIMARY] = g_FirstWeapon[WPN_PRIMARY]
		g_PreWeapon[i][WPN_SECONDARY] = g_FirstWeapon[WPN_SECONDARY]
		g_PreWeapon[i][WPN_MELEE] = g_FirstWeapon[WPN_MELEE]
	}
	
	// Handle WeaponList
	g_WeaponListCount[WPN_PRIMARY] = 0
	g_WeaponListCount[WPN_SECONDARY] = 0
	g_WeaponListCount[WPN_MELEE] = 0
	
	static Type
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		Type = ArrayGetCell(ArWeaponType, i)
		
		if(Type == WPN_PRIMARY)
		{
			g_WeaponList[WPN_PRIMARY][g_WeaponListCount[WPN_PRIMARY]] = i
			g_WeaponListCount[WPN_PRIMARY]++
		} else if(Type == WPN_SECONDARY) {
			g_WeaponList[WPN_SECONDARY][g_WeaponListCount[WPN_SECONDARY]] = i
			g_WeaponListCount[WPN_SECONDARY]++
		} else if(Type == WPN_MELEE) {
			g_WeaponList[WPN_MELEE][g_WeaponListCount[WPN_MELEE]] = i
			g_WeaponListCount[WPN_MELEE]++
		}
	}
	
	// Get GameName
	formatex(GameName, sizeof(GameName), "%L", GAME_LANG, "GAME_NAME")
}

public plugin_natives()
{
	register_native("zg_weapon_register", "Native_RegisterWeapon", 1)
	register_native("zg_weapon_get_cswid", "Native_Get_CSWID", 1)
}

public Native_RegisterWeapon(const Name[], Type, BasedOn, Cost)
{
	param_convert(1)
	
	ArrayPushString(ArWeaponName, Name)
	ArrayPushCell(ArWeaponType, Type)
	ArrayPushCell(ArWeaponBasedOn, BasedOn)
	ArrayPushCell(ArWeaponCost, Cost)
	
	g_TotalWeaponCount++
	g_WeaponCount[Type]++
	
	return g_TotalWeaponCount - 1
}

public Native_Get_CSWID(id, ItemID)
{
	if(ItemID >= g_TotalWeaponCount)
		return 0
	
	return ArrayGetCell(ArWeaponBasedOn, ItemID)
}

public client_putinserver(id)
{
	Reset_PlayerWeapon(id, 1)
}

public client_disconnect(id)
{
	Reset_PlayerWeapon(id, 1)
}

public zg_equipment_menu(id)
{
	Reset_PlayerWeapon(id, 0)
	Player_Equipment(id)
}

public Reset_PlayerWeapon(id, NewPlayer)
{
	if(NewPlayer)
	{
		g_PreWeapon[id][WPN_PRIMARY] = g_FirstWeapon[WPN_PRIMARY]
		g_PreWeapon[id][WPN_SECONDARY] = g_FirstWeapon[WPN_SECONDARY]
		g_PreWeapon[id][WPN_MELEE] = g_FirstWeapon[WPN_MELEE]
		
		for(new i = 0; i < MAX_WEAPON; i++)
			g_UnlockedWeapon[id][i] = 0
	}
	
	UnSet_BitVar(g_GotWeapon, id)
}

public zg_become_giant(id)
{
	ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
	ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
	ExecuteForward(g_Forwards[WPN_REMOVE], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
}

public Player_Equipment(id)
{
	if(!is_user_bot(id)) Show_MainEquipMenu(id)
	else set_task(random_float(0.25, 1.0), "Bot_RandomWeapon", id)
}

public Show_MainEquipMenu(id)
{
	if(zg_is_giant(id))
		return
	if(Get_BitVar(g_GotWeapon, id))
		return
	
	static LangText[64]; formatex(LangText, sizeof(LangText), "%L", GAME_LANG, "WPN_MENU_NAME")
	static Menu; Menu = menu_create(LangText, "MenuHandle_MainEquip")
	
	static WeaponName[32]
	
	if(g_PreWeapon[id][WPN_PRIMARY] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_PRIMARY], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L [\y%s\w]", GAME_LANG, "WPN_MENU_PRIMARY", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d[ ]\w", GAME_LANG, "WPN_MENU_PRIMARY")
	}
	menu_additem(Menu, LangText, "wpn_pri")
	
	if(g_PreWeapon[id][WPN_SECONDARY] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_SECONDARY], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L [\y%s\w]", GAME_LANG, "WPN_MENU_SECONDARY", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d[ ]\w", GAME_LANG, "WPN_MENU_SECONDARY")
	}
	menu_additem(Menu, LangText, "wpn_sec")
	
	if(g_PreWeapon[id][WPN_MELEE] != -1)
	{
		ArrayGetString(ArWeaponName, g_PreWeapon[id][WPN_MELEE], WeaponName, sizeof(WeaponName))
		formatex(LangText, sizeof(LangText), "%L [\y%s\w]^n", GAME_LANG, "WPN_MENU_MELEE", WeaponName)
	} else {
		formatex(LangText, sizeof(LangText), "%L \d[ ]\w^n", GAME_LANG, "WPN_MENU_MELEE")
	}
	menu_additem(Menu, LangText, "wpn_melee")
   
	formatex(LangText, sizeof(LangText), "\y%L", GAME_LANG, "WPN_MENU_TAKEWPN")
	menu_additem(Menu, LangText, "get_wpn")
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, 0)
}

public Bot_RandomWeapon(id)
{
	if(!is_user_alive(id))
		return
	
	g_PreWeapon[id][WPN_PRIMARY] = g_WeaponList[WPN_PRIMARY][random(g_WeaponListCount[WPN_PRIMARY])]
	g_PreWeapon[id][WPN_SECONDARY] = g_WeaponList[WPN_SECONDARY][random(g_WeaponListCount[WPN_SECONDARY])]
	g_PreWeapon[id][WPN_MELEE] = g_WeaponList[WPN_MELEE][random(g_WeaponListCount[WPN_MELEE])]
	
	Equip_Weapon(id)
}

public MenuHandle_MainEquip(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zg_is_giant(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	if(equal(Data, "wpn_pri"))
	{
		if(g_WeaponCount[WPN_PRIMARY]) Show_WpnSubMenu(id, WPN_PRIMARY, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "wpn_sec")) {
		if(g_WeaponCount[WPN_SECONDARY]) Show_WpnSubMenu(id, WPN_SECONDARY, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "wpn_melee")) {
		if(g_WeaponCount[WPN_MELEE]) Show_WpnSubMenu(id, WPN_MELEE, 0)
		else Show_MainEquipMenu(id)
	} else if(equal(Data, "get_wpn")) {
		Equip_Weapon(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Show_WpnSubMenu(id, WpnType, Page)
{
	static WeaponTypeN[16], MenuName[32]
	
	if(WpnType == WPN_PRIMARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_PRIMARY")
	else if(WpnType == WPN_SECONDARY) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_SECONDARY")
	else if(WpnType == WPN_MELEE) formatex(WeaponTypeN, sizeof(WeaponTypeN), "%L", GAME_LANG, "WPN_MENU_MELEE")
	
	formatex(MenuName, sizeof(MenuName), "%L [%s]", GAME_LANG, "WPN_MENU_SELECT", WeaponTypeN)
	new Menu = menu_create(MenuName, "MenuHandle_WpnSubMenu")

	static WeaponType, WeaponName[32], MenuItem[64], ItemID[4]
	static WeaponPrice, Money; Money = cs_get_user_money(id)
	
	for(new i = 0; i < g_TotalWeaponCount; i++)
	{
		WeaponType = ArrayGetCell(ArWeaponType, i)
		if(WpnType != WeaponType)
			continue
			
		ArrayGetString(ArWeaponName, i, WeaponName, sizeof(WeaponName))
		WeaponPrice = ArrayGetCell(ArWeaponCost, i)
		
		if(WeaponPrice > 0)
		{
			if(g_UnlockedWeapon[id][i] || (get_user_flags(id) & VIP_FLAG)) 
				formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
			else {
				if(Money >= WeaponPrice) formatex(MenuItem, sizeof(MenuItem), "%s \y($%i)\w", WeaponName, WeaponPrice)
				else formatex(MenuItem, sizeof(MenuItem), "\d%s \r($%i)\w", WeaponName, WeaponPrice)
			}
		} else {
			formatex(MenuItem, sizeof(MenuItem), "%s", WeaponName)
		}
		
		num_to_str(i, ItemID, sizeof(ItemID))
		menu_additem(Menu, MenuItem, ItemID)
	}
   
	menu_setprop(Menu, MPROP_EXIT, MEXIT_ALL)
	menu_display(id, Menu, Page)
}

public MenuHandle_WpnSubMenu(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		Show_MainEquipMenu(id)
		
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id) || zg_is_giant(id))
	{
		menu_destroy(Menu)
		return PLUGIN_HANDLED
	}

	new Name[64], Data[16], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)

	new ItemId = str_to_num(Data)
	new WeaponPrice = ArrayGetCell(ArWeaponCost, ItemId)
	new Money = cs_get_user_money(id)
	new WeaponName[32]; ArrayGetString(ArWeaponName, ItemId, WeaponName, sizeof(WeaponName))
	new OutputInfo[80], WeaponType; WeaponType = ArrayGetCell(ArWeaponType, ItemId)
	
	if(WeaponPrice > 0)
	{
		if(g_UnlockedWeapon[id][ItemId]) 
		{
			g_PreWeapon[id][WeaponType] = ItemId
			Show_MainEquipMenu(id)
		} else {
			if((get_user_flags(id) & VIP_FLAG))
			{
				g_UnlockedWeapon[id][ItemId] = 1
				
				g_PreWeapon[id][WeaponType] = ItemId
				Show_MainEquipMenu(id)
			} else {
				if(Money >= WeaponPrice) // Unlock now
				{
					g_UnlockedWeapon[id][ItemId] = 1
					
					g_PreWeapon[id][WeaponType] = ItemId
					Show_MainEquipMenu(id)
					
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "WPN_NOTICE_UNLOCKED", WeaponName, WeaponPrice)
					client_printc(id, OutputInfo)
					
					cs_set_user_money(id, Money - (WeaponPrice / 2))
				} else { // Not Enough $
					formatex(OutputInfo, sizeof(OutputInfo), "!g[%s]!n %L", GameName, GAME_LANG, "WPN_NOTICE_NEEDMONEY", WeaponPrice, WeaponName)
					client_printc(id, OutputInfo)
					
					Show_WpnSubMenu(id, WeaponType, 0)
				}
			}
		}
	} else {
		if(!g_UnlockedWeapon[id][ItemId]) 
			g_UnlockedWeapon[id][ItemId] = 1
				
		g_PreWeapon[id][WeaponType] = ItemId
		Show_MainEquipMenu(id)
	}
	
	menu_destroy(Menu)
	return PLUGIN_CONTINUE
}

public Equip_Weapon(id)
{
	// Equip: Melee
	if(g_PreWeapon[id][WPN_MELEE] != -1)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_MELEE])
		
	// Equip: Secondary
	if(g_PreWeapon[id][WPN_SECONDARY] != -1)
	{
		drop_weapons(id, 2)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_SECONDARY])
	}
		
	// Equip: Primary
	if(g_PreWeapon[id][WPN_PRIMARY] != -1)
	{
		drop_weapons(id, 1)
		ExecuteForward(g_Forwards[WPN_BOUGHT], g_fwResult, id, g_PreWeapon[id][WPN_PRIMARY])
	}
	
	Set_BitVar(g_GotWeapon, id)
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

stock client_printc(index, const text[], any:...)
{
	static szMsg[128]; vformat(szMsg, sizeof(szMsg) - 1, text, 3)

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04")
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01")
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03")

	if(index)
	{
		message_begin(MSG_ONE_UNRELIABLE, g_MsgSayText, _, index);
		write_byte(index);
		write_string(szMsg);
		message_end();
	}
} 
