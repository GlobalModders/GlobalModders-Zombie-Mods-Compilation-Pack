#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <biohazard>
#include <bio_shop>

#define TASK_SHOW_AMMO 111111

new const weapon_classname[] = "svdex"
new const w_model[] = "models/w_svdex.mdl"
new const p_model[] = "models/p_svdex.mdl"
new const v_model1[] = "models/v_svdex.mdl"
new const v_model2[] = "models/v_svdex_2.mdl"
new const grenade_model[] = "models/s_svdex.mdl"

new const grenade_exp_spr[] = "sprites/biohazard/explode_nade.spr"
new const grenade_exp_sound[] = "weapons/svdex_exp.wav"
new const grenade_launch_sound[] = "weapons/svdex_shoot2.wav"

new bool:g_has_ak47launcher[33]
new ak47_mode[33]
new bool:no_draw_other[33]
new bool:is_changing[33]
new Float:last_press[33]
new Float:cl_pushangle[33]

new g_grenade[33]
new g_nodrop[33]
new g_trail, exp_spr

// Cvars
new cvar_default_mode, cvar_radius
new cvar_ammo_default, cvar_normal_dmg, cvar_launch_dmg
new cvar_speed, cvar_recoil

// Weapon entity names
new const WEAPONENTNAMES[][] = {
	"weapon_p228", "weapon_scout", "weapon_hegrenade", "weapon_xm1014", 
	"weapon_c4", "weapon_mac10", "weapon_aug", "weapon_smokegrenade", "weapon_elite", 
	"weapon_fiveseven", "weapon_ump45", "weapon_sg550", "weapon_galil", "weapon_famas", 
	"weapon_usp", "weapon_glock18", "weapon_awp", "weapon_mp5navy", "weapon_m249",
	"weapon_m3", "weapon_m4a1", "weapon_tmp", "weapon_g3sg1", "weapon_flashbang", "weapon_deagle",
	"weapon_sg552", "weapon_ak47", "weapon_knife", "weapon_p90" 
}

new g_ak47launcher

public plugin_init()
{
	register_plugin("[Bio] Shop: Ak47 Launcher", "1.0", "Dias")
	
	// Events
	register_event("CurWeapon", "event_curweapon", "be", "1=1")
	register_event("DeathMsg", "event_death", "a")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	RegisterHam(Ham_Spawn, "player", "fw_spawn_post", 1)
	for(new i = 0 ; i < sizeof WEAPONENTNAMES; i++)
		register_clcmd(WEAPONENTNAMES[i], "fw_changeweapon")
	register_clcmd("lastinv", "fw_changeweapon")
	RegisterHam(Ham_Item_Deploy, "weapon_ak47", "fw_ak47_deploy_post", 1)
	
	// Forward
	register_forward(FM_CmdStart, "fw_cmdstart")
	register_touch("svdex_grenade", "*", "fw_touch")
	RegisterHam(Ham_TakeDamage, "player", "fw_takedmg")
	
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_primary_attack")
	RegisterHam(Ham_Weapon_PrimaryAttack, "weapon_ak47", "fw_primary_attack_post",1) 
	
	// Cvars
	cvar_default_mode = register_cvar("bio_ak47_launcher_default_mode", "1")
	cvar_radius = register_cvar("bio_ak47_launcher_radius", "200.0")
	
	cvar_speed = register_cvar("bio_ak47_normal_speed", "5.5")
	cvar_recoil = register_cvar("bio_ak47_normal_recoil", "0.5")
	
	cvar_ammo_default = register_cvar("bio_ak47_launcher_ammo", "5")
	cvar_normal_dmg = register_cvar("bio_ak47_launcher_normal_dmg", "3.5")
	cvar_launch_dmg = register_cvar("bio_ak47_launcher_dmg", "500")
	
	register_clcmd("drop", "cmd_drop", 0)
	
	g_ak47launcher = bio_register_item("AK47 - Launcher", 15000, "[Right Mouse] -> Grenade Launcher", TEAM_HUMAN)
}

