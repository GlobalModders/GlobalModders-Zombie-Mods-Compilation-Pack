#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <xs>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Melee: Balrog-9"
#define VERSION "1.0"
#define AUTHOR "Dias"

// ================ Weapon Config ======================
// =====================================================
// Draw Time
#define DRAW_TIME 1.0

// Next Attack Time
#define NEXTATTACK_MISS 0.5
#define NEXTATTACK_HIT 0.3

// Attack Distance
#define ATTACKDIS_SLASH 58.0
#define ATTACKDIS_CHARGE 68.0

// Attack Damage
#define DAMAGE_SLASH 200.0
#define DAMAGE_CHARGE 400.0

// Charge Mode
#define CHARGE_STARTTIME 0.75
#define CHARGE_ATTACKTIME 0.75
#define CHARGE_TIME 2.0
#define CHARGE_NEXTATTACK 1.0
#define CHARGE_EXPRADIUS 120

#define CHARGE_ATTACK_KNOCKPOWER 1000.0

// Task
#define TASK_CHARGE_STARTING 75675
#define TASK_CHARGING 464334

new const v_model[] = "models/zombie_thehero/weapon/melee/v_balrog9.mdl"
new const p_model[] = "models/zombie_thehero/weapon/melee/p_balrog9.mdl"
new const exp_spr[] = "sprites/balrog5stack.spr"

new const weapon_sound[9][] =
{
	"weapons/balrog9_draw.wav",
	"weapons/balrog9_slash1.wav",
	"weapons/balrog9_slash2.wav",
	"weapons/balrog9_hitwall.wav",
	"weapons/balrog9_hit1.wav",
	"weapons/balrog9_hit2.wav",
	"weapons/balrog9_charge_start1.wav",
	"weapons/balrog9_charge_finish1.wav",
	"weapons/balrog9_charge_attack2.wav"
}

enum
{
	B9_DRAW = 0,
	B9_SLASH1,
	B9_SLASH2,
	B9_HITWALL,
	B9_HIT1,
	B9_HIT2,
	B9_CHARGE_START,
	B9_CHARGE_FINISH,
	B9_CHARGE_ATTACK
}

new g_balrog9, g_bot, g_exp_sprid
new g_had_balrog9[33], g_attack_mode[33], g_charging[33], g_charged[33], g_chargeattack[33]
new g_OldWeapon[33]

enum
{
	MODE_NORMAL = 1,
	MODE_CHARGE
}

enum
{
	KNIFE_ANIM_IDLE = 0,
	KNIFE_ANIM_SLASH1,
	KNIFE_ANIM_SLASH2,
	KNIFE_ANIM_DRAW,
	KNIFE_ANIM_STAB_HIT,
	KNIFE_ANIM_STAB_MISS,
	KNIFE_ANIM_MIDSLASH1,
	KNIFE_ANIM_MIDSLASH2
}

enum
{
	BALROG9_ANIM_IDLE = 0,
	BALROG9_ANIM_SLASH1,
	BALROG9_ANIM_SLASH2,
	BALROG9_ANIM_SLASH3,
	BALROG9_ANIM_SLASH4,
	BALROG9_ANIM_SLASH5,
	BALROG9_ANIM_DRAW,
	BALROG9_ANIM_CHARGE_START,
	BALROG9_ANIM_CHARGE_FINISH,
	BALROG9_ANIM_CHARGE_IDLE1,
	BALROG9_ANIM_CHARGE_IDLE2,
	BALROG9_ANIM_CHARGE_ATTACK1,
	BALROG9_ANIM_CHARGE_ATTACK2
}

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_EmitSound, "fw_EmitSound")
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_TraceLine, "fw_TraceLine")
	register_forward(FM_TraceHull, "fw_TraceHull")		
	
	RegisterHam(Ham_CS_Weapon_SendWeaponAnim, "weapon_knife", "fw_Knife_SendAnim", 1)
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, v_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	
	for(new i = 0; i < sizeof(weapon_sound); i++)
		engfunc(EngFunc_PrecacheSound, weapon_sound[i])
		
	g_exp_sprid = engfunc(EngFunc_PrecacheModel, exp_spr)
	g_balrog9 = zbheroex_register_weapon("Balrog-IX", WEAPON_MELEE, CSW_KNIFE, 0)
}

