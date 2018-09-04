#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Shop: Zombie"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

// Increase HP
#define HEALTH_INCREASE 1.25
#define RESPAWNHEALTH_INCREASE 20
new g_IncreaseHP, g_Had_IncreaseHP, g_IncreaseHP_Cost

// Zombie Grenade
#define ZOMBIEGRENADE_KNOCKPOWER 1000
#define ZOMBIEGRENADE_RADIUS 200

#define ZOMBIEGRENADE_PMODEL "models/zombie_thehero/p_zombibomb.mdl"
#define ZOMBIEGRENADE_WMODEL "models/zombie_thehero/w_zombibomb.mdl"

#define ZOMBIEGRENADE_EXPSOUND "zombie_thehero/zombi_bomb_exp.wav"
#define ZOMBIEGRENADE_EXPSPR "sprites/zombie_thehero/zombiebomb_exp.spr"

new const ZombieGrenade_Sound[11][] =
{
	"zombie_thehero/zombi_bomb_deploy.wav",
	"zombie_thehero/zombi_bomb_idle_1.wav",
	"zombie_thehero/zombi_bomb_idle_2.wav",
	"zombie_thehero/zombi_bomb_idle_3.wav",
	"zombie_thehero/zombi_bomb_idle_4.wav",
	"zombie_thehero/zombi_bomb_idle_5.wav",
	"zombie_thehero/zombi_bomb_idle_6.wav",
	"zombie_thehero/zombi_bomb_idle_7.wav",
	"zombie_thehero/zombi_bomb_idle_8.wav",
	"zombie_thehero/zombi_bomb_pull_1.wav",
	"zombie_thehero/zombi_bomb_throw.wav"
}

new const ZombieGrenade_VModel[9][] =
{
	"models/zombie_thehero/zombiebomb/v_zombibomb_tank.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_cosspeed1.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_heal.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_deimos_host.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_deimos_origin.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_witch_host.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_witch_origin.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_stamper.mdl",
	"models/zombie_thehero/zombiebomb/v_zombibomb_resident.mdl"
}

new const HitSound[3][] =
{
	"player/bhit_flesh-1.wav",
	"player/bhit_flesh-2.wav",
	"player/bhit_flesh-3.wav"
}	

new g_ZombieGrenade, g_Had_ZombieGrenade, g_ZombieGrenade_Cost
new ZOMBIEGRENADE_EXPSPRID
new g_OldWeapon[33], g_MaxPlayers, g_Msg_ShakeScreen

// Immediately Respawn
new g_ImRespawn, g_Had_ImRespawn, g_ImRespawn_Cost

// Hud
#define HUD_BUFF_X 0.015
#define HUD_BUFF_Y 0.20

new g_OwnItem
new g_Hud_Buff

// Temp Text
new g_FullText[256], g_FullText2[128], g_ItemName[64]

// MACROS
#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_forward(FM_SetModel, "fw_SetModel")	
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	
	g_MaxPlayers = get_maxplayers()
	g_Msg_ShakeScreen = get_user_msgid("ScreenShake")
	g_Hud_Buff = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)

	Load_ItemConfig()
	Register_Item()
	
	engfunc(EngFunc_PrecacheModel, ZOMBIEGRENADE_PMODEL)
	engfunc(EngFunc_PrecacheModel, ZOMBIEGRENADE_WMODEL)
	
	for(new i = 0; i < sizeof(ZombieGrenade_VModel); i++)
		engfunc(EngFunc_PrecacheModel, ZombieGrenade_VModel[i])
	for(new i = 0; i < sizeof(ZombieGrenade_Sound); i++)
		engfunc(EngFunc_PrecacheSound, ZombieGrenade_Sound[i])	
	
	engfunc(EngFunc_PrecacheSound, ZOMBIEGRENADE_EXPSOUND)
	ZOMBIEGRENADE_EXPSPRID = engfunc(EngFunc_PrecacheModel, ZOMBIEGRENADE_EXPSPR)
}

public Load_ItemConfig()
{
	g_IncreaseHP_Cost = amx_load_setting_int(SETTING_FILE, "Item", "INCREASEHP_COST")
	g_ZombieGrenade_Cost = amx_load_setting_int(SETTING_FILE, "Item", "ZOMBIEGRENADE_COST")
	g_ImRespawn_Cost = amx_load_setting_int(SETTING_FILE, "Item", "IMRESPAWN_COST")
}

