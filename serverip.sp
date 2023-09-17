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
		

	Address Steam3Server = GameConfGetAddress(hGameConf, "Steam3Server");
	if (Steam3Server == Address_Null) 
		SetFailState("Failed to get address: Steam3Server");
		
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetVirtual(hGameConf.GetOffset("Malloc"));
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	Handle hMalloc = EndPrepSDKCall();	
	
	int pszIP = SDKCall(hMalloc, pMemAlloc, 0x60);	
	
	/*
	101be38a 8b 4e 04        MOV        ECX,dword ptr [ESI + 0x4]
	101be38d 8d 54 24 34     LEA        EDX,[ESP + 0x34]
	101be392 8b 01           MOV        EAX,dword ptr [ECX]
	101be394 ff 90 84        CALL       dword ptr [EAX + 0x84]
			 00 00 00
	*/	
	
	Address GetPublicIP = Dereference(Dereference(Dereference(Steam3Server, 0x4)), 0x84);
	StartPrepSDKCall(SDKCall_Raw);
	PrepSDKCall_SetAddress(GetPublicIP);
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	Handle hGetPublicIP = EndPrepSDKCall();

	if(!hGetPublicIP) 
		SetFailState("Could not initialize call to hGetPublicIP");
		
	SDKCall(hGetPublicIP, pszIP, Dereference(Steam3Server, 0x4));
	int ip = LoadFromAddress(view_as<Address>(pszIP), NumberType_Int32);
	PrintToServer("Public IP is %d.%d.%d.%d\n", (ip >> 24) & 0x000000FF, (ip >> 16) & 0x000000FF, (ip >> 8) & 0x000000FF, ip & 0x000000FF );
}

stock any Dereference( Address ptr, int offset = 0, NumberType type = NumberType_Int32 )
{
	return view_as<Address>(LoadFromAddress(ptr + view_as<Address>(offset), type));
}