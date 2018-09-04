#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <biohazard>
#include <bio_shop>
#include <xs>
#include <fun>

#define PLUGIN "[Bio] Zombie Class: Witch"
#define VERSION "1.0"
#define AUTHOR "Dias"

// Main Class
#define D_ZOMBIE_NAME "Witch Zombie"
#define D_ZOMBIE_DESC "[G] -> Tha Doi"
#define D_PLAYER_MODEL "models/player/witch_zombi_origin/witch_zombi_origin.mdl"
#define D_CLAWS "models/biohazard/v_knife_witch_zombi.mdl"

new g_zclass_witch
new const bat_model[] = "models/biohazard/bat_witch.mdl"

// Other HardCode
new witch_skull_bat_speed,witch_skull_bat_flytime,witch_skull_bat_catch_time,
witch_skull_bat_catch_speed, bat_timewait, g_stop[33]
new g_bat_time[33], g_bat_stat[33], g_bat_enemy[33]
new spr_skull
new cvar_cooldown

#define TASK_REMOVE_STAT 122334
#define TASK_COOLDOWN 123123
new const bat_classname[] = "bat_witch"
new bool:can_use_skill[33]

// Confusion Bomb
#define CLASSNAME_FAKE_PLAYER "illusion_player"
#define TASK_REMOVE_ILLUSION 111111
#define TASK_CONFUSION_SPR 434343

#define pev_nade_type        pev_flTimeStepSound
#define NADE_TYPE_CONFUSION    121314
#define TASK_GET_BOMB 131232

new g_confused_bomb
new g_iConfusing[33], g_iEntFake[33]
new g_confusing[33]
new bool:has_confuse_bomb[33]

new cvar_distance, cvar_time_hit, cvar_time_give

new const v_model[] = "models/biohazard/v_zombibomb.mdl"
new const p_model[] = "models/biohazard/p_zombibomb.mdl"
new const w_model[] = "models/biohazard/w_zombibomb.mdl"

new const witch_laugh[] = "biohazard/zombi_banshee_laugh.wav"
new const bat_sound[] = "biohazard/zombi_banshee_pulling_fire.wav"

new const confusion_exp[] = "biohazard/zombi_bomb_exp.wav"
new const confusing[] = "biohazard/zombi_banshee_confusion_keep.wav"
new const confusion_spr[] = "sprites/biohazard/zb_confuse.spr"

new g_iCurrentWeapon[33]
new confuse_spr_id
new g_exp_spr

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	// Events
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0")
	register_event("DeathMsg", "Death", "a")
	
	//Skull Command
	register_clcmd("drop", "cmd_bat")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
	
	//Ham Register
	register_touch(bat_classname, "*", "fw_touch_post")
	register_touch("player", "player", "fw_touch_player")
	RegisterHam(Ham_Think, "info_target", "fw_Think")
	
	// Register Cvars
	witch_skull_bat_speed = register_cvar("bh_witch_bat_speed", "500.0")
	witch_skull_bat_flytime = register_cvar("bh_witch_bat_flytime", "2.0")
	
	witch_skull_bat_catch_speed = register_cvar("bh_witch_bat_catch_speed", "300.0")
	witch_skull_bat_catch_time = register_cvar("bh_witch_bat_catch_time", "2.0")
	
	bat_timewait = register_cvar("bh_bat_timewait", "5.0")
	cvar_cooldown = register_cvar("bh_skill_cooldown", "10.0")
	
	register_zombie_class()
	
	// Confusion Bomb
	register_forward(FM_AddToFullPack, "Forward_AddToFullPack_Post", 1)
	
	register_event("CurWeapon", "EV_CurWeapon", "be", "1=1")
	register_event("DeathMsg", "EV_DeathMsg", "a")
	
	register_forward(FM_SetModel, "fw_SetModel")
	RegisterHam(Ham_Think, "grenade", "fw_GrenadeThink")
	RegisterHam(Ham_Touch, "grenade", "fw_GrenadeTouch")

	cvar_distance = register_cvar("bh_confuse_bomb_distance", "200.0")
	cvar_time_hit = register_cvar("bh_confuse_bomb_time_hit", "15.0")
	cvar_time_give = register_cvar("bh_confuse_bomb_time_give", "20.0")
	
	g_confused_bomb = bio_register_item("Confused Bomb", 5000, "Make human Confused", TEAM_ZOMBIE)
	
	register_clcmd("say /test", "test")
}

