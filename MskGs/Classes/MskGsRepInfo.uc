class MskGsRepInfo extends ReplicationInfo;

// Server vars
var public MskGsMut Mut;
var public Controller C;

// Client vars
var private OnlineSubsystemSteamworks SW;

simulated event PostBeginPlay()
{
	`log("[MSK-GS] DBG: PostBeginPlay()");
	
    super.PostBeginPlay();

    if (bDeleteMe) return;
	
	if (Role < ROLE_Authority || WorldInfo.NetMode == NM_StandAlone)
	{
		`log("[MSK-GS] DBG: if (Role < ROLE_Authority || WorldInfo.NetMode == NM_StandAlone)");
		ClientGetOnlineSubsystem();
	}
}

private reliable client function ClientGetOnlineSubsystem()
{
	`log("[MSK-GS] DBG: ClientGetOnlineSubsystem()");
	
	if (SW == None)
	{
		`log("[MSK-GS] DBG: 1");
		SW = OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem());
	}
	
	if (SW == None)
	{
		`log("[MSK-GS] DBG: 2");
		SetTimer(0.1f, false, nameof(ClientGetOnlineSubsystem));
	}
	else
	{
		`log("[MSK-GS] DBG: 3");
		ClearTimer(nameof(ClientGetOnlineSubsystem));
		ClientGetMembership();
	}
}

private reliable client function ClientGetMembership()
{
	local UniqueNetId GroupID;
	`log("[MSK-GS] DBG: ClientGetMembership()");
	class'OnlineSubsystem'.Static.StringToUniqueNetId("0x017000000223386E", GroupID);
	if (SW.CheckPlayerGroup(GroupID))
	{
		`log("[MSK-GS] DBG: ClientGetMembership() ServerApplyMembership()");
		ServerApplyMembership();
	}
}

private simulated reliable server function ServerApplyMembership()
{
	`log("[MSK-GS] DBG: ServerApplyMembership() start");
	
	if (Mut == None || C == None)
	{
		`log("[MSK-GS] DBG: ServerApplyMembership() timer");
		SetTimer(1.0f, false, nameof(ServerApplyMembership));
		return;
	}
	
	`log("[MSK-GS] DBG: ServerApplyMembership()"@Self@Mut@C);
	ClearTimer(nameof(ServerApplyMembership));
	Mut.MskGsMemberList.AddItem(C);
}

DefaultProperties
{
	bAlwaysRelevant = false;
	bOnlyRelevantToOwner = true;
	Role = ROLE_Authority;
	RemoteRole = ROLE_SimulatedProxy;
	bSkipActorPropertyReplication = false; // This is needed, otherwise the client-to-server RPC fails
}