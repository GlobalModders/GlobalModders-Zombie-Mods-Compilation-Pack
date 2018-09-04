#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <hamsandwich>

#define PLUGIN "Weapon Misc"
#define VERSION "1.0"
#define AUTHOR "Dias"

new Float:g_last_fire[33]
new g_blood, g_bloodspray
new const GUNSHOT_DECALS[] = {41}	// Gunshot decal list

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_forward(FM_CmdStart, "fw_cmdstart")
}

public plugin_precache()
{
	g_blood = precache_model("sprites/blood.spr")
	g_bloodspray = precache_model("sprites/bloodspray.spr")	
}

public fw_cmdstart(id, uc_handle, seed)
{
	if(!is_user_alive(id))
		return FMRES_IGNORED
		
	static buttons, Float:Time, wpn_id, fInReload, ent, curweapon, clip, ammo
	
	buttons = get_uc(uc_handle, UC_Buttons)
	Time = get_gametime()
	curweapon = get_user_weapon(id, clip, ammo)
	
	if(clip == 0)
		return FMRES_IGNORED
	
	if(curweapon == CSW_ELITE)
	{
		ent = find_ent_by_owner(-1, "weapon_elite", id)
		fInReload = get_pdata_int(ent, 54, 4)
	
		if(fInReload)
			return FMRES_IGNORED
		
		if(buttons & IN_ATTACK2)
		{
			if(Time - 0.1 > g_last_fire[id])
			{
				wpn_id = get_weapon_ent(id, get_user_weapon(id))
				
				ExecuteHam(Ham_Weapon_PrimaryAttack, wpn_id)
				ExecuteHam(Ham_Weapon_SecondaryAttack, wpn_id)
				
				testbulet(id)
				
				static random1
				random1 = random_num(0,1)
				
				if(random1 == 0)
				{
					play_weapon_anim(id, 2)
				} else {
					play_weapon_anim(id, 8)
				}
				
				emit_sound(id, CHAN_WEAPON, "weapons/elite_fire.wav", 1.0, ATTN_NORM, 0, PITCH_NORM)
				
				g_last_fire[id] = Time
			}
		}
	}
		
	return FMRES_HANDLED
}

//hit bulet 
public testbulet(id){
	// Find target
	new aimOrigin[3], target, body
	get_user_origin(id, aimOrigin, 3)
	get_user_aiming(id, target, body)
	
	if(target > 0 && target <= get_maxplayers())
	{
		new Float:fStart[3], Float:fEnd[3], Float:fRes[3], Float:fVel[3]
		pev(id, pev_origin, fStart)
		
		// Get ids view direction
		velocity_by_aim(id, 64, fVel)
		
		// Calculate position where blood should be displayed
		fStart[0] = float(aimOrigin[0])
		fStart[1] = float(aimOrigin[1])
		fStart[2] = float(aimOrigin[2])
		fEnd[0] = fStart[0]+fVel[0]
		fEnd[1] = fStart[1]+fVel[1]
		fEnd[2] = fStart[2]+fVel[2]
		
		// Draw traceline from victims origin into ids view direction to find
		// the location on the wall to put some blood on there
		new res
		engfunc(EngFunc_TraceLine, fStart, fEnd, 0, target, res)
		get_tr2(res, TR_vecEndPos, fRes)
				
		// Show some blood :)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY) 
		write_byte(TE_BLOODSPRITE)
		write_coord(floatround(fStart[0])) 
		write_coord(floatround(fStart[1])) 
		write_coord(floatround(fStart[2])) 
		write_short(g_bloodspray)
		write_short(g_blood)
		write_byte(70)
		write_byte(random_num(1,2))
		message_end()
		
		
	} else {
		new decal = GUNSHOT_DECALS[random_num(0, sizeof(GUNSHOT_DECALS) - 1)]
		
		// Check if the wall hit is an entity
		if(target)
		{
			// Put decal on an entity
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_DECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(decal)
			write_short(target)
			message_end()
		} else {
			// Put decal on "world" (a wall)
			message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
			write_byte(TE_WORLDDECAL)
			write_coord(aimOrigin[0])
			write_coord(aimOrigin[1])
			write_coord(aimOrigin[2])
			write_byte(decal)
			message_end()
		}
		
		// Show sparcles
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_GUNSHOTDECAL)
		write_coord(aimOrigin[0])
		write_coord(aimOrigin[1])
		write_coord(aimOrigin[2])
		write_short(id)
		write_byte(decal)
		message_end()
	}
}

get_weapon_ent(id, weaponid)
{
	static wname[32], weapon_ent
	get_weaponname(weaponid, wname, charsmax(wname))
	weapon_ent = fm_find_ent_by_owner(-1, wname, id)
	return weapon_ent
}
public play_weapon_anim(player, anim)
{
	set_pev(player, pev_weaponanim, anim)
	message_begin(MSG_ONE, SVC_WEAPONANIM, {0, 0, 0}, player)
	write_byte(anim)
	write_byte(pev(player, pev_body))
	message_end()
}

stock fm_find_ent_by_owner(index, const classname[], owner, jghgtype = 0) {
	new strtype[11] = "classname", ent = index;
	switch (jghgtype) {
		case 1: strtype = "target";
		case 2: strtype = "targetname";
	}

	while ((ent = engfunc(EngFunc_FindEntityByString, ent, strtype, classname)) && pev(ent, pev_owner) != owner) {}

	return ent;
}
