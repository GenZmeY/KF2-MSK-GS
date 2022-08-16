class MSKGS_GM_Objective extends KFGameInfo_Objective;

const GI  = class'MSKGS_GameInfo';
const GIC = "KFGameContent.KFGameInfo_Objective";

var public MSKGS      MSKGS;
var public E_LogLevel LogLevel;

simulated function ExileServerUsingKickBan()
{
	return;
}

public function UpdateGameSettings()
{
	GI.static.UpdateGameSettings(Self, GIC, MSKGS);
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	Super.DistributeMoneyAndXP(GI.static.PickProxyZed(MonsterClass, MSKGS), DamageHistory, Killer);
}

defaultproperties
{
	bIsCustomGame = false
}
