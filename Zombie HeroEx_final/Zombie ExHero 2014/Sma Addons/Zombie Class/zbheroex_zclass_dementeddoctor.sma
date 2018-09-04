#include <amxmodx>
#include <amxmisc>
#include <engine>
#include <fakemeta>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Class: Demented Doctor"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define HEAL_AMOUNT_HOST 2000
#define HEAL_AMOUNT_ORIGIN 500
#define HEAL_COOLDOWN_HOST 10
#define HEAL_COOLDOWN_ORIGIN 7
#define HEAL_RADIUS 500.0
#define HEAL_FOV 100

#define LANG_OFFICIAL LANG_PLAYER
#define SETTING_FILE "zombie_theheroex.ini"
#define LANG_FILE "zombie_theheroex.txt"

#define TASK_COOLDOWN 12001

// Zombie Configs
new zclass_name[32] = "Demented Doctor"
new zclass_desc[32] = "Heal"
new const zclass_sex = SEX_MALE
new zclass_lockcost = 0
new const zclass_hostmodel[] = "heal_zombi_host"
new const zclass_originmodel[] = "heal_zombi_origin"
new const zclass_clawsmodelhost[] = "v_knife_heal_zombi.mdl"
new const zclass_clawsmodelorigin[] = "v_knife_heal_zombi.mdl"
new const Float:zclass_gravity = 0.8
new const Float:zclass_speed = 280.0
new const Float:zclass_knockback = 1.25
new const DeathSound[2][] =
{
	"zombie_thehero/zombie/zombi_death_1.wav",
	"zombie_thehero/zombie/zombi_death_2.wav"
}
new const HurtSound[2][] = 
{
	"zombie_thehero/zombie/zombi_hurt_01.wav",
	"zombie_thehero/zombie/zombi_hurt_02.wav"	
}
new const HealSound[] = "zombie_thehero/zombie/zombi_heal.wav"
new const HealSound_Female[] = "zombie_thehero/zombie/zombi_heal_female.wav"
new const EvolSound[] = "zombie_thehero/zombie/zombi_evolution.wav"
new const HealSkillSound[] = "zombie_thehero/td_heal.wav"
new const HealerSpr[] = "sprites/zombie_thehero/zombihealer.spr"
new const HealedSpr[] = "sprites/zombie_thehero/zombiheal_head.spr"

new g_Zombie_DementedDoctor, g_CanHeal

new g_synchud1, g_MaxPlayers, g_Msg_Fov, g_MsgScreenFade, ReadyWords[16]

#define Get_BitVar(%1,%2) (%1 & (1 << (%2 & 31)))
#define Set_BitVar(%1,%2) %1 |= (1 << (%2 & 31))
#define UnSet_BitVar(%1,%2) %1 &= ~(1 << (%2 & 31))

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1)
	
	g_synchud1 = zbheroex_get_synchud_id(SYNCHUD_ZBHM_SKILL2)
	g_MaxPlayers = get_maxplayers()
	
	g_Msg_Fov = get_user_msgid("SetFOV")
	g_MsgScreenFade = get_user_msgid("ScreenFade")
}

public plugin_precache()
{
	register_dictionary(LANG_FILE)
	
	zclass_lockcost = amx_load_setting_int(SETTING_FILE, "Special Zombie Config", "HEAL_COST")
	formatex(zclass_name, sizeof(zclass_name), "%L", LANG_OFFICIAL, "ZOMBIE_HEAL_NAME")
	formatex(zclass_desc, sizeof(zclass_desc), "%L", LANG_OFFICIAL, "ZOMBIE_HEAL_DESC")
	formatex(ReadyWords, sizeof(ReadyWords), "%L", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_READY")
	
	// Register Zombie Class
	g_Zombie_DementedDoctor = zbheroex_register_zombie_class(zclass_name, zclass_desc, zclass_sex, zclass_lockcost, 
	zclass_gravity, zclass_speed, zclass_knockback)
	
	zbheroex_set_zombie_class_data1(zclass_hostmodel, zclass_originmodel, zclass_clawsmodelhost, zclass_clawsmodelorigin)
	zbheroex_set_zombie_class_data2(DeathSound[0], DeathSound[1], HurtSound[0], HurtSound[1], HealSound, EvolSound)
	zbheroex_set_zombiecode(g_Zombie_DementedDoctor, 1957)
	
	// Precache Class Resource
	engfunc(EngFunc_PrecacheSound, HealSound)
	engfunc(EngFunc_PrecacheSound, HealSound_Female)
	engfunc(EngFunc_PrecacheSound, HealSkillSound)
	
	engfunc(EngFunc_PrecacheModel, HealerSpr)
	engfunc(EngFunc_PrecacheModel, HealedSpr)
}

public zbheroex_user_infected(id)
{
	reset_skill(id)
}

public zbheroex_class_active(id, ClassID)
{
	if(ClassID != g_Zombie_DementedDoctor)
		return
		
	Set_BitVar(g_CanHeal, id)
	zbheroex_set_user_time(id, 100)
	
	if(is_user_bot(id)) set_task(random_float(5.0, 10.0), "Bot_DoSkill", id+111)
}

public Bot_DoSkill(id)
{
	id -= 111
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_DementedDoctor)
		return
	if(!Get_BitVar(g_CanHeal, id))
	{
		if(is_user_bot(id)) set_task(random_float(5.0, 10.0), "Bot_DoSkill", id+111)
		return
	}
	
	Do_Heal(id)
	if(is_user_bot(id)) set_task(random_float(5.0, 10.0), "Bot_DoSkill", id+111)
}

