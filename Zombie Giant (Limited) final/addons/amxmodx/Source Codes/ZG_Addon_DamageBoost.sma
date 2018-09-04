#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <zombie_giant>

#define PLUGIN "[ZG] Addon: Damage Boost"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define LANG_DEFAULT "zombie_giant.txt"
#define RADIUS_ATKUP 200.0

#define HUD_PLAYER_X -1.0
#define HUD_PLAYER_Y 0.80

new Float:MyTime[33], g_Hud_Player, g_HamBot
new g_DamagePercent[33], g_PreviousPercent[33], g_PlayerLevel[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_dictionary(LANG_DEFAULT)
	
	RegisterHam(Ham_TakeDamage, "player", "fw_PlayerTakeDamage")
	g_Hud_Player = CreateHudSyncObj(4)
}

public Register_HamBot(id) 
{
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_PlayerTakeDamage")
}

public client_putinserver(id)
{
	if(!g_HamBot && is_user_bot(id))
	{
		g_HamBot = 1
		set_task(0.1, "Register_HamBot", id)
	}
}

public client_PostThink(id)
{
	if(!is_user_alive(id))
		return
	if(zg_is_giant(id))
		return
		
	static Float:Time; Time = get_gametime()
	if(Time - 0.5 > MyTime[id])
	{
		Update_PlayerHud(id)
		MyTime[id] = Time
	}
}

public Update_PlayerHud(id)
{
	static PowerUp[32], PowerDown[32]
	formatex(PowerUp, sizeof(PowerUp), "")
	formatex(PowerDown, sizeof(PowerDown), "")
	
	static Victim; Victim = -1
	static Float:Origin[3]; pev(id, pev_origin, Origin)
	static AvailableHuman; AvailableHuman = 0

	while((Victim = find_ent_in_sphere(Victim, Origin, RADIUS_ATKUP)) != 0)
	{
		if(Victim == id)
			continue
		if(!is_user_alive(Victim))
			continue
		if(zg_is_giant(Victim))
			continue
		
		AvailableHuman++
	}
	
	g_DamagePercent[id] = 100
	g_DamagePercent[id] += (10 * g_PlayerLevel[id])
	g_DamagePercent[id] += (5 * AvailableHuman)

	static Level; Level = clamp(g_DamagePercent[id], 100, 200)

	for(new i = 100; i < Level; i += 10)
		formatex(PowerUp, sizeof(PowerUp), "%s||", PowerUp)
	for(new i = 0; i < ((200 - Level) / 10); i++)
		formatex(PowerDown, sizeof(PowerDown), "%s---", PowerDown)
		
	// Update
	static Colour[3]
	Colour[0] = get_color_level(g_DamagePercent[id], 0)
	Colour[1] = get_color_level(g_DamagePercent[id], 1)
	Colour[2] = get_color_level(g_DamagePercent[id], 2)	
	
	if(g_DamagePercent[id] != g_PreviousPercent[id])
	{
		if(g_DamagePercent[id] > 100) fm_set_user_rendering(id, kRenderFxGlowShell, Colour[0], Colour[1], Colour[2], kRenderNormal, 0)
		else fm_set_user_rendering(id)
		
		g_PreviousPercent[id] = g_DamagePercent[id]
	}

	// Hud
	set_hudmessage(Colour[0], Colour[1], Colour[2], HUD_PLAYER_X, HUD_PLAYER_Y, 0, 1.0, 1.0)
	ShowSyncHudMsg(id, g_Hud_Player, "%L: %i%% + %i%%^n[%s%s]", LANG_DEFAULT, "HUD_ATK", 100 + (10 * g_PlayerLevel[id]), (5 * AvailableHuman), PowerUp, PowerDown)
}

public fw_PlayerTakeDamage(Victim, Inflictor, Attacker, Float:Damage, DamageBits)
{
	if((is_user_alive(Attacker) && is_user_alive(Victim)) && !zg_is_giant(Attacker))
	{
		static Float:Multiple
		Multiple = float(g_DamagePercent[Attacker]) / 100.0
		
		if(Multiple > 1.0 && Multiple != 0.0)
			SetHamParamFloat(4, Damage * Multiple)
	}

	return HAM_HANDLED
}

stock get_color_level(percent, num)
{
	static Color[3]
	switch(percent)
	{
		case 100..139: Color = {0,177,0}
		case 140..159: Color = {137,191,20}
		case 160..179: Color = {250,229,0}
		case 180..199: Color = {243,127,1}
		case 200..209: Color = {255,3,0}
		case 210..1000: Color = {127,40,208}
		default: Color = {100, 100, 100}
	}
	
	return Color[num]
}
