#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>
#include <hamsandwich>
#include <cstrike>
#include <fun>
#include <zombie_theheroex>

#define PLUGIN "[ZBHeroEx] Primary: Thunderbolt"
#define VERSION "2.0"
#define AUTHOR "Dias"

#define CSW_THUNDERBOLT CSW_AWP
#define weapon_thunderbolt "weapon_awp"
#define old_event "events/awp.sc"
#define old_w_model "models/w_awp.mdl"
#define WEAPON_SECRETCODE 4234234

#define DEFAULT_AMMO 20
#define RELOAD_TIME 2.67
#define DAMAGE 480

#define ZOOM_DELAY 0.5
#define ZOOM_DELAY2 0.1

new const v_model[] = "models/zombie_thehero/weapon/pri/v_sfsniper2.mdl"
new const p_model[] = "models/zombie_thehero/weapon/pri/p_sfsniper.mdl"
new const w_model[] = "models/zombie_thehero/weapon/pri/w_sfsniper.mdl"
new const weapon_sound[5][] = 
{
	"weapons/sfsniper-1.wav",
	"weapons/sfsniper_insight1.wav",
	"weapons/sfsniper_zoom.wav",
	"weapons/sfsniper_idle.wav",
	"weapons/sfsniper_draw.wav"
}


new const WeaponResource[4][] = 
{
	"sprites/weapon_sfsniper.txt",
	"sprites/640hud2_2.spr",
	"sprites/640hud10_2.spr",
	"sprites/640hud81_2.spr"
}

enum
{
	TB_ANIM_IDLE = 0,
	TB_ANIM_SHOOT,
	TB_ANIM_DRAW
}

new g_Thunderbolt
new g_had_thunderbolt[33], g_thunderbolt_ammo[33], g_Shoot_Count[33], Float:StartOrigin2[3], Float:EndOrigin2[3],
Float:g_thunderbolt_zoomdelay[33]//, Float:g_thunderbolt_zoomdelay2[33], Float:g_thunderbolt_zoomdelay3[33]
new g_old_weapon[33], g_smokepuff_id, m_iBlood[2], g_event_thunderbolt//, g_scope_hud
new g_Beam_SprId, Float:g_can_laser[33]

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	
	register_forward(FM_CmdStart, "fw_CmdStart")
	register_forward(FM_SetModel, "fw_SetModel")
	register_forward(FM_UpdateClientData, "fw_UpdateClientData_Post", 1)	
	register_forward(FM_PlaybackEvent, "fw_PlaybackEvent")		
	
	RegisterHam(Ham_Item_AddToPlayer, weapon_thunderbolt, "fw_AddToPlayer_Post", 1)
	RegisterHam(Ham_TraceAttack, "worldspawn", "fw_TraceAttack2")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack")
	RegisterHam(Ham_TraceAttack, "player", "fw_TraceAttack_Post", 1)

	//g_scope_hud = CreateHudSyncObj(1962)
	register_clcmd("weapon_sfsniper", "hook_weapon")
}

public plugin_precache()
{
	precache_model(v_model)
	precache_model(p_model)
	precache_model(w_model)
	
	for(new i = 0; i < sizeof(weapon_sound); i++) 
		precache_sound(weapon_sound[i])
		
	precache_generic(WeaponResource[0])
	for(new i = 1; i < sizeof(WeaponResource); i++)
		precache_model(WeaponResource[i])
	
	g_smokepuff_id = engfunc(EngFunc_PrecacheModel, "sprites/wall_puff1.spr")
	m_iBlood[0] = precache_model("sprites/blood.spr")
	m_iBlood[1] = precache_model("sprites/bloodspray.spr")	
	g_Beam_SprId = precache_model("sprites/laserbeam.spr")
	
	register_forward(FM_PrecacheEvent, "fw_PrecacheEvent_Post", 1)	
	g_Thunderbolt = zbheroex_register_weapon("Thunderbolt", WEAPON_PRIMARY, CSW_THUNDERBOLT, 14999)
}

new g_register
public client_putinserver(id)
{
	if(!g_register && is_user_bot(id))
	{
		g_register = 0
		set_task(0.1, "do_register", id, _, _, "b")
	}
}

public do_register(id)
{
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack")
	RegisterHamFromEntity(Ham_TraceAttack, id, "fw_TraceAttack_Post", 1)
}

public fw_PrecacheEvent_Post(type, const name[])
{
	if(equal(old_event, name))
		g_event_thunderbolt = get_orig_retval()
}

