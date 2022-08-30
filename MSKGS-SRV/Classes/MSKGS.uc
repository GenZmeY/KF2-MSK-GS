class MSKGS extends Info
	implements(IMSKGS)
	config(MSKGS);

const LatestVersion = 1;

const CfgCredits      = class'CfgCredits';
const CfgLifespan     = class'CfgLifespan';
const CfgSpawnManager = class'CfgSpawnManager';
const CfgXPBoost      = class'CfgXPBoost';
const CfgSrvRank      = class'CfgSrvRank';

const CfgPerks        = class'CfgPerks';
const CfgLevels       = class'CfgLevels';

const MSKGS_GameInfo  = class'MSKGS_GameInfo';

struct ZedMap
{
	var const Name                  ZedName;
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
	CfgPerks.static.InitConfig(Version, LatestVersion, LogLevel);
	CfgLevels.static.InitConfig(Version, LatestVersion, LogLevel);
	
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
	
	CfgLevels.static.Load(LogLevel);
	
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
	
	WorldInfo.Game.PlayerControllerClass = class'MSKGS_PlayerController';
	
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
	
	XPNotifications = false;
	if (MSKGS_Endless(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_Endless(KFGI).MSKGS    = Self;
		MSKGS_Endless(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_Endless(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_Objective(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_Objective(KFGI).MSKGS    = Self;
		MSKGS_Objective(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_Objective(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_Survival(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_Survival(KFGI).MSKGS    = Self;
		MSKGS_Survival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_Survival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_VersusSurvival(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_VersusSurvival(KFGI).MSKGS    = Self;
		MSKGS_VersusSurvival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_VersusSurvival(KFGI).LogLevel = LogLevel;
	}
	else if (MSKGS_WeeklySurvival(KFGI) != None)
	{
		XPNotifications = true;
		MSKGS_WeeklySurvival(KFGI).MSKGS    = Self;
		MSKGS_WeeklySurvival(KFGI).GI       = new MSKGS_GameInfo;
		MSKGS_WeeklySurvival(KFGI).LogLevel = LogLevel;
	}
	
	KFGI.UpdateGameSettings();
	
	`Log_Info("GameInfo initialized:" @ KFGI);
	
	KFGRI = KFGameReplicationInfo(KFGI.GameReplicationInfo);
	if (KFGRI == None)
	{
		`Log_Fatal("Incompatible Replication info:" @ KFGI.GameReplicationInfo);
		SafeDestroy();
		return;
	}
	
	KFGRI.PerksAvailableData = CfgPerks.static.Load(LogLevel);
	
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
	
	if (XPBoost > 0)
	{
		Index = ZedProxies.Find('ZedName', MonsterClass.Name);
		if (Index == INDEX_NONE)
		{
			`Log_Error("Can't find proxy for zed:" @ String(MonsterClass));
			return MonsterClass;
		}
		
		`Log_Debug("Proxy Zed:" @ ZedProxies[Index].Proxy);
		return ZedProxies[Index].Proxy;
	}
	
	`Log_Debug("(Not) Proxy Zed:" @ MonsterClass);
	return MonsterClass;
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
	local MSKGS_PlayerController MSKGSPC;
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	MSKGSPC = MSKGS_PlayerController(C);
	
	if (MSKGSPC == None)
	{
		`Log_Error("Can't cast" @ C @ "to MSKGS_PlayerController");
		return;
	}
	
	if (CfgPerks.default.bHideDisabledPerks)
	{
		MSKGSPC.ServerHidePerks();
	}

	RepInfo = CreateRepInfo(C);
	if (RepInfo == None)
	{
		`Log_Error("Can't create RepInfo for:" @ C @ (C == None ? "" : String(C.PlayerReplicationInfo)));
		return;
	}
	
	MSKGSPC.RepInfo         = RepInfo;
	MSKGSPC.MinLevel        = CfgLevels.static.MinLevel();
	MSKGSPC.MaxLevel        = CfgLevels.static.MaxLevel();
	MSKGSPC.DisconnectTimer = CfgLevels.default.DisconnectTime;
	
	if (RepInfo.PlayerType() >= MSKGS_Admin)
	{
		`Log_Info("Increase boost:" @ RepInfo.PlayerType());
		IncreaseXPBoost(RepInfo.GetKFPC());
	}
	
	if (CfgLevels.static.MinLevel() != 0 || CfgLevels.static.MaxLevel() != `MAX_PERK_LEVEL)
	{
		RepInfo.WriteToChatLocalized(
			MSKGS_AllowedLevels,
			CfgLevels.default.HexColorInfo,
			String(CfgLevels.static.MinLevel()),
			String(CfgLevels.static.MaxLevel()));
	}
}

public function NotifyLogout(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	RepInfo = FindRepInfo(C);
	if (RepInfo == None)
	{
		`Log_Error("Can't find RepInfo for:" @ C);
		return;
	}
	
	if (PlayerXPBoost(RepInfo) > 0)
	{
		`Log_Info("Decrease boost:" @ RepInfo.PlayerType());
		DecreaseXPBoost(C);
	}

	if (!DestroyRepInfo(RepInfo))
	{
		`Log_Error("Can't destroy RepInfo:" @ RepInfo @ C);
	}
}

public function MSKGS_RepInfo CreateRepInfo(Controller C)
{
	local MSKGS_RepInfo RepInfo;
	
	`Log_Trace();
	
	if (C == None || C.PlayerReplicationInfo == None) return None;
	
	RepInfo = Spawn(class'MSKGS_RepInfo', C);
	
	if (RepInfo == None) return None;
	
	RepInfo.Init(
		LogLevel,
		Self,
		GroupID,
		CfgXPBoost.default.CheckGroupTimer,
		CfgXPBoost.default.MaxRetries,
		C.PlayerReplicationInfo.UniqueId == OwnerID);
		
	RepInfos.AddItem(RepInfo);
	
	return RepInfo;
}

public function bool DestroyRepInfo(MSKGS_RepInfo RepInfo)
{
	`Log_Trace();
	
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
	
	if (XPNotifications)
	{
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
}

public function DecreaseXPBoost(Controller Booster)
{
	local String HexColor;
	local String TotalBoost;
	local String BoosterName;
	
	`Log_Trace();
	
	UpdateXPBoost(Booster);
	KFGI.UpdateGameSettings();
	
	HexColor    = CfgXPBoost.default.HexColorLeave;
	BoosterName = Booster.PlayerReplicationInfo.PlayerName;
	TotalBoost  = String(XPBoost);
	
	if (XPNotifications)
	{
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

public function UpdateXPBoost(optional Controller Except = None)
{
	local MSKGS_RepInfo RepInfo;
	local int NextBoost;
	local int Index;
	
	`Log_Trace();
	
	NextBoost = 0;
	foreach RepInfos(RepInfo)
	{
		if (RepInfo.Owner != Except)
		{
			NextBoost += PlayerXPBoost(RepInfo);
		}
	}
	
	ZedProxies.Length = 0;
	NextBoost = Clamp(NextBoost, 0, CfgXPBoost.default.MaxBoost);
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
	
	`Log_Debug("PlayerType:" @ RepInfo.PlayerType());
	
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

defaultproperties
{
	XPBoosts.Add({(
		BoostValue=10,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_010')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_010')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_010')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_010')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_010')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_010')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_010')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_010')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_010')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_010')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_010')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_010')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_010')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_010')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_010')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_010')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_010')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_010')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_010')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_010')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_010')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_010')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_010')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_010')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_010')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_010')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_010')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_010')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_010')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_010')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_010')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_010')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_010')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_010')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_010')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_010')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_010')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_010')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_010')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_010')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_010')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_010')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_010')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_010')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_010')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_010')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_010')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_010')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_010')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_010')}
	)})
	XPBoosts.Add({(
		BoostValue=20,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_020')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_020')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_020')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_020')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_020')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_020')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_020')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_020')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_020')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_020')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_020')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_020')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_020')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_020')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_020')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_020')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_020')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_020')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_020')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_020')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_020')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_020')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_020')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_020')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_020')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_020')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_020')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_020')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_020')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_020')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_020')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_020')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_020')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_020')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_020')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_020')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_020')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_020')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_020')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_020')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_020')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_020')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_020')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_020')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_020')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_020')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_020')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_020')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_020')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_020')}
	)})
	XPBoosts.Add({(
		BoostValue=30,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_030')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_030')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_030')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_030')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_030')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_030')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_030')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_030')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_030')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_030')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_030')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_030')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_030')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_030')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_030')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_030')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_030')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_030')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_030')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_030')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_030')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_030')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_030')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_030')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_030')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_030')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_030')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_030')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_030')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_030')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_030')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_030')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_030')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_030')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_030')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_030')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_030')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_030')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_030')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_030')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_030')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_030')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_030')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_030')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_030')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_030')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_030')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_030')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_030')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_030')}
	)})
	XPBoosts.Add({(
		BoostValue=40,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_040')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_040')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_040')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_040')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_040')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_040')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_040')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_040')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_040')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_040')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_040')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_040')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_040')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_040')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_040')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_040')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_040')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_040')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_040')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_040')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_040')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_040')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_040')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_040')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_040')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_040')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_040')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_040')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_040')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_040')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_040')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_040')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_040')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_040')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_040')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_040')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_040')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_040')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_040')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_040')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_040')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_040')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_040')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_040')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_040')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_040')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_040')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_040')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_040')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_040')}
	)})
	XPBoosts.Add({(
		BoostValue=50,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_050')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_050')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_050')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_050')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_050')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_050')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_050')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_050')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_050')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_050')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_050')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_050')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_050')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_050')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_050')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_050')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_050')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_050')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_050')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_050')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_050')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_050')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_050')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_050')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_050')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_050')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_050')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_050')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_050')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_050')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_050')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_050')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_050')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_050')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_050')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_050')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_050')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_050')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_050')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_050')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_050')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_050')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_050')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_050')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_050')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_050')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_050')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_050')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_050')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_050')}
	)})
	XPBoosts.Add({(
		BoostValue=60,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_060')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_060')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_060')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_060')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_060')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_060')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_060')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_060')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_060')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_060')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_060')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_060')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_060')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_060')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_060')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_060')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_060')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_060')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_060')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_060')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_060')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_060')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_060')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_060')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_060')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_060')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_060')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_060')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_060')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_060')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_060')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_060')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_060')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_060')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_060')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_060')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_060')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_060')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_060')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_060')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_060')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_060')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_060')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_060')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_060')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_060')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_060')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_060')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_060')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_060')}
	)})
	XPBoosts.Add({(
		BoostValue=70,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_070')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_070')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_070')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_070')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_070')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_070')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_070')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_070')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_070')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_070')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_070')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_070')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_070')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_070')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_070')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_070')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_070')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_070')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_070')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_070')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_070')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_070')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_070')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_070')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_070')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_070')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_070')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_070')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_070')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_070')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_070')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_070')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_070')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_070')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_070')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_070')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_070')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_070')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_070')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_070')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_070')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_070')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_070')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_070')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_070')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_070')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_070')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_070')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_070')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_070')}
	)})
	XPBoosts.Add({(
		BoostValue=80,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_080')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_080')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_080')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_080')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_080')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_080')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_080')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_080')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_080')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_080')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_080')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_080')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_080')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_080')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_080')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_080')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_080')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_080')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_080')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_080')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_080')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_080')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_080')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_080')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_080')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_080')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_080')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_080')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_080')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_080')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_080')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_080')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_080')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_080')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_080')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_080')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_080')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_080')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_080')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_080')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_080')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_080')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_080')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_080')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_080')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_080')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_080')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_080')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_080')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_080')}
	)})
	XPBoosts.Add({(
		BoostValue=90,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_090')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_090')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_090')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_090')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_090')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_090')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_090')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_090')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_090')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_090')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_090')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_090')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_090')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_090')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_090')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_090')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_090')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_090')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_090')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_090')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_090')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_090')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_090')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_090')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_090')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_090')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_090')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_090')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_090')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_090')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_090')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_090')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_090')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_090')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_090')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_090')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_090')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_090')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_090')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_090')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_090')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_090')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_090')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_090')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_090')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_090')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_090')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_090')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_090')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_090')}
	)})
	XPBoosts.Add({(
		BoostValue=100,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_100')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_100')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_100')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_100')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_100')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_100')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_100')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_100')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_100')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_100')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_100')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_100')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_100')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_100')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_100')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_100')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_100')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_100')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_100')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_100')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_100')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_100')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_100')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_100')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_100')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_100')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_100')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_100')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_100')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_100')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_100')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_100')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_100')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_100')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_100')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_100')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_100')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_100')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_100')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_100')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_100')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_100')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_100')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_100')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_100')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_100')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_100')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_100')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_100')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_100')}
	)})
	XPBoosts.Add({(
		BoostValue=110,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_110')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_110')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_110')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_110')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_110')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_110')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_110')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_110')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_110')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_110')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_110')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_110')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_110')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_110')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_110')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_110')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_110')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_110')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_110')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_110')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_110')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_110')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_110')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_110')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_110')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_110')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_110')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_110')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_110')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_110')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_110')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_110')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_110')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_110')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_110')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_110')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_110')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_110')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_110')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_110')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_110')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_110')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_110')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_110')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_110')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_110')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_110')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_110')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_110')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_110')}
	)})
	XPBoosts.Add({(
		BoostValue=120,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_120')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_120')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_120')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_120')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_120')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_120')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_120')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_120')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_120')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_120')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_120')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_120')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_120')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_120')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_120')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_120')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_120')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_120')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_120')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_120')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_120')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_120')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_120')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_120')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_120')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_120')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_120')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_120')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_120')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_120')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_120')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_120')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_120')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_120')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_120')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_120')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_120')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_120')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_120')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_120')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_120')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_120')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_120')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_120')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_120')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_120')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_120')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_120')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_120')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_120')}
	)})
	XPBoosts.Add({(
		BoostValue=130,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_130')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_130')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_130')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_130')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_130')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_130')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_130')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_130')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_130')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_130')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_130')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_130')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_130')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_130')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_130')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_130')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_130')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_130')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_130')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_130')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_130')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_130')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_130')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_130')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_130')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_130')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_130')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_130')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_130')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_130')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_130')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_130')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_130')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_130')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_130')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_130')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_130')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_130')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_130')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_130')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_130')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_130')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_130')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_130')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_130')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_130')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_130')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_130')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_130')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_130')}
	)})
	XPBoosts.Add({(
		BoostValue=140,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_140')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_140')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_140')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_140')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_140')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_140')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_140')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_140')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_140')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_140')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_140')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_140')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_140')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_140')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_140')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_140')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_140')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_140')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_140')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_140')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_140')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_140')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_140')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_140')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_140')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_140')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_140')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_140')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_140')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_140')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_140')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_140')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_140')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_140')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_140')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_140')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_140')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_140')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_140')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_140')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_140')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_140')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_140')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_140')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_140')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_140')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_140')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_140')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_140')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_140')}
	)})
	XPBoosts.Add({(
		BoostValue=150,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_150')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_150')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_150')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_150')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_150')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_150')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_150')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_150')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_150')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_150')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_150')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_150')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_150')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_150')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_150')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_150')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_150')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_150')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_150')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_150')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_150')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_150')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_150')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_150')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_150')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_150')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_150')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_150')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_150')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_150')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_150')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_150')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_150')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_150')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_150')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_150')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_150')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_150')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_150')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_150')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_150')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_150')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_150')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_150')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_150')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_150')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_150')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_150')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_150')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_150')}
	)})
	XPBoosts.Add({(
		BoostValue=160,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_160')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_160')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_160')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_160')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_160')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_160')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_160')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_160')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_160')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_160')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_160')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_160')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_160')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_160')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_160')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_160')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_160')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_160')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_160')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_160')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_160')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_160')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_160')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_160')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_160')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_160')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_160')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_160')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_160')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_160')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_160')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_160')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_160')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_160')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_160')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_160')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_160')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_160')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_160')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_160')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_160')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_160')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_160')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_160')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_160')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_160')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_160')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_160')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_160')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_160')}
	)})
	XPBoosts.Add({(
		BoostValue=170,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_170')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_170')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_170')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_170')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_170')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_170')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_170')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_170')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_170')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_170')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_170')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_170')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_170')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_170')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_170')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_170')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_170')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_170')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_170')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_170')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_170')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_170')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_170')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_170')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_170')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_170')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_170')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_170')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_170')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_170')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_170')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_170')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_170')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_170')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_170')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_170')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_170')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_170')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_170')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_170')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_170')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_170')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_170')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_170')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_170')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_170')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_170')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_170')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_170')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_170')}
	)})
	XPBoosts.Add({(
		BoostValue=180,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_180')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_180')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_180')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_180')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_180')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_180')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_180')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_180')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_180')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_180')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_180')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_180')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_180')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_180')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_180')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_180')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_180')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_180')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_180')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_180')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_180')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_180')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_180')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_180')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_180')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_180')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_180')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_180')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_180')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_180')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_180')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_180')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_180')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_180')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_180')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_180')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_180')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_180')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_180')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_180')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_180')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_180')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_180')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_180')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_180')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_180')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_180')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_180')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_180')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_180')}
	)})
	XPBoosts.Add({(
		BoostValue=190,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_190')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_190')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_190')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_190')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_190')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_190')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_190')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_190')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_190')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_190')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_190')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_190')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_190')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_190')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_190')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_190')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_190')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_190')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_190')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_190')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_190')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_190')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_190')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_190')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_190')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_190')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_190')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_190')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_190')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_190')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_190')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_190')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_190')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_190')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_190')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_190')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_190')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_190')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_190')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_190')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_190')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_190')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_190')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_190')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_190')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_190')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_190')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_190')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_190')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_190')}
	)})
	XPBoosts.Add({(
		BoostValue=200,
		Zeds[0]={(ZedName=KFPawn_ZedBloat,Proxy=class'Proxy_KFPawn_ZedBloat_200')},
		Zeds[1]={(ZedName=KFPawn_ZedBloatKing,Proxy=class'Proxy_KFPawn_ZedBloatKing_200')},
		Zeds[2]={(ZedName=KFPawn_ZedBloatKing_SantasWorkshop,Proxy=class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_200')},
		Zeds[3]={(ZedName=KFPawn_ZedBloatKingSubspawn,Proxy=class'Proxy_KFPawn_ZedBloatKingSubspawn_200')},
		Zeds[4]={(ZedName=KFPawn_ZedClot_Alpha,Proxy=class'Proxy_KFPawn_ZedClot_Alpha_200')},
		Zeds[5]={(ZedName=KFPawn_ZedClot_AlphaKing,Proxy=class'Proxy_KFPawn_ZedClot_AlphaKing_200')},
		Zeds[6]={(ZedName=KFPawn_ZedClot_Cyst,Proxy=class'Proxy_KFPawn_ZedClot_Cyst_200')},
		Zeds[7]={(ZedName=KFPawn_ZedClot_Slasher,Proxy=class'Proxy_KFPawn_ZedClot_Slasher_200')},
		Zeds[8]={(ZedName=KFPawn_ZedCrawler,Proxy=class'Proxy_KFPawn_ZedCrawler_200')},
		Zeds[9]={(ZedName=KFPawn_ZedCrawlerKing,Proxy=class'Proxy_KFPawn_ZedCrawlerKing_200')},
		Zeds[10]={(ZedName=KFPawn_ZedDAR,Proxy=class'Proxy_KFPawn_ZedDAR_200')},
		Zeds[11]={(ZedName=KFPawn_ZedDAR_EMP,Proxy=class'Proxy_KFPawn_ZedDAR_EMP_200')},
		Zeds[12]={(ZedName=KFPawn_ZedDAR_Laser,Proxy=class'Proxy_KFPawn_ZedDAR_Laser_200')},
		Zeds[13]={(ZedName=KFPawn_ZedDAR_Rocket,Proxy=class'Proxy_KFPawn_ZedDAR_Rocket_200')},
		Zeds[14]={(ZedName=KFPawn_ZedFleshpound,Proxy=class'Proxy_KFPawn_ZedFleshpound_200')},
		Zeds[15]={(ZedName=KFPawn_ZedFleshpoundKing,Proxy=class'Proxy_KFPawn_ZedFleshpoundKing_200')},
		Zeds[16]={(ZedName=KFPawn_ZedFleshpoundMini,Proxy=class'Proxy_KFPawn_ZedFleshpoundMini_200')},
		Zeds[17]={(ZedName=KFPawn_ZedGorefast,Proxy=class'Proxy_KFPawn_ZedGorefast_200')},
		Zeds[18]={(ZedName=KFPawn_ZedGorefastDualBlade,Proxy=class'Proxy_KFPawn_ZedGorefastDualBlade_200')},
		Zeds[19]={(ZedName=KFPawn_ZedHans,Proxy=class'Proxy_KFPawn_ZedHans_200')},
		Zeds[20]={(ZedName=KFPawn_ZedHusk,Proxy=class'Proxy_KFPawn_ZedHusk_200')},
		Zeds[21]={(ZedName=KFPawn_ZedMatriarch,Proxy=class'Proxy_KFPawn_ZedMatriarch_200')},
		Zeds[22]={(ZedName=KFPawn_ZedPatriarch,Proxy=class'Proxy_KFPawn_ZedPatriarch_200')},
		Zeds[23]={(ZedName=KFPawn_ZedScrake,Proxy=class'Proxy_KFPawn_ZedScrake_200')},
		Zeds[24]={(ZedName=KFPawn_ZedSiren,Proxy=class'Proxy_KFPawn_ZedSiren_200')},
		Zeds[25]={(ZedName=KFPawn_ZedStalker,Proxy=class'Proxy_KFPawn_ZedStalker_200')},
		Zeds[26]={(ZedName=WMPawn_ZedBloatKing,Proxy=class'Proxy_WMPawn_ZedBloatKing_200')},
		Zeds[27]={(ZedName=WMPawn_ZedClot_Slasher_Omega,Proxy=class'Proxy_WMPawn_ZedClot_Slasher_Omega_200')},
		Zeds[28]={(ZedName=WMPawn_ZedCrawler_Big,Proxy=class'Proxy_WMPawn_ZedCrawler_Big_200')},
		Zeds[29]={(ZedName=WMPawn_ZedCrawler_Huge,Proxy=class'Proxy_WMPawn_ZedCrawler_Huge_200')},
		Zeds[30]={(ZedName=WMPawn_ZedCrawler_Medium,Proxy=class'Proxy_WMPawn_ZedCrawler_Medium_200')},
		Zeds[31]={(ZedName=WMPawn_ZedCrawler_Mini,Proxy=class'Proxy_WMPawn_ZedCrawler_Mini_200')},
		Zeds[32]={(ZedName=WMPawn_ZedCrawler_Ultra,Proxy=class'Proxy_WMPawn_ZedCrawler_Ultra_200')},
		Zeds[33]={(ZedName=WMPawn_ZedFleshpound_Omega,Proxy=class'Proxy_WMPawn_ZedFleshpound_Omega_200')},
		Zeds[34]={(ZedName=WMPawn_ZedFleshpound_Predator,Proxy=class'Proxy_WMPawn_ZedFleshpound_Predator_200')},
		Zeds[35]={(ZedName=WMPawn_ZedFleshpoundKing,Proxy=class'Proxy_WMPawn_ZedFleshpoundKing_200')},
		Zeds[36]={(ZedName=WMPawn_ZedGorefast_Omega,Proxy=class'Proxy_WMPawn_ZedGorefast_Omega_200')},
		Zeds[37]={(ZedName=WMPawn_ZedHans,Proxy=class'Proxy_WMPawn_ZedHans_200')},
		Zeds[38]={(ZedName=WMPawn_ZedHusk_Omega,Proxy=class'Proxy_WMPawn_ZedHusk_Omega_200')},
		Zeds[39]={(ZedName=WMPawn_ZedHusk_Tiny,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_200')},
		Zeds[40]={(ZedName=WMPawn_ZedHusk_Tiny_Blue,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Blue_200')},
		Zeds[41]={(ZedName=WMPawn_ZedHusk_Tiny_Green,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Green_200')},
		Zeds[42]={(ZedName=WMPawn_ZedHusk_Tiny_Pink,Proxy=class'Proxy_WMPawn_ZedHusk_Tiny_Pink_200')},
		Zeds[43]={(ZedName=WMPawn_ZedMatriarch,Proxy=class'Proxy_WMPawn_ZedMatriarch_200')},
		Zeds[44]={(ZedName=WMPawn_ZedPatriarch,Proxy=class'Proxy_WMPawn_ZedPatriarch_200')},
		Zeds[45]={(ZedName=WMPawn_ZedScrake_Emperor,Proxy=class'Proxy_WMPawn_ZedScrake_Emperor_200')},
		Zeds[46]={(ZedName=WMPawn_ZedScrake_Omega,Proxy=class'Proxy_WMPawn_ZedScrake_Omega_200')},
		Zeds[47]={(ZedName=WMPawn_ZedScrake_Tiny,Proxy=class'Proxy_WMPawn_ZedScrake_Tiny_200')},
		Zeds[48]={(ZedName=WMPawn_ZedSiren_Omega,Proxy=class'Proxy_WMPawn_ZedSiren_Omega_200')},
		Zeds[49]={(ZedName=WMPawn_ZedStalker_Omega,Proxy=class'Proxy_WMPawn_ZedStalker_Omega_200')}
	)})
}
