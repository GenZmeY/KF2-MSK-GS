class CfgSpawnManager extends Object
	config(MSKGS)
	abstract;

var public config Array<int> MaxMonsters;

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
	
	foreach default.MaxMonsters(MM, PL)
	{
		if (MM <= 0)
		{
			`Log_Error("MaxMonsters[" $ PL $ "] =" @ MM @ "must be greater than 0");
			default.MaxMonsters[PL] = 32;
		}
	}
}

protected static function ApplyDefault(E_LogLevel LogLevel)
{
	`Log_TraceStatic();
	
	default.MaxMonsters.Length = 0;
	default.MaxMonsters.AddItem(12);
	default.MaxMonsters.AddItem(18);
	default.MaxMonsters.AddItem(24);
	default.MaxMonsters.AddItem(30);
	default.MaxMonsters.AddItem(34);
	default.MaxMonsters.AddItem(36);
}

defaultproperties
{

}
