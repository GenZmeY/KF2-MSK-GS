class MSKGS_PlayerController extends KFPlayerController;

var public  MSKGS_RepInfo RepInfo;
var public  byte MinLevel, MaxLevel;
var public  int  DisconnectTimer;
var public  String HexColorInfo;
var public  String HexColorWarn;
var public  String HexColorError;

var private KFGameReplicationInfo KFGRI;

var private bool StatsInitialized;
var private KFGFxWidget_PartyInGame PartyInGameWidget;
var private bool bChatMessageRecieved;

replication
{
	if (bNetInitial && Role == ROLE_Authority)
		RepInfo, MinLevel, MaxLevel, DisconnectTimer,
		HexColorInfo, HexColorWarn, HexColorError;
}

public simulated event PreBeginPlay()
{
	super.PreBeginPlay();
}

public simulated event PostBeginPlay()
{
	super.PostBeginPlay();
}

private simulated function KFGameReplicationInfo GetKFGRI()
{
	if (KFGRI == None)
	{
		KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	}
	
	return KFGRI;
}

private simulated function SetPartyInGameWidget()
{
	if (MyGFxManager == None) return;
	if (MyGFxManager.PartyWidget == None) return;
	
	PartyInGameWidget = KFGFxWidget_PartyInGame(MyGFxManager.PartyWidget);
}

private simulated function bool CheckPartyInGameWidget()
{
	if (PartyInGameWidget == None)
	{
		SetPartyInGameWidget();
	}
	
	return (PartyInGameWidget != None);
}

private simulated function HideReadyButton()
{
	if (CheckPartyInGameWidget())
	{
		PartyInGameWidget.SetReadyButtonVisibility(false);
	}
}

private simulated function ShowReadyButton()
{
	if (CheckPartyInGameWidget())
	{
		PartyInGameWidget.SetReadyButtonVisibility(true);
		PartyInGameWidget.UpdateReadyButtonText();
		PartyInGameWidget.UpdateReadyButtonVisibility();
	}
}

private simulated function NoPerkDisconnect()
{
	if (CheckPartyInGameWidget())
	{
		if (!bChatMessageRecieved)
		{
			RepInfo.WriteToChatLocalized(
				MSKGS_NoPerksDisconnect,
				HexColorError,
				String(DisconnectTimer));
			bChatMessageRecieved = true;
		}
		
		if (DisconnectTimer-- <= 0)
		{
			ClearTimer(nameof(HideReadyButton));
			ClearTimer(nameof(NoPerkDisconnect));
			ClientWasKicked();
		}
	}
}

private simulated function PerksLocked()
{
	if (CheckPartyInGameWidget() && !bChatMessageRecieved)
	{
		ClearTimer(nameof(PerksLocked));
		RepInfo.WriteToChatLocalized(
			MSKGS_UnsuitablePerksLocked,
			HexColorWarn);
		bChatMessageRecieved = true;
	}
}

public simulated function OnStatsInitialized(bool bWasSuccessful)
{
	Super.OnStatsInitialized(bWasSuccessful);
	StatsInitialized = true;
	RequestPerkChange(CheckCurrentPerkAllowed());
}

public reliable server function ServerHidePerks()
{
	HidePerks();
	ClientHidePerks();
}

private reliable client function ClientHidePerks()
{
	HidePerks();
}

private simulated function HidePerks()
{
	local int Index;

	if (GetKFGRI() == None)
	{
		SetTimer(0.1f, false, nameof(HidePerks));
		return;
	}

	for (Index = PerkList.length - 1; Index >= 0; --Index)
	{
		if (!KFGRI.IsPerkAllowed(PerkList[Index].PerkClass))
		{
			PerkList.Remove(Index, 1);
		}
	}
	
	SavedPerkIndex = CheckCurrentPerkAllowed();
}

public simulated function byte CheckCurrentPerkAllowed()
{
	local PerkInfo Perk;
	
	if (SavedPerkIndex >= PerkList.length || !IsPerkAllowed(PerkList[SavedPerkIndex]))
	{
		SavedPerkIndex = 0;
		for (SavedPerkIndex = 0; SavedPerkIndex < PerkList.length; SavedPerkIndex++)
		{
			if (IsPerkAllowed(PerkList[SavedPerkIndex]))
			{
				break;
			}
		}
	}

	if (SavedPerkIndex >= PerkList.length)
	{
		SavedPerkIndex = 0;
		if (StatsInitialized && ROLE < ROLE_Authority)
		{
			SetTimer(0.1f, true, nameof(HideReadyButton));
			SetTimer(1.0f, true, nameof(NoPerkDisconnect));
		}
	}
	else if (StatsInitialized && ROLE < ROLE_Authority)
	{
		foreach PerkList(Perk)
		{
			if (!IsPerkAllowed(Perk))
			{
				SetTimer(1.0f, true, nameof(PerksLocked));
				break;
			}
		}
	}

	return SavedPerkIndex;
}

public simulated function bool IsPerkAllowed(PerkInfo Perk)
{
	local bool PerkAllowed;

	PerkAllowed = true;
	
	if (GetKFGRI() != None)
	{
		PerkAllowed = KFGRI.IsPerkAllowed(Perk.PerkClass);
	}
	
	return (PerkAllowed && Perk.PerkLevel >= MinLevel && Perk.PerkLevel <= MaxLevel);
}

public simulated function InitPerkLoadout()
{
	if (CurrentPerk == None) // Problem here: it is NONE for some reason
	{
		CurrentPerk = GetPerk(); // even after that
		// dunno where and how it is initialized
		// and why it dont happened now
	}
		
	Super.InitPerkLoadout();
}

defaultproperties
{
	StatsInitialized     = false
	bChatMessageRecieved = false
	
	DisconnectTimer      = 15
	MinLevel             = 0
	MaxLevel             = 25
	
	HexColorInfo         = "0000FF"
	HexColorWarn         = "FFFF00"
	HexColorError        = "FF0000"
}