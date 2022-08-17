class MSKGS_GameInfo extends Object
	implements(IMSKGS_GameInfo);

const CfgXPBoost = class'CfgXPBoost';
const CfgSrvRank = class'CfgSrvRank';

public static function UpdateGameSettings(
KFGameInfo_Survival KFGI,
String GameModeClass,
IMSKGS MSKGS,
bool bCustomGame,
bool bUsesStats)
{
	local name SessionName;
	local KFOnlineGameSettings KFGameSettings;
	local int NumHumanPlayers;
	local KFGameEngine KFEngine;
	local PlayerController PC;
	local E_LogLevel LogLevel;
	
	LogLevel = (MSKGS == None ? LL_None : MSKGS.GetLogLevel());
	
	`Log_TraceStatic();
	`Log_Debug("UpdateGameSettings");

	if (KFGI.WorldInfo.NetMode == NM_DedicatedServer || KFGI.WorldInfo.NetMode == NM_ListenServer)
	{
		if (KFGI.GameInterface != None)
		{
			KFEngine = KFGameEngine(class'Engine'.static.GetEngine());

			SessionName = KFGI.PlayerReplicationInfoClass.default.SessionName;

			if (KFGI.PlayfabInter != None && KFGI.PlayfabInter.GetGameSettings() != None)
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
				KFGameSettings.Mode = KFGI.default.GameModes.Find('ClassNameAndPath', GameModeClass);
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

				if (KFGI.MyKFGRI != None)
				{
					KFGameSettings.NumWaves = KFGI.MyKFGRI.GetFinalWaveNum();
					if (CfgSrvRank.default.bAuto)
					{
						KFGI.MyKFGRI.bCustom = bCustomGame;
					}
					else
					{
						KFGI.MyKFGRI.bCustom = CfgSrvRank.default.bCustom;
					}
				}
				else
				{
					KFGameSettings.NumWaves = KFGI.WaveMax - 1;
				}
				
				if (MSKGS == None || !MSKGS.GetXPNotifications() || MSKGS.GetXPBoost() <= 0)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;
				}
				else if (MSKGS.GetXPBoost() >= CfgXPBoost.default.MaxBoost)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +" $ CfgXPBoost.default.MaxBoost $ "% XP";
				}
				else
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +" $ MSKGS.GetXPBoost() $ "% XP";
				}

				KFGameSettings.NumPublicConnections = KFGI.MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword    = KFGI.RequiresPassword();
				KFGameSettings.NumSpectators        = KFGI.NumSpectators;
				if (CfgSrvRank.default.bAuto)
				{
					KFGameSettings.bCustom          = bCustomGame;
					KFGameSettings.bUsesStats       = bUsesStats;
				}
				else
				{
					KFGameSettings.bCustom          = CfgSrvRank.default.bCustom;
					KFGameSettings.bUsesStats       = CfgSrvRank.default.bUsesStats;
				}
				
				if (KFGI.WorldInfo.IsConsoleDedicatedServer() || KFGI.WorldInfo.IsEOSDedicatedServer())
				{
					KFGameSettings.MapName = KFGI.WorldInfo.GetMapName(true);
					
					foreach KFGI.WorldInfo.AllControllers(class'PlayerController', PC)
						if (PC.bIsPlayer
						&& PC.PlayerReplicationInfo != None
						&& !PC.PlayerReplicationInfo.bOnlySpectator
						&& !PC.PlayerReplicationInfo.bBot)
							NumHumanPlayers++;

					KFGameSettings.NumOpenPublicConnections = KFGameSettings.NumPublicConnections - NumHumanPlayers;
				}

				if (KFGI.PlayfabInter != None && KFGI.PlayfabInter.IsRegisteredWithPlayfab())
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

defaultproperties
{

}