#include <amxmodx>
#include <engine>
#include <fakemeta>
#include <fakemeta_util>

#define PLUGIN "[ZBHeroEx] Addon: Attachment"
#define VERSION "1.0"
#define AUTHOR "Dias"

#define MAX_CHANNEL 5
#define ATTACHMENT_CLASSNAME "attachment"

const pev_user = pev_iuser1
const pev_livetime = pev_fuser1
const pev_totalframe = pev_fuser2

new g_MyAttachment[33][MAX_CHANNEL]

public plugin_init() 
{
	register_plugin(PLUGIN, VERSION, AUTHOR)
	
	register_event("HLTV", "Event_NewRound", "a", "1=0", "2=0")
	register_think(ATTACHMENT_CLASSNAME, "fw_Think")
}

public plugin_natives()
{
	register_native("zbheroex_show_attachment", "Native_ShowAttachment", 1)
}

public Native_ShowAttachment(id, const Sprite[], Float:Time, Float:Scale, Float:FrameRate, TotalFrame)
{
	param_convert(2)
	Show_Attachment(id, Sprite, Time, Scale, FrameRate, TotalFrame)
}

public Event_NewRound() remove_entity_name(ATTACHMENT_CLASSNAME)
public Show_Attachment(id, const Sprite[],  Float:Time, Float:Scale, Float:FrameRate, TotalFrame)
{
	if(!is_user_alive(id))
		return

	static channel; channel = 0
	for(new i = 0; i < MAX_CHANNEL; i++)
	{
		if(pev_valid(g_MyAttachment[id][i])) channel++
		else {
			channel = i
			break
		}
	}
	if(channel >= MAX_CHANNEL) return
	if(!pev_valid(g_MyAttachment[id][channel]))
		g_MyAttachment[id][channel] = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	if(!pev_valid(g_MyAttachment[id][channel]))
		return
		
	// Set Properties
	set_pev(g_MyAttachment[id][channel], pev_takedamage, DAMAGE_NO)
	set_pev(g_MyAttachment[id][channel], pev_solid, SOLID_NOT)
	set_pev(g_MyAttachment[id][channel], pev_movetype, MOVETYPE_FOLLOW)
	
	// Set Sprite
	set_pev(g_MyAttachment[id][channel], pev_classname, ATTACHMENT_CLASSNAME)
	engfunc(EngFunc_SetModel, g_MyAttachment[id][channel], Sprite)
	
	// Set Rendering
	set_pev(g_MyAttachment[id][channel], pev_renderfx, kRenderFxNone)
	set_pev(g_MyAttachment[id][channel], pev_rendermode, kRenderTransAdd)
	set_pev(g_MyAttachment[id][channel], pev_renderamt, 200.0)
	
	// Set other
	set_pev(g_MyAttachment[id][channel], pev_user, id)
	set_pev(g_MyAttachment[id][channel], pev_scale, Scale)
	set_pev(g_MyAttachment[id][channel], pev_livetime, get_gametime() + Time)
	set_pev(g_MyAttachment[id][channel], pev_totalframe, float(TotalFrame))
	
	// Set Origin
	static Float:Origin[3]; pev(id, pev_origin, Origin)
	if(!(pev(id, pev_flags) & FL_DUCKING)) Origin[2] += 25.0
	else Origin[2] += 20.0
	
	engfunc(EngFunc_SetOrigin, g_MyAttachment[id][channel], Origin)
	
	// Allow animation of sprite ?
	if(TotalFrame && FrameRate > 0.0)
	{
		set_pev(g_MyAttachment[id][channel], pev_animtime, get_gametime())
		set_pev(g_MyAttachment[id][channel], pev_framerate, FrameRate + 9.0)
		
		set_pev(g_MyAttachment[id][channel], pev_spawnflags, SF_SPRITE_STARTON)
		dllfunc(DLLFunc_Spawn, g_MyAttachment[id][channel])
	}	
	
	// Force Think
	set_pev(g_MyAttachment[id][channel], pev_nextthink, get_gametime() + 0.05)
}

public fw_Think(Ent)
{
	if(!pev_valid(Ent))
		return
		
	static Owner; Owner = pev(Ent, pev_user)
	if(!is_user_alive(Owner))
	{
		engfunc(EngFunc_RemoveEntity, Ent)
		return
	}
	if(get_gametime() >= pev(Ent, pev_livetime))
	{
		if(pev(Ent, pev_renderamt) > 0.0)
		{
			static Float:AMT; pev(Ent, pev_renderamt, AMT)
			static Float:RealAMT; 
			
			AMT -= 10.0
			RealAMT = float(max(floatround(AMT), 0))
			
			set_pev(Ent, pev_renderamt, RealAMT)
		} else {
			engfunc(EngFunc_RemoveEntity, Ent)
			return
		}
	}
	if (pev(Ent, pev_frame) >= pev(Ent, pev_totalframe)) set_pev(Ent, pev_frame, 0.0)
	
	// Set Attachment
	static Float:Origin[3]; pev(Owner, pev_origin, Origin)
	
	if(!(pev(Owner, pev_flags) & FL_DUCKING)) Origin[2] += 25.0
	else Origin[2] += 20.0
	
	engfunc(EngFunc_SetOrigin, Ent, Origin)
	
	// Force Think
	set_pev(Ent, pev_nextthink, get_gametime() + 0.05)
}
/* AMXX-Studio Notes - DO NOT MODIFY BELOW HERE
*{\\ rtf1\\ ansi\\ deff0{\\ fonttbl{\\ f0\\ fnil Tahoma;}}\n\\ viewkind4\\ uc1\\ pard\\ lang1033\\ f0\\ fs16 \n\\ par }
*/
