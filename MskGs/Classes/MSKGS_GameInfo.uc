class MSKGS_GameInfo extends Object;

const CfgXPBoost = class'CfgXPBoost';
const CfgSrvRank = class'CfgSrvRank';

public static function UpdateGameSettings(KFGameInfo_Survival KFGI, string GameModeClass, MSKGS MSKGS)
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
					KFGI.MyKFGRI.bCustom = CfgSrvRank.default.bCustom;
				}
				else
				{
					KFGameSettings.NumWaves = KFGI.WaveMax - 1;
				}
				
				if (MSKGS == None || !MSKGS.XPNotifications || MSKGS.XPBoost <= 0)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName;
				}
				else if (MSKGS.XPBoost >= CfgXPBoost.default.MaxBoost)
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +" $ CfgXPBoost.default.MaxBoost $ "% XP";
				}
				else
				{
					KFGameSettings.OwningPlayerName = class'GameReplicationInfo'.default.ServerName $ " | +" $ MSKGS.XPBoost $ "% XP";
				}

				KFGameSettings.NumPublicConnections = KFGI.MaxPlayersAllowed;
				KFGameSettings.bRequiresPassword    = KFGI.RequiresPassword();
				KFGameSettings.bCustom              = CfgSrvRank.default.bCustom;
				KFGameSettings.bUsesStats           = CfgSrvRank.default.bUsesStats;
				KFGameSettings.NumSpectators        = KFGI.NumSpectators;
				
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

public static function class<KFPawn_Monster> PickProxyZed(class<KFPawn_Monster> MonsterClass, MSKGS MSKGS)
{
	local String SMC;
	local Name NMC;
	
	SMC = String(MonsterClass);
	NMC = Name(SMC);
	
	switch (MSKGS.XPBoost)
	{
		case 0:   return MonsterClass;
		case 10:  return PickProxyZed010(NMC, MonsterClass);
		case 20:  return PickProxyZed020(NMC, MonsterClass);
		case 30:  return PickProxyZed030(NMC, MonsterClass);
		case 40:  return PickProxyZed040(NMC, MonsterClass);
		case 50:  return PickProxyZed050(NMC, MonsterClass);
		case 60:  return PickProxyZed060(NMC, MonsterClass);
		case 70:  return PickProxyZed070(NMC, MonsterClass);
		case 80:  return PickProxyZed080(NMC, MonsterClass);
		case 90:  return PickProxyZed090(NMC, MonsterClass);
		case 100: return PickProxyZed100(NMC, MonsterClass);
		default:  return PickProxyZed100(NMC, MonsterClass);
	}
}

