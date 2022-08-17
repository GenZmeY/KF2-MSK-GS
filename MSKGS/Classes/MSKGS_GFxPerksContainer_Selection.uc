class MSKGS_GFxPerksContainer_Selection extends KFGFxPerksContainer_Selection;

var const Texture2D NegativeIcon;

function UpdatePerkSelection(byte SelectedPerkIndex)
{
 	local int Index;
	local GFxObject DataProvider;
	local GFxObject TempObj;
	local MSKGS_PlayerController MSKGSPC;
	local byte bTierUnlocked;
	local int UnlockedPerkLevel;
	local PerkInfo PerkInfo;

	MSKGSPC = MSKGS_PlayerController(GetPC());
	
	if (MSKGSPC == None) return;

	DataProvider = CreateArray();

	foreach MSKGSPC.PerkList(PerkInfo, Index)
	{
		class'KFPerk'.static.LoadTierUnlockFromConfig(PerkInfo.PerkClass, bTierUnlocked, UnlockedPerkLevel);
		TempObj = CreateObject("Object");
		TempObj.SetInt("PerkLevel", PerkInfo.PerkLevel);
		TempObj.SetString("Title",  PerkInfo.PerkClass.default.PerkName);
		if (MSKGSPC.IsPerkAllowed(PerkInfo))
		{
			TempObj.SetString("iconSource", "img://" $ PerkInfo.PerkClass.static.GetPerkIconPath());
			TempObj.SetBool("bPerkAllowed", true);
		}
		else
		{
			TempObj.SetString("iconSource", "img://" $ PathName(NegativeIcon));
			TempObj.SetBool("bPerkAllowed", false);
		}
		TempObj.SetBool("bTierUnlocked", bool(bTierUnlocked) && PerkInfo.PerkLevel >= UnlockedPerkLevel);
		DataProvider.SetElementObject(Index, TempObj);
	}

	SetObject("perkData", DataProvider);
	SetInt("SelectedIndex", SelectedPerkIndex);
	SetInt("ActiveIndex", SelectedPerkIndex);

	UpdatePendingPerkInfo(SelectedPerkIndex);
}

defaultproperties
{
	NegativeIcon = Texture2D'UI_VoiceComms_TEX.UI_VoiceCommand_Icon_Negative'
}