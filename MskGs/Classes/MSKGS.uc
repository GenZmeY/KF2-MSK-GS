class MSKGS extends Info
	config(MSKGS);

const LatestVersion = 1;

const CfgLifespan     = class'CfgLifespan';
const CfgSpawnManager = class'CfgSpawnManager';
const CfgXPBoost      = class'CfgXPBoost';
const CfgSrvRank      = class'CfgSrvRank';

var public  int  XPBoost;
var public  bool XPNotifications;

var private config int        Version;
var private config E_LogLevel LogLevel;

var private OnlineSubsystem       OS;
var private KFGameInfo            KFGI;
var private KFGameReplicationInfo KFGRI;

var private Array<MSKGS_RepInfo> RepInfos;

var private UniqueNetId OwnerID;
var private UniqueNetId GroupID;

public simulated function bool SafeDestroy()
{
	`Log_Trace();
	
	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	`Log_Trace();
	
	if (WorldInfo.NetMode == NM_Client)
	{
		`Log_Fatal("NetMode:" @ WorldInfo.NetMode);
		SafeDestroy();
		return;
	}
	
	Super.PreBeginPlay();
	
	PreInit();
}

public event PostBeginPlay()
{
	`Log_Trace();
	
	if (bPendingDelete || bDeleteMe) return;
	
	Super.PostBeginPlay();
	
	PostInit();
}

private function PreInit()
{
	`Log_Trace();
	
	if (Version == `NO_CONFIG)
	{
		LogLevel = LL_Info;
		SaveConfig();
	}
	
	CfgLifespan.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgSpawnManager.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgXPBoost.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgSrvRank.static.InitConfig(Version, LatestVersion, LogLevel);

	switch (Version)
	{
		case `NO_CONFIG:
			`Log_Info("Config created");
			
		case MaxInt:
			`Log_Info("Config updated to version" @ LatestVersion);
			break;
			
		case LatestVersion:
			`Log_Info("Config is up-to-date");
			break;
			
		default:
			`Log_Warn("The config version is higher than the current version (are you using an old mutator?)");
			`Log_Warn("Config version is" @ Version @ "but current version is" @ LatestVersion);
			`Log_Warn("The config version will be changed to" @ LatestVersion);
			break;
	}
	
	if (LatestVersion != Version)
	{
		Version = LatestVersion;
		SaveConfig();
	}

	if (LogLevel == LL_WrongLevel)
	{
		LogLevel = LL_Info;
		`Log_Warn("Wrong 'LogLevel', return to default value");
		SaveConfig();
	}
	`Log_Base("LogLevel:" @ LogLevel);
	
	CfgLifespan.static.Load(LogLevel);
	CfgSpawnManager.static.Load(LogLevel);
	CfgXPBoost.static.Load(LogLevel);
	CfgSrvRank.static.Load(LogLevel);
	
	OS = class'GameEngine'.static.GetOnlineSubsystem();
	if (OS == None)
	{
		`Log_Fatal("Can't get online subsystem!");
		SafeDestroy();
		return;
	}
	
	OwnerID = CfgXPBoost.static.LoadOwnerID(OS, LogLevel);
	GroupID = CfgXPBoost.static.LoadGroupID(OS, LogLevel);
}

