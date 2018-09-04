#include <amxmodx>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <biohazard>
#include <bio_shop>

/*================================================================================
 [Plugin Customization]
=================================================================================*/

// Uncomment the following if you wish to set custom models for napalms
#define USE_NAPALM_CUSTOM_MODELS

#if defined USE_NAPALM_CUSTOM_MODELS // Then set your custom models here
new const g_model_napalm_view[] = "models/biohazard/v_holybomb.mdl"
new const g_model_napalm_player[] = "models/biohazard/p_holybomb.mdl"
new const g_model_napalm_world[] = "models/biohazard/w_holybomb.mdl"
#endif

// Explosion sounds
new const grenade_fire[][] = { "weapons/hegrenade-1.wav" }

// Player burning sounds
new const grenade_fire_player[][] = { "scientist/sci_fear8.wav", "scientist/sci_pain1.wav", "scientist/scream02.wav" }

// Grenade sprites
new const sprite_grenade_fire[] = "sprites/biohazard/holybomb_burn.spr"
new const sprite_grenade_smoke[] = "sprites/black_smoke3.spr"
new const sprite_grenade_trail[] = "sprites/laserbeam.spr"
new const sprite_grenade_ring[] = "sprites/shockwave.spr"

// Glow and trail colors (red, green, blue)
const NAPALM_R = 0
const NAPALM_G = 200
const NAPALM_B = 200

/*===============================================================================*/

// Burning task
const TASK_BURN = 1000
#define ID_BURN (taskid - TASK_BURN)
#define BURN_DURATION args[0]
#define BURN_ATTACKER args[1]

// CS Player PData Offsets (win32)
const OFFSET_CSTEAMS = 114
const OFFSET_CSMONEY = 115
const OFFSET_MAPZONE = 235
new const AFFECTED_BPAMMO_OFFSETS[] = { 388, 387, 389 }
const OFFSET_LINUX = 5 // offsets +5 in Linux builds

// CS Player CBase Offsets (win32)
const OFFSET_ACTIVE_ITEM = 373

// CS Weapon PData Offsets (win32)
const OFFSET_WEAPONID = 43
const OFFSET_LINUX_WEAPONS = 4 // weapon offsets are only 4 steps higher on Linux

// CS Weapon CBase Offsets (win32)
const OFFSET_WEAPONOWNER = 41

// Some constants
const PLAYER_IN_BUYZONE = (1<<0)

// pev_ field used to store custom nade types and their values
const PEV_NADE_TYPE = pev_flTimeStepSound
const NADE_TYPE_NAPALM = 681856

// pev_ field used to store napalm's custom ammo
const PEV_NAPALM_AMMO = pev_flSwimTime

// Weapons that can be napalms
new const AFFECTED_NAMES[][] = { "HE", "FB", "SG" }
new const AFFECTED_CLASSNAMES[][] = { "weapon_hegrenade", "weapon_flashbang", "weapon_smokegrenade" }
new const AFFECTED_MODELS[][] = { "w_he", "w_fl", "w_sm" }
new const AFFECTED_AMMOID[] = { 12, 11, 13 }
#if defined USE_NAPALM_CUSTOM_MODELS
new const AFFECTED_WEAPONS[] = { CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE }
#endif

// CS Sounds
new const sound_buyammo[] = "items/9mmclip1.wav"

// Whether ham forwards are registered for CZ bots
new g_hamczbots

// Precached sprites indices
new g_flameSpr, g_smokeSpr, g_trailSpr, g_exploSpr

// Messages
new g_msgDamage, g_msgMoney, g_msgBlinkAcct, g_msgAmmoPickup

// CVAR pointers
new cvar_radius, cvar_price, cvar_hitself, cvar_duration, cvar_slowdown, cvar_override,
cvar_damage, cvar_on, cvar_buyzone, cvar_ff, cvar_cankill, cvar_spread, cvar_botquota,
cvar_teamrestrict, cvar_screamrate, cvar_keepexplosion, cvar_affect, cvar_carrylimit