public hook_weapon(id)
{
	engclient_cmd(id, weapon_thunderbolt)
	return
}

public zbheroex_weapon_bought(id, ItemID)
{
	if(ItemID == g_Thunderbolt) get_thunderbolt(id)
}

public zbheroex_weapon_remove(id, ItemID)
{
	if(ItemID == g_Thunderbolt) remove_thunderbolt(id)
}

public remove_thunderbolt(id)
{
	g_had_thunderbolt[id] = 0
	g_thunderbolt_ammo[id] = 0
}

public get_thunderbolt(id)
{
	if(!is_user_alive(id))
		return
		
	g_had_thunderbolt[id] = 1
	g_thunderbolt_ammo[id] = DEFAULT_AMMO
	
	give_item(id, weapon_thunderbolt)
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_thunderbolt, id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)
}

public fw_UpdateClientData_Post(id, sendweapons, cd_handle)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED	
	if(get_user_weapon(id) == CSW_THUNDERBOLT && g_had_thunderbolt[id])
		set_cd(cd_handle, CD_flNextAttack, get_gametime() + 0.001) 
	
	return FMRES_HANDLED
}

public fw_PlaybackEvent(flags, invoker, eventid, Float:delay, Float:origin[3], Float:angles[3], Float:fparam1, Float:fparam2, iParam1, iParam2, bParam1, bParam2)
{
	if (!is_user_connected(invoker))
		return FMRES_IGNORED		
	if(get_user_weapon(invoker) == CSW_THUNDERBOLT && g_had_thunderbolt[invoker] && eventid == g_event_thunderbolt)
	{
		engfunc(EngFunc_PlaybackEvent, flags | FEV_HOSTONLY, invoker, eventid, delay, origin, angles, fparam1, fparam2, iParam1, iParam2, bParam1, bParam2)	

		set_weapon_anim(invoker, TB_ANIM_SHOOT)
		emit_sound(invoker, CHAN_WEAPON, weapon_sound[0], 1.0, ATTN_NORM, 0, PITCH_NORM)	

		return FMRES_SUPERCEDE
	}
	
	return FMRES_HANDLED
}

public Event_CurWeapon(id)
{
	if(!is_user_alive(id))
		return
		
	if(get_user_weapon(id) == CSW_THUNDERBOLT && g_had_thunderbolt[id])
	{
		set_pev(id, pev_viewmodel2, cs_get_user_zoom(id) == 1 ? v_model : "")
		set_pev(id, pev_weaponmodel2, p_model)
		
		if(g_old_weapon[id] != CSW_THUNDERBOLT) set_weapon_anim(id, TB_ANIM_DRAW)
		update_ammo(id)
	} else if(get_user_weapon(id) != CSW_THUNDERBOLT && g_old_weapon[id] == CSW_THUNDERBOLT) {
		cs_set_user_zoom(id, 1, 1)
	}
	
	g_old_weapon[id] = get_user_weapon(id)
}

public fw_CmdStart(id, uc_handle, seed)
{
	if(!is_user_alive(id) || !is_user_connected(id))
		return FMRES_IGNORED
	if(get_user_weapon(id) != CSW_THUNDERBOLT || !g_had_thunderbolt[id])
		return FMRES_IGNORED
	
	static CurButton
	CurButton = get_uc(uc_handle, UC_Buttons)
	
	if(CurButton & IN_ATTACK)
	{
		CurButton &= ~IN_ATTACK
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		thunderbolt_shoothandle(id)
	}
	if(CurButton & IN_ATTACK2) 
	{
		CurButton &= ~IN_ATTACK2
		set_uc(uc_handle, UC_Buttons, CurButton)
		
		if(get_gametime() - ZOOM_DELAY > g_thunderbolt_zoomdelay[id])
		{
			if(get_pdata_float(id, 83, 5) <= 0.0)
			{
				if(cs_get_user_zoom(id) == 1)
				{
					cs_set_user_zoom(id, CS_SET_FIRST_ZOOM, 1)
				} else {
					cs_set_user_zoom(id, 1, 1)
				}
					
				emit_sound(id, CHAN_ITEM, weapon_sound[2], 1.0, ATTN_NORM, 0, PITCH_NORM)
			}
			g_thunderbolt_zoomdelay[id] = get_gametime()
		}
	}
	
	/*
	if(get_gametime() - ZOOM_DELAY2 > g_thunderbolt_zoomdelay2[id])
	{
		if(cs_get_user_zoom(id) == CS_SET_FIRST_ZOOM)
		{
			static Body, Target
			get_user_aiming(id, Target, Body, 99999999)
			
			if(!is_user_alive(Target))
			{
				set_hudmessage(0, 200, 0, -1.0, -1.0, 0, 0.1, 0.1)
			} else {
				set_hudmessage(255, 0, 0, -1.0, -1.0, 0, 0.1, 0.1)
				
				if(get_gametime() - ZOOM_DELAY > g_thunderbolt_zoomdelay3[id])
				{
					emit_sound(id, CHAN_ITEM, weapon_sound[1], 1.0, ATTN_NORM, 0, PITCH_NORM)
					g_thunderbolt_zoomdelay3[id] = get_gametime()
				}	
			}
			
			ShowSyncHudMsg(id, g_scope_hud, "|^n-- + --^n|")
		} else {
			set_hudmessage(0, 200, 0, -1.0, -1.0, 0, 0.1, 0.1)
			ShowSyncHudMsg(id, g_scope_hud, "")
		}
			
		g_thunderbolt_zoomdelay2[id] = get_gametime()
	}*/
	
	return FMRES_HANDLED
}

