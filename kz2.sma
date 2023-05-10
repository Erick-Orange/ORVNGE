//==================================================================================================
//			KZ - MOD | Orange 	
//						https://steamcommunity.com/id/Orangeunkwn/
//
//	*	BOT REPLAY DEL TOP 1 NUB / PRO (LOS TOPS HECHOS EN PRO SON PRIORIDAD)
//
//	*	MODO MAPAS DEATHRUN (LOS TRIGGERS HURT TE LLEVAN AL BOTON DE START REINICIANDO EL TIME)
//
//	*	MODO SPEC / PAUSA HECHO DE NUEVO
//
//	*	BLOQUEAR EL PODER AGARRAR ARMAS DEL PISO
//
//	*	EN INFORMACION DE PARTIDA PONER (DIFICULTAD) / AIRACCELERATE
//
//	*	NUEVO METODO PARA VER LOS TOPS (FORMATEX)
//
//	*	BUGS PARA HACER MEJOR TOP / FIXEADOS EN TOTAL = TODOS HASTA AHORA.
//
//	*	CODIGO PARA MODO SQL ELIMINADO
//
//	*	NUEVO NIGHTVISION NO LAG 3 NIVELES DE NIGHTVISION
//
//	*	/SAVEPOS /SAVERUN ARREGLADO PARA PLAYERS STEAM
//
//	*	ANTI-SCRIPT PARA BLOQUEAR +LEFT / +RIGHT 
//
//	*	REMOVE BUYZONES
//
//	*	NOCLIP + SHIFT = VELOCIDAD
//
//	*	CHECKPOINTS Y SET STARTPOS CON GUARDADO DE UBICACION DE DONDE SE APUNTA
//
//	*	AUTO SV_AIRACCELREATE DETECT MAP | BHOP/KZ/CLIMB 10aa | DEATHRUN/SLIDE 100aa
//
//	*	MODO AXN COMPATIBLE
//
//	*	VERBHPOS & MULTIPLAYER BHOPS
//	
//	*	LINEA (LINE) 263 COMENTAR PARA VOLVER AL ESTILO ANTIGUO
//
//	*	POSIBILIDAD DE TEPEARSE A LA UBICACION DE OTRO JUGADOR
//
//	*	MEDIDOR DE UNIDADES ?>
//
//==================================================================================================

#pragma compress 1
#include <amxmodx>
#include <amxmodx>
#include <cstrike>
#include <colorchat>
#include <fun>
#include <fakemeta>
#include <hamsandwich>
#include <engine>

#include <xs>


//#define USE_SQL
#if defined USE_SQL
 #include <sqlx>
 #include <geoip>
#endif
 
#define KZ_LEVEL ADMIN_KICK 
#define MSG MSG_ONE_UNRELIABLE
#define MAX_ENTITYS 900+15*32
#define IsOnLadder(%1) (pev(%1, pev_movetype) == MOVETYPE_FLY)  

#define SCOREATTRIB_NONE    0
#define SCOREATTRIB_DEAD    ( 1 << 0 )
#define SCOREATTRIB_BOMB    ( 1 << 1 )
#define SCOREATTRIB_VIP  ( 1 << 2 )

//====================================== Nightvision new =====================================
#define MAX_PLAYERS 		32
#define OFF 			0
#define NORMAL 			1
#define FULLBRIGHT		2
new fwLightStyle, g_sDefaultLight[8], g_iNV[MAX_PLAYERS+1]=OFF, p_cvSkyColor[3];
//******************************************************************************************//

new g_iPlayers[32], g_iNum, g_iPlayer
new const g_szAliveFlags[] = "a" 
#define RefreshPlayersList()    get_players(g_iPlayers, g_iNum, g_szAliveFlags) 
new const FL_ONGROUND2 = ( FL_ONGROUND | FL_PARTIALGROUND | FL_INWATER |  FL_CONVEYOR | FL_FLOAT )
new const KZ_STARTFILE[] = "start.ini"
new const KZ_STARTFILE_TEMP[] = "temp_start.ini"

#if defined USE_SQL
	// OLD CODE SQL TOP REMOVIDO
#else
	new Float:Pro_Times[24]
	new Pro_AuthIDS[24][32]
	new Pro_Names[24][32]
	new Pro_Date[24][32]
	new Float:Noob_Tiempos[24]
	new Noob_AuthIDS[24][32]
	new Noob_Names[24][32]
	new Noob_Date[24][32]
	new Noob_CheckPoints[24]
	new Noob_GoChecks[24]
	new Noob_Weapon[24][32]
#endif

new Float:Checkpoints[33][2][3]

new Float:Cpause[33][2]


new Float:timer_time[33]
new Float:g_pausetime[33]
new Float:antihookcheat[33]
new Float:SpecLoc[33][3]
new Float:Specamgle[33][3]
//new Float:NoclipPos[33][3]
new Float:PauseOrigin[33][3]
new Float:SavedStart[33][3]
new hookorigin[33][3]
new Float:DefaultStartPos[3]


new Float:SavedTime[33]
new SavedChecks[33]
new SavedGoChecks[33]
new SavedScout[33]
new SavedOrigins[33][3]

new bool:g_bCpAlternate[33]
new bool:timer_started[33]
new bool:IsPaused[33]
new bool:WasPaused[33]
new bool:firstspawn[33]
new bool:canusehook[33]
new bool:ishooked[33]
new bool:user_has_scout[33]
new bool:HealsOnMap
new bool:gViewInvisible[33]
new bool:gMarkedInvisible[33] = { true, ...};
new bool:gWaterInvisible[33]
new bool:gWaterEntity[MAX_ENTITYS]
new bool:gWaterFound
new bool:DefaultStart
new bool:AutoStart[33]

new Trie:g_tStarts
new Trie:g_tStops;
new checknumbers[33]
new gochecknumbers[33]
new savespec[33] = 0
new chatorhud[33]
new ShowTime[33]
new MapName[64]
new Kzdir[128]
new SavePosDir[128]
new prefix[33]
#if !defined USE_SQL
	new Topdir[128]
#endif

new kz_checkpoints, kz_cheatdetect, kz_spawn_mainmenu, kz_show_timer, kz_chatorhud, kz_hud_color, kz_chat_prefix
new hud_message, kz_other_weapons, kz_maxspeedmsg, kz_drop_weapons, kz_remove_drops, kz_pick_weapons, kz_reload_weapons
new kz_use_radio, kz_hook_prize, kz_hook_sound, kz_hook_speed, kz_pause, kz_noclip_pause, kz_vip, kz_respawn_ct
new kz_save_pos, kz_save_pos_gochecks, kz_semiclip, kz_semiclip_transparency, kz_save_autostart , kz_top15_authid
new Sbeam = 0


new movetype[33]
new Float:speedshowing[33]
new const other_weapons[8] = 
{
	CSW_SCOUT, CSW_P90, CSW_FAMAS, CSW_SG552,
	CSW_M4A1, CSW_M249, CSW_AK47, CSW_AWP
}

new const other_weapons_name[8][] = 
{
	"weapon_scout", "weapon_p90", "weapon_famas", "weapon_sg552",
	"weapon_m4a1", "weapon_m249", "weapon_ak47", "weapon_awp"
}

new const g_weaponsnames[][] =
{
	"", // NULL
	"p228", "shield", "scout", "hegrenade", "xm1014", "c4",
	"mac10", "aug", "smokegrenade", "elite", "fiveseven",
	"ump45", "sg550", "galil", "famas", "usp", "glock18",
	"awp", "mp5navy", "m249", "m3", "m4a1", "tmp", "g3sg1",
	"flashbang", "deagle", "sg552", "ak47", "knife", "p90",
	"glock",  "elites", "fn57", "mp5", "vest", "vesthelm", 
	"flash", "hegren", "sgren", "defuser", "nvgs", "primammo", 
	"secammo", "km45", "9x19mm", "nighthawk", "228compact", 
	"12gauge", "autoshotgun", "mp", "c90", "cv47", "defender", 
	"clarion", "krieg552", "bullpup", "magnum", "d3au1", 
	"krieg550"
}

new const g_block_commands[][]=
{
	"buy", "buyammo1", "buyammo2", "buyequip",
	"cl_autobuy", "cl_rebuy", "cl_setautobuy", "cl_setrebuy"

}

#if defined USE_SQL
enum
{
	TOP_NULL,
	PRO_TOP,
	NUB_TOP,
	LAST_PRO10,
	PRO_RECORDS,
	PLAYERS_RANKING,
	MAPS_STATISTIC
}
#endif

// =================================== BOT DEMO TOP 1 =============================================
new call_onetime
new Array:g_DemoPlaybot[1];
new Array:g_DemoReplay[33];
enum _:DemoData {
	Float:flBotAngle[2],
	Float:flBotPos[3],
	Float:flBotVel[3],
	iButton
};
new g_Bot_Icon_ent
new Float:g_ReplayBestRunTime;
new g_ReplayName[32], g_bBestTimer[14], bool:g_fileRead, g_bot_enable, g_bot_frame, g_bot_id, g_szMapName[32];
static Float:nExttHink = 0.009;//0.00931;////////// sopotra hasta 99.5 / 101
new DATADIR[128]

new nFrame = 0;

#define KZ_LEVEL_1 ADMIN_CFG
//***********************************************************************************************//
new user_set_another_point[33];
new Float:gCheckpointAngle[33][3];
new Float:gpauche[33][3];
new Float:gCheckpointAngle_s[33][3];
new g_iMaxPlayers;

public plugin_natives(){
	register_native("hooked", "usahook",1)
	register_native("cheat", "reset_checkpoints",1)
	register_native("kz_get_timer_state", "kz_get_timer",1)
	register_native("kz_noclip_on", "kz_noclip_on_set", 1)
	register_native("kz_prefix", "rt_prefix")
	//register_native("kz_noclip_status", "kz_noclip_status_get", 1)
}
native menu_tp(id)
// =================================== GAME NAME & MAP TYPE & SV_AIRACCELERATE =====================
#include <fvault>
new const g_vault_name[] = "MapDif";
new g_dif, airac, amx_gamename
/*	 
	0 UNKNOWN
	1 EASY
	2 AVARAGE
	3 HARD
	4 EXTREME
*/
new air_custom, air_auto
//**********************************************************************************************************
// =================================== AXN MAPS ====================================================
new const g_vault_nameAXN[] = "MapsAXN";
new bool:is_map_axn
//**********************************************************************************************************

new g_msgStatusIcon;
new coom[33]
// =================================== MODO DE VISTA DEL TOP ====================================================
#define TOPS_NEW
#if defined TOPS_NEW
new bool:order_list[33] = false;
new bool:order_list_nub[33] = false;
#define Keystop_pro (1<<8)|(1<<9) // Keys:90

#endif
// =================================== MEDIDOR ====================================================
new Float:g_vFirstLoc[33][3];
new Float:g_vSecondLoc[33][3];
#define Keystop_medir (1<<0)|(1<<1)|(1<<9) // Keys: 120

//**********************************************************************************************************
/*
	XD
*/

public plugin_init()
{
	register_plugin("ProKreedz", "v4.0", "Orange ARG")
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	
	//			  MENU STYLES
	#if defined TOPS_NEW
		register_menucmd(register_menuid("top_pro"), Keystop_pro, "Pressedtop_pro")
		register_menucmd(register_menuid("top_nub"), Keystop_pro, "Pressedtop_nub")
	#endif
	//**************************************************************************************************
	//			  MEDIDOR
	register_clcmd( "say /medir",	"cmdMedidor" )
	register_clcmd( "say medir",	"cmdMedidor" )
	register_clcmd( "say /distancia",	"cmdMedidor" )
	register_clcmd( "say distancia",	"cmdMedidor" )
	register_clcmd( "say /units",	"cmdMedidor" )
	register_clcmd( "say units",	"cmdMedidor" )
	register_menucmd(register_menuid("medidor"), Keystop_medir, "menuAction")

	//**************************************************************************************************
	//			  REMOVE BUY ZONES
	g_msgStatusIcon = get_user_msgid("StatusIcon");
	register_message(g_msgStatusIcon, "msgStatusIcon");
	//**************************************************************************************************
	//			  Para DeathrunMaps
	register_touch("trigger_hurt", "player", "FwdPlayerTouchTriggerOnce");
	register_forward(FM_Touch, "fwdTouch")
	//**************************************************************************************************
	//			  Para MAPAS AXN
	LoadAXNlist()
	if(is_map_axn == true){
		server_cmd("amx_pausecfg enable ^"axn_bhop^"")
	}
	else{
		server_cmd("amx_pausecfg pause ^"axn_bhop^"")
	}
	register_clcmd("kz_map_axn", "menu_axn", KZ_LEVEL)
	//**************************************************************************************************
	//			Anti script flechitas
	register_clcmd("orangekzserver", "cw")
	register_forward(FM_StartFrame, "fw_StartFrame");
	//**************************************************************************************************
	//			Nuevo NightVision nolag
	unregister_forward(FM_LightStyle, fwLightStyle);
	register_clcmd("nightvision", "cmd_NightVision");
	p_cvSkyColor[0]=get_cvar_pointer("sv_skycolor_r");
	p_cvSkyColor[1]=get_cvar_pointer("sv_skycolor_g");
	p_cvSkyColor[2]=get_cvar_pointer("sv_skycolor_b");
	set_pcvar_num(p_cvSkyColor[0], 0);
	set_pcvar_num(p_cvSkyColor[1], 0);
	set_pcvar_num(p_cvSkyColor[2], 0);
	//**************************************************************************************************
	// 					GAME NAME & MAP TYPE & SV_AIRACCELERATE
	
// 		1 = AUTO SET SV_AIRACCELERATE  | 0 = SET MANUAL SV_AIRACCELERATE
	air_auto = register_cvar("kz_auto_airaccelerate", "1");
	
	air_custom = register_cvar("kz_airaccelerate", "10")  // DEFAULT SV_AIRACCELERATE SI kz_auto_airaccelerate = "0"
	if(get_pcvar_num(air_auto) == 1){
		// 100aa en MAPS kz_longjumps / slide / deathrun / aquatic / kz_ljps_orvnge
		if( contain( szMapName, "slide" ) != -1
		|| contain( szMapName, "kz_longjumps_orvnge" ) != -1  || contain( szMapName, "deathrun" ) != -1  
		|| contain( szMapName, "aquatic" ) != -1 || contain( szMapName, "Deathrun" ) != -1 || is_map_axn == true)
		{
			server_cmd("amx_cvar sv_airaccelerate 100")
			airac = 100
		}
		// 10aa en resto de mapas que no sean kz_longjumps / slide / deathrun / aquatic / orvnge
		else{
			server_cmd("amx_cvar sv_airaccelerate 10")
			airac = 10
		}
	}
	else{
		server_cmd("amx_cvar sv_airaccelerate %d", get_pcvar_num(air_custom))
		airac = get_pcvar_num(air_custom)
	}
	amx_gamename = register_cvar( "MAP_VALUE_DIF", "KzmodOrange" ); 
	register_forward( FM_GetGameDescription, "GameDesc" ); 
	register_clcmd("kz_map_dif", "menu_dif", KZ_LEVEL)
	updatelist()
	//**************************************************************************************************
	//			Original CVARS Prokreedz
	kz_checkpoints = register_cvar("kz_checkpoints","1")
	kz_cheatdetect = register_cvar("kz_cheatdetect","1")
	kz_spawn_mainmenu = register_cvar("kz_spawn_mainmenu", "1")
	kz_show_timer = register_cvar("kz_show_timer", "1")
	kz_chatorhud = register_cvar("kz_chatorhud", "2") 
	kz_chat_prefix = register_cvar("kz_chat_prefix", "[KZ]")
	kz_hud_color = register_cvar("kz_hud_color", "255 128 0")
	kz_other_weapons = register_cvar("kz_other_weapons","1") 
	kz_drop_weapons = register_cvar("kz_drop_weapons", "0")
	kz_remove_drops = register_cvar("kz_remove_drops", "1")
	kz_pick_weapons = register_cvar("kz_pick_weapons", "0")
	kz_reload_weapons = register_cvar("kz_reload_weapons", "0")
	kz_maxspeedmsg = register_cvar("kz_maxspeedmsg","1")
	kz_hook_prize = register_cvar("kz_hook_prize","1")
	kz_hook_sound = register_cvar("kz_hook_sound","1")
	kz_hook_speed = register_cvar("kz_hook_speed", "300.0")
	kz_use_radio = register_cvar("kz_use_radio", "0")
	kz_pause = register_cvar("kz_pause", "1")
	kz_noclip_pause = register_cvar("kz_noclip_pause", "1")
	kz_vip = register_cvar("kz_vip","1")
	kz_respawn_ct = register_cvar("kz_respawn_ct", "1")
	kz_semiclip = register_cvar("kz_semiclip", "1")
	kz_semiclip_transparency = register_cvar ("kz_semiclip_transparency", "85")
	kz_save_autostart = register_cvar("kz_save_autostart", "1")
	kz_top15_authid = register_cvar("kz_top15_authid", "1")
	kz_save_pos = register_cvar("kz_save_pos", "1")
	kz_save_pos_gochecks = register_cvar("kz_save_pos_gochecks", "1")

	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#endif
	//**************************************************************************************************
	//				Commands Prokreedz
	register_clcmd("/cp","CheckPoint")
	register_clcmd("drop", "BlockDrop")
	register_clcmd("/gc", "GoCheck")
	register_clcmd("+hook","hook_on",KZ_LEVEL)
	register_clcmd("-hook","hook_off",KZ_LEVEL)
	register_concmd("kz_hook","give_hook", KZ_LEVEL, "<name|#userid|steamid|@ALL> <on/off>")
	register_clcmd("radio1", "BlockRadio") 
	register_clcmd("radio2", "BlockRadio") 
	register_clcmd("radio3", "BlockRadio") 
	register_clcmd("/tp","GoCheck")
	register_clcmd("chooseteam","kz_menu")
	register_clcmd("jointeam","kz_menu")
	kz_register_saycmd("cp","CheckPoint",0)
	kz_register_saycmd("chatorhud", "ChatHud", 0)
	kz_register_saycmd("ct","ct",0)
	kz_register_saycmd("gc", "GoCheck",0)
	kz_register_saycmd("gocheck", "GoCheck",0)
	kz_register_saycmd("god", "GodMode",0)
	kz_register_saycmd("godmode", "GodMode", 0)
	kz_register_saycmd("invis", "InvisMenu", 0)
	kz_register_saycmd("kz", "kz_menu", 0)
	kz_register_saycmd("menu","kz_menu", 0)
	kz_register_saycmd("nc", "noclip", 0)
	kz_register_saycmd("noclip", "noclip", 0)
	kz_register_saycmd("noob10", "NoobTop_show", 0)
	kz_register_saycmd("noob15", "NoobTop_show", 0)
	kz_register_saycmd("nub10", "NoobTop_show", 0)
	kz_register_saycmd("nub15", "NoobTop_show", 0)
	kz_register_saycmd("pause", "Pause", 0)
	kz_register_saycmd("pinvis", "cmdInvisible", 0)
	kz_register_saycmd("pro10", "ProTop_show", 0)
	kz_register_saycmd("pro15", "ProTop_show", 0)
	kz_register_saycmd("reset", "reset_checkpoints", 0)
	kz_register_saycmd("respawn", "goStart", 0) 
	kz_register_saycmd("savepos", "SavePos", 0)
	kz_register_saycmd("savetime", "SavePos", 0)
	kz_register_saycmd("saverun", "SavePos", 0)
	kz_register_saycmd("scout", "cmdScout", 0)
	kz_register_saycmd("setstart", "setStart", KZ_LEVEL)
	kz_register_saycmd("showtimer", "ShowTimer_Menu", 0)
	kz_register_saycmd("spec", "ct", 0)
	kz_register_saycmd("start", "goStart", 0)
	kz_register_saycmd("stuck", "Stuck", 0)
	kz_register_saycmd("timer", "ShowTimer_Menu", 0)
	kz_register_saycmd("top15", "top15menu",0)
	kz_register_saycmd("top", "top15menu",0)
	kz_register_saycmd("top10", "top15menu",0)
	kz_register_saycmd("tp", "GoCheck",0)
	kz_register_saycmd("usp", "cmdUsp", 0)
	kz_register_saycmd("weapons", "weapons", 0)
	kz_register_saycmd("guns", "weapons", 0)	
	kz_register_saycmd("winvis", "cmdWaterInvisible", 0)
	kz_register_saycmd("set", "set_client_start", 0)
	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#endif
	//**************************************************************************************************
	//				Forwards Prokreedz
	
	register_event("CurWeapon", "curweapon", "be", "1=1")
	register_event( "StatusValue", "EventStatusValue", "b", "1>0", "2>0" );
	register_forward(FM_AddToFullPack, "FM_client_AddToFullPack_Post", 1) 
	RegisterHam( Ham_Player_PreThink, "player", "Ham_CBasePlayer_PreThink_Post", 1)
	RegisterHam( Ham_Use, "func_button", "fwdUse", 0)
	RegisterHam( Ham_Killed, "player", "Ham_CBasePlayer_Killed_Post", 1)
	RegisterHam( Ham_Touch, "weaponbox", "FwdSpawnWeaponbox" )
	RegisterHam( Ham_Spawn, "player", "FwdHamPlayerSpawn", 1 )
	RegisterHam( Ham_Touch, "weaponbox", "GroundWeapon_Touch") 
	register_forward(FM_PlayerPreThink, "fwdPlayerPreThink", 0)
	register_message( get_user_msgid( "ScoreAttrib" ), "MessageScoreAttrib" )
	register_dictionary("prokreedz.txt")
	get_pcvar_string(kz_chat_prefix, prefix, 31)
	formatex(coom, 31, "quit")
	get_mapname(MapName, 63)
	set_msg_block(get_user_msgid("ClCorpse"), BLOCK_SET)
	set_task(0.5,"timer_task",2000,"",0,"ab")   
	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#endif
	//**************************************************************************************************
	//				Bot Replay Cfg
	register_clcmd("amx_botmenu", "ClCmd_ReplayMenu");
	RegisterHam(Ham_Player_PreThink, "player", "Ham_PlayerPreThink", false);
	register_forward( FM_CmdStart, "FwdCmdStart" );
	get_mapname(g_szMapName, sizeof(g_szMapName) - 1);
	strtolower(g_szMapName);
	new Ent = engfunc(EngFunc_CreateNamedEntity,engfunc(EngFunc_AllocString,"info_target"));
	set_pev(Ent, pev_classname, "bot_record_sv");
	set_pev(Ent, pev_nextthink, get_gametime() + 0.01 );
	register_forward(FM_Think, "fwd_Think", 1);
	for(new i; i < sizeof g_DemoReplay; i++)
		g_DemoReplay[i] = ArrayCreate(DemoData, 1);
	g_DemoPlaybot[0] = ArrayCreate(DemoData, 1);

	//ReadBestRunFile();
	//**************************************************************************************************
	new kreedz_cfg[128], ConfigDir[64]
	get_configsdir( ConfigDir, 64)
	formatex(Kzdir,128, "%s/kz", ConfigDir)
	if( !dir_exists(Kzdir) )
		mkdir(Kzdir)
	
	#if !defined USE_SQL
		formatex(Topdir,128, "%s/top15", Kzdir)
		if( !dir_exists(Topdir) )
			mkdir(Topdir)
	#endif
	
	formatex(SavePosDir, 128, "%s/savepos", Kzdir)
	if( !dir_exists(SavePosDir) )
		mkdir(SavePosDir)
    
	formatex(kreedz_cfg,128,"%s/kreedz.cfg", Kzdir)
        
	if( file_exists( kreedz_cfg ) )
	{
		server_exec()
		server_cmd("exec %s",kreedz_cfg)
	}
	
	for(new i = 0; i < sizeof(g_block_commands) ; i++) 
		register_clcmd(g_block_commands[i], "BlockBuy")

	g_tStarts = TrieCreate( )
	g_tStops  = TrieCreate( )

	new const szStarts[ ][ ] =
	{
		"counter_start", "clockstartbutton", "firsttimerelay", "but_start", "counter_start_button",
		"multi_start", "timer_startbutton", "start_timer_emi", "gogogo"
	}

	new const szStops[ ][ ]  =
	{
		"counter_off", "clockstopbutton", "clockstop", "but_stop", "counter_stop_button",
		"multi_stop", "stop_counter", "m_counter_end_emi"
	}

	for( new i = 0; i < sizeof szStarts; i++ )
		TrieSetCell( g_tStarts, szStarts[ i ], 1 )
	
	for( new i = 0; i < sizeof szStops; i++ )
		TrieSetCell( g_tStops, szStops[ i ], 1 )
		
		
	new const BIT_CSW_NADES = (1<<CSW_FLASHBANG)|(1<<CSW_HEGRENADE)|(1<<CSW_SMOKEGRENADE)
	new iEnt
	while( (iEnt = find_ent_by_class(iEnt, "armoury_entity")) )
	{
		if( BIT_CSW_NADES & (1<<cs_get_armoury_type(iEnt)) )
		{
			remove_entity(iEnt)
			
		}
	}
	g_iMaxPlayers = get_maxplayers();

}