private function PostInit()
{
	`Log_Trace();
	
	if (WorldInfo == None || WorldInfo.Game == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}
	
	KFGI = KFGameInfo(WorldInfo.Game);
	if (KFGI == None)
	{
		`Log_Fatal("Incompatible gamemode:" @ WorldInfo.Game);
		SafeDestroy();
		return;
	}
	
	if (KFGI.GameReplicationInfo == None)
	{
		SetTimer(1.0f, false, nameof(PostInit));
		return;
	}
	
	KFGRI = KFGameReplicationInfo(KFGI.GameReplicationInfo);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ KFGI.GameReplicationInfo);
		SafeDestroy();
		return;
	}
	
	if (MSKGS_GM_Endless(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_GM_Endless(KFGI).MSKGS    = Self;
		MSKGS_GM_Endless(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_Objective(KFGI) != None)
	{
		XPNotifications = (KFGI.GameDifficulty != 3);
		MSKGS_GM_Objective(KFGI).MSKGS    = Self;
		MSKGS_GM_Objective(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_Survival(KFGI) != None)
	{
		XPNotifications = (KFGI.GameDifficulty != 3);
		MSKGS_GM_Survival(KFGI).MSKGS    = Self;
		MSKGS_GM_Survival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_VersusSurvival(KFGI) != None)
	{
		XPNotifications = false;
		MSKGS_GM_VersusSurvival(KFGI).MSKGS    = Self;
		MSKGS_GM_VersusSurvival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_WeeklySurvival(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_GM_WeeklySurvival(KFGI).MSKGS    = Self;
		MSKGS_GM_WeeklySurvival(KFGI).LogLevel = LogLevel;
	}
	
	ModifySpawnManager();
}

private function ModifySpawnManager()
{
	local byte Difficulty, Players;
	
	if (KFGI.SpawnManager == None)
	{
		SetTimer(1.f, false, nameof(ModifySpawnManager));
		return;
	}
	
	for (Difficulty = 0; Difficulty < KFGI.SpawnManager.PerDifficultyMaxMonsters.Length; Difficulty++)
	{
		for (Players = 0; Players < KFGI.SpawnManager.PerDifficultyMaxMonsters[Difficulty].MaxMonsters.Length; Players++)
		{
			KFGI.SpawnManager.PerDifficultyMaxMonsters[Difficulty].MaxMonsters[Players] = CfgSpawnManager.default.MaxMonsters[Players];
		}
	}
}

public function ModifyLifespan(Actor A)
{
	if (KFDroppedPickup_Cash(A) != None)
	{
		if (CfgLifespan.default.Dosh != 0)
		{
			A.Lifespan = float(CfgLifespan.default.Dosh);
		}
	}
	else if (KFDroppedPickup(A) != None)
	{
		if (CfgLifespan.default.Weap != 0)
		{
			A.Lifespan = float(CfgLifespan.default.Weap);
		}
	}
}

public function SetMaxPlayers(int MaxPlayers)
{
	if (MaxPlayers != INDEX_NONE)
	{
		KFGI.MaxPlayers        = MaxPlayers;
		KFGI.MaxPlayersAllowed = MaxPlayers;
	}
}

public function NotifyLogin(Controller C)
{
	`Log_Trace();

	if (!CreateRepInfo(C))
	{
		`Log_Error("Can't create RepInfo for:" @ C);
	}
}

public function NotifyLogout(Controller C)
{
	`Log_Trace();

	if (!DestroyRepInfo(C))
	{
		`Log_Error("Can't destroy RepInfo of:" @ C);
	}
}

public function bool CreateRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	if (C == None) return false;
	
	RepInfo = Spawn(class'MSKGS_RepInfo', C);
	
	if (RepInfo == None) return false;
	
	RepInfo.LogLevel    = LogLevel;
	RepInfo.MSKGS       = Self;
	RepInfo.GroupID     = GroupID;
	RepInfo.ServerOwner = false;
	
	RepInfos.AddItem(RepInfo);
	
	return true;
}

public function bool DestroyRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	if (C == None) return false;
	
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner == C)
		{
			RepInfo.SafeDestroy();
			RepInfos.RemoveItem(RepInfo);
			return true;
		}
	}
	
	return false;
}

public function IncreaseXPBoost(KFPlayerController Booster)
{
	local MSKGS_RepInfo RepInfo;
	
	UpdateXPBoost();
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner == Booster)
		{
			// TODO: Recive localized message
			// You give boost to this server
		}
		else
		{
			// TODO: Recive localized message
			// Booster give boost to this server
		}
	}
	
	KFGI.UpdateGameSettings();
}

public function DecreaseXPBoost(KFPlayerController Booster)
{
	local MSKGS_RepInfo RepInfo;
	
	UpdateXPBoost();
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner != Booster)
		{
			// TODO: Recive localized message
			// Booster left the game
		}
	}
	
	KFGI.UpdateGameSettings();
}

public function UpdateXPBoost()
{
	local MSKGS_RepInfo RepInfo;
	local int NextBoost;
	
	NextBoost = 0;
	foreach RepInfos(RepInfo)
	{
		NextBoost += RepInfo.XPBoost();
	}
	
	XPBoost = NextBoost;
}

/*
function AddMskGsMember(Controller C)
{
	MskGsMemberList.AddItem(C);
	if (XpNotifications)
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

function DelMskGsMember(Controller C)
{
	Initialize();
	
	if (MskGsMemberList.Find(C) != INDEX_NONE)
	{
		MskGsMemberList.RemoveItem(C);
		if (XpNotifications)
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
}
*/

DefaultProperties
{

}