public Register_Item()
{
	static ItemName[64], ItemDesc[80]
	
	// Increase HP
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_INCREASEHP_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_INCREASEHP_DESC")
	g_IncreaseHP_Cost = zbheroex_register_item(ItemName, ItemDesc, g_IncreaseHP_Cost, TEAM_ZOMBIE)
	
	// Zombie Grenade
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_ZOMBIEGRENADE_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_ZOMBIEGRENADE_DESC")
	g_ZombieGrenade = zbheroex_register_item(ItemName, ItemDesc, g_ZombieGrenade_Cost, TEAM_ZOMBIE)

	// Immediately Respawn
	formatex(ItemName, sizeof(ItemName), "%L", LANG_OFFICIAL, "ITEM_IMRESPAWN_NAME")
	formatex(ItemDesc, sizeof(ItemDesc), "%L", LANG_OFFICIAL, "ITEM_IMRESPAWN_DESC")
	g_ImRespawn = zbheroex_register_item(ItemName, ItemDesc, g_ImRespawn_Cost, TEAM_ZOMBIE)
}


public client_putinserver(id) 
{	
	Reset_Skill(id)
	//Give_RandomItem(id)
}

public Reset_Skill(id)
{
	UnSet_BitVar(g_Had_IncreaseHP, id)
	UnSet_BitVar(g_Had_ZombieGrenade, id)
	UnSet_BitVar(g_Had_ImRespawn, id)
}

public zbheroex_user_infect(id)
{
	//Reset_Skill(id)
}

public Give_RandomItem(id)
{
	static RandomNum
	
	RandomNum = random_num(0, 100)
	if(RandomNum >= 70)
	{
		zbheroex_shop_item_bought(id, g_ZombieGrenade)
		zbheroex_set_item_status(id, g_ZombieGrenade, 1)
	}
	
	RandomNum = random_num(0, 100)
	if(RandomNum >= 80)
	{
		zbheroex_shop_item_bought(id, g_Had_ImRespawn)
		zbheroex_set_item_status(id, g_Had_ImRespawn, 1)
	}
}

public zbheroex_skill_show(id, Zombie)
{
	if(!Zombie) return
	
	Show_BuffItem(id)
}

public Show_BuffItem(id)
{
	if(!Get_BitVar(g_OwnItem, id)) return
	formatex(g_FullText, sizeof(g_FullText), "[%L]^n", LANG_OFFICIAL, "ITEM_LISTNAME")
	
	if(Get_BitVar(g_Had_IncreaseHP, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_INCREASEHP_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}
	if(Get_BitVar(g_Had_ZombieGrenade, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_ZOMBIEGRENADE_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}
	if(Get_BitVar(g_Had_ImRespawn, id))
	{
		formatex(g_ItemName, sizeof(g_ItemName), " %L", LANG_OFFICIAL, "ITEM_IMRESPAWN_NAME")
		formatex(g_FullText2, sizeof(g_FullText2), "%s^n%s", g_FullText, g_ItemName)
		formatex(g_FullText, sizeof(g_FullText), "%s", g_FullText2)
	}		
	
	set_hudmessage(85, 255, 255, HUD_BUFF_X, HUD_BUFF_Y, 0, 2.0, 2.0)
	ShowSyncHudMsg(id, g_Hud_Buff, g_FullText)
}

public zbheroex_shop_item_bought(id, ItemId)
{
	if(ItemId == g_IncreaseHP)
	{
		Set_BitVar(g_Had_IncreaseHP, id)
		if(is_user_alive(id) && zbheroex_get_user_zombie(id)) zbheroex_user_infected(id, 0, 1)
		
		Set_BitVar(g_OwnItem, id)
	} else if(ItemId == g_ZombieGrenade) {
		Set_BitVar(g_Had_ZombieGrenade, id)
		
		if(is_user_alive(id) && zbheroex_get_user_zombie(id)) fm_give_item(id, "weapon_hegrenade")
		
		Set_BitVar(g_OwnItem, id)
	} else if(ItemId == g_ImRespawn) {
		Set_BitVar(g_Had_ImRespawn, id)
		zbheroex_set_respawntime(id, 0)
		
		Set_BitVar(g_OwnItem, id)
	}
}

// Increase Health
public zbheroex_user_infected(id, Infector, Infection)
{
	// IncreaseHP
	if(Get_BitVar(g_Had_IncreaseHP, id))
	{
		if(Infection)
		{ // Infection
			zbheroex_set_user_health(id, floatround(float(get_user_health(id)) * HEALTH_INCREASE), 1)
		} else { // Respawn
			static Health; Health = get_user_health(id)
			static AddHealth; AddHealth = (Health * RESPAWNHEALTH_INCREASE) / 100
			
			zbheroex_set_user_health(id, Health + AddHealth, 1)
		}
	}

	// Zombie Grenade
	ZombieGrenade_Handle(id)
}

// Zombie Grenade
public ZombieGrenade_Handle(id)
{
	if(Get_BitVar(g_Had_ZombieGrenade, id))
	{
		fm_give_item(id, "weapon_hegrenade")
		engclient_cmd(id, "weapon_knife")
	}
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id)) return
	if(!zbheroex_get_user_zombie(id)) return
	
	static CSWID; CSWID = read_data(2)
	
	if((CSWID == CSW_HEGRENADE && g_OldWeapon[id] != CSW_HEGRENADE) && Get_BitVar(g_Had_ZombieGrenade, id))
	{
		set_pev(id, pev_viewmodel2, ZombieGrenade_VModel[Get_ZombieGrenade_ModelId(zbheroex_get_user_zombie_class(id), zbheroex_get_user_level(id) > 1 ? 1 : 0)])
		set_pev(id, pev_weaponmodel2, ZOMBIEGRENADE_PMODEL)
	}
	
	g_OldWeapon[id] = CSWID
}