public zbheroex_class_unactive(id, ClassID)
{
	if(ClassID != g_Zombie_DementedDoctor)
		return
		
	reset_skill(id)
}

public reset_skill(id)
{
	UnSet_BitVar(g_CanHeal, id)
	zbheroex_set_user_time(id, 0)

	remove_task(id+TASK_COOLDOWN)
}

public zbheroex_user_spawned(id, Zombie)
{
	if(!Zombie) reset_skill(id)
}

public zbheroex_user_died(id) reset_skill(id)
public fw_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet)
{
	if(!player)
		return FMRES_IGNORED
	if(!is_user_alive(ent) || !is_user_alive(host))
		return FMRES_IGNORED
	if(!zbheroex_get_user_zombie(ent) || !zbheroex_get_user_zombie(host))
		return FMRES_IGNORED
	if(zbheroex_get_user_zombie_class(host) != g_Zombie_DementedDoctor)
		return FMRES_IGNORED
	if(!zbheroex_get_user_nvg(host, 1, 1))
		return FMRES_IGNORED
		
	static Float:CurHealth, Float:MaxHealth
	static Float:Percent, Percent2, RealPercent
	
	CurHealth = float(get_user_health(ent))
	MaxHealth = float(zbheroex_get_maxhealth(ent))
	
	Percent = (CurHealth / MaxHealth) * 100.0
	Percent2 = floatround(Percent)
	RealPercent = clamp(Percent2, 1, 100)
	
	static Color[3]
	
	switch(RealPercent)
	{
		case 1..49: Color = {75, 0, 0}
		case 50..79: Color = {75, 75, 0}
		case 80..100: Color = {0, 75, 0}
	}
	
	set_es(es, ES_RenderFx, kRenderFxGlowShell)
	set_es(es, ES_RenderMode, kRenderNormal)
	set_es(es, ES_RenderColor, Color)
	set_es(es, ES_RenderAmt, 16)
	
	return FMRES_HANDLED
}

public zbheroex_zombie_skill(id, ClassID)
{
	client_print(id, print_chat, "Fuck Bitch")
	if(ClassID != g_Zombie_DementedDoctor)
		return
	if(!Get_BitVar(g_CanHeal, id))
		return

	Do_Heal(id)
}

public Do_Heal(id)
{
	if(!is_user_alive(id))
		return
		
	static CurrentHealth, MaxHealth, RealHealth
	
	zbheroex_set_user_time(id, 0)
	UnSet_BitVar(g_CanHeal, id)
	
	if(zbheroex_get_user_level(id) > 1) // Origin Zombie
	{
		for(new i = 0; i < g_MaxPlayers; i++)
		{
			if(!is_user_alive(i))
				continue
			if(!zbheroex_get_user_zombie(i))
				continue
			if(entity_range(id, i) > HEAL_RADIUS)
				continue
				
			CurrentHealth = get_user_health(i)
			MaxHealth = zbheroex_get_maxhealth(i)
			
			RealHealth = min(CurrentHealth + HEAL_AMOUNT_ORIGIN, MaxHealth)
			zbheroex_set_user_health(id, RealHealth, 0)
			
			if(id == i) Heal_Icon(i, 1)
			else Heal_Icon(i, 0)
			
			if(zbheroex_get_user_nvg(i, 1, 0) || zbheroex_get_user_nvg(i, 0, 0))
			{
				// Make a screen fade 
				message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, i)
				write_short((1<<12) * 2) // duration
				write_short(0) // hold time
				write_short(0x0000) // fade type
				write_byte(0) // red
				write_byte(150) // green
				write_byte(0) // blue
				write_byte(50) // alpha
				message_end()
			}
			
			PlaySound(i, !zbheroex_get_user_female(id) ? HealSound : HealSound_Female)
		}
		
		EmitSound(id, CHAN_BODY, HealSkillSound)
	} else { // Host Zombie
		CurrentHealth = get_user_health(id)
		MaxHealth = zbheroex_get_maxhealth(id)
		
		RealHealth = clamp(CurrentHealth + HEAL_AMOUNT_HOST, CurrentHealth, MaxHealth)
		zbheroex_set_user_health(id, RealHealth, 0)
		
		Heal_Icon(id, 1)
		EmitSound(id, CHAN_BODY, HealSkillSound)
		
		if(zbheroex_get_user_nvg(id, 1, 0) || zbheroex_get_user_nvg(id, 0, 0))
		{
			// Make a screen fade 
			message_begin(MSG_ONE_UNRELIABLE, g_MsgScreenFade, _, id)
			write_short((1<<12) * 2) // duration
			write_short(0) // hold time
			write_short(0x0000) // fade type
			write_byte(0) // red
			write_byte(150) // green
			write_byte(0) // blue
			write_byte(50) // alpha
			message_end()
		}
	}
	
	set_fov(id, HEAL_FOV)
	set_task(0.5, "Remove_Fov", id)
	
	set_task(zbheroex_get_user_level(id) > 1 ? float(HEAL_COOLDOWN_ORIGIN) : float(HEAL_COOLDOWN_HOST), "Remove_Heal", id+TASK_COOLDOWN)
}

