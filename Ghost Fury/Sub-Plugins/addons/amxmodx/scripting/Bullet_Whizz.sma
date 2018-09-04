#include <amxmodx>
#include <fakemeta>
#include <engine>
#include <xs>

#define MAX_SOUNDS	5
new g_BulletSounds[MAX_SOUNDS][] = 
{ 
	"misc/whizz1.wav",	
	"misc/whizz2.wav", 	
	"misc/whizz3.wav",	
	"misc/whizz4.wav",	
	"misc/whizz5.wav"
}

new g_LastWeapon[33]
new g_LastAmmo[33]

new PLUGIN_NAME[] 	= "Bullet Whizz"
new PLUGIN_AUTHOR[] 	= "Cheap_Suit"
new PLUGIN_VERSION[] 	= "1.4"

public plugin_init() 
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR)
	register_event("CurWeapon", "Event_CurWeapon", "be", "1=1")
	register_cvar("amx_bulletwhizz_dis", "40")
	register_cvar("amx_bulletwhizz", "1")
}

public plugin_precache()
{
	for(new i = 0; i < MAX_SOUNDS; ++i) {	
		precache_sound(g_BulletSounds[i])
	}
}

public Event_CurWeapon(id) 
{
	if(!get_cvar_num("amx_bulletwhizz") || !is_user_connected(id) || !is_user_alive(id)) {
		return PLUGIN_CONTINUE
	}
	
	new WeaponID = read_data(2), Clip = read_data(3)
	switch(WeaponID) {
		case CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE, CSW_C4, CSW_KNIFE: return PLUGIN_CONTINUE
	}
	
	if(g_LastWeapon[id] == WeaponID && g_LastAmmo[id] > Clip)
	{
		new Players[32], iNum
		get_players(Players, iNum, "a")
		for(new i = 0; i < iNum; ++i) if(id != Players[i])
		{
			new target = Players[i]
			new Float:fOrigin[2][3], temp[3], Float:fAim[3]
			entity_get_vector(id, EV_VEC_origin, fOrigin[0])
			entity_get_vector(target, EV_VEC_origin, fOrigin[1])
			
			get_user_origin(id, temp, 3)
			IVecFVec(temp, fAim)
			
			new iDistance = get_distance_to_line(fOrigin[0], fOrigin[1], fAim)
			if(iDistance > get_cvar_num("amx_bulletwhizz_dis") || iDistance < 0 
			|| !fm_is_ent_visible(id, target)) {
				continue
			}

			new RandomSound[64]
			format(RandomSound, 63, "%s", g_BulletSounds[random_num(0, MAX_SOUNDS-1)]) 
			client_cmd(target, "spk %s", RandomSound)
		}
	}
	g_LastWeapon[id] = WeaponID
	g_LastAmmo[id] = Clip
	
	return PLUGIN_CONTINUE
}

stock get_distance_to_line(Float:pos_start[3], Float:pos_end[3], Float:pos_object[3])  
{  
	new Float:vec_start_end[3], Float:vec_start_object[3], Float:vec_end_object[3], Float:vec_end_start[3] 
	xs_vec_sub(pos_end, pos_start, vec_start_end) // vector from start to end 
	xs_vec_sub(pos_object, pos_start, vec_start_object) // vector from end to object 
	xs_vec_sub(pos_start, pos_end, vec_end_start) // vector from end to start 
	xs_vec_sub(pos_end, pos_object, vec_end_object) // vector object to end 
	
	new Float:len_start_object = getVecLen(vec_start_object) 
	new Float:angle_start = floatacos(xs_vec_dot(vec_start_end, vec_start_object) / (getVecLen(vec_start_end) * len_start_object), degrees)  
	new Float:angle_end = floatacos(xs_vec_dot(vec_end_start, vec_end_object) / (getVecLen(vec_end_start) * getVecLen(vec_end_object)), degrees)  

	if(angle_start <= 90.0 && angle_end <= 90.0) 
		return floatround(len_start_object * floatsin(angle_start, degrees)) 
	return -1  
}

stock Float:getVecLen(Float:Vec[3])
{ 
	new Float:VecNull[3] = {0.0, 0.0, 0.0}
	new Float:len = get_distance_f(Vec, VecNull)
	return len
} 

stock bool:fm_is_ent_visible(index, entity) 
{
	new Float:origin[3], Float:view_ofs[3], Float:eyespos[3]
	pev(index, pev_origin, origin)
	pev(index, pev_view_ofs, view_ofs)
	xs_vec_add(origin, view_ofs, eyespos)

	new Float:entpos[3]
	pev(entity, pev_origin, entpos)
	engfunc(EngFunc_TraceLine, eyespos, entpos, 0, index)

	switch (pev(entity, pev_solid)) {
		case SOLID_BBOX..SOLID_BSP: return global_get(glb_trace_ent) == entity
	}

	new Float:fraction
	global_get(glb_trace_fraction, fraction)
	if (fraction == 1.0)
		return true

	return false
}