public test(id)
{
	set_player_animation(id, 7)
}

public bio_item_selected(id, item)
{
	if(item != g_confused_bomb)
		return PLUGIN_HANDLED
		
	has_confuse_bomb[id] = true
	give_item(id, "weapon_smokegrenade")
		
	return PLUGIN_CONTINUE
}

public plugin_precache()
{
	spr_skull = precache_model("sprites/biohazard/ef_bat.spr")

	precache_model(bat_model)
	
	precache_model(D_PLAYER_MODEL)
	precache_model(D_CLAWS)
	
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	
	engfunc(EngFunc_PrecacheSound, witch_laugh)
	engfunc(EngFunc_PrecacheSound, bat_sound)
	engfunc(EngFunc_PrecacheSound, confusion_exp)
	engfunc(EngFunc_PrecacheSound, confusing)
	
	confuse_spr_id = precache_model(confusion_spr)
	g_exp_spr = engfunc(EngFunc_PrecacheModel, "sprites/biohazard/zombiebomb.spr")
}

public register_zombie_class()
{
	g_zclass_witch = register_class(D_ZOMBIE_NAME, D_ZOMBIE_DESC)
	
	if(g_zclass_witch != -1)
	{
		set_class_data(g_zclass_witch, DATA_HEALTH, 3000.0)
		set_class_data(g_zclass_witch, DATA_SPEED, 280.0)
		set_class_data(g_zclass_witch, DATA_GRAVITY, 1.0)
		set_class_data(g_zclass_witch, DATA_ATTACK, 1.0)
		set_class_data(g_zclass_witch, DATA_HITDELAY, 1.0)
		set_class_data(g_zclass_witch, DATA_HITREGENDLY, 999.0)
		set_class_data(g_zclass_witch, DATA_DEFENCE, 1.0)
		set_class_data(g_zclass_witch, DATA_HEDEFENCE, 1.0)
		set_class_data(g_zclass_witch, DATA_KNOCKBACK, 1.5)
		set_class_data(g_zclass_witch, DATA_MODELINDEX, 1.0)
		set_class_pmodel(g_zclass_witch, D_PLAYER_MODEL)
		set_class_wmodel(g_zclass_witch, D_CLAWS)
	}	
}

public event_round_start()
{
	for (new id=1; id<33; id++)
	{
		if (!is_user_connected(id)) continue;
		
		reset_value_player(id)
		//UNDONE Reset SPR
	}
}
public Death()
{
	new victim = read_data(2) 
	reset_value_player(victim)
}

public client_connect(id)
{
	reset_value_player(id)
}

public client_disconnect(id)
{
	reset_value_player(id)
	if(task_exists(id+TASK_COOLDOWN)) remove_task(id+TASK_COOLDOWN)
	
	if(g_iEntFake[id])
		remove_entity(g_iEntFake[id])
}

reset_value_player(id)
{
	g_bat_time[id]=0
	set_task(0.1, "remove_confuse", id+TASK_REMOVE_ILLUSION)
}

// #################### MAIN FUNCTION ####################
public event_infect(id)
{
	has_confuse_bomb[id] = false
	g_iConfusing[id] = 0
	
	// tao ent fake cho attacker neu chua co
	new iEntFake = find_ent_by_owner(-1, CLASSNAME_FAKE_PLAYER, id)
	if(!iEntFake)
		iEntFake = create_fake_player(id)
	
	if(is_user_zombie(id) && get_user_class(id) == g_zclass_witch)
	{
		can_use_skill[id] = true
		client_printc(id, "!g[Bio] !nYou are !tWitch Zombie!n. Press !t(G)!n to !gSumon Bat!n !!!")
		client_printc(id, "!g[Bio] !nYou also have !tConfused Bomb!n. Press !t(4)!n to !gSwitch!n !!!")
		
		has_confuse_bomb[id] = true
		give_item(id, "weapon_smokegrenade")
		
		set_task(get_pcvar_float(cvar_time_give), "get_new_bomb", id+TASK_GET_BOMB, _, _, "b")
		
		if(is_user_bot(id))
		{
			set_task(random_float(10.0, 17.0), "cmd_bat", id)
			set_task(random_float(7.0, 12.0), "cmd_illusion", id)
		}
	}
}