// Cached stuff
new g_maxplayers, g_on, g_affect, g_override, g_allowedteam, g_keepexplosion, g_spread,
g_ff, g_duration, g_buyzone, g_price, g_carrylimit, g_hitself, g_screamrate, g_damage,
Float:g_slowdown, g_cankill, Float:g_radius

new g_holy_bomb

// Precache all custom stuff
public plugin_precache()
{
	new i
	for (i = 0; i < sizeof grenade_fire; i++)
		engfunc(EngFunc_PrecacheSound, grenade_fire[i])
	for (i = 0; i < sizeof grenade_fire_player; i++)
		engfunc(EngFunc_PrecacheSound, grenade_fire_player[i])
	
	g_flameSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_fire)
	g_smokeSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_smoke)
	g_trailSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_trail)
	g_exploSpr = engfunc(EngFunc_PrecacheModel, sprite_grenade_ring)
	
	// CS sounds (just in case)
	engfunc(EngFunc_PrecacheSound, sound_buyammo)
	
#if defined USE_NAPALM_CUSTOM_MODELS
	engfunc(EngFunc_PrecacheModel, g_model_napalm_view)
	engfunc(EngFunc_PrecacheModel, g_model_napalm_player)
	engfunc(EngFunc_PrecacheModel, g_model_napalm_world)
#endif
}

public plugin_init()
{
	// Register plugin call
	register_plugin("Napalm Nades", "1.3a", "MeRcyLeZZ")
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	
	// Forwards
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_ThinkGrenade")
	RegisterHam(Ham_Touch, "player", "fw_TouchPlayer")
#if defined USE_NAPALM_CUSTOM_MODELS
	for (new i = 0; i < sizeof AFFECTED_CLASSNAMES; i++)
		RegisterHam(Ham_Item_Deploy, AFFECTED_CLASSNAMES[i], "fw_Item_Deploy_Post", 1)
#endif
	
	g_holy_bomb = bio_register_item("Holy Bomb", 3000, "That holy can burn zombie", TEAM_HUMAN)
	
	// Client commands
	//register_clcmd("say napalm", "buy_napalm")
	//register_clcmd("say /napalm", "buy_napalm")
	
	// CVARS
	cvar_on = register_cvar("bio_napalm_on", "1")
	cvar_affect = register_cvar("bio_napalm_affect", "1")
	cvar_teamrestrict = register_cvar("bio_napalm_team", "0")
	cvar_override = register_cvar("bio_napalm_override", "0")
	cvar_price = register_cvar("bio_napalm_price", "1000")
	cvar_buyzone = register_cvar("bio_napalm_buyzone", "0")
	cvar_carrylimit = register_cvar("bio_napalm_carrylimit", "3")
	
	cvar_radius = register_cvar("bio_napalm_radius", "240")
	cvar_hitself = register_cvar("bio_napalm_hitself", "0")
	cvar_ff = register_cvar("bio_napalm_ff", "0")
	cvar_spread = register_cvar("bio_napalm_spread", "1")
	cvar_keepexplosion = register_cvar("bio_napalm_keepexplosion", "0")
	
	cvar_duration = register_cvar("bio_napalm_duration", "10")
	cvar_damage = register_cvar("bio_napalm_damage", "5")
	cvar_cankill = register_cvar("bio_napalm_cankill", "1")
	cvar_slowdown = register_cvar("bio_napalm_slowdown", "0.5")
	cvar_screamrate = register_cvar("bio_napalm_screamrate", "20")
	
	cvar_botquota = get_cvar_pointer("bot_quota")
	g_maxplayers = get_maxplayers()
	
	// Message ids
	g_msgDamage = get_user_msgid("Damage")
	g_msgMoney = get_user_msgid("Money")
	g_msgBlinkAcct = get_user_msgid("BlinkAcct")
	g_msgAmmoPickup = get_user_msgid("AmmoPickup")
}

public plugin_cfg()
{
	// Cache CVARs after configs are loaded
	set_task(0.5, "event_round_start")
}

