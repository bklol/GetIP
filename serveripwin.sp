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
	
	Address pMemAlloc = hGameConf.GetAddress("g_pMemAlloc");
	if(pMemAlloc == Address_Null)
		SetFailState("Couldn't get g_pMemAlloc address!");

	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(hGameConf.GetOffset("Malloc"));
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hMalloc = EndPrepSDKCall();	
	
	int pszIP = SDKCall(hMalloc, pMemAlloc, 0x60);	
	PrintToServer("pszIP is %x", view_as<Address>(pszIP));
	
	Address SteamGameServer = Dereference(GameConfGetAddress(hGameConf, "SteamGameServer"));
	PrintToServer("SteamGameServer is %x", SteamGameServer);	

	Address EAX = Dereference(SteamGameServer);//MOV        EAX,dword ptr [ECX]
	PrintToServer("EAX is %x", EAX);
	
	Address GetPublicIP = Dereference(EAX, 0x84);//CALL       dword ptr [EAX + 0x84]
	PrintToServer("GetPublicIP is %x", GetPublicIP);
	
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetAddress(GetPublicIP);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	Handle hGetPublicIP = EndPrepSDKCall();

	if(!hGetPublicIP) 
		SetFailState("Could not initialize call to hGetPublicIP");
		
	SDKCall(hGetPublicIP, pszIP, SteamGameServer);
	int ip = LoadFromAddress(view_as<Address>(pszIP), NumberType_Int32);
	PrintToServer("Public IP is %d.%d.%d.%d\n", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF );
}

stock any Dereference( Address ptr, int offset = 0, NumberType type = NumberType_Int32 )
{
	return view_as<Address>(LoadFromAddress(ptr + view_as<Address>(offset), type));
}