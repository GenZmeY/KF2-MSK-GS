class MSKGS_GM_Survival extends KFGameInfo_Survival;

const GI  = class'MSKGS_GameInfo';
const GIC = "KFGameContent.KFGameInfo_Survival";

var public MSKGSMut Mut;

simulated function ExileServerUsingKickBan()
{
	return;
}

public function UpdateGameSettings()
{
	GI.static.UpdateGameSettings(Self, GIC, Mut);
}

protected function DistributeMoneyAndXP(class<KFPawn_Monster> MonsterClass, const out array<DamageInfo> DamageHistory, Controller Killer)
{
	Super.DistributeMoneyAndXP(GI.static.PickProxyZed(MonsterClass, Mut), DamageHistory, Killer);
}

defaultproperties
{
	bIsCustomGame = false
}
