#include <amxmodx>
#include <biohazard>
#include <hamsandwich>
#include <fakemeta_util>
#include <cstrike>

#define D_ZOMBIE_NAME "Fleshpound Zombie"
#define D_ZOMBIE_DESC "[G] -> Nem Thit"
#define D_PLAYER_MODEL "models/player/flesher/flesher.mdl"
#define D_CLAWS "models/biohazard/v_knife_flesh.mdl"

#define CLASS_FLESH	"flesh throw"

new const g_sound_pain[][] =
{
	"aslave/slv_pain1.wav",
	"aslave/slv_pain2.wav", 
	"headcrab/hc_pain1.wav",
	"headcrab/hc_pain2.wav",
	"headcrab/hc_pain3.wav",
	"zombie/zo_pain1.wav",
	"zombie/zo_pain2.wav"
}

new const ZOMBIE_FLESH[][] =
{
	"models/abone_template1.mdl",
	"models/bonegibs.mdl",
	"models/fleshgibs.mdl",
	"models/gib_b_bone.mdl",
	"models/gib_b_gib.mdl",
	"models/gib_legbone.mdl",
	"models/gib_lung.mdl"
}	

new g_class
new cvar_fleshthrow,cvar_fforce, cvar_fleshdmg, cvar_fselfdmg
new Float: g_LastFthrow[33]
	
public plugin_init() 
{         
	register_plugin("[Bio] Class: Fleshpound","1.2b","bipbip")
	is_biomod_active() ? plugin_init2() : pause("ad")
}
public plugin_precache() 
{
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	
	new iNum
	for (iNum = 0; iNum < sizeof g_sound_pain; iNum++)
		engfunc(EngFunc_PrecacheSound, g_sound_pain[iNum])
	for (iNum = 0; iNum < sizeof ZOMBIE_FLESH; iNum++)
		engfunc(EngFunc_PrecacheModel, ZOMBIE_FLESH[iNum])
}

public plugin_init2() 
{
	g_class = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)
	
	if(g_class != -1)
	{
		set_class_data(g_class, DATA_HEALTH, 2500.0)
		set_class_data(g_class, DATA_SPEED, 275.0)
		set_class_data(g_class, DATA_GRAVITY, 1.0)
		set_class_data(g_class, DATA_ATTACK, 1.0)
		set_class_data(g_class, DATA_HITDELAY, 1.0)
		set_class_data(g_class, DATA_HITREGENDLY, 999.0)
		set_class_data(g_class, DATA_DEFENCE, 0.85)
		set_class_data(g_class, DATA_HEDEFENCE, 1.0)
		set_class_data(g_class, DATA_KNOCKBACK, 1.5)
		set_class_data(g_class, DATA_MODELINDEX, 1.0)		
		set_class_pmodel(g_class, D_PLAYER_MODEL)
		set_class_wmodel(g_class, D_CLAWS)
	}
	
	register_clcmd("drop", "do_skill")
	
	cvar_fleshthrow	= register_cvar("bio_fleshthrow", "1")
	cvar_fforce = register_cvar("bio_fforce", "1700")
	cvar_fleshdmg =	register_cvar("bio_fleshdmg", "35")
	cvar_fselfdmg = register_cvar("bio_fselfdmg", "100")
	
	register_forward(FM_Touch,"fw_Touch")
	register_forward(FM_PlayerPreThink,"fw_PlayerPreThink", 1)
}


public event_infect(victim, attacker) 
{
	if (is_user_zombie(victim) && get_user_class(victim) == g_class)
	{
		//client_print(victim, print_center, D_ZOMBIE_DESC)
		
		if(is_user_bot(victim))
			set_task(random_float(5.0, 10.0), "do_skill", victim, _, _, "b")
	}
}

public do_skill(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_class)
		cmd_throw(id)
}