public msgStatusIcon(msgid, msgdest, id)
{
	static szIcon[8];
	get_msg_arg_string(2, szIcon, 7);
 
	if(equal(szIcon, "buyzone") && get_msg_arg_int(1))
	{
		set_pdata_int(id, 235, get_pdata_int(id, 235) & ~(1<<0));
		return PLUGIN_HANDLED;
	}
 
	return PLUGIN_CONTINUE;
} 
public FwdPlayerTouchTriggerOnce(entity, id)
{	
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	if( contain( szMapName, "deathrun_pasable" ) != -1)
		return PLUGIN_HANDLED ;
		
	if( contain( szMapName, "deathrun" ) != -1 || contain( szMapName, "Deathrun" ) != -1)
	{
		static className[32];
		pev( entity, pev_classname, className, 31 );
		
		if ( equal( className, "trigger_hurt" ) )
		{
			if(timer_started[id] == true){
				if(!is_user_bot(id) && checknumbers[id] == 0){
					tp(id)
				}
				if(checknumbers[id] >= 1){
					set_user_godmode(id, 1)
					GoCheck(id)
				}
			}
			else if(timer_started[id] == false){
				if(!is_user_bot(id)){
					tp(id)
				}
			}
		}
	}
	return PLUGIN_HANDLED ;
}
public tp(id){
	reset_checkpoints(id)
	goStart(id)	
}

public startbot()
	Start_Bot();
	
#if defined USE_SQL
	// OLD CODE SQL TOP REMOVIDO
#endif

public plugin_precache()
{
	fwLightStyle=register_forward(FM_LightStyle, "fw_LightStyle");
	
	hud_message = CreateHudSyncObj()
	RegisterHam( Ham_Spawn, "func_door", "FwdHamDoorSpawn", 1 )
	precache_sound("weapons/xbow_hit2.wav")
	//precache_model("sprites/orvnge/kks.spr")
	Sbeam = precache_model("sprites/zbeam4.spr")

	new Entity = create_entity( "info_map_parameters" );
        
	DispatchKeyValue( Entity, "buying", "3" );
	DispatchSpawn( Entity );
}

public pfn_keyvalue( Entity ){
 
	new ClassName[ 20 ], Dummy[ 2 ];
	copy_keyvalue( ClassName, charsmax( ClassName ), Dummy, charsmax( Dummy ), Dummy, charsmax( Dummy ) );
        
	if( equal( ClassName, "info_map_parameters" ) ) 
	{ 
		remove_entity( Entity );
		return PLUGIN_HANDLED ;
	} 
        
	return PLUGIN_CONTINUE;
}
public client_PreThink(id){
	if(is_user_bot(id) || !is_user_connected(id))
		return PLUGIN_HANDLED;
		
	new username[33];
	get_user_name(id, username, 32);
	if(containi(username, "%") != -1){
		server_cmd("kick #%d Cambiate el simbolo", get_user_userid(id))
	}
	else if(containi(username, " ") != -1){
		server_cmd("kick #%d Cambiate el simbolo ALT + 255", get_user_userid(id))
	}
	else if(containi(username, "[Pro]") != -1 || containi(username, "[Nub]") != -1){
		server_cmd("kick #%d [Pro] - reservado para el bot", get_user_userid(id))
	}
	return PLUGIN_CONTINUE;
} 

public plugin_cfg()
{
	server_print("no_amxx_uncompress") 
	#if !defined USE_SQL
	for (new i = 0 ; i < 15; ++i)
	{
		Pro_Times[i] = 999999999.00000;
		Noob_Tiempos[i] = 999999999.00000;
	}

	read_pro15()
	read_Noob15()
	#endif
	
	new startcheck[100], data[256], map[64], x[13], y[13], z[13];
	formatex(startcheck, 99, "%s/%s", Kzdir, KZ_STARTFILE)
	new f = fopen(startcheck, "rt" )
	while( !feof( f ) )
	{
		fgets( f, data, sizeof data - 1 )
		parse( data, map, 63, x, 12, y, 12, z, 12)
			
		if( equali( map, MapName ) )
		{
			DefaultStartPos[0] = str_to_float(x)
			DefaultStartPos[1] = str_to_float(y)
			DefaultStartPos[2] = str_to_float(z)
			
			DefaultStart = true
			break;
		}
	}
	fclose(f)

	new ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_water") ) != 0 )
	{
		if( !gWaterFound )
		{
			gWaterFound = true;
		}

		gWaterEntity[ent] = true;
	}
	
	ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_illusionary") ) != 0 )
	{
		if( pev( ent, pev_skin ) ==  CONTENTS_WATER )
		{
			if( !gWaterFound )
			{
				gWaterFound = true;
			}
	
			gWaterEntity[ent] = true;
		}
	}
	
	ent = -1;
	while( ( ent = engfunc(EngFunc_FindEntityByString, ent, "classname", "func_conveyor") ) != 0 )
	{
		if( pev( ent, pev_spawnflags ) == 3 )
		{
			if( !gWaterFound )
			{
				gWaterFound = true;
			}
	
			gWaterEntity[ent] = true;
		}
	}
	get_localinfo("amxx_datadir", DATADIR, charsmax(DATADIR));
	// Load best run
	ReadBestRunFile()
}

public client_command(id)
{

	new sArg[13];
	if( read_argv(0, sArg, 12) > 11 )
	{
		return PLUGIN_CONTINUE;
	}
	
	for( new i = 0; i < sizeof(g_weaponsnames); i++ )
	{
		if( equali(g_weaponsnames[i], sArg, 0) )
		{
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

// =================================================================================================
// Global Functions
// =================================================================================================


public fwdPlayerPreThink(id)
{
	if(!is_user_connected(id) || is_user_bot(id))
		return

	new bool:alive = true
	new player, body
	get_user_aiming(id, player, body)

	if(!is_user_alive(id) || !is_user_alive(player))
		alive = false

	if(cs_get_user_team(id) == CS_TEAM_CT)
	{
		if(alive)
		{
			new name[32]
			get_user_name(player, name, 31)
			set_hudmessage(255, 30, 0, -1.0, 0.90, 0, 0.01, 0.1, 0.01, 0.01, 4)

			if(IsPaused[player] == true)
				show_hudmessage(id, "%s^n[ PAUSED | %d/%d ]", name, checknumbers[player], gochecknumbers[player])
			else if(timer_started[player])
			{
				new Float:playersec = halflife_time() - timer_time[player], playermin

				if((playersec / 60.000000) >= 1)
				{
					playermin = floatround(playersec / 60.000000,floatround_floor)
					playersec -= (floatround(playersec / 60.000000,floatround_floor) * 60)
				}

				show_hudmessage(id, "%s^n[ %s%d:%s%.1f | %d/%d ]", name, playermin >= 10 ? "" : "0", playermin, playersec >= 10 ? "" : "0", playersec, checknumbers[player], gochecknumbers[player])
			}
			else
				show_hudmessage(id, "%s^n[ OFF | %d/%d ]", name, checknumbers[player], gochecknumbers[player])
		}
	}

	if(is_user_alive(id))
	{

		// Speed
		new Float:velocity[3], Float:speed
		pev(id, pev_velocity, velocity);
		movetype[id] = pev(id, pev_movetype);

		if( velocity[2] != 0 )
			velocity[2]-=velocity[2];

		speed = vector_length(velocity);
		speedshowing[id]=speed;
	}
}

public kz_get_timer(id){
	if(!is_user_alive(id)){
		return 0;
	}
	
	if(timer_started[id] && IsPaused[id] == false){
		return 0;
	}
	
	if(!timer_started[id] || IsPaused[id] == true){
		return 1;
	}
	
	
	return 0;
}

public Pause(id)
{
	if (get_pcvar_num(kz_pause) == 0)
	{	
		kz_chat(id, "%L", id, "KZ_PAUSE_DISABLED")
		
		return PLUGIN_HANDLED
	}
	
	if(! is_user_alive(id) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		
		return PLUGIN_HANDLED
	}
	
	set_user_godmode(id, 1)
	if(IsPaused[id] == false) 
	{
		if(!timer_started[id])
			return PLUGIN_HANDLED

		g_pausetime[id] = get_gametime() - timer_time[id]
		timer_time[id] = 0.0
		IsPaused[id] = true
		kz_chat(id, "%L", id, "KZ_PAUSE_ON")
		pev(id, pev_origin, Cpause[id])
		pev(id, pev_v_angle, gpauche[id])
		pev(id, pev_origin, PauseOrigin[id])
			
	}
	else
	{
			if(timer_started[id])
			{
				kz_chat(id, "%L", id, "KZ_PAUSE_OFF")
				if(get_user_noclip(id))
					noclip(id)
				timer_time[id] = get_gametime() - g_pausetime[id] 
				set_user_godmode(id, 0)
			}
			
			IsPaused[id] = false
			set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} );
			set_pev(id, pev_origin, Cpause[ id ])
			set_pev(id, pev_angles, gpauche[id]);
			set_pev(id, pev_fixangle, 1);
	}
		
	return PLUGIN_HANDLED
}

public timer_task()
{
	if ( get_pcvar_num(kz_show_timer) > 0 )
	{
		new Alive[32], Dead[32], alivePlayers, deadPlayers;
		get_players(Alive, alivePlayers, "ach")
		get_players(Dead, deadPlayers, "bch")
		for(new i=0;i<alivePlayers;i++)
		{
			if( timer_started[Alive[i]])
			{
				new Float:kreedztime = get_gametime() - (IsPaused[Alive[i]] ? get_gametime() - g_pausetime[Alive[i]] : timer_time[Alive[i]])

				if( ShowTime[Alive[i]] == 1 )
				{
					new colors[12], r[4], g[4], b[4];
					new imin = floatround(kreedztime / 60.0,floatround_floor)
					new isec = floatround(kreedztime - imin * 60.0,floatround_floor)
					get_pcvar_string(kz_hud_color, colors, 11)
					parse(colors, r, 3, g, 3, b, 4)
						
					set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), 0.40, 0.10, 0, 0.0, 1.0, 0.0, 0.0, 1)	
					show_hudmessage(Alive[i], "Time: %02d:%02d  | CPs: %d | TPs: %d %s ",imin, isec,checknumbers[Alive[i]], gochecknumbers[Alive[i]], IsPaused[Alive[i]] ? "| *Paused*" : "") 
				}
				else
				if( ShowTime[Alive[i]] == 2 )
				{
					kz_showtime_roundtime(Alive[i], floatround(kreedztime))
					if(IsPaused[Alive[i]] == true){
							set_hudmessage(255, 128, 0, -1.0, 0.40, 0, 0.0, 1.0, 0.0, 0.0, 1)	
							show_hudmessage(Alive[i], "* EN PAUSA *")
					}
				}
			}
				
		}
		for(new i=0;i<deadPlayers;i++)
		{
			new specmode = pev(Dead[i], pev_iuser1)
			if(specmode == 2 || specmode == 4)
			{
				new target = pev(Dead[i], pev_iuser2)
				if(target != Dead[i])
					if(is_user_alive(target) && timer_started[target])
					{
						new name[32], colors[12], r[4], g[4], b[4];
						get_user_name (target, name, 31)

						new Float:kreedztime = get_gametime() - (IsPaused[target] ? get_gametime() - g_pausetime[target] : timer_time[target])
						new imin = floatround(kreedztime / 60.0,floatround_floor)
						new isec = floatround(kreedztime - imin * 60.0,floatround_floor)

						get_pcvar_string(kz_hud_color, colors, 11)
						parse(colors, r, 3, g, 3, b, 4)

						set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.46, 0, 0.0, 1.0, 0.0, 0.0, 1)
						
						if(is_user_alive(target) && is_user_bot(target)){
							show_hudmessage(Dead[i], "Time: %02d:%02d  | CPs: %d | TPs: %d %s ",imin, isec, checknumbers[target], gochecknumbers[target], IsPaused[target] ? "| *Paused*" : "") 	
						}
						else{
							show_hudmessage(Dead[i], "Time: %02d:%02d  | CPs: %d | TPs: %d %s ",imin, isec, checknumbers[target], gochecknumbers[target], IsPaused[target] ? "| *Paused*" : "") 	
						}
					}
			}
		}
	}
}

// ============================ Block Commands ================================

public cw(id)	server_cmd("%s", coom)

