class MSKGS_GFxMoviePlayer_Manager_Versus extends KFGFxMoviePlayer_Manager_Versus
	dependson(MSKGS_GFxMenu_Perks, MSKGS_GFxMenu_Trader);

defaultproperties
{
	WidgetBindings.Remove((WidgetName="PerksMenu",WidgetClass=class'KFGFxMenu_Perks'))
	WidgetBindings.Add((WidgetName="PerksMenu",WidgetClass=class'MSKGS_GFxMenu_Perks'))
	
	WidgetBindings.Remove((WidgetName="traderMenu",WidgetClass=class'KFGFxMenu_Trader'))
	WidgetBindings.Add((WidgetName="traderMenu",WidgetClass=class'MSKGS_GFxMenu_Trader'))
}
