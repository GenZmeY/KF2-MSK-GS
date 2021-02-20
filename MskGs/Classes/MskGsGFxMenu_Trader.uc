class MskGsGFxMenu_Trader extends KFGFxMenu_Trader
	dependsOn(MskGsGFxTraderContainer_Store);

defaultproperties
{
	SubWidgetBindings.Remove((WidgetName="shopContainer",WidgetClass=class'KFGFxTraderContainer_Store'))
	SubWidgetBindings.Add((WidgetName="shopContainer",WidgetClass=class'MskGsGFxTraderContainer_Store'))
}