public clcmd_throw(id)
{
	static Float: Origin[3], Float: Velocity[3], Float: Angle[3], MinBox[3], MaxBox[3]
	pev(id, pev_origin, Origin)
	pev(id, pev_velocity, Velocity)
	pev(id, pev_angles, Angle)
	static Health, Float: damage
	Health = get_user_health(id)
	damage = get_pcvar_float(cvar_fselfdmg)
	
	if (Health > damage)
	{
		static ent ; ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))
		
		set_pev(ent, pev_classname, CLASS_FLESH)
		engfunc(EngFunc_SetModel, ent, ZOMBIE_FLESH[random(sizeof ZOMBIE_FLESH)])
		Angle[0] = random_float(0.0, 360.0)
		Angle[1] = random_float(0.0, 360.0)
		MinBox = { -1.0, -1.0, -1.0 }
		MaxBox = { 1.0, 1.0, 1.0 }
		
		set_pev(ent, pev_angles, Angle)
		engfunc(EngFunc_SetSize, ent, MinBox, MaxBox)
		engfunc(EngFunc_SetOrigin, ent, Origin)
		set_pev(ent, pev_movetype, MOVETYPE_TOSS)
		set_pev(ent, pev_solid, SOLID_TRIGGER)
		set_pev(ent, pev_owner, id)
		
		velocity_by_aim(id, get_pcvar_num(cvar_fforce), Velocity)
		set_pev(ent, pev_velocity, Velocity)
		
		emit_sound(id, CHAN_VOICE, g_sound_pain[random(sizeof g_sound_pain)], VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		set_pev(id, pev_health, Health - damage)
	}
	else
	{
		color_saytext(id, "^x04[Bio]^x01 You don't have enough Meat to^x03 Throw")
	}
}
public fw_Touch(pToucher, pTouched)
{
	if ( pev_valid(pToucher))
	{
		static className[32], className2[32]
		pev(pToucher, pev_classname, className, 31)
		if ( pev_valid(pTouched)) pev(pTouched, pev_classname, className2, 31)
		
		if ( equal(className, CLASS_FLESH))
		{
			static attacker ; attacker = pev(pToucher, pev_owner)
			
			if ( pev_valid(pTouched))
			{
				if ( equal(className2, "player") && is_user_connected(pTouched))
				{
					static origin[3], Float: damage
					get_user_origin(pTouched, origin)
					damage = get_pcvar_float(cvar_fleshdmg)
					static CsTeams:team[2]
					team[0] = cs_get_user_team(pTouched), team[1] = cs_get_user_team(attacker)
					
					if (attacker == pTouched)
						return FMRES_SUPERCEDE
					
					if (!get_cvar_num("mp_friendlyfire") && team[0] == team[1]) 
						return FMRES_SUPERCEDE
					
					message_begin(MSG_BROADCAST, SVC_TEMPENTITY);
					write_byte(TE_BLOOD);
					write_coord(origin[0]);
					write_coord(origin[1]);
					write_coord(origin[2] + 10);
					write_coord(random_num(-360, 360));
					write_coord(random_num(-360, 360));
					write_coord(-10);
					write_byte(70);
					write_byte(random_num(15, 35));
					message_end() 
					ExecuteHam(Ham_TakeDamage, pTouched, pToucher, attacker, damage, DMG_GENERIC)
				}
				else if ( equal(className2, "func_breakable")) dllfunc(DLLFunc_Use, pTouched, attacker)		
					else if ( equal(className2, CLASS_FLESH)) return FMRES_SUPERCEDE	
				}		
			engfunc(EngFunc_RemoveEntity, pToucher)
		}
	}
	
	return FMRES_IGNORED
}  
public cmd_throw(id)
{
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
	
	static Float: Time
	Time = get_gametime()
	
	if (is_user_zombie(id) && get_user_class(id) == g_class )
	{
		if (get_pcvar_num(cvar_fleshthrow))
		{
			if(Time - 1.1 > g_LastFthrow[id])
			{
				clcmd_throw(id)
				g_LastFthrow[id] = Time
			}
		}
	}	
	return PLUGIN_HANDLED
}	

color_saytext(player, const message[], any:...)
{
	new text[301]
	format(text, 300, "%s", message)

	new dest
	if (player) dest = MSG_ONE
	else dest = MSG_ALL
	
	message_begin(dest, get_user_msgid("SayText"), {0,0,0}, player)
	write_byte(1)
	write_string(check_text(text))
	return message_end()
}

check_text(text1[])
{
	new text[301]
	format(text, 300, "%s", text1)
	replace(text, 300, "/g", "^x04")
	replace(text, 300, "/r", "^x03")
	replace(text, 300, "/y", "^x01")
	return text
}