public get_new_bomb(taskid)
{
	new id = taskid - TASK_GET_BOMB
	
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_witch && !is_user_boss(id))
	{
		if(!has_confuse_bomb[id])
		{
			has_confuse_bomb[id] = true
			give_item(id, "weapon_smokegrenade")
		}
	}
	
}

public cmd_illusion(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_witch)
	{
		if(has_confuse_bomb[id])
		{
			engclient_cmd(id, "weapon_smokegrenade")
			set_task(1.5, "throw_confusebomb", id)
			
		} else {
			has_confuse_bomb[id] = true
			give_item(id, "weapon_smokegrenade")
			
			set_task(1.5, "cmd_illusion", id)
		}
	}	
}

public throw_confusebomb(id)
{
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_witch)
	{
		new ent = find_ent_by_owner(-1, "weapon_smokegrenade", id)
		ExecuteHamB(Ham_Weapon_PrimaryAttack, ent)
	}
}

public cmd_bat(id)
{
	if (!is_user_alive(id)) return PLUGIN_CONTINUE

	if (is_user_zombie(id) && get_user_class(id) == g_zclass_witch && can_use_skill[id])
	{
		g_bat_time[id] = 1
		
		send_weapon_anim(id, 2)
		
		set_pev(id, pev_sequence, 151)
		entity_set_int(id, EV_INT_sequence, 151)

		set_weapons_timeidle(id, 7.0)
		set_player_nextattack(id, 1.5)		
		
		set_task(1.5, "do_skill_now", id)
		emit_sound(id, CHAN_VOICE, witch_laugh, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}

public do_skill_now(id)
{
	emit_sound(id, CHAN_VOICE, witch_laugh, 1.0, ATTN_NORM, SND_STOP, PITCH_NORM)
	// set time wait
	g_bat_time[id] = 1
	set_task(get_pcvar_float(bat_timewait),"clear_stat",TASK_REMOVE_STAT+id)
	
	//EFFECT!!
	new ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"))
	if(!pev_valid(ent)) return PLUGIN_HANDLED
		
	new Float:vecAngle[3],Float:vecOrigin[3],Float:vecVelocity[3],Float:vecForward[3]
	fm_get_user_startpos(id,5.0,2.0,-1.0,vecOrigin)
	pev(id,pev_angles,vecAngle)
	
	engfunc(EngFunc_MakeVectors,vecAngle)
	global_get(glb_v_forward,vecForward)

	//xs_vec_mul_scalar(vecForward,banchee_skull_bat_speed,vecVelocity)
	velocity_by_aim(id, get_pcvar_num(witch_skull_bat_speed),vecVelocity)
	
	//Entity Statue
	set_pev(ent,pev_origin,vecOrigin)
	set_pev(ent,pev_angles,vecAngle)
	entity_set_string(ent, EV_SZ_classname, bat_classname)
	set_pev(ent,pev_movetype,MOVETYPE_FLY)
	set_pev(ent,pev_solid,SOLID_BBOX)
	engfunc(EngFunc_SetSize,ent,{-20.0,-15.0,-8.0},{20.0,15.0,8.0})

	engfunc(EngFunc_SetModel, ent, bat_model)
	set_pev(ent,pev_animtime, get_gametime())
	set_pev(ent,pev_framerate,1.0) // speed :D
	set_pev(ent,pev_owner,id)
	set_pev(ent,pev_velocity,vecVelocity)
	set_pev(ent,pev_nextthink,get_gametime()+get_pcvar_float(witch_skull_bat_flytime))
	
	can_use_skill[id] = false
	g_stop[id] = ent
	
	//emit_sound(id, CHAN_VOICE, bat_sound, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	set_task(get_pcvar_float(cvar_cooldown), "reset_cooldown", id+TASK_COOLDOWN)	
	
	return PLUGIN_CONTINUE
}

public reset_cooldown(taskid)
{
	new id = taskid - TASK_COOLDOWN
	
	if(is_user_alive(id) && is_user_zombie(id) && get_user_class(id) == g_zclass_witch)
		can_use_skill[id] = true
}

public fw_Think(ent)
{
	if(!pev_valid(ent)) return HAM_IGNORED
	
	new classname[32]
	pev(ent,pev_classname,classname,31)
	
	if(equal(classname,bat_classname))
	{
		static Float:origin[3];
		pev(ent,pev_origin,origin);
    
		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION); // TE_EXPLOSION
		write_coord(floatround(origin[0])); // origin x
		write_coord(floatround(origin[1])); // origin y
		write_coord(floatround(origin[2])); // origin z
		write_short(spr_skull); // sprites
		write_byte(40); // scale in 0.1's
		write_byte(30); // framerate
		write_byte(0); // flags 
		message_end(); // message end
		
		static id
		
		id = pev(ent, pev_owner)
		g_stop[pev(ent,pev_owner)] = 0
		set_pev(pev(ent, pev_owner), pev_maxspeed, get_class_data(get_user_class(pev(ent, pev_owner)), DATA_SPEED))
		engfunc(EngFunc_RemoveEntity,ent)
		
		emit_sound(ent, CHAN_VOICE, bat_sound, 0.0, ATTN_NONE, SND_STOP, PITCH_NORM)
		
		g_bat_stat[id]=0
		g_bat_time[id]=0
	
		send_weapon_anim(id, 0)
		if(pev(id, pev_sequence) != 1)
			entity_set_int(id, EV_INT_sequence, 1)	
			
		remove_task(id+TASK_REMOVE_STAT)
	}

	return HAM_IGNORED
}

public fw_PlayerPreThink(id)
{
	if(!is_user_alive(id)) return FMRES_IGNORED
	if(g_bat_stat[id])
	{
		new owner = g_bat_enemy[id],Float:ownerorigin[3]
		pev(owner,pev_origin,ownerorigin)
		static Float:vec[3]
		aim_at_origin(id,ownerorigin,vec)
		engfunc(EngFunc_MakeVectors, vec)
		global_get(glb_v_forward, vec)
		vec[0] *= get_pcvar_float(witch_skull_bat_catch_speed)
		vec[1] *= get_pcvar_float(witch_skull_bat_catch_speed)
		vec[2] =0.0
		set_pev(id,pev_velocity,vec)
	}
	if(g_bat_time[id])
	{
		set_pev(id,pev_maxspeed,0.1)
		
		if(pev(id, pev_sequence) != 152)
		{
			set_pev(id, pev_sequence, 152)
			entity_set_int(id, EV_INT_sequence, 152)
		}
	}
	return FMRES_IGNORED
}
public clear_stat(taskid)
{
	new id= taskid - TASK_REMOVE_STAT
	g_bat_stat[id]=0
	g_bat_time[id]=0
	
	set_pev(id, pev_maxspeed, get_class_data(get_user_class(id), DATA_SPEED))
	
	send_weapon_anim(id, 0)
	if(pev(id, pev_sequence) != 1)
		entity_set_int(id, EV_INT_sequence, 1)	
}

public fw_touch_post(ent, ptd)
{
	if(!pev_valid(ent)) return HAM_IGNORED

	if(!pev_valid(ptd))
	{
		static Float:origin[3];
		pev(ent,pev_origin,origin);

		message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
		write_byte(TE_EXPLOSION); // TE_EXPLOSION
		write_coord(floatround(origin[0])); // origin x
		write_coord(floatround(origin[1])); // origin y
		write_coord(floatround(origin[2])); // origin z
		write_short(spr_skull); // sprites
		write_byte(40); // scale in 0.1's
		write_byte(30); // framerate
		write_byte(0); // flags 
		message_end(); // message end
		
		static id
		
		g_stop[pev(ent,pev_owner)]=0
		id = pev(ent, pev_owner)
		
		set_pev(pev(ent, pev_owner), pev_maxspeed, get_class_data(get_user_class(pev(ent, pev_owner)), DATA_SPEED))
		engfunc(EngFunc_RemoveEntity,ent)
		
		g_bat_stat[id]=0
		g_bat_time[id]=0	
		
		send_weapon_anim(id, 0)
		remove_task(id+TASK_REMOVE_STAT)
		
		emit_sound(ent, CHAN_VOICE, bat_sound, 0.0, ATTN_NONE, SND_STOP, PITCH_NORM)
		
		return HAM_IGNORED
	}
			
	new owner = pev(ent,pev_owner)
	if(0<ptd&&ptd<33&&is_user_alive(ptd)&& !is_user_zombie(ptd) && ptd!=owner)
	{
		g_bat_enemy[ptd]=owner
		
		set_pev(ent,pev_nextthink,get_gametime() + get_pcvar_float(witch_skull_bat_catch_time))
		set_pev(ent,pev_movetype,MOVETYPE_FOLLOW)
		set_pev(ent,pev_aiment,ptd)
		
		set_task(get_pcvar_float(witch_skull_bat_catch_time),"clear_stat2",ptd+TASK_REMOVE_STAT)
		
		g_bat_stat[ptd]=1
	}
	
	return HAM_IGNORED
}

public clear_stat2(idx)
{
	new id = idx-TASK_REMOVE_STAT
	
	g_bat_enemy[id]=0
	g_bat_stat[id]=0
	
	set_pev(id, pev_maxspeed, get_class_data(get_user_class(id), DATA_SPEED))
	
	send_weapon_anim(id, 0)
	if(pev(id, pev_sequence) != 1)
		entity_set_int(id, EV_INT_sequence, 1)		
}

stock fm_get_user_startpos(id,Float:forw,Float:right,Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_v_angle, vAngle)
	
	engfunc(EngFunc_MakeVectors, vAngle)
	
	global_get(glb_v_forward, vForward)
	global_get(glb_v_right, vRight)
	global_get(glb_v_up, vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
}

stock aim_at_origin(id, Float:target[3], Float:angles[3])
{
	static Float:vec[3]
	pev(id,pev_origin,vec)
	vec[0] = target[0] - vec[0]
	vec[1] = target[1] - vec[1]
	vec[2] = target[2] - vec[2]
	engfunc(EngFunc_VecToAngles,vec,angles)
	angles[0] *= -1.0
	angles[2] = 0.0
}

send_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

client_printc(index, const text[], any:...)
{
	new szMsg[128];
	vformat(szMsg, sizeof(szMsg) - 1, text, 3);

	replace_all(szMsg, sizeof(szMsg) - 1, "!g", "^x04");
	replace_all(szMsg, sizeof(szMsg) - 1, "!n", "^x01");
	replace_all(szMsg, sizeof(szMsg) - 1, "!t", "^x03");

	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, index);
	write_byte(index);
	write_string(szMsg);
	message_end();
}  