// Round Start Event
public event_round_start()
{
	// Cache CVARs
	g_on = get_pcvar_num(cvar_on)
	g_affect = get_pcvar_num(cvar_affect)
	g_override = get_pcvar_num(cvar_override)
	g_allowedteam = get_pcvar_num(cvar_teamrestrict)
	g_keepexplosion = get_pcvar_num(cvar_keepexplosion)
	g_spread = get_pcvar_num(cvar_spread)
	g_ff = get_pcvar_num(cvar_ff)
	g_duration = get_pcvar_num(cvar_duration)
	g_buyzone = get_pcvar_num(cvar_buyzone)
	g_price = get_pcvar_num(cvar_price)
	g_carrylimit = get_pcvar_num(cvar_carrylimit)
	g_hitself = get_pcvar_num(cvar_hitself)
	g_screamrate = get_pcvar_num(cvar_screamrate)
	g_slowdown = get_pcvar_float(cvar_slowdown)
	g_damage = floatround(get_pcvar_float(cvar_damage), floatround_ceil)
	g_cankill = get_pcvar_num(cvar_cankill)
	g_radius = get_pcvar_float(cvar_radius)
	
	// Stop any burning tasks on players
	for (new id = 1; id <= g_maxplayers; id++)
		remove_task(id+TASK_BURN);
}

// Client joins the game
public client_putinserver(id)
{
	// CZ bots seem to use a different "classtype" for player entities
	// (or something like that) which needs to be hooked separately
	if (!g_hamczbots && cvar_botquota && is_user_bot(id))
	{
		// Set a task to let the private data initialize
		set_task(0.1, "register_ham_czbots", id)
	}
}

