class KFWeap_AutoTurretFixed extends KFWeap_AutoTurret;

function CheckTurretAmmo()
{
	if (KFPC != None)
	{
		Super.CheckTurretAmmo();
	}
}

defaultproperties
{

}