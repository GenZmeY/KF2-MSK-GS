class MskGsGFxMoviePlayer_Manager extends KFGFxMoviePlayer_Manager
	dependsOn(MskGsGFxMenu_Trader);

defaultproperties
{
	WidgetBindings.Remove((WidgetName="traderMenu",WidgetClass=class'KFGFxMenu_Trader'))
	WidgetBindings.Add((WidgetName="traderMenu",WidgetClass=class'MskGsGFxMenu_Trader'))
}
