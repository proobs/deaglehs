#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <deagle>


#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Deagle HS",
	author = "proobs",
	description = "",
	version = "2.0",
	url = "https://github.com/proobs"
};

/* Main Cvars */ 
ConVar g_cvEnable = null;
ConVar g_cvGrenadeDamage = null;
ConVar g_cvKnife = null;
ConVar g_cvWorldDamage = null;
ConVar g_cvEnforceConVars = null;

/* Round Vote Cvars */
ConVar g_cvRoundVoteEnable = null; 
ConVar g_cvRoundVoteCoolDown = null;
ConVar g_cvVotePercentage = null; 
ConVar g_cvHighFovRound = null; 
ConVar g_cvLowFovRound = null; 
ConVar g_cvZeusRound = null; 
ConVar g_cvRevolverRound = null;
ConVar g_cvHighFovValue = null;
ConVar g_cvLowFovValue = null;

/* forwards */ 
Handle g_hOnRoundVotePre;
Handle g_hOnRoundVote;
Handle g_hOnRoundStart;
Handle g_hOnRoundEnd;
Handle g_hOnPlayerDeath;
Handle g_hOnPlayerSpawn;

/* variables */
roundType g_iRoundType = ROUNDTYPE_NONE;

int g_iCoolDown = 0;

/* Deagle Includes */
#include "deagle/dg_roundvotes.sp"