public fw_SetModel(Ent, const Model[])
{
	if(!pev_valid(Ent))
		return FMRES_IGNORED;

	static Float:dmgtime
	pev(Ent, pev_dmgtime, dmgtime)
	
	if(dmgtime == 0.0) return FMRES_IGNORED;
	
	// Get attacker
	static id; id = pev(Ent, pev_owner)
	
	if(is_user_connected(id) && zbheroex_get_user_zombie(id))
	{
		if(Model[9] == 'h' && Model[10] == 'e') // Zombie Bomb
		{
			set_pev(Ent, pev_flTimeStepSound, 3465345)
			engfunc(EngFunc_SetModel, Ent, ZOMBIEGRENADE_WMODEL)

			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_ThinkGrenade(Ent)
{
	if(!pev_valid(Ent)) return HAM_IGNORED

	static Float:dmgtime
	pev(Ent, pev_dmgtime, dmgtime)
	
	if(dmgtime > get_gametime())
		return HAM_IGNORED
	if(pev(Ent, pev_flTimeStepSound) != 3465345)
		return HAM_IGNORED
		
	ZombieGrenade_Explosion(Ent)
	
	return HAM_SUPERCEDE	
}

public ZombieGrenade_Explosion(Ent)
{
	static Float:Origin[3]
	pev(Ent, pev_origin, Origin)
	
	// Make the explosion
	EffectZombieBomExp(Origin)
	
	engfunc(EngFunc_EmitSound, Ent, CHAN_BODY, ZOMBIEGRENADE_EXPSOUND, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	for(new i = 0; i < g_MaxPlayers; i++)
	{
		if(!is_user_alive(i))
			continue
		if(entity_range(Ent, i) > float(ZOMBIEGRENADE_RADIUS))
			continue
			
		Shake_Screen(i)
		HookEnt(i, Origin, float(ZOMBIEGRENADE_KNOCKPOWER))
		emit_sound(i, CHAN_BODY, HitSound[random_num(0, sizeof(HitSound) - 1)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		
		if(!zbheroex_get_user_zombie(i))
		{
			static Float:Angles[3]
			pev(i, pev_v_angle, Angles)
			
			Angles[0] += random_float(-50.0, 50.0)
			Angles[0] = float(clamp(floatround(Angles[0]), -180, 180))
			
			Angles[1] += random_float(-50.0, 50.0)
			Angles[1] = float(clamp(floatround(Angles[1]), -180, 180))
			
			set_pev(i, pev_fixangle, 1)
			set_pev(i, pev_v_angle, Angles)
		}
	}

	// Remove
	engfunc(EngFunc_RemoveEntity, Ent)
}

public Shake_Screen(id)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_ShakeScreen, {0,0,0}, id)
	write_short(1<<14)
	write_short(1<<13)
	write_short(1<<13)
	message_end()
}

public EffectZombieBomExp(Float:Origin[3])
{
	for(new i = 0; i < 3; i++)
	{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_EXPLOSION)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(ZOMBIEGRENADE_EXPSPRID)
		write_byte(40)
		write_byte(30)
		write_byte(14)
		message_end()
	}
}

stock HookEnt(ent, Float:VicOrigin[3], Float:speed)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	static Float:fl_Time; fl_Time = distance_f / speed
	
	fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
	fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
	fl_Velocity[2] = (EntOrigin[2] - VicOrigin[2]) / fl_Time

	set_pev(ent, pev_velocity, fl_Velocity)
}

public Get_ZombieGrenade_ModelId(ZombieClass, OriginZombie)
{
	static SecretCode; SecretCode = zbheroex_get_zombiecode(ZombieClass)
	switch(SecretCode)
	{
		case 1912: return 0
		case 1942: return 1
		case 1957: return 2
		case 1962:
		{
			if(!OriginZombie) return 3
			else return 4
		}
		case 1975: 
		{
			if(!OriginZombie) return 5
			else return 6
		}
		case 1986: return 7
		case 1996: return 8
		default: return 0
	}
	
	return 0
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