public zbheroex_weapon_bought(id, WeaponID)
{
	if(WeaponID == g_balrog9) get_balrog9(id)
}

public zbheroex_weapon_remove(id, WeaponID)
{
	if(WeaponID == g_balrog9) remove_balrog9(id)
}

public get_balrog9(id)
{
	g_had_balrog9[id] = 1
	g_attack_mode[id] = 0
	g_charged[id] = 0
	g_charging[id] = 0
	g_chargeattack[id] = 0
	
	if(get_user_weapon(id) == CSW_KNIFE) 
	{
		Event_CurWeapon(id)
		set_weapon_anim(id, BALROG9_ANIM_DRAW)
	}
	
	engclient_cmd(id, "weapon_knife")
}

public remove_balrog9(id)
{
	g_had_balrog9[id] = 0
	g_attack_mode[id] = 0
	g_charged[id] = 0
	g_charging[id] = 0	
	g_chargeattack[id] = 0
	
	remove_task(id+TASK_CHARGE_STARTING)
	remove_task(id+TASK_CHARGING)
}

public client_putinserver(id)
{
	if(is_user_bot(id) && !g_bot)
	{
		g_bot = 1
		set_task(0.1, "Do_RegisterHamBot", id)
	}
}

public Do_RegisterHamBot(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Post", 1)
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return 1
	
	if(g_had_balrog9[id] && (read_data(2) == CSW_KNIFE && g_OldWeapon[id] != CSW_KNIFE))
	{
		set_pev(id, pev_viewmodel2, v_model)
		set_pev(id, pev_weaponmodel2, p_model)
	}
	
	g_OldWeapon[id] = read_data(2)
		
	return 0
}

public fw_Knife_SendAnim(ent, anim, skip_local)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
		
	static id; id = get_pdata_cbase(ent, 41 , 4)
	
	if(!g_had_balrog9[id])
		return HAM_IGNORED
	
	static Float:PunchAngles[3]
	
	if(anim == KNIFE_ANIM_DRAW)
	{
		set_weapons_timeidle(id, DRAW_TIME)
		set_player_nextattack(id, DRAW_TIME)	
		
		set_weapon_anim(id, BALROG9_ANIM_DRAW)
		Remove_OldStuff(id)
	} else if(anim == KNIFE_ANIM_MIDSLASH1) {
		PunchAngles[0] = random_float(-1.0, -2.0)
		PunchAngles[1] = random_float(0.5, 1.5)
		PunchAngles[2] = 0.0
		
		set_pev(id, pev_punchangle, PunchAngles)
		set_weapon_anim(id, BALROG9_ANIM_SLASH1)
		Remove_OldStuff(id)
	} else if(anim == KNIFE_ANIM_MIDSLASH2) {
		PunchAngles[0] = random_float(-1.0, -2.0)
		PunchAngles[1] = random_float(-0.5, -1.5)
		PunchAngles[2] = 0.0
		
		set_pev(id, pev_punchangle, PunchAngles)
		set_weapon_anim(id, BALROG9_ANIM_SLASH2)
		Remove_OldStuff(id)
	} else if(anim == KNIFE_ANIM_STAB_HIT) {
		PunchAngles[0] = random_float(-0.5, 0.5)
		PunchAngles[1] = random_float(-0.5, -1.0)
		PunchAngles[2] = 0.0
		
		set_pev(id, pev_punchangle, PunchAngles)
		
		if(g_chargeattack[id] == 2) 
		{
			set_weapon_anim(id, BALROG9_ANIM_CHARGE_ATTACK2)
			set_task(0.1, "Effect_ChargedAttack", id)
		} else set_weapon_anim(id, BALROG9_ANIM_CHARGE_ATTACK1)
	} else if(anim == KNIFE_ANIM_STAB_MISS) {
		PunchAngles[0] = random_float(-0.5, 0.5)
		PunchAngles[1] = random_float(-0.5, -1.0)
		PunchAngles[2] = 0.0
		
		if(g_chargeattack[id] == 2) 
		{
			set_weapon_anim(id, BALROG9_ANIM_CHARGE_ATTACK2)
			set_task(0.1, "Effect_ChargedAttack", id)
		} else set_weapon_anim(id, BALROG9_ANIM_CHARGE_ATTACK1)
	}

	return HAM_IGNORED
}

