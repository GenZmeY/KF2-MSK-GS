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
PercentEnd=200
PercentInc=10

function modded_xp () # $1: XP, $2: Percent
{
	local Scale=$(echo "scale=2; 1.0 + ${2}/100" | bc)
	printf "%.0f" $(echo "${1}*${Scale}" | bc)
}

function main ()
{
	local TmpDir
	local Index
	local DefProps
	
	if ! command -v bc &> /dev/null; then
		echo "Error: bc not found"
		return
	fi
	
	if ! [[ -d "$ProxiesDir" ]]; then mkdir "$ProxiesDir"; fi
	
	TmpDir=$(mktemp -d)
	for ((Percent = PercentStart; Percent <= PercentEnd; Percent += PercentInc ))
	do
	(
		PercentStr=$(printf "%03d" $Percent)
		DefProps="$TmpDir/DefProps_${PercentStr}.dp"
		echo -e -n "\tXPBoosts.Add({(\n\t\tBoostValue=${Percent}" > "$DefProps"
		Index=0
		for Zed in $(find "$PawnsDir" -type f -iname '*.uc' -printf "%f\n" | grep -oP '.*(?=[.])' | sort)
		do
			ProxyZed="Proxy_${Zed}_${PercentStr}"
			TmpZed="$TmpDir/$ProxyZed.uc"
			cp "$PawnsDir/$Zed.uc" "$TmpZed"
			sed -i -r "s|class.+extends (.+);|class $ProxyZed extends \1;|g" "$TmpZed"
			grep -Po 'XPValues\(\d\)=(\d+)' "$TmpZed" | \
			while read XPValue
			do
				CurrentExp=$(echo "$XPValue" | sed -r 's|.+=([0-9]+)|\1|g')
				CurrentDiff=$(echo "$XPValue" | sed -r 's|.+\(([0-9])\).+|\1|g')
				ModdedXP=$(modded_xp "$CurrentExp" "$Percent")
				sed -i "s|$XPValue|XPValues($CurrentDiff)=$ModdedXP // $CurrentExp|g" "$TmpZed"
			done
			echo -e -n ",\n\t\tZeds[${Index}]={(ZedName=${Zed},Proxy=class'${ProxyZed}')}" >> "$DefProps"
			((Index+=1))
			mv -f "$TmpZed" "$ProxiesDir"
			echo "$ProxyZed"
		done
		echo -e -n "\n\t)})\n" >> "$DefProps"
	) &
	done
	wait
	
	echo -e -n 'defaultproperties\n{\n' > "$ScriptDir/ProxiesDefProps.uc"
	find "$TmpDir" -type f -iname '*.dp' -exec cat {} \; >> "$ScriptDir/ProxiesDefProps.uc"
	echo -e -n '}\n' >> "$ScriptDir/ProxiesDefProps.uc"
	
	rm -rf "$TmpDir"
	echo "Done"
}

main "$@"
