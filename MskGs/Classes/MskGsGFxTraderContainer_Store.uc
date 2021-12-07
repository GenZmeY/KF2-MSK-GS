class MskGsGFxTraderContainer_Store extends KFGFxTraderContainer_Store;

/*
var bool GroupMember;
function Initialize(KFGFxObject_Menu NewParentMenu)
{
	local OnlineSubsystemSteamworks OnlineSub;
	local UniqueNetId GroupID;
	
	super.Initialize(NewParentMenu);
	
	OnlineSub = OnlineSubsystemSteamworks(class'GameEngine'.static.GetOnlineSubsystem());
	class'OnlineSubsystem'.Static.StringToUniqueNetId("0x017000000223386E", GroupID);
	GroupMember = OnlineSub.CheckPlayerGroup(GroupID);
}
*/

function bool IsItemFiltered(STraderItem Item, optional bool bDebug)
{
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.ClassName))
		return true;
	if (KFPC.GetPurchaseHelper().IsInOwnedItemList(Item.DualClassName))
		return true;
	if (!KFPC.GetPurchaseHelper().IsSellable(Item))
		return true;
	//if (!GroupMember && Item.WeaponDef.default.SharedUnlockId != SCU_None && !class'KFUnlockManager'.static.IsSharedContentUnlocked(Item.WeaponDef.default.SharedUnlockId))
	//	return true;
	if (Item.WeaponDef.default.PlatformRestriction != PR_All && class'KFUnlockManager'.static.IsPlatformRestricted(Item.WeaponDef.default.PlatformRestriction))
		return true;

   	return false;
}

defaultproperties
{
	
}
