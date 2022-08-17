class MSKGS_GFxMenu_Trader extends KFGFxMenu_Trader
	dependsOn(MSKGS_GFxTraderContainer_Store);

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'MSKGS_GFxTraderContainer_Store'))
}
