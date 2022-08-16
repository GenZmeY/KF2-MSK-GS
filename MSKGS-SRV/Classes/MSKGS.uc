class MSKGS extends Info
	implements(IMSKGS)
	config(MSKGS);

const LatestVersion = 1;

const CfgCredits      = class'CfgCredits';
const CfgLifespan     = class'CfgLifespan';
const CfgSpawnManager = class'CfgSpawnManager';
const CfgXPBoost      = class'CfgXPBoost';
const CfgSrvRank      = class'CfgSrvRank';

const MSKGS_GameInfo  = class'MSKGS_GameInfo';

struct ZedMap
{
	var const class<KFPawn_Monster> Zed;
	var const class<KFPawn_Monster> Proxy;
};

struct BoostMap
{
	var const int BoostValue;
	var const Array<ZedMap> Zeds;
};

var private Array<BoostMap> XPBoosts;
var private Array<ZedMap>   ZedProxies;

var private int  XPBoost;
var private bool XPNotifications;

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
	
	CfgCredits.static.InitConfig(Version, LatestVersion, LogLevel);
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
	
	CfgCredits.static.Load(LogLevel);
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
	
	OwnerID = CfgCredits.static.LoadOwnerID(OS, LogLevel);
	GroupID = CfgCredits.static.LoadGroupID(OS, LogLevel);
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
		MSKGS_GM_Endless(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_GM_Endless(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_Objective(KFGI) != None)
	{
		XPNotifications = (KFGI.GameDifficulty != 3);
		MSKGS_GM_Objective(KFGI).MSKGS    = Self;
		MSKGS_GM_Objective(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_GM_Objective(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_Survival(KFGI) != None)
	{
		XPNotifications = (KFGI.GameDifficulty != 3);
		MSKGS_GM_Survival(KFGI).MSKGS    = Self;
		MSKGS_GM_Survival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_GM_Survival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_VersusSurvival(KFGI) != None)
	{
		XPNotifications = false;
		MSKGS_GM_VersusSurvival(KFGI).MSKGS    = Self;
		MSKGS_GM_VersusSurvival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_GM_VersusSurvival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_GM_WeeklySurvival(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_GM_WeeklySurvival(KFGI).MSKGS    = Self;
		MSKGS_GM_WeeklySurvival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_GM_WeeklySurvival(KFGI).LogLevel = LogLevel;
	}
	
	`Log_Info("GameInfo initialized:" @ KFGI);
	
	KFGI.UpdateGameSettings();
	
	ModifySpawnManager();
	
	`Log_Info("Initialized");
}

private function ModifySpawnManager()
{
	local byte Difficulty, Players;
	
	`Log_Trace();
	
	if (KFGI.SpawnManager == None)
	{
		SetTimer(1.f, false, nameof(ModifySpawnManager));
		return;
	}
	
	for (Difficulty = 0; Difficulty < KFGI.SpawnManager.PerDifficultyMaxMonsters.Length; Difficulty++)
	{
		for (Players = 0; Players < KFGI.SpawnManager.PerDifficultyMaxMonsters[Difficulty].MaxMonsters.Length; Players++)
		{
			KFGI.SpawnManager.PerDifficultyMaxMonsters[Difficulty].MaxMonsters[Players] = CfgSpawnManager.default.PerPlayerMaxMonsters[Players];
		}
	}
	
	`Log_Info("SpawnManager modified");
}

public function class<KFPawn_Monster> PickProxyZed(class<KFPawn_Monster> MonsterClass)
{
	local int Index;
	
	Index = ZedProxies.Find('Zed', MonsterClass);
	if (Index == INDEX_NONE)
	{
		`Log_Error("Can't find proxy for zed:" @ String(MonsterClass));
		return MonsterClass;
	}
	
	`Log_Debug("Proxy Zed:" @ ZedProxies[Index].Proxy);
	
	return ZedProxies[Index].Proxy;
}

public function int GetXPBoost()
{
	return XPBoost;
}

public function bool GetXPNotifications()
{
	return XPNotifications;
}

public function E_LogLevel GetLogLevel()
{
	return LogLevel;
}

public function ModifyLifespan(Actor A)
{
	`Log_Trace();
	
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
	`Log_Trace();
	
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
		`Log_Error("Can't create RepInfo for:" @ C @ (C == None ? "" : String(C.PlayerReplicationInfo)));
	}
}

public function NotifyLogout(Controller C)
{
	`Log_Trace();
	
	if (PlayerXPBoost(FindRepInfo(C)) > 0)
	{
		DecreaseXPBoost(C);
	}

	if (!DestroyRepInfo(C))
	{
		`Log_Error("Can't destroy RepInfo of:" @ C);
	}
}

public function bool CreateRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	if (C == None || C.PlayerReplicationInfo == None) return false;
	
	RepInfo = Spawn(class'MSKGS_RepInfo', C);
	
	if (RepInfo == None) return false;
	
	RepInfo.Init(
		LogLevel,
		Self,
		GroupID,
		CfgXPBoost.default.CheckGroupTimer,
		C.PlayerReplicationInfo.UniqueId == OwnerID);
		
	RepInfos.AddItem(RepInfo);
	
	return true;
}

public function bool DestroyRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	if (C == None) return false;
	
	RepInfo = FindRepInfo(C);
	if (RepInfo != None)
	{
		RepInfo.SafeDestroy();
		RepInfos.RemoveItem(RepInfo);
		return true;
	}
	
	return false;
}

public function IncreaseXPBoost(KFPlayerController Booster)
{
	local MSKGS_RepInfo BoosterRepInfo;
	local String HexColor;
	local int    PlayerBoost;
	local String PlayerBoostStr;
	local String TotalBoostStr;
	local String BoosterName;
	
	`Log_Trace();
	
	UpdateXPBoost();
	KFGI.UpdateGameSettings();
	
	BoosterRepInfo = FindRepInfo(Booster);
	TotalBoostStr  = String(XPBoost);
	BoosterName    = Booster.PlayerReplicationInfo.PlayerName;
	HexColor       = PlayerHexColor(BoosterRepInfo);
	PlayerBoost    = PlayerXPBoost(BoosterRepInfo);
	PlayerBoostStr = String(PlayerBoost);
	
	if (XPBoost >= CfgXPBoost.default.MaxBoost)
	{
		BroadcastChatLocalized(
			MSKGS_PlayerGiveBoostToServerMax,
			HexColor,
			None,
			BoosterName,
			PlayerBoostStr,
			String(CfgXPBoost.default.MaxBoost));
	}
	else if (PlayerBoost == XPBoost)
	{
		BroadcastChatLocalized(
			MSKGS_PlayerGiveBoostToServerFirst,
			HexColor,
			None,
			BoosterName,
			TotalBoostStr);
	}
	else
	{
		BroadcastChatLocalized(
			MSKGS_PlayerGiveBoostToServer,
			HexColor,
			None,
			BoosterName,
			PlayerBoostStr,
			TotalBoostStr);
	}
}

public function DecreaseXPBoost(Controller Booster)
{
	local String HexColor;
	local String TotalBoost;
	local String BoosterName;
	
	`Log_Trace();
	
	UpdateXPBoost();
	KFGI.UpdateGameSettings();
	
	HexColor    = CfgXPBoost.default.HexColorLeave;
	BoosterName = Booster.PlayerReplicationInfo.PlayerName;
	TotalBoost  = String(XPBoost);
	
	if (XPBoost >= CfgXPBoost.default.MaxBoost)
	{
		BroadcastChatLocalized(
			MSKGS_BoosterLeaveServerMax,
			HexColor,
			Booster,
			BoosterName,
			String(CfgXPBoost.default.MaxBoost));
	}
	else if (XPBoost > 0)
	{
		BroadcastChatLocalized(
			MSKGS_BoosterLeaveServer,
			HexColor,
			Booster,
			BoosterName,
			TotalBoost);
	}
	else
	{
		BroadcastChatLocalized(
			MSKGS_BoosterLeaveServerNoBoost,
			HexColor,
			Booster,
			BoosterName);
	}
}

private function BroadcastChatLocalized(E_MSKGS_LocalMessageType LMT, String HexColor, optional Controller Except = None, optional String String1, optional String String2, optional String String3)
{
	local MSKGS_RepInfo RepInfo;
	
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner != Except)
		{
			RepInfo.WriteToChatLocalized(
				LMT,
				HexColor,
				String1,
				String2,
				String3);
		}
	}
}

private function MSKGS_RepInfo FindRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	foreach RepInfos(RepInfo)
		if (RepInfo.Owner == C)
			break;
	
	return RepInfo;
}

public function UpdateXPBoost()
{
	local MSKGS_RepInfo RepInfo;
	local int NextBoost;
	local int Index;
	
	`Log_Trace();
	
	NextBoost = 0;
	foreach RepInfos(RepInfo)
	{
		NextBoost += PlayerXPBoost(RepInfo);
	}
	
	if (NextBoost > 0)
	{
		Index = XPBoosts.Find('BoostValue', NextBoost);
		if (Index == INDEX_NONE)
		{
			`Log_Error("Can't find boost proxy:" @ NextBoost);
		}
		else
		{
			ZedProxies = XPBoosts[Index].Zeds;
		}
	}
	
	XPBoost = NextBoost;
}

private function int PlayerXPBoost(MSKGS_RepInfo RepInfo)
{
	`Log_Trace();
	
	if (RepInfo != None) switch (RepInfo.PlayerType())
	{
		case MSKGS_Owner: return CfgXPBoost.default.BoostOwner;
		case MSKGS_Admin: return CfgXPBoost.default.BoostAdmin;
		case MSKGS_Group: return CfgXPBoost.default.BoostGroup;
	}
	
	return CfgXPBoost.default.BoostPlayer;
}

private function String PlayerHexColor(MSKGS_RepInfo RepInfo)
{
	`Log_Trace();
	
	switch (RepInfo.PlayerType())
	{
		case MSKGS_Owner: return CfgXPBoost.default.HexColorOwner;
		case MSKGS_Admin: return CfgXPBoost.default.HexColorAdmin;
		case MSKGS_Group: return CfgXPBoost.default.HexColorGroup;
	}
	
	return CfgXPBoost.default.HexColorPlayer;
}

DefaultProperties
{
	XPBoosts.Add({(
		BoostValue=10,
		Zeds[0]={(Zed=class'KFPawn_ZedBloat',Proxy=class'KFPawn_ZedBloat')},
		Zeds[1]={(Zed=class'KFPawn_ZedBloat',Proxy=class'KFPawn_ZedBloat')}
	)})
	XPBoosts.Add({(
		BoostValue=10,
		Zeds[0]={(Zed=class'KFPawn_ZedBloat',Proxy=class'KFPawn_ZedBloat')},
		Zeds[1]={(Zed=class'KFPawn_ZedBloat',Proxy=class'KFPawn_ZedBloat')}
	)})
}