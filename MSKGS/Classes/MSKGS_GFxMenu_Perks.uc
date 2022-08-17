class MSKGS_GFxMenu_Perks extends KFGFxMenu_Perks
	dependson(MSKGS_GFxPerksContainer_Selection);

function PerkChanged(byte NewPerkIndex, bool bClickedIndex)
{
	local KFGameReplicationInfo KFGRI;
	local MSKGS_PlayerController MSKGSPC;

	if (KFPC == None) return;

	KFGRI = KFGameReplicationInfo(KFPC.WorldInfo.GRI);
	MSKGSPC = MSKGS_PlayerController(KFPC);
	
	if (KFGRI == None || MSKGSPC == None) return;

	if (!MSKGSPC.IsPerkAllowed(MSKGSPC.PerkList[NewPerkIndex])) return;

	UpdateSkillsHolder(MSKGSPC.PerkList[NewPerkIndex].PerkClass);
	
	bChangesMadeDuringLobby = !IsMatchStarted();
		
	if (bClickedIndex)
	{
		LastPerkIndex = NewPerkIndex;
		bModifiedPerk = true;

		if (MSKGSPC.Pawn == None || !MSKGSPC.Pawn.IsAliveAndWell())
		{
			SavePerkData();
			SelectionContainer.SavePerk( NewPerkIndex );
			Manager.CachedProfile.SetProfileSettingValueInt( KFID_SavedPerkIndex, NewPerkIndex );
		}
	}
	
	UpdateContainers(MSKGSPC.PerkList[NewPerkIndex].PerkClass, bClickedIndex);
}

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="SelectionContainer",WidgetClass=class'KFGFxPerksContainer_Selection'))
	SubWidgetBindings.Add((WidgetName="SelectionContainer",WidgetClass=class'MSKGS_GFxPerksContainer_Selection'))
}
