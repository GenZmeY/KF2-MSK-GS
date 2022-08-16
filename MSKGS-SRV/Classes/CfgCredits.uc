class CfgCredits extends Object
	config(MSKGS)
	abstract;

var private config String OwnerId;
var private config String GroupID;

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
