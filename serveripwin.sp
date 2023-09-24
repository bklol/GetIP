#include <sourcemod>
#include <sdktools>

public Plugin myinfo =
{
	name = "get ip from ISteamGameServer::GetPublicIP",
	author = "neko AKA bklol"
}

public void OnPluginStart()
{
	GameData hGameConf = LoadGameConfigFile("steamserver.games");
	if (!hGameConf)
	{
		SetFailState("where is steamserver.games ?");
		return;
	}

	Address SteamGameServer = Dereference(GameConfGetAddress(hGameConf, "SteamGameServer"));
	Address GetPublicIP = Dereference(Dereference(SteamGameServer), 0x84);
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetAddress(GetPublicIP);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hGetPublicIP = EndPrepSDKCall();

	if(!hGetPublicIP) 
		SetFailState("Could not initialize call to hGetPublicIP");
	int ip = LoadFromAddress(SDKCall(hGetPublicIP, SteamGameServer), NumberType_Int32);
	PrintToServer("Public IP is %d.%d.%d.%d\n", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF );
}

stock any Dereference( Address ptr, int offset = 0, NumberType type = NumberType_Int32 )
{
	return view_as<Address>(LoadFromAddress(ptr + view_as<Address>(offset), type));
}