#!/bin/bash

# Whoami
ScriptFullname="$(readlink -e "$0")"
ScriptName="$(basename "$0")"
ScriptDir="$(dirname "$ScriptFullname")"

# Dirs
PawnsDir="$ScriptDir/Pawns"
ProxiesDir="$ScriptDir/Classes"

# Gen params
PercentStart=10
PercentEnd=100
PercentInc=10

function modded_xp () # $1: XP, $2: Percent
{
	local Scale=$(echo "scale=2; 1.0 + ${2}/100" | bc)
	printf "%.0f" $(echo "${1}*${Scale}" | bc)
}

function main ()
{
	local TmpDir
	
	if ! command -v bc &> /dev/null; then
		echo "Error: bc not found"
		return
	fi
	
	if ! [[ -d "$ProxiesDir" ]]; then mkdir "$ProxiesDir"; fi
	
	TmpDir=$(mktemp -d)
	for ((Percent = PercentStart; Percent <= PercentEnd; Percent += PercentInc ))
	do
		PercentStr=$(printf "%03d" $Percent)
		echo "$PercentStr"
		for Zed in $(find "$PawnsDir" -type f -iname '*.uc' -printf "%f\n" | grep -oP '.*(?=[.])')
		do
		(
			ProxyZed="Proxy_${Zed}_${PercentStr}"
			TmpZed="$TmpDir/$ProxyZed.uc"
			echo "$ProxyZed"
			cp "$PawnsDir/$Zed.uc" "$TmpZed"
			sed -i "s|$Zed|$ProxyZed|g" "$TmpZed"
			grep -Po 'XPValues\(\d\)=(\d+)' "$TmpZed" | \
			while read XPValue
			do
				CurrentExp=$(echo "$XPValue" | sed -r 's|.+=([0-9]+)|\1|g')
				CurrentDiff=$(echo "$XPValue" | sed -r 's|.+\(([0-9])\).+|\1|g')
				ModdedXP=$(modded_xp "$CurrentExp" "$Percent")
				sed -i "s|$XPValue|XPValues($CurrentDiff)=$ModdedXP // $CurrentExp|g" "$TmpZed"
			done
			mv -f "$TmpZed" "$ProxiesDir"
		) &
		done
		wait
	done

	rm -rf "$TmpDir"
	echo "Done"
}

main "$@"
