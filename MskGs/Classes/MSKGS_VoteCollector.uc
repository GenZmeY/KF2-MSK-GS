class MskGsVoteCollector extends KFVoteCollector
	dependson(MapStats);

var string SortPolicy;
var bool bOfficialNextMapOnly;
var bool bRandomizeNextMap;

var private array<string> ActiveMapCycle;

var public array<UniqueNetId> KickProtectedList;

var private array<KFPlayerController> KickWarningList;
var private array<KFPlayerController> KickPunishList;

function NotifyLogout(Controller Exiting)
{
	KickWarningList.RemoveItem(KFPlayerController(Exiting));
	KickPunishList.RemoveItem(KFPlayerController(Exiting));
}

function PunishmentTick()
{
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;
	local KFPlayerController KFPC;
	local KFInventoryManager KFIM;
	local array<KFPlayerController> LocalKickPunishList;
	
	if (KickPunishList.Length == 0)
	{
		ClearTimer(nameof(PunishmentTick));
		return;
	}
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	
	LocalKickPunishList = KickPunishList;
	foreach LocalKickPunishList(KFPC)
	{
		if (KFGRI.bMatchHasBegun)
		{
			if (KFPC.Pawn.Health <= 1)
			{
				KFPC.Suicide();
				KickPunishList.RemoveItem(KFPC);
				KickWarningList.RemoveItem(KFPC);
			}
			else
			{
				KFPC.Pawn.Health--;
				
				if (KFPawn_Human(KFPC.Pawn).Armor > 0)
					KFPawn_Human(KFPC.Pawn).Armor--;
				
				if (KFPC.Pawn.InvManager != None)
				{
					KFIM = KFInventoryManager(KFPC.Pawn.InvManager);
					if (KFIM != None)
					{
						KFIM.ThrowMoney();
					}
				}
			}
		}
		else if (KFGI.AccessControl != none)
		{
			KickPunishList.RemoveItem(KFPC);
			KickWarningList.RemoveItem(KFPC);
			KFAccessControl(KFGI.AccessControl).ForceKickPlayer(KFPC, KFGI.AccessControl.KickedMsg);
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteSucceeded, CurrentKickVote.PlayerPRI);
		}
	}
}

function bool IsPlayerKickProtected(PlayerReplicationInfo PRI_Kickee)
{
	return (KickProtectedList.Find('Uid', PRI_Kickee.UniqueId.Uid) != -1);
}

function bool IsKickerWarned(KFPlayerController KFPC)
{
	return (KickWarningList.Find(KFPC) != -1);
}

function bool IsKickerPunishListed(KFPlayerController KFPC)
{
	return (KickPunishList.Find(KFPC) != -1);
}

function WarnKicker(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{	
	local KFPlayerController KFPC_Kicker;
	
	KFPC_Kicker = KFPlayerController(PRI_Kicker.Owner);
	if (!IsKickerWarned(KFPC_Kicker))
	{
		KickWarningList.AddItem(KFPC_Kicker);
		WorldInfo.Game.Broadcast(KFPC_Kicker, PRI_Kicker.PlayerName@"tried to kick"@PRI_Kickee.PlayerName$". If he tries to do it again, the hand of God will punish him");
	}
}

function PunishKicker(PlayerReplicationInfo PRI_Kicker)
{
	local KFPlayerController KFPC_Kicker;

	KFPC_Kicker = KFPlayerController(PRI_Kicker.Owner);
	if (!IsKickerPunishListed(KFPC_Kicker))
	{
		KickPunishList.AddItem(KFPC_Kicker);
		WorldInfo.Game.Broadcast(KFPC_Kicker, PRI_Kicker.PlayerName@"seems to be feeling bad...");
		if (!IsTimerActive(nameof(PunishmentTick)))
		{
			SetTimer(0.5f, true, nameof(PunishmentTick), self);
		}
	}
}

function ServerStartVoteKick(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{
	local int i;
	local array<KFPlayerReplicationInfo> PRIs;
	local KFGameInfo KFGI;
	local KFPlayerController KFPC, KickeePC;

	KFGI = KFGameInfo(WorldInfo.Game);
	KFPC = KFPlayerController(PRI_Kicker.Owner);
	KickeePC = KFPlayerController(PRI_Kickee.Owner);
	
	if (KFGI.bDisableKickVote) // Kick voting is disabled
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteDisabled);
		return;
	}

	if (PRI_Kicker.bOnlySpectator) // Spectators aren't allowed to vote
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNoSpectators);
		return;
	}

	if (KFGI.NumPlayers <= 2) // Not enough players to start a vote
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNotEnoughPlayers);
		return;
	}

	if (KickedPlayers >= 2) // Maximum number of players kicked per match has been reached
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteMaxKicksReached);
		return;
	}

	if (IsPlayerKickProtected(PRI_Kickee)) // Bottling
	{
		if (IsKickerWarned(KFPC))
		{
			PunishKicker(PRI_Kicker);
		}
		else
		{
			WarnKicker(PRI_Kickee, PRI_Kicker);
		}
		return;
	}

	if (KFGI.AccessControl != none) // Can't kick admins
	{
		if (KFGI.AccessControl.IsAdmin(KickeePC))
		{
			KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteAdmin);
			return;
		}
	}

	if (bIsFailedVoteTimerActive) // Last vote failed, must wait until failed vote cooldown before starting a new vote
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteRejected);
		return;
	}

	if (bIsSkipTraderVoteInProgress || bIsPauseGameVoteInProgress) // A kick vote is not allowed while another vote is active
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	if (!bIsKickVoteInProgress)
	{
		// Clear voter array
		PlayersThatHaveVoted.Length = 0;

		// Cache off these values in case player leaves before vote ends -- no cheating!
		CurrentKickVote.PlayerID = PRI_Kickee.UniqueId;
		CurrentKickVote.PlayerPRI = PRI_Kickee;
		CurrentKickVote.PlayerIPAddress = KickeePC.GetPlayerNetworkAddress();

		bIsKickVoteInProgress = true;

		GetKFPRIArray(PRIs);
		for (i = 0; i < PRIs.Length; i++)
		{
			PRIs[i].ShowKickVote(PRI_Kickee, VoteTime, !(PRIs[i] == PRI_Kicker || PRIs[i] == PRI_Kickee));
		}
		KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteStarted, CurrentKickVote.PlayerPRI);
		WorldInfo.Game.Broadcast(KFPC, PRI_Kicker.PlayerName@"starts voting for kick"@PRI_Kickee.PlayerName);
		SetTimer(VoteTime, false, nameof(ConcludeVoteKick), self );
		// Cast initial vote
		RecieveVoteKick(PRI_Kicker, true);
	}
	else if (PRI_Kickee == CurrentKickVote.PlayerPRI)
	{
		RecieveVoteKick(PRI_Kicker, false);
	}
	else
	{
		// Can't start a new vote until current one is over
		KFPlayerController(PRI_Kicker.Owner).ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteInProgress);
	}
}

