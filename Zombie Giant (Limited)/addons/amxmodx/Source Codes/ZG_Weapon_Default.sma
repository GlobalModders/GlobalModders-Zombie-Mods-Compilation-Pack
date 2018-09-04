#include <amxmodx>
#include <hamsandwich>
#include <zombie_giant>
#include <fun>

#define PLUGIN "[ZG] Weapon: CS Default"
#define VERSION "1.0"
#define AUTHOR "Dias Pendragon"

new g_Pri_M4A1, g_Pri_AK47, g_Pri_AUG, g_Pri_SG552, g_Pri_Galil, g_Pri_M3, g_Pri_XM1014, 
g_Pri_AWP, g_Pri_Scout, g_Pri_Famas, g_Pri_MP5, g_Pri_P90, g_Pri_UMP45, g_Pri_MAC, g_Pri_TMP
new g_Sec_USP, g_Sec_Glock18, g_Sec_DE, g_Sec_P228, g_Sec_FiveSeven, g_Sec_DualElite
new g_Melee_SealKnife

// Const
const PRIMARY_WEAPONS_BIT_SUM = (1<<CSW_SCOUT)|(1<<CSW_XM1014)|(1<<CSW_MAC10)|(1<<CSW_AUG)|(1<<CSW_UMP45)|(1<<CSW_SG550)|(1<<CSW_GALIL)|(1<<CSW_FAMAS)|(1<<CSW_AWP)|(1<<CSW_MP5NAVY)|(1<<CSW_M249)|(1<<CSW_M3)|(1<<CSW_M4A1)|(1<<CSW_TMP)|(1<<CSW_G3SG1)|(1<<CSW_SG552)|(1<<CSW_AK47)|(1<<CSW_P90)
const SECONDARY_WEAPONS_BIT_SUM = (1<<CSW_P228)|(1<<CSW_ELITE)|(1<<CSW_FIVESEVEN)|(1<<CSW_USP)|(1<<CSW_GLOCK18)|(1<<CSW_DEAGLE)
const NADE_WEAPONS_BIT_SUM = ((1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)|(1<<CSW_FLASHBANG))

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	Register_ThoseWeapons()
}

public Register_ThoseWeapons()
{
	// Primary
	g_Pri_M4A1 = zg_weapon_register("M4A1 Carbine", WPN_PRIMARY, CSW_M4A1, 0)
	g_Pri_AK47 = zg_weapon_register("AK-47 Kalashnikov", WPN_PRIMARY, CSW_AK47, 0)
	g_Pri_AUG = zg_weapon_register("Steyr AUG A1", WPN_PRIMARY, CSW_AUG, 0)
	g_Pri_SG552 = zg_weapon_register("SG-552 Commando", WPN_PRIMARY, CSW_SG552, 0)
	g_Pri_Galil = zg_weapon_register("IMI Galil", WPN_PRIMARY, CSW_GALI, 0)
	g_Pri_M3 = zg_weapon_register("M3 Super 90", WPN_PRIMARY, CSW_M3, 0)
	g_Pri_XM1014 = zg_weapon_register("XM1014 M4", WPN_PRIMARY, CSW_XM1014, 0)
	g_Pri_AWP = zg_weapon_register("AWP Magnum Sniper", WPN_PRIMARY, CSW_AWP, 0)
	g_Pri_Scout = zg_weapon_register("Schmidt Scout", WPN_PRIMARY, CSW_SCOUT, 0)
	g_Pri_Famas = zg_weapon_register("Famas", WPN_PRIMARY, CSW_FAMAS, 0)
	g_Pri_MP5 = zg_weapon_register("MP5 Navy", WPN_PRIMARY, CSW_MP5NAVY, 0)
	g_Pri_P90 = zg_weapon_register("ES P90", WPN_PRIMARY, CSW_P90, 0)
	g_Pri_UMP45 = zg_weapon_register("UMP 45", WPN_PRIMARY, CSW_UMP45, 0)
	g_Pri_MAC = zg_weapon_register("Ingram MAC-10", WPN_PRIMARY, CSW_MAC10, 0)
	g_Pri_TMP = zg_weapon_register("Schmidt TMP", WPN_PRIMARY, CSW_TMP, 0)
	
	// Secondary
	g_Sec_USP = zg_weapon_register("USP .45 ACP Tactical", WPN_SECONDARY, CSW_USP, 0)
	g_Sec_Glock18 = zg_weapon_register("Glock 18C", WPN_SECONDARY, CSW_GLOCK18, 0)
	g_Sec_DE = zg_weapon_register("Desert Eagle .50 AE", WPN_SECONDARY, CSW_DEAGLE, 0)
	g_Sec_P228 = zg_weapon_register("P228 Compact", WPN_SECONDARY, CSW_P228, 0)
	g_Sec_FiveSeven = zg_weapon_register("FiveseveN", WPN_SECONDARY, CSW_FIVESEVEN, 0)
	g_Sec_DualElite = zg_weapon_register("Dual Elite Berettas", WPN_SECONDARY, CSW_ELITE, 0)
	
	// Melee
	g_Melee_SealKnife = zg_weapon_register("Seal Knife", WPN_MELEE, CSW_KNIFE, 0)
}

