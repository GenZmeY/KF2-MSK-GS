Class MskGsMut extends KFMutator
	config(MskGs);

const CurrentVersion = 3;
var config int ConfigVersion;

var config bool bEnableMapStats;
var config string SortStats;
var config bool bOfficialNextMapOnly;
var config bool bRandomizeNextMap;
var config int WeapDespawnTime;
var config int DoshDespawnTime;

var config array<string> KickProtectedList;
var config array<int> PerPlayerMaxMonsters;

function InitMutator(string Options, out string ErrorMessage)
{
	local int MaxPlayers, MaxPlayersAllowed;

	super.InitMutator(Options, ErrorMessage);

	if (MyKFGI == none)
	{
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
			WeapDespawnTime = 2147483647;
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
			if (DoshDespawnTime == 0)
			{
				DoshDespawnTime = 60 * 5;
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

	if (WorldInfo.Game.BaseMutator == None)
		WorldInfo.Game.BaseMutator = Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator(Self);
	
	if (bDeleteMe) return;
	
	Initialize();
}

function Initialize()
{
	local MskGsVoteCollector VoteCollector;
	local OnlineSubsystem steamworks;
	local string Person;
	local UniqueNetId PersonUID;
	
	if (MyKFGI == None || MyKFGI.MyKFGRI == None)
	{
		SetTimer(1.f, false, nameof(Initialize));
		return;
	}

	InitConfig();

	MyKFGI.KFGFxManagerClass = class'MskGsGFxMoviePlayer_Manager';
	MyKFGI.MyKFGRI.VoteCollectorClass = class'MskGsVoteCollector';
	MyKFGI.MyKFGRI.VoteCollector = new(MyKFGI.MyKFGRI) MyKFGI.MyKFGRI.VoteCollectorClass;
	
	VoteCollector = MskGsVoteCollector(MyKFGI.MyKFGRI.VoteCollector);
	VoteCollector.bEnableMapStats = bEnableMapStats;
	VoteCollector.bOfficialNextMapOnly = bOfficialNextMapOnly;
	VoteCollector.bRandomizeNextMap = bRandomizeNextMap;
	VoteCollector.SortPolicy = SortStats;
	
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
	local KFDroppedPickup DroppedPickup;

	SuperRelevant = super.CheckRelevance(Other);

	// if this actor is going to be destroyed, return now
	if (!SuperRelevant)
	{
		return SuperRelevant;
	}

	DroppedPickup = KFDroppedPickup(Other);

	// otherwise modify weapon lifespan
	if (DroppedPickup != None)
	{
		if (KFDroppedPickup_Cash(DroppedPickup) != None)
			DroppedPickup.Lifespan = DoshDespawnTime;
		else
			DroppedPickup.Lifespan = WeapDespawnTime;
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

function NotifyLogin(Controller NewPlayer)
{
    super.NotifyLogin(NewPlayer);
}

function NotifyLogout(Controller Exiting)
{
	local MskGsVoteCollector VoteCollector;
	
	VoteCollector = MskGsVoteCollector(MyKFGI.MyKFGRI.VoteCollector);
	
    VoteCollector.NotifyLogout(Exiting);

    super.NotifyLogout(Exiting);
}

defaultproperties
{
	
}