public void OnPluginStart() {
	g_cvEnable = CreateConVar("dg_plugin_enable", "1", "Enables or disables headshot only");
	g_cvGrenadeDamage = CreateConVar("dg_grenades", "0", "Enable or disable grenade damage");
	g_cvKnife = CreateConVar("dg_knife_damage", "0", "Enables or disables knife damage");
	g_cvWorldDamage = CreateConVar("dg_world_damage", "0", "Enables or disables world damage");
	g_cvEnforceConVars = CreateConVar("dg_enforce_cvars", "1", "enforce cvars necessary");
	
	
	g_cvRoundVoteEnable = CreateConVar("dg_roundvotes_enable", "1", "Enable or disable deagle round votes");
	g_cvRoundVoteCoolDown = CreateConVar("dg_roundvote_cooldown", "3", "how many rounds it'd tale in order to call another round vote once it gets called");
	g_cvVotePercentage = CreateConVar("dg_roundvote_percentage", ".60", "Minimum threshold percentage to actually accept a round vote");
	g_cvHighFovRound = CreateConVar("dg_high_fov_round_enable", "1", "Enable or disable high fov rounds");
	g_cvLowFovRound = CreateConVar("dg_low_fov_round_enable", "1", "enable or disable low fov rounds");
	g_cvZeusRound = CreateConVar("dg_zeus_round_enable", "1", "enable or disable zeus rounds");
	g_cvRevolverRound = CreateConVar("dg_revolver_round_enable", "1", "enable or disable revolver round");
	g_cvHighFovValue = CreateConVar("dg_high_fov_value", "110", "Value of high fov round when enabled");
	g_cvLowFovValue = CreateConVar("dg_low_fov_value", "70", "Value of low fov round");
	
	AutoExecConfig(true, "deagle");
	
	RegAdminCmd("sm_dgadmin", CMD_Admin, ADMFLAG_CUSTOM5);
	RegAdminCmd("sm_roundvote", CMD_RoundVote, ADMFLAG_RESERVATION, "Opens a menu to VIP+ on SNG, Allows them to call a round vote, if it can be called");
	
	for(int i = 1; i <= MaxClients; i++) {
		if(IsClientValid(i)) {
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
	
	HookEventEx("round_start", OnRoundStart);
	HookEventEx("round_end", OnRoundEnd);
	HookEventEx("player_spawn", OnPlayerSpawn);
	HookEventEx("player_death", OnPlayerDeath);
}

// Natives & Forwards

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	CreateNative("DG_GetRoundType", Native_GetRoundType);
	
	g_hOnRoundVotePre = CreateGlobalForward("DG_OnRoundVotePre", ET_Ignore);
	g_hOnRoundVote = CreateGlobalForward("DG_OnRoundVote", ET_Ignore, Param_Cell);
	g_hOnRoundStart = CreateGlobalForward("DG_OnRoundStart", ET_Ignore); 
	g_hOnRoundEnd = CreateGlobalForward("DG_OnRoundEnd", ET_Ignore);
	g_hOnPlayerDeath = CreateGlobalForward("DG_OnPlayerDeath", ET_Ignore, Param_Cell, Param_Cell);
	g_hOnPlayerSpawn = CreateGlobalForward("DG_OnPlayerSpawn", ET_Ignore, Param_Cell); 
	
	RegPluginLibrary("deagle");
	return APLRes_Success;
}

// Main

public void OnMapStart() { 
	EnforceConVars();
}

public void OnClientPutInServer(int client) {
	if(IsClientValid(client)) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientDisconnect(int client) {
	if(IsClientValid(client)) {
		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if(g_cvEnable.BoolValue) {
		if(IsClientValid(victim)) {
			if(damagetype == DMG_FALL|| damagetype == DMG_GENERIC || attacker == 0)
				if(!g_cvWorldDamage.BoolValue)
					return Plugin_Handled; /*Negates fall damage and other world damage*/	
		}
		
		if(IsClientValid(attacker)) { 
			char cWeapon[32];
			char cGrenade[32];
			
			GetClientWeapon(attacker, cWeapon, sizeof(cWeapon));
			if((StrContains(cWeapon, "knife", false) != -1) || (StrContains(cWeapon, "bayonet", false) != -1))
				if(!g_cvKnife.BoolValue)
					return Plugin_Handled;  /* Negates knife damage */
			
			GetEdictClassname(inflictor, cGrenade, sizeof(cGrenade));
			if(StrContains(cGrenade, "_projectile", false) != -1) 
				if(!g_cvGrenadeDamage.BoolValue)
					return Plugin_Handled; /* Negates grenade damage */
				
			if(damagetype & CS_DMG_HEADSHOT)
				return Plugin_Continue; /*allow for headshot dmg*/
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

// Commands

public Action CMD_Admin(int client, int args) {
	if(!IsClientValid) {
		PrintToChat(client, "%s Cannot preform action currently.", PREFIX);
		return Plugin_Handled;
	}
	
	OpenAdminMenu(client);
	return Plugin_Handled;
}

public Action CMD_RoundVote(int client, int args) {
	if(!g_cvRoundVoteEnable) {
		ReplyToCommand(client, "%s Command has been disabled by the server operator", PREFIX);
		return Plugin_Handled; 
	}
	
	if(!IsClientValid(client)) {
		ReplyToCommand(client, "%s You cannot use this command right now..", PREFIX);
		return Plugin_Handled; 
	}
	
	if(IsVoteInProgress()) {
		ReplyToCommand(client, "%s Vote is currently in process...", PREFIX);
		return Plugin_Handled;
	}
	
	if(g_iCoolDown != 0) {
		ReplyToCommand(client, "%s Cannot currently call roundvote. Try again in %d rounds.", PREFIX, g_iCoolDown);
		return Plugin_Handled;
	}
	
	OpenRoundVoteMenu(client);
	return Plugin_Handled;
}

public void OpenAdminMenu(int client) {
	Menu menu = new Menu(admin_handler);
	menu.SetTitle("Deagle Settings");
	menu.AddItem("", "Use this menu to enable or disable some aspects of the plugin", ITEMDRAW_DISABLED);
	menu.AddItem("", "These changes will only last for a map.", ITEMDRAW_DISABLED);
	menu.AddItem("", "", ITEMDRAW_SPACER);
	
	char buf[5][32]; /* TODO: Find a way to make this more effecient */
	
	Format(buf[0], sizeof(buf), "%s Deagle plugin", (g_cvEnable.BoolValue) ? "Enable" : "Disable");
	Format(buf[1], sizeof(buf), "%s Grenade Damage", (g_cvGrenadeDamage.BoolValue) ? "Enable" : "Disable");
	Format(buf[2], sizeof(buf), "%s Knife Damage", (g_cvKnife.BoolValue) ? "Enable" : "Disable");
	Format(buf[3], sizeof(buf), "%s World Damage", (g_cvWorldDamage.BoolValue) ? "Enable" : "Disable");
	Format(buf[4], sizeof(buf), "%s Round Votes", (g_cvRoundVoteEnable) ? "Enable" : "Disable");
	
	
	char buffer[32];
	for (int i = 0; i < sizeof(buf[]); i++) {
		IntToString(i, buffer, sizeof(buffer));
		menu.AddItem(buffer, buf[i]); 
	}
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public int admin_handler(Menu menu, MenuAction action, int param1, int param2) {
	switch(action) {
		case MenuAction_Select: {
			OpenAdminMenu(param1);
			
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			int item = StringToInt(info);
		
			if(item == -1) 
				return;
			
			/* I promise to make this less aids... Sometime... */ 
			switch(item) {
				case 0: {
					if(g_cvEnable.BoolValue) {
						g_cvEnable.SetBool(false);
					} else {
						
						g_cvEnable.SetBool(true);
					}
				} case 1: {
					if(g_cvGrenadeDamage.BoolValue) {
						g_cvGrenadeDamage.SetBool(false);
					} else {
						g_cvGrenadeDamage.SetBool(true);
					}
				} case 2: {
					if(g_cvKnife.BoolValue) {
						g_cvKnife.SetBool(false);
					} else {
						g_cvKnife.SetBool(true);
					}
				} case 3: {
					if(g_cvWorldDamage.BoolValue) {
						g_cvWorldDamage.SetBool(false);
					} else {
						g_cvWorldDamage.SetBool(true);
					}
				} case 4: {
					if(g_cvRoundVoteEnable.BoolValue) {
						g_cvRoundVoteEnable.SetBool(false);
					} else {
						g_cvRoundVoteEnable.SetBool(true);
					}
				} 
			}
			
		} case MenuAction_End: {
			delete menu;
		}
	}
}

// Events

public void OnRoundStart(Event event, const char[] name, bool broadCast) {
	RoundStart();
	
	if(g_iRoundType == ROUNDTYPE_NONE) {
		for (int i = 1; i <= MaxClients; i++) {
			GiveDeagle(i);
		}
		return;
	}
	
	switch(g_iRoundType) {
		case ROUNDTYPE_HIGHFOV: {
			HighFovRound();
		} case ROUNDTYPE_LOWFOV: {
			LowFovRound();
		} case ROUNDTYPE_ZEUS: {
			ZeusRound();
		} case ROUNDTYPE_REVOLVER: {
			RevolverRound();
		}
	}
	
	RoundVoteType();
}

public void OnRoundEnd(Event event, const char[] name, bool broadCast) {
	if(g_iRoundType != ROUNDTYPE_NONE) {
		
		if(g_iRoundType == ROUNDTYPE_HIGHFOV || g_iRoundType == ROUNDTYPE_LOWFOV)
			ResetFov();
		
		g_iRoundType = ROUNDTYPE_NONE;
	}
	
	Call_StartForward(g_hOnRoundEnd);
	

}

public void OnPlayerSpawn(Event event, const char[] name, bool broadCast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Call_StartForward(g_hOnPlayerSpawn);
	Call_PushCell(client);
}

public void OnPlayerDeath(Event event, const char[] name, bool broadCast) {
	int attacker = GetClientOfUserId(event.GetInt("attacker"));
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	Call_StartForward(g_hOnPlayerDeath);
	Call_PushCell(client);
	Call_PushCell(attacker);
}

// Enforce cvars

void EnforceConVars() {
	if(g_cvEnforceConVars.BoolValue) {
		ConVar cvFreezeTime = FindConVar("mp_freezetime");
		cvFreezeTime.IntValue = 0;
		ConVar cvWarmupTime = FindConVar("mp_warmuptime");
		cvWarmupTime.IntValue = 0;
		ConVar cvMapWeapons = FindConVar("mp_weapons_allow_map_placed");
		cvMapWeapons.IntValue = 0;
		ConVar cvBuy = FindConVar("mp_buytime");
		cvBuy.IntValue = 0;
		ConVar cvSetDeaglesT = FindConVar("mp_ct_default_secondary");
		cvSetDeaglesT.SetString("weapon_deagle");
		ConVar cvSetDeaglesCT = FindConVar("mp_t_default_secondary");
		cvSetDeaglesCT.SetString("weapon_deagle");
	}
	
	g_iCoolDown = g_cvRoundVoteCoolDown.IntValue;
	
	RemoveBombsites();
}

// Natives & Forwards

public int Native_GetRoundType(Handle hPlugin, int numParams) {
	return g_iRoundType;
}

public void RoundStart() {
	Call_StartForward(g_hOnRoundStart);
}

public void RoundVoteType() {
	Call_StartForward(g_hOnRoundVote);
	Call_PushCell(g_iRoundType);
}