public thunderbolt_shoothandle(id)
{
	if(get_pdata_float(id, 83, 5) <= 0.0 && g_thunderbolt_ammo[id] > 0)
	{
		g_thunderbolt_ammo[id]--
		g_Shoot_Count[id] = 0
		update_ammo(id)
		
		Stock_Get_Postion(id, 50.0, 10.0, 5.0, StartOrigin2)
		
		set_task(0.1, "Create_Laser", id)
		
		static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_thunderbolt, id)
		if(pev_valid(weapon_ent)) ExecuteHamB(Ham_Weapon_PrimaryAttack, weapon_ent)
		set_player_nextattack(id, CSW_THUNDERBOLT, RELOAD_TIME)
		
		// Reset Weapon
		cs_set_user_zoom(id, 1, 1)

		//set_hudmessage(0, 200, 0, -1.0, -1.0, 0, 0.1, 0.1)
	//	ShowSyncHudMsg(id, g_scope_hud, "")
	}
}

public Create_Laser(id)
{
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
	write_byte(TE_BEAMPOINTS)
	engfunc(EngFunc_WriteCoord, StartOrigin2[0])
	engfunc(EngFunc_WriteCoord, StartOrigin2[1])
	engfunc(EngFunc_WriteCoord, StartOrigin2[2] - 10.0)
	engfunc(EngFunc_WriteCoord, EndOrigin2[0])
	engfunc(EngFunc_WriteCoord, EndOrigin2[1])
	engfunc(EngFunc_WriteCoord, EndOrigin2[2])
	write_short(g_Beam_SprId)
	write_byte(0)
	write_byte(0)
	write_byte(30)
	write_byte(25)
	write_byte(0)
	write_byte(0)
	write_byte(0)
	write_byte(255)
	write_byte(255)
	write_byte(0)
	message_end()	
}

public fw_SetModel(entity, model[])
{
	if(!pev_valid(entity))
		return FMRES_IGNORED
	
	static Classname[64]
	pev(entity, pev_classname, Classname, sizeof(Classname))
	
	if(!equal(Classname, "weaponbox"))
		return FMRES_IGNORED
	
	static id
	id = pev(entity, pev_owner)
	
	if(equal(model, old_w_model))
	{
		static weapon
		weapon = fm_get_user_weapon_entity(entity, CSW_THUNDERBOLT)
		
		if(!pev_valid(weapon))
			return FMRES_IGNORED
		
		if(g_had_thunderbolt[id])
		{
			set_pev(weapon, pev_impulse, WEAPON_SECRETCODE)
			set_pev(weapon, pev_iuser4, g_thunderbolt_ammo[id])
			engfunc(EngFunc_SetModel, entity, w_model)
			
			g_had_thunderbolt[id] = 0
			g_thunderbolt_ammo[id] = 0
			
			return FMRES_SUPERCEDE
		}
	}

	return FMRES_IGNORED;
}