public zg_weapon_bought(id, ItemID)
{
	if(ItemID == g_Pri_M4A1) give_item(id, "weapon_m4a1")
	else if(ItemID == g_Pri_AK47) give_item(id, "weapon_ak47")
	else if(ItemID == g_Pri_AUG) give_item(id, "weapon_aug")
	else if(ItemID == g_Pri_SG552) give_item(id, "weapon_sg552")
	else if(ItemID == g_Pri_Galil) give_item(id, "weapon_galil")
	else if(ItemID == g_Pri_M3) give_item(id, "weapon_m3")
	else if(ItemID == g_Pri_XM1014) give_item(id, "weapon_xm1014")
	else if(ItemID == g_Pri_AWP) give_item(id, "weapon_awp")
	else if(ItemID == g_Pri_Scout) give_item(id, "weapon_scout")
	else if(ItemID == g_Pri_Famas) give_item(id, "weapon_famas")
	else if(ItemID == g_Pri_MP5) give_item(id, "weapon_mp5navy")
	else if(ItemID == g_Pri_P90) give_item(id, "weapon_p90")
	else if(ItemID == g_Pri_UMP45) give_item(id, "weapon_ump45")
	else if(ItemID == g_Pri_MAC) give_item(id, "weapon_mac10")
	else if(ItemID == g_Pri_TMP) give_item(id, "weapon_tmp")
		
	if(ItemID == g_Sec_USP) give_item(id, "weapon_usp")
	else if(ItemID == g_Sec_Glock18) give_item(id, "weapon_glock18")
	else if(ItemID == g_Sec_DE) give_item(id, "weapon_deagle")
	else if(ItemID == g_Sec_P228) give_item(id, "weapon_p228")
	else if(ItemID == g_Sec_FiveSeven) give_item(id, "weapon_fiveseven")
	else if(ItemID == g_Sec_DualElite) give_item(id, "weapon_elite")
		
	if(ItemID == g_Melee_SealKnife) give_item(id, "weapon_knife")
	
	// Give the Fucking Ammo
	if(ItemID != g_Melee_SealKnife) Give_FuckingAmmo(id, zg_weapon_get_cswid(id, ItemID), 0)
}

public zg_weapon_addammo(id, ItemID)
{
	Give_FuckingAmmo(id, zg_weapon_get_cswid(id, ItemID), 0)
}

public Give_FuckingAmmo(id, CSWID, Silent)
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
		default: {Amount = 0; Max = 0;}
	}

	for(new i = 0; i < Amount; i++) give_ammo(id, Silent, CSWID, Max)
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
			if(!Get_BitVar(g_Connected, i))
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