// Set Model Forward
public fw_SetModel(entity, const model[])
{
	// Napalm grenades disabled
	if (!g_on) return FMRES_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Grenade not yet thrown
	if (dmgtime == 0.0)
		return FMRES_IGNORED;
	
	// Not an affected grenade
	if (!equal(model[7], AFFECTED_MODELS[g_affect-1], 4))
		return FMRES_IGNORED;
	
	// Get owner of grenade and napalm weapon entity
	static owner, napalm_weaponent
	owner = pev(entity, pev_owner)
	napalm_weaponent = fm_get_user_current_weapon_ent(owner)
	
	// Not a napalm grenade (because the weapon entity of its owner doesn't have the flag set)
	if (!g_override && pev(napalm_weaponent, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return FMRES_IGNORED;
	
	// Get owner's team
	static owner_team
	owner_team = fm_get_user_team(owner)
	
	// Player is on a restricted team
	if (g_allowedteam > 0 && g_allowedteam != owner_team)
		return FMRES_IGNORED;
	
	// Give it a glow
	fm_set_rendering(entity, kRenderFxGlowShell, NAPALM_R, NAPALM_G, NAPALM_B, kRenderNormal, 16)
	
	// And a colored trail
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // TE id
	write_short(entity) // entity
	write_short(g_trailSpr) // sprite
	write_byte(10) // life
	write_byte(10) // width
	write_byte(NAPALM_R) // r
	write_byte(NAPALM_G) // g
	write_byte(NAPALM_B) // b
	write_byte(200) // brightness
	message_end()
	
	// Reduce napalm ammo
	static napalm_ammo
	napalm_ammo = pev(napalm_weaponent, PEV_NAPALM_AMMO)
	set_pev(napalm_weaponent, PEV_NAPALM_AMMO, --napalm_ammo)
	
	// Run out of napalms?
	if (napalm_ammo < 1)
	{
		// Remove napalm flag from the owner's weapon entity
		set_pev(napalm_weaponent, PEV_NADE_TYPE, 0)
	}
	
	// Set grenade type on the thrown grenade entity
	set_pev(entity, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
	
	// Set owner's team on the thrown grenade entity
	set_pev(entity, pev_team, owner_team)
	
#if defined USE_NAPALM_CUSTOM_MODELS
	// Set custom model and supercede the original forward
	engfunc(EngFunc_SetModel, entity, g_model_napalm_world)
	return FMRES_SUPERCEDE;
#else
	return FMRES_IGNORED;
#endif
}

// Grenade Think Forward
public fw_ThinkGrenade(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return HAM_IGNORED;
	
	// Get damage time of grenade
	static Float:dmgtime
	pev(entity, pev_dmgtime, dmgtime)
	
	// Check if it's time to go off
	if (dmgtime > get_gametime())
		return HAM_IGNORED;
	
	// Not a napalm grenade
	if (pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return HAM_IGNORED;
	
	// Explode event
	napalm_explode(entity)
	
	// Keep the original explosion?
	if (g_keepexplosion)
	{
		set_pev(entity, PEV_NADE_TYPE, 0)
		return HAM_IGNORED;
	}
	
	// Get rid of the grenade
	engfunc(EngFunc_RemoveEntity, entity)
	return HAM_SUPERCEDE;
}

// Player Touch Forward
public fw_TouchPlayer(self, other)
{
	// Spread cvar disabled or not touching a player
	if (!g_spread || !is_user_alive(other))
		return;
	
	// Toucher not on fire or touched player already on fire
	if (!task_exists(self+TASK_BURN) || task_exists(other+TASK_BURN))
		return;
	
	// Check if friendly fire is allowed
	if (!g_ff && fm_get_user_team(self) == fm_get_user_team(other))
		return;
	
	// Heat icon
	message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, other)
	write_byte(0) // damage save
	write_byte(0) // damage take
	write_long(DMG_BURN) // damage type
	write_coord(0) // x
	write_coord(0) // y
	write_coord(0) // z
	message_end()
	
	// Our task params
	static params[2]
	params[0] = g_duration * 2 // duration (reduced a bit)
	params[1] = self // attacker
	
	// Set burning task on victim
	set_task(0.1, "burning_flame", other+TASK_BURN, params, sizeof params)
}

#if defined USE_NAPALM_CUSTOM_MODELS
// Ham Weapon Deploy Forward
public fw_Item_Deploy_Post(entity)
{
	// Napalm grenades disabled
	if (!g_on) return;
	
	// Not a napalm grenade (because the weapon entity of its owner doesn't have the flag set)
	if (!g_override && pev(entity, PEV_NADE_TYPE) != NADE_TYPE_NAPALM)
		return;
	
	// Get weapon's id
	static weaponid
	weaponid = fm_get_weapon_ent_id(entity)
	
	// Not an affected grenade
	if (weaponid != AFFECTED_WEAPONS[g_affect-1])
		return;
	
	// Get weapon's owner
	static owner
	owner = fm_get_weapon_ent_owner(entity)
	
	// Player is on a restricted team
	if (g_allowedteam > 0 && g_allowedteam != fm_get_user_team(owner))
		return;
	
	// Replace models
	set_pev(owner, pev_viewmodel2, g_model_napalm_view)
	set_pev(owner, pev_weaponmodel2, g_model_napalm_player)
}
#endif

public bio_item_selected(id, item)
{
	if(item == g_holy_bomb)
	{
		// Get napalm weapon entity
		static napalm_weaponent
		napalm_weaponent = fm_get_napalm_entity(id, g_affect)
		
		// Does the player have a napalm already?
		if (napalm_weaponent != 0)
		{
			// Retrieve napalm ammo
			static napalm_ammo
			napalm_ammo = pev(napalm_weaponent, PEV_NAPALM_AMMO)
			
			// Check if allowed to have this many napalms
			if (napalm_ammo < g_carrylimit)
			{
				// Increase napalm ammo
				set_pev(napalm_weaponent, PEV_NAPALM_AMMO, ++napalm_ammo)
				
				// Increase player's backpack ammo
				set_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1], get_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1]) + 1, OFFSET_LINUX)
				
				// Flash ammo in hud
				message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
				write_byte(AFFECTED_AMMOID[g_affect-1]) // ammo id
				write_byte(1) // ammo amount
				message_end()
				
				// Play clip purchase sound
				engfunc(EngFunc_EmitSound, id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				// Set napalm flag on the weapon entity (bugfix)
				set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
			}
			else
			{
				client_print(id, print_center, "You cannot carry any more napalms!")
				return PLUGIN_HANDLED;
			}
		}
		else
		{
			// Give napalm
			fm_give_item(id, AFFECTED_CLASSNAMES[g_affect-1])
			
			// Get napalm weapon entity now it exists
			napalm_weaponent = fm_get_napalm_entity(id, g_affect)
			
			// Set napalm flag on the weapon entity
			set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
			
			// Set napalm ammo
			set_pev(napalm_weaponent, PEV_NAPALM_AMMO, 1)
		}
	}
	
	return PLUGIN_CONTINUE
}


