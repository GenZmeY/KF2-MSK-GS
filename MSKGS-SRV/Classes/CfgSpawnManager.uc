class CfgSpawnManager extends Object
	config(MSKGS)
	abstract;

var public config Array<int> PerPlayerMaxMonsters;

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
	local int MM, PL;
	
	`Log_TraceStatic();
	
	foreach default.PerPlayerMaxMonsters(MM, PL)
	{
		if (MM <= 0)
		{
			`Log_Error("PerPlayerMaxMonsters[" $ PL $ "] =" @ MM @ "must be greater than 0");
			default.PerPlayerMaxMonsters[PL] = 32;
		}
	}
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.PerPlayerMaxMonsters.Length = 0;
	default.PerPlayerMaxMonsters.AddItem(12);
	default.PerPlayerMaxMonsters.AddItem(18);
	default.PerPlayerMaxMonsters.AddItem(24);
	default.PerPlayerMaxMonsters.AddItem(30);
	default.PerPlayerMaxMonsters.AddItem(34);
	default.PerPlayerMaxMonsters.AddItem(36);
}

defaultproperties
{

}