public fw_AddToPlayer_Post(ent, id)
{
	if(pev(ent, pev_impulse) == WEAPON_SECRETCODE)
	{
		g_had_thunderbolt[id] = 1
		g_thunderbolt_ammo[id] = pev(ent, pev_iuser4)
		
		set_pev(ent, pev_impulse, 0)
	}			
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("WeaponList"), _, id)
	write_string((g_had_thunderbolt[id] == 1 ? "weapon_sfsniper" : "weapon_awp"))
	write_byte(1)
	write_byte(30)
	write_byte(-1)
	write_byte(-1)
	write_byte(0)
	write_byte(2)
	write_byte(CSW_THUNDERBOLT)
	write_byte(0)
	message_end()
}

public fw_TraceAttack(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_THUNDERBOLT || !g_had_thunderbolt[attacker])
		return HAM_IGNORED
		
	SetHamParamFloat(3, float(DAMAGE))	
	
	return HAM_IGNORED
}

public fw_TraceAttack_Post(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_THUNDERBOLT || !g_had_thunderbolt[attacker])
		return HAM_IGNORED

	static Float:flEnd[3]
	get_tr2(ptr, TR_vecEndPos, flEnd)
	
	EndOrigin2 = flEnd
	
	return HAM_HANDLED
}

public fw_TraceAttack2(ent, attacker, Float:Damage, Float:fDir[3], ptr, iDamageType)
{
	if(!is_user_alive(attacker))
		return HAM_IGNORED	
	if(get_user_weapon(attacker) != CSW_THUNDERBOLT || !g_had_thunderbolt[attacker])
		return HAM_IGNORED
		
	if(get_gametime() - 0.1 > g_can_laser[attacker])
	{
		static Float:flEnd[3]
			
		get_tr2(ptr, TR_vecEndPos, flEnd)	
		EndOrigin2 = flEnd
		
		make_bullet(attacker, flEnd)
		fake_smoke(attacker, ptr)

		g_can_laser[attacker] = get_gametime()
	}

	return HAM_HANDLED
}

public update_ammo(id)
{
	if(!is_user_alive(id))
		return
	
	static weapon_ent; weapon_ent = fm_find_ent_by_owner(-1, weapon_thunderbolt, id)
	if(pev_valid(weapon_ent)) cs_set_weapon_ammo(weapon_ent, 1)	
	
	cs_set_user_bpammo(id, CSW_THUNDERBOLT, 0)
	
	engfunc(EngFunc_MessageBegin, MSG_ONE_UNRELIABLE, get_user_msgid("CurWeapon"), {0, 0, 0}, id)
	write_byte(1)
	write_byte(CSW_THUNDERBOLT)
	write_byte(-1)
	message_end()
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("AmmoX"), _, id)
	write_byte(1)
	write_byte(g_thunderbolt_ammo[id])
	message_end()
}

stock set_weapon_anim(id, anim)
{
	if(!is_user_alive(id))
		return
	
	set_pev(id, pev_weaponanim, anim)
	
	message_begin(MSG_ONE_UNRELIABLE, SVC_WEAPONANIM, {0, 0, 0}, id)
	write_byte(anim)
	write_byte(pev(id, pev_body))
	message_end()
}


stock set_player_light(id, const LightStyle[])
{
	if(!is_user_alive(id))
		return
		
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, .player = id)
	write_byte(0)
	write_string(LightStyle)
	message_end()
}