// Napalm purchase command
public buy_napalm(id)
{
	// Napalm grenades disabled
	if (!g_on) return PLUGIN_CONTINUE;
	
	// Check if override setting is enabled instead
	if (g_override)
	{
		client_print(id, print_center, "Just buy a %s grenade and get a napalm automatically!", AFFECTED_NAMES[g_affect-1])
		return PLUGIN_HANDLED;
	}
	
	// Check if player is alive
	if (!is_user_alive(id))
	{
		client_print(id, print_center, "You can't buy when you're dead!")
		return PLUGIN_HANDLED;
	}
	
	// Check if the player is on a restricted team
	if (g_allowedteam > 0 && g_allowedteam != fm_get_user_team(id))
	{
		client_print(id, print_center, "Your team cannot buy napalm nades!")
		return PLUGIN_HANDLED;
	}
	
	// Check if player needs to be in a buyzone
	if (g_buyzone && !fm_get_user_buyzone(id))
	{
		client_print(id, print_center, "You are not in a buyzone!")
		return PLUGIN_HANDLED;
	}
	
	// Check that player has the money
	if (fm_get_user_money(id) < g_price)
	{
		client_print(id, print_center, "#Cstrike_TitlesTXT_Not_Enough_Money")
		
		// Blink money
		message_begin(MSG_ONE_UNRELIABLE, g_msgBlinkAcct, _, id)
		write_byte(2) // times
		message_end()
		
		return PLUGIN_HANDLED;
	}
	
	// Get napalm weapon entity
	static napalm_weaponent
	napalm_weaponent = fm_get_napalm_entity(id, g_affect)
	
	// Does the player have a napalm already?
	if (napalm_weaponent != 0)
	{
		// Retrieve napalm ammo
		static napalm_ammo
		napalm_ammo = pev(napalm_weaponent, PEV_NAPALM_AMMO)
		
		// Check if allowed to have this many napalms
		if (napalm_ammo < g_carrylimit)
		{
			// Increase napalm ammo
			set_pev(napalm_weaponent, PEV_NAPALM_AMMO, ++napalm_ammo)
			
			// Increase player's backpack ammo
			set_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1], get_pdata_int(id, AFFECTED_BPAMMO_OFFSETS[g_affect-1]) + 1, OFFSET_LINUX)
			
			// Flash ammo in hud
			message_begin(MSG_ONE_UNRELIABLE, g_msgAmmoPickup, _, id)
			write_byte(AFFECTED_AMMOID[g_affect-1]) // ammo id
			write_byte(1) // ammo amount
			message_end()
			
			// Play clip purchase sound
			engfunc(EngFunc_EmitSound, id, CHAN_ITEM, sound_buyammo, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			// Set napalm flag on the weapon entity (bugfix)
			set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
		}
		else
		{
			client_print(id, print_center, "You cannot carry any more napalms!")
			return PLUGIN_HANDLED;
		}
	}
	else
	{
		// Give napalm
		fm_give_item(id, AFFECTED_CLASSNAMES[g_affect-1])
		
		// Get napalm weapon entity now it exists
		napalm_weaponent = fm_get_napalm_entity(id, g_affect)
		
		// Set napalm flag on the weapon entity
		set_pev(napalm_weaponent, PEV_NADE_TYPE, NADE_TYPE_NAPALM)
		
		// Set napalm ammo
		set_pev(napalm_weaponent, PEV_NAPALM_AMMO, 1)
	}
	
	// Calculate new money amount
	static newmoney
	newmoney = fm_get_user_money(id) - g_price
	
	// Update money offset
	fm_set_user_money(id, newmoney)
	
	// Update money on HUD
	message_begin(MSG_ONE, g_msgMoney, _, id)
	write_long(newmoney) // amount
	write_byte(1) // flash
	message_end()
	
	return PLUGIN_HANDLED;
}

