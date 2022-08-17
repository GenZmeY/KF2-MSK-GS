class CfgLifespan extends Object
	config(MSKGS)
	abstract;

var public config int Weap;
var public config int Dosh;

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
	
	if (default.Weap < 0)
	{
		`Log_Error("Weap" @ "(" $ default.Weap $ ")" @ "must be equal or greater than 0");
		default.Weap = 60 * 60;
	}
	
	if (default.Dosh < 0)
	{
		`Log_Error("Dosh" @ "(" $ default.Dosh $ ")" @ "must be equal or greater than 0");
		default.Dosh = 60 * 5;
	}
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.Weap = 60 * 60; // 1 hour
	default.Dosh = 60 * 5;  // 5 min
}

defaultproperties
{

}