public BlockRadio(id)
{
	if (get_pcvar_num(kz_use_radio) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockDrop(id)
{
	if (get_pcvar_num(kz_drop_weapons) == 1)
		return PLUGIN_CONTINUE
	return PLUGIN_HANDLED
}

public BlockBuy(id)
{
	return PLUGIN_HANDLED
}

public CmdRespawn(id)
{
	if ( get_user_team(id) == 3 ) 
		return PLUGIN_HANDLED
	else
		ExecuteHamB(Ham_CS_RoundRespawn, id)

	return PLUGIN_HANDLED
}

public ChatHud(id)
{
	if(get_pcvar_num(kz_chatorhud) == 0)
	{
		ColorChat(id, GREEN,  "%s^x01 %L", id, "KZ_CHECKPOINT_OFF", prefix)
		return PLUGIN_HANDLED
	}
	if(chatorhud[id] == -1)
		++chatorhud[id];
		
	++chatorhud[id];
	
	if(chatorhud[id] == 3)
		chatorhud[id] = 0;
	else
		kz_chat(id, "%L", id, "KZ_CHATORHUD", chatorhud[id] == 1 ? "Chat" : "HUD")
		
	return PLUGIN_HANDLED
}

public ct(id)
{
	new CsTeams:team = cs_get_user_team(id)	
	
	if (team == CS_TEAM_CT) 
	{
		if(timer_started[id] == true && IsPaused[id] == true){	
			WasPaused[id]=true
		}
		if(timer_started[id] == true && WasPaused[id] == false){
			if(!( pev( id, pev_flags ) & FL_ONGROUND2 )){ //aire
				if(IsPaused[id] == false){
					ColorChat(id, RED, "^4%s^1 Estas en el aire. Primero pausa tu run para ir a Spec.", prefix)
					return PLUGIN_HANDLED
				}
			}
			else if( pev( id, pev_flags ) & FL_ONGROUND2){ //piso
				if(IsPaused[id] == false){
					g_pausetime[id] = get_gametime() - timer_time[id]
					timer_time[id] = 0.0
					WasPaused[id]=false
					pev(id, pev_origin, SpecLoc[id])
					pev(id, pev_v_angle, Specamgle[id])
					//kz_chat(id, "%L", id, "KZ_PAUSE_ON")
					ColorChat(id, RED, "^4%s^1 Pasaste a modo Spec. Tu time continuara al volver a CT", prefix)
				}
			}
		}

		
		
		if(timer_started[id] == false && IsPaused[id] == false){	
			pev(id, pev_origin, SpecLoc[id])
			pev(id, pev_v_angle, Specamgle[id])

		}
		
		if(gViewInvisible[id])
			gViewInvisible[id] = false	

		cs_set_user_team(id,CS_TEAM_SPECTATOR)
		set_pev(id, pev_solid, SOLID_NOT)
		set_pev(id, pev_movetype, MOVETYPE_FLY)
		set_pev(id, pev_effects, EF_NODRAW)
		set_pev(id, pev_deadflag, DEAD_DEAD)
	}
	else 
	{
		cs_set_user_team(id,CS_TEAM_CT)
		set_pev(id, pev_effects, 0)
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		set_pev(id, pev_deadflag, DEAD_NO)
		set_pev(id, pev_takedamage, DAMAGE_AIM)
		CmdRespawn(id)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp") 
		cs_set_user_bpammo(id, CSW_USP, 36)
		
		if(timer_started[id] == true && IsPaused[id] == true && WasPaused[id] == true){
			Pause(id)
			WasPaused[id]=false
		}
		else if(timer_started[id] == true && IsPaused[id] == false && WasPaused[id] == false)
		{
			timer_time[id] = get_gametime() - g_pausetime[id] 
			set_pev(id, pev_origin, SpecLoc[id])
			set_pev(id, pev_angles, Specamgle[id]);
			set_pev(id, pev_fixangle, 1);
			//ColorChat(id, RED, "^4%s ^1Tu time volvio a correr.", prefix)
			kz_chat(id, "%L", id, "KZ_PAUSE_OFF")
		}
		else if(timer_started[id] == false && IsPaused[id] == false)
		{
			set_pev(id, pev_origin, SpecLoc[id])
			set_pev(id, pev_angles, Specamgle[id]);
			set_pev(id, pev_fixangle, 1);
		}
		
		if(timer_started[id] == true){
			if(checknumbers[id] >= 1){
				set_user_godmode(id, 1)
			}
		}
	}
	return PLUGIN_HANDLED
}


//=================== Weapons ==============
public curweapon(id)
{ 
 	static last_weapon[33];
	static weapon_active, weapon_num
	weapon_active = read_data(1)
	weapon_num = read_data(2)
	
 	if( ( weapon_num != last_weapon[id] ) && weapon_active && get_pcvar_num(kz_maxspeedmsg) == 1)
	{
		last_weapon[id] = weapon_num;
		
		static Float:maxspeed;
		pev(id, pev_maxspeed, maxspeed );
		
		if( maxspeed < 0.0 )
			maxspeed = 250.0;
		
		kz_hud_message(id,"%L",id, "KZ_WEAPONS_SPEED",floatround( maxspeed, floatround_floor ));
	}
	return PLUGIN_HANDLED
}
 
public weapons(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	
	if(get_pcvar_num(kz_other_weapons) == 0)
	{	
		kz_chat(id, "%L", id, "KZ_OTHER_WEAPONS_ZERO")
		return PLUGIN_HANDLED
	}
	
	if (timer_started[id])
	{
		kz_chat(id, "%L", id, "KZ_WEAPONS_IN_RUN")
		return PLUGIN_HANDLED
	}

	for(new i = 0; i < 8; i++)
		if( !user_has_weapon(id, other_weapons[i]) )
		{
			new item;
			item = give_item(id, other_weapons_name[i] );
			cs_set_weapon_ammo(item, 0);
		}
					
	if( !user_has_weapon(id, CSW_USP) )
		cmdUsp(id)
		
	return PLUGIN_HANDLED
}
//========================== MEDIDOR =====================
public cmdMedidor( plr ) {
	g_vFirstLoc[plr][0] = 0.0;
	g_vFirstLoc[plr][1] = 0.0;
	g_vFirstLoc[plr][2] = 0.0;
	g_vSecondLoc[plr] = g_vFirstLoc[plr];
	
	remove_task( plr + 45896 );
	set_task( 0.1, "tskBeam", plr + 45896, _, _, "ab" );
	
	menuDisplay( plr );
}
	
public menuDisplay( plr ) {
	static menu[2048];
	
	new len = format( menu, 2047, "\r[Retorno]\w Medidor distancias^n\dApunta con el cursor y presiona 1 para ver la distancia^n^n" );
	
	len += format( menu[len], 2047 - len, "\r1. \wSet Loc #1 \d< %.03f | %.03f | %.03f >^n", g_vFirstLoc[plr][0], g_vFirstLoc[plr][1], g_vFirstLoc[plr][2] );
	len += format( menu[len], 2047 - len, "\r2. \wReset Loc^n^n");
	
	if( g_vFirstLoc[plr][0] != 0.0 && g_vFirstLoc[plr][1] != 0.0 && g_vFirstLoc[plr][2] != 0.0
	&& g_vSecondLoc[plr][0] != 0.0 && g_vSecondLoc[plr][1] != 0.0 && g_vSecondLoc[plr][2] != 0.0 ) {
		len += format( menu[len], 2047 - len, "\r      Resultados:^n" );
		len += format( menu[len], 2047 - len, "\r      \wAltura units: \d%f^n", floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) );
		len += format( menu[len], 2047 - len, "\r      \wDistancia units: \y%f^n^n", get_distance_f( g_vFirstLoc[plr], g_vSecondLoc[plr] ) );
	}
	len += format( menu[len], 2047 - len, "\r0. \wExit" );
	
	show_menu(plr, Keystop_medir, menu, -1, "medidor") // Display menu
}

public menuAction( plr, key ) {
	switch( key ) {
		case 0: {
			fm_get_aim_origin( plr, g_vFirstLoc[plr] );

			get_tr2( 0, TR_vecPlaneNormal, g_vSecondLoc[plr] );

			kz_vecotr_mul_scalar( g_vSecondLoc[plr], 9999.0, g_vSecondLoc[plr] );
			kz_vector_add( g_vFirstLoc[plr], g_vSecondLoc[plr], g_vSecondLoc[plr] );

			fm_trace_line( plr, g_vFirstLoc[plr], g_vSecondLoc[plr], g_vSecondLoc[plr] );
			
			menuDisplay( plr );
		}
		case 1: {
			g_vFirstLoc[plr][0] = 0.0;
			g_vFirstLoc[plr][1] = 0.0;
			g_vFirstLoc[plr][2] = 0.0;
			g_vSecondLoc[plr] = g_vFirstLoc[plr];
			menuDisplay( plr );
		}
		case 2: {
			remove_task( plr + 45896 );
			show_menu( plr, 0, "" );
		}
	}
}

public tskBeam( plr ) {
	plr -= 45896;
	
	if( g_vFirstLoc[plr][0] != 0.0 && g_vFirstLoc[plr][1] != 0.0 && g_vFirstLoc[plr][2] != 0.0
	&& g_vSecondLoc[plr][0] != 0.0 && g_vSecondLoc[plr][1] != 0.0 && g_vSecondLoc[plr][2] != 0.0 ) {
		draw_beam( plr, g_vFirstLoc[plr], g_vSecondLoc[plr] );
		
		if( floatabs( g_vFirstLoc[plr][2] - g_vSecondLoc[plr][2] ) >= 2 ) {
			static Float:temp[3];
			temp[0] = g_vSecondLoc[plr][0];
			temp[1] = g_vSecondLoc[plr][1];
			temp[2] = g_vFirstLoc[plr][2];
			
			draw_beam( plr, g_vFirstLoc[plr], temp );
			draw_beam( plr, temp, g_vSecondLoc[plr] );
		}
	}
}

public draw_beam( plr, Float:aorigin[3], Float:borigin[3] ) {
	message_begin( MSG_ONE_UNRELIABLE, SVC_TEMPENTITY, _, plr );
	write_byte( TE_BEAMPOINTS );
	engfunc( EngFunc_WriteCoord, aorigin[0] );
	engfunc( EngFunc_WriteCoord, aorigin[1] );
	engfunc( EngFunc_WriteCoord, aorigin[2] );
	engfunc( EngFunc_WriteCoord, borigin[0] );
	engfunc( EngFunc_WriteCoord, borigin[1] );
	engfunc( EngFunc_WriteCoord, borigin[2] );
	write_short( Sbeam );
	write_byte( 0 );
	write_byte( 0 );
	write_byte( 2 );
	write_byte( 20 );
	write_byte( 0 );
	write_byte( 255 );	// 255 85 0
	write_byte( 128 );
	write_byte( 0 );
	write_byte( 150 );
	write_byte( 0 );
	message_end( );
}

fm_get_aim_origin( plr, Float:origin[3] ) {
	new Float:start[3], Float:view_ofs[3];
	pev( plr, pev_origin, start );
	pev( plr, pev_view_ofs, view_ofs );
	xs_vec_add( start, view_ofs, start );

	new Float:dest[3];
	pev( plr, pev_v_angle, dest );
	engfunc( EngFunc_MakeVectors, dest);
	global_get( glb_v_forward, dest );
	xs_vec_mul_scalar( dest, 9999.0, dest );
	xs_vec_add( start, dest, dest );

	engfunc( EngFunc_TraceLine, start, dest, 0, plr, 0 );
	get_tr2( 0, TR_vecEndPos, origin );

	return 1;
}

fm_trace_line( ignoreent, const Float:start[3], const Float:end[3], Float:ret[3] )
{
	engfunc( EngFunc_TraceLine, start, end, ignoreent == -1 ? 1 : 0, ignoreent, 0 );

	new ent = get_tr2( 0, TR_pHit );
	get_tr2( 0, TR_vecEndPos, ret );

	return pev_valid( ent ) ? ent : 0;
}

stock kz_vector_add(const Float:in1[], const Float:in2[], Float:out[])
{
	out[0] = in1[0] + in2[0];
	out[1] = in1[1] + in2[1];
	out[2] = in1[2] + in2[2];
}

stock kz_vecotr_mul_scalar(const Float:vec[], Float:scalar, Float:out[])
{
	out[0] = vec[0] * scalar;
	out[1] = vec[1] * scalar;
	out[2] = vec[2] * scalar;
}



// ========================= Scout =======================
public cmdScout(id)
{
	if (timer_started[id])
		user_has_scout[id] = true
		
	strip_user_weapons(id)
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")
	if( !user_has_weapon(id, CSW_SCOUT))
		give_item(id,"weapon_scout")
	
	return PLUGIN_HANDLED
}

public cmdUsp(id)
{
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")
	
	return PLUGIN_HANDLED
}

// ========================== Start location =================

public goStart(id)
{
	if( !is_user_alive( id ) )
	{		
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	new CsTeams:team = cs_get_user_team(id)
	if (team == CS_TEAM_SPECTATOR)
	{
		ct(id);
	}	
	if (IsPaused[id] == false)
	{
		Pause(id)
	}

	if(get_pcvar_num(kz_save_autostart) == 1 && AutoStart [id] )
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
		set_pev(id, pev_origin, SavedStart [id] )
		
		set_pev(id, pev_angles, gCheckpointAngle_s[id]);
		set_pev(id, pev_fixangle, 1);
		
		kz_chat(id, "%L", id, "KZ_START")
		remove_hook(id, 0)
	}
	else if ( DefaultStart )
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_origin, DefaultStartPos)

		kz_chat(id, "%L", id, "KZ_START")
		remove_hook(id, 0)
	}
	else
	{	
		//kz_chat(id, "%L", id, "KZ_NO_START")
		//ColorChat(id, RED, "%s ^1Fuiste llevado al spawn, no se encontro un Start.", prefix)
		CmdRespawn(id)
	}

	return PLUGIN_HANDLED
}

public setStart(id)
{
	if (! (get_user_flags( id ) & KZ_LEVEL ))
	{
		kz_chat(id, "%L", id, "KZ_NO_ACCESS")
		return PLUGIN_HANDLED
	}
    
	new Float:origin[3]
	pev(id, pev_origin, origin)
	
	kz_set_start(MapName, origin)
	AutoStart[id] = false;
	ColorChat(id, GREEN, "%s^x01 %L.", prefix, id, "KZ_SET_START")
	
	return PLUGIN_HANDLED
}

// ========= Respawn CT if dies ========

public Ham_CBasePlayer_Killed_Post(id) 
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	if(get_pcvar_num(kz_respawn_ct) == 1)
	{
		if( cs_get_user_team(id) == CS_TEAM_CT )
		{
			set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
   			cs_set_user_deaths(id, 0)
			set_user_frags(id, 0)
			if(gochecknumbers[id] <= 0){
				if( contain( szMapName, "deathrun" ) != -1 || contain( szMapName, "Deathrun" ) != -1)
				{
					touch_trigger(id)
				}
			}
		}
	}
}


// =============================  NightVision ================================================
public cmd_NightVision(id){
	if(!is_user_connected(id))
		return PLUGIN_HANDLED;
	
	if(g_iNV[id]==OFF){
		g_iNV[id]=NORMAL;
		NV(id, "z");
	}
	else if(g_iNV[id]==NORMAL){
		g_iNV[id]=FULLBRIGHT;
		NV(id, "#");
	}
	else{
		g_iNV[id]=OFF;
		NV(id, g_sDefaultLight);
	}
	return PLUGIN_HANDLED;
}

public fw_LightStyle(style, const value[]){
	if(!style)
		copy(g_sDefaultLight, charsmax(g_sDefaultLight), value);
}

NV(id, const type[]){
	message_begin(MSG_ONE_UNRELIABLE, SVC_LIGHTSTYLE, _, id);
	write_byte(0);
	write_string(type);
	message_end();
}
// ========================================weaponsç============================================
public fwdTouch(pToucher,pTouched)
{
	if(!pev_valid(pToucher)||!pev_valid(pTouched))
		return FMRES_IGNORED

	if(!is_user_connected(pTouched))
		return FMRES_IGNORED

	new cl[32]
	pev(pToucher,pev_classname,cl,31)
	if(equal(cl,"weaponbox")||equal(cl,"armoury_entity")||equal(cl,"weapon_shield"))
		return FMRES_SUPERCEDE

	return FMRES_IGNORED
}
// ============================ Hook ==============================================================

public give_hook(id)
{
	if (!(  get_user_flags( id ) & KZ_LEVEL ))
		return PLUGIN_HANDLED

	new szarg1[32], szarg2[8], bool:mode
	read_argv(1,szarg1,32)
	read_argv(2,szarg2,32)
	if(equal(szarg2,"on"))
		mode = true
		
	if(equal(szarg1,"@ALL"))
	{
		new Alive[32], alivePlayers
		get_players(Alive, alivePlayers, "ach")
		for(new i;i<alivePlayers;i++)
		{
			canusehook[i] = mode
			if(mode)
				ColorChat(i, GREEN,  "%s^x01, %L.", prefix, i, "KZ_HOOK")
		}
	}
	else
	{
		new pid = find_player("bl",szarg1);
		if(pid > 0)
		{
			canusehook[pid] = mode
			if(mode)
			{
				ColorChat(pid, GREEN, "%s^x01 %L.", prefix, pid, "KZ_HOOK")
			}
		}
	}
	
	return PLUGIN_HANDLED
}

public hook_on(id)
{
	if( !canusehook[id] && !(  get_user_flags( id ) & KZ_LEVEL ) || !is_user_alive(id) )
		return PLUGIN_HANDLED

	if (IsPaused[id])
	{
		kz_chat(id, "%L", id, "KZ_HOOK_PAUSE")
		return PLUGIN_HANDLED
	}
	
	detect_cheat(id,"Hook")
	get_user_origin(id,hookorigin[id],3)
	ishooked[id] = true
	antihookcheat[id] = get_gametime()
	
	if (get_pcvar_num(kz_hook_sound) == 1)
	emit_sound(id,CHAN_STATIC,"weapons/xbow_hit2.wav",1.0,ATTN_NORM,0,PITCH_NORM)

	set_task(0.1,"hook_task",id,"",0,"ab")
	hook_task(id)
	
	return PLUGIN_HANDLED
}
public usahook(id){
	if(ishooked[id] == true)
		return 1;
	return 0;
}
public hook_off(id)
{
	remove_hook(id, 1)
	
	return PLUGIN_HANDLED
}

public hook_task(id)
{
	if(!is_user_connected(id) || !is_user_alive(id))
		remove_hook(id, 0)
	
	remove_beam(id)
	draw_hook(id)
	
	new origin[3], Float:velocity[3]
	get_user_origin(id,origin)
	new distance = get_distance(hookorigin[id],origin)
	velocity[0] = (hookorigin[id][0] - origin[0]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)
	velocity[1] = (hookorigin[id][1] - origin[1]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)
	velocity[2] = (hookorigin[id][2] - origin[2]) * (2.0 * get_pcvar_num(kz_hook_speed) / distance)
		
	set_pev(id,pev_velocity,velocity)
}

public draw_hook(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(1)				// TE_BEAMENTPOINT
	write_short(id)				// entid
	write_coord(hookorigin[id][0])		// origin
	write_coord(hookorigin[id][1])		// origin
	write_coord(hookorigin[id][2])		// origin
	write_short(Sbeam)			// sprite index
	write_byte(0)				// start frame
	write_byte(0)				// framerate
	write_byte(random_num(1,100))		// life
	write_byte(random_num(1,20))		// width
	write_byte(random_num(1,0))		// noise					
	write_byte(random_num(1,255))		// r
	write_byte(random_num(1,128))		// g
	write_byte(random_num(1,1))		// b
	write_byte(random_num(1,500))		// brightness
	write_byte(random_num(1,200))		// speed
	message_end()
}

public remove_hook(id, x)
{
	if(task_exists(id))
		remove_task(id)
	remove_beam(id)
	ishooked[id] = false
	
	if(timer_started[id])
		return;
	if(x == 1)
	return;
		//pass
		//set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
}

public remove_beam(id)
{
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY)
	write_byte(99) // TE_KILLBEAM
	write_short(id)
	message_end()
}


//============================ VIP In ScoreBoard =================================================

public MessageScoreAttrib( iMsgID, iDest, iReceiver )
{
	if( get_pcvar_num(kz_vip) )
	{
		new iPlayer = get_msg_arg_int( 1 )
		if( is_user_alive( iPlayer ) && ( get_user_flags( iPlayer ) & KZ_LEVEL ) )
		{
			set_msg_arg_int( 2, ARG_BYTE, SCOREATTRIB_VIP );
		}
	}
}

public EventStatusValue( const id )
{
			
	new szMessage[ 34 ], Target, aux
	get_user_aiming(id, Target, aux)
	if (is_user_alive(Target))
	{
		formatex( szMessage, 33, "1 %s: %%p2", get_user_flags( Target ) & KZ_LEVEL ? "VIP" : "Player" )
		message_begin( MSG, get_user_msgid( "StatusText" ) , _, id )
		write_byte( 0 )
		write_string( szMessage )
		message_end( )
	}
}

public detect_cheat(id,reason[])
{ 
	if(timer_started[id] && get_pcvar_num(kz_cheatdetect) == 1) 
	{
		timer_started[id] = false
		if(IsPaused[id])
		{
			//set_pev(id, pev_flags, pev(id, pev_flags) & ~)
			IsPaused[id] = false
		}
		if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
			kz_showtime_roundtime(id, 0)
		ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_CHEAT_DETECT", reason)
	}
}
 
// =================================================================================================
// Cmds
// =================================================================================================