public Remove_OldStuff(id)
{
	g_charging[id] = 0
	g_charged[id] = 0
	g_chargeattack[id] = 0

	remove_task(id+TASK_CHARGE_STARTING)
	remove_task(id+TASK_CHARGING)	
}

public Effect_ChargedAttack(id)
{
	static Float:Origin[3]
	get_position(id, 48.0, 0.0, 0.0, Origin)
	
	// DLight
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(27)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_byte(20)
	write_byte(200)
	write_byte(0)
	write_byte(0)
	write_byte(10)
	write_byte(60)
	message_end()
	
	// Exp
	message_begin(MSG_BROADCAST ,SVC_TEMPENTITY)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(g_exp_sprid)	// sprite index
	write_byte(10)	// scale in 0.1's
	write_byte(30)	// framerate
	write_byte(4)	// flags
	message_end()
	
	// Check Attack Damage
	HamRadiusDamage(id, fm_get_user_weapon_entity(id, CSW_KNIFE), float(CHARGE_EXPRADIUS), DAMAGE_CHARGE, DMG_BURN)
}

stock HamRadiusDamage(id, ent, Float:radius, Float:damage, bits) 
{ 
	static target, Float:origin[3] 
	
	target = -1
	pev(ent, pev_origin, origin) 
     
	while((target = find_ent_in_sphere(target, origin, radius) )) 
	{ 
		static Float:o[3] 
		pev(target, pev_origin, o) 
         
		xs_vec_sub(origin, o, o) 
         
		// Recheck if the entity is in radius 
		if (xs_vec_len(o) > radius) 
			continue 
		
		if(is_user_alive(target))
		{
			if(id == target)
				continue
			if(!zbheroex_get_user_zombie(target))
				continue
		}
         
		Ham_ExecDamageB(target, ent, id, damage * (xs_vec_len(o) / radius), HIT_GENERIC, bits) 
	} 
}  

stock Ham_ExecDamageB(victim, inflictor, attacker, Float:damage, hitgroup, bits)
{
	static const Float:hitgroup_multi[] =
	{
		1.0,  // HIT_GENERIC
		4.0,  // HIT_HEAD
		1.0,  // HIT_CHEST
		1.25, // HIT_STOMACH
		1.0,  // HIT_LEFTARM
		1.0,  // HIT_RIGHTARM
		0.75, // HIT_LEFTLEG
		0.75,  // HIT_RIGHTLEG
		0.0   // HIT_SHIELD
	} 
	
	set_pdata_int(victim, 75, hitgroup, 5)
	ExecuteHamB(Ham_TakeDamage, victim, inflictor, attacker, damage * hitgroup_multi[hitgroup], bits)
} 

public fw_TraceAttack(ent, attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_KNIFE || !g_had_balrog9[attacker])
		return HAM_IGNORED
		
	if(g_attack_mode[attacker] == MODE_NORMAL) SetHamParamFloat(3, DAMAGE_SLASH)
	else if(g_attack_mode[attacker] == MODE_CHARGE) SetHamParamFloat(3, DAMAGE_CHARGE)
	
	return HAM_HANDLED
}

public fw_TraceAttack_Post(ent, attacker, Float:Damage, Float:Dir[3], ptr, DamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED
	if(get_user_weapon(attacker) != CSW_KNIFE || !g_had_balrog9[attacker])
		return HAM_IGNORED
	if(g_attack_mode[attacker] == MODE_CHARGE) 
	{
		if(g_chargeattack[attacker] == 2 && zbheroex_get_user_zombie(ent)) // Do KnockBack Here
		{
			static Float:Origin[3]
			pev(attacker, pev_origin, Origin)
			
			hook_ent2(ent, Origin, CHARGE_ATTACK_KNOCKPOWER, 2)
		}
	}
	
	return HAM_HANDLED
}

