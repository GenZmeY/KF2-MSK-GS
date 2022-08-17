class CfgLevels extends Object
	config(RPL)
	abstract;

var protected const int DefaultMin;
var protected const int DefaultMax;

var protected const int NoRestrictionsMin;
var protected const int NoRestrictionsMax;

var public  config int DisconnectTime;
var private config int Min;
var private config int Max;

var public  config String HexColorInfo;
var public  config String HexColorWarn;
var public  config String HexColorError;

public static function InitConfig(int Version, int LatestVersion, E_LogLevel LogLevel)
{
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault();
			
		default: break;
	}
	
	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

public static function Load(E_LogLevel LogLevel)
{
	if (default.Min < default.NoRestrictionsMin)
	{
		`Log_Error("Min" @ "(" $ default.Min $ ")" @ "must be equal or greater than" @ default.NoRestrictionsMin);
	}
	
	if (default.Max > default.NoRestrictionsMax)
	{
		`Log_Error("Max" @ "(" $ default.Max $ ")" @ "must be equal or less than" @ default.NoRestrictionsMax);
	}
	
	if (default.Min > default.Max)
	{
		`Log_Error("Min" @ "(" $ default.Min $ ")" @ "must be less than Max (" $ default.Max $ ")");
	}
	
	if (!IsValidHexColor(default.HexColorInfo, LogLevel))
	{
		`Log_Error("HexColorInfo" @ "(" $ default.HexColorInfo $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorWarn, LogLevel))
	{
		`Log_Error("HexColorWarn" @ "(" $ default.HexColorWarn $ ")" @ "is not valid hex color");
	}
	
	if (!IsValidHexColor(default.HexColorError, LogLevel))
	{
		`Log_Error("HexColorError" @ "(" $ default.HexColorError $ ")" @ "is not valid hex color");
	}
}

public static function bool Available(byte Level)
{
	return Level >= MinLevel() && Level <= MaxLevel();
}

public static function byte MinLevel()
{
	return byte(default.Min);
}

public static function byte MaxLevel()
{
	return byte(default.Max);
}

protected static function ApplyDefault()
{
	default.Min = default.DefaultMin;
	default.Max = default.DefaultMax;
	
	default.DisconnectTime = 15;
	
	default.HexColorInfo  = class'KFLocalMessage'.default.EventColor;
	default.HexColorWarn  = class'KFLocalMessage'.default.PriorityColor;
	default.HexColorError = class'KFLocalMessage'.default.InteractionColor;
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
	DefaultMin = 0
	DefaultMax = `MAX_PERK_LEVEL
	
	NoRestrictionsMin = 0
	NoRestrictionsMax = `MAX_PERK_LEVEL
}
