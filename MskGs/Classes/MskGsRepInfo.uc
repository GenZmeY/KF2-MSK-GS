class MskGsRepInfo extends ReplicationInfo;

// Server vars
var public MskGsMut Mut;
var public Controller C;

// Client vars
var private OnlineSubsystemSteamworks SW;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

    if (bDeleteMe) return;
	
	if (Role < ROLE_Authority || WorldInfo.NetMode == NM_StandAlone)
	{
		ClientGetOnlineSubsystem();
	}
}

private reliable client function ClientGetOnlineSubsystem()
{
	if (SW == None)
	{
		SW = OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem());
	}
	
	if (SW == None)
	{
		SetTimer(0.1f, false, nameof(ClientGetOnlineSubsystem));
	}
	else
	{
		ClearTimer(nameof(ClientGetOnlineSubsystem));
		ClientGetMembership();
	}
}

private reliable client function ClientGetMembership()
{
	local UniqueNetId GroupID;
	class'OnlineSubsystem'.Static.StringToUniqueNetId("0x017000000223386E", GroupID);
	if (SW.CheckPlayerGroup(GroupID)) ServerApplyMembership();
}

private simulated reliable server function ServerApplyMembership()
{
	if (Mut == None || C == None)
	{
		SetTimer(1.0f, false, nameof(ServerApplyMembership));
		return;
	}
	
	ClearTimer(nameof(ServerApplyMembership));
	Mut.MskGsMemberList.AddItem(C);
}

DefaultProperties
{
	bAlwaysRelevant = false;
	bOnlyRelevantToOwner = true;
	Role = ROLE_Authority;
	RemoteRole = ROLE_SimulatedProxy;
	bSkipActorPropertyReplication = false;
}