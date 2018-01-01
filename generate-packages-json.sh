#!/usr/bin/env nix-shell
#!nix-shell -p python -p bash -i bash

PS4=' $ '

set -e
set -u
set -x

PUBLIC="$PWD/"

join() { local IFS="$1"; shift; echo -n "$*"; }

series_array() {
	# Eww...
	set +x
	echo -n '["'
	join , ${@} | sed 's/,/","/g'
	echo -n '"]'
	echo
	set -x
}

generate() {
	local NIXOS_SERIES="$1"
	shift
	local NIXPKGS="https://nixos.org/channels/nixos-${NIXOS_SERIES}/nixexprs.tar.xz"
	local FILENAME="packages-${NIXOS_SERIES}.json.gz"

	mkdir -p tmp
	(
	cd tmp

	nixpkgs=$(nix-instantiate --find-file nixpkgs -I nixpkgs="${NIXPKGS}")

	(echo -n '{ "commit": "' && cat $nixpkgs/.git-revision && echo -n '","packages":' \
	  && nix-env -f '<nixpkgs>' -I nixpkgs=${NIXPKGS} -qa --json --arg config '{allowUnfree = true;}' \
	  && echo -n '}') \
	  | sed "s|$nixpkgs/||g" | gzip -9 > "${FILENAME}.tmp"

	gunzip < "${FILENAME}.tmp" | python -mjson.tool > /dev/null

	mv "${FILENAME}.tmp" "${FILENAME}"
	mkdir -p "${PUBLIC}"
	mv "${FILENAME}" "${PUBLIC}/"
	)
	(
	cd "${PUBLIC}"
	gunzip -fk "${FILENAME}"
	)
}

SERIES=(
	#17.09
	#17.03
	unstable
)

for series in "${SERIES[@]}"; do
	generate "$series"
done

series_array "${SERIES[@]}" > ${PUBLIC}/packages_channels.json
