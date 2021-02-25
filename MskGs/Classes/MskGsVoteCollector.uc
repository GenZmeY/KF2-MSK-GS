class MskGsVoteCollector extends KFVoteCollector;

var public array<UniqueNetId> ImportantPersonList;
var private array<KFPlayerController> PunishList;

function ServerStartPunishment()
{
	local KFGameReplicationInfo KFGRI;
	local KFGameInfo KFGI;
	local KFPlayerController KFPC;
	local int i;
	
	if (PunishList.Length == 0)
		return;
	
	KFGRI = KFGameReplicationInfo(WorldInfo.GRI);
	KFGI = KFGameInfo(WorldInfo.Game);
	
	for (i=0; i < PunishList.Length; i++)
	{
		KFPC = PunishList[i];
		if (KFGRI.bMatchHasBegun)
		{
			KFPC.Suicide();
		}
		else if (KFGI.AccessControl != none)
		{
			KFAccessControl(KFGI.AccessControl).ForceKickPlayer(KFPC, KFGI.AccessControl.KickedMsg);
			KFGI.BroadcastLocalized(KFGI, class'KFLocalMessage', LMT_KickVoteSucceeded, CurrentKickVote.PlayerPRI);
		}
	}
	PunishList.Length = 0;
}

function bool ImportantKickee(PlayerReplicationInfo PRI_Kickee, PlayerReplicationInfo PRI_Kicker)
{
	local string PunishMessage;
	local KFPlayerController KFPC_Kicker;

	if (ImportantPersonList.Find('Uid', PRI_Kickee.UniqueId.Uid) != -1)
	{
		KFPC_Kicker = KFPlayerController(PRI_Kicker.Owner);
		if (PunishList.Find(KFPC_Kicker) == -1)
		{
			PunishMessage = PRI_Kicker.PlayerName@"tried to kick"@PRI_Kickee.PlayerName@", but sat down on the bottle instead.";
			WorldInfo.Game.Broadcast(KFPC_Kicker, PunishMessage);

			PunishList.AddItem(KFPC_Kicker);
			SetTimer(2.0f, false, 'ServerStartPunishment', self);
		}
		return true;
	}
	return false;
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

	// Kick voting is disabled
	if(KFGI.bDisableKickVote)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteDisabled);
		return;
	}

	// Spectators aren't allowed to vote
	if(PRI_Kicker.bOnlySpectator)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNoSpectators);
		return;
	}

	// Not enough players to start a vote
	if( KFGI.NumPlayers <= 2 )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteNotEnoughPlayers);
		return;
	}

	// Maximum number of players kicked per match has been reached
	if( KickedPlayers >= 2 )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteMaxKicksReached);
		return;
	}

	// Bottling
	if (ImportantKickee(PRI_Kickee, PRI_Kicker))
	{
		return;
	}

	// Can't kick admins
	if(KFGI.AccessControl != none)
	{
		if(KFGI.AccessControl.IsAdmin(KickeePC))
		{
			KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteAdmin);
			return;
		}
	}

	// Last vote failed, must wait until failed vote cooldown before starting a new vote
	if( bIsFailedVoteTimerActive )
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_KickVoteRejected);
		return;
	}

	// A kick vote is not allowed while another vote is active
	if(bIsSkipTraderVoteInProgress)
	{
		KFPC.ReceiveLocalizedMessage(class'KFLocalMessage', LMT_OtherVoteInProgress);
		return;
	}

	if( !bIsKickVoteInProgress )
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
		SetTimer( VoteTime, false, nameof(ConcludeVoteKick), self );
		// Cast initial vote
		RecieveVoteKick(PRI_Kicker, true);
	}
	else if(PRI_Kickee == CurrentKickVote.PlayerPRI)
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

function int GetNextMap()
{
	local KFGameInfo KFGI;
	local array<string> ActiveMapCycle;
	local array<string> AviableMaps;
	local string Map;

	if(MapVoteList.Length > 0)
	{
		return MapVoteList[0].MapIndex;
	}
	else // random default map that exists in the active map cycle and allowed for current gamemode
	{
		KFGI = KFGameInfo(WorldInfo.Game);
		if (KFGI == None) return -1;
		
		ActiveMapCycle = KFGI.GameMapCycles[KFGI.ActiveMapCycle].Maps;

		foreach class'KFGameViewportClient'.default.TripWireOfficialMaps(Map)
			if (ActiveMapCycle.Find(Map) != -1 && KFGI.IsMapAllowedInCycle(Map))
				AviableMaps.AddItem(Map);

		foreach class'KFGameViewportClient'.default.CommunityOfficialMaps(Map)
			if (ActiveMapCycle.Find(Map) != -1 && KFGI.IsMapAllowedInCycle(Map))
				AviableMaps.AddItem(Map);

		if (AviableMaps.Length > 0)
			return ActiveMapCycle.Find(AviableMaps[Rand(AviableMaps.Length)]);
	}

	return -1;
}

DefaultProperties
{
}