public plugin_precache()
{
	engfunc(EngFunc_PrecacheModel, w_model)
	engfunc(EngFunc_PrecacheModel, p_model)
	engfunc(EngFunc_PrecacheModel, v_model1)
	engfunc(EngFunc_PrecacheModel, v_model2)
	
	engfunc(EngFunc_PrecacheModel, grenade_model)
	engfunc(EngFunc_PrecacheSound, grenade_exp_sound)
	engfunc(EngFunc_PrecacheSound, grenade_launch_sound)
	
	precache_sound("weapons/svdex_shoot1.wav")
	precache_sound("weapons/svdex_clipin.wav")
	precache_sound("weapons/svdex_clipon.wav")
	precache_sound("weapons/svdex_clipout.wav")
	precache_sound("weapons/svdex_draw.wav")
	
	g_trail = engfunc(EngFunc_PrecacheModel, "sprites/smoke.spr")
	exp_spr = engfunc(EngFunc_PrecacheModel, grenade_exp_spr)
}

public bio_item_selected(id, item)
{
	if(item != g_ak47launcher)
		return PLUGIN_HANDLED
	
	if(!g_has_ak47launcher[id])
	{
		g_has_ak47launcher[id] = true
		
		ak47_mode[id] = get_pcvar_num(cvar_default_mode)
		g_grenade[id] = get_pcvar_num(cvar_ammo_default)
		cs_set_user_bpammo(id, CSW_AK47, 250)
		
		give_item(id, "weapon_ak47")
	}
	
	return PLUGIN_CONTINUE
}

public fw_changeweapon(id)
{
	if(no_draw_other[id])
		return PLUGIN_HANDLED
	
	return PLUGIN_CONTINUE
}

public fw_ak47_deploy_post(ent)
{
	static id
	id = pev(ent, pev_owner)
	
	if(!is_user_alive(id) || !is_user_connected(id))
		return HAM_IGNORED
	
	if(get_user_weapon(id) == CSW_AK47 && g_has_ak47launcher[id] && ak47_mode[id] == 2)
		set_task(0.2, "show_ammo", id+TASK_SHOW_AMMO)
		
	return HAM_HANDLED
}

public fw_takedmg(victim, inflictor, attacker, Float:damage, damagebits)
{
	if(!is_user_connected(victim) || !is_user_connected(attacker))
		return HAM_IGNORED
	
	if(get_user_weapon(attacker) == CSW_AK47 && g_has_ak47launcher[attacker] && ak47_mode[attacker] == 1)
	{
		SetHamParamFloat(4, damage * get_pcvar_float(cvar_normal_dmg))
	}
	
	return HAM_HANDLED
}

