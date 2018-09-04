#include <amxmodx>
#include <fakemeta>
#include <biohazard>

public plugin_init()
{
	register_plugin("Bot not attack when round begin", "0.1", "Dolph_ziggler")
	register_forward( FM_CmdStart , "fm_CmdStart" );
}

public fm_CmdStart(id,Handle)
{
	new Buttons; Buttons = get_uc(Handle,UC_Buttons);
	if(is_user_bot(id) && get_zb_count() == 0)
	{
		Buttons &= ~IN_ATTACK;
		set_uc( Handle , UC_Buttons , Buttons );
		return FMRES_SUPERCEDE;
	}
	return FMRES_IGNORED;
	
	
} 

public get_zb_count()
{
	new i1 = 0
	
	for(new i = 0; i < get_maxplayers(); i++)
	{
		if(is_user_connected(i))
		{
			if(is_user_zombie(i))
				i1++
		}
	}
	
	return i1
}
