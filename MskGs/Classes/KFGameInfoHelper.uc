class KFGameInfoHelper extends Object;

public static function UpdateGameSettings(KFGameInfo_Survival KFGI, bool bUsesStats, string GameModeClass, MskGsMut Mut)
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

				if (KFGI.MyKFGRI != none)
				{
					KFGameSettings.NumWaves = KFGI.MyKFGRI.GetFinalWaveNum();
					KFGI.MyKFGRI.bCustom = False;
				}
				else
				{
					KFGameSettings.NumWaves = KFGI.WaveMax - 1;
				}
				
				if (Mut == NONE || !Mut.bXpNotifications || Mut.MskGsMemberList.Length == 0)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;
				}
				else if (Mut.MskGsMemberList.Length > 10)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +100% XP";
				}
				else
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +" $ Mut.MskGsMemberList.Length * 10 $ "% XP";
				}

				KFGameSettings.NumPublicConnections = KFGI.MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword = KFGI.RequiresPassword();
				KFGameSettings.bCustom = False;
				KFGameSettings.bUsesStats = bUsesStats;
				KFGameSettings.NumSpectators = KFGI.NumSpectators;
				
				if (KFGI.WorldInfo.IsConsoleDedicatedServer() || KFGI.WorldInfo.IsEOSDedicatedServer())
				{
					KFGameSettings.MapName = KFGI.WorldInfo.GetMapName(true);
					// Old:
					//foreach KFGI.WorldInfo.AllControllers(class'PlayerController', PC)
					//	if (PC.bIsPlayer
					//	&& PC.PlayerReplicationInfo != none
					//	&& !PC.PlayerReplicationInfo.bBot)
					//		NumHumanPlayers++;
					
					foreach KFGI.WorldInfo.AllControllers(class'PlayerController', PC)
						if (PC.bIsPlayer
						&& PC.PlayerReplicationInfo != none
						&& !PC.PlayerReplicationInfo.bOnlySpectator
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
	switch (Mut.MskGsMemberList.Length)
	{
		case 0:  return MonsterClass;
		case 1:	 return PickProxyZed010(MonsterClass);
		case 2:  return PickProxyZed020(MonsterClass);
		case 3:  return PickProxyZed030(MonsterClass);
		case 4:  return PickProxyZed040(MonsterClass);
		case 5:  return PickProxyZed050(MonsterClass);
		case 6:  return PickProxyZed060(MonsterClass);
		case 7:  return PickProxyZed070(MonsterClass);
		case 8:  return PickProxyZed080(MonsterClass);
		case 9:  return PickProxyZed090(MonsterClass);
		case 10: return PickProxyZed100(MonsterClass);
		default: return PickProxyZed100(MonsterClass);
	}
}

private static function class<KFPawn_Monster> PickProxyZed010(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_010';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_010';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_010';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_010';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_010';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_010';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_010';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_010';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_010';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_010';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_010';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_010';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_010';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_010';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_010';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_010';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_010';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_010';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_010';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_010';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_010';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_010';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_010';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_010';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_010';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_010';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed020(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_020';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_020';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_020';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_020';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_020';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_020';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_020';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_020';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_020';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_020';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_020';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_020';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_020';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_020';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_020';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_020';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_020';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_020';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_020';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_020';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_020';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_020';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_020';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_020';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_020';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_020';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed030(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_030';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_030';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_030';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_030';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_030';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_030';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_030';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_030';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_030';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_030';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_030';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_030';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_030';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_030';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_030';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_030';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_030';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_030';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_030';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_030';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_030';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_030';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_030';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_030';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_030';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_030';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed040(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_040';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_040';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_040';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_040';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_040';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_040';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_040';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_040';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_040';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_040';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_040';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_040';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_040';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_040';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_040';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_040';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_040';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_040';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_040';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_040';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_040';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_040';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_040';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_040';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_040';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_040';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed050(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_050';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_050';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_050';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_050';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_050';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_050';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_050';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_050';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_050';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_050';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_050';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_050';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_050';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_050';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_050';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_050';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_050';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_050';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_050';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_050';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_050';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_050';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_050';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_050';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_050';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_050';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed060(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_060';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_060';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_060';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_060';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_060';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_060';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_060';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_060';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_060';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_060';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_060';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_060';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_060';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_060';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_060';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_060';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_060';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_060';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_060';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_060';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_060';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_060';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_060';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_060';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_060';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_060';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed070(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_070';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_070';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_070';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_070';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_070';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_070';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_070';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_070';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_070';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_070';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_070';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_070';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_070';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_070';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_070';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_070';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_070';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_070';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_070';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_070';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_070';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_070';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_070';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_070';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_070';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_070';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed080(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_080';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_080';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_080';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_080';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_080';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_080';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_080';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_080';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_080';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_080';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_080';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_080';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_080';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_080';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_080';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_080';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_080';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_080';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_080';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_080';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_080';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_080';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_080';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_080';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_080';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_080';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed090(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_090';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_090';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_090';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_090';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_090';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_090';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_090';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_090';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_090';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_090';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_090';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_090';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_090';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_090';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_090';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_090';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_090';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_090';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_090';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_090';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_090';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_090';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_090';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_090';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_090';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_090';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed100(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_100';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_100';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_100';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_100';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_100';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_100';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_100';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_100';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_100';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_100';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_100';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_100';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_100';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_100';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_100';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_100';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_100';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_100';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_100';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_100';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_100';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_100';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_100';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_100';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_100';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_100';
		default:                                        return MonsterClass;
	}	
}

defaultproperties
{

}