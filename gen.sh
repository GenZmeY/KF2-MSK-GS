#!/bin/bash

OrigDir="./OrigKFPawnMonsters"
OutputDir="./GeneratedProxies"

ZedList=(
	"KFPawnProxy_ZedBloat"
	"KFPawnProxy_ZedBloatKing"
	"KFPawnProxy_ZedBloatKing_SantasWorkshop"
	"KFPawnProxy_ZedBloatKingSubspawn"
	"KFPawnProxy_ZedClot_Alpha"
	"KFPawnProxy_ZedClot_AlphaKing"
	"KFPawnProxy_ZedClot_Cyst"
	"KFPawnProxy_ZedClot_Slasher"
	"KFPawnProxy_ZedCrawler"
	"KFPawnProxy_ZedCrawlerKing"
	"KFPawnProxy_ZedDAR"
	"KFPawnProxy_ZedDAR_EMP"
	"KFPawnProxy_ZedDAR_Laser"
	"KFPawnProxy_ZedDAR_Rocket"
	"KFPawnProxy_ZedFleshpound"
	"KFPawnProxy_ZedFleshpoundKing"
	"KFPawnProxy_ZedFleshpoundMini"
	"KFPawnProxy_ZedGorefast"
	"KFPawnProxy_ZedGorefastDualBlade"
	"KFPawnProxy_ZedHans"
	"KFPawnProxy_ZedHusk"
	"KFPawnProxy_ZedMatriarch"
	"KFPawnProxy_ZedPatriarch"
	"KFPawnProxy_ZedScrake"
	"KFPawnProxy_ZedSiren"
	"KFPawnProxy_ZedStalker"
	"WMPawn_ZedClot_Slasher_Omega"
	"WMPawn_ZedCrawler_Mini"
	"WMPawn_ZedCrawler_Medium"
	"WMPawn_ZedCrawler_Big"
	"WMPawn_ZedCrawler_Huge"
	"WMPawn_ZedCrawler_Ultra"
	"WMPawn_ZedFleshpound_Predator"
	"WMPawn_ZedFleshpound_Omega"
	"WMPawn_ZedGorefast_Omega"
	"WMPawn_ZedHusk_Tiny"
	"WMPawn_ZedHusk_Omega"
	"WMPawn_ZedScrake_Tiny"
	"WMPawn_ZedScrake_Omega"
	"WMPawn_ZedScrake_Emperor"
	"WMPawn_ZedSiren_Omega"
	"WMPawn_ZedStalker_Omega"
)

rm -rf "$OutputDir" && mkdir -p "$OutputDir"

function modded_xp () # $1: XP, $2: Percent
{
	local Scale=$(echo "scale=2; 1.0 + ${2}/100" | bc)
	printf "%.0f" $(echo "${1}*${Scale}" | bc)
}

for Percent in 010 020 030 040 050 060 070 080 090 100
do
	echo $Percent
	for Zed in ${ZedList[*]}
	do
	(
		ProxyZed="${Zed}_${Percent}"
		echo $ProxyZed
		cp "$OrigDir/$Zed.uc" "$ProxyZed.uc"
		sed -i "s|$Zed|$ProxyZed|g" "$ProxyZed.uc"
		grep -Po 'XPValues\(\d\)=(\d+)' "$ProxyZed.uc" | \
		while read XPValue
		do
			CurrentExp=$(echo "$XPValue" | sed -r 's|.+=([0-9]+)|\1|g')
			CurrentDiff=$(echo "$XPValue" | sed -r 's|.+\(([0-9])\).+|\1|g')
			ModdedXP=$(modded_xp "$CurrentExp" "$Percent")
			sed -i "s|$XPValue|XPValues($CurrentDiff)=$ModdedXP // $CurrentExp|g" "$ProxyZed.uc"
		done
		mv -f "$ProxyZed.uc" "$OutputDir"
	) &
	done
done