// Napalm Grenade Explosion
napalm_explode(ent)
{
	// Get attacker and its team
	static attacker, attacker_team
	attacker = pev(ent, pev_owner)
	attacker_team = pev(ent, pev_team)
	
	// Get origin
	static Float:originF[3]
	pev(ent, pev_origin, originF)
	
	// Custom explosion effect
	create_blast2(originF)
	
	// Napalm explosion sound
	engfunc(EngFunc_EmitSound, ent, CHAN_WEAPON, grenade_fire[random_num(0, sizeof grenade_fire - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Collisions
	static victim
	victim = -1
	
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, originF, g_radius)) != 0)
	{
		// Only effect alive players
		if (!is_user_alive(victim))
			continue;
		
		// Check if myself is allowed
		if (!g_hitself && victim == attacker)
			continue;
		
		// Check if friendly fire is allowed
		if (!g_ff && victim != attacker && attacker_team == fm_get_user_team(victim))
			continue;
		
		// Heat icon
		message_begin(MSG_ONE_UNRELIABLE, g_msgDamage, _, victim)
		write_byte(0) // damage save
		write_byte(0) // damage take
		write_long(DMG_BURN) // damage type
		write_coord(0) // x
		write_coord(0) // y
		write_coord(0) // z
		message_end()
		
		// Our task params
		static params[2]
		params[0] = g_duration * 5 // duration
		params[1] = attacker // attacker
		
		// Set burning task on victim
		set_task(0.1, "burning_flame", victim+TASK_BURN, params, sizeof params)
	}
}

// Burning Task
public burning_flame(args[2], taskid)
{
	// Player died/disconnected
	if (!is_user_alive(ID_BURN))
		return;
	
	// Get player origin and flags
	static Float:originF[3], flags
	pev(ID_BURN, pev_origin, originF)
	flags = pev(ID_BURN, pev_flags)
	
	// In water or burning stopped
	if ((flags & FL_INWATER) || BURN_DURATION < 1)
	{
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		return;
	}
	
	// Randomly play burning sounds
	if (g_screamrate > 0 && random_num(1, g_screamrate) == 1)
		engfunc(EngFunc_EmitSound, ID_BURN, CHAN_VOICE, grenade_fire_player[random_num(0, sizeof grenade_fire_player - 1)], 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Fire slow down
	if (g_slowdown > 0.0 && (flags & FL_ONGROUND))
	{
		static Float:velocity[3]
		pev(ID_BURN, pev_velocity, velocity)
		xs_vec_mul_scalar(velocity, g_slowdown, velocity)
		set_pev(ID_BURN, pev_velocity, velocity)
	}
	
	// Get victim's health
	static health
	health = pev(ID_BURN, pev_health)
	
	// Take damage from the fire
	if (health - g_damage > 0)
		set_pev(ID_BURN, pev_health, float(health - g_damage))
	else if (g_cankill)
	{
		// Kill victim
		ExecuteHamB(Ham_Killed, ID_BURN, BURN_ATTACKER, 0)
		
		// Smoke sprite
		engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
		write_byte(TE_SMOKE) // TE id
		engfunc(EngFunc_WriteCoord, originF[0]) // x
		engfunc(EngFunc_WriteCoord, originF[1]) // y
		engfunc(EngFunc_WriteCoord, originF[2]-50.0) // z
		write_short(g_smokeSpr) // sprite
		write_byte(random_num(15, 20)) // scale
		write_byte(random_num(10, 20)) // framerate
		message_end()
		
		return;
	}
	
	// Flame sprite
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_SPRITE) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]+random_float(-5.0, 5.0)) // x
	engfunc(EngFunc_WriteCoord, originF[1]+random_float(-5.0, 5.0)) // y
	engfunc(EngFunc_WriteCoord, originF[2]+random_float(-10.0, 10.0)) // z
	write_short(g_flameSpr) // sprite
	write_byte(random_num(5, 10)) // scale
	write_byte(200) // brightness
	message_end()
	
	// Decrease task cycle count
	BURN_DURATION -= 1;
	
	// Keep sending flame messages
	set_task(0.2, "burning_flame", taskid, args, sizeof args)
}

