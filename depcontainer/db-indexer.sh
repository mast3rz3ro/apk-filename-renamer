#!/bin/env bash


f{()
{ # revision 2.1
# This function are licensed under GNU GPL-2.0-only
# Using this function will enforce you to follow the GNU GPL-2.0-only license.

	if [ "${1:0:1}" != "-" ]; then
		local x; local y
		for x in "${@:3}"; do
			if [ "$x" = "}" ]; then test "$1" "$2" "$y"; return
			elif [ "$x" != "AND" ] && [ "$x" != "OR" ]; then y="$x"; continue
			elif [ "$x" = "OR" ]; then if test "$1" "$2" "$y"; then return 0; else continue; fi
			elif [ "$x" = "AND" ]; then if test "$1" "$2" "$y"; then continue; else return 1; fi; fi
		done
	elif [ "${1:0:1}" = "-" ] && [ "${1:2:1}" = "" ]; then
		local y; x=
		for y in "${@:2}"; do
			if [ "$y" = "}" ]; then test "$1" "$x"; return
			elif [ "$y" != "AND" ] && [ "$y" != "OR" ]; then x="$y"; continue
			elif [ "$y" = "OR" ]; then if test "$1" "$x"; then return 0; else continue; fi
			elif [ "$y" = "AND" ]; then if test "$1" "$x"; then continue; else return 1; fi; fi
		done
	elif [ "${1:0:1}" = "-" ] && [ "${1:3:1}" = "" ]; then
		local y; x=""
		for y in "${@:2}"; do
			if [ "$y" = "}" ]; then test "${1:0:1}${1:1:1}" "$x" && test "${1:0:1}${1:2:1}" "$x"; return
			elif [ "$y" != "AND" ] && [ "$y" != "OR" ]; then x="$y"; continue
			elif [ "$y" = "OR" ]; then if test "${1:0:1}${1:1:1}" "$x" && test "${1:0:1}${1:2:1}" "$x"; then return 0; else continue; fi
			elif [ "$y" = "AND" ]; then if test "${1:0:1}${1:1:1}" "$x" && test "${1:0:1}${1:2:1}" "$x"; then continue; else return 1; fi; fi
		done
	else
		return 1
	fi
}


	f{ -f "./package-ids.json" OR "./depcontainer/package-ids.json" } && db="$x" || { echo "Error missing file: $x"; exit 1; }
	f{ -f "./ids.log" OR "./depcontainer/ids.log" } && ids="$x" || { echo "Missing file: $x"; exit 1; }

	echo "- Checking db header.." && f{ "$(jq 'has("pkg")' "$db")" = "false" OR "" } && echo "- Could not find object: '.pkg' creating new db: '${db}'" && echo '{"pkg":{}}' | jq . >"${db}"
	while read -r x; do
		if [ "$x" != "" ]; then
			if [ "$(jq --arg x "$x" '.pkg | has($x)' "$db")" = "false" ]; then
				echo "- Adding: '${x}'"
				tmp="$(mktemp)"
				jq --arg x "$x" '.pkg.[$x] = ["null", "null", 0]' "${db}" >"${tmp}" && mv "${tmp}" "${db}"
			else
				echo "- Skipping: '${x}'"
			fi
		fi
	done< <(cat "$ids")

