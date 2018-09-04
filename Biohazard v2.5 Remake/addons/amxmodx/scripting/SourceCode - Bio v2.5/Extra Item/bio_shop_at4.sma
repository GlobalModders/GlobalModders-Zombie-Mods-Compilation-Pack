#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <fun>
#include <hamsandwich>
#include <biohazard>
#include <bio_shop>

// Plugin info
new const PLUGIN[] = "[Bio] Item: AT4"
new const VERSION[] = "1.0"
new const AUTHOR[] = "NiHiLaNTh REDACTED CEP}I{"

// Weapon/Grenade models
new const P_MODEL[] = "models/biohazard/p_at4.mdl"
new const V_MODEL[] = "models/biohazard/v_at4.mdl"
new const W_MODEL[] = "models/biohazard/w_at4.mdl"
new const GRENADE_MODEL[] = "models/grenade.mdl"

// Fire sound
new const GRENADE_SHOOT[] = "weapons/at4-1.wav"

// Sprites
new const GRENADE_TRAIL[] = "sprites/laserbeam.spr"
new const GRENADE_EXPLOSION[] = "sprites/zerogxplode.spr"
new const GRENADE_SMOKE[] = "sprites/black_smoke3.spr"

// Cached sprite indexes
new sTrail, sExplo, sSmoke

// Bodyparts and blood
new mdl_gib_flesh, mdl_gib_head, mdl_gib_lung, mdl_gib_spine,
blood_drop, blood_spray

// Item ID
new g_m79

// Player variables
new g_hasM79[33] // whether player has M79
new g_FireM79[33] // player is shooting
new g_canShoot[33] // player can shoot
new Float:g_last_shot_time[33]
new grenade_count[33] // current grenade count
new g_restarted // whether game was restarted

// Message ID's
new g_msgScreenShake

// Customization(CHANGE HERE)
#define GRENADE_DAMAGE 	    700
#define GRENADE_RADIUS      300
#define LAUNCHER_COST	     12000

// Tasks
#define TASK_HUDAMMO	    1337
#define ID_HUDAMMO (taskid - TASK_HUDAMMO)

// Plugin precache
public plugin_precache()
{
	// Models
	precache_model(P_MODEL)
	precache_model(V_MODEL)
	precache_model(W_MODEL)
	precache_model(GRENADE_MODEL)
	
	// Sounds
	precache_sound(GRENADE_SHOOT)
	precache_sound("weapons/at4_clipin1.wav")
	precache_sound("weapons/at4_clipin2.wav")
	precache_sound("weapons/at4_clipin3.wav")
	precache_sound("weapons/at4_draw.wav")
	precache_sound("weapons/357_cock1.wav")
	
	// Sprites
	sTrail = precache_model(GRENADE_TRAIL)
	sExplo = precache_model(GRENADE_EXPLOSION)
	sSmoke = precache_model(GRENADE_SMOKE)
	
	// Bodyparts and blood
	blood_drop = precache_model("sprites/blood.spr")
	blood_spray = precache_model("sprites/bloodspray.spr")
	mdl_gib_flesh = precache_model("models/Fleshgibs.mdl")
	mdl_gib_head = precache_model("models/GIB_Skull.mdl")
	mdl_gib_lung = precache_model("models/GIB_Lung.mdl")
	mdl_gib_spine = precache_model("models/GIB_B_Bone.mdl")
}

// Plugin init
public plugin_init()
{
	// Register plugin
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_cvar("bh_at4_version", VERSION, FCVAR_SERVER)
	
	// Register new extra item
	g_m79 = bio_register_item("AT4", LAUNCHER_COST, "A Rocket Weapon", TEAM_HUMAN)
	
	// Events
	register_event("CurWeapon", "Event_CurrentWeapon", "be", "1=1")
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0");
	register_event("TextMsg", "Event_GameRestart", "a", "2=#Game_Commencing", "2=#Game_will_restart_in");
	
	// Forwards
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Killed, "player", "fw_PlayerKilled")
	RegisterHam(Ham_Item_Deploy, "weapon_xm1014", "fw_deploy_post", 1)
	
	register_clcmd("drop", "drop_weapon")
	
	register_forward(FM_Touch, "fw_Touch")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)
	
	// Messages
	g_msgScreenShake = get_user_msgid("ScreenShake")
}