// Napalm Grenade: Fire Blast (originally made by Avalanche in Frostnades)
create_blast2(const Float:originF[3])
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+385.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Medium ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+470.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(200) // red
	write_byte(200) // green
	write_byte(0) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
	
	// Largest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+555.0) // z axis
	write_short(g_exploSpr) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(60) // width
	write_byte(0) // noise
	write_byte(0) // red
	write_byte(200) // green
	write_byte(200) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()
}

// Register Ham Forwards for CZ bots
public register_ham_czbots(id)
{
	// Make sure it's a CZ bot and it's still connected
	if (g_hamczbots || !get_pcvar_num(cvar_botquota) || !is_user_connected(id))
		return;
	
	RegisterHamFromEntity(Ham_Touch, id, "fw_TouchPlayer")
	
	// Ham forwards for CZ bots succesfully registered
	g_hamczbots = true;
}

// Set entity's rendering type (from fakemeta_util)
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

// Give an item to a player (from fakemeta_util)
stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item));
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF);
	set_pev(ent, pev_origin, originF);
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN);
	dllfunc(DLLFunc_Spawn, ent);
	
	static save
	save = pev(ent, pev_solid);
	dllfunc(DLLFunc_Touch, ent, id);
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent);
}

// Find entity by its owner (from fakemeta_util)
stock fm_find_ent_by_owner(entity, const classname[], owner)
{
	while ((entity = engfunc(EngFunc_FindEntityByString, entity, "classname", classname)) && pev(entity, pev_owner) != owner) {}
	
	return entity;
}

// Finds napalm grenade weapon entity of a player
stock fm_get_napalm_entity(id, g_affect)
{
	return fm_find_ent_by_owner(-1, AFFECTED_CLASSNAMES[g_affect-1], id);
}

// Get User Current Weapon Entity
stock fm_get_user_current_weapon_ent(id)
{
	return get_pdata_cbase(id, OFFSET_ACTIVE_ITEM, OFFSET_LINUX);
}

// Get Weapon Entity's CSW_ ID
stock fm_get_weapon_ent_id(ent)
{
	return get_pdata_int(ent, OFFSET_WEAPONID, OFFSET_LINUX_WEAPONS);
}

// Get Weapon Entity's Owner
stock fm_get_weapon_ent_owner(ent)
{
	return get_pdata_cbase(ent, OFFSET_WEAPONOWNER, OFFSET_LINUX_WEAPONS);
}

// Get User Money
stock fm_get_user_money(id)
{
	return get_pdata_int(id, OFFSET_CSMONEY, OFFSET_LINUX);
}

// Set User Money
stock fm_set_user_money(id, amount)
{
	set_pdata_int(id, OFFSET_CSMONEY, amount, OFFSET_LINUX);
}

// Get User Team
stock fm_get_user_team(id)
{
	return get_pdata_int(id, OFFSET_CSTEAMS, OFFSET_LINUX);
}

// Returns whether user is in a buyzone
stock fm_get_user_buyzone(id)
{
	if (get_pdata_int(id, OFFSET_MAPZONE) & PLAYER_IN_BUYZONE)
		return 1;
	
	return 0;
}
