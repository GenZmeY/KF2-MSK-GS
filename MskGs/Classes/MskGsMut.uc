Class MskGsMut extends KFMutator
	config(MskGs);

const CurrentVersion = 3;
var config int ConfigVersion;

var config bool bEnableMapStats; var config string SortStats; var config bool bOfficialNextMapOnly; var config bool bRandomizeNextMap; var config int WeapLifespan;
var config int DoshLifespan;

var config array<string> KickProtectedList;
var config array<string> AdminList;
var config array<int> PerPlayerMaxMonsters;

var public bool bXpNotifications;
var bool bInitialized;

var array<MskGsRepInfo> RepClients;
var array<Controller> MskGsMemberList;
var array<UniqueNetId> AdminUIDList;

function InitMutator(string Options, out string ErrorMessage)
{
	local int MaxPlayers, MaxPlayersAllowed;
	
	super.InitMutator(Options, ErrorMessage);
	
	if (MyKFGI == none)
	{
		`log("[MskGsMut] Error: can't init, MyKFGI is none");
		return;
	}
	
	MaxPlayers = Clamp(MyKFGI.GetIntOption(Options, "MaxPlayers", MaxPlayers), 6, 128);
	MaxPlayersAllowed = MaxPlayers;
	MyKFGI.MaxPlayers = MaxPlayers;
	MyKFGI.MaxPlayersAllowed = MaxPlayersAllowed;
}

function InitConfig()
{
	// Update from config version to current version if needed
	switch (ConfigVersion)
	{
		case 0: // which means there is no config right now
			bEnableMapStats = True;
			SortStats = "CounterDesc";
			bOfficialNextMapOnly = True;
			bRandomizeNextMap = True;
			WeapLifespan = 60 * 60;
		case 1:
			if (PerPlayerMaxMonsters.Length != 6)
			{
				PerPlayerMaxMonsters.Length = 0;
				PerPlayerMaxMonsters.AddItem(12);
				PerPlayerMaxMonsters.AddItem(18);
				PerPlayerMaxMonsters.AddItem(24);
				PerPlayerMaxMonsters.AddItem(32);
				PerPlayerMaxMonsters.AddItem(34);
				PerPlayerMaxMonsters.AddItem(36);
			}
		case 2:
			if (DoshLifespan == 0)
			{
				DoshLifespan = 60 * 5;
			}
		case 2147483647:
			`log("[MskGsMut] Config updated to version"@CurrentVersion);
			break;
		case CurrentVersion:
			`log("[MskGsMut] Config is up-to-date");
			break;
		default:
			`log("[MskGsMut] Warn: The config version is higher than the current version");
			`log("[MskGsMut] Warn: Config version is"@ConfigVersion@"but current version is"@CurrentVersion);
			`log("[MskGsMut] Warn: The config version will be changed to "@CurrentVersion);
			break;
	}
	
	// Check and correct some values
	if (!(SortStats ~= "CounterAsc"
		|| SortStats ~= "CounterDesc"
		|| SortStats ~= "NameAsc"
		|| SortStats ~= "NameDesc"
		|| SortStats ~= "False"))
	{
		`log("[MskGsMut] Warn: SortStats value not recognized ("$SortStats$") and will be set to False");
		`log("[MskGsMut] Warn: Valid values for SortStats: False CounterAsc CounterDesc NameAsc NameDesc");
		SortStats = "False";
	}

	ConfigVersion = CurrentVersion;
	SaveConfig();
}

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

	Initialize();
}