// Client connected
public client_connect(id)
{
	// Reset all
	g_hasM79[id] = false
	g_canShoot[id] = false
	g_last_shot_time[id] = 0.0
	grenade_count[id] = 0
}

public fw_deploy_post(ent)
{
	new id = pev(ent, pev_owner)
	
	if((1 < id < 32) && g_hasM79[id])
	{
		set_pev(id, pev_weaponanim, 2)
	}
}

// Extra item selected
public bio_item_selected(id, itemid)
{
	// Our item
	if (itemid == g_m79)
	{
		// Already has our weapon
		if (g_hasM79[id] || user_has_weapon(id, CSW_XM1014))
		{
			client_print(id, print_center, "Already have Launcher/Shotgun")
			
			// Set player's ammo packs back
			cs_set_user_money(id, cs_get_user_money(id) + LAUNCHER_COST)
		}
		else
		{
			Color(id, "!g[Bio]!y You have !t10!y Grenades !!!")
			
			give_item(id, "weapon_xm1014")
			static ent
			ent = fm_get_user_weapon_entity(id, CSW_XM1014)
			cs_set_weapon_ammo(ent, 0)
			
			// Reset
			g_hasM79[id] = true
			g_canShoot[id] = true
			g_last_shot_time[id] = 0.0
			grenade_count[id] = 10
			
			// Initialize HUD
			set_task(0.1, "hud_init", id+TASK_HUDAMMO, _, _, "b")
		}
	}
}

public drop_weapon(id)
{
	if(get_user_weapon(id) == CSW_XM1014 && g_hasM79[id])
	{
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
		write_byte(0)
		write_string("")
		message_end()
	}
}

// User has been injected
public event_infect(id, infector)
{
	if (g_hasM79[id])
	{
		// Reset all
		g_hasM79[id] = false
		g_canShoot[id] = false
		g_FireM79[id] = false
		g_last_shot_time[id] = 0.0
		grenade_count[id] = 0
		
		// Remove HUD
		remove_task(id+TASK_HUDAMMO)
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
		write_byte(0)
		write_string("")
		message_end()		
	}
}

// Current weapon player is holding
public Event_CurrentWeapon(id)
{
	// Ignore zombie/Nemesis
	if (is_user_zombie(id) || is_user_boss(id))
		return
	
	// Read weapon ID
	new weaponID = read_data(2)
	
	if (weaponID == CSW_XM1014)
	{
		if (g_hasM79[id])
		{
			// Initialize HUD
			set_task(0.1, "hud_init", id+TASK_HUDAMMO, _, _, "b")
			
			set_pev(id, pev_weaponanim, 2)
			// View model
			set_pev(id, pev_viewmodel2, V_MODEL)
			
			// Player model
			set_pev(id, pev_weaponmodel2, P_MODEL)
		}
		//Simple shotgun
		else
		{
			if(task_exists(id+TASK_HUDAMMO))
			{
				message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
				write_byte(0)
				write_string("")
				message_end()	
				
				remove_task(id+TASK_HUDAMMO)
			}
			
			
			
			// View model
			set_pev(id, pev_viewmodel2, "models/v_xm1014.mdl")
			
			// Player model
			set_pev(id, pev_weaponmodel2, "models/p_xm1014.mdl")
		}
	}
}

// New round started
public Event_NewRound(id)
{
	if (g_restarted)
	{
		// Strip from M79 if game have been restarted
		for (new i = 0; i < get_maxplayers(); i++)
		{
			g_hasM79[i] = false
		}
		g_restarted = false
	}
}

// Restart
public Event_GameRestart()
{
	g_restarted = true
}
		
