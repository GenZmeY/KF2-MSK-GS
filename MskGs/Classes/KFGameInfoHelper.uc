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
				
				if (Mut == NONE || Mut.MskGsMemberList.Length == 0)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;
				}
				else if (Mut.MskGsMemberList.Length > 10)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName @ "(+50% XP)";
				}
				else
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName @ "(+" $ Mut.MskGsMemberList.Length * 5 $ "% XP)";
				}

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
	switch (Mut.MskGsMemberList.Length)
	{
		case 0:  return MonsterClass;
		case 1:	 return PickProxyZed05(MonsterClass);
		case 2:  return PickProxyZed10(MonsterClass);
		case 3:  return PickProxyZed15(MonsterClass);
		case 4:  return PickProxyZed20(MonsterClass);
		case 5:  return PickProxyZed25(MonsterClass);
		case 6:  return PickProxyZed30(MonsterClass);
		case 7:  return PickProxyZed35(MonsterClass);
		case 8:  return PickProxyZed40(MonsterClass);
		case 9:  return PickProxyZed45(MonsterClass);
		case 10: return PickProxyZed50(MonsterClass);
		default: return PickProxyZed50(MonsterClass);
	}
}

private static function class<KFPawn_Monster> PickProxyZed05(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_05';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_05';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_05';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_05';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_05';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_05';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_05';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_05';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_05';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_05';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_05';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_05';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_05';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_05';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_05';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_05';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_05';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_05';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_05';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_05';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_05';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_05';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_05';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_05';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_05';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_05';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed10(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_10';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_10';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_10';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_10';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_10';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_10';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_10';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_10';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_10';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_10';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_10';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_10';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_10';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_10';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_10';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_10';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_10';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_10';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_10';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_10';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_10';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_10';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_10';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_10';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_10';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_10';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed15(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_15';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_15';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_15';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_15';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_15';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_15';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_15';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_15';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_15';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_15';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_15';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_15';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_15';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_15';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_15';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_15';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_15';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_15';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_15';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_15';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_15';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_15';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_15';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_15';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_15';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_15';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed20(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_20';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_20';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_20';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_20';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_20';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_20';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_20';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_20';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_20';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_20';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_20';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_20';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_20';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_20';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_20';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_20';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_20';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_20';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_20';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_20';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_20';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_20';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_20';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_20';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_20';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_20';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed25(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_25';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_25';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_25';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_25';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_25';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_25';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_25';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_25';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_25';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_25';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_25';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_25';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_25';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_25';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_25';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_25';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_25';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_25';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_25';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_25';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_25';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_25';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_25';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_25';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_25';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_25';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed30(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_30';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_30';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_30';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_30';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_30';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_30';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_30';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_30';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_30';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_30';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_30';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_30';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_30';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_30';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_30';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_30';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_30';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_30';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_30';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_30';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_30';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_30';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_30';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_30';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_30';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_30';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed35(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_35';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_35';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_35';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_35';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_35';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_35';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_35';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_35';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_35';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_35';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_35';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_35';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_35';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_35';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_35';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_35';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_35';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_35';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_35';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_35';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_35';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_35';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_35';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_35';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_35';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_35';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed40(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_40';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_40';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_40';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_40';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_40';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_40';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_40';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_40';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_40';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_40';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_40';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_40';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_40';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_40';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_40';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_40';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_40';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_40';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_40';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_40';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_40';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_40';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_40';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_40';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_40';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_40';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed45(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_45';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_45';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_45';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_45';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_45';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_45';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_45';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_45';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_45';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_45';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_45';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_45';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_45';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_45';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_45';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_45';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_45';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_45';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_45';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_45';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_45';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_45';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_45';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_45';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_45';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_45';
		default:                                        return MonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed50(class<KFPawn_Monster> MonsterClass)
{
	switch (MonsterClass)
	{
		case class'KFPawn_ZedBloat':                    return class'KFPawnProxy_ZedBloat_50';
		case class'KFPawn_ZedBloatKing':                return class'KFPawnProxy_ZedBloatKing_50';
		case class'KFPawn_ZedBloatKing_SantasWorkshop': return class'KFPawnProxy_ZedBloatKing_SantasWorkshop_50';
		case class'KFPawn_ZedBloatKingSubspawn':        return class'KFPawnProxy_ZedBloatKingSubspawn_50';
		case class'KFPawn_ZedClot_Alpha':               return class'KFPawnProxy_ZedClot_Alpha_50';
		case class'KFPawn_ZedClot_AlphaKing':           return class'KFPawnProxy_ZedClot_AlphaKing_50';
		case class'KFPawn_ZedClot_Cyst':                return class'KFPawnProxy_ZedClot_Cyst_50';
		case class'KFPawn_ZedClot_Slasher':             return class'KFPawnProxy_ZedClot_Slasher_50';
		case class'KFPawn_ZedCrawler':                  return class'KFPawnProxy_ZedCrawler_50';
		case class'KFPawn_ZedCrawlerKing':              return class'KFPawnProxy_ZedCrawlerKing_50';
		case class'KFPawn_ZedDAR':                      return class'KFPawnProxy_ZedDAR_50';
		case class'KFPawn_ZedDAR_EMP':                  return class'KFPawnProxy_ZedDAR_EMP_50';
		case class'KFPawn_ZedDAR_Laser':                return class'KFPawnProxy_ZedDAR_Laser_50';
		case class'KFPawn_ZedDAR_Rocket':               return class'KFPawnProxy_ZedDAR_Rocket_50';
		case class'KFPawn_ZedFleshpound':               return class'KFPawnProxy_ZedFleshpound_50';
		case class'KFPawn_ZedFleshpoundKing':           return class'KFPawnProxy_ZedFleshpoundKing_50';
		case class'KFPawn_ZedFleshpoundMini':           return class'KFPawnProxy_ZedFleshpoundMini_50';
		case class'KFPawn_ZedGorefast':                 return class'KFPawnProxy_ZedGorefast_50';
		case class'KFPawn_ZedGorefastDualBlade':        return class'KFPawnProxy_ZedGorefastDualBlade_50';
		case class'KFPawn_ZedHans':                     return class'KFPawnProxy_ZedHans_50';
		case class'KFPawn_ZedHusk':                     return class'KFPawnProxy_ZedHusk_50';
		case class'KFPawn_ZedMatriarch':                return class'KFPawnProxy_ZedMatriarch_50';
		case class'KFPawn_ZedPatriarch':                return class'KFPawnProxy_ZedPatriarch_50';
		case class'KFPawn_ZedScrake':                   return class'KFPawnProxy_ZedScrake_50';
		case class'KFPawn_ZedSiren':                    return class'KFPawnProxy_ZedSiren_50';
		case class'KFPawn_ZedStalker':                  return class'KFPawnProxy_ZedStalker_50';
		default:                                        return MonsterClass;
	}	
}

defaultproperties
{

}