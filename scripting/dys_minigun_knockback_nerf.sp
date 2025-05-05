#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define NERF_INTERVAL 4

static bool _late_load;

int g_wepShots[2048];

public Plugin myinfo = {
	name = "Dys Minigun Knockback Nerf",
	description = "Nerfs knockback on Minigun",
	author = "bauxite",
	version = "0.1.0",
	url = "",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	_late_load = late;
	return APLRes_Success;
}

public void OnPluginStart()
{
	if (_late_load)
	{
		for (int client = 1; client <= MaxClients; ++client)
		{
			if (!IsClientInGame(client))
			{
				continue;
			}
			if (!SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage))
			{
				ThrowError("Failed to SDKHook");
			}
			else
			{
				PrintToServer("Hook ok!");
			}
		}
	}
}

public void OnClientPutInServer(int client)
{
	if (!SDKHookEx(client, SDKHook_OnTakeDamage, OnTakeDamage))
	{
		ThrowError("Failed to SDKHook");
	}
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{	
	if (!IsValidEntity(inflictor))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[14 + 1];

	if (!GetEntityClassname(inflictor, sWeapon, sizeof(sWeapon)))
	{
		return Plugin_Continue;
	}
	
	if (!StrEqual(sWeapon,"weapon_minigun"))
	{
		return Plugin_Continue;
	}
	
	++g_wepShots[inflictor];
	RequestFrame(ResetShots, inflictor);
	
	if(ShouldReduce(inflictor))
	{
		damagetype = DMG_PREVENT_PHYSICS_FORCE;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void ResetShots(int weapon)
{
	g_wepShots[weapon] = 0;
}

bool ShouldReduce(int weapon)
{
	if(g_wepShots[weapon] <= 1)
	{
		// never reduce knockback on first or only hit
		return false;
	}
	
	if(g_wepShots[weapon] == NERF_INTERVAL)
	{
		//g_wepShots[weapon] = 0; resets on next frame
		return false;
	}
	else
	{
		return true;
	}
}
