class KFGameInfoHelper extends Object;

public static function UpdateGameSettings(KFGameInfo_Survival KFGI, bool bUsesStats, string GameModeClass)
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

public static function class<KFPawn_Monster> PickProxyZed(class<KFPawn_Monster> MonsterClass, Controller Killer, MskGsMut Mut)
{
	if (Mut.MskGsMemberList.Find(Killer) == INDEX_NONE) return MonsterClass;
	
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    MonsterClass = class'KFPawnProxy_ZedBloat';                    break;
		case class'KFPawn_ZedBloatKing':                MonsterClass = class'KFPawnProxy_ZedBloatKing';                break;
		case class'KFPawn_ZedBloatKing_SantasWorkshop': MonsterClass = class'KFPawnProxy_ZedBloatKing_SantasWorkshop'; break;
		case class'KFPawn_ZedBloatKingSubspawn':        MonsterClass = class'KFPawnProxy_ZedBloatKingSubspawn';        break;
		case class'KFPawn_ZedClot_Alpha':               MonsterClass = class'KFPawnProxy_ZedClot_Alpha';               break;
		case class'KFPawn_ZedClot_AlphaKing':           MonsterClass = class'KFPawnProxy_ZedClot_AlphaKing';           break;
		case class'KFPawn_ZedClot_Cyst':                MonsterClass = class'KFPawnProxy_ZedClot_Cyst';                break;
		case class'KFPawn_ZedClot_Slasher':             MonsterClass = class'KFPawnProxy_ZedClot_Slasher';             break;
		case class'KFPawn_ZedCrawler':                  MonsterClass = class'KFPawnProxy_ZedCrawler';                  break;
		case class'KFPawn_ZedCrawlerKing':              MonsterClass = class'KFPawnProxy_ZedCrawlerKing';              break;
		case class'KFPawn_ZedDAR':                      MonsterClass = class'KFPawnProxy_ZedDAR';                      break;
		case class'KFPawn_ZedDAR_EMP':                  MonsterClass = class'KFPawnProxy_ZedDAR_EMP';                  break;
		case class'KFPawn_ZedDAR_Laser':                MonsterClass = class'KFPawnProxy_ZedDAR_Laser';                break;
		case class'KFPawn_ZedDAR_Rocket':               MonsterClass = class'KFPawnProxy_ZedDAR_Rocket';               break;
		case class'KFPawn_ZedFleshpound':               MonsterClass = class'KFPawnProxy_ZedFleshpound';               break;
		case class'KFPawn_ZedFleshpoundKing':           MonsterClass = class'KFPawnProxy_ZedFleshpoundKing';           break;
		case class'KFPawn_ZedFleshpoundMini':           MonsterClass = class'KFPawnProxy_ZedFleshpoundMini';           break;
		case class'KFPawn_ZedGorefast':                 MonsterClass = class'KFPawnProxy_ZedGorefast';                 break;
		case class'KFPawn_ZedGorefastDualBlade':        MonsterClass = class'KFPawnProxy_ZedGorefastDualBlade';        break;
		case class'KFPawn_ZedHans':                     MonsterClass = class'KFPawnProxy_ZedHans';                     break;
		case class'KFPawn_ZedHusk':                     MonsterClass = class'KFPawnProxy_ZedHusk';                     break;
		case class'KFPawn_ZedMatriarch':                MonsterClass = class'KFPawnProxy_ZedMatriarch';                break;
		case class'KFPawn_ZedPatriarch':                MonsterClass = class'KFPawnProxy_ZedPatriarch';                break;
		case class'KFPawn_ZedScrake':                   MonsterClass = class'KFPawnProxy_ZedScrake';                   break;
		case class'KFPawn_ZedSiren':                    MonsterClass = class'KFPawnProxy_ZedSiren';                    break;
		case class'KFPawn_ZedStalker':                  MonsterClass = class'KFPawnProxy_ZedStalker';                  break;
	}

	return MonsterClass;
}

defaultproperties
{

}