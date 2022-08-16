class MSKGS_RepInfo extends ReplicationInfo;

const CfgXPBoost = class'CfgXPBoost';

var public E_LogLevel  LogLevel;
var public MSKGS       MSKGS;
var public UniqueNetId GroupID;
var public float       CheckGroupTimer;

var private KFPlayerController KFPC;
var private OnlineSubsystem    OS;

var public  bool ServerOwner;
var private bool GroupMember;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		LogLevel, GroupID, CheckGroupTimer;
}

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public simulated event PreBeginPlay()
{
	`Log_Trace();
	
	if (Role < ROLE_Authority || WorldInfo.NetMode == NM_StandAlone)
	{
		OS = class'GameEngine'.static.GetOnlineSubsystem();
		if (OS != None)
		{
			CheckGroupMembership();
		}
		else
		{
			`Log_Error("Can't get online subsystem!");
		}
	}
	
	Super.PreBeginPlay();
}

public simulated event PostBeginPlay()
{
	`Log_Trace();
	
	if (bPendingDelete || bDeleteMe) return;
	
	Super.PostBeginPlay();
}

private simulated function CheckGroupMembership()
{
	if (OS.CheckPlayerGroup(GroupID))
	{
		ClearTimer(nameof(CheckGroupMembership));
		ServerApplyMembership();
	}
	else if (CheckGroupTimer > 0.0f && !IsTimerActive(nameof(CheckGroupMembership)))
	{
		SetTimer(CheckGroupTimer, true, nameof(CheckGroupMembership));
	}
}

private reliable server function ServerApplyMembership()
{
	GroupMember = true;
	MSKGS.IncreaseXPBoost(GetKFPC());
}

public function int XPBoost()
{
	`Log_Trace();
	
	if (ServerOwner)
	{
		return CfgXPBoost.default.BoostOwner;
	}
	
	if (GetKFPC() != None && GetKFPC().PlayerReplicationInfo != None && GetKFPC().PlayerReplicationInfo.bAdmin)
	{
		return CfgXPBoost.default.BoostAdmin;
	}
	
	if (GroupMember)
	{
		return CfgXPBoost.default.BoostGroup;
	}
	
	return CfgXPBoost.default.BoostPlayer;
}

private simulated function KFPlayerController GetKFPC()
{
	`Log_Trace();
	
	if (KFPC != None) return KFPC;
	
	KFPC = KFPlayerController(Owner);
	
	if (KFPC == None && ROLE < ROLE_Authority)
	{
		KFPC = KFPlayerController(GetALocalPlayerController());
	}
	
	return KFPC;
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
	
	GroupMember = false;
	ServerOwner = false;
}