function Initialize()
{
	local MskGsVoteCollector VoteCollector;
	local OnlineSubsystem steamworks;
	local string Person;
	local UniqueNetId PersonUID;
	
	if (bInitialized) return;
	
	if (MyKFGI == None || MyKFGI.MyKFGRI == None)
	{
		SetTimer(1.f, false, nameof(Initialize));
		return;
	}
	
	bInitialized = true;

	InitConfig();

	MyKFGI.KFGFxManagerClass = class'MskGsGFxMoviePlayer_Manager';
	MyKFGI.MyKFGRI.VoteCollectorClass = class'MskGsVoteCollector';
	if (MyKFGI.PlayerControllerClass == class'KFGame.KFPlayerController')
		MyKFGI.PlayerControllerClass = class'MskGsPlayerController';
	else if (MyKFGI.PlayerControllerClass == class'KFGameContent.KFPlayerControllerVersus')
		MyKFGI.PlayerControllerClass = class'MskGsPlayerControllerVersus';
	else if (MyKFGI.PlayerControllerClass == class'KFGame.KFPlayerController_WeeklySurvival')
		MyKFGI.PlayerControllerClass = class'MskGsPlayerController_WeeklySurvival';
	MyKFGI.MyKFGRI.VoteCollector = new(MyKFGI.MyKFGRI) MyKFGI.MyKFGRI.VoteCollectorClass;
	
	VoteCollector = MskGsVoteCollector(MyKFGI.MyKFGRI.VoteCollector);
	VoteCollector.bEnableMapStats = bEnableMapStats;
	VoteCollector.bOfficialNextMapOnly = bOfficialNextMapOnly;
	VoteCollector.bRandomizeNextMap = bRandomizeNextMap;
	VoteCollector.SortPolicy = SortStats;
	
	if (MskGs_Endless(MyKFGI) != None)
	{
		bXpNotifications = true;
		MskGs_Endless(MyKFGI).Mut = Self;
	}
	else if (MskGs_Objective(MyKFGI) != None)
	{
		bXpNotifications = (MyKFGI.GameDifficulty != 3);
		MskGs_Objective(MyKFGI).Mut = Self;
	}
	else if (MskGs_Survival(MyKFGI) != None)
	{
		bXpNotifications = (MyKFGI.GameDifficulty != 3);
		MskGs_Survival(MyKFGI).Mut = Self;
	}
	else if (MskGs_VersusSurvival(MyKFGI) != None)
	{
		bXpNotifications = false;
		MskGs_VersusSurvival(MyKFGI).Mut = Self;
	}
	else if (MskGs_WeeklySurvival(MyKFGI) != None)
	{
		bXpNotifications = true;
		MskGs_WeeklySurvival(MyKFGI).Mut = Self;
	}
	
	steamworks = class'GameEngine'.static.GetOnlineSubsystem();
	
	foreach KickProtectedList(Person)
	{
		if (IsUID(Person) && steamworks.StringToUniqueNetId(Person, PersonUID))
		{
			if (VoteCollector.KickProtectedList.Find('Uid', PersonUID.Uid) == -1)
				VoteCollector.KickProtectedList.AddItem(PersonUID);
		}
		else if (steamworks.Int64ToUniqueNetId(Person, PersonUID))
		{
			if (VoteCollector.KickProtectedList.Find('Uid', PersonUID.Uid) == -1)
				VoteCollector.KickProtectedList.AddItem(PersonUID);
		}
		else `Log("[MskGsMut] WARN: Can't add person:"@Person);
	}
	
	foreach AdminList(Person)
	{
		if (IsUID(Person) && steamworks.StringToUniqueNetId(Person, PersonUID))
		{
			if (AdminUIDList.Find('Uid', PersonUID.Uid) == -1)
				AdminUIDList.AddItem(PersonUID);
		}
		else if (steamworks.Int64ToUniqueNetId(Person, PersonUID))
		{
			if (AdminUIDList.Find('Uid', PersonUID.Uid) == -1)
				AdminUIDList.AddItem(PersonUID);
		}
		else `Log("[MskGsMut] WARN: Can't add admin:"@Person);
	}
	
	ModifySpawnManager();

	`Log("[MskGsMut] Mutator loaded.");
}

function ModifySpawnManager()
{
	local int i, j;
	
	if (MyKFGI.SpawnManager == None)
	{
		SetTimer(1.f, false, nameof(ModifySpawnManager));
		return;
	}
	
	for (i = 0; i < MyKFGI.SpawnManager.PerDifficultyMaxMonsters.Length; i++)
		for (j = 0; j < MyKFGI.SpawnManager.PerDifficultyMaxMonsters[i].MaxMonsters.Length; j++)
			MyKFGI.SpawnManager.PerDifficultyMaxMonsters[i].MaxMonsters[j] = PerPlayerMaxMonsters[j];
}

function AddMutator(Mutator Mut)
{
	if (Mut == Self) return;
	
	if (Mut.Class == Class)
		Mut.Destroy();
	else
		Super.AddMutator(Mut);
}

private function bool IsUID(String ID)
{
	return (Left(ID, 2) ~= "0x");
}

function bool CheckRelevance(Actor Other)
{
	local bool SuperRelevant;

	SuperRelevant = super.CheckRelevance(Other);

	// if this actor is going to be destroyed, return now
	if (!SuperRelevant)
	{
		return SuperRelevant;
	}

	// otherwise modify dosh or weapon lifespan
	if (KFDroppedPickup_Cash(Other) != None)
	{
		if (DoshLifespan != 0) Other.Lifespan = float(DoshLifespan);
	}
	else if (KFDroppedPickup(Other) != None)
	{
		if (WeapLifespan != 0) Other.Lifespan = float(WeapLifespan);
	}

	return SuperRelevant;
}

function bool PreventDeath(Pawn Killed, Controller Killer, class<DamageType> damageType, vector HitLocation)
{
	local KFWeapon TempWeapon;
	local KFPawn_Human KFP;
	
	KFP = KFPawn_Human(Killed);
	
	if (Role >= ROLE_Authority && KFP != None && KFP.InvManager != none)
		foreach KFP.InvManager.InventoryActors(class'KFWeapon', TempWeapon)
			if (TempWeapon != none && TempWeapon.bDropOnDeath && TempWeapon.CanThrow())
				KFP.TossInventory(TempWeapon);

	return Super.PreventDeath(Killed, Killer, damageType, HitLocation);
}

function AddMskGsMember(Controller C)
{
	MskGsMemberList.AddItem(C);
	if (bXpNotifications)
	{
		if (MskGsMemberList.Length >= 10)
		{
			if (C.PlayerReplicationInfo != NONE)
				WorldInfo.Game.Broadcast(C, C.PlayerReplicationInfo.PlayerName$" gives a boost to this server! XP bonus: +100% (MAX!)");
			else
				WorldInfo.Game.Broadcast(C, "XP bonus: +100% (MAX!)");
		}
		else
		{
			if (C.PlayerReplicationInfo != NONE)
				WorldInfo.Game.Broadcast(C, C.PlayerReplicationInfo.PlayerName$" gives a boost to this server! XP bonus: +"$string(MskGsMemberList.Length * 10)$"%");
			else
				WorldInfo.Game.Broadcast(C, "XP bonus: +"$string(MskGsMemberList.Length * 10)$"%");
		}
	}
	MyKFGI.UpdateGameSettings();
}

function NotifyLogin(Controller C)
{
	local MskGsRepInfo RepInfo;
	
	if (C == None) return;
	
	Initialize();
	
	`log("NotifyLogin:" @ C);
	
	RepInfo = Spawn(class'MskGsRepInfo', KFPlayerController(C));
	RepInfo.C = C;
	RepInfo.Mut = Self;
	RepClients.AddItem(RepInfo);
	
	if (AdminUIDList.Find('Uid', C.PlayerReplicationInfo.UniqueId.Uid) != -1)
		C.PlayerReplicationInfo.bAdmin = true;
	
    super.NotifyLogin(C);
}

