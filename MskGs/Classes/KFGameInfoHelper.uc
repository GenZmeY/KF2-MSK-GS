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
	local class<KFPawn_Monster> ProxyClass;
	
	ProxyClass = MonsterClass;
	
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    ProxyClass = class'KFPawnProxy_ZedBloat';                    break;
		case class'KFPawn_ZedBloatKing':                ProxyClass = class'KFPawnProxy_ZedBloatKing';                break;
		case class'KFPawn_ZedBloatKing_SantasWorkshop': ProxyClass = class'KFPawnProxy_ZedBloatKing_SantasWorkshop'; break;
		case class'KFPawn_ZedBloatKingSubspawn':        ProxyClass = class'KFPawnProxy_ZedBloatKingSubspawn';        break;
		case class'KFPawn_ZedClot_Alpha':               ProxyClass = class'KFPawnProxy_ZedClot_Alpha';               break;
		case class'KFPawn_ZedClot_AlphaKing':           ProxyClass = class'KFPawnProxy_ZedClot_AlphaKing';           break;
		case class'KFPawn_ZedClot_Cyst':                ProxyClass = class'KFPawnProxy_ZedClot_Cyst';                break;
		case class'KFPawn_ZedClot_Slasher':             ProxyClass = class'KFPawnProxy_ZedClot_Slasher';             break;
		case class'KFPawn_ZedCrawler':                  ProxyClass = class'KFPawnProxy_ZedCrawler';                  break;
		case class'KFPawn_ZedCrawlerKing':              ProxyClass = class'KFPawnProxy_ZedCrawlerKing';              break;
		case class'KFPawn_ZedDAR':                      ProxyClass = class'KFPawnProxy_ZedDAR';                      break;
		case class'KFPawn_ZedDAR_EMP':                  ProxyClass = class'KFPawnProxy_ZedDAR_EMP';                  break;
		case class'KFPawn_ZedDAR_Laser':                ProxyClass = class'KFPawnProxy_ZedDAR_Laser';                break;
		case class'KFPawn_ZedDAR_Rocket':               ProxyClass = class'KFPawnProxy_ZedDAR_Rocket';               break;
		case class'KFPawn_ZedFleshpound':               ProxyClass = class'KFPawnProxy_ZedFleshpound';               break;
		case class'KFPawn_ZedFleshpoundKing':           ProxyClass = class'KFPawnProxy_ZedFleshpoundKing';           break;
		case class'KFPawn_ZedFleshpoundMini':           ProxyClass = class'KFPawnProxy_ZedFleshpoundMini';           break;
		case class'KFPawn_ZedGorefast':                 ProxyClass = class'KFPawnProxy_ZedGorefast';                 break;
		case class'KFPawn_ZedGorefastDualBlade':        ProxyClass = class'KFPawnProxy_ZedGorefastDualBlade';        break;
		case class'KFPawn_ZedHans':                     ProxyClass = class'KFPawnProxy_ZedHans';                     break;
		case class'KFPawn_ZedHusk':                     ProxyClass = class'KFPawnProxy_ZedHusk';                     break;
		case class'KFPawn_ZedMatriarch':                ProxyClass = class'KFPawnProxy_ZedMatriarch';                break;
		case class'KFPawn_ZedPatriarch':                ProxyClass = class'KFPawnProxy_ZedPatriarch';                break;
		case class'KFPawn_ZedScrake':                   ProxyClass = class'KFPawnProxy_ZedScrake';                   break;
		case class'KFPawn_ZedSiren':                    ProxyClass = class'KFPawnProxy_ZedSiren';                    break;
		case class'KFPawn_ZedStalker':                  ProxyClass = class'KFPawnProxy_ZedStalker';                  break;
	}

	return ProxyClass;
}

defaultproperties
{

}