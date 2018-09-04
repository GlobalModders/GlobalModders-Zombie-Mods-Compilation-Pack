#include <amxmodx>
#include <fakemeta>

#define PLUGIN	"[Bio] Addon: ModelIndex Update"
#define VERSION	"1.0"
#define AUTHOR	"Dias"

new const DBUG_PLAYER_MODEL[][] = { 
	"arctic",
	"davidblack",
	"gign",
	"leon1",
	"gsg9",
	//"spetsnaz",
	"guerilla",
	//"stalker_human",
	"leet",
	"umbrella1",
	"sas",
	"terror",
	"urban",
	"flesher",
	"speed_zombi_origin",
	"stamper_zombi",
	"tank_zombi_host",
	"witch_zombi_origin",
	"zombie_source",
	"zombie_nemesis_new"
}

new modelindex[sizeof DBUG_PLAYER_MODEL]
new g_player_model[33][32]
new debug_ing[33]

const OFFSET_MODELINDEX = 491
const OFFSET_LINUX = 5

public plugin_init()
{
	register_plugin(PLUGIN, VERSION, AUTHOR);
	
	register_forward(FM_ClientUserInfoChanged, "fw_ClientUserInfoChanged")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink")
}

public plugin_precache()
{
	new i, model[100]
	for (i = 0; i < sizeof DBUG_PLAYER_MODEL; i++)
	{
		format(model, charsmax(model), "models/player/%s/%s.mdl", DBUG_PLAYER_MODEL[i], DBUG_PLAYER_MODEL[i])
		modelindex[i] = precache_model(model)
	}
}

public fw_ClientUserInfoChanged(id)
{
	static current_model[32]
	fm_get_user_model(id, current_model, sizeof current_model - 1)
	
	new DefinePlayerModels = sizeof DBUG_PLAYER_MODEL
	new index = random_num(0, DefinePlayerModels - 1)
	copy(g_player_model[id], sizeof g_player_model[] - 1, DBUG_PLAYER_MODEL[index])
	
	if (equal(current_model, g_player_model[id]))
	{
		debug_ing[id] = true
		fm_set_user_model(id, g_player_model[id])
		fm_set_user_model_index(id, modelindex[index])
	}
	else
		debug_ing[id] = false
}

public fw_PlayerPreThink(id)
{
	if (is_user_alive(id))
	{
		new DefinePlayerModels = sizeof DBUG_PLAYER_MODEL
		if (DefinePlayerModels > 0)
		{
			fm_get_user_model(id, g_player_model[id], sizeof g_player_model[] - 1)
			
			new index = random_num(0, DefinePlayerModels - 1)
			copy(g_player_model[id], sizeof g_player_model[] - 1, DBUG_PLAYER_MODEL[index])
			
			static current_model[32]
			fm_get_user_model(id, current_model, sizeof current_model - 1)
			if (equal(current_model, g_player_model[id]))
			{
				fm_set_user_model(id, g_player_model[id])
				fm_set_user_model_index(id, modelindex[index])
			}
			else
				debug_ing[id] = false
		}
	}
}

stock fm_get_user_model(player, model[], len)
{
	get_user_info(player, "model", model, len)
}

// Set User Model
stock fm_set_user_model(id, const model[])
{
	set_user_info(id, "model", model)
}

// Set the precached model index (updates hitboxes server side)
stock fm_set_user_model_index(id, value)
{
	set_pdata_int(id, OFFSET_MODELINDEX, value, OFFSET_LINUX)
}  
