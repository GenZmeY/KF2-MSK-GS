Class MskGsMut extends KFMutator
	config(MskGs);

var const int SteamIDLen;
var const int UniqueIDLen;

var config array<string> ImportantPersonList;

simulated event PostBeginPlay()
{
    super.PostBeginPlay();

	if (WorldInfo.Game.BaseMutator == None)
		WorldInfo.Game.BaseMutator = Self;
	else
		WorldInfo.Game.BaseMutator.AddMutator(Self);
	
	if (bDeleteMe)
		return;
	
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
		SetTimer(2.f, false, nameof(Initialize));
		return;
	}

	MyKFGI.KFGFxManagerClass = class'MskGsGFxMoviePlayer_Manager';
	MyKFGI.MyKFGRI.VoteCollectorClass = class'MskGsVoteCollector';
	MyKFGI.MyKFGRI.PostBeginPlay();
	
	steamworks = class'GameEngine'.static.GetOnlineSubsystem();
	VoteCollector = MskGsVoteCollector(MyKFGI.MyKFGRI.VoteCollector);
	
	if (VoteCollector == None)
	{
		`Log("[MskGsMut] ERROR: VoteCollector is None!");
		return;
	}
	
	foreach ImportantPersonList(Person)
	{
		if (Len(Person) == UniqueIDLen && steamworks.StringToUniqueNetId(Person, PersonUID))
		{
			if (VoteCollector.ImportantPersonList.Find('Uid', PersonUID.Uid) == -1)
				VoteCollector.ImportantPersonList.AddItem(PersonUID);
		}
		else if (Len(Person) == SteamIDLen && steamworks.Int64ToUniqueNetId(Person, PersonUID))
		{
			if (VoteCollector.ImportantPersonList.Find('Uid', PersonUID.Uid) == -1)
				VoteCollector.ImportantPersonList.AddItem(PersonUID);
		}
		else `Log("[MskGsMut] WARN: Can't add person:"@Person);
	}

	`Log("[MskGsMut] Mutator loaded.");
}

function AddMutator(Mutator Mut)
{
	if (Mut == Self)
		return;
	
	if (Mut.Class == Class)
		Mut.Destroy();
	else
		Super.AddMutator(Mut);
}

defaultproperties
{
	SteamIDLen=17
	UniqueIDLen=18
}