function NotifyLogout(Controller C)
{
	local MskGsVoteCollector VoteCollector;
	local int i;
	
	if (C == None) return;
	
	Initialize();
	
	VoteCollector = MskGsVoteCollector(MyKFGI.MyKFGRI.VoteCollector);
    VoteCollector.NotifyLogout(C);
	
	if (MskGsMemberList.Find(C) != INDEX_NONE)
	{
		MskGsMemberList.RemoveItem(C);
		if (bXpNotifications)
		{
			if (MskGsMemberList.Length >= 10)
			{
				if (C.PlayerReplicationInfo != NONE)
					WorldInfo.Game.Broadcast(C, C.PlayerReplicationInfo.PlayerName$" left the game. XP bonus: +100% (MAX!)");
				else
					WorldInfo.Game.Broadcast(C, "XP bonus: +100% (MAX!)");
			}
			else if (MskGsMemberList.Length > 0)
			{
				if (C.PlayerReplicationInfo != NONE)
					WorldInfo.Game.Broadcast(C, C.PlayerReplicationInfo.PlayerName$" left the game. XP bonus: +"$string(MskGsMemberList.Length * 10)$"%");
				else
					WorldInfo.Game.Broadcast(C, "XP bonus: +"$string(MskGsMemberList.Length * 10)$"%");
			}
			else
			{
				if (C.PlayerReplicationInfo != NONE)
					WorldInfo.Game.Broadcast(C, C.PlayerReplicationInfo.PlayerName$" left the game. No XP bonus now.");
				else
					WorldInfo.Game.Broadcast(C, "No XP bonus now.");
			}
		}
		MyKFGI.UpdateGameSettings();
	}

	for (i = RepClients.Length - 1; i >= 0; i--)
	{
		if (RepClients[i].C == C)
		{
			RepClients[i].Destroy();
			RepClients.Remove(i, 1);
		}
	}
	
    super.NotifyLogout(C);
}

defaultproperties
{
	bInitialized=false
}