// Set model		
public fw_SetModel(ent, const model[])
{
	// Invalid entity
	if (!pev_valid(ent))	
		return FMRES_IGNORED
	
	// Not needed model
	if(!equali(model, "models/w_xm1014.mdl")) 
		return FMRES_IGNORED
	
	// Get owner and classname
	new owner = pev(ent, pev_owner)
	new classname[33]; pev(ent, pev_classname, classname, charsmax(classname))
	
	// Entity classname is a weaponbox
	if(equal(classname, "weaponbox"))
	{
		// The weapon owner has a M79
		if(g_hasM79[owner])
		{
			// Strip from m79
			g_hasM79[owner] = false
			
			// Set world model
			engfunc(EngFunc_SetModel, ent, W_MODEL)
			
			// Touch fix
			set_task(0.1, "touch_fix", owner)
			
			// Remove HUD
			remove_task(owner+TASK_HUDAMMO)
			
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED

}

// Player killed
public fw_PlayerKilled(victim, attacker, shouldgib)
{
	if (g_hasM79[victim])		
	{
		// Reset all
		g_hasM79[victim] = false
		g_canShoot[victim] = false
		g_FireM79[victim] = false
		grenade_count[victim] = 0
		
		// Remove HUD
		remove_task(victim+TASK_HUDAMMO)
	}
}

public fw_Touch(ent, toucher)
{
	// Invalid ent/toucher
	if(!pev_valid(ent) || !pev_valid(toucher))
		return FMRES_IGNORED;
	
	// Get model, toucherclass, entityclass
	new model[33], toucherclass[33], entityclass[33]
	pev(ent, pev_model, model, charsmax(model))
	pev(ent, pev_classname, entityclass, charsmax(entityclass))
	pev(toucher, pev_classname, toucherclass, charsmax(toucherclass))
	
	// TOucher isn't player and entity isn't weapon
	if (!equali(toucherclass, "player") || !equali(entityclass, "weaponbox"))
		return FMRES_IGNORED
	
	// Our world model
	if(equali(model, W_MODEL))
	{
		// If not a zombie
		if(allowed_toucher(toucher))
		{
			// Pick up weapon
			g_hasM79[toucher] = true
			g_canShoot[toucher] = true
			g_FireM79[toucher] = false
		}
	}
	
	return FMRES_IGNORED;
}

// Command start
public fw_CmdStart(id, uc_handle, seed) 
{
	// Ignore dead
	if (!is_user_alive(id))
		return FMRES_IGNORED
		
	// Ignore zombies	
	if (is_user_zombie(id) || is_user_boss(id))
		return FMRES_IGNORED
		
	// Don't have our weapon	
	if (!g_hasM79[id])
		return FMRES_IGNORED
		
	// Get ammo, clip, weapon	
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	
	// Not replaced weapon
	if (weapon != 5)
		return FMRES_IGNORED
		
	// Get buttons	
	new buttons = get_uc(uc_handle, UC_Buttons)
	
	// Attack1 button pressed
	if(buttons & IN_ATTACK)
	{
		g_FireM79[id] = true
	
		// Remove attack button from their button mask
		buttons &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, buttons)
	}
	else 
		g_FireM79[id] = false	
		
	return FMRES_HANDLED
}

// Player think after
public fw_PlayerPostThink(id)
{
	// ignore dead
	if (!is_user_alive(id))
		return FMRES_IGNORED
		
	// Ignore zombies/nemesis	
	if (is_user_zombie(id) || is_user_boss(id))
		return FMRES_IGNORED
		
	// Don't have our weapon	
	if (!g_hasM79[id])
		return FMRES_IGNORED
		
	// Get ammo, clip, and weapon	
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	
	// Not our replaced weapon
	if (weapon != 5)
		return FMRES_IGNORED
		
	// If player is firing	
	if (g_FireM79[id])
	{
		// Grenades are more or equal to 1
		if (grenade_count[id] >= 1)
		{
			// Player can shoot
			if (get_gametime() - g_last_shot_time[id] > 4.0)
			{
				message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, id)
				write_byte(7)
				write_byte(pev(id, pev_body))
				message_end()
				
				// Fire!!!
				FireGrenade(id)
				
				// Decrease nade count
				grenade_count[id]--
				
				// Without this HUD is not updating correctly
				set_task(0.1, "hud_init", id+TASK_HUDAMMO)
				
				// Remember last shot time
				g_last_shot_time[id] = get_gametime()
			}
		}
		else
		{
			// Don't have nades
			client_print(id, print_center, "Out of grenades!")
		}
	}
	
	return FMRES_IGNORED
}

// Update client data
public fw_UpdateClientData_Post(id, sendweapons, cd_handle) 
{
	// Dead
	if (!is_user_alive(id))
		return FMRES_IGNORED
		
	// A zombie/nemesis	
	if (is_user_zombie(id) || is_user_boss(id))
		return FMRES_IGNORED
		
	// Don't have our weapon	
	if (!g_hasM79[id])
		return FMRES_IGNORED
	
	// Get ammo, clip, weapon
	new ammo, clip, weapon = get_user_weapon(id, clip, ammo)
	
	// Not replaced weapon
	if (weapon != 5)
		return FMRES_IGNORED
		
	// Block default sounds	
	set_cd(cd_handle, CD_ID, 0)
	return FMRES_HANDLED
}