public EV_CurWeapon(id)
{
	if (!is_user_alive (id) || !is_user_zombie(id))
		return PLUGIN_CONTINUE
	
	g_iCurrentWeapon[id] = read_data(2)
	
	if (has_confuse_bomb[id] && g_iCurrentWeapon [id] == CSW_SMOKEGRENADE)
	{
		set_pev (id, pev_viewmodel2, v_model)
		set_pev (id, pev_weaponmodel2, p_model)
	}
	
	return PLUGIN_CONTINUE
}

public EV_DeathMsg()
{
	new iVictim = read_data(2)
	
	if (!is_user_connected(iVictim))
		return
	
	has_confuse_bomb[iVictim] = false
}

public fw_SetModel(ent, const Model[])
{
	if (ent < 0)
		return FMRES_IGNORED
	
	if (pev(ent, pev_dmgtime) == 0.0)
		return FMRES_IGNORED
	
	new iOwner = pev(ent, pev_owner)
	
	if (has_confuse_bomb[iOwner] && equal(Model[7], "w_sm", 4))
	{
		// Reset any other nade
		set_pev (ent, pev_nade_type, 0 )
		
		set_pev (ent, pev_nade_type, NADE_TYPE_CONFUSION)
		
		entity_set_model(ent, w_model)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public event_newround(id)
{
	g_iConfusing[id] = 0
	
	if(task_exists(id+TASK_REMOVE_ILLUSION)) remove_task(id+TASK_REMOVE_ILLUSION)
	if(task_exists(id+TASK_CONFUSION_SPR)) remove_task(id+TASK_CONFUSION_SPR)
}

public fw_GrenadeThink(ent)
{
	if(!pev_valid(ent))
		return HAM_IGNORED
	
	static id
	id = pev(ent, pev_owner)
	
	static dmgtime
	dmgtime = pev(ent, pev_dmgtime)
	
	if(dmgtime != 0.0)
		return HAM_IGNORED
	
	if(is_user_zombie(id) && pev(ent, pev_nade_type) == NADE_TYPE_CONFUSION)
	{ 
		if(has_confuse_bomb[id])
		{
			has_confuse_bomb[id] = false
			confuse_bomb_exp(ent, id)
			
			engfunc(EngFunc_RemoveEntity, ent)
			
			return HAM_SUPERCEDE
		}
	}

	return HAM_HANDLED
}

public fw_GrenadeTouch(bomb)
{
	if(!pev_valid(bomb))
		return HAM_IGNORED
	
	static id
	id = pev(bomb, pev_owner)
	
	if(is_user_zombie(id) && pev(bomb, pev_nade_type) == NADE_TYPE_CONFUSION)
	{ 
		if(has_confuse_bomb[id])
		{
			set_pev(bomb, pev_dmgtime, 0.0)
		}
	}

	return HAM_HANDLED	
}

public confuse_bomb_exp(ent, owner)
{
	static Float:Origin[3]
	pev(ent, pev_origin, Origin)
	
	// Make the explosion
	EffectZombieBomExp(ent)
	emit_sound(ent, CHAN_AUTO, confusion_exp, 1.0, ATTN_NORM, 0, PITCH_NORM)
	
	// Make Hit Human
	static victim = -1
	while ((victim = engfunc(EngFunc_FindEntityInSphere, victim, Origin, get_pcvar_float(cvar_distance))) != 0)
	{
		if(!is_user_alive(victim) || !is_user_connected(victim) || is_user_zombie(victim) || g_confusing[victim])
			continue
		
		client_print(victim, print_chat, "[Bio] You are Confusing !!!")
		
		if(is_user_alive(victim) && is_user_connected(victim) && !is_user_zombie(victim))
		{
			g_iConfusing[victim] = owner
			g_confusing[victim] = 1
			
			set_task(0.1, "makespr", victim+TASK_CONFUSION_SPR)
			
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, victim)
			write_short(10)
			write_short(10)
			write_short(0x0000)
			write_byte(100)
			write_byte(100)
			write_byte(100)
			write_byte(255)
			message_end()
			
			emit_sound(victim, CHAN_VOICE, confusing, 1.0, ATTN_NORM, 0, PITCH_NORM)
			
			set_task(get_pcvar_float(cvar_time_hit), "remove_confuse", victim+TASK_REMOVE_ILLUSION)
		}
	}
}

EffectZombieBomExp(id)
{
	static Float:origin[3];
	pev(id,pev_origin,origin);
    
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY); 
	write_byte(TE_EXPLOSION); // TE_EXPLOSION
	write_coord(floatround(origin[0])); // origin x
	write_coord(floatround(origin[1])); // origin y
	write_coord(floatround(origin[2])); // origin z
	write_short(g_exp_spr); // sprites
	write_byte(40); // scale in 0.1's
	write_byte(30); // framerate
	write_byte(14); // flags 
	message_end(); // message end
}