private static function class<KFPawn_Monster> PickProxyZed010(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_010';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_010';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_010';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_010';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_010';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_010';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_010';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_010';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_010';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_010';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_010';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_010';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_010';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_010';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_010';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_010';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_010';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_010';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_010';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_010';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_010';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_010';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_010';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_010';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_010';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_010';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_010';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_010';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_010';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_010';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_010';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_010';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_010';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_010';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_010';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_010';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_010';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_010';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_010';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_010';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_010';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_010';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed020(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_020';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_020';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_020';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_020';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_020';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_020';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_020';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_020';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_020';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_020';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_020';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_020';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_020';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_020';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_020';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_020';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_020';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_020';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_020';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_020';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_020';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_020';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_020';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_020';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_020';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_020';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_020';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_020';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_020';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_020';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_020';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_020';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_020';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_020';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_020';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_020';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_020';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_020';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_020';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_020';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_020';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_020';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed030(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_030';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_030';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_030';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_030';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_030';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_030';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_030';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_030';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_030';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_030';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_030';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_030';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_030';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_030';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_030';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_030';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_030';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_030';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_030';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_030';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_030';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_030';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_030';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_030';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_030';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_030';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_030';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_030';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_030';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_030';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_030';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_030';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_030';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_030';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_030';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_030';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_030';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_030';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_030';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_030';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_030';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_030';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed040(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_040';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_040';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_040';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_040';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_040';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_040';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_040';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_040';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_040';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_040';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_040';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_040';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_040';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_040';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_040';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_040';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_040';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_040';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_040';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_040';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_040';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_040';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_040';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_040';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_040';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_040';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_040';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_040';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_040';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_040';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_040';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_040';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_040';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_040';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_040';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_040';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_040';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_040';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_040';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_040';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_040';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_040';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed050(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_050';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_050';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_050';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_050';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_050';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_050';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_050';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_050';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_050';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_050';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_050';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_050';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_050';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_050';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_050';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_050';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_050';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_050';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_050';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_050';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_050';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_050';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_050';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_050';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_050';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_050';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_050';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_050';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_050';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_050';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_050';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_050';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_050';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_050';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_050';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_050';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_050';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_050';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_050';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_050';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_050';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_050';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed060(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_060';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_060';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_060';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_060';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_060';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_060';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_060';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_060';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_060';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_060';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_060';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_060';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_060';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_060';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_060';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_060';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_060';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_060';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_060';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_060';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_060';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_060';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_060';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_060';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_060';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_060';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_060';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_060';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_060';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_060';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_060';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_060';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_060';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_060';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_060';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_060';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_060';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_060';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_060';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_060';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_060';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_060';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed070(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_070';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_070';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_070';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_070';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_070';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_070';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_070';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_070';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_070';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_070';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_070';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_070';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_070';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_070';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_070';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_070';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_070';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_070';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_070';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_070';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_070';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_070';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_070';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_070';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_070';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_070';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_070';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_070';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_070';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_070';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_070';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_070';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_070';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_070';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_070';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_070';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_070';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_070';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_070';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_070';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_070';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_070';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed080(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_080';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_080';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_080';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_080';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_080';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_080';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_080';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_080';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_080';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_080';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_080';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_080';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_080';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_080';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_080';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_080';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_080';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_080';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_080';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_080';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_080';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_080';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_080';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_080';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_080';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_080';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_080';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_080';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_080';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_080';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_080';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_080';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_080';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_080';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_080';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_080';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_080';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_080';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_080';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_080';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_080';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_080';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed090(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_090';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_090';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_090';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_090';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_090';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_090';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_090';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_090';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_090';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_090';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_090';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_090';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_090';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_090';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_090';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_090';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_090';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_090';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_090';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_090';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_090';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_090';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_090';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_090';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_090';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_090';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_090';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_090';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_090';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_090';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_090';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_090';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_090';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_090';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_090';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_090';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_090';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_090';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_090';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_090';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_090';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_090';
		default:                                   return DefMonsterClass;
	}	
}

private static function class<KFPawn_Monster> PickProxyZed100(Name MonsterClass, class<KFPawn_Monster> DefMonsterClass)
{
	switch (MonsterClass)
	{
		case 'KFPawn_ZedBloat':                    return class'Proxy_KFPawn_ZedBloat_100';
		case 'KFPawn_ZedBloatKing':                return class'Proxy_KFPawn_ZedBloatKing_100';
		case 'KFPawn_ZedBloatKing_SantasWorkshop': return class'Proxy_KFPawn_ZedBloatKing_SantasWorkshop_100';
		case 'KFPawn_ZedBloatKingSubspawn':        return class'Proxy_KFPawn_ZedBloatKingSubspawn_100';
		case 'KFPawn_ZedClot_Alpha':               return class'Proxy_KFPawn_ZedClot_Alpha_100';
		case 'KFPawn_ZedClot_AlphaKing':           return class'Proxy_KFPawn_ZedClot_AlphaKing_100';
		case 'KFPawn_ZedClot_Cyst':                return class'Proxy_KFPawn_ZedClot_Cyst_100';
		case 'KFPawn_ZedClot_Slasher':             return class'Proxy_KFPawn_ZedClot_Slasher_100';
		case 'KFPawn_ZedCrawler':                  return class'Proxy_KFPawn_ZedCrawler_100';
		case 'KFPawn_ZedCrawlerKing':              return class'Proxy_KFPawn_ZedCrawlerKing_100';
		case 'KFPawn_ZedDAR':                      return class'Proxy_KFPawn_ZedDAR_100';
		case 'KFPawn_ZedDAR_EMP':                  return class'Proxy_KFPawn_ZedDAR_EMP_100';
		case 'KFPawn_ZedDAR_Laser':                return class'Proxy_KFPawn_ZedDAR_Laser_100';
		case 'KFPawn_ZedDAR_Rocket':               return class'Proxy_KFPawn_ZedDAR_Rocket_100';
		case 'KFPawn_ZedFleshpound':               return class'Proxy_KFPawn_ZedFleshpound_100';
		case 'KFPawn_ZedFleshpoundKing':           return class'Proxy_KFPawn_ZedFleshpoundKing_100';
		case 'KFPawn_ZedFleshpoundMini':           return class'Proxy_KFPawn_ZedFleshpoundMini_100';
		case 'KFPawn_ZedGorefast':                 return class'Proxy_KFPawn_ZedGorefast_100';
		case 'KFPawn_ZedGorefastDualBlade':        return class'Proxy_KFPawn_ZedGorefastDualBlade_100';
		case 'KFPawn_ZedHans':                     return class'Proxy_KFPawn_ZedHans_100';
		case 'KFPawn_ZedHusk':                     return class'Proxy_KFPawn_ZedHusk_100';
		case 'KFPawn_ZedMatriarch':                return class'Proxy_KFPawn_ZedMatriarch_100';
		case 'KFPawn_ZedPatriarch':                return class'Proxy_KFPawn_ZedPatriarch_100';
		case 'KFPawn_ZedScrake':                   return class'Proxy_KFPawn_ZedScrake_100';
		case 'KFPawn_ZedSiren':                    return class'Proxy_KFPawn_ZedSiren_100';
		case 'KFPawn_ZedStalker':                  return class'Proxy_KFPawn_ZedStalker_100';
		case 'WMPawn_ZedClot_Slasher_Omega':       return class'Proxy_WMPawn_ZedClot_Slasher_Omega_100';
		case 'WMPawn_ZedCrawler_Mini':             return class'Proxy_WMPawn_ZedCrawler_Mini_100';
		case 'WMPawn_ZedCrawler_Medium':           return class'Proxy_WMPawn_ZedCrawler_Medium_100';
		case 'WMPawn_ZedCrawler_Big':              return class'Proxy_WMPawn_ZedCrawler_Big_100';
		case 'WMPawn_ZedCrawler_Huge':             return class'Proxy_WMPawn_ZedCrawler_Huge_100';
		case 'WMPawn_ZedCrawler_Ultra':            return class'Proxy_WMPawn_ZedCrawler_Ultra_100';
		case 'WMPawn_ZedFleshpound_Predator':      return class'Proxy_WMPawn_ZedFleshpound_Predator_100';
		case 'WMPawn_ZedFleshpound_Omega':         return class'Proxy_WMPawn_ZedFleshpound_Omega_100';
		case 'WMPawn_ZedGorefast_Omega':           return class'Proxy_WMPawn_ZedGorefast_Omega_100';
		case 'WMPawn_ZedHusk_Tiny':                return class'Proxy_WMPawn_ZedHusk_Tiny_100';
		case 'WMPawn_ZedHusk_Omega':               return class'Proxy_WMPawn_ZedHusk_Omega_100';
		case 'WMPawn_ZedScrake_Tiny':              return class'Proxy_WMPawn_ZedScrake_Tiny_100';
		case 'WMPawn_ZedScrake_Omega':             return class'Proxy_WMPawn_ZedScrake_Omega_100';
		case 'WMPawn_ZedScrake_Emperor':           return class'Proxy_WMPawn_ZedScrake_Emperor_100';
		case 'WMPawn_ZedSiren_Omega':              return class'Proxy_WMPawn_ZedSiren_Omega_100';
		case 'WMPawn_ZedStalker_Omega':            return class'Proxy_WMPawn_ZedStalker_Omega_100';
		default:                                   return DefMonsterClass;
	}	
}

defaultproperties
{

}