//for recoil and sound...
public fw_primary_attack(ent)
{
	new id = pev(ent,pev_owner)
	pev(id,pev_punchangle, cl_pushangle[id])
	return HAM_IGNORED
}
public fw_primary_attack_post(ent)
{
	new id = pev(ent,pev_owner)
	new clip, ammo
	new weap = get_user_weapon( id, clip, ammo )
	if(weap == CSW_AK47 && g_has_ak47launcher[id])
	{
		new Float:push[3]
		pev(id,pev_punchangle,push)
		xs_vec_sub(push,cl_pushangle[id],push)
		xs_vec_mul_scalar(push,get_pcvar_float(cvar_recoil),push)
		xs_vec_add(push,cl_pushangle[id],push)
		set_pev(id,pev_punchangle,push)
		if( clip > 0)
		{
			ExecuteHamB(Ham_Weapon_PlayEmptySound, ent)
			emit_sound(id, CHAN_AUTO, "weapons/svdex_shoot1.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
		}
	}	
	
	return HAM_IGNORED
}

public event_newround(id)
{
	for(new i = 0; i < get_maxplayers(); i++)
	{
		g_nodrop[i] = false
		no_draw_other[i] = false
	}
	
	for(new i = 0; i < entity_count(); i++)
	{
		static ent
		ent = find_ent_by_class(-1, weapon_classname)
		
		remove_entity(ent)
	}
}

public cmd_drop(id)
{
	new plrClip, plrAmmo
	new plrWeapId
	plrWeapId = get_user_weapon(id, plrClip , plrAmmo)
	
	if(plrWeapId == CSW_AK47 && g_has_ak47launcher[id] && is_user_alive(id)) 
	{
		if(g_nodrop[id])
		{
			return PLUGIN_HANDLED
		} else {
			no_draw_other[id] = false
			create_w_class(id, plrClip, plrAmmo, 1)	
			return PLUGIN_HANDLED
		}
	} 
	
	return PLUGIN_CONTINUE
}

public create_w_class(id, clip, ammo, type)
{
	new Float:Aim[3],Float:origin[3]
	VelocityByAim(id, 64, Aim)
	entity_get_vector(id,EV_VEC_origin,origin)
	
	if (type == 1) {
		origin[0] += 2*Aim[0]
		origin[1] += 2*Aim[1]
	}
	
	new ent = create_entity("info_target")
	entity_set_string(ent,EV_SZ_classname, weapon_classname)
	entity_set_model(ent, w_model)	
	
	entity_set_size(ent,Float:{-2.0,-2.0,-2.0},Float:{5.0,5.0,5.0})
	entity_set_int(ent,EV_INT_solid,1)
	
	entity_set_int(ent,EV_INT_movetype,6)
	entity_set_int(ent, EV_INT_iuser1, clip)
	entity_set_int(ent, EV_INT_iuser2, ammo)
	entity_set_int(ent, EV_INT_iuser3, g_grenade[id])
	entity_set_vector(ent,EV_VEC_origin, origin)
	g_has_ak47launcher[id] = false
	remove_gun(id)
}

public pfn_touch(ptr, ptd) {
	if(is_valid_ent(ptr)) {
		
		new classname[32]
		entity_get_string(ptr,EV_SZ_classname,classname,31)
		if(equal(classname, weapon_classname)) {
			if(is_valid_ent(ptd)) {
				new id = ptd
				if(id > 0 && id < 34) {
					if(!g_has_ak47launcher[id] && is_user_alive(id)) {
						give_weapon(id,entity_get_int(ptr, EV_INT_iuser1), entity_get_int(ptr, EV_INT_iuser2))
						g_grenade[id] = entity_get_int(ptr, EV_INT_iuser3)
						remove_entity(ptr)
					}
				}
			}
		}
	}
}

public remove_gun(id) { 
	new wpnList[32] 
	new number
	get_user_weapons(id,wpnList,number) 
	for (new i = 0;i < number ;i++) { 
		if (wpnList[i] == CSW_AK47) {
			fm_strip_user_gun(id, wpnList[i])
		}
	}
} 

public give_weapon(id, clip, ammo){
	g_has_ak47launcher[id] = true
	give_item(id, "weapon_ak47")
	cs_set_user_bpammo(id, CSW_AK47, ammo)
	new ent = get_weapon_ent(id, CSW_AK47)
	cs_set_weapon_ammo(ent, clip)
	
}

public event_curweapon(id)
{
	if (!is_user_alive(id))
		return PLUGIN_HANDLED
	
	static CurWeapon
	CurWeapon = read_data(2)
	
	if(CurWeapon == CSW_AK47 && g_has_ak47launcher[id])
	{
		if(ak47_mode[id] == 1)
		{
			static weapon_ent
			weapon_ent = get_weapon_ent(id, CurWeapon)
			
			if(weapon_ent) 
			{
				static Float:Delay
				Delay = get_pdata_float(weapon_ent, 46, 4) * get_pcvar_float(cvar_speed)
				if (Delay > 0.0)
					set_pdata_float(weapon_ent, 46, Delay, 4)
			}
			
			set_pev(id, pev_viewmodel2, v_model1)
			} else if(ak47_mode[id] == 2) {
			set_pev(id, pev_viewmodel2, v_model2)
		}
		
		set_pev(id, pev_weaponmodel2, p_model)
	}
	
	return PLUGIN_CONTINUE
}

public event_death()
{
	new id = read_data(2)
	
	new plrClip, plrAmmo
	get_user_weapon(id, plrClip , plrAmmo)
	
	if(g_has_ak47launcher[id])
	{
		create_w_class(id, plrClip, plrAmmo, 0)
		g_has_ak47launcher[id] = false
		
		if(ak47_mode[id] == 2)
		{
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
			write_byte(0)
			message_end()
		}
		
		return PLUGIN_HANDLED
	}	

	return PLUGIN_CONTINUE
}

public fw_spawn_post(id)
{
	if(g_has_ak47launcher[id])
	{
		g_has_ak47launcher[id] = false
	}
	g_grenade[id] = 0	
	g_nodrop[id] = false
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
	write_byte(0)
	message_end()
}

public event_infect(id)
{
	if(g_has_ak47launcher[id])
	{
		g_has_ak47launcher[id] = false
	}
	
	g_grenade[id] = 0	
	g_nodrop[id] = false
	no_draw_other[id] = false
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
	write_byte(0)
	message_end()	
}

public fw_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !g_has_ak47launcher[id] || get_user_weapon(id) != CSW_AK47)
		return FMRES_IGNORED
	
	if(is_changing[id])
		return FMRES_IGNORED
	
	static Button, Float:Time, fInReload, ent
	
	Button = get_uc(uc_handle, UC_Buttons)
	Time = get_gametime()
	ent = find_ent_by_owner(-1, "weapon_ak47", id)
	fInReload = get_pdata_int(ent, 54, 4)
	
	if(fInReload)
	{
		no_draw_other[id] = true
		return FMRES_IGNORED
		} else {
		no_draw_other[id] = false
	}
	
	if(Button & IN_ATTACK2)
	{
		if(ak47_mode[id] == 1)
		{
			is_changing[id] = true
			no_draw_other[id] = true
			g_nodrop[id] = true
			
			play_weapon_anim(id, 6)
			set_player_nextattack(id, 1.8)
			
			new task[2]
			task[0] = id
			task[1] = 2
			set_task(1.8, "change_complete", _, task, sizeof(task))
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
			write_byte((1<<6))
			message_end()
			
			} else if(ak47_mode[id] == 2) {
			is_changing[id] = true
			no_draw_other[id] = true
			g_nodrop[id] = true
			
			play_weapon_anim(id, 6)
			set_player_nextattack(id, 1.8)
			
			new task[2]
			task[0] = id
			task[1] = 1
			set_task(1.8, "change_complete", _, task, sizeof(task))
		}
	}
	
	if(Button & IN_RELOAD)
	{
		if(is_changing[id])
		{
			Button &= ~IN_RELOAD
			set_uc(uc_handle, UC_Buttons, Button)
		}
	} else if(Button & IN_ATTACK) {
		if(Time - 3.0 > last_press[id] && ak47_mode[id] == 2)
		{
			set_player_nextattack(id, 999999.0)
			
			launch_grenade(id)
			last_press[id] = Time
		}
	}
	
	return FMRES_HANDLED
}