public Forward_AddToFullPack_Post(es_handled, inte, ent, host, hostflags, player, pSet)
{
	// neu host ko con song thi bo qua
	if (!is_user_alive(host))
		return FMRES_IGNORED
		
	if(!g_confusing[host] || !g_iConfusing[host])
		return FMRES_IGNORED

	// neu ent chinh la thang nem bomb
	if ((1 < ent < 32) && is_user_zombie(ent))
	{
			// an? thang do'
			set_es(es_handled, ES_RenderMode, kRenderTransAdd)
			set_es(es_handled, ES_RenderAmt, 0.0)
			
			// tao ent fake cho attacker neu chua co
			new iEntFake = find_ent_by_owner(-1, CLASSNAME_FAKE_PLAYER, ent)
			if(!iEntFake || !pev_valid(ent))
			{
				iEntFake = create_fake_player(ent)
			}
			
			g_iEntFake[ent] = iEntFake	
	}  else if(ent >= g_iEntFake[32])
	{	
		// show hang' cho thang victim xem
		set_es(es_handled, ES_RenderMode, kRenderNormal)
		set_es(es_handled, ES_RenderAmt, 255.0)
		
		// set model cua host cho ent fake
		//set_es(es_handled, ES_ModelIndex, pev(host, pev_modelindex))
	}
	
	return FMRES_IGNORED
}

