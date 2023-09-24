#include <sourcemod>
#include <sdktools>

char PublicIP[64];

public Plugin myinfo =
{
	name = "Get ip from ISteamGameServer::GetPublicIP",
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
	char szBuf[14];
	int ip;
	GetCommandLine(szBuf, sizeof szBuf);
	bool g_bWindows = strcmp(szBuf, "./srcds_linux") != 0;
	if(!g_bWindows)
	{
		Address pMemAlloc = hGameConf.GetAddress("g_pMemAlloc");
		if(pMemAlloc == Address_Null)
			SetFailState("Couldn't get g_pMemAlloc address!");
			
		Address Steam3Server = GameConfGetAddress(hGameConf, "Steam3Server");
		if (Steam3Server == Address_Null) 
			SetFailState("Failed to get address: Steam3Server");
			
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetVirtual(hGameConf.GetOffset("Malloc"));
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		Handle hMalloc = EndPrepSDKCall();	
		
		int pszIP = SDKCall(hMalloc, pMemAlloc, 0x60);
		Address GetPublicIP = Dereference(Dereference(Dereference(Steam3Server, 0x4)), 0x84);
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(GetPublicIP);
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);	
		Handle hGetPublicIP = EndPrepSDKCall();	
		SDKCall(hGetPublicIP, pszIP, Dereference(Steam3Server, 0x4));
		
		ip = LoadFromAddress(view_as<Address>(pszIP), NumberType_Int32);
	}
	else
	{
		Address SteamGameServer = Dereference(GameConfGetAddress(hGameConf, "SteamGameServer"));
		Address GetPublicIP = Dereference(Dereference(SteamGameServer), 0x84);
		
		StartPrepSDKCall(SDKCall_Raw);
		PrepSDKCall_SetAddress(GetPublicIP);
		PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
		Handle hGetPublicIP = EndPrepSDKCall();
		
		ip = LoadFromAddress(SDKCall(hGetPublicIP, SteamGameServer), NumberType_Int32);
	}

	Format(PublicIP, sizeof(PublicIP), "%d.%d.%d.%d", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF )
	PrintToServer("Public IP is %s\n", PublicIP);
}

stock any Dereference( Address ptr, int offset = 0, NumberType type = NumberType_Int32 )
{
	return view_as<Address>(LoadFromAddress(ptr + view_as<Address>(offset), type));
}