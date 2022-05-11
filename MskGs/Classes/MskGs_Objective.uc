class MskGs_Objective extends KFGameInfo_Objective;

var const class<KFGameInfoHelper> KFGIH;

var public MskGsMut Mut;


simulated function ExileServerUsingKickBan()
{
	return;
}

function UpdateGameSettings()
{
	KFGIH.static.UpdateGameSettings(Self, !IsUnrankedGame(), "KFGameContent.KFGameInfo_Objective", Mut);
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	`log(">>>>>>>>>>" @ KFGIH.static.PickProxyZed(MonsterClass, Killer, Mut));
	Super.DistributeMoneyAndXP(KFGIH.static.PickProxyZed(MonsterClass, Killer, Mut), DamageHistory, Killer);
}

defaultproperties
{
	KFGIH=class'KFGameInfoHelper'
	bIsCustomGame=False
}
