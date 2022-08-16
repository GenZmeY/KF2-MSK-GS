class CfgXPBoost extends Object
	config(MSKGS)
	abstract;

var private config String OwnerId;
var private config String GroupID;

var public  config int    MaxBoost;

var public  config int    BoostOwner;
var public  config int    BoostAdmin;
var public  config int    BoostGroup;
var public  config int    BoostPlayer;

var public  config int    CheckGroupTimer;

public static function InitConfig(int Version, int LatestVersion, E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault(LogLevel);
			
		default: break;
	}
	
	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

public static function Load(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	if (default.MaxBoost < 0)
	{
		`Log_Error("MaxBoost" @ "(" $ default.MaxBoost $ ")" @ "must be equal or greater than 0");
		default.MaxBoost = 30;
	}
	
	if (default.BoostOwner < 0)
	{
		`Log_Error("BoostOwner" @ "(" $ default.BoostOwner $ ")" @ "must be equal or greater than 0");
		default.BoostOwner = 30;
	}
	
	if (default.BoostAdmin < 0)
	{
		`Log_Error("BoostAdmin" @ "(" $ default.BoostAdmin $ ")" @ "must be equal or greater than 0");
		default.BoostAdmin = 20;
	}
	
	if (default.BoostGroup < 0)
	{
		`Log_Error("BoostGroup" @ "(" $ default.BoostGroup $ ")" @ "must be equal or greater than 0");
		default.BoostGroup = 10;
	}
	
	if (default.BoostPlayer < 0)
	{
		`Log_Error("BoostPlayer" @ "(" $ default.BoostPlayer $ ")" @ "must be equal or greater than 0");
		default.BoostPlayer = 0;
	}
	
	if (default.CheckGroupTimer < 0)
	{
		`Log_Error("CheckGroupTimer" @ "(" $ default.CheckGroupTimer $ ")" @ "must be equal or greater than 0");
		default.CheckGroupTimer = 10;
	}
}

public static function UniqueNetId LoadOwnerId(OnlineSubsystem OS, E_LogLevel LogLevel)
{
	local UniqueNetId UID;
	
	if (AnyToUID(OS, default.OwnerId, UID, LogLevel))
	{
		`Log_Debug("Loaded OwnerId:" @ default.OwnerId);
	}
	else
	{
		`Log_Warn("Can't load OwnerId:" @ default.OwnerId);
	}
	
	return UID;
}

public static function UniqueNetId LoadGroupID(OnlineSubsystem OS, E_LogLevel LogLevel)
{
	local UniqueNetId UID;
	
	if (AnyToUID(OS, default.GroupID, UID, LogLevel))
	{
		`Log_Debug("Loaded GroupID:" @ default.GroupID);
	}
	else
	{
		`Log_Warn("Can't load GroupID:" @ default.GroupID);
	}
	
	return UID;
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.OwnerId = "76561198001617867";
	default.GroupID = "0x017000000223386E";
	
	default.MaxBoost    = 100;
	
	default.BoostOwner  = 30;
	default.BoostAdmin  = 20;
	default.BoostGroup  = 10;
	default.BoostPlayer = 0;
	
	default.CheckGroupTimer = 10;
}

private static function bool IsUID(String ID, E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	return (Locs(Left(ID, 2)) == "0x");
}

private static function bool AnyToUID(OnlineSubsystem OS, String ID, out UniqueNetId UID, E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	return IsUID(ID, LogLevel) ? OS.StringToUniqueNetId(ID, UID) : OS.Int64ToUniqueNetId(ID, UID);
}

defaultproperties
{

}
