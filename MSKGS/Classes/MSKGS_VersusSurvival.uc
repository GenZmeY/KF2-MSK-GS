class MSKGS_VersusSurvival extends KFGameInfo_VersusSurvival;

const GIC = "KFGameContent.KFGameInfo_VersusSurvival";

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
		GI.UpdateGameSettings(Self, GIC, MSKGS, bIsCustomGame, !IsUnrankedGame());
	}
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	`Log_Trace();
	
	Super.DistributeMoneyAndXP(MSKGS == None ? MonsterClass : MSKGS.PickProxyZed(MonsterClass), DamageHistory, Killer);
}

defaultproperties
{
	KFGFxManagerClass = class'MSKGS_GFxMoviePlayer_Manager_Versus'
}