public fw_EmitSound(id, channel, const sample[], Float:volume, Float:attn, flags, pitch)
{
	if(!is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_KNIFE || !g_had_balrog9[id])
		return FMRES_IGNORED
		
	if(sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if(sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			set_weapons_timeidle(id, NEXTATTACK_MISS)
			set_player_nextattack(id, NEXTATTACK_MISS)
			
			if(g_attack_mode[id] == MODE_CHARGE)
			{
				if(g_chargeattack[id] == 2)
					emit_sound(id, channel, weapon_sound[B9_CHARGE_ATTACK], volume, attn, flags, pitch)
				else
					emit_sound(id, channel, weapon_sound[random_num(B9_SLASH1, B9_SLASH2)], volume, attn, flags, pitch)
			} else emit_sound(id, channel, weapon_sound[random_num(B9_SLASH1, B9_SLASH2)], volume, attn, flags, pitch)
			return FMRES_SUPERCEDE
		}
		if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't') // hit
		{
			if (sample[17] == 'w') // wall
			{
				set_weapons_timeidle(id, NEXTATTACK_HIT)
				set_player_nextattack(id, NEXTATTACK_HIT)	
				
				if(g_attack_mode[id] == MODE_CHARGE)
				{
					if(g_chargeattack[id] == 2)
						emit_sound(id, channel, weapon_sound[B9_CHARGE_ATTACK], volume, attn, flags, pitch)
					else
						emit_sound(id, channel, weapon_sound[B9_HITWALL], volume, attn, flags, pitch)
				} else emit_sound(id, channel, weapon_sound[B9_HITWALL], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			} else {
				set_weapons_timeidle(id, NEXTATTACK_HIT)
				set_player_nextattack(id, NEXTATTACK_HIT)
				
				if(g_attack_mode[id] == MODE_CHARGE)
				{
					if(g_chargeattack[id] == 2)
						emit_sound(id, channel, weapon_sound[B9_CHARGE_ATTACK], volume, attn, flags, pitch)
					else
						emit_sound(id, channel, weapon_sound[random_num(B9_HIT1, B9_HIT2)], volume, attn, flags, pitch)
				} else emit_sound(id, channel, weapon_sound[random_num(B9_HIT1, B9_HIT2)], volume, attn, flags, pitch)
				return FMRES_SUPERCEDE
			}
		}
		if(sample[14] == 's' && sample[15] == 't' && sample[16] == 'a') // stab
		{
			if(g_chargeattack[id] == 2)
				emit_sound(id, channel, weapon_sound[B9_CHARGE_ATTACK], volume, attn, flags, pitch)
			else
				emit_sound(id, channel, weapon_sound[random_num(B9_HIT1, B9_HIT2)], volume, attn, flags, pitch)
				
			return FMRES_SUPERCEDE
		}
	}
	
	return FMRES_IGNORED
}

