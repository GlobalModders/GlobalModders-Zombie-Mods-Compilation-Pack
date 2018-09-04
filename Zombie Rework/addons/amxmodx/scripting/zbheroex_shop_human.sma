#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Shop: Human"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define TASK_SPRINT 213464
#define TASK_SPRINT_SOUND 353674
#define TASK_USING_ITEM1 588976
#define TASK_USING_ITEM2 588623

// Heavenly Boot
#define HEAVENLYBOOT_GRAVITY 0.75
new g_HeavenlyBoot, g_Had_HeavenlyBoot, g_HeavenlyBoot_Cost

// x2 Grenade & x1.3 Damage
#define MAX_LEVEL 13
new g_X2_Grenade, g_Had_X2Grenade, g_DoubledGrenade, g_X2Grenade_Cost
new g_X13Dmg, g_Had_X13Dmg, g_X13Dmg_Cost

// Sprint
#define DEADRUN_TIME 10
#define DEADRUN_SPEED 350
#define SLOWRUN_TIME 5
#define SLOWRUN_SPEED 100

#define SOUND_USEITEM "zombie_thehero/speedup.wav"
#define SOUND_HEARTBEAT "zombie_thehero/speedup_heartbeat.wav"
#define SOUND_BREATH_MALE "zombie_thehero/human_breath_male.wav"
#define SOUND_BREATH_FEMALE "zombie_thehero/human_breath_female.wav"

new g_Sprint, g_Sprint_Cost
new g_Had_Sprint, g_CanSprint, g_Sprinting, g_Slowing

// DeadlyShot
#define DEADLYSHOT_TIME 5.0
#define DEADLYSHOT_ICON "sprites/zombie_thehero/zb_skill_headshot.spr"

new g_DeadlyShot, g_DeadlyShot_Cost
new g_Had_DeadlyShot, g_CanDeadlyShot, g_Activating_DeadlyShot

// BloodyBlade
#define BLOODYBLADE_TIME 7.5
#define BLOODYBLADE_ICON "sprites/zombie_thehero/zb_meleeup.spr"

new g_BloodyBlade, g_BloodyBlade_Cost
new g_Had_BloodyBlade, g_CanBloodyBlade, g_Activating_BloodyBlade

// Night Vision
new g_NightVision, g_NightVision_Cost
new g_Had_NVG

// Hud
#define HUD_BUFF_X 0.015
#define HUD_BUFF_Y 0.20

#define HUD_ACTIVE_X -1.0
#define HUD_ACTIVE_Y 0.10

new g_OwnItem
new g_Hud_Buff, g_Hud_Active

// Temp Text
new g_FullText[256], g_FullText2[128], g_ItemName[64]
new g_Word_Ready[16], g_Word_Activating[16], g_Word_Disabled[16]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

new g_GameStart, g_Msg_ScreenFade, g_RegHamBot

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	g_Hud_Buff = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL1)
	g_Hud_Active = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
	g_Msg_ScreenFade = get_user_msgid("ScreenFade")
	
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_Item_AddToPlayer, "weapon_hegrenade", "fw_Add_Hegrenade_Post", 1)
	
	register_clcmd("Skill1", "Skill1")
	register_clcmd("Skill2", "Skill2")
	register_clcmd("Skill3", "Skill3")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	formatex(g_Word_Ready, sizeof(g_Word_Ready), "%L", LANG_OFFICIAL, "ITEM_READY")
	formatex(g_Word_Activating, sizeof(g_Word_Activating), "%L", LANG_OFFICIAL, "ITEM_ACTIVATING")
	formatex(g_Word_Disabled, sizeof(g_Word_Disabled), "%L", LANG_OFFICIAL, "ITEM_DISABLED")

	Load_ItemConfig()
	Register_Item()
	
	engfunc(EngFunc_PrecacheSound, SOUND_USEITEM)
	engfunc(EngFunc_PrecacheSound, SOUND_HEARTBEAT)
	engfunc(EngFunc_PrecacheSound, SOUND_BREATH_MALE)
	engfunc(EngFunc_PrecacheSound, SOUND_BREATH_FEMALE)
	
	engfunc(EngFunc_PrecacheModel, DEADLYSHOT_ICON)
	engfunc(EngFunc_PrecacheModel, BLOODYBLADE_ICON)
}

