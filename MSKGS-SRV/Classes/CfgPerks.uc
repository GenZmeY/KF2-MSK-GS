class CfgPerks extends Object
	config(RPL)
	abstract;

var public  config bool bHideDisabledPerks;

var private config bool bBerserker;
var private config bool bCommando;
var private config bool bSupport;
var private config bool bFieldMedic;
var private config bool bDemolitionist;
var private config bool bFirebug;
var private config bool bGunslinger;
var private config bool bSharpshooter;
var private config bool bSwat;
var private config bool bSurvivalist;

public static function InitConfig(int Version, int LatestVersion, E_LogLevel LogLevel)
{
	switch (Version)
	{
		case `NO_CONFIG:
			ApplyDefault();
			
		default: break;
	}
	
	if (LatestVersion != Version)
	{
		StaticSaveConfig();
	}
}

public static function PerkAvailableData Load(E_LogLevel LogLevel)
{
	local PerkAvailableData PerkAvailableData;
	
	PerkAvailableData.bPerksAvailableLimited = PerksAvailableLimited();
	
	PerkAvailableData.bBerserkerAvailable     = default.bBerserker;
	PerkAvailableData.bCommandoAvailable      = default.bCommando;
	PerkAvailableData.bSupportAvailable       = default.bSupport;
	PerkAvailableData.bFieldMedicAvailable    = default.bFieldMedic;
	PerkAvailableData.bDemolitionistAvailable = default.bDemolitionist;
	PerkAvailableData.bFirebugAvailable       = default.bFirebug;
	PerkAvailableData.bGunslingerAvailable    = default.bGunslinger;
	PerkAvailableData.bSharpshooterAvailable  = default.bSharpshooter;
	PerkAvailableData.bSwatAvailable          = default.bSwat;
	PerkAvailableData.bSurvivalistAvailable   = default.bSurvivalist;
	
	return PerkAvailableData;
}

public static function bool Available(class<KFPerk> Perk)
{
	switch (Perk)
	{
		case class'KFPerk_Berserker':     return default.bBerserker;
		case class'KFPerk_Commando':      return default.bCommando;
		case class'KFPerk_Support':       return default.bSupport;
		case class'KFPerk_FieldMedic':    return default.bFieldMedic;
		case class'KFPerk_Demolitionist': return default.bDemolitionist;
		case class'KFPerk_Firebug':       return default.bFirebug;
		case class'KFPerk_Gunslinger':    return default.bGunslinger;
		case class'KFPerk_Sharpshooter':  return default.bSharpshooter;
		case class'KFPerk_SWAT':          return default.bSwat;
		case class'KFPerk_Survivalist':   return default.bSurvivalist;
		default: return true;
	}
}

private static function bool PerksAvailableLimited()
{
	return (
		!default.bBerserker     ||
		!default.bCommando      ||
		!default.bSupport       ||
		!default.bFieldMedic    ||
		!default.bDemolitionist ||
		!default.bFirebug       ||
		!default.bGunslinger    ||
		!default.bSharpshooter  ||
		!default.bSwat          ||
		!default.bSurvivalist);
}

private static function ApplyDefault()
{
	default.bHideDisabledPerks = true;
	
	default.bBerserker     = true;
	default.bCommando      = true;
	default.bSupport       = true;
	default.bFieldMedic    = true;
	default.bDemolitionist = true;
	default.bFirebug       = true;
	default.bGunslinger    = true;
	default.bSharpshooter  = true;
	default.bSwat          = true;
	default.bSurvivalist   = true;
}

defaultproperties
{
	
}
