class MskGs_Endless extends KFGameInfo_Endless;

function WaveEnded(EWaveEndCondition WinCondition)
{
	// fix bugs after tripware
	if(!bWaveStarted && !MyKFGRI.bTraderIsOpen)
		return;

	Super.WaveEnded(WinCondition);
}

function UpdateGameSettings()
{
	local name SessionName;
	local KFOnlineGameSettings KFGameSettings;
	local int NumHumanPlayers;
	local KFGameEngine KFEngine;
	local PlayerController PC;

	if (WorldInfo.NetMode == NM_DedicatedServer || WorldInfo.NetMode == NM_ListenServer)
	{
		//`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 1 - GameInterface: "$GameInterface);
		if (GameInterface != None)
		{
			KFEngine = KFGameEngine(class'Engine'.static.GetEngine());

			SessionName = PlayerReplicationInfoClass.default.SessionName;

			if( PlayfabInter != none && PlayfabInter.GetGameSettings() != none )
			{
				KFGameSettings = KFOnlineGameSettings(PlayfabInter.GetGameSettings());
				KFGameSettings.bAvailableForTakeover = KFEngine.bAvailableForTakeover;
			}
			else
			{
				KFGameSettings = KFOnlineGameSettings(GameInterface.GetGameSettings(SessionName));
			}
			//Ensure bug-for-bug compatibility with KF1

			//`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 2 - KFGameSettings: "$KFGameSettings);

			if (KFGameSettings != None)
			{
				//`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 3 - KFGameSettings.bAvailableForTakeover: "$KFGameSettings.bAvailableForTakeover);

				KFGameSettings.Mode = default.GameModes.Find('ClassNameAndPath', "KFGameContent.KFGameInfo_Endless");
				KFGameSettings.Difficulty = GameDifficulty;
				//Ensure bug-for-bug compatibility with KF1
				if (WaveNum == 0)
				{
					KFGameSettings.bInProgress = false;
					KFGameSettings.CurrentWave = 1;
				}
				else
				{
					KFGameSettings.bInProgress = true;
					KFGameSettings.CurrentWave = WaveNum;
				}
				//Also from KF1
				if(MyKFGRI != none)
				{
					KFGameSettings.NumWaves = MyKFGRI.GetFinalWaveNum();
				}
				else
				{
					KFGameSettings.NumWaves = WaveMax - 1;
				}
				KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;

				KFGameSettings.NumPublicConnections = MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword = RequiresPassword();
				KFGameSettings.bCustom = False;
				KFGameSettings.bUsesStats = !IsUnrankedGame();
				KFGameSettings.NumSpectators = NumSpectators;
				if(MyKFGRI != none)
				{
					MyKFGRI.bCustom = False;
				}

				// Set the map name
				//@SABER_EGS IsEOSDedicatedServer() case added
				if( WorldInfo.IsConsoleDedicatedServer() || WorldInfo.IsEOSDedicatedServer() )
				{
					KFGameSettings.MapName = WorldInfo.GetMapName(true);
					foreach WorldInfo.AllControllers(class'PlayerController', PC)
						if (PC.bIsPlayer
						&& PC.PlayerReplicationInfo != none
						&& !PC.PlayerReplicationInfo.bOnlySpectator)
							NumHumanPlayers++;
					KFGameSettings.NumOpenPublicConnections = KFGameSettings.NumPublicConnections - NumHumanPlayers;
				}

				//`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 4 - PlayfabInter: "$PlayfabInter);
				if (PlayfabInter != none)
				{
					//`REMOVEMESOON_ServerTakeoverLog("KFGameInfo_Survival.UpdateGameSettings 4.1 - IsRegisteredWithPlayfab: "$PlayfabInter.IsRegisteredWithPlayfab());
				}

				if( PlayfabInter != none && PlayfabInter.IsRegisteredWithPlayfab() )
				{
					PlayfabInter.ServerUpdateOnlineGame();
					//@SABER_EGS_BEGIN Crossplay support
					if (WorldInfo.IsEOSDedicatedServer()) {
						GameInterface.UpdateOnlineGame(SessionName, KFGameSettings, true);
					}
					//@SABER_EGS_END
				}
				else
				{
					//Trigger re-broadcast of game settings
					GameInterface.UpdateOnlineGame(SessionName, KFGameSettings, true);
				}
			}
		}
	}
}

defaultproperties
{
	bIsCustomGame=False
}