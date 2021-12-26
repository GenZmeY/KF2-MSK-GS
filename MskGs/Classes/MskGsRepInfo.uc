class MskGsRepInfo extends ReplicationInfo;

const GroupUIDStr = "0x017000000223386E";
const MaxRetries  = 10;
const TimerDelay  = 1.0f;

// Server vars
var public MskGsMut Mut;
var public Controller C;
var private int ServerApplyMembershipRetries;

// Client vars
var private OnlineSubsystemSteamworks SW;
var private int ClientGetOnlineSubsystemRetries;

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
	
	if (SW == None && ClientGetOnlineSubsystemRetries < MaxRetries)
	{
		ClientGetOnlineSubsystemRetries++;
		SetTimer(TimerDelay, false, nameof(ClientGetOnlineSubsystem));
	}
	else
	{
		ClearTimer(nameof(ClientGetOnlineSubsystem));
		if (SW != None) ClientGetMembership();
	}
}

private reliable client function ClientGetMembership()
{
	local UniqueNetId GroupID;
	class'OnlineSubsystem'.Static.StringToUniqueNetId(GroupUIDStr, GroupID);
	if (SW.CheckPlayerGroup(GroupID)) ServerApplyMembership();
}

private simulated reliable server function ServerApplyMembership()
{
	if ((Mut == None || C == None) && ServerApplyMembershipRetries < MaxRetries)
	{
		ServerApplyMembershipRetries++;
		SetTimer(TimerDelay, false, nameof(ServerApplyMembership));
		return;
	}
	
	ClearTimer(nameof(ServerApplyMembership));
	
	if (Mut != None && C != None) Mut.AddMskGsMember(C);
}

DefaultProperties
{
	bAlwaysRelevant = false;
	bOnlyRelevantToOwner = true;
	Role = ROLE_Authority;
	RemoteRole = ROLE_SimulatedProxy;
	bSkipActorPropertyReplication = false;
	
	ServerApplyMembershipRetries = 0
	ClientGetOnlineSubsystemRetries = 0
}