stock make_bullet(id, Float:Origin[3])
{
	// Find target
	new decal = random_num(41, 45)
	const loop_time = 2
	
	static Body, Target
	get_user_aiming(id, Target, Body, 999999)
	
	if(is_user_connected(Target))
		return
	
	for(new i = 0; i < loop_time; i++)
	{
		// Put decal on "world" (a wall)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_WORLDDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_byte(decal)
		message_end()
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		engfunc(EngFunc_WriteCoord, Origin[0])
		engfunc(EngFunc_WriteCoord, Origin[1])
		engfunc(EngFunc_WriteCoord, Origin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

public fake_smoke(id, trace_result)
{
	static Float:vecSrc[3], Float:vecEnd[3], TE_FLAG
	
	get_weapon_attachment(id, vecSrc)
	global_get(glb_v_forward, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 8192.0, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)

	get_tr2(trace_result, TR_vecEndPos, vecSrc)
	get_tr2(trace_result, TR_vecPlaneNormal, vecEnd)
    
	xs_vec_mul_scalar(vecEnd, 2.5, vecEnd)
	xs_vec_add(vecSrc, vecEnd, vecEnd)
    
	TE_FLAG |= TE_EXPLFLAG_NODLIGHTS
	TE_FLAG |= TE_EXPLFLAG_NOSOUND
	TE_FLAG |= TE_EXPLFLAG_NOPARTICLES
	
	engfunc(EngFunc_MessageBegin, MSG_PAS, SVC_TEMPENTITY, vecEnd, 0)
	write_byte(TE_EXPLOSION)
	engfunc(EngFunc_WriteCoord, vecEnd[0])
	engfunc(EngFunc_WriteCoord, vecEnd[1])
	engfunc(EngFunc_WriteCoord, vecEnd[2] - 10.0)
	write_short(g_smokepuff_id)
	write_byte(2)
	write_byte(50)
	write_byte(TE_FLAG)
	message_end()	
}

stock Stock_Get_Postion(id,Float:forw,Float:right, Float:up,Float:vStart[])
{
	new Float:vOrigin[3], Float:vAngle[3], Float:vForward[3], Float:vRight[3], Float:vUp[3]
	
	pev(id, pev_origin, vOrigin)
	pev(id, pev_view_ofs,vUp) //for player
	xs_vec_add(vOrigin,vUp,vOrigin)
	pev(id, pev_v_angle, vAngle) // if normal entity ,use pev_angles
	
	angle_vector(vAngle,ANGLEVECTOR_FORWARD,vForward) //or use EngFunc_AngleVectors
	angle_vector(vAngle,ANGLEVECTOR_RIGHT,vRight)
	angle_vector(vAngle,ANGLEVECTOR_UP,vUp)
	
	vStart[0] = vOrigin[0] + vForward[0] * forw + vRight[0] * right + vUp[0] * up
	vStart[1] = vOrigin[1] + vForward[1] * forw + vRight[1] * right + vUp[1] * up
	vStart[2] = vOrigin[2] + vForward[2] * forw + vRight[2] * right + vUp[2] * up
} 

stock get_weapon_attachment(id, Float:output[3], Float:fDis = 40.0)
{ 
	new Float:vfEnd[3], viEnd[3] 
	get_user_origin(id, viEnd, 3)  
	IVecFVec(viEnd, vfEnd) 
	
	new Float:fOrigin[3], Float:fAngle[3]
	
	pev(id, pev_origin, fOrigin) 
	pev(id, pev_view_ofs, fAngle)
	
	xs_vec_add(fOrigin, fAngle, fOrigin) 
	
	new Float:fAttack[3]
	
	xs_vec_sub(vfEnd, fOrigin, fAttack)
	xs_vec_sub(vfEnd, fOrigin, fAttack) 
	
	new Float:fRate
	
	fRate = fDis / vector_length(fAttack)
	xs_vec_mul_scalar(fAttack, fRate, fAttack)
	
	xs_vec_add(fOrigin, fAttack, output)
}

stock create_blood(const Float:origin[3])
{
	// Show some blood :)
	message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
	write_byte(TE_BLOODSPRITE)
	engfunc(EngFunc_WriteCoord, origin[0])
	engfunc(EngFunc_WriteCoord, origin[1])
	engfunc(EngFunc_WriteCoord, origin[2])
	write_short(m_iBlood[1])
	write_short(m_iBlood[0])
	write_byte(75)
	write_byte(5)
	message_end()
}

stock set_player_screenfade(pPlayer, sDuration = 0, sHoldTime = 0, sFlags = 0, r = 0, g = 0, b = 0, a = 0 )
{
	if(!is_user_connected(pPlayer))
		return
	
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("ScreenFade"), _, pPlayer)
	write_short(sDuration)
	write_short(sHoldTime)
	write_short(sFlags)
	write_byte(r)
	write_byte(g)
	write_byte(b)
	write_byte(a)
	message_end()
}

stock set_player_nextattack(player, weapon_id, Float:NextTime)
{
	if(!is_user_alive(player))
		return
	
	const m_flNextPrimaryAttack = 46
	const m_flNextSecondaryAttack = 47
	const m_flTimeWeaponIdle = 48
	const m_flNextAttack = 83
	
	static weapon
	weapon = fm_get_user_weapon_entity(player, weapon_id)
	
	set_pdata_float(player, m_flNextAttack, NextTime, 5)
	if(pev_valid(weapon))
	{
		set_pdata_float(weapon, m_flNextPrimaryAttack , NextTime, 4)
		set_pdata_float(weapon, m_flNextSecondaryAttack, NextTime, 4)
		set_pdata_float(weapon, m_flTimeWeaponIdle, NextTime, 4)
	}
}
