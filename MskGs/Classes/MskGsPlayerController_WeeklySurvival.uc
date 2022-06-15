class MskGsPlayerController_WeeklySurvival extends KFPlayerController_WeeklySurvival;

event Destroyed()
{
	local KFProjectile KFProj;
	local int i;

    // Stop currently playing stingers when the map is being switched
    if( StingerAkComponent != none )
    {
        StingerAkComponent.StopEvents();
    }
	
	// Useful:
	// https://wiki.beyondunreal.com/What_happens_when_an_Actor_is_destroyed
	for (i = DeployedTurrets.Length - 1; i >= 0; --i)
	{
		if (DeployedTurrets[i] != None)
			if (!DeployedTurrets[i].bPendingDelete && !DeployedTurrets[i].bDeleteMe)
				DeployedTurrets[i].Destroy();
		
		// don't worry about the Destroyed event on Turret
		// because it doesn't do anything if the turret is not in the list
		DeployedTurrets.Remove(i, 1);
	}

    SetRTPCValue( 'Health', 100, true );
    PostAkEvent( LowHealthStopEvent );
	bPlayingLowHealthSFX = false;

	// Update projectiles in the world
	foreach DynamicActors( class'KFProjectile', KFProj )
	{
		if( KFProj.InstigatorController == self )
		{
			KFProj.OnInstigatorControllerLeft();
		}
	}

	if( LocalCustomizationPawn != none && !LocalCustomizationPawn.bPendingDelete )
	{
		LocalCustomizationPawn.Destroy();
	}

	if (OnlineSub != none)
	{
		OnlineSub.ClearAllReadOnlineAvatarByNameCompleteDelegates();
		OnlineSub.ClearAllReadOnlineAvatarCompleteDelegates();
	}

	if (WorldInfo.NetMode != NM_DedicatedServer)
	{
		ClearMixerDelegates();
		ClearDiscord();
	}

    ClientMatchEnded();

	Super(GamePlayerController).Destroyed();
}

defaultproperties
{

}