// Fire gremade
public FireGrenade(id)
{
	// Get origin. angle and velocity
	new Float:fOrigin[3], Float:fAngle[3], Float:fVelocity[3]
	pev(id, pev_origin, fOrigin)
	pev(id, pev_v_angle, fAngle)
	
	// Create ent
	new grenade = create_entity("info_target")
	
	// Not grenade
	if (!grenade) return PLUGIN_HANDLED
	
	// Classname
	entity_set_string(grenade, EV_SZ_classname, "m79_grenade")
	
	// Model
	entity_set_model(grenade, GRENADE_MODEL)
	
	// Origin
	entity_set_origin(grenade, fOrigin)
	
	// Angles
	entity_set_vector(grenade, EV_VEC_angles, fAngle)
	
	// Size
	new Float:MinBox[3] = {-1.0, -1.0, -1.0}
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	entity_set_vector(grenade, EV_VEC_mins, MinBox)
	entity_set_vector(grenade, EV_VEC_maxs, MaxBox)
	
	// Interaction
	entity_set_int(grenade, EV_INT_solid, SOLID_SLIDEBOX)
	
	// Movetype
	entity_set_int(grenade, EV_INT_movetype, MOVETYPE_TOSS)
	
	// Owner
	entity_set_edict(grenade, EV_ENT_owner, id)
	
	// Effects
	entity_set_int(grenade, EV_INT_effects, EF_BRIGHTLIGHT)
	
	// Velocity
	VelocityByAim(id, 1500, fVelocity)
	entity_set_vector(grenade, EV_VEC_velocity, fVelocity)
	
	// Launch sound
	emit_sound(grenade, CHAN_WEAPON, GRENADE_SHOOT, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
	
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMFOLLOW) // Temporary entity ID
	write_short(grenade) // Entity
	write_short(sTrail) // Sprite index
	write_byte(10) // Life
	write_byte(3) // Line width
	write_byte(255) // Red
	write_byte(255) // Green
	write_byte(255) // Blue
	write_byte(255) // Alpha
	message_end() 
	
	return PLUGIN_CONTINUE
}	

// We hit something!!!
public pfn_touch(ptr, ptd)
{
	// If ent is valid
	if (pev_valid(ptr))
	{	
		// Get classnames
		static classname[32], classnameptd[32]
		pev(ptr, pev_classname, classname, 31)
		pev(ptd, pev_classname, classnameptd, 31)
		
		// Our ent
		if(equal(classname, "m79_grenade"))
		{
			// Get it's origin
			new Float:originF[3]
			pev(ptr, pev_origin, originF)
			
			// Draw explosion
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_EXPLOSION) // Temporary entity ID
			engfunc(EngFunc_WriteCoord, originF[0]) // engfunc because float
			engfunc(EngFunc_WriteCoord, originF[1])
			engfunc(EngFunc_WriteCoord, originF[2])
			write_short(sExplo) // Sprite index
			write_byte(50) // Scale
			write_byte(15) // Framerate
			write_byte(0) // Flags
			message_end()
			
			// Draw smoke
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_SMOKE) // Temporary entity IF
			engfunc(EngFunc_WriteCoord, originF[0]) // Pos X
			engfunc(EngFunc_WriteCoord, originF[1]) // Pos Y
			engfunc(EngFunc_WriteCoord, originF[2]) // Pos Z
			write_short(sSmoke) // Sprite index
			write_byte(75) // Scale
			write_byte(15) // Framerate
			message_end()
			
			// Get owner
			new owner = pev(ptr, pev_owner)
			
			// Loop through all players
			for(new i = 0; i < get_maxplayers(); i++)
			{
				// Alive...
				if (is_user_alive(i) == 1)
				{
					// Start screen shake
					message_begin(MSG_ONE, g_msgScreenShake, {0,0,0}, i)
					write_short(1<<14) // Amount
					write_short(1<<14) // Duration
					write_short(1<<14) // Frequency
					message_end()
					
					// A zombie/nemesis
					if (is_user_zombie(i) || is_user_boss(i))
					{
						// Get victims origin and distance
						new Float:VictimOrigin[3], Float:distance
						pev(i, pev_origin, VictimOrigin)
						
						// Get distance between victim and epicenter
						distance = get_distance_f(VictimOrigin, originF)
						
						if (distance <= GRENADE_RADIUS)
						{
							// Get victims health
							new health = get_user_health(i)
							
							// Still alive
							if (health - GRENADE_DAMAGE >= 1)
							{
								// Set health
								set_user_health(i, health - GRENADE_DAMAGE)
							}
							else
							{
								// Silently kill victim
								user_silentkill(i)
							
								// Make death message
								make_deathmsg(owner, i, 0, "grenade")
								
								// Bloody parts
								create_blood(VictimOrigin)
								
								// Set frags
								set_user_frags(owner, get_user_frags(owner) + 1)
								
								// Set deaths
								cs_set_user_deaths(i, cs_get_user_deaths(i) + 1)
								
								// Set ammo packs
								cs_set_user_money(owner, cs_get_user_money(owner) + 500)
							}
						}
					}
				}
				// Destroy ent
				set_pev(ptr, pev_flags, FL_KILLME)
			}
			// We hit breakable
			if (equali(classnameptd, "func_breakable"))
			{
				// Destroy it
				force_use(ptr,ptd)
			}
		}
	}	
}	
	