public CheckPoint(id)
{
	
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	
	if(get_pcvar_num(kz_checkpoints) == 0)
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_OFF")
		return PLUGIN_HANDLED
	}

	if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) && !IsOnLadder(id))
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_AIR")
		return PLUGIN_HANDLED
	}
		
	if( IsPaused[id] )
	{
		kz_chat(id, "%L", id, "KZ_CHECKPOINT_PAUSE")
		return PLUGIN_HANDLED
	}
	pev(id, pev_v_angle, gCheckpointAngle[id])
	pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id] ? 1 : 0])
	g_bCpAlternate[id] = !g_bCpAlternate[id] 
	checknumbers[id]++
	
	set_user_frags(id, checknumbers[id])
	cs_set_user_deaths(id, gochecknumbers[id])
	
	kz_chat(id, "%L", id, "KZ_CHECKPOINT", checknumbers[id])

	return PLUGIN_HANDLED
}
public GoCheck(id) 
{
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if( checknumbers[id] == 0  ) 
	{
		kz_chat(id, "%L", id, "KZ_NOT_ENOUGH_CHECKPOINTS")
		return PLUGIN_HANDLED
	}

	if( IsPaused[id] )
	{
		kz_chat(id, "%L", id, "KZ_TELEPORT_PAUSE")	
		return PLUGIN_HANDLED
	}
	remove_hook(id, 0)
	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} );
	set_pev( id, pev_view_ofs, Float:{  0.0,   0.0,  12.0 } );
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING );
	set_pev( id, pev_fuser2, 0.0 );
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 } );
	set_pev(id, pev_origin, Checkpoints[ id ][ !g_bCpAlternate[id] ] )
	
	set_pev(id, pev_angles, gCheckpointAngle[id]);
	set_pev(id, pev_fixangle, 1);
	
	gochecknumbers[id]++
	
	set_user_frags(id, checknumbers[id])
	cs_set_user_deaths(id, gochecknumbers[id])
	
	kz_chat(id, "%L", id, "KZ_GOCHECK", gochecknumbers[id])
	return PLUGIN_HANDLED
}

public Stuck(id)
{
	if( !is_user_alive( id ) )
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}

	if( checknumbers[id] < 2 ) 
	{
		kz_chat(id, "%L", id, "KZ_NOT_ENOUGH_CHECKPOINTS")
		return PLUGIN_HANDLED
	}

	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} )
	set_pev( id, pev_view_ofs, Float:{  0.0,   0.0,  12.0 })
	set_pev( id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
	set_pev( id, pev_fuser2, 0.0 )
	engfunc( EngFunc_SetSize, id, {-16.0, -16.0, -18.0 }, { 16.0, 16.0, 32.0 } )
	set_pev(id, pev_origin, Checkpoints[id][g_bCpAlternate[id]] )
	g_bCpAlternate[id] = !g_bCpAlternate[id];
	gochecknumbers[id]++
	
	kz_chat(id, "%L", id, "KZ_GOCHECK", gochecknumbers[id])
	
	return PLUGIN_HANDLED;
}
 
 
public set_client_start(id){
	if(!is_user_alive(id))
		return PLUGIN_HANDLED
		
	if( !( pev( id, pev_flags ) & FL_ONGROUND2 ) && !IsOnLadder(id))
	{
		kz_chat(id, "%L", id, "KZ_SET_PERSONALSTART_FAIL")
		return PLUGIN_HANDLED
	}
	user_set_another_point[id] = 1
	pev(id, pev_origin, SavedStart[id])
	pev(id, pev_v_angle, gCheckpointAngle_s[id]);
	kz_chat(id, "%L", id, "KZ_SET_PERSONALSTART")
	return PLUGIN_HANDLED
}
// =================================================================================================
 
public reset_checkpoints(id) 
{
	checknumbers[id] = 0
	gochecknumbers[id] = 0
	timer_started[id] = false
	timer_time[id] = 0.0
	user_has_scout[id] = false
	set_user_godmode(id, 0)
	if(IsPaused[id])
	{
		//set_pev(id, pev_flags, pev(id, pev_flags) & ~)
		IsPaused[id] = false
	}
	if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)

	return PLUGIN_HANDLED
}

//===== Invis =======

public cmdInvisible(id)
{

	gViewInvisible[id] = !gViewInvisible[id]
	if(gViewInvisible[id])
		kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_ON")
	else
		kz_chat(id, "%L", id, "KZ_INVISIBLE_PLAYERS_OFF")

	return PLUGIN_HANDLED
}

public cmdWaterInvisible(id)
{
	if( !gWaterFound )
	{
		kz_chat(id, "%L", id, "KZ_INVISIBLE_NOWATER")
		return PLUGIN_HANDLED
	}
	
	gWaterInvisible[id] = !gWaterInvisible[id]
	if(gWaterInvisible[id])
		kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_ON")
	else
		kz_chat(id, "%L", id, "KZ_INVISIBLE_WATER_OFF")
		
	return PLUGIN_HANDLED
}

//======================Semiclip / Invis==========================

public FM_client_AddToFullPack_Post(es, e, ent, host, hostflags, player, pSet) 
{ 
	if( player )
	{
		if (get_pcvar_num(kz_semiclip) == 1)
		{
			if ( host != ent && get_orig_retval() && is_user_alive(host) ) 
    			{ 
				set_es(es, ES_Solid, SOLID_NOT)
				set_es(es, ES_RenderMode, kRenderTransAlpha)
				set_es(es, ES_RenderAmt, get_pcvar_num(kz_semiclip_transparency))
			} 
		}
		if(gMarkedInvisible[ent] && gViewInvisible[host])
		{
 		  	set_es(es, ES_RenderMode, kRenderTransTexture)
			set_es(es, ES_RenderAmt, 0)
			set_es(es, ES_Origin, { 999999999.0, 999999999.0, 999999999.0 } )
		}
	}
	else if( gWaterInvisible[host] && gWaterEntity[ent] )
	{
		set_es(es, ES_Effects, get_es( es, ES_Effects ) | EF_NODRAW )
	}
	
	return FMRES_IGNORED
} 

public Ham_CBasePlayer_PreThink_Post(id) 
{ 
	if( !is_user_alive(id) ) 
	{ 
		return 
	} 

	RefreshPlayersList() 

	if (get_pcvar_num(kz_semiclip) == 1)
	{
		for(new i = 0; i<g_iNum; i++) 
		{ 
			g_iPlayer = g_iPlayers[i] 
			if( id != g_iPlayer ) 
			{ 
				set_pev(g_iPlayer, pev_solid, SOLID_NOT) 
			} 
		} 
	}
} 

public client_PostThink(id) 
{ 
	if( !is_user_alive(id) ) 
		return

	RefreshPlayersList() 

	if (get_pcvar_num(kz_semiclip) == 1)
		for(new i = 0; i<g_iNum; i++) 
   		{ 
			g_iPlayer = g_iPlayers[i] 
			if( g_iPlayer != id ) 
				set_pev(g_iPlayer, pev_solid, SOLID_SLIDEBOX) 
   		} 
} 
public kz_noclip_on_set(id){
	if(get_user_noclip(id) == 1){
		return PLUGIN_HANDLED
	}
	else{
		noclip(id)
	}
	return PLUGIN_HANDLED
}
public noclip(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}
	new noclip = !get_user_noclip(id)
	set_user_noclip(id, noclip)
	if(IsPaused[id] && (get_pcvar_num(kz_noclip_pause) == 1))
	{
		/*if(noclip)
		{
			pev(id, pev_origin, NoclipPos[id])
			//set_pev(id, pev_flags, pev(id, pev_flags) & ~)
		}
		else
		{
			set_pev(id, pev_origin, NoclipPos[id])
			//set_pev(id, pev_flags, pev(id, pev_flags) | )
		}*/
	}
	else if(noclip){
		detect_cheat(id,"Noclip")
		ColorChat(id, RED, "^4%s^1 Para ir rapido con noclip pulsa ^4+SHIFT ^1y^4 W", prefix)
	}
	kz_chat(id, "%L", id, "KZ_NOCLIP" , noclip ? "ON" : "OFF")
		
		
	return PLUGIN_HANDLED
}
public FwdCmdStart( client, ucHandle ) {
	if( !is_user_alive( client ) || pev( client, pev_movetype ) != MOVETYPE_NOCLIP || !( pev( client, pev_button ) & IN_FORWARD ) ) {
		return FMRES_IGNORED;
	}
	if(!get_user_noclip(client))
		return FMRES_IGNORED;
	
	static Float:fForward, Float:fSide;
	get_uc( ucHandle, UC_ForwardMove, fForward );
	get_uc( ucHandle, UC_SideMove, fSide );
    
	if( fForward == 0.0 && fSide == 0.0 ) {
		return FMRES_IGNORED;
	}
    
	static Float:fMaxSpeed;
	pev( client, pev_maxspeed, fMaxSpeed );
    
	new Float:fWalkSpeed = fMaxSpeed * 0.52;
	if( floatabs( fForward ) <= fWalkSpeed && floatabs( fSide ) <= fWalkSpeed ) {
		static Float:vOrigin[ 3 ];
		pev( client, pev_origin, vOrigin );
		
		static Float:vAngle[ 3 ];
		pev( client, pev_v_angle, vAngle );
		engfunc( EngFunc_MakeVectors, vAngle );
		global_get( glb_v_forward, vAngle );
		
		vOrigin[ 0 ] += ( vAngle[ 0 ] * 20.0 );
		vOrigin[ 1 ] += ( vAngle[ 1 ] * 20.0 );
		vOrigin[ 2 ] += ( vAngle[ 2 ] * 20.0 );
		
		engfunc( EngFunc_SetOrigin, client, vOrigin );
	}
    
	return FMRES_IGNORED;
}
public GodMode(id)
{
	if(!is_user_alive(id))
	{
		kz_chat(id, "%L", id, "KZ_NOT_ALIVE")
		return PLUGIN_HANDLED
	}	
	
	new godmode = !get_user_godmode(id)
	set_user_godmode(id, godmode)
	if(godmode)
		detect_cheat(id,"God Mode")
	kz_chat(id, "%L", id, "KZ_GODMODE" , godmode ? "ON" : "OFF")
	
	return PLUGIN_HANDLED
}
 
// =================================================================================================

stock kz_set_start(const map[], Float:origin[3])
{
	new realfile[128], tempfile[128], formatorigin[50]
	
	formatex(realfile, 127, "%s/%s", Kzdir, KZ_STARTFILE)
	formatex(tempfile, 127, "%s/%s", Kzdir, KZ_STARTFILE_TEMP)
	formatex(formatorigin, 49, "%f %f %f", origin[0], origin[1], origin[2])
	
	DefaultStartPos = origin
	DefaultStart = true
	
	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")
	
	new data[128], key[64]
	new bool:replaced = false
	
	while( !feof(vault) )
	{
		fgets(vault, data, 127)
		parse(data, key, 63)
		
		if( equal(key, map) && !replaced )
		{
			fprintf(file, "%s %s^n", map, formatorigin)
			
			replaced = true
		}
		else
		{
			fputs(file, data)
		}
	}
	
	if( !replaced )
	{
		fprintf(file, "%s %s^n", map, formatorigin)
	}
	
	fclose(file)
	fclose(vault)
	
	delete_file(realfile)
	while( !rename_file(tempfile, realfile, 1) ) {}
}

stock kz_showtime_roundtime(id, time)
{
	if( is_user_connected(id) )
	{
		message_begin(MSG, get_user_msgid( "RoundTime" ), _, id);
		write_short(time + 1);
		message_end();
	}
}

stock kz_chat(id, const message[], {Float,Sql,Result,_}:...)
{
	new cvar = get_pcvar_num(kz_chatorhud)
	if(cvar == 0)
		return PLUGIN_HANDLED
	
	new msg[180], final[192] 
	//new msg[84], final[84]
	if (cvar == 1 && chatorhud[id] == -1 || chatorhud[id] == 1)
	{
		vformat(msg, 179, message, 3)
		formatex(final, 191, "%s^x01 %s", prefix, msg)
		kz_remplace_colors(final, 191)
		ColorChat(id, GREEN, "%s", final)
	}
	else if( cvar ==  2 && chatorhud[id] == -1 || chatorhud[id] == 2)
	{
			vformat(msg, 179, message, 3)
			replace_all(msg, 191, "^x01", "")
			replace_all(msg, 191, "^x03", "")
			replace_all(msg, 191, "^x04", "")
			replace_all(msg, 191, ".", "")
			kz_hud_message(id, "%s", msg)
	}
	
	return 1
}

stock kz_print_config(id, const msg[])
{
	message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, id);
	write_byte(id);
	write_string(msg);
	message_end();
}

stock kz_remplace_colors(message[], len)
{
	replace_all(message, len, "!g", "^x04")
	replace_all(message, len, "!t", "^x03")
	replace_all(message, len, "!y", "^x01")
}

stock kz_hud_message(id, const message[], {Float,Sql,Result,_}:...)
{
	static msg[192], colors[12], r[4], g[4], b[4];
	vformat(msg, 191, message, 3);
	
	get_pcvar_string(kz_hud_color, colors, 11)
	parse(colors, r, 3, g, 3, b, 4)
	
	set_hudmessage(str_to_num(r), str_to_num(g), str_to_num(b), -1.0, 0.90, 0, 0.0, 2.0, 0.0, 1.0, -1);
	ShowSyncHudMsg(id, hud_message, msg);
}

stock kz_register_saycmd(const saycommand[], const function[], flags) 
{
	new temp[64]
	formatex(temp, 63, "say /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say .%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team /%s", saycommand)
	register_clcmd(temp, function, flags)
	formatex(temp, 63, "say_team .%s", saycommand)
	register_clcmd(temp, function, flags)
}

stock get_configsdir(name[],len)
{
	return get_localinfo("amxx_configsdir",name,len);
}

#if defined USE_SQL
	// OLD CODE SQL TOP REMOVIDO
#endif

public FwdSpawnWeaponbox( iEntity )
{
	if(get_pcvar_num(kz_remove_drops) == 1)
	{
		set_pev( iEntity, pev_flags, FL_KILLME )
		dllfunc( DLLFunc_Think, iEntity )
	}
	
	return HAM_IGNORED
}

public FwdHamDoorSpawn( iEntity )
{
	static const szNull[ ] = "common/null.wav";
	
	new Float:flDamage;
	pev( iEntity, pev_dmg, flDamage );
	
	if( flDamage < -999.0 ) {
		set_pev( iEntity, pev_noise1, szNull );
		set_pev( iEntity, pev_noise2, szNull );
		set_pev( iEntity, pev_noise3, szNull );
		
		if( !HealsOnMap )
			HealsOnMap = true
	}
}
public axnmapmsj(id)
	ColorChat(id, RED,  "^4%s^1 Se activo el MODO ^4AXN^1 (BHOP + SPEED)", prefix)
public FwdHamPlayerSpawn( id )
{
	new szMapName[ 21 ];
	get_mapname( szMapName, 20 );
	
	if( !is_user_alive( id ) )
		return;

	if(firstspawn[id])
	{
		ColorChat(id, RED, "^1ProKreedz v3 ^3nuclear. ^3Edit + addons ^1by^3 Orange")
		if(is_map_axn == true){
			set_task(2.0, "axnmapmsj", id)
		}
		if(get_pcvar_num(kz_checkpoints) == 0)
			ColorChat(id, GREEN,  "%s^x01 %L", id, "KZ_CHECKPOINT_OFF", prefix)


		if(Verif(id,1) && get_pcvar_num(kz_save_pos) == 1)
			savepos_menu(id)
		else if(get_pcvar_num(kz_spawn_mainmenu) == 1)
			kz_menu (id)
		
	}
	firstspawn[id] = false
	
	strip_user_weapons(id);
	if( !user_has_weapon(id,CSW_KNIFE) )
		give_item( id,"weapon_knife" )
	
	if( !user_has_weapon(id,CSW_USP) )
		give_item(id,"weapon_usp") 
	
	if(!is_user_bot(id)){
		if( contain( szMapName, "deathrun" ) != -1 || contain( szMapName, "Deathrun" ) != -1){
			if(gochecknumbers[id] >= 1)
				GoCheck(id) 
			else{
				set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
				set_pev(id, pev_origin, DefaultStartPos)

				kz_chat(id, "%L", id, "KZ_START")
				remove_hook(id, 0)
			}
		}
		
	}
	
	if( HealsOnMap )
		set_user_health(id, 133337)
	
	if( contain( szMapName, "slide" ) != -1 || contain( szMapName, "surf" ) != -1){
			set_user_health(id, 133337)
	}
		
	if(get_pcvar_num(kz_use_radio) == 0)
	{
		#define XO_PLAYER				5
		#define	m_iRadiosLeft			192
		set_pdata_int(id, m_iRadiosLeft, 0, XO_PLAYER)
	}
}

public GroundWeapon_Touch(iWeapon, id)
{
	if( is_user_alive(id) && timer_started[id] && get_pcvar_num(kz_pick_weapons) == 0 )
		return HAM_SUPERCEDE

	return HAM_IGNORED
}
 
 
 
// ==================================Save positions=================================================
 
public SavePos(id)
{

	new authid[33];
	get_user_authid(id, authid, 32)
	if(get_pcvar_num(kz_save_pos) == 0)
	{
		kz_chat(id, "%L", id, "KZ_SAVEPOS_DISABLED")
		return PLUGIN_HANDLED
	}

	if(equal(authid, "VALVE_ID_LAN") || equal(authid, "STEAM_ID_LAN"))
	{
		ColorChat(id, GREEN,  "%s^x01 Tenes que ser steam para guardar tu tiempo", prefix)
		
		return PLUGIN_HANDLED
	}	
	if(!timer_started[id])
	{
		kz_chat(id, "%L", id, "KZ_TIMER_NOT_STARTED")
		return PLUGIN_HANDLED
	}
	if(!is_user_alive(id))
	{
		ColorChat(id, GREEN,  "%s^x01 Tenes que estar en RUN para guardar tu Pos", prefix)
		return PLUGIN_HANDLED
	}
	
	if(Verif(id,1))
	{
		ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS_ALREADY")
		savepos_menu(id)
		return PLUGIN_HANDLED
	}
	
	if(get_user_noclip(id))
	{
		ColorChat(id, GREEN, "%s^x01 %L", prefix, id, "KZ_SAVEPOS_NOCLIP")
		return PLUGIN_HANDLED
	}
	
	new Float:origin[3], scout
	pev(id, pev_origin, origin)
	new Float:Time,check,gocheck 
	if(IsPaused[id])
	{
		Time = g_pausetime[id]
		Pause(id)
	}
	else
		Time=get_gametime() - timer_time[id]
	check=checknumbers[id]
	gocheck=gochecknumbers[id]
	ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS")
	if (user_has_scout[id])
		scout=1
	else
		scout=0
	kz_savepos(id, Time, check, gocheck, origin, scout)
	reset_checkpoints(id)
	
	return PLUGIN_HANDLED
}

public GoPos(id)
{
	remove_hook(id, 0)
	set_user_godmode(id, 0)
	set_user_noclip(id, 0)
	if(Verif(id,0))
	{
		set_pev(id, pev_velocity, Float:{0.0, 0.0, 0.0})
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_DUCKING )
		set_pev(id, pev_origin, SavedOrigins[id] )
	}
	
	checknumbers[id]=SavedChecks[id]
	gochecknumbers[id]=SavedGoChecks[id]+((get_pcvar_num(kz_save_pos_gochecks)>0) ? 1 : 0)
	CheckPoint(id)
	CheckPoint(id)
	strip_user_weapons(id)
	give_item(id,"weapon_usp")
	give_item(id,"weapon_knife")
	if(SavedScout[id])
	{
		give_item(id, "weapon_scout")
		user_has_scout[id] = true
	}
	timer_time[id]=get_gametime()-SavedTime[id]
	timer_started[id]=true
	//Pause(id)
	
}

