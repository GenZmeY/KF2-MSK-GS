class KFGameInfoHelper extends object;

static function UpdateGameSettings(KFGameInfo_Survival KFGI, bool bUsesStats, string GameModeClass)
{
	local name SessionName;
	local KFOnlineGameSettings KFGameSettings;
	local int NumHumanPlayers;
	local KFGameEngine KFEngine;
	local PlayerController PC;

	if (KFGI.WorldInfo.NetMode == NM_DedicatedServer || KFGI.WorldInfo.NetMode == NM_ListenServer)
	{
		if (KFGI.GameInterface != None)
		{
			KFEngine = KFGameEngine(class'Engine'.static.GetEngine());

			SessionName = KFGI.PlayerReplicationInfoClass.default.SessionName;

			if (KFGI.PlayfabInter != none && KFGI.PlayfabInter.GetGameSettings() != none)
			{
				KFGameSettings = KFOnlineGameSettings(KFGI.PlayfabInter.GetGameSettings());
				KFGameSettings.bAvailableForTakeover = KFEngine.bAvailableForTakeover;
			}
			else
			{
				KFGameSettings = KFOnlineGameSettings(KFGI.GameInterface.GetGameSettings(SessionName));
			}

			if (KFGameSettings != None)
			{
				KFGameSettings.Mode = class'KFGameInfo'.static.GetGameModeNumFromClass(GameModeClass);
				KFGameSettings.Difficulty = KFGI.GameDifficulty;

				if (KFGI.WaveNum == 0)
				{
					KFGameSettings.bInProgress = false;
					KFGameSettings.CurrentWave = 1;
				}
				else
				{
					KFGameSettings.bInProgress = true;
					KFGameSettings.CurrentWave = KFGI.WaveNum;
				}

				if (KFGI.MyKFGRI != none)
				{
					KFGameSettings.NumWaves = KFGI.MyKFGRI.GetFinalWaveNum();
					KFGI.MyKFGRI.bCustom = False;
				}
				else
				{
					KFGameSettings.NumWaves = KFGI.WaveMax - 1;
				}
				KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;

				KFGameSettings.NumPublicConnections = KFGI.MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword = KFGI.RequiresPassword();
				KFGameSettings.bCustom = False;
				KFGameSettings.bUsesStats = bUsesStats;
				KFGameSettings.NumSpectators = KFGI.NumSpectators;
				
				if (KFGI.WorldInfo.IsConsoleDedicatedServer() || KFGI.WorldInfo.IsEOSDedicatedServer())
				{
					KFGameSettings.MapName = KFGI.WorldInfo.GetMapName(true);
					foreach KFGI.WorldInfo.AllControllers(class'PlayerController', PC)
						if (PC.bIsPlayer
						&& PC.PlayerReplicationInfo != none
						&& !PC.PlayerReplicationInfo.bBot)
							NumHumanPlayers++;

					KFGameSettings.NumOpenPublicConnections = KFGameSettings.NumPublicConnections - NumHumanPlayers;
				}

				if (KFGI.PlayfabInter != none && KFGI.PlayfabInter.IsRegisteredWithPlayfab())
				{
					KFGI.PlayfabInter.ServerUpdateOnlineGame();
					if (KFGI.WorldInfo.IsEOSDedicatedServer())
					{
						KFGI.GameInterface.UpdateOnlineGame(SessionName, KFGameSettings, true);
					}
				}
				else
				{
					KFGI.GameInterface.UpdateOnlineGame(SessionName, KFGameSettings, true);
				}
			}
		}
	}
}

static function class<KFPawn_Monster> PickProxyZed(class<KFPawn_Monster> MonsterClass, Controller Killer)
{
	`log(">>>>>>>>>>>>> DBG: monsterclass"@MonsterClass);
	return MonsterClass;
}

defaultproperties
{

}