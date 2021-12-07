class MskGs_Survival extends KFGameInfo_Survival;

var const class<KFGameInfoHelper> KFGIH;

simulated function ExileServerUsingKickBan()
{
	return;
}

function UpdateGameSettings()
{
	KFGIH.static.UpdateGameSettings(Self, !IsUnrankedGame(), "KFGameContent.KFGameInfo_Survival");
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	Super.DistributeMoneyAndXP(KFGIH.static.PickProxyZed(MonsterClass, Killer), DamageHistory, Killer);
}

defaultproperties
{
	KFGIH=class'KFGameInfoHelper'
	bIsCustomGame=False
}