public Load_ItemConfig()
{
	g_HeavenlyBoot_Cost = amx_load_setting_int(SETTING_FILE, "Item", "WINGBOOT_COST")
	g_X2Grenade_Cost = amx_load_setting_int(SETTING_FILE, "Item", "X2GRENADE_COST")
	g_X13Dmg_Cost = amx_load_setting_int(SETTING_FILE, "Item", "X13DMG_COST")
	g_Sprint_Cost = amx_load_setting_int(SETTING_FILE, "Item", "SPRINT_COST")
	g_DeadlyShot_Cost = amx_load_setting_int(SETTING_FILE, "Item", "DEADLYSHOT_COST")
	g_BloodyBlade_Cost = amx_load_setting_int(SETTING_FILE, "Item", "BLOODYBLADE_COST")
	g_NightVision_Cost = amx_load_setting_int(SETTING_FILE, "Item", "NIGHTVISION_COST")
}

public Register_Item()
{
	static ItemName[64], ItemDesc[80]
	
	// Heavenly Boot
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_WINGBOOT_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_WINGBOOT_DESC")
	g_HeavenlyBoot = zbheroex_register_item(ItemName, ItemDesc, g_HeavenlyBoot_Cost, TEAM_HUMAN)
	
	// x2 Grenade
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_X2GRENADE_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_X2GRENADE_DESC")
	g_X2_Grenade = zbheroex_register_item(ItemName, ItemDesc, g_X2Grenade_Cost, TEAM_HUMAN)

	// x1.3 Damage
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_X13DMG_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_X13DMG_DESC")
	g_X13Dmg = zbheroex_register_item(ItemName, ItemDesc, g_X13Dmg_Cost, TEAM_HUMAN)
	
	// Sprint
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_SPRINT_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_SPRINT_DESC")
	g_Sprint = zbheroex_register_item(ItemName, ItemDesc, g_Sprint_Cost, TEAM_HUMAN)
	
	// DeadlyShot
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_DEADLYSHOT_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_DEADLYSHOT_DESC")
	g_DeadlyShot = zbheroex_register_item(ItemName, ItemDesc, g_DeadlyShot_Cost, TEAM_HUMAN)
	
	// BloodyBlade
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_BLOODYBLADE_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_BLOODYBLADE_DESC")
	g_BloodyBlade = zbheroex_register_item(ItemName, ItemDesc, g_BloodyBlade_Cost, TEAM_HUMAN)
	
	// NightVision
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_NIGHTVISION_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_NIGHTVISION_DESC")
	g_NightVision = zbheroex_register_item(ItemName, ItemDesc, g_NightVision_Cost, TEAM_HUMAN)
}

public client_putinserver(id) 
{	
	Reset_Skill(id, 1)
	//Give_RandomItem(id)
	
	set_task(1.0, "Force_BindButton", id)
	
	if(!g_RegHamBot && is_user_bot(id))
	{
		g_RegHamBot = 1
		set_task(0.1, "RegisterHamBot", id)
	}
}

public RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
}

public zbheroex_round_new() g_GameStart = 0
public zbheroex_game_start() g_GameStart = 1

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) 
	{
		Reset_Skill(id, 0)
		set_task(1.0, "Force_BindButton", id)
	}
}

public Force_BindButton(id)
{
	engclient_cmd(id, "bind F1 Skill1")
	engclient_cmd(id, "bind F2 Skill2")
	engclient_cmd(id, "bind F3 Skill3")
}