public fw_touch(grenade, id)
{
	if(!pev_valid(grenade))
		return FMRES_IGNORED
	
	// Get it's origin
	static Float:Origin[3]
	pev(grenade, pev_origin, Origin)
	
	// Explosion
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, Origin[0])
	engfunc(EngFunc_WriteCoord, Origin[1])
	engfunc(EngFunc_WriteCoord, Origin[2])
	write_short(exp_spr)
	write_byte(40)
	write_byte(30)
	write_byte(0)
	message_end()
	
	static owner
	owner = pev(grenade, pev_owner)	

	// Remove grenade
	engfunc(EngFunc_RemoveEntity, grenade)
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_alive(i) && is_user_connected(i))
		{
			static Float:Origin2[3], Float:distance_f
			
			pev(i, pev_origin, Origin2)
			distance_f = get_distance_f(Origin, Origin2)
			
			if (distance_f <= get_pcvar_float(cvar_radius))
			{
				new Damage
				Damage = get_pcvar_num(cvar_launch_dmg)
		
				ExecuteHamB(Ham_TakeDamage, i, "grenade", owner, Damage, DMG_BLAST)
				emit_sound(owner, CHAN_VOICE, grenade_exp_sound, 1.0, ATTN_NORM, 0, PITCH_NORM) 
		
				if(!is_user_zombie(i))
					return FMRES_IGNORED
				if(i == owner)
					return FMRES_IGNORED
					
				static health
				health = get_user_health(i)
				
				if(health - Damage >= 1)
				{
					set_user_health(i, health - Damage) 
					make_knockback(i, Origin, 2.0 * Damage)
				}
				else
				{
					death_message(owner, i, "grenade", 1)
					Origin2[2] -= 45.0
				}
			}
		}
	}

	return FMRES_HANDLED
}

