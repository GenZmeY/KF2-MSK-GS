#!/bin/bash

OrigDir="./OrigKFPawnMonsters"

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
)

function modded_xp () # $1: XP, $2: Percent
{
	local Scale=$(echo "scale=2; 1.0 + ${2}/100" | bc)
	printf "%.0f" $(echo "${1}*${Scale}" | bc)
}

for Percent in 05 10 15 20 25 30 35 40 45 50
do
	echo $Percent
	for Zed in ${ZedList[*]}
	do
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
	done
done
