#if defined _deagle_included
 #endinput
#endif
#define _deagle_included

#include <sdkhooks>
#include <sdktools>
#include <cstrike>

#define PREFIX " \x0C➤➤➤\x0B"

enum roundType {
	ROUNDTYPE_NONE = 0,		/* No Round Type active */
	ROUNDTYPE_HIGHFOV, 		/* HIGH FOV Round Type active */
	ROUNDTYPE_LOWFOV,		/* LOW FOV Round Type active */
	ROUNDTYPE_ZEUS,			/* Zeus Round Type active */
	ROUNDTYPE_REVOLVER		/* Revolver Round Type active */
}

/*
* Checks what type of round it is currently
*
* @return	roundType (View roundType enum)
*/
native roundType DG_GetRoundType()

/*
* Called once vote has ended
*
*/
forward void DG_OnRoundVotePre()

/*
* Called once a round vote starts at the beggining of a round
*
* @param Round	Current round
*
*/
forward void DG_OnRoundVote(roundType Round)

/*
* Called on round start
*
*/
forward void DG_OnRoundStart()

/*
* Called on round end
*
*/
forward void DG_OnRoundEnd()

/*
* Called on player death
*
* @param client		dead player
* @param attacker	killer
*
*/
forward void DG_OnPlayerDeath(int client, int attacker)

/*
* Called on player spawn
*
* @param client		client spawned in
*/
forward void DG_OnPlayerSpawn(int client)


/*
* Checks if client index is valid
*
* @param 	client index
*
* @return	true if valid, false otherwise
*/
stock bool IsClientValid(int client) {
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || !IsClientConnected(client) || IsFakeClient(client))
		return false;
       
	return true;
}

/*
* Strips client weapons and gives them deagle + knife
*
* @param 	client index
*
* @noreturn
*/
stock void GiveDeagle(int client) {
	for(int i; i < GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons"); i++) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(IsValidEntity(weapon)) {
            AcceptEntityInput(weapon, "Kill");
		}
	}
	GivePlayerItem(client, "weapon_knife");
	GivePlayerItem(client, "weapon_deagle");
}

/*
* Strips client weapons and gives them knife
*
* @param 	client index
*
* @noreturn
*/
stock void StripWeapons(int client) {
	for(int i; i < GetEntPropArraySize(client, Prop_Send, "m_hMyWeapons"); i++) {
		int weapon = GetEntPropEnt(client, Prop_Send, "m_hMyWeapons", i);
		
		if(IsValidEntity(weapon)) {
            AcceptEntityInput(weapon, "Kill");
		}
	}
	GivePlayerItem(client, "weapon_knife");
}

/*
* Iterates through entities and kills bomb site entity
*
* @noreturn
*/
stock void RemoveBombsites() {
	int entity = -1;
	while((entity = FindEntityByClassname(entity, "func_bomb_target")) != -1)
		AcceptEntityInput(entity, "kill");    //Destroy the entity
}

/*
* Iterates through entities and kills hostage entity
*
* @noreturn
*/
stock void RemoveHostages() {
    int entity = -1;
    while((entity = FindEntityByClassname(entity, "hostage_entity")) != -1)
        AcceptEntityInput(entity, "kill");
}


public __pl_INTERFACE_SetNTVOptional()
{
	MarkNativeAsOptional("DG_GetRoundType");
}


public SharedPlugin __pl_INTERFACE =
{
	name = "Deagle-Core",
	file = ".smx",
	#if defined REQUIRE_PLUGIN
	required = 1,
	#else
	required = 0,
	#endif
};
