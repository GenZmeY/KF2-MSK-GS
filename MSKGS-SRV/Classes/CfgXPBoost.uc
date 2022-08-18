class CfgXPBoost extends Object
	config(MSKGS)
	abstract;

var public  config int    MaxBoost;

var public  config int    BoostOwner;
var public  config int    BoostAdmin;
var public  config int    BoostGroup;
var public  config int    BoostPlayer;

var public  config String HexColorOwner;
var public  config String HexColorAdmin;
var public  config String HexColorGroup;
var public  config String HexColorPlayer;
var public  config String HexColorLeave;

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
		default.CheckGroupTimer = 0;
	}
	
	if (!IsValidHexColor(default.HexColorOwner, LogLevel))
	{
		`Log_Error("HexColorOwner" @ "(" $ default.HexColorOwner $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorAdmin, LogLevel))
	{
		`Log_Error("HexColorAdmin" @ "(" $ default.HexColorAdmin $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorGroup, LogLevel))
	{
		`Log_Error("HexColorGroup" @ "(" $ default.HexColorGroup $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorPlayer, LogLevel))
	{
		`Log_Error("HexColorPlayer" @ "(" $ default.HexColorPlayer $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorLeave, LogLevel))
	{
		`Log_Error("HexColorLeave" @ "(" $ default.HexColorLeave $ ")" @ "is not valid hex color");
	}
}

private static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.MaxBoost    = 100;
	
	default.BoostOwner  = 30;
	default.BoostAdmin  = 20;
	default.BoostGroup  = 10;
	default.BoostPlayer = 0;
	
	default.HexColorOwner  = "00FF00";
	default.HexColorAdmin  = "00FF00";
	default.HexColorGroup  = "00FF00";
	default.HexColorPlayer = "FFFFFF";
	default.HexColorLeave  = "FF0000";
	
	default.CheckGroupTimer = 0;
}

private static function bool IsValidHexColor(String HexColor, E_LogLevel LogLevel)
{
	local byte Index;
	
	`Log_TraceStatic();
	
	if (len(HexColor) != 6) return false;
	
	HexColor = Locs(HexColor);
	
	for (Index = 0; Index < 6; ++Index)
	{
		switch (Mid(HexColor, Index, 1))
		{
			case "0": break;
			case "1": break;
			case "2": break;
			case "3": break;
			case "4": break;
			case "5": break;
			case "6": break;
			case "7": break;
			case "8": break;
			case "9": break;
			case "a": break;
			case "b": break;
			case "c": break;
			case "d": break;
			case "e": break;
			case "f": break;
			default: return false;
		}
	}

	return true;
}

defaultproperties
{

}