public Give_RandomItem(id)
{
	static RandomNum; 
	
	RandomNum = random_num(0, 100)
	if(RandomNum >= 35 && RandomNum <= 65)
	{
		zbheroex_shop_item_bought(id, g_HeavenlyBoot)
		zbheroex_set_item_status(id, g_HeavenlyBoot, 1)
		
		RandomNum = random_num(0, 3)
		if(!RandomNum) 
		{
			zbheroex_shop_item_bought(id, g_X2_Grenade)
			zbheroex_set_item_status(id, g_X2_Grenade, 1)
			zbheroex_shop_item_bought(id, g_X13Dmg)
			zbheroex_set_item_status(id, g_X13Dmg, 1)
		} else if(RandomNum == 1) {
			zbheroex_shop_item_bought(id, g_X2_Grenade)
			zbheroex_set_item_status(id, g_X2_Grenade, 1)
			zbheroex_shop_item_bought(id, g_NightVision)
			zbheroex_set_item_status(id, g_NightVision, 1)
		} else if(RandomNum == 2) {
			zbheroex_shop_item_bought(id, g_X13Dmg)
			zbheroex_set_item_status(id, g_X13Dmg, 1)
			zbheroex_shop_item_bought(id, g_NightVision)
			zbheroex_set_item_status(id, g_NightVision, 1)
		} else if(RandomNum == 3) {
			zbheroex_shop_item_bought(id, g_NightVision)
			zbheroex_set_item_status(id, g_NightVision, 1)
		}
	}
	
	RandomNum = random_num(0, 100)
	if(RandomNum >= 0 && RandomNum <= 20)
	{
		zbheroex_shop_item_bought(id, g_HeavenlyBoot)
		
		RandomNum = random_num(0, 4)
		if(!RandomNum) 
		{
			zbheroex_shop_item_bought(id, g_DeadlyShot)
			zbheroex_set_item_status(id, g_DeadlyShot, 1)
			zbheroex_shop_item_bought(id, g_BloodyBlade)
			zbheroex_set_item_status(id, g_BloodyBlade, 1)
		} else if(RandomNum == 1) {
			zbheroex_shop_item_bought(id, g_Sprint)
			zbheroex_set_item_status(id, g_Sprint, 1)
		} else if(RandomNum == 2) {
			zbheroex_shop_item_bought(id, g_BloodyBlade)
			zbheroex_set_item_status(id, g_BloodyBlade, 1)
		} else if(RandomNum == 3) {
			zbheroex_shop_item_bought(id, g_DeadlyShot)
			zbheroex_set_item_status(id, g_DeadlyShot, 1)
		} else if(RandomNum == 4) {
			zbheroex_shop_item_bought(id, g_BloodyBlade)
			zbheroex_set_item_status(id, g_BloodyBlade, 1)
			zbheroex_shop_item_bought(id, g_Sprint)
			zbheroex_set_item_status(id, g_Sprint, 1)
		} 
	}
}

public zbheroex_shop_item_bought(id, ItemId)
{
	if(ItemId == g_HeavenlyBoot)
	{
		Set_BitVar(g_Had_HeavenlyBoot, id)
		if(is_user_alive(id)) Activate_HeavenlyBoot(id)
		
		Set_BitVar(g_OwnItem, id)
	} else if(ItemId == g_X2_Grenade) {
		Set_BitVar(g_Had_X2Grenade, id)
		if(is_user_alive(id)) 
		{
			Set_BitVar(g_DoubledGrenade, id)
		
			if(!cs_get_user_bpammo(id, CSW_HEGRENADE))
			{
				fm_give_item(id, "weapon_hegrenade")
				cs_set_user_bpammo(id, CSW_HEGRENADE, 1)
			} else cs_set_user_bpammo(id, CSW_HEGRENADE, 2)
		}
		
		Set_BitVar(g_OwnItem, id)
	} else if(ItemId == g_X13Dmg) {
		Set_BitVar(g_Had_X13Dmg, id)
		zbheroex_set_max_level(id, MAX_LEVEL)
		if(is_user_alive(id)) zbheroex_set_user_level(id, zbheroex_get_user_level(id) + 3)
		
		Set_BitVar(g_OwnItem, id)
	} else if(ItemId == g_Sprint) {
		Set_BitVar(g_Had_Sprint, id)
		
		// Set Sprint
		Set_BitVar(g_CanSprint, id)
		UnSet_BitVar(g_Sprinting, id)
		UnSet_BitVar(g_Slowing, id)
	} else if(ItemId == g_DeadlyShot) {
		Set_BitVar(g_Had_DeadlyShot, id)
		
		Set_BitVar(g_CanDeadlyShot, id)
		UnSet_BitVar(g_Activating_DeadlyShot, id)
	} else if(ItemId == g_BloodyBlade) {
		Set_BitVar(g_Had_BloodyBlade, id)
		
		Set_BitVar(g_CanBloodyBlade, id)
		UnSet_BitVar(g_Activating_BloodyBlade, id)
	} else if(ItemId == g_NightVision) {
		Set_BitVar(g_Had_NVG, id)
		if(is_user_alive(id)) zbheroex_set_user_nvg(id, 1, 1, 1, 0)
		
		Set_BitVar(g_OwnItem, id)
	}
}

public zbheroex_skill_show(id, Zombie)
{
	if(Zombie) return
	
	Show_BuffItem(id)
	Show_ActiveItem(id)
}