public fw_CmdStart(id, uc_handle, seed)
{
	if (!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_balrog9[id])
		return
	
	static ent
	ent = find_ent_by_owner(-1, "weapon_knife", id)
	
	if(!pev_valid(ent))
		return
	
	static CurButton, OldButton
	
	CurButton = get_uc(uc_handle, UC_Buttons)
	OldButton = (pev(id, pev_oldbuttons) & IN_ATTACK2)
	
	if(CurButton & IN_ATTACK)
	{
		if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
			return
		
		g_attack_mode[id] = MODE_NORMAL
		set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
	} else {
		if(CurButton & IN_ATTACK2) 
		{
			set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK2)
			set_uc(uc_handle, UC_Buttons, CurButton & ~IN_ATTACK)
			
			if(OldButton) // Holding This Button
			{
				if(g_charging[id] == 2)
				{
					if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
						return
					
					if(g_charged[id])
					{
						set_weapons_timeidle(id, 99999.0)
						set_player_nextattack(id, 99999.0)
						
						if(pev(id, pev_weaponanim) != BALROG9_ANIM_CHARGE_IDLE2)
							set_weapon_anim(id, BALROG9_ANIM_CHARGE_IDLE2)
					} else {
						set_weapons_timeidle(id, 99999.5)
						set_player_nextattack(id, 9999.5)
						
						if(pev(id, pev_weaponanim) != BALROG9_ANIM_CHARGE_IDLE1)
							set_weapon_anim(id, BALROG9_ANIM_CHARGE_IDLE1)
					}
				}
			}		
			
			if(get_pdata_float(ent, 46, 4) > 0.0 || get_pdata_float(ent, 47, 4) > 0.0) 
				return
			
			remove_task(id+TASK_CHARGE_STARTING)
			remove_task(id+TASK_CHARGING)	
			
			g_attack_mode[id] = MODE_CHARGE
			g_charging[id] = 1
			g_charged[id] = 0
			g_chargeattack[id] = 1
			
			set_weapons_timeidle(id, CHARGE_STARTTIME + 0.25)
			set_player_nextattack(id, CHARGE_STARTTIME + 0.25)
		
			set_weapon_anim(id, BALROG9_ANIM_CHARGE_START)
			
			set_task(CHARGE_STARTTIME, "Do_HoldCharge", id+TASK_CHARGE_STARTING)
			set_task(CHARGE_TIME, "Do_SetCharge", id+TASK_CHARGING)
		} else {
			if(OldButton) // After Press this Button (no Hold)
			{
				if(g_charging[id] == 2)
				{
					if(g_chargeattack[id])
					{
						ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		
						set_weapons_timeidle(id, CHARGE_NEXTATTACK)
						set_player_nextattack(id, CHARGE_NEXTATTACK)
						
						g_charging[id] = 0
						g_charged[id] = 0
						g_chargeattack[id] = 0
						
						remove_task(id+TASK_CHARGE_STARTING)
						remove_task(id+TASK_CHARGING)
					}
				}
			}
		}
	}
}

public Do_SetCharge(id)
{
	id -= TASK_CHARGING
	
	if(!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_balrog9[id])
		return
		
	g_charging[id] = 2
	g_charged[id] = 1
	g_chargeattack[id] = 2
	
	set_weapons_timeidle(id, 0.25)
	set_player_nextattack(id, 0.25)
						
	set_weapon_anim(id, BALROG9_ANIM_CHARGE_FINISH)	
}

public Do_HoldCharge(id)
{
	id -= TASK_CHARGE_STARTING
	
	if(!is_user_alive(id)) 
		return
	if(get_user_weapon(id) != CSW_KNIFE)
		return
	if(!g_had_balrog9[id])
		return
		
	if(!(pev(id, pev_button) & IN_ATTACK2) && !(pev(id, pev_oldbuttons) & IN_ATTACK2))
	{
		static ent
		ent = find_ent_by_owner(-1, "weapon_knife", id)
	
		if(!pev_valid(ent))
			return		
			
		ExecuteHamB(Ham_Weapon_SecondaryAttack, ent)
		
		set_weapons_timeidle(id, CHARGE_NEXTATTACK)
		set_player_nextattack(id, CHARGE_NEXTATTACK)
		
		g_charging[id] = 0
		g_charged[id] = 0
		g_chargeattack[id] = 0
		
		remove_task(id+TASK_CHARGE_STARTING)
		remove_task(id+TASK_CHARGING)
						
		return
	}
	
	g_charging[id] = 2
	g_chargeattack[id] = 1
	g_charged[id] = 0
		
	set_weapons_timeidle(id, CHARGE_TIME + 0.25)
	set_player_nextattack(id, CHARGE_TIME + 0.25)
		
	set_weapon_anim(id, BALROG9_ANIM_CHARGE_IDLE1)	
}