public launch_grenade(id)
{	
	if(g_grenade[id] <= 0)
	{
		client_print(id, print_center, "[Out Of Ammo]")
		return PLUGIN_HANDLED
	}
	
	play_weapon_anim(id, random_num(3, 5))
	
	new Float:Origin[3], Float:Velocity[3], Float:vAngle[3], Ent
	
	entity_get_vector(id, EV_VEC_origin , Origin)
	entity_get_vector(id, EV_VEC_v_angle, vAngle)
	Origin[2] = Origin[2] + 10
	
	Ent = create_entity("info_target")
	if (!Ent) return PLUGIN_HANDLED
	
	entity_set_string(Ent, EV_SZ_classname, "svdex_grenade")
	entity_set_model(Ent, grenade_model)
	
	new Float:MinBox[3] = {-1.0, -1.0, -1.0}
	new Float:MaxBox[3] = {1.0, 1.0, 1.0}
	entity_set_vector(Ent, EV_VEC_mins, MinBox)
	entity_set_vector(Ent, EV_VEC_maxs, MaxBox)
	
	entity_set_origin(Ent, Origin)
	entity_set_vector(Ent, EV_VEC_angles, vAngle)
	
	entity_set_int(Ent, EV_INT_effects, 2)
	entity_set_int(Ent, EV_INT_solid, 1)
	entity_set_int(Ent, EV_INT_movetype, 10)
	entity_set_edict(Ent, EV_ENT_owner, id)
	
	VelocityByAim(id, 2500 , Velocity)
	entity_set_vector(Ent, EV_VEC_velocity ,Velocity)
	
	//sound when lauch...
	emit_sound(id,CHAN_VOICE, grenade_launch_sound, 1.0, ATTN_NORM, 0, PITCH_NORM) 
	
	g_grenade[id]--
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY )
	write_byte(TE_BEAMFOLLOW)
	write_short(Ent)
	write_short(g_trail)
	write_byte(10)
	write_byte(5)
	write_byte(255)
	write_byte(255)
	write_byte(255)
	write_byte(100)
	message_end()
	
	if(g_grenade[id] <= 0)
	{
		client_print(id, print_center, "Out Of Ammo... Switch to Normal AK47 !!!")
		
		is_changing[id] = true
		no_draw_other[id] = true
		
		play_weapon_anim(id, 6)
		set_player_nextattack(id, 1.8)
		
		new task[2]
		task[0] = id
		task[1] = 1
		set_task(1.8, "change_complete", _, task, sizeof(task))
	} else {
		client_print(id, print_center, "Reloading... Please Wait !!!")
	}
		
	return PLUGIN_CONTINUE
}