public zbheroex_user_infected(id, infector, Infection)
{
	if(Infection) Stop_Skill(id)
}

public Show_BuffItem(id)
{
	if(!Get_BitVar(g_OwnItem, id)) return
	formatex(g_FullText, sizeof(g_FullText), "[%L]^n", LANG_OFFICIAL, "ITEM_LISTNAME")
	
	if(Get_BitVar(g_Had_HeavenlyBoot, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_WINGBOOT_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}
	if(Get_BitVar(g_Had_X2Grenade, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_X2GRENADE_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}
	if(Get_BitVar(g_Had_X13Dmg, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_X13DMG_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}		
	if(Get_BitVar(g_Had_NVG, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_NIGHTVISION_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}		

	set_hudmessage(85, 255, 255, HUD_BUFF_X, HUD_BUFF_Y, 0, 2.0, 2.0)
	ShowSyncHudMsg(id, g_Hud_Buff, g_FullText)
}

public Show_ActiveItem(id)
{
	formatex(g_FullText, sizeof(g_FullText), "")
	
	if(Get_BitVar(g_Had_Sprint, id))
	{
		if(Get_BitVar(g_CanSprint, id) && !Get_BitVar(g_Sprinting, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F1] - %L (%s)", LANG_OFFICIAL, "ITEM_SPRINT_NAME", g_Word_Ready)
		else if(!Get_BitVar(g_CanSprint, id) && Get_BitVar(g_Sprinting, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F1] - %L (%s)", LANG_OFFICIAL, "ITEM_SPRINT_NAME", g_Word_Activating)
		else if(!Get_BitVar(g_CanSprint, id) && !Get_BitVar(g_Sprinting, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F1] - %L (%s)", LANG_OFFICIAL, "ITEM_SPRINT_NAME", g_Word_Disabled)
	
		formatex(g_FullText, sizeof(g_FullText), "%s^n", g_FullText2)
	}
	
	if(Get_BitVar(g_Had_DeadlyShot, id))
	{
		if(Get_BitVar(g_CanDeadlyShot, id) && !Get_BitVar(g_Activating_DeadlyShot, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F2] - %L (%s)", LANG_OFFICIAL, "ITEM_DEADLYSHOT_NAME", g_Word_Ready)
		else if(!Get_BitVar(g_CanDeadlyShot, id) && Get_BitVar(g_Activating_DeadlyShot, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F2] - %L (%s)", LANG_OFFICIAL, "ITEM_DEADLYSHOT_NAME", g_Word_Activating)
		else if(!Get_BitVar(g_CanDeadlyShot, id) && !Get_BitVar(g_Activating_DeadlyShot, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F2] - %L (%s)", LANG_OFFICIAL, "ITEM_DEADLYSHOT_NAME", g_Word_Disabled)
	
		formatex(g_FullText, sizeof(g_FullText), "%s%s^n", g_FullText, g_FullText2)
	} 
	
	if(Get_BitVar(g_Had_BloodyBlade, id))
	{
		if(Get_BitVar(g_CanBloodyBlade, id) && !Get_BitVar(g_Activating_BloodyBlade, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F3] - %L (%s)", LANG_OFFICIAL, "ITEM_BLOODYBLADE_NAME", g_Word_Ready)
		else if(!Get_BitVar(g_CanBloodyBlade, id) && Get_BitVar(g_Activating_BloodyBlade, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F3] - %L (%s)", LANG_OFFICIAL, "ITEM_BLOODYBLADE_NAME", g_Word_Activating)
		else if(!Get_BitVar(g_CanBloodyBlade, id) && !Get_BitVar(g_Activating_BloodyBlade, id)) 
			formatex(g_FullText2, sizeof(g_FullText2), "[F3] - %L (%s)", LANG_OFFICIAL, "ITEM_BLOODYBLADE_NAME", g_Word_Disabled)
	
		formatex(g_FullText, sizeof(g_FullText), "%s%s^n", g_FullText, g_FullText2)
	}
		
	set_hudmessage(0, 200, 0, HUD_ACTIVE_X, HUD_ACTIVE_Y, 0, 2.0, 2.0)
	ShowSyncHudMsg(id, g_Hud_Active, g_FullText)	
}

public Reset_Skill(id, NewPlayer)
{
	if(NewPlayer)
	{
		UnSet_BitVar(g_Had_HeavenlyBoot, id)
		UnSet_BitVar(g_Had_X2Grenade, id)
		UnSet_BitVar(g_Had_X13Dmg, id)
		UnSet_BitVar(g_Had_Sprint, id)
		UnSet_BitVar(g_Had_DeadlyShot, id)
		UnSet_BitVar(g_Had_BloodyBlade, id)
		UnSet_BitVar(g_Had_NVG, id)
		UnSet_BitVar(g_OwnItem, id)
		UnSet_BitVar(g_DoubledGrenade, id)
	}
	
	if(Get_BitVar(g_Had_HeavenlyBoot, id)) Activate_HeavenlyBoot(id)
	UnSet_BitVar(g_DoubledGrenade, id)
	if(Get_BitVar(g_Had_X13Dmg, id)) zbheroex_set_user_level(id, zbheroex_get_user_level(id) + 3)
	if(Get_BitVar(g_Had_Sprint, id)) Set_BitVar(g_CanSprint, id)
	UnSet_BitVar(g_Sprinting, id)
	UnSet_BitVar(g_Slowing, id)
	if(Get_BitVar(g_Had_DeadlyShot, id)) Set_BitVar(g_CanDeadlyShot, id)
	if(Get_BitVar(g_Had_BloodyBlade, id)) Set_BitVar(g_CanBloodyBlade, id)
	UnSet_BitVar(g_Activating_DeadlyShot, id)
	UnSet_BitVar(g_Activating_BloodyBlade, id)
	if(Get_BitVar(g_Had_NVG, id)) zbheroex_set_user_nvg(id, 1, 0, 0, 0)
}

public Stop_Skill(id)
{
	remove_task(id+TASK_SPRINT)
	remove_task(id+TASK_SPRINT_SOUND)
	
	UnSet_BitVar(g_Activating_DeadlyShot, id)
	UnSet_BitVar(g_Activating_BloodyBlade, id)
}

public Activate_HeavenlyBoot(id)
{
	if(!Get_BitVar(g_Had_HeavenlyBoot, id))
		return
		
	set_pev(id, pev_gravity, HEAVENLYBOOT_GRAVITY)
}

public fw_Add_Hegrenade_Post(Ent, Id)
{
	if(!pev_valid(Ent))
		return HAM_IGNORED
	if(!is_user_connected(Id))
		return HAM_IGNORED
	if(zbheroex_get_user_zombie(Id))
		return HAM_IGNORED	
	if(!Get_BitVar(g_Had_X2Grenade, Id))
		return HAM_IGNORED
	if(!Get_BitVar(g_DoubledGrenade, Id))
	{
		Set_BitVar(g_DoubledGrenade, Id)
		
		fm_give_item(Id, "weapon_hegrenade")
		cs_set_user_bpammo(Id, CSW_HEGRENADE, 2)
	}
	
	return HAM_IGNORED
}

public Skill1(id) // Dead Run
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Had_Sprint, id) || !Get_BitVar(g_CanSprint, id))
		return
	static IsDias; IsDias = 0
	static SteamID[64]; get_user_authid(id, SteamID, sizeof(SteamID))
	if(equal(SteamID, "STEAM_0:1:48204318")) IsDias = 1
	if(!IsDias)
	{
		if(!g_GameStart)
		{
			client_print(id, print_center, "%L", LANG_OFFICIAL, "ITEM_CANTUSE")
			return
		}	
	}
	
	Show_ActiveItem(id)
	
	UnSet_BitVar(g_CanSprint, id)
	UnSet_BitVar(g_Slowing, id)
	Set_BitVar(g_Sprinting, id)
	
	if(!zbheroex_get_user_nvg(id, 1, 1))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(100) // alpha
		message_end()
	}
	
	zbheroex_set_user_speed(id, DEADRUN_SPEED)
	emit_sound(id, CHAN_ITEM, SOUND_USEITEM, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	remove_task(id+TASK_SPRINT)
	set_task(float(DEADRUN_TIME), "Remove_DeadRun", id+TASK_SPRINT)
	set_task(1.0, "Task_BreathSound", id+TASK_SPRINT_SOUND)	
}

public Task_BreathSound(id)
{
	id -= TASK_SPRINT_SOUND
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(Get_BitVar(g_Sprinting, id))
	{
		emit_sound(id, CHAN_BODY, SOUND_HEARTBEAT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_task(1.0, "Task_BreathSound", id+TASK_SPRINT_SOUND)
	} else if(Get_BitVar(g_Slowing, id)) {
		emit_sound(id, CHAN_BODY, !zbheroex_get_user_female(id) ? SOUND_BREATH_MALE : SOUND_BREATH_FEMALE, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_task(1.0, "Task_BreathSound", id+TASK_SPRINT_SOUND)
	}
}

public zbheroex_user_nvg(id, On, Zombie)
{
	if(Zombie) return
	if(!On && (Get_BitVar(g_Sprinting, id) || Get_BitVar(g_Activating_DeadlyShot, id) || Get_BitVar(g_Activating_BloodyBlade, id)))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()
	}
}

public Remove_DeadRun(id)
{
	id -= TASK_SPRINT
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Sprinting, id))
		return
		
	UnSet_BitVar(g_CanSprint, id)
	UnSet_BitVar(g_Sprinting, id)
	Set_BitVar(g_Slowing, id)
	
	if(zbheroex_get_user_nvg(id, 1, 1)) 
	{
		zbheroex_set_user_nvg(id, 0, 0, 0, 1)
		zbheroex_set_user_nvg(id, 1, 0, 0, 1)
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()	
	}

	zbheroex_set_user_speed(id, SLOWRUN_SPEED)
	
	remove_task(id+TASK_SPRINT)
	set_task(float(SLOWRUN_TIME), "Remove_SlowRun", id+TASK_SPRINT)
}

public Remove_SlowRun(id)
{
	id -= TASK_SPRINT
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Slowing, id))
		return
		
	zbheroex_reset_user_speed(id)
	
	remove_task(id+TASK_SPRINT)
	remove_task(id+TASK_SPRINT_SOUND)
}

public Skill2(id) // DeadlyShot
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Had_DeadlyShot, id) || !Get_BitVar(g_CanDeadlyShot, id))
		return
	static IsDias; IsDias = 0
	static SteamID[64]; get_user_authid(id, SteamID, sizeof(SteamID))
	if(equal(SteamID, "STEAM_0:1:48204318")) IsDias = 1
	if(!IsDias)
	{
		if(!g_GameStart)
		{
			client_print(id, print_center, "%L", LANG_OFFICIAL, "ITEM_CANTUSE")
			return
		}	
	}
	
	Show_ActiveItem(id)
	
	UnSet_BitVar(g_CanDeadlyShot, id)
	Set_BitVar(g_Activating_DeadlyShot, id)
	
	if(!zbheroex_get_user_nvg(id, 1, 1))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(100) // alpha
		message_end()
	}
	
	emit_sound(id, CHAN_ITEM, SOUND_USEITEM, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	zbheroex_show_attachment(id, DEADLYSHOT_ICON, DEADLYSHOT_TIME, 1.0, 1.0, 0)
	
	remove_task(id+TASK_USING_ITEM1)
	set_task(DEADLYSHOT_TIME, "Remove_DeadlyShot", id+TASK_USING_ITEM1)	
}

public fw_TraceAttack(victim, attacker, Float:damage, Float:direction[3], tracehandle, damage_type)
{
	if (victim == attacker || !is_user_connected(attacker))
		return HAM_IGNORED
	if (cs_get_user_team(victim) == cs_get_user_team(attacker))
		return HAM_IGNORED
		
	if(Get_BitVar(g_Activating_DeadlyShot, attacker) && get_user_weapon(attacker) != CSW_KNIFE)
		set_tr2(tracehandle, TR_iHitgroup, HIT_HEAD)
	if(Get_BitVar(g_Activating_BloodyBlade, attacker) && get_user_weapon(attacker) == CSW_KNIFE)
		SetHamParamFloat(3, damage * 2.0)
	
	return HAM_IGNORED
}

public Remove_DeadlyShot(id)
{
	id -= TASK_USING_ITEM1
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Activating_DeadlyShot, id))
		return	
		
	UnSet_BitVar(g_CanDeadlyShot, id)
	UnSet_BitVar(g_Activating_DeadlyShot, id)
	
	if(zbheroex_get_user_nvg(id, 1, 1)) 
	{
		zbheroex_set_user_nvg(id, 0, 0, 0, 1)
		zbheroex_set_user_nvg(id, 1, 0, 0, 1)
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()	
	}
}

public Skill3(id) // BloodyBlade
{
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Had_BloodyBlade, id) || !Get_BitVar(g_CanBloodyBlade, id))
		return
	static IsDias; IsDias = 0
	static SteamID[64]; get_user_authid(id, SteamID, sizeof(SteamID))
	if(equal(SteamID, "STEAM_0:1:48204318")) IsDias = 1
	if(!IsDias)
	{
		if(!g_GameStart)
		{
			client_print(id, print_center, "%L", LANG_OFFICIAL, "ITEM_CANTUSE")
			return
		}	
	}	
	
	Show_ActiveItem(id)
	
	UnSet_BitVar(g_CanBloodyBlade, id)
	Set_BitVar(g_Activating_BloodyBlade, id)
	
	if(!zbheroex_get_user_nvg(id, 1, 1))
	{
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(100) // alpha
		message_end()
	}
	
	emit_sound(id, CHAN_ITEM, SOUND_USEITEM, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	zbheroex_show_attachment(id, BLOODYBLADE_ICON, BLOODYBLADE_TIME, 1.0, 1.0, 0)
	
	remove_task(id+TASK_USING_ITEM2)
	set_task(DEADLYSHOT_TIME, "Remove_BloodyBlade", id+TASK_USING_ITEM2)	
}

