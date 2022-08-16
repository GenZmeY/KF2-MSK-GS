class MSKGS_GM_Objective extends KFGameInfo_Objective;

const GIC = "KFGameContent.KFGameInfo_Objective";

var public IMSKGS_GameInfo GI;
var public IMSKGS          MSKGS;
var public E_LogLevel      LogLevel;

public simulated function ExileServerUsingKickBan()
{
	`Log_Trace();
	
	return;
}

public function UpdateGameSettings()
{
	`Log_Trace();
	
	if (GI != None)
	{
		GI.UpdateGameSettings(Self, GIC, MSKGS);
	}
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	`Log_Trace();
	
	Super.DistributeMoneyAndXP(MSKGS == None ? MonsterClass : MSKGS.PickProxyZed(MonsterClass), DamageHistory, Killer);
}

defaultproperties
{
	bIsCustomGame = false
}