// HUD init	
public hud_init(taskid)
{
	new id = taskid - TASK_HUDAMMO
	
	static Message[32]
	formatex(Message, sizeof(Message), "Rocket Ammo: %i", grenade_count[id])
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
	write_byte(0)
	write_string(Message)
	message_end()
}

// Touch fix
public touch_fix(id)
{
	if (g_hasM79[id])
		g_hasM79[id] = false
}

// Allowed toucher
stock allowed_toucher(player)
{
	// Zombie/Nemesis/Already has it
	if (is_user_zombie(player) || is_user_boss(player) || g_hasM79[player])
		return false
	
	return true
}

// Blood and bodyparts
stock create_blood(const Float:origin[3])
{
	// Head
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_coord(random_num(-100,100))
	write_coord(random_num(-100,100))
	write_coord(random_num(100,200))
	write_angle(random_num(0,360))
	write_short(mdl_gib_head) // Sprite index
	write_byte(0) // bounce
	write_byte(500) // life
	message_end()
	
	// Spine
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(TE_MODEL)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_coord(random_num(-100,100))
	write_coord(random_num(-100,100))
	write_coord(random_num(100,200))
	write_angle(random_num(0,360))
	write_short(mdl_gib_spine)
	write_byte(0) // bounce
	write_byte(500) // life
	message_end()
	
	// Lung
	for(new i = 0; i < random_num(1,2); i++) 
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		write_coord(random_num(-100,100))
		write_coord(random_num(-100,100))
		write_coord(random_num(100,200))
		write_angle(random_num(0,360))
		write_short(mdl_gib_lung)
		write_byte(0) // bounce
		write_byte(500) // life
		message_end()
	}
	
	// Parts, 10 times
	for(new i = 0; i < 10; i++) 
	{
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
		write_byte(TE_MODEL)
		engfunc(EngFunc_WriteCoord, origin[0])
		engfunc(EngFunc_WriteCoord, origin[1])
		engfunc(EngFunc_WriteCoord, origin[2])
		write_coord(random_num(-100,100))
		write_coord(random_num(-100,100))
		write_coord(random_num(100,200))
		write_angle(random_num(0,360))
		write_short(mdl_gib_flesh)
		write_byte(0) // bounce
		write_byte(500) // life
		message_end()
	}
	
	// Blood
	for(new i = 0; i < 3; i++) 
	{
		new x,y,z
		x = random_num(-100,100)
		y = random_num(-100,100)
		z = random_num(0,100)
		for(new j = 0; j < 3; j++)
		{
			message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
			write_byte(TE_BLOODSPRITE)
			engfunc(EngFunc_WriteCoord, origin[0]+(x*j))
			engfunc(EngFunc_WriteCoord, origin[1]+(y*j))
			engfunc(EngFunc_WriteCoord, origin[2]+(z*j))
			write_short(blood_spray)
			write_short(blood_drop)
			write_byte(229) // color index
			write_byte(15) // size
			message_end()
		}
	}
}

stock Color(const id, const input[], any:...)
{
	static msg[191]
	vformat(msg, 190, input, 3)
	
	replace_all(msg, 190, "!g", "^4")
	replace_all(msg, 190, "!y", "^1")
	replace_all(msg, 190, "!t", "^3")
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, id)
	write_byte(id)
	write_string(msg)
	message_end()
}
	
	