public Remove_BloodyBlade(id)
{
	id -= TASK_USING_ITEM2
	
	if(!is_user_alive(id))
		return
	if(zbheroex_get_user_zombie(id))
		return
	if(!Get_BitVar(g_Activating_BloodyBlade, id))
		return	
		
	UnSet_BitVar(g_CanBloodyBlade, id)
	UnSet_BitVar(g_Activating_BloodyBlade, id)
	
	if(zbheroex_get_user_nvg(id, 1, 1)) 
	{
		zbheroex_set_user_nvg(id, 0, 0, 0, 1)
		zbheroex_set_user_nvg(id, 1, 0, 0, 1)
	} else {
		message_begin(MSG_ONE_UNRELIABLE, g_Msg_ScreenFade, _, id)
		write_short(0) // duration
		write_short(0) // hold time
		write_short(0x0004) // fade type
		write_byte(255) // r
		write_byte(255) // g
		write_byte(255) // b
		write_byte(0) // alpha
		message_end()	
	}
}

stock amx_load_setting_int(const filename[], const setting_section[], setting_key[])
{
	if (strlen(filename) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZBHeroEX] Can't load settings: empty filename")
		return false;
	}
	
	if (strlen(setting_section) < 1 || strlen(setting_key) < 1)
	{
		log_error(AMX_ERR_NATIVE, "[ZBHeroEX] Can't load settings: empty section/key")
		return false;
	}
	
	// Build customization file path
	new path[64]
	get_configsdir(path, charsmax(path))
	format(path, charsmax(path), "%s/%s", path, filename)
	
	// File not present
	if (!file_exists(path))
		return false;
	
	// Open customization file for reading
	new file = fopen(path, "rt")
	
	// File can't be opened
	if (!file)
		return false;
	
	// Set up some vars to hold parsing info
	new linedata[1024], section[64]
	
	// Seek to setting's section
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// New section starting
		if (linedata[0] == '[')
		{
			// Store section name without braces
			copyc(section, charsmax(section), linedata[1], ']')
			
			// Is this our setting's section?
			if (equal(section, setting_section))
				break;
		}
	}
	
	// Section not found
	if (!equal(section, setting_section))
	{
		fclose(file)
		return false;
	}
	
	// Set up some vars to hold parsing info
	new key[64], current_value[32]
	
	// Seek to setting's key
	while (!feof(file))
	{
		// Read one line at a time
		fgets(file, linedata, charsmax(linedata))
		
		// Replace newlines with a null character to prevent headaches
		replace(linedata, charsmax(linedata), "^n", "")
		
		// Blank line or comment
		if (!linedata[0] || linedata[0] == ';') continue;
		
		// Section ended?
		if (linedata[0] == '[')
			break;
		
		// Get key and value
		strtok(linedata, key, charsmax(key), current_value, charsmax(current_value), '=')
		
		// Trim spaces
		trim(key)
		trim(current_value)
		
		// Is this our setting's key?
		if (equal(key, setting_key))
		{
			static return_value
			// Return int by reference
			return_value = str_to_num(current_value)
			
			// Values succesfully retrieved
			fclose(file)
			return return_value
		}
	}
	
	// Key not found
	fclose(file)
	return false;
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