public fw_TraceLine(Float:vector_start[3], Float:vector_end[3], ignored_monster, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED	
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_balrog9[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	if(g_attack_mode[id] == MODE_NORMAL)
		xs_vec_mul_scalar(v_forward, ATTACKDIS_SLASH, v_forward)
	else if(g_attack_mode[id] == MODE_CHARGE)
		xs_vec_mul_scalar(v_forward, ATTACKDIS_CHARGE, v_forward)
	
	xs_vec_add(vecStart, v_forward, vecEnd)
	engfunc(EngFunc_TraceLine, vecStart, vecEnd, ignored_monster, id, handle)
	
	return FMRES_SUPERCEDE
}

public fw_TraceHull(Float:vector_start[3], Float:vector_end[3], ignored_monster, hull, id, handle)
{
	if (!is_user_alive(id))
		return FMRES_IGNORED
	if (get_user_weapon(id) != CSW_KNIFE)
		return FMRES_IGNORED
	if(!g_had_balrog9[id])
		return FMRES_IGNORED
	
	static Float:vecStart[3], Float:vecEnd[3], Float:v_angle[3], Float:v_forward[3], Float:view_ofs[3], Float:fOrigin[3]
	
	pev(id, pev_origin, fOrigin)
	pev(id, pev_view_ofs, view_ofs)
	xs_vec_add(fOrigin, view_ofs, vecStart)
	pev(id, pev_v_angle, v_angle)
	
	engfunc(EngFunc_MakeVectors, v_angle)
	get_global_vector(GL_v_forward, v_forward)

	if(g_attack_mode[id] == MODE_NORMAL)
		xs_vec_mul_scalar(v_forward, ATTACKDIS_SLASH, v_forward)
	else if(g_attack_mode[id] == MODE_CHARGE)
		xs_vec_mul_scalar(v_forward, ATTACKDIS_CHARGE, v_forward)
		
	xs_vec_add(vecStart, v_forward, vecEnd)
	engfunc(EngFunc_TraceHull, vecStart, vecEnd, ignored_monster, hull, id, handle)
	
	return FMRES_SUPERCEDE
}

stock get_position(ent, Float:forw, Float:right, Float:up, Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(ent, pev_origin, vOrigin)
	pev(ent, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(ent, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}
	
stock set_weapons_timeidle(id, Float:TimeIdle)
{
	if(!is_user_alive(id))
		return
		
	new entwpn = fm_get_user_weapon_entity(id, CSW_KNIFE)
	if (pev_valid(entwpn)) 
	{
		set_pdata_float(entwpn, 46, TimeIdle, 4)
		set_pdata_float(entwpn, 47, TimeIdle, 4)
		set_pdata_float(entwpn, 48, TimeIdle + 1.0, 4)
	}
}

stock set_player_nextattack(id, Float:nexttime)
{
	if(!is_user_alive(id))
		return
		
	const m_flNextAttack = 83
	set_pdata_float(id, m_flNextAttack, nexttime, 5)
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
		
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, _, id)
	write_byte(anim)
	write_byte(0)
	message_end()	
}

stock hook_ent2(ent, Float:VicOrigin[3], Float:speed, type)
{
	static Float:fl_Velocity[3]
	static Float:EntOrigin[3]
	
	pev(ent, pev_origin, EntOrigin)
	static Float:distance_f
	distance_f = get_distance_f(EntOrigin, VicOrigin)
	
	new Float:fl_Time = distance_f / speed
	
	VicOrigin[2] -= 36.0
	
	if(type == 1)
	{
		fl_Velocity[0] = ((VicOrigin[0] - EntOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((VicOrigin[1] - EntOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = ((VicOrigin[2] - EntOrigin[2]) / fl_Time) * 1.5
	} else if(type == 2) {
		fl_Velocity[0] = ((EntOrigin[0] - VicOrigin[0]) / fl_Time) * 1.5
		fl_Velocity[1] = ((EntOrigin[1] - VicOrigin[1]) / fl_Time) * 1.5
		fl_Velocity[2] = ((EntOrigin[2] - VicOrigin[2]) / fl_Time) * 1.5
	}

	entity_set_vector(ent, EV_VEC_velocity, fl_Velocity)
}
