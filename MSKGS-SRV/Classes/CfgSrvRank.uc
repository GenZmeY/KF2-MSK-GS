class CfgSrvRank extends Object
	config(MSKGS)
	abstract;

var public config bool   bAuto;
var public config bool   bCustom;
var public config bool   bUsesStats;
var public config bool   bServerExiled;
var public config bool   bAntiCheat;
var public config String PasswdText;

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

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.bAuto         = true;
	default.bCustom       = false;
	default.bUsesStats    = true;
	default.bServerExiled = false;
	default.bAntiCheat    = true;
	default.PasswdText    = "";
}

defaultproperties
{

}
