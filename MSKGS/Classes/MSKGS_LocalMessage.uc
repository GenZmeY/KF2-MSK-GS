class MSKGS_LocalMessage extends Object;

enum E_MSKGS_LocalMessageType
{
	MSKGS_PlayerGiveBoostToServer,
	MSKGS_PlayerGiveBoostToServerFirst,
	MSKGS_PlayerGiveBoostToServerMax,
	MSKGS_BoosterLeaveServer,
	MSKGS_BoosterLeaveServerMax,
	MSKGS_BoosterLeaveServerNoBoost,
	
	MSKGS_AllowedLevels,
	MSKGS_UnsuitablePerksLocked,
	MSKGS_NoPerksDisconnect
};

var const             String PlayerGivesBoostDefault;
var private localized String PlayerGivesBoost;
var const             String PlayerGivesBoostFirstDefault;
var private localized String PlayerGivesBoostFirst;
var const             String TotalBoostDefault;
var private localized String TotalBoost;
var const             String MaxDefault;
var private localized String Max;
var const             String PlayerLeftDefault;
var private localized String PlayerLeft;
var const             String NoBoostDefault;
var private localized String NoBoost;

var const             String AllowedLevelsDefault;
var private localized String AllowedLevels;
var const             String UnsuitablePerksLockedDefault;
var private localized String UnsuitablePerksLocked;
var const             String NoPerksDisconnectDefault;
var private localized String NoPerksDisconnect;

private static function String ReplPlayer(String Str, String Player)
{
	return Repl(Str, "<player>", Player, false);
}

private static function String ReplPlayerBoost(String Str, String Boost)
{
	return Repl(Str, "<playerboost>", Boost, false);
}

private static function String ReplTotalBoost(String Str, String Boost)
{
	return Repl(Str, "<totalboost>", Boost, false);
}

private static function String ReplMinLevel(String Str, String MinLevel)
{
	return Repl(Str, "<minlevel>", MinLevel, false);
}

private static function String ReplMaxLevel(String Str, String MaxLevel)
{
	return Repl(Str, "<maxlevel>", MaxLevel, false);
}

private static function String ReplDisconnectTime(String Str, String DisconnectTime)
{
	return Repl(Str, "<disconnecttime>", DisconnectTime, false);
}

public static function String GetLocalizedString(
	E_LogLevel LogLevel,
	E_MSKGS_LocalMessageType LMT,
	optional String String1,
	optional String String2,
	optional String String3)
{
	local String RV;
	
	`Log_TraceStatic();
	
	RV = "";
	
	switch (LMT)
	{
		case MSKGS_PlayerGiveBoostToServer:
			RV = (default.PlayerGivesBoost != "" ? default.PlayerGivesBoost : default.PlayerGivesBoostDefault)
			   @ (default.TotalBoost != "" ? default.TotalBoost : default.TotalBoostDefault);
			RV = ReplPlayer(RV, String1);
			RV = ReplPlayerBoost(RV, String2);
			RV = ReplTotalBoost(RV, String3);
			break;
			
		case MSKGS_PlayerGiveBoostToServerFirst:
			RV = (default.PlayerGivesBoostFirst != "" ? default.PlayerGivesBoostFirst : default.PlayerGivesBoostFirstDefault)
			   @ (default.TotalBoost != "" ? default.TotalBoost : default.TotalBoostDefault);
			RV = ReplPlayer(RV, String1);
			RV = ReplTotalBoost(RV, String2);
			break;
			
		case MSKGS_PlayerGiveBoostToServerMax:
			RV = (default.PlayerGivesBoost != "" ? default.PlayerGivesBoost : default.PlayerGivesBoostDefault)
			   @ (default.TotalBoost != "" ? default.TotalBoost : default.TotalBoostDefault)
			   @ (default.Max != "" ? default.Max : default.MaxDefault);
			RV = ReplPlayer(RV, String1);
			RV = ReplPlayerBoost(RV, String2);
			RV = ReplTotalBoost(RV, String3);
			break;
			
		case MSKGS_BoosterLeaveServer:
			RV = (default.PlayerLeft != "" ? default.PlayerLeft : default.PlayerLeftDefault)
			   @ (default.TotalBoost != "" ? default.TotalBoost : default.TotalBoostDefault);
			RV = ReplPlayer(RV, String1);
			RV = ReplTotalBoost(RV, String2);
			break;
			
		case MSKGS_BoosterLeaveServerMax:
			RV = (default.PlayerLeft != "" ? default.PlayerLeft : default.PlayerLeftDefault)
			   @ (default.TotalBoost != "" ? default.TotalBoost : default.TotalBoostDefault)
			   @ (default.Max != "" ? default.Max : default.MaxDefault);
			RV = ReplPlayer(RV, String1);
			RV = ReplTotalBoost(RV, String2);
			break;
			
		case MSKGS_BoosterLeaveServerNoBoost:
			RV = (default.PlayerLeft != "" ? default.PlayerLeft : default.PlayerLeftDefault)
			   @ (default.NoBoost != "" ? default.NoBoost : default.NoBoostDefault);
			RV = ReplPlayer(RV, String1);
			break;
			
		case MSKGS_AllowedLevels:
			RV = (default.AllowedLevels != "" ? default.AllowedLevels : default.AllowedLevelsDefault);
			RV = ReplMinLevel(RV, String1);
			RV = ReplMaxLevel(RV, String2);
			break;
			
		case MSKGS_UnsuitablePerksLocked:
			RV = (default.UnsuitablePerksLocked != "" ? default.UnsuitablePerksLocked : default.UnsuitablePerksLockedDefault);
			break;
			
		case MSKGS_NoPerksDisconnect:
			RV = (default.NoPerksDisconnect != "" ? default.NoPerksDisconnect : default.NoPerksDisconnectDefault);
			RV = ReplDisconnectTime(RV, String1);
			break;
	}
	
	return RV;
}

defaultproperties
{
	PlayerGivesBoostFirstDefault = "<player> gives boost to this server!"
	PlayerGivesBoostDefault      = "<player> gives +<playerboost>% XP boost to this server!"
	TotalBoostDefault            = "Total XP boost: +<totalboost>%"
	MaxDefault                   = "(MAX)"
	PlayerLeftDefault            = "<player> left the server."
	NoBoostDefault               = "Now there is no XP boost."
	
	AllowedLevelsDefault         = "Allowed levels: <minlevel> - <maxlevel>"
	UnsuitablePerksLockedDefault = "Perks with unsuitable level are locked"
	NoPerksDisconnectDefault     = "You don't have perks with required level. Disconnect after <disconnecttime> seconds..."
}