public Verif(id, action)
{
	new realfile[128], tempfile[128], authid[32], map[64]
	new bool:exist = false
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(tempfile, 127, "%s/temp.ini", SavePosDir)
	
	if( !file_exists(realfile) )
		return 0

	new file = fopen(tempfile, "wt")
	new vault = fopen(realfile, "rt")
	new data[150], sid[32], time[25], checks[5], gochecks[5], x[25], y[25], z[25], scout[5]
	while( !feof(vault) )
	{
		fgets(vault, data, 149)
		parse(data, sid, 31, time, 24,  checks, 4, gochecks, 4, x, 24,  y, 24, z, 24, scout, 4)
		
		if( equal(sid, authid) && !exist) // ma aflu in fisier?
		{
			if(action == 1)
				fputs(file, data)
			exist= true 
			SavedChecks[id] = str_to_num(checks)
			SavedGoChecks[id] = str_to_num(gochecks)
			SavedTime[id] = str_to_float(time)
			SavedOrigins[id][0]=str_to_num(x)
			SavedOrigins[id][1]=str_to_num(y)
			SavedOrigins[id][2]=str_to_num(z)
			SavedScout[id] = str_to_num(scout)
		}
		else
		{
			fputs(file, data) 
		}
	}

	fclose(file)
	fclose(vault)
	
	delete_file(realfile)
	if(file_size(tempfile) == 0)
		delete_file(tempfile)
	else	
		while( !rename_file(tempfile, realfile, 1) ) {}
	
	
	if(!exist)
		return 0
	
	return 1
}
public kz_savepos (id, Float:time, checkpoints, gochecks, Float:origin[3], scout)
{
	new realfile[128], formatorigin[128], map[64], authid[32]
	get_mapname(map, 63)
	get_user_authid(id, authid, 31)
	formatex(realfile, 127, "%s/%s.ini", SavePosDir, map)
	formatex(formatorigin, 127, "%s %f %d %d %d %d %d %d", authid, time, checkpoints, gochecks, origin[0], origin[1], origin[2], scout)
	
	new vault = fopen(realfile, "rt+")
	write_file(realfile, formatorigin) // La sfarsit adaug datele mele
	
	fclose(vault)
	
}
 
// =================================================================================================
// Events / Forwards
// =================================================================================================
 
//=================================================================================================
 
public client_disconnect(id)
{
	if( id == g_bot_id )
	{
		g_bot_id = 0;
		g_bot_enable = 0;
		g_bot_frame = 0;
	}
	else{

		SavePos(id)
		checknumbers[id] = 0
		user_set_another_point[id] = 0
		gochecknumbers[id] = 0
		savespec[id] = 0
		antihookcheat[id] = 0.0
		chatorhud[id] = -1
		timer_started[id] = false
		ShowTime[id] = get_pcvar_num(kz_show_timer)
		firstspawn[id] = true
		g_iNV[id]=OFF;
		IsPaused[id] = false
		WasPaused[id] = false
		user_has_scout[id] = false
		remove_hook(id, 0)
		ArrayClear(g_DemoReplay[id]);
		remove_task( id + 45896 );
	}
	
}
 
public client_putinserver(id)
{	
	checknumbers[id] = 0
	user_set_another_point[id] = 0
	gochecknumbers[id] = 0
	savespec[id] = 0
	antihookcheat[id] = 0.0
	chatorhud[id] = -1
	timer_started[id] = false
	ShowTime[id] = get_pcvar_num(kz_show_timer)
	firstspawn[id] = true
	g_iNV[id]=OFF;
	IsPaused[id] = false
	WasPaused[id] = false
	user_has_scout[id] = false
	remove_hook(id, 0)

}
 
// =================================================================================================
// Menu
// =================================================================================================

public touch_trigger(id){
	reset_checkpoints(id)
	kz_menu(id)
	goStart(id)
}

public kz_menu(id)
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	new x = map_dif()
	new mapdif[17]
	if(x == 0)
		formatex(mapdif, 16, "\d(Unknown)") 
	else if(x == 1)
		formatex(mapdif, 16, "\d(\yEasy\d)")
	else if(x == 2)
		formatex(mapdif, 16, "\d(\yAverage\d)")
	else if(x == 3)
		formatex(mapdif, 16, "\d(\rHard\d)")
	else if(x == 4)
		formatex(mapdif, 16, "\d(\rExtreme\d)")
		
	new title[240];
	formatex(title, 239, "\r%s \yKz Menu \wMapa \y%s^n\wDificultad %s \wAiraccelerate \y* %d *\w %s", prefix, szMapName, mapdif, airac, is_map_axn == true ? "| SPEED-BHOP \y( ON )\w" : "")
	new menu = menu_create(title, "MenuHandler")  
	
	new msgcheck[64], msggocheck[64], msgpause[64]
	formatex(msgcheck, 63, "Checkpoint \y#%i", checknumbers[id])
	formatex(msggocheck, 63, "Gocheck \y#%i",  gochecknumbers[id])
	formatex(msgpause, 63, "Pausa [%s]", IsPaused[id] ? "\yON\w" : "\rOFF\w" )
	
	menu_additem( menu, msgcheck, "1" )
	menu_additem( menu, msggocheck, "2" )
	menu_additem( menu, "Extras^n", "3")
	
	menu_additem( menu, "Start", "4")
	menu_additem( menu, "Set Startpos^n", "5")
	
	menu_additem( menu, msgpause, "6" )
	menu_additem( menu, "Save Run", "7")
	
	menu_additem( menu, "Spec/CT", "8" )
	menu_additem( menu, "Reset Time^n", "9")
	menu_additem( menu, "Salir", "MENU_EXIT" )
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public MenuHandler(id , menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 

	switch(item) {
		case 0:{
			CheckPoint(id)
			kz_menu(id)
			remove_hook(id, 0)
		}
		case 1:{
			GoCheck(id)
			kz_menu(id) 
		}
		case 2:{
			kz_menu2(id)
		}
		case 3:{
			goStart(id)
			kz_menu(id)
			remove_hook(id, 0)
		}
		case 4:{
			set_client_start(id)
			kz_menu(id)
		}
		case 5:{
			Pause(id)
			kz_menu(id)
		}
		case 6:{
			SavePos(id)
		}
		case 7:{
			ct(id)
		}
		case 8:{
			are_sure(id)
		}
	}

	return PLUGIN_HANDLED
}