reliable server function RecieveVoteKick(PlayerReplicationInfo PRI, bool bKick)
{
	local KFPlayerController KFPC;

	if(PlayersThatHaveVoted.Find(PRI) == INDEX_NONE)
	{
		//accept their vote
		PlayersThatHaveVoted.AddItem(PRI);
		if(bKick)
		{
			yesVotes++;
		}
		else
		{
			noVotes++;
		}

		KFPC = KFPlayerController(PRI.Owner);
		if(KFPC != none)
		{
			if(bKick)
			{
				KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteYesReceived, CurrentKickVote.PlayerPRI);
				WorldInfo.Game.Broadcast(KFPC, PRI.PlayerName@"vote: Yes");
			}
			else
			{
				KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNoReceived, CurrentKickVote.PlayerPRI);
				WorldInfo.Game.Broadcast(KFPC, PRI.PlayerName@"vote: No");
			}
			
		}

		if( ShouldConcludeKickVote() )
		{
			ConcludeVoteKick();
		}
		else
		{
			ReplicateKickVotes();
		}
	}
}

function LoadActiveMapCycle()
{
	local KFGameInfo KFGI;

	if (ActiveMapCycle.Length > 0) return;		
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (WorldInfo.NetMode == NM_Standalone)
		ActiveMapCycle = Maplist;
	else if (KFGI != None) 
		ActiveMapCycle = KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps;
}

function bool IsOfficialMap(string MapName)
{
	local KFMapSummary MapData;
	MapData = class'KFUIDataStore_GameResource'.static.GetMapSummaryFromMapName(MapName);
	if (MapData == None) return False;
	return (MapData.MapAssociation != EAI_Custom);
}

function int GetNextMapIndex()
{
	local KFGameInfo KFGI;
	local array<string> AviableMaps;
	local string Map;
	local int CurrentMapIndex;
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None) return INDEX_NONE;

	LoadActiveMapCycle();
	if (bRandomizeNextMap)
	{
		foreach ActiveMapCycle(Map)
		{
			if (bOfficialNextMapOnly && !IsOfficialMap(Map))
				continue;
			if (KFGI.IsMapAllowedInCycle(Map))
				AviableMaps.AddItem(Map);
		}
		if (AviableMaps.Length > 0)
			return ActiveMapCycle.Find(AviableMaps[Rand(AviableMaps.Length)]);
	}
	else if (ActiveMapCycle.Length > 0)
	{
		// I don't use KFGameInfo.GetNextMap() because
		// it uses and changes global KFGameInfo.MapCycleIndex variable
		CurrentMapIndex = ActiveMapCycle.Find(WorldInfo.GetMapName(true));
		if (CurrentMapIndex != INDEX_NONE)
		{
			for (CurrentMapIndex++; CurrentMapIndex < ActiveMapCycle.Length; CurrentMapIndex++)
			{
				if (bOfficialNextMapOnly && !IsOfficialMap(ActiveMapCycle[CurrentMapIndex]))
					continue;
				if (KFGI.IsMapAllowedInCycle(ActiveMapCycle[CurrentMapIndex]))
					return CurrentMapIndex;
			}
		}
		return 0;
	}
	
	return INDEX_NONE;
}

function int GetNextMap()
{
	local int MapIndex;

	if (MapVoteList.Length > 0)
		MapIndex = MapVoteList[0].MapIndex;
	else
		MapIndex = GetNextMapIndex();

	return MapIndex;
}

DefaultProperties
{
}