public change_complete(task[])
{
	static id, mode_change
	id = task[0]
	mode_change = task[1]
	
	if(mode_change == 1)
	{
		new ent = find_ent_by_owner(-1, "weapon_ak47", id)
		ExecuteHam(Ham_Item_Deploy, ent)
		set_pev(id, pev_viewmodel2, v_model1)
		play_weapon_anim(id, 0)
		
		ak47_mode[id] = 1
		client_print(id, print_center, "[Switch to AK47 Normal]")
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("HideWeapon"), _, id)
		write_byte(0)
		message_end()
		
		} else if(mode_change == 2) {
			
		new ent = find_ent_by_owner(-1, "weapon_ak47", id)
		ExecuteHam(Ham_Item_Deploy, ent)
		set_pev(id, pev_viewmodel2, v_model2)
		play_weapon_anim(id, 0)
		set_player_nextattack(id, 999999.0)
		
		ak47_mode[id] = 2
		client_print(id, print_center, "[Switch to AK47 - Launcher]")
		
		set_task(0.2, "show_ammo", id+TASK_SHOW_AMMO, _, _, "b")
	}
	g_nodrop[id] = false
	set_pev(id, pev_weaponmodel2, p_model)
	
	is_changing[id] = false
	no_draw_other[id] = false
}

public play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

public set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 5)
}

public make_knockback(id, Float:Origin[3], Float:maxspeed)
{
	// Get and set velocity
	new Float:fVelocity[3]
	kickback(id, Origin, maxspeed, fVelocity)
	
	entity_set_vector(id, EV_VEC_velocity, fVelocity)
}

stock kickback(ent, Float:fOrigin[3], Float:fSpeed, Float:fVelocity[3])
{
	// Find origin
	new Float:fEntOrigin[3];
	entity_get_vector( ent, EV_VEC_origin, fEntOrigin );

	// Do some calculations
	new Float:fDistance[3];
	fDistance[0] = fEntOrigin[0] - fOrigin[0];
	fDistance[1] = fEntOrigin[1] - fOrigin[1];
	fDistance[2] = fEntOrigin[2] - fOrigin[2];
	new Float:fTime = (vector_distance( fEntOrigin,fOrigin ) / fSpeed);
	fVelocity[0] = fDistance[0] / fTime;
	fVelocity[1] = fDistance[1] / fTime;
	fVelocity[2] = fDistance[2] / fTime;

	return (fVelocity[0] && fVelocity[1] && fVelocity[2]);
}

// Death message
public death_message(Killer, Victim, const Weapon[], ScoreBoard)
{
	// Block death msg
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_SET)
	ExecuteHamB(Ham_Killed, Victim, Killer, 2)
	set_msg_block(get_user_msgid("DeathMsg"), BLOCK_NOT)
	
	// Death
	make_deathmsg(Killer, Victim, 0, Weapon)

	// Update score board
	if (ScoreBoard)
	{
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(Killer) // id
		write_short(pev(Killer, pev_frags)) // frags
		write_short(cs_get_user_deaths(Killer)) // deaths
		write_short(0) // class?
		write_short(get_user_team(Killer)) // team
		message_end()
		
		message_begin(MSG_BROADCAST, get_user_msgid("ScoreInfo"))
		write_byte(Victim) // id
		write_short(pev(Victim, pev_frags)) // frags
		write_short(cs_get_user_deaths(Victim)) // deaths
		write_short(0) // class?
		write_short(get_user_team(Victim)) // team
		message_end()
	}
}

public show_ammo(taskid)
{
	new id = taskid - TASK_SHOW_AMMO
	
	if(get_user_weapon(id) == CSW_AK47 && g_has_ak47launcher[id] && ak47_mode[id] == 2)
	{
		static Message[32]
		formatex(Message, sizeof(Message), "Grenade Ammo: %i/%i", g_grenade[id], get_pcvar_num(cvar_ammo_default))
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
		write_byte(0)
		write_string(Message)
		message_end()
	} else {
		
		message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("StatusText"), {0,0,0}, id)
		write_byte(0)
		write_string("")
		message_end()
		remove_task(id+TASK_SHOW_AMMO)
	}
}

stock get_weapon_ent(id,wpnid=0,wpnName[]="")
{
	static newName[24]

	if(wpnid) get_weaponname(wpnid,newName,23)
	else formatex(newName,23,"%s",wpnName)

	if(!equal(newName,"weapon_",7))
		format(newName,23,"weapon_%s",newName)

	return fm_find_ent_by_owner(get_maxplayers(),newName,id)
} 
