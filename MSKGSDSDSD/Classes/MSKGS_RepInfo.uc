class MSKGS_RepInfo extends ReplicationInfo;

const MSKGS_LMT = class'MSKGS_LocalMessage';

enum MSKGS_PlayerType
{
	MSKGS_Unknown,
	MSKGS_Player,
	MSKGS_Group,
	MSKGS_Admin,
	MSKGS_Owner
};

var private IMSKGS MSKGS;
var private bool   ServerOwner;
var private bool   GroupMember;

var private repnotify E_LogLevel  LogLevel;
var private repnotify UniqueNetId GroupID;
var private repnotify float       CheckGroupTimer;

var private bool ObtainLogLevel;
var private bool ObtainGroupID;
var private bool ObtainCheckGroupTimer;

var private KFPlayerController        KFPC;
var private OnlineSubsystemSteamworks OSS;

replication
{
	if (bNetInitial)
		LogLevel, GroupID, CheckGroupTimer, ServerOwner;
}

public simulated event ReplicatedEvent(name VarName)
{
	`Log_Trace();
	
	switch (VarName)
	{
		case 'LogLevel':
			ObtainLogLevel = true;
			CheckGroupMembership();
			break;
			
		case 'GroupID':
			ObtainGroupID  = true;
			CheckGroupMembership();
			break;
			
		case 'CheckGroupTimer':
			ObtainCheckGroupTimer  = true;
			CheckGroupMembership();
			break;
		
		default:
			super.ReplicatedEvent(VarName);
			break;
	}
}

public function Init(
	E_LogLevel  _LogLevel,
	IMSKGS      _MSKGS,
	UniqueNetId _GroupID,
	float       _CheckGroupTimer,
	bool        _ServerOwner)
{
	LogLevel        = _LogLevel;
	MSKGS           = _MSKGS;
	GroupID         = _GroupID;
	CheckGroupTimer = _CheckGroupTimer;
	ServerOwner     = _ServerOwner;
	
	`Log_Trace();
}

public simulated function bool SafeDestroy()
{
	`Log_Trace();

	return (bPendingDelete || bDeleteMe || Destroy());
}

public simulated event PreBeginPlay()
{
	`Log_Trace();
	
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
	`Log_Trace();
	
	if (WorldInfo.NetMode == NM_StandAlone
	|| (ObtainLogLevel && ObtainGroupID && ObtainCheckGroupTimer && Role < ROLE_Authority))
	{
		if (GetKFPC() != None && KFPC.bIsEosPlayer)
		{
			`Log_Debug("EGS Player, skip group check");
			return;
		}
		
		if (OSS == None)
		{
			OSS = OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem());
		}
		
		if (OSS != None)
		{
			if (OSS.CheckPlayerGroup(GroupID))
			{
				ClearTimer(nameof(CheckGroupMembership));
				GroupMember = true;
				ServerApplyMembership();
			}
			else if (!IsTimerActive(nameof(CheckGroupMembership)) && CheckGroupTimer > 0.0f)
			{
				SetTimer(CheckGroupTimer, true, nameof(CheckGroupMembership));
			}
		}
		else
		{
			`Log_Error("Can't get online subsystem steamworks!");
		}
	}
}

public simulated function MSKGS_PlayerType PlayerType()
{
	`Log_Trace();
	
	if (IsServerOwner())
	{
		return MSKGS_Owner;
	}
		
	if (IsAdmin())
	{
		return MSKGS_Admin;
	}
		
	if (IsGroupMember())
	{
		return MSKGS_Group;
	}
		
	return MSKGS_Player;
}

public simulated function bool IsServerOwner()
{
	return ServerOwner;
}

public simulated function bool IsAdmin()
{
	return (GetKFPC() != None && KFPC.PlayerReplicationInfo != None && KFPC.PlayerReplicationInfo.bAdmin);
}

public simulated function bool IsGroupMember()
{
	return GroupMember;
}

public simulated function KFPlayerController GetKFPC()
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

private reliable server function ServerApplyMembership()
{
	`Log_Trace();
	
	GroupMember = true;
	
	if (PlayerType() <= MSKGS_Group)
	{
		`Log_Info("Increase boost:" @ PlayerType());
		MSKGS.IncreaseXPBoost(GetKFPC());
	}
}

public reliable client function WriteToChatLocalized(E_MSKGS_LocalMessageType LMT, String HexColor, optional String String1, optional String String2, optional String String3)
{
	`Log_Trace();
	
	WriteToChat(MSKGS_LMT.static.GetLocalizedString(LogLevel, LMT, String1, String2, String3), HexColor);
}

public reliable client function WriteToChat(String Message, String HexColor)
{
	local KFGFxHudWrapper HUD;
	
	`Log_Trace();
	
	if (GetKFPC() == None) return;
	
	if (KFPC.MyGFxManager.PartyWidget != None && KFPC.MyGFxManager.PartyWidget.PartyChatWidget != None)
	{
		KFPC.MyGFxManager.PartyWidget.PartyChatWidget.AddChatMessage(Message, HexColor);
	}

	HUD = KFGFxHudWrapper(KFPC.myHUD);
	if (HUD != None && HUD.HUDMovie != None && HUD.HUDMovie.HudChatBox != None)
	{
		HUD.HUDMovie.HudChatBox.AddChatMessage(Message, HexColor);
	}
}

public reliable client function WriteToHUDLocalized(E_MSKGS_LocalMessageType LMT, optional String String1, optional String String2, optional String String3, optional float DisplayTime = 0.0f)
{
	`Log_Trace();
	
	WriteToHUD(MSKGS_LMT.static.GetLocalizedString(LogLevel, LMT, String1, String2, String3), DisplayTime);
}

public reliable client function WriteToHUD(String Message, optional float DisplayTime = 0.0f)
{
	`Log_Trace();
	
	if (GetKFPC() == None) return;
	
	if (DisplayTime <= 0.0f)
	{
		DisplayTime = CalcDisplayTime(Message);
	}
	
	if (KFPC.MyGFxHUD != None)
	{
		KFPC.MyGFxHUD.DisplayMapText(Message, DisplayTime, false);
	}
}

public reliable client function DefferedClearMessageHUD(optional float Time = 0.0f)
{
	`Log_Trace();
	
	SetTimer(Time, false, nameof(ClearMessageHUD));
}

public reliable client function ClearMessageHUD()
{
	`Log_Trace();
	
	if (GetKFPC() == None) return;
	
	if (KFPC.MyGFxHUD != None && KFPC.MyGFxHUD.MapTextWidget != None)
	{
		KFPC.MyGFxHUD.MapTextWidget.StoredMessageList.Length = 0;
		KFPC.MyGFxHUD.MapTextWidget.HideMessage();
	}
}

private simulated function float CalcDisplayTime(String Message)
{
	`Log_Trace();
	
	return FClamp(Len(Message) / 20.0f, 3, 30);
}

defaultproperties
{
	bAlwaysRelevant               = false
	bOnlyRelevantToOwner          = true
	bSkipActorPropertyReplication = false
	
	GroupMember = false;
	ServerOwner = false;
	
	ObtainLogLevel        = false;
	ObtainGroupID         = false;
	ObtainCheckGroupTimer = false;
}