public Remove_Fov(id)
{
	if(!is_user_connected(id))
		return
		
	set_fov(id)
}

public Remove_Heal(id)
{
	id -= TASK_COOLDOWN

	if(!is_user_alive(id))
		return
	if(!zbheroex_get_user_zombie(id))
		return
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_DementedDoctor)
		return 
	if(Get_BitVar(g_CanHeal, id))
		return	
		
	Set_BitVar(g_CanHeal, id)
	zbheroex_set_user_time(id, 100)
}

public zbheroex_skill_show(id, Zombie)
{
	client_print(id, print_chat, "Show 0")
	if(!Zombie)
		return
	client_print(id, print_chat, "Show 1")
	if(zbheroex_get_user_zombie_class(id) != g_Zombie_DementedDoctor)
		return 	
		
	static Time; Time = zbheroex_get_user_time(id)
	if(Time < 100) zbheroex_set_user_time(id, Time + 1)
	
	static Float:percent, percent2
	static Float:timewait
	
	client_print(id, print_chat, "Show 2")
	
	timewait = zbheroex_get_user_level(id) > 1 ? float(HEAL_COOLDOWN_ORIGIN) : float(HEAL_COOLDOWN_HOST)
	
	percent = (float(Time) / timewait) * 100.0
	percent2 = floatround(percent)
	
	if(percent2 > 0 && percent2 < 50)
	{
		client_print(id, print_chat, "Show 3")
		set_hudmessage(255, 0, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, percent2)
	} else if(percent2 >= 50 && percent < 100) {
		client_print(id, print_chat, "Show 4")
		set_hudmessage(255, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%i%%)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, percent2)
	} else if(percent2 >= 100) {
		set_hudmessage(0, 255, 0, -1.0, 0.10, 0, 1.5, 1.5)
		ShowSyncHudMsg(id, g_synchud1, "[%L] %s^n[G] - %s (%s)", LANG_OFFICIAL, "ZOMBIE_SKILL_HUD_CLASS", zclass_name, zclass_desc, ReadyWords)
		
		client_print(id, print_chat, "Show")
		
		if(!Get_BitVar(g_CanHeal, id)) Set_BitVar(g_CanHeal, id)
	}	
}

stock Heal_Icon(id, Healer)
{
	if(Healer) zbheroex_show_attachment(id, HealerSpr, 2.0, 1.0, 1.0, 24)
	else zbheroex_show_attachment(id, HealedSpr, 2.0, 1.0, 1.0, 0)
	
	/*
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2]) + Healer == 1 ? 0 : 35); // origin z
	write_short(Healer == 1 ? g_HealerSpr_Id : g_HealedSpr_Id); // sprites
	write_byte(15); // scale in 0.1's
	write_byte(12); // framerate
	write_byte(14); // flags 
	message_end(); // message end*/
}

stock EmitSound(id, chan, const file_sound[])
{
	emit_sound(id, chan, file_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
}

stock PlaySound(id, const sound[])
{
	if(equal(sound[strlen(sound)-4], ".mp3")) client_cmd(id, "mp3 play ^"sound/%s^"", sound)
	else client_cmd(id, "spk ^"%s^"", sound)
}

stock set_fov(id, num = 90)
{
	message_begin(MSG_ONE_UNRELIABLE, g_Msg_Fov, {0,0,0}, id)
	write_byte(num)
	message_end()
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
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang3076\\ f0\\ fs16 \n\\ par }
*/
