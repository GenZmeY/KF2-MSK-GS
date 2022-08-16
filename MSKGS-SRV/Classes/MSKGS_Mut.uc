class MSKGS_Mut extends KFMutator
	config(MSKGS);

var private MSKGS MSKGS;

public simulated function bool SafeDestroy()
{
	return (bPendingDelete || bDeleteMe || Destroy());
}

public event PreBeginPlay()
{
	Super.PreBeginPlay();
	
	if (WorldInfo.NetMode == NM_Client) return;
	
	foreach WorldInfo.DynamicActors(class'MSKGS', MSKGS)
	{
		break;
	}
	
	if (MSKGS == None)
	{
		MSKGS = WorldInfo.Spawn(class'MSKGS');
	}
	
	if (MSKGS == None)
	{
		`Log_Base("FATAL: Can't Spawn 'MSKGS'");
		SafeDestroy();
	}
}

public function InitMutator(String Options, out String ErrorMessage)
{
	Super.InitMutator(Options, ErrorMessage);
	
	MSKGS.SetMaxPlayers(class'GameInfo'.static.GetIntOption(Options, "MaxPlayers", INDEX_NONE));
}

public function AddMutator(Mutator Mut)
{
	if (Mut == Self) return;
	
	if (Mut.Class == Class)
		Mut.Destroy();
	else
		Super.AddMutator(Mut);
}

public function bool CheckRelevance(Actor A)
{
	local bool Relevance;

	Relevance = Super.CheckRelevance(A);
	if (Relevance)
	{
		MSKGS.ModifyLifespan(A);
	}

	return Relevance;
}

public function NotifyLogin(Controller C)
{
	MSKGS.NotifyLogin(C);
	
	Super.NotifyLogin(C);
}

public function NotifyLogout(Controller C)
{
	MSKGS.NotifyLogout(C);
	
	Super.NotifyLogout(C);
}

defaultproperties
{
	
}
