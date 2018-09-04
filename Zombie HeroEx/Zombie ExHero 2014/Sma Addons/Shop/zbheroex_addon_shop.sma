#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Addon: Shop"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define GAMENAME "Zombie: ExHero"
#define LANG_OFFICIAL LANG_PLAYER

#define LANG_FILE "zombie_theheroex.txt"
#define SETTING_FILE "zombie_theheroex.ini"

#define MAX_ITEM 16

new g_UnlockedItem[33][MAX_ITEM]
new Array:ItemName, Array:ItemDesc, Array:ItemCost, Array:ItemTeam
new g_TotalItem, g_ItemCount_Human, g_ItemCount_Zombie
new g_Forward_Bought, g_fwResult

// Temp Var
new ShopTitle[64]
new ItemNameS[32], ItemDescS[64], ItemCostS, ItemTeamS
new ItemAddName[80], ItemAddDesc[4]

// Temp Cache
new g_MaxPlayers, g_MsgSayText
	
public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_MaxPlayers = get_maxplayers()
	g_MsgSayText = get_user_msgid("SayText")
	
	g_Forward_Bought = CreateMultiForward("zbheroex_shop_item_bought", ET_IGNORE, FP_CELL, FP_CELL)
	register_clcmd("ZBHeroEx_OpenShop", "CMD_OpenShop")
}

public plugin_precache()
{
	ItemName = ArrayCreate(64, 1)
	ItemDesc = ArrayCreate(64, 1)
	ItemCost = ArrayCreate(1, 1)
	ItemTeam = ArrayCreate(1, 1)
}

public plugin_natives()
{
	register_native("zbheroex_set_item_status", "Native_SetItemStatus", 1)
	register_native("zbheroex_register_item", "Native_RegisterItem", 1)
}

public Native_SetItemStatus(id, ItemID, Unlock)
{
	g_UnlockedItem[id][ItemID] = Unlock
}

public Native_RegisterItem(const Name[], const Desc[], Cost, Team)
{
	param_convert(1)
	param_convert(2)
	
	ArrayPushString(ItemName, Name)
	ArrayPushString(ItemDesc, Desc)
	ArrayPushCell(ItemCost, Cost)
	ArrayPushCell(ItemTeam, Team)
	
	g_TotalItem++
	if(Team == TEAM_HUMAN) g_ItemCount_Human++
	else if(Team == TEAM_ZOMBIE) g_ItemCount_Zombie++
	
	return g_TotalItem - 1
}

public client_putinserver(id)
{
	for(new i = 0; i < MAX_ITEM; i++)
		g_UnlockedItem[id][i] = 0
}

public CMD_OpenShop(id)
{
	if(!is_user_alive(id))
		return
		
	if(pev_valid(id) == 2) set_pdata_int(id, 205, 0, 5)
		
	if(!zbheroex_get_user_zombie(id)) Open_Shop(id, TEAM_HUMAN)
	else Open_Shop(id, TEAM_ZOMBIE)
}

public Open_Shop(id, Team)
{
	if(Team == TEAM_HUMAN)
	{
		if(!g_ItemCount_Human)
		{
			client_print(id, print_center, "%L", LANG_OFFICIAL, "SHOP_NOITEM")
			return
		}
	} else {
		if(!g_ItemCount_Zombie)
		{
			client_print(id, print_center, "%L", LANG_OFFICIAL, "SHOP_NOITEM")
			return
		}
	}
	
	formatex(ShopTitle, sizeof(ShopTitle), "%L", LANG_OFFICIAL, (Team == TEAM_HUMAN ? "SHOP_HUMAN_NAME" : "SHOP_ZOMBIE_NAME"))
	static Menu; Menu = menu_create(ShopTitle, "MenuHandle_Shop")
	
	for(new i = 0; i < g_TotalItem; i++)
	{
		ItemTeamS = ArrayGetCell(ItemTeam, i)
		if(ItemTeamS != Team)
			continue
			
		ArrayGetString(ItemName, i, ItemNameS, sizeof(ItemNameS))
		ArrayGetString(ItemDesc, i, ItemDescS, sizeof(ItemDescS))
		ItemCostS = ArrayGetCell(ItemCost, i)
		
		if(g_UnlockedItem[id][i])
		{
			formatex(ItemAddName, sizeof(ItemAddName), "\d%s - %s\w (\y%L\w)", ItemNameS, ItemDescS, LANG_OFFICIAL, "SHOP_BOUGHT")
		} else {
			if(cs_get_user_money(id) >= ItemCostS || is_user_admin(id)) formatex(ItemAddName, sizeof(ItemAddName), "%s - \y%s\w (\r$%i\w)", ItemNameS, ItemDescS, ItemCostS)
			else formatex(ItemAddName, sizeof(ItemAddName), "\d%s - %s\w (\r$%i\w)", ItemNameS, ItemDescS, ItemCostS)
		}
	
		num_to_str(i, ItemAddDesc, sizeof(ItemAddDesc))
		menu_additem(Menu, ItemAddName, ItemAddDesc)
	}
	
	menu_display(id, Menu)
}

public MenuHandle_Shop(id, Menu, Item)
{
	if(Item == MENU_EXIT)
	{
		menu_destroy(Menu)
		return
	}
	if(!is_user_alive(id))
	{
		menu_destroy(Menu)
		return
	}
		
	static Data[6], Name[64], ItemAccess, ItemCallback
	menu_item_getinfo(Menu, Item, ItemAccess, Data, charsmax(Data), Name, charsmax(Name), ItemCallback)
	
	static ItemId; ItemId = str_to_num(Data)
	
	ArrayGetString(ItemName, ItemId, ItemNameS, sizeof(ItemNameS))
	ArrayGetString(ItemDesc, ItemId, ItemDescS, sizeof(ItemDescS))
	ItemCostS = ArrayGetCell(ItemCost, ItemId)
	
	if(g_UnlockedItem[id][ItemId])
	{
		client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "SHOP_ALREADY_UNLOCKED", ItemNameS, ItemCostS)
		
		menu_destroy(Menu)
		CMD_OpenShop(id)
		
		return
	} else {
		if(cs_get_user_money(id) >= ItemCostS || is_user_admin(id)) 
		{
			ExecuteForward(g_Forward_Bought, g_fwResult, id, ItemId)
			
			g_UnlockedItem[id][ItemId] = 1
			if(!is_user_admin(id)) cs_set_user_money(id, cs_get_user_money(id) - ItemCostS)
			
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "SHOP_UNLOCKED", ItemNameS, ItemCostS)
		} else {
			client_printc(id, "!g[%s]!n %L", GAMENAME, LANG_OFFICIAL, "SHOP_NOMONEY", ItemNameS, ItemCostS)
		
			menu_destroy(Menu)
			CMD_OpenShop(id)
			return
		}
	}
	
	menu_destroy(Menu)
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