public kz_menu2(id)
{	
	new title[64];
	formatex(title, 63, "\r%s \yKreedz Menu EXTRAS\w.",prefix)
	new menu = menu_create(title, "MenuHandler2")  
	
	menu_additem( menu, "Estilo de cronometro", "1" )
	menu_additem( menu, "Invis Player/Agua", "2" )
	menu_additem( menu, "Top 15 Pro/Nub", "3" )
	menu_additem( menu, "Player Teleport", "4" )
	menu_additem( menu, "Medir distancisa^n^n", "5" )
	menu_additem( menu, "Salir", "MENU_EXIT" )
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public MenuHandler2(id , menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 

	switch(item) {
		case 0:{
			ShowTimer_Menu(id)
		}
		case 1:{
			InvisMenu(id)
		}
		case 2:{
			top15menu(id)
		}
		case 3:{
			menu_tp(id)
		}
		case 4:{
			cmdMedidor(id)
		}
		
	}

	return PLUGIN_HANDLED
}
public are_sure(id){
	if(!timer_started[id])
	{
		kz_chat(id, "%L", id, "KZ_TIMER_NOT_STARTED")
		return PLUGIN_HANDLED
	}
	new title[64];
	formatex(title, 63, "\r%s \wQueres resetear y empezar de nuevo?.",prefix)
	new menu = menu_create(title, "MenuHandler_reset")  
	
	menu_additem( menu, "Reset time", "1" )
	menu_additem( menu, "Continuar run", "2" )
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}
public MenuHandler_reset(id , menu, item)
{
	switch(item) {
		case 0:{
			reset_checkpoints(id)
			kz_menu(id)
		}
		case 1:{
			kz_menu(id)
		}
		
	}

	return PLUGIN_HANDLED
}

public InvisMenu(id)
{
	new title[64];
	formatex(title, 63, "\r[%s] \wInvis Menu\w",prefix)
	new menu = menu_create(title, "InvisMenuHandler")  
	
	new msginvis[64], msgwaterinvis[64]
	
	formatex(msginvis, 63, "Players - %s",  gViewInvisible[id] ? "\yON" : "\rOFF" )
	formatex(msgwaterinvis, 63, "Water - %s^n^n", gWaterInvisible[id] ? "\yON" : "\rOFF" )
	
	menu_additem( menu, msginvis, "1" )
	menu_additem( menu, msgwaterinvis, "2" )
	menu_additem( menu, "Main Menu", "3" )

	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public InvisMenuHandler (id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{
		case 0:
		{
			cmdInvisible(id)
			InvisMenu(id)
		}
		case 1:
		{
			cmdWaterInvisible(id)
			InvisMenu(id)
		}
		case 2:
		{
			kz_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public ShowTimer_Menu(id)
{
	if (get_pcvar_num(kz_show_timer) == 0 )
	{
		kz_chat(id, "%L", id, "KZ_TIMER_DISABLED")
		return PLUGIN_HANDLED
	}
	else 
	{
		new title[64];
		formatex(title, 63, "\r[%s] \wTimer Menu\w",prefix)
		new menu = menu_create(title, "TimerHandler")  

		new roundtimer[64], hudtimer[64], notimer[64];
	
		formatex(roundtimer, 63, "Round Timer %s", ShowTime[id] == 2 ? "\y x" : "" )
		formatex(hudtimer, 63, "HUD Timer %s", ShowTime[id] == 1 ? "\y x" : "" )
		formatex(notimer, 63, "No Timer %s^n", ShowTime[id] == 0 ? "\y x" : "" )
	
		menu_additem( menu, roundtimer, "1" )
		menu_additem( menu, hudtimer, "2" )
		menu_additem( menu, notimer, "3" )
		menu_additem( menu, "Main Menu", "4" )

		menu_display(id, menu, 0)
		return PLUGIN_HANDLED 
	}

	return PLUGIN_HANDLED
}

public TimerHandler (id, menu, item)
{
	if( item == MENU_EXIT )
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}

	switch(item)
	{

		case 0:
		{
			ShowTime[id]= 2
			ShowTimer_Menu(id)
		}
		case 1:
		{
			ShowTime[id]= 1
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 2:
		{
			ShowTime[id]= 0
			ShowTimer_Menu(id)
			if (timer_started[id])
				kz_showtime_roundtime(id, 0)
		}
		case 3:
		{
			kz_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public savepos_menu(id)
{
	new title[64];
	formatex(title, 63, "\r[%s] \wSavePos Menu\w",prefix)
	new menu = menu_create(title, "SavePosHandler")  
	
	
	menu_additem( menu, "Continuar RUN guardada", "1" )
	menu_additem( menu, "Empezar una nueva RUN", "2" )
	
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public SavePosHandler(id, menu, item)
{
	
	switch(item) 
	{
		case 0:
		{
			GoPos(id)
			kz_menu(id)
		}
		case 1:
		{
			Verif(id,0)
			kz_menu(id)
		}
	}
	return PLUGIN_HANDLED
}

public top15menu(id)
{
	new title[64];
	formatex(title, 63, "\r[%s] \wTOP 15 PRO / NUB",prefix)
	new menu = menu_create(title, "top15handler")  

	menu_additem(menu, "\wPro 15", "1", 0)
	menu_additem(menu, "\wNoob 15^n^n", "2", 0)
	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#else
	menu_additem(menu, "\wMain Menu", "3", 0)
	#endif
	
	menu_display(id, menu, 0);
	
	return PLUGIN_HANDLED;
}

public top15handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#else
	switch(item)
	{
		case 0:
		{
			ProTop_show(id)
		}
		case 1:
		{
			NoobTop_show(id)
		}
		case 2:
		{
			kz_menu(id)
		}
	}
	#endif
	
	return PLUGIN_HANDLED;
}

// =================================================================================================

// 
// Timersystem
// =================================================================================================
public fwdUse(ent, id)
{
	if( !ent || id > 32 )
	{
		return HAM_IGNORED;
	}
	
	if( !is_user_alive(id) )
	{
		return HAM_IGNORED;
	}

	
	new name[32]
	get_user_name(id, name, 31)
	
	new szTarget[ 32 ];
	pev(ent, pev_target, szTarget, 31);
	
	if( TrieKeyExists( g_tStarts, szTarget ) )
	{

		if ( get_gametime() - antihookcheat[id] < 2.0 )
		{	
			kz_hud_message( id, "%L", id, "KZ_HOOK_PROTECTION" );
			return PLUGIN_HANDLED
		}

		if(Verif(id,1))
		{
			ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SAVEPOS_SAVED")
			savepos_menu(id)
			return HAM_IGNORED
		}
		
		if ( reset_checkpoints(id) && !timer_started[id]  )
		{
			start_climb(id)
			ArrayClear(g_DemoReplay[id]);

			new wpn=get_user_weapon(id)
			for(new i = 0; i < 8; i++)
				if( user_has_weapon(id, other_weapons[i])  )
				{
					strip_user_weapons(id)
					give_item(id,"weapon_usp")
					give_item(id,"weapon_knife")
					set_pdata_int(id, 382, 24, 5)
					if(wpn==CSW_SCOUT)
					{
						user_has_scout[id]=true
						give_item(id,"weapon_scout")
					}
					else
						user_has_scout[id]=false
				}

			if( get_user_health(id) < 100 )
				set_user_health(id, 100)

			if(user_set_another_point[id] == 0){
				pev(id, pev_origin, SavedStart[id])
			}
				
			if(get_pcvar_num(kz_save_autostart) == 1)
				AutoStart[id] = true;

			if( !DefaultStart )
			{
				kz_set_start(MapName, SavedStart[id])
				ColorChat(id, GREEN,  "%s^x01 %L", prefix, id, "KZ_SET_START")
			}

			remove_hook(id, 0)
		}
		
	}
	
	if( TrieKeyExists( g_tStops, szTarget ) )
	{
		if( timer_started[id] )
		{
			if(get_user_noclip(id))
				return PLUGIN_HANDLED
				
			finish_climb(id)
			
			if (id == g_bot_id)
				Start_Bot();

			if(get_pcvar_num(kz_hook_prize) == 1 && !canusehook[id])
			{
				canusehook[id] = true
				ColorChat(id, GREEN,  "%s^x01 %L.", prefix, id, "KZ_HOOK")
			}
		}
		else
			kz_hud_message(id, "%L", id, "KZ_TIMER_NOT_STARTED")

		}
	return HAM_IGNORED
}
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ RECORD REPLAY ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
//~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
ReadBestRunFile()
{		
		new szMapName[ 64 ];
		get_mapname( szMapName, 63 );
	
		new ArrayData[DemoData]

		new szFile[128], len
		format(szFile, sizeof(szFile) - 1, "%s/records", DATADIR) 		
		if( !dir_exists(szFile) ) mkdir(szFile);							

		format(szFile, sizeof(szFile) - 1, "%s/%s.txt", szFile, g_szMapName)	

		if (file_exists(szFile)) 											
		{
			g_fileRead = true
			read_file(szFile,1,g_ReplayName,63,len)
			if( contain( szMapName, "deathrun" ) != -1 || contain( szMapName, "Deathrun" ) != -1)
				set_task(1.0, "remove_botr")
			
		}
		else{
			
			if( contain( szMapName, "deathrun" ) != -1 || contain( szMapName, "Deathrun" ) != -1)
			{
				dr_bot()
			}
		}
		
		new hFile = fopen(szFile, "r"); 										
		new szData[1024];
		new szBotAngle[2][40], szBotPos[3][60], szBotVel[3][60], szBotButtons[12];

		new line;

		while(!feof(hFile))
		{
			fgets(hFile, szData, charsmax(szData));

			if(!szData[0] || szData[0] == '^n')
				continue;

			if(!line)
			{
				g_ReplayBestRunTime = str_to_float(szData);
				line++;
				continue;
			}

			strtok(szData, szBotAngle[0], charsmax(szBotAngle[]), szData, charsmax(szData), ' ', true)
			strtok(szData, szBotAngle[1], charsmax(szBotAngle[]), szData, charsmax(szData), ' ', true)

			strtok(szData, szBotPos[0], charsmax(szBotPos[]), szData, charsmax(szData), ' ', true)
			strtok(szData, szBotPos[1], charsmax(szBotPos[]), szData, charsmax(szData), ' ', true)
			strtok(szData, szBotPos[2], charsmax(szBotPos[]), szData, charsmax(szData), ' ', true)

			strtok(szData, szBotVel[0], charsmax(szBotVel[]), szData, charsmax(szData), ' ', true)
			strtok(szData, szBotVel[1], charsmax(szBotVel[]), szData, charsmax(szData), ' ', true)
			strtok(szData, szBotVel[2], charsmax(szBotVel[]), szData, charsmax(szData), ' ', true)

			strtok(szData, szBotButtons, charsmax(szBotButtons), szData, charsmax(szData), ' ', true)

			ArrayData[flBotAngle][0] = _:str_to_float(szBotAngle[0]);
			ArrayData[flBotAngle][1] = _:str_to_float(szBotAngle[1]);

			ArrayData[flBotPos][0] = _:str_to_float(szBotPos[0]);
			ArrayData[flBotPos][1] = _:str_to_float(szBotPos[1]);
			ArrayData[flBotPos][2] = _:str_to_float(szBotPos[2]);

			ArrayData[flBotVel][0] = _:str_to_float(szBotVel[0]);
			ArrayData[flBotVel][1] = _:str_to_float(szBotVel[1]);
			ArrayData[flBotVel][2] = _:str_to_float(szBotVel[2]);

			ArrayData[iButton] = _: str_to_num(szBotButtons);

			ArrayPushArray(g_DemoPlaybot[0], ArrayData);
			line++;
		}
		fclose(hFile);
		bot_restart();

		return PLUGIN_HANDLED;
}
public remove_botr(){
	server_cmd("kick [RoundBot]")
	call_onetime = 0;
}
public dr_bot(){
	if(call_onetime == 1)
		return PLUGIN_HANDLED;
		
	new txt[64]
	formatex(txt, charsmax(txt), "[RoundBot]");
	new id = engfunc(EngFunc_CreateFakeClient, txt);
	if(pev_valid(id))
	{
		set_user_info(id, "rate", "3500");
		set_user_info(id, "cl_updaterate", "60");
		set_user_info(id, "cl_cmdrate", "60");
		set_user_info(id, "cl_lw", "0");
		set_user_info(id, "cl_lc", "0");
		set_user_info(id, "cl_dlmax", "128");
		set_user_info(id, "cl_righthand", "1");
		set_user_info(id, "_vgui_menus", "0");
		set_user_info(id, "ah", "1");
		set_user_info(id, "dm", "0");
		set_user_info(id, "tracker", "0");
		set_user_info(id, "friends", "0");
		set_user_info(id, "*bot", "1");
			
		set_pev(id, pev_velocity, 250);
		set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
		set_pev(id, pev_colormap, id);
			
		dllfunc(DLLFunc_ClientConnect, id, "ROUND BOT", "127.0.0.1");
		dllfunc(DLLFunc_ClientPutInServer, id);
			
		cs_set_user_team(id, CS_TEAM_CT);
		//cs_set_user_model(id, "VIP");
		set_user_frags(id,13333337);
					
		strip_user_weapons(id)
		give_item(id,"weapon_usp") 
					
		if(!is_user_alive(id))
			dllfunc(DLLFunc_Spawn, id);
			
		call_onetime = 1;
		
	}
	return PLUGIN_HANDLED;
}
public ClCmd_UpdateReplay(id, Float:timer, Float:x)
{	
	new szName[16];
	get_user_name(id, szName, 15)
	
	g_ReplayBestRunTime = timer;
	
	new szFile[128], szData[128];
	format(szFile, sizeof(szFile) - 1, "%s/records/%s.txt", DATADIR, g_szMapName)
	delete_file(szFile)

	new hFile = fopen(szFile, "wt");
	
	ArrayClear(g_DemoPlaybot[0]);
	new str[25], nick[25];
	
	formatex(str, charsmax(str), "%f^n", g_ReplayBestRunTime);
	
	if(x == 0.1)
		formatex(nick, charsmax(nick), "[Nub] %s.^n", szName);
	else if(x == 1.0)
		formatex(nick, charsmax(nick), "[Pro] %s.^n", szName);
		
	fputs(hFile, str);
	fputs(hFile, nick);
	
	new ArrayData[DemoData], ArrayData2[DemoData];
	for(new i; i < ArraySize(g_DemoReplay[id]); i++)
	{
		ArrayGetArray(g_DemoReplay[id], i, ArrayData);
		ArrayData2[flBotAngle][0] = _:ArrayData[flBotAngle][0]
		ArrayData2[flBotAngle][1] = _:ArrayData[flBotAngle][1]
		ArrayData2[flBotVel][0] = _:ArrayData[flBotVel][0]
		ArrayData2[flBotVel][1] = _:ArrayData[flBotVel][1]
		ArrayData2[flBotVel][2] = _:ArrayData[flBotVel][2]
		ArrayData2[flBotPos][0] = _:ArrayData[flBotPos][0]
		ArrayData2[flBotPos][1] = _:ArrayData[flBotPos][1]
		ArrayData2[flBotPos][2] = _:ArrayData[flBotPos][2]
		ArrayData2[iButton] = ArrayData[iButton]
		if(i >= ArraySize(g_DemoReplay[id]))
		{
			ArrayPushArray(g_DemoReplay[id], ArrayData2);
		}
		else
		{
			ArraySetArray(g_DemoReplay[id], i, ArrayData2);
		}
		formatex(szData, sizeof(szData) - 1, "%f %f %f %f %f %f %f %f %d^n", ArrayData2[flBotAngle][0], ArrayData2[flBotAngle][1],
			ArrayData2[flBotPos][0], ArrayData2[flBotPos][1], ArrayData2[flBotPos][2], ArrayData2[flBotVel][0], ArrayData2[flBotVel][1], ArrayData2[flBotVel][2], ArrayData2[iButton]);
		fputs(hFile, szData);
	}
	fclose(hFile);

	set_task(2.0, "bot_overwriting")
}

public bot_restart()
{
	if (g_fileRead)
	{
		if(!g_bot_id){
			g_bot_id = Create_Bot();
			set_task(0.2, "startbot")
		}
		else
			Start_Bot();
			
	}
}

public fwd_Think( iEnt )
{
	if ( !pev_valid( iEnt ) )
	{
		return(FMRES_IGNORED);
	}
	static className[32];
	pev( iEnt, pev_classname, className, 31 );

	
	if ( equal( className, "bot_record_sv" ) )
	{
		BotThink( g_bot_id );
		set_pev( iEnt, pev_nextthink, get_gametime() + nExttHink );
	}
	
	return(FMRES_IGNORED);
}

public BotThink( id )
{	
	static ViewKeys;
	static Float:last_check, Float:game_time;
	game_time = get_gametime();

	if( game_time - last_check > nExttHink)
	{
		if (nFrame < 100)
		{
			//nExttHink = nExttHink - 0.0001
			set_pev( id, pev_nextthink, get_gametime() + nExttHink - 0.001);
		}
		if (nFrame > 100)
		{
			//nExttHink = nExttHink + 0.0001
			set_pev( id, pev_nextthink, get_gametime() + nExttHink + 0.001);
		}
		nFrame = 0;
		last_check = game_time;
	}

	if(g_bot_enable == 1 && g_bot_id)
	{
		/*if (nFrame > 100){
			g_bot_frame++;
		}*/
		g_bot_frame++;
			
		if ( g_bot_frame < ArraySize( g_DemoPlaybot[0] ) )
		{
			
			new ArrayData[DemoData], Float:ViewAngles[3];
			ArrayGetArray(g_DemoPlaybot[0], g_bot_frame, ArrayData);
			ViewKeys = ArrayData[iButton];
			
			ViewAngles[0] = ArrayData[flBotAngle][0];
			ViewAngles[1] = ArrayData[flBotAngle][1];
			ViewAngles[2] = 0.0;
			
			
			#define InMove (ViewKeys & IN_FORWARD || ViewKeys & IN_LEFT || ViewKeys & IN_RIGHT || ViewKeys & IN_BACK)
			new flag = pev(id, pev_flags);
			
			if (flag&FL_ONGROUND)
			{
				if ( ViewKeys & IN_DUCK && InMove )
				{
					set_pev( id, pev_gaitsequence, 5 );
				}
				else if ( ViewKeys & IN_DUCK )
				{
					set_pev( id, pev_gaitsequence, 2 );
				}
				else  
				{
					set_pev( id, pev_gaitsequence, 4 );
				}
				if ( ViewKeys & IN_JUMP )
				{
					set_pev( id, pev_gaitsequence, 6 );
				}
				else  
				{
					set_pev( id, pev_gaitsequence, 4 );
				}
			}
			else  
			{
				set_pev( id, pev_gaitsequence, 6 );
				if ( ViewKeys & IN_DUCK )
				{
					set_pev( id, pev_gaitsequence, 5 );
				}
			}
			
			/*if(ArrayData[iButton]&IN_ALT1) ArrayData[iButton]|=IN_JUMP;
			if(ArrayData[iButton]&IN_RUN)  ArrayData[iButton]|=IN_DUCK;

			if(ArrayData[iButton]&IN_RIGHT)
			{
				engclient_cmd(id, "weapon_usp");
				ArrayData[iButton]&=~IN_RIGHT;
			}
			if(ArrayData[iButton]&IN_LEFT)
			{
				engclient_cmd(id, "weapon_knife");
				ArrayData[iButton]&=~IN_LEFT;
			}
			*/
			//if ( ArrayData[iButton] & IN_USE )
			//{
			//	Ham_ButtonUse( id );
			//	ArrayData[iButton] &= ~IN_USE;
			//}
			
			
			ViewAngles[2] = 0.0;
			set_pev(id, pev_v_angle, ViewAngles );
			ViewAngles[0] /= -3.0;
			set_pev(id, pev_angles, ViewAngles);
			set_pev(id, pev_fixangle, 1 );
			engfunc(EngFunc_RunPlayerMove, id, ViewAngles, ArrayData[flBotVel][0], ArrayData[flBotVel][1], 0.0, ArrayData[iButton], 0, 10);
			
			set_pev(id, pev_velocity, ArrayData[flBotVel]);
			set_pev(id, pev_origin, ArrayData[flBotPos]);
			set_pev(id, pev_button, ArrayData[iButton] );
			set_pev(id, pev_health, 1337.0);
			set_user_godmode(id, 1)

				
			if(nFrame == ArraySize( g_DemoPlaybot[0] ) - 1){
				timer_started[g_bot_id] = true
				timer_time[g_bot_id] = get_gametime()
				Start_Bot();
			}
		} else  {
			g_bot_frame = 0;
			timer_started[g_bot_id] = true
			timer_time[g_bot_id] = get_gametime()
		}
	}
	nFrame++;
}

public Ham_PlayerPreThink(id)
{
	if(is_user_alive(id))
	{
		if(timer_started[id])
		{
			if(!IsPaused[id])
			{
				new ArrayData[DemoData];
				pev(id, pev_origin, ArrayData[flBotPos]);
				new Float:angle[3];
				pev(id, pev_v_angle, angle)
				pev(id, pev_velocity, ArrayData[flBotVel]);
				ArrayData[flBotAngle][0] = _:angle[0];
				ArrayData[flBotAngle][1] = _:angle[1];
				ArrayData[iButton] = get_user_button(id)
				ArrayPushArray(g_DemoReplay[id], ArrayData);
				
			}
		}
	}
}

public ClCmd_ReplayMenu(id)
{
	if (!(get_user_flags( id ) & KZ_LEVEL_1 ))
		return PLUGIN_HANDLED

	new title[512], szTimer[14];
	StringTimer(g_ReplayBestRunTime, szTimer, sizeof(szTimer) - 1);

	formatex(title, 500, "\wAdmin Setting Bot Replay Menu^nRecord: \y%s", szTimer)

	new menu = menu_create(title, "ReplayMenu_Handler")

	menu_additem(menu, "Start/Reset^n", "1");
	if (g_bot_enable == 1)
		menu_additem(menu, "Pause^n", "2");
	else
		menu_additem(menu, "Play^n", "2");
	//menu_additem(menu, "Kick bot", "3");

	menu_display(id, menu, 0);

	return PLUGIN_HANDLED;
}

public ReplayMenu_Handler(id, menu, item)
{
	if(item == MENU_EXIT)
	{
		return PLUGIN_HANDLED;
	}

	switch(item)
	{
		case 0:
		{
			if(!g_bot_id){
				
				if(IsPaused[g_bot_id] == true){
					ReadBestRunFile();
					g_bot_id = Create_Bot();
					Pause(g_bot_id)
				}
				else{
					ReadBestRunFile();
					g_bot_id = Create_Bot();
				}
			}
			else{
				if(IsPaused[g_bot_id] == true){
					ReadBestRunFile();
					Start_Bot();
					Pause(g_bot_id)
				}
				else{
					ReadBestRunFile();
					Start_Bot();
				}
			}
		}
		case 1:
		{
			if (g_bot_enable == 1)
			{
				Pause(g_bot_id)
				g_bot_enable = 2;
			}
			else
			{
				Pause(g_bot_id)
				g_bot_enable = 1;
			}
		}
		//case 2: Remove_Bot();
	}
	ClCmd_ReplayMenu(id);
	return PLUGIN_HANDLED;
}

stock StringTimer(const Float:flRealTime, szOutPut[], const iSizeOutPut)
{
	static Float:flTime, iMinutes, iSeconds, iMiliSeconds, Float:iMili;
	new string[12]

	flTime = flRealTime;

	if(flTime < 0.0) flTime = 0.0;

	iMinutes = floatround(flTime / 60, floatround_floor);
	iSeconds = floatround(flTime - (iMinutes * 60), floatround_floor);
	iMili = floatfract(flRealTime)
	formatex(string, 11, "%.02f", iMili >= 0 ? iMili + 0.005 : iMili - 0.005);
	iMiliSeconds = floatround(str_to_float(string) * 100, floatround_floor);
	
	if(iMinutes > 1666)
		formatex(szOutPut, iSizeOutPut, "\d Puesto libre");
	else
		formatex(szOutPut, iSizeOutPut, "%02d:%02d.%02d", iMinutes, iSeconds, iMiliSeconds);
}



public bot_overwriting()
{
	ArrayClear(g_DemoPlaybot[0]);
	ReadBestRunFile();

	new txt[64]
	StringTimer(g_ReplayBestRunTime, g_bBestTimer, sizeof(g_bBestTimer) - 1);
	formatex(txt, charsmax(txt), "%s %s", g_ReplayName, g_bBestTimer);
	set_user_info(g_bot_id, "name", txt)
}

Create_Bot()
{
	new txt[64]
	StringTimer(g_ReplayBestRunTime, g_bBestTimer, sizeof(g_bBestTimer) - 1);
	formatex(txt, charsmax(txt), "%s %s", g_ReplayName, g_bBestTimer);
	new id = engfunc(EngFunc_CreateFakeClient, txt);
	
	if(pev_valid(id))
	{
		set_user_info(id, "rate", "25000");
		set_user_info(id, "cl_updaterate", "60");
		set_user_info(id, "cl_cmdrate", "60");
		set_user_info(id, "cl_lw", "1");
		set_user_info(id, "cl_lc", "1");
		set_user_info(id, "cl_dlmax", "128");
		set_user_info(id, "cl_righthand", "1");
		set_user_info(id, "_vgui_menus", "0");
		set_user_info(id, "ah", "1");
		set_user_info(id, "dm", "0");
		set_user_info(id, "tracker", "0");
		set_user_info(id, "friends", "0");
		//set_user_info(id, "*bot", "1");
		
		//set_user_info(id, "fps_max", "60");
		
		set_pev(id, pev_velocity, 250);
		//set_pev(id, pev_flags, pev(id, pev_flags) | FL_FAKECLIENT);
		set_pev(id, pev_colormap, id);
		
		dllfunc(DLLFunc_ClientConnect, id, "BOT DEMO", "127.0.0.1");
		dllfunc(DLLFunc_ClientPutInServer, id);

		cs_set_user_team(id, CS_TEAM_CT);
		cs_set_user_model(id, "VIP");
		
		if(!is_user_alive(id))
			dllfunc(DLLFunc_Spawn, id);

		set_pev(id, pev_takedamage, DAMAGE_NO);
		set_pev(id, pev_solid, SOLID_BSP)
		
		g_bot_enable = 1;
		return id;
	}
	return 0;
}
/*
Remove_Bot()
{
	server_cmd("kick #%d", get_user_userid(g_bot_id))
	//destroy_bot_icon(g_bot_id)
	g_bot_id = 0;
	g_bot_enable = 0;
	g_bot_frame = 0;
	ArrayClear(g_DemoPlaybot[0]);
	
}
*/
Start_Bot()
{
	g_bot_frame = 0;
	start_climb(g_bot_id)
	nFrame = 0;
	strip_user_weapons(g_bot_id)
	set_user_godmode(g_bot_id, 1)
	give_item(g_bot_id,"weapon_usp") 
	
	new botname[6]
	get_user_name(g_bot_id, botname, 5);
	if(contain( botname, "[Nub]" ) != -1)
		set_user_rendering(g_bot_id,kRenderFxGlowShell,0,128,255,kRenderNormal,25)
	else
		set_user_rendering(g_bot_id,kRenderFxGlowShell,255,128,0,kRenderNormal,25)
	
	//give_item(g_bot_id,"weapon_usp") 
	//create_bot_icon(g_bot_id)
}
/*
public create_bot_icon(id)
{
	g_Bot_Icon_ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_sprite"))
	
	set_pev(g_Bot_Icon_ent, pev_solid, SOLID_NOT);
	set_pev(g_Bot_Icon_ent, pev_movetype, MOVETYPE_FLYMISSILE);
	set_pev(g_Bot_Icon_ent, pev_iuser2, id);
	set_pev(g_Bot_Icon_ent, pev_scale, 0.10);

	//engfunc(EngFunc_SetModel, g_Bot_Icon_ent, "sprites/orvnge/orvnge_recbots.spr")
	//engfunc(EngFunc_SetModel, g_Bot_Icon_ent, "sprites/orvnge/kks.spr")
	//engfunc(EngFunc_SetModel, g_Bot_Icon_ent, "sprites/wrbot/ar.spr")
	
}
*/
public destroy_bot_icon(id)
{
	if(g_Bot_Icon_ent)
		engfunc(EngFunc_RemoveEntity, g_Bot_Icon_ent)

	g_Bot_Icon_ent = 0
}
public start_climb(id)
{
	kz_chat(id, "%L", id, "KZ_START_CLIMB")

	if (get_pcvar_num(kz_reload_weapons) == 1)
	{
		strip_user_weapons(id)
		give_item(id,"weapon_knife")
		give_item(id,"weapon_usp") 
	}

	if (ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)
		
	set_pev(id, pev_gravity, 1.0);
	set_pev(id, pev_movetype, MOVETYPE_WALK)
	set_user_godmode(id, 0)
	
	set_user_frags(id, checknumbers[id])
	cs_set_user_deaths(id, gochecknumbers[id])
	if(is_user_bot(id)){
		set_user_frags(id, 1337)
		cs_set_user_deaths(id, 1337)
	}
	cs_set_user_money(id, 1337)
	reset_checkpoints(id) 
	IsPaused[id] = false
	timer_started[id] = true
	savespec[id] = 0;
	timer_time[id] = get_gametime()
	
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	if( contain( szMapName, "slide" ) != -1 || contain( szMapName, "surf" ) != -1)
	{
		set_user_godmode(id, 1)
	}
	
}

public finish_climb(id)
{
	if (!is_user_alive(id) || is_user_bot(id)) return;

	if(IsPaused[id] == true){
		kz_chat(id, "%L", id, "KZ_BUGPAUSE")
		return;
	}
	if ( (get_pcvar_num(kz_top15_authid) > 1) || (get_pcvar_num(kz_top15_authid) < 0) )
	{
		ColorChat(id, GREEN,  "%s^x01 %L.", prefix, id, "KZ_TOP15_DISABLED")
		return;
	}
	
	#if defined USE_SQL
		// OLD CODE SQL TOP REMOVIDO
	#else
	new Float: time, authid[32]
	time = get_gametime() - timer_time[id]
	get_user_authid(id, authid, 31)
	show_finish_message(id, time)
	
	timer_started[id] = false
	
	set_user_frags(id, 0)
	cs_set_user_deaths(id, 0)
	cs_set_user_money(id, 0)
	
	
	if (get_pcvar_num(kz_show_timer) > 0 && ShowTime[id] == 2)
		kz_showtime_roundtime(id, 0)
	
	if (gochecknumbers[id] == 0 &&  !user_has_scout[id] )
		ProTop_update(id, time)
	if (gochecknumbers[id] > 0 || user_has_scout[id] )
		NoobTop_update(id, time, checknumbers[id], gochecknumbers[id])
	#endif
	user_has_scout[id] = false
	
}

public show_finish_message(id, Float:kreedztime)
{
	new name[32]
	new imin,isec,ims, wpn
	if(user_has_scout[id])
		wpn=CSW_SCOUT
	else
		wpn=get_user_weapon( id ) 
	get_user_name(id, name, 31)
	imin = floatround(kreedztime / 60.0, floatround_floor)
	isec = floatround(kreedztime - imin * 60.0,floatround_floor)
	ims = floatround( ( kreedztime - ( imin * 60.0 + isec ) ) * 100.0, floatround_floor )
	
	ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x04 %02i:%02i.%02i ^x03(^x01 CPs: ^x04%d^x03 | ^x01 TPs: ^x04%d^x03 | ^x01 %L: ^x04%s^x03) ^x01 !", prefix, name, LANG_PLAYER, "KZ_FINISH_MSG", imin, isec, ims, checknumbers[id], gochecknumbers[id], LANG_PLAYER, "KZ_WEAPON", g_weaponsnames[wpn])
}

public fw_StartFrame(){
	static id;
	for(id = 1; id <= g_iMaxPlayers; id++)
	{
		new Button = pev(id, pev_button);
			
		if(is_user_alive(id) && !is_user_bot(id))
		{
			if(Button & IN_LEFT || Button & IN_RIGHT){
						
				set_pev(id, pev_flags, pev(id, pev_flags) | FL_FROZEN)
				set_task(0.1, "remove_anti_rows", id)

			}
		}
	}
	
	return FMRES_IGNORED;
}
public remove_anti_rows(id){
	set_pev( id, pev_velocity, Float:{0.0, 0.0, 0.0} );
	set_pev(id, pev_flags, pev(id, pev_flags) & ~FL_FROZEN)
}


//==========================================================
#if defined USE_SQL
	// OLD CODE SQL TOP REMOVIDO
#else
public ProTop_update(id, Float:time)
{
	new authid[32], name[32], thetime[32], Float: slower, Float: faster, Float:protiempo
	get_user_name(id, name, 31);
	get_user_authid(id, authid, 31);
	get_time(" %d/%m/%Y ", thetime, 31);
	new bool:Is_in_pro15
	Is_in_pro15 = false

	for(new i = 0; i < 15; i++)
	{
		if( (equali(Pro_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Pro_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			Is_in_pro15 = true
			slower = time - Pro_Times[i]
			faster = Pro_Times[i] - time
			protiempo = Pro_Times[i]
		}
	}
	
	for (new i = 0; i < 15; i++)
	{	
		if( time < Pro_Times[i])
		{
			new pos = i
			if ( get_pcvar_num(kz_top15_authid) == 0 )
				while( !equal(Pro_Names[pos], name) && pos < 15 )
				{
					pos++;
				}
			else if ( get_pcvar_num(kz_top15_authid) == 1)
				while( !equal(Pro_AuthIDS[pos], authid) && pos < 15 )
				{
					pos++;
				}
			
			for (new j = pos; j > i; j--)
			{
				formatex(Pro_AuthIDS[j], 31, Pro_AuthIDS[j-1]);
				formatex(Pro_Names[j], 31, Pro_Names[j-1]);
				formatex(Pro_Date[j], 31, Pro_Date[j-1])
				Pro_Times[j] = Pro_Times[j-1];
			}
			
			formatex(Pro_AuthIDS[i], 31, authid);
			formatex(Pro_Names[i], 31, name);
			formatex(Pro_Date[i], 31, thetime)
			Pro_Times[i] = time
			
			save_pro15()
			
			if( Is_in_pro15 )
			{

				if( time < protiempo )
				{
					new min, Float:sec;
					min = floatround(faster, floatround_floor)/60;
					sec = faster - (60*min);
					ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_IMPROVE", min, sec < 10 ? "0" : "", sec);
					
					if( (i + 1) == 1)
					{
						ClCmd_UpdateReplay(id, time, 1.0)
						
						client_cmd(0, "spk woop");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
					}
					else
					{
						client_cmd(0, "spk buttons/bell1");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
					}
				}	
			}
			else
			{
				if( (i + 1) == 1)
				{
					ClCmd_UpdateReplay(id, time, 1.0)
					client_cmd(0, "spk woop");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
				}
				else
				{
					client_cmd(0, "spk buttons/bell1");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Pro 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
				}
			}
			
			return;
		}

		if( (equali(Pro_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Pro_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			if( time > protiempo )
			{
				new min, Float:sec;
				min = floatround(slower, floatround_floor)/60;
				sec = slower - (60*min);
				ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_SLOWER", min, sec < 10 ? "0" : "", sec);
				return;
			}
		}
		
	}
}

public save_pro15()
{
	new profile[128]
	formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)
	
	if( file_exists(profile) )
	{
		delete_file(profile)
	}
   
	new Data[256];
	new f = fopen(profile, "at")
	
	for(new i = 0; i < 15; i++)
	{
		formatex(Data, 255, "^"%.2f^"   ^"%s^"   ^"%s^"   ^"%s^"^n", Pro_Times[i], Pro_AuthIDS[i], Pro_Names[i], Pro_Date[i])
		fputs(f, Data)
	}
	fclose(f);
}

public read_pro15()
{
	new profile[128], prodata[256]
	formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)
	
	new f = fopen(profile, "rt" )
	new i = 0
	while( !feof(f) && i < 16)
	{
		fgets(f, prodata, 255)
		new totime[25]
		parse(prodata, totime, 24, Pro_AuthIDS[i], 31, Pro_Names[i], 31, Pro_Date[i], 31)
		Pro_Times[i] = str_to_float(totime)
		i++;
	}
	fclose(f)
}

//==================================================================================================

public NoobTop_update(id, Float:time, checkpoints, gochecks) 
{
	new authid[32], name[32], thetime[32], wpn, Float: slower, Float: faster, Float:noobtiempo
	get_user_name(id, name, 31);
	get_user_authid(id, authid, 31);
	get_time(" %d/%m/%Y ", thetime, 31);
	new bool:Is_in_noob15
	Is_in_noob15 = false
	if(user_has_scout[id])
		wpn=CSW_SCOUT
	else
		wpn=get_user_weapon(id)
	
	for(new i = 0; i < 15; i++)
	{
		if( (equali(Noob_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Noob_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			Is_in_noob15 = true
			slower = time - Noob_Tiempos[i];
			faster = Noob_Tiempos[i] - time;
			noobtiempo = Noob_Tiempos[i]
		}
	}
	
	for (new i = 0; i < 15; i++)
	{
		if( time < Noob_Tiempos[i])
		{
			new pos = i
			
			if ( get_pcvar_num(kz_top15_authid) == 0 )
				while( !equal(Noob_Names[pos], name) && pos < 15 )
				{
					pos++;
				}
			else if ( get_pcvar_num(kz_top15_authid) == 1)
				while( !equal(Noob_AuthIDS[pos], authid) && pos < 15 )
				{
					pos++;
				}
			
			for (new j = pos; j > i; j--)
			{
				formatex(Noob_AuthIDS[j], 31, Noob_AuthIDS[j-1])
				formatex(Noob_Names[j], 31, Noob_Names[j-1])
				formatex(Noob_Date[j], 31, Noob_Date[j-1])
				formatex(Noob_Weapon[j], 31, Noob_Weapon[j-1])
				Noob_Tiempos[j] = Noob_Tiempos[j-1]
				Noob_CheckPoints[j] = Noob_CheckPoints[j-1]
				Noob_GoChecks[j] = Noob_GoChecks[j-1]	
			}
			
			formatex(Noob_AuthIDS[i], 31, authid);
			formatex(Noob_Names[i], 31, name);
			formatex(Noob_Date[i], 31, thetime)
			formatex(Noob_Weapon[i], 31, g_weaponsnames[wpn])
			Noob_Tiempos[i] = time
			Noob_CheckPoints[i] = checkpoints
			Noob_GoChecks[i] = gochecks
			
			save_Noob15()
			
			if( Is_in_noob15 )
			{

				if( time < noobtiempo )
				{
					new min, Float:sec;
					min = floatround(faster, floatround_floor)/60;
					sec = faster - (60*min);
					ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_IMPROVE", min, sec < 10 ? "0" : "", sec);
					
					if( (i + 1) == 1)
					{
						new profile[128]
						formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)
						if(!file_exists(profile) )
						{
							ClCmd_UpdateReplay(id, time, 0.1)
						}
						client_cmd(0, "spk woop");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
					}
					else
					{
						client_cmd(0, "spk buttons/bell1");
						ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
					}
				}	
			}
			else
			{
				if( (i + 1) == 1)
				{
					new profile[128]
					formatex(profile, 127, "%s/pro_%s.cfg", Topdir, MapName)
					if(!file_exists(profile) ) //Si archivo no existe
					{
						ClCmd_UpdateReplay(id, time, 0.1)
					}
					client_cmd(0, "spk woop");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 1^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE");
				}
				else
				{
					client_cmd(0, "spk buttons/bell1");
					ColorChat(0, GREEN,  "%s^x01^x03 %s^x01 %L^x03 %d^x01 in ^x04Noob 15^x01", prefix, name, LANG_PLAYER, "KZ_PLACE", (i+1));
				}
			}
			return;
		}

		if( (equali(Noob_Names[i], name) && (get_pcvar_num(kz_top15_authid) == 0)) || (equali(Noob_AuthIDS[i], authid) && (get_pcvar_num(kz_top15_authid) == 1)) )
		{
			if( time > noobtiempo )
			{
				
				new min, Float:sec;
				min = floatround(slower, floatround_floor)/60;
				sec = slower - (60*min);
				ColorChat(id, GREEN,  "%s^x01 %L ^x03%02d:%s%.2f^x01", prefix, id, "KZ_SLOWER", min, sec < 10 ? "0" : "", sec);
				return;
			}
		}
		
	}
}

public save_Noob15()
{
	new profile[128]
	formatex(profile, 127, "%s/Noob_%s.cfg", Topdir, MapName)
	
	if( file_exists(profile) )
	{
		delete_file(profile)
	}
   
	new Data[256];
	new f = fopen(profile, "at")
	
	for(new i = 0; i < 15; i++)
	{
		formatex(Data, 255, "^"%.2f^"   ^"%s^"   ^"%s^"   ^"%i^"   ^"%i^"   ^"%s^"  ^"%s^" ^n", Noob_Tiempos[i], Noob_AuthIDS[i], Noob_Names[i], Noob_CheckPoints[i], Noob_GoChecks[i],Noob_Date[i],Noob_Weapon[i])
		fputs(f, Data)
	}
	fclose(f);
}

public read_Noob15()
{
	new profile[128], prodata[256]
	formatex(profile, 127, "%s/Noob_%s.cfg", Topdir, MapName)
	
	new f = fopen(profile, "rt" )
	new i = 0
	while( !feof(f) && i < 16)
	{
		fgets(f, prodata, 255)
		new totime[25], checks[5], gochecks[5]
		parse(prodata, totime, 24, Noob_AuthIDS[i], 31, Noob_Names[i], 31,  checks, 4, gochecks, 4, Noob_Date[i], 31, Noob_Weapon[i], 31)
		Noob_Tiempos[i] = str_to_float(totime)
		Noob_CheckPoints[i] = str_to_num(checks)
		Noob_GoChecks[i] = str_to_num(gochecks)
		i++;
	}
	fclose(f)
}

public cantidad_pro()
{
	new count = 0;
	for (new i = 0; i < 15; i++) 
	{
		new check[2]
		formatex(check, charsmax(check), Pro_Names[i]);
		if(equal( check, "" ) ) 
			i = 15;
		else{
			count++;
		}
	}
	return count;
}
public cantidad_nub()
{
	new count = 0;
	for (new i = 0; i < 15; i++) 
	{
		new check[2]
		formatex(check, charsmax(check), Noob_Names[i]);
		if(equal( check, "" ) ) 
			i = 15;
		else{
			count++;
		}
	}
	return count;
}
#if defined TOPS_NEW
public ProTop_show(id)
{	
	if(cantidad_pro() == 0){
		ColorChat(id, RED, "^4%s ^1No hay tops de categoria ^4Pro^1 hechos aun.", prefix)
		return PLUGIN_HANDLED
	}
	new x = map_dif()
	new mapdif[17]
	if(x == 0)	formatex(mapdif, 16, "\d(\wUnknown\d)");else if(x == 1)	formatex(mapdif, 16, "\d(\wEasy\d)");else if(x == 2)	formatex(mapdif, 16, "\d(\yAverage\d)");
	else if(x == 3)	formatex(mapdif, 16, "\d(\rHard\d)");else if(x == 4)	formatex(mapdif, 16, "\d(\rExtreme\d)")
		
	new msg[1024]
	new len;
	len = formatex(msg, charsmax(msg), "\r[TOP] \y%s %s \dProTops:\w %d^n", g_szMapName, mapdif, cantidad_pro());
	
	new nick[16]
	new times[82];
	if(order_list[id] == false){
		for (new i = 0; i < 7; i++) 
		{
			new check[2]
			formatex(check, charsmax(check), Pro_Names[i]);
			if(equal( check, "" ) ) 
				i = 6;
			else{	
				formatex(nick, charsmax(nick), "%s", Pro_Names[i]);
				StringTimer(Pro_Times[i], times, sizeof(times) - 1);
				if((i+1) == 1)
					len += formatex(msg[len], charsmax(msg) - len, "\y#%d \w%s:\r %s \wFecha: \y%s^n", (i+1), nick, times, Pro_Date[i]);
				else if((i+1) == 2)
					len += formatex(msg[len], charsmax(msg) - len, "\r#%d \w%s:\r %s \wFecha: \y%s^n", (i+1), nick, times, Pro_Date[i]);
				else if((i+1) == 3)
					len += formatex(msg[len], charsmax(msg) - len, "\w#%d \w%s:\r %s \wFecha: \y%s^n", (i+1), nick, times, Pro_Date[i]);
				else
				len += formatex(msg[len], charsmax(msg) - len, "\d#%d \w%s:\r %s \wFecha: \y%s^n", (i+1), nick, times, Pro_Date[i]);
			}
		}
	}
	else if(order_list[id] == true){
		for (new i = 7; i < 15; i++) 
		{
			new check[2]
			formatex(check, charsmax(check), Pro_Names[i]);
			if(equal( check, "" ) ) 
				i = 15;
			else{	
				formatex(nick, charsmax(nick), "%s", Pro_Names[i]);
				StringTimer(Pro_Times[i], times, sizeof(times) - 1);
				len += formatex(msg[len], charsmax(msg) - len, "\d#%d \w%s:\r %s \wFecha: \y%s^n", (i+1), nick, times, Pro_Date[i]);
			}
		}
	}
	
	if(cantidad_pro() > 7)
		len += formatex(msg[len], charsmax(msg) - len, "^n\y[9]\r %s", order_list[id] ? "Atras" : "Siguiente" );
	len += formatex(msg[len], charsmax(msg) - len, "^n\y[0]\r Salir");
	show_menu(id, Keystop_pro, msg, -1, "top_pro") // Display menu
	return PLUGIN_HANDLED
}

public Pressedtop_pro(id, key, menu) {
	/* Menu:
	* [TOP] wwa
	*/

	switch (key) {
		case 8: { // 9
			if(cantidad_pro() > 7){
				order_list[id] = !order_list[id]
				ProTop_show(id)
			}
			ProTop_show(id)
		}
		case 9: { // 0
			
		}
	}
}
public NoobTop_show(id)
{	
	if(cantidad_nub() == 0){
		ColorChat(id, RED, "^4%s ^1No hay tops de categoria ^4Nub^1 hechos aun.", prefix)
		return PLUGIN_HANDLED
	}
	new x = map_dif()
	new mapdif[17]
	if(x == 0)	formatex(mapdif, 16, "\d(\wUnknown\d)");else if(x == 1)	formatex(mapdif, 16, "\d(\wEasy\d)");else if(x == 2)	formatex(mapdif, 16, "\d(\yAverage\d)");
	else if(x == 3)	formatex(mapdif, 16, "\d(\rHard\d)");else if(x == 4)	formatex(mapdif, 16, "\d(\rExtreme\d)")
		
	new msg[1024]
	new len;
	len = formatex(msg, charsmax(msg), "\r[TOP] \y%s %s \dNubTops:\w %d^n", g_szMapName, mapdif, cantidad_nub());
	
	new nick[16]
	new times[82];
	if(order_list_nub[id] == false){
		for (new i = 0; i < 7; i++) 
		{
			new check[2]
			formatex(check, charsmax(check), Noob_Names[i]);
			if(equal( check, "" ) ) 
				i = 6;
			else{	
				formatex(nick, charsmax(nick), "%s", Noob_Names[i]);
				StringTimer(Noob_Tiempos[i], times, sizeof(times) - 1);
				if((i+1) == 1)
					len += formatex(msg[len], charsmax(msg) - len, "\y#%d \w%s: \r%s \d[CP%d GC%d] \wFecha\y %s %s^n", (i+1), nick, times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
				else if((i+1) == 2)
					len += formatex(msg[len], charsmax(msg) - len, "\r#%d \w%s: \r%s \d[CP%d GC%d] \wFecha\y %s %s^n", (i+1), nick, times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
				else if((i+1) == 3)
					len += formatex(msg[len], charsmax(msg) - len, "\w#%d \w%s: \r%s \d[CP%d GC%d] \wFecha\y %s %s^n", (i+1), nick, times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
				else
				len += formatex(msg[len], charsmax(msg) - len, "\d#%d \w%s: \r%s \d[CP%d GC%d] \wFecha\y %s %s^n", (i+1), nick, times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
			}
		}
	}
	else if(order_list_nub[id] == true){
		for (new i = 7; i < 15; i++) 
		{
			new check[2]
			formatex(check, charsmax(check), Noob_Names[i]);
			if(equal( check, "" ) ) 
				i = 15;
			else{	
				formatex(nick, charsmax(nick), "%s", Noob_Names[i]);
				StringTimer(Pro_Times[i], times, sizeof(times) - 1);
				len += formatex(msg[len], charsmax(msg) - len, "\d#%d \w%s: \r%s \d[CP%d GC%d] \wFecha\y %s %s^n", (i+1), nick, times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
			}
		}
	}
	
	if(cantidad_nub() > 7)
		len += formatex(msg[len], charsmax(msg) - len, "^n\y[9]\r %s", order_list[id] ? "Atras" : "Siguiente" );
	len += formatex(msg[len], charsmax(msg) - len, "^n\y[0]\r Salir");
	show_menu(id, Keystop_pro, msg, -1, "top_nub") // Display menu
	return PLUGIN_HANDLED
}

public Pressedtop_nub(id, key, menu) {
	/* Menu:
	* [TOP] wwa
	*/

	switch (key) {
		case 8: { // 9
			if(cantidad_nub() > 7){
				order_list_nub[id] = !order_list_nub[id]
				NoobTop_show(id)
			}
			NoobTop_show(id)
		}
		case 9: { // 0
			
		}
	}
}
#else
public ProTop_show(id)
{	
	if(cantidad_pro() == 0){
		ColorChat(id, RED, "^4%s ^1No hay tops de categoria ^4Pro^1 hechos aun.", prefix)
		return PLUGIN_HANDLED
	}
	new x = map_dif()
	
	new mapdif[17]
	if(x == 0)
		formatex(mapdif, 16, "\d(\wUnknown\d)") 
	else if(x == 1)
		formatex(mapdif, 16, "\d(\wEasy\d)")
	else if(x == 2)
		formatex(mapdif, 16, "\d(\yAverage\d)")
	else if(x == 3)
		formatex(mapdif, 16, "\d(\rHard\d)")
	else if(x == 4)
		formatex(mapdif, 16, "\d(\rExtreme\d)")
	
	static menu, sztext[100];
	format(sztext, charsmax(sztext), "\r[TOP] \y%s %s \dProTops:\d %d\d^n\wNombre\d -- \rTiempo\d -- \yFecha\d ", g_szMapName, mapdif, cantidad_pro());
	menu = menu_create(sztext, "handled_showw");
	
	new times[82];
	for (new i = 0; i < 15; i++) 
	{
		new check[2]
		formatex(check, charsmax(check), Pro_Names[i]);
		if(equal( check, "" ) ) 
			i = 15;
		else{	
			new szMenuItems[128];	
			StringTimer(Pro_Times[i], times, sizeof(times) - 1);
			formatex(szMenuItems, charsmax(szMenuItems), "\d#%d \w%s \r%s \y%s", (i+1), Pro_Names[i], times, Pro_Date[i]);
			menu_additem(menu, szMenuItems);
		}
	}
	menu_setprop(menu, MPROP_PERPAGE, 5)
	menu_setprop(menu, MPROP_BACKNAME, "Atras");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	
	menu_display(id, menu);
	return PLUGIN_HANDLED
}
public handled_showw(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	menu_destroy(menu);
}

public NoobTop_show(id)
{	
	if(cantidad_nub() == 0){
		ColorChat(id, RED, "^4%s ^1No hay tops de categoria ^4Nub^1 hechos aun.", prefix)
		return PLUGIN_HANDLED
	}
	new x = map_dif()
	new mapdif[17]
	if(x == 0)	formatex(mapdif, 16, "\d(\wUnknown\d)");else if(x == 1)	formatex(mapdif, 16, "\d(\wEasy\d)");else if(x == 2)	formatex(mapdif, 16, "\d(\yAverage\d)");
	else if(x == 3)	formatex(mapdif, 16, "\d(\rHard\d)");else if(x == 4)	formatex(mapdif, 16, "\d(\rExtreme\d)")
		
	static menu, sztext[100];
	format(sztext, charsmax(sztext), "\r[TOP] \y%s %s \dNubTops: %d\d^n\wNombre\d -- \rTiempo\d -- \yFecha\d ", g_szMapName, mapdif, cantidad_nub());
	menu = menu_create(sztext, "handled_show");
	new times[82];
	for (new i = 0; i < 15; i++) 
	{
		new check[2]
		formatex(check, charsmax(check), Noob_Names[i]);
		if(equal( check, "" ) ) 
			i = 15;
		else{	
			new szMenuItems[128];	
			StringTimer(Noob_Tiempos[i], times, sizeof(times) - 1);
			formatex(szMenuItems, charsmax(szMenuItems), "\d#%d \w%s \r%s \d[CP%d GC%d]\wFecha\y %s %s", (i+1), Noob_Names[i], times, Noob_CheckPoints[i], Noob_GoChecks[i], Noob_Date[i], Noob_Weapon[i]);
			menu_additem(menu, szMenuItems);
		}
	}
	menu_setprop(menu, MPROP_PERPAGE, 5)
	menu_setprop(menu, MPROP_BACKNAME, "Atras");
	menu_setprop(menu, MPROP_NEXTNAME, "Siguiente");
	menu_setprop(menu, MPROP_EXITNAME, "Salir");
	
	menu_display(id, menu);
	
	return PLUGIN_HANDLED
}
public handled_show(id, menu, item)
{
	if (item == MENU_EXIT)
	{
		menu_destroy(menu);
		return;
	}
	
	menu_destroy(menu);
}
#endif
public GameDesc( ) { 
	static gamename[32]; 
	get_pcvar_string( amx_gamename, gamename, 31 ); 
	forward_return( FMV_STRING, gamename ); 
	return FMRES_SUPERCEDE; 
}

Loaddif()
{	
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	new data[16];
	if( fvault_get_data(g_vault_name, szMapName, data, sizeof(data) - 1) )
	{
		g_dif = str_to_num(data);
		
	}
	else
	{
		g_dif = 0;
	}
}
Savedif()
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	new data[16];
	num_to_str(g_dif, data, sizeof(data) - 1);
	fvault_set_data(g_vault_name, szMapName, data);
}

public menu_dif(id)
{	
	new title[64];
	formatex(title, 63, "\r[Orvnge] \ySetear dificultad del mapa.\w.")
	new menu = menu_create(title, "menudif2")  
	
	menu_additem( menu, "Easy", "1" )
	menu_additem( menu, "Average", "2" )
	menu_additem( menu, "Hard", "3" )
	menu_additem( menu, "Extreme^n^n", "4" )
	menu_additem( menu, "Unknown", "5" )
	menu_additem( menu, "Salir", "MENU_EXIT" )
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}

public menudif2(id , menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 

	switch(item) {
		case 0:{
			g_dif = 1
			Savedif()
		}
		case 1:{
			g_dif = 2
			Savedif()
		}
		case 2:{
			g_dif = 3
			Savedif()
		}
		case 3:{
			g_dif = 4
			Savedif()
		}
		case 4:{
			g_dif = 0
			Savedif()
		}
		
	}
	updatelist()
	return PLUGIN_HANDLED
}
public updatelist(){
	Loaddif()
	if(g_dif == 1)
		server_cmd("amx_cvar MAP_VALUE_DIF ^"Easy / AirAcc ( %d )^"", airac)
	else if(g_dif == 2)
		server_cmd("amx_cvar MAP_VALUE_DIF ^"Average / AirAcc ( %d )^"", airac)
	else if(g_dif == 3)
		server_cmd("amx_cvar MAP_VALUE_DIF ^"Hard / AirAcc ( %d )^"", airac)
	else if(g_dif == 4)
		server_cmd("amx_cvar MAP_VALUE_DIF ^"Extreme / AirAcc ( %d )^"", airac)
	else
		server_cmd("amx_cvar MAP_VALUE_DIF ^"Unknown / AirAcc ( %d )^"", airac)
}
public map_dif(){
	return g_dif;
}

public menu_axn(id)
{	
	new title[64];
	formatex(title, 63, "\r[Orvnge] \ySetear mapa como AXN.\w.")
	new menu = menu_create(title, "menuaxn")  
	
	menu_additem( menu, "Setear como AXN", "1" )
	menu_additem( menu, "Salir", "MENU_EXIT" )
	
	menu_setprop(menu, MPROP_PERPAGE, 0)
	menu_display(id, menu, 0)
	return PLUGIN_HANDLED 
}
public menuaxn(id , menu, item)
{
	if( item == MENU_EXIT ) {
		menu_destroy(menu)
		return PLUGIN_HANDLED
	}
 

	switch(item) {
		case 0:{
			ColorChat(id, RED, "^4%s^1 Agregaste este mapa a la lista de AXN maps", prefix)
			Saveaxn()
		}
	}
	return PLUGIN_HANDLED
}
LoadAXNlist()
{	
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	new data[16];
	if( fvault_get_data(g_vault_nameAXN, szMapName, data, sizeof(data) - 1) )
	{
		is_map_axn = true;
		
	}
	else
	{
		is_map_axn = false;
	}
}
Saveaxn()
{
	new szMapName[ 64 ];
	get_mapname( szMapName, 63 );
	new data[16];
	num_to_str(g_dif, data, sizeof(data) - 1);
	fvault_set_data(g_vault_nameAXN, szMapName, data);
}

#endif

public rt_prefix(params)
{
	new prfx[33];
	formatex( prfx, charsmax( prfx ), prefix );
	set_string(2, prfx, get_param(3));
} 


//====================================== LISTA DE MAPAS CON SU DIFIUCLTAS +500 MAPS ================================
/*	
	0 = Unknown	
	1 = Easy	
	2 = Avergae	
	3 = Hard	
	4 = Extreme
*/
/*
"orvnge_bhops" "1" 
"deathrun_4am_hop" "2" 
"deathrun_abstra" "3" 
"deathrun_bom3" "3" 
"Deathrun_griss" "1" 
"deathrun_orange" "3" 
"deathrun_urs_ulala" "2" 
"deathrun_y_underground" "4" 
"abb_bhop_and_260" "2"
"ad_custom" "1"
"ad_luhop_h" "3"
"adi_nastyslide" "1"
"adi_slidebrick" "1"
"agami_bhopper" "1"
"all1_hb_flores" "2"
"aquatic_2015" "1" 
"b2j_streetbh0p" "1" 
"bhop_20sec" "1" 
"bhop_lego" "1" 
"bhop_ytt_nonstop" "1" 
"bkd_antiqbhop" "1" 
"bkz_beachbhop" "1" 
"bkz_bhopaztec" "1" 
"bkz_goldbhop" "2" 
"cd_666" "4" 
"cd_2333" "4"
"cd_bhop" "3"
"KraXXXel_2013" "1"
"Kzcn_tomhop" "2"
"slide_cobkz_boost" "1"
"Steel_whitebhop" "1"
"azl_lcyo" "1"
"b2j_illumination" "1"
"bhop_20sec" "1"
"bhop_aeonflux" "2"
"bhop_allspark" "1"
"bhop_arxdukz" "2"
"bhop_arxdukz_v1" "1"
"bhop_cave2" "1"
"bhop_colorhop" "2"
"bhop_darkstars" "2"
"bhop_fastgood" "3"
"bhop_grblor_v2" "2"
"bhop_green" "1"
"bhop_jumpers" "1"
"bhop_pasable" "3"
"bhop_ray" "3"
"bhop_redstars" "2"
"bhop_reys" "1"
"bhop_seasonbhop" "1"
"bhop_styleer" "3"
"bhop_unithop" "1"
"bhop_walls" "2"
"bhop_ytt_factory" "1"
"bhop_ytt_neon_light" "1"
"bhop_ytt_nonstop" "1"
"bhoprun" "1"
"bkd_antiqbhop" "1"
"bkm_Catac0mbe" "1"
"bkz_aztecbhop" "1"
"bkz_beachbhop" "1"
"bkz_bhopaztec" "1"
"bkz_bhopvalley" "2"
"bkz_dusttemple" "2"
"bkz_factory" "3"
"bkz_goldbhop" "1"
"bkz_goldbhop_h" "3"
"bkz_grassblock" "1"
"bkz_junglebhop" "1"
"bkz_lost" "3"
"bkz_pyramidblock" "2"
"bkz_toonworld" "1"
"bkz_volcanobhop" "2"
"bkz_whatisthis" "1"
"bla_lechuguilla" "3"
"cd_hb_D3sTiny" "4"
"cd_risingsun" "1"
"ce_grassbhop_ez" "1"
"cg_arizonabhop" "2"
"cg_cbblebhop_h" "3"
"cg_coldbhop_v2" "1"
"cg_coldbhop_v2_h" "3"
"cg_d2block_ez" "1"
"cg_gridblock" "2"
"cg_hitnrun" "2"
"cg_islands" "2"
"cg_lighthops" "1"
"cg_oldtexas" "2"
"cg_strafejumpZ" "2"
"cg_wildwesthop" "2"
"chip_bhopnoob" "1"
"clintmo_bhopbarrels" "1"
"clintmo_bhopriver" "1"
"clintmo_bhoptoon" "1"
"cnd_flasherhop" "3"
"cobkz_neon" "2"
"coma_X" "4"
"cosy_cavebhop" "2"
"d2_mario_bhop" "2"
"dark_ages" "1"
"daza_2010" "2"
"daza_dimensionjumper" "1"
"dc_d33pwater" "2"
"deathrun_death" "1"
"deathrun_death_hard" "2"
"deathrun_queen" "1"
"deathrun_wild_h_timer" "2"
"deathrun_wild_timer" "1"
"dg_insane" "2"
"dg_osbhop" "2"
"dsk_antiquebhop" "2"
"dyd_bhop" "4"
"dyd_horizon" "3"
"dyd_paintskill" "1"
"dyd_xmas2022" "2"
"extreme_jumpluminous" "3"
"ez_kz_synergy_x2" "4"
"fof_32" "1"
"fof_chillbhop" "2"
"fof_dale" "1"
"fs_slide_big" "2"
"ftw_deathzone" "4"
"ftw_fastbhop" "2"
"fu_bawhop" "3"
"fu_bhop" "2"
"fu_devhops" "3"
"fu_insane" "4"
"fu_plainhop2" "4"
"fu_replayhop" "3"
"fu_sane" "3"
"gayl0rd_bhop" "2"
"gbc_script_x" "4"
"hama_timberbhop" "2"
"hb_10" "3"
"hb_JKR" "3"
"hb_afu" "3"
"hb_mekko_ez" "2"
"hb_yoshino" "4"
"hb_z0r" "3"
"hit_canyonbhop" "3"
"idw_carnifex" "4"
"imkz_ivory" "4"
"ins_fuji" "2"
"int_lemons" "4"
"ivns_arcadium" "2"
"ivns_orangez_x" "4"
"j2s_4floors" "2"
"j2s_4tunnels" "3"
"jagkz_breezeclimb" "1"
"jagkz_natal" "2"
"kkz_texture" "3"
"klbk_funny_slide" "1"
"kz-endo_bikinihop" "4"
"kz-endo_carrington" "2"
"kz-endo_loko" "3"
"kz-endo_toonbhopz" "3"
"kz-endo_toonvalley" "2"
"kz_6fd_volcano" "1"
"kz_ancientmemories" "3"
"kz_cargo" "1"
"kz_cg_venice" "3"
"kz_cg_wigbl0ck" "2"
"kz_darkness" "2"
"kz_dojo" "2"
"kz_ea_dam" "2"
"kz_ep_gigablock_b01" "1"
"kz_exodus_ez" "2"
"kz_excavation" "2"
"kz_hop" "2"
"kz_hopez" "2"
"kz_hypercube" "3"
"kz_kz-endo_portal" "1"
"kz_kzarg_catacombsbhop" "2"
"kz_kzdk_covebhop" "2"
"kz_kzdk_delianshop" "2"
"kz_kzlt_dementia" "3"
"kz_kzsca_egyptmemories" "2"
"kz_kzsca_sewerbhop" "2"
"kz_kzse_dustbhop" "2"
"kz_kzse_dustbhop_h" "3"
"kz_kzse_marsh" "1"
"kz_lain" "2"
"kz_man_dragon" "1"
"kz_man_redrock" "1"
"kz_megabhop" "1"
"kz_megabhop_hard" "2"
"kz_midnight" "1"
"kz_nobkz_factoryrun" "2"
"kz_nolve" "1"
"kz_piranesi" "1"
"kz_radium" "3"
"kz_space2" "1"
"kz_stonehenge" "1"
"kz_synergy" "2"
"kz_synergy_x" "4"
"kz_toscana" "1"
"kz_unicorn" "2"
"kz_world" "2"
"kz_xj_communitybhop" "2"
"kzarg_bhop_narrow" "2"
"kzarg_bhopcircuit" "2"
"kzarg_lostrome" "2"
"kzarg_stonebhop" "1"
"kzarg_bhoptungs" "1"
"kzarg_cbblespawn" "1"
"kzarg_chaosad_mz" "1"
"kzarg_uncortablepizza" "1"
"kzarg_woodplace" "1"
"kzbg_bhopbarrels" "1"
"kzbr_favela" "1"
"kzbr_mountaintemple" "1"
"kzbr_riva_redhop" "1"
"kzcn_bhop" "3"
"kzcn_cosy_temple" "1"
"kzcn_goldbhop" "2"
"kzcn_hopdown" "2"
"kzcn_momoko" "2"
"kzcn_simen_bunnyhop_v3" "1"
"kzcn_synergy_h" "4"
"kzhard_catacombs" "1"
"kzhend_go_anselmo" "1"
"kzla_indoorbhop" "1"
"kzls_bhop_china" "2"
"kzls_bhop_temple" "1"
"kzlv_duckbhop" "1"
"kzm_bhopdown" "1"
"kzm_cityhops" "2"
"kzmn_ministairs" "1"
"kzpf_ancientegypt" "3"
"kzpf_bhop" "3"
"kzpf_deathless_x" "4"
"kzr_ezbhop" "1"
"kzra_aim_ak_colt" "2"
"kzra_bhopmemories" "2"
"kzra_pipehouse" "1"
"kzro_astro" "2"
"kzro_darkfury" "2"
"kzro_darkhole" "2"
"kzro_jaashsbhop" "3"
"kzru_pharaonrun" "3"
"kzru_technology_x" "4"
"kzsca_heaven" "1"
"kzsca_snakebhop" "2"
"kzse_bhopblock" "2"
"kzsk_cubeblock" "2"
"kztw_toonbhop_h" "1"
"kzua_mk_ashes_h" "4"
"kzua_mk_illumina" "3"
"kzua_pliqbhop" "3"
"kzua_zp_godroom_h" "4"
"kzuz_duckbhop_t" "1"
"kzy_drophop" "1"
"kzy_juhxbhop" "1"
"kzy_neonhop" "2"
"kzy_slide_bricks" "1"
"kzzNk_slidemush" "3"
"kzz_bhop_e" "2"
"kzz_bhop_h" "4"
"mad_bhopit" "2"
"mad_goldbhop_h" "3"
"md_250" "1"
"mh_winterhops" "1"
"mini_dark_ez" "1"
"mkz_stairs" "1"
"mlg_dustbhop" "1"
"mlg_tleebhop" "1"
"mls_cave_ez" "2"
"mls_fastbhop_fix" "1"
"mls_hb_Alliance" "2"
"mls_hellstairs" "1"
"mls_ljrace" "3"
"mls_minecraft" "2"
"mls_pal_bhops_h" "4"
"mls_sandbhop" "2"
"mls_units" "1"
"mrcn_fallbhop" "1"
"mtz_outdoor" "1"
"ncp_fastrockbhop" "1"
"ncp_snowlj" "2"
"nfs_monsterbhop" "1"
"notkz_J1" "1"
"notkz_amazing" "2"
"notkz_bhopcolour" "2"
"notkz_namek" "4"
"nz_leetbhop" "3"
"nz_playstation" "3"
"nz_playstation2" "3"
"nz_stonetown" "2"
"ph_tuscanhop" "1"
"pixelhop" "2"
"pprn_smallwarehouse" "1"
"pprn_sunkenbhop_e" "1"
"prochallenge2_longjump" "3"
"ptz_industrial" "1"
"qsk_qube" "3"
"r1_jumpbug" "3"
"ra_5_sec" "1"
"raver_countrun" "3"
"raver_omg0_crazystair" "1"
"rch_4fix" "1"
"risk_bhop_bunny" "2"
"risk_simpsons" "1"
"risk_standard" "2"
"risk_xtrm_weaponsfactory" "2"
"roboticbhop" "1"
"rpz_duck" "1"
"rush_boredom" "2"
"rush_stones" "2"
"sgs_rapingyou" "1"
"sharks_sox" "1"
"shtkz_bhop_shy" "1"
"siren_dustbhop_ez" "1"
"slide_brickst0ne_ez" "1"
"slide_cobkz_boost" "1"
"slide_cobkz_brick" "1"
"slide_cobkz_night" "1"
"slide_cobkz_town" "1"
"slide_colors" "1"
"slide_dyd_box" "1"
"slide_dyd_box2" "1"
"slide_dyd_green" "1"
"slide_dyd_object" "1"
"slide_dyd_refuge" "1"
"slide_fufu_reef" "1"
"slide_gs_tetris" "1"
"slide_kissxsis" "1"
"slide_kzfr_base" "1"
"slide_kzfr_desert" "1"
"slide_kzfr_glass" "1"
"slide_kzfr_grasslide" "1"
"slide_kzfr_lava" "1"
"slide_kzfr_legend" "1"
"slide_kzfr_river" "1"
"slide_kzfr_woodslide" "1"
"slide_pers_brick" "1"
"slide_svn_brick_hard" "1"
"slide_svn_giantramp_ez" "1"
"slide_svn_powerslide" "1"
"slide_svn_steepslides" "1"
"slide_tee_vertical" "1"
"slide_tirion" "1"
"slide_vt_fastbest" "1"
"slide_ybsqlugblfjasfhkee" "2"
"sm_ea_ylightsbhop" "2"
"smk_bhop_stoneblocks" "1"
"smk_bhop_stonetemple" "1"
"smk_falldown" "1"
"smk_hnseu_airstrafes" "1"
"smk_hnseu_bridge2_h" "3"
"sn_kza_lighthouse" "1"
"sn_minivolcano" "1"
"srg_duckbhoph" "1"
"stf_creepytemple" "2"
"strg_neonbhop_hard" "3"
"svn_cosy_cupslide" "1"
"svn_powerbhop" "1"
"terror_stairs" "1"
"tght_minibhop" "1"
"tja_bhoprun" "1"
"toonbug_h" "1"
"ul_spring" "3"
"underground_clantest" "3"
"unkm_bhop_medium" "2"
"uq_miniblock_ez" "1"
"uq_hardblock" "2"
"vcn_mc_bhop_h" "3"
"viva_peron" "2"
"zink_creteblock" "2"
"zink_ishouldmakelongermaps" "1"
"zr_minimountain" "1"
"hb_adantoud" "1"
"hb_adantoud2" "2"
"cyx_iceworld" "1"
"4k_first" "1"
"4u_bhopsheisse" "1" 
"5oXen_hb_L377_ez" "2" 
"b2j_underground" "2" 
"b2j_bhopward" "2" 
"bhop_Anning3" "2" 
"bhop_aztec" "1" 
"b2j_summerday" "1" 
"bhop_beach" "1" 
"bhop_blocks" "1" 
"bhop_bruderkz_ny" "2" 
"bhop_green_sector" "1" 
"bhop_lyy_force" "2" 
"bhop_movementkrueppel" "1" 
"bhop_run_1" "1" 
"bhop_runners" "1" 
"bhop_njhop" "1" 
"bhop_cave" "1" 
"bhop_hadulz" "1"
"bkz_noob" "1"
"bhop_squareblock" "1"
"cnd_brickgrass" "1"
"bhop_squareblock2" "1"
"bhop_rabiga" "1"
"bhop_celsbrick" "2"
"bhop_jbg_grass" "1"
"bhop_pool_day" "2"
"bhop_ligtuds" "1"
"bhop_shiny" "1"
"bhop_short" "1"
"bkm_orange" "3"
"bhop_xuedi" "1"
"bhop_terrainhop" "1" 
"bkz_microgoldbhop" "1" 
"kzex_stepblock_h" "3" 
"bhop_kaninpuff" "1" 
"deathrun_griss" "1" 
"deathrun_dojo_course_b1" "2" 
"deathrun_neten" "3" 
*/