public remove_confuse(taskid)
{
	new id = taskid - TASK_REMOVE_ILLUSION
	g_iConfusing[id] = 0
	g_confusing[id] = 0
	
	if(task_exists(id+TASK_CONFUSION_SPR)) remove_task(id+TASK_CONFUSION_SPR)
}

public makespr(taskid)
{
	new id = taskid - TASK_CONFUSION_SPR
	
	if(is_user_zombie(id) || !is_user_alive(id))
		return
	
	static Float:Origin[3]
	pev(id, pev_origin, Origin)
	
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, Origin, 0)
	write_byte(TE_SPRITE)
	engfunc(EngFunc_WriteCoord,Origin[0])
	engfunc(EngFunc_WriteCoord,Origin[1])
	engfunc(EngFunc_WriteCoord,Origin[2]+25.0)
	write_short(confuse_spr_id)
	write_byte(8)
	write_byte(255)
	message_end()
	
	set_task(0.1,"makespr",id+TASK_CONFUSION_SPR)
}

public create_fake_player(id)
{
	new iEntFake = create_entity("info_target")
	set_pev(iEntFake, pev_classname, CLASSNAME_FAKE_PLAYER)
	set_pev(iEntFake, pev_modelindex, pev(id, pev_modelindex))
	set_pev(iEntFake, pev_movetype, MOVETYPE_FOLLOW)
	set_pev(iEntFake, pev_solid, SOLID_NOT)
	set_pev(iEntFake, pev_aiment, id)
	set_pev(iEntFake, pev_owner, id)
	
	entity_set_float(iEntFake, EV_FL_animtime, 2.0)
	entity_set_float(iEntFake, EV_FL_framerate, 1.0)

	entity_set_int(iEntFake, EV_INT_sequence, 4)

	// an? fake player
	set_pev(iEntFake, pev_rendermode, kRenderTransAdd)
	set_pev(iEntFake, pev_renderamt, 0.0)
	
	set_pev(iEntFake, pev_nextthink, halflife_time() + 0.01)
	
	return iEntFake
}  

get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = fm_find_ent_by_owner(-1, wname, id)
	return weapon_ent
}

set_weapons_timeidle(id, Float:timeidle)
{
	new entwpn = get_weapon_ent(id, get_user_weapon(id))
	if (pev_valid(entwpn)) set_pdata_float(entwpn, 48, timeidle+3.0, 4)
}

set_player_nextattack(id, Float:nexttime)
{
	set_pdata_float(id, 83, nexttime, 4)
}


set_player_animation(index, sequence, Float: framerate = 1.0)
{
	set_pev(index, pev_animtime, get_gametime())
	set_pev(index, pev_framerate,  framerate)
	set_pev(index, pev_frame, 0.0)
	set_pev(index, pev_sequence, sequence)
}  
