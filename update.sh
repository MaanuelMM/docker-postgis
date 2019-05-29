#!/bin/bash
# Derived from https://github.com/docker-library/postgres/blob/master/update.sh
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */Dockerfile )
fi
versions=( "${versions[@]%/Dockerfile}" )

travisEnv=
for version in "${versions[@]}"; do
	IFS=- read pg_major postgis_major <<< "$version"

	# Check on "https://github.com/postgis/postgis/releases" for the latest PostGIS 2.3.x release to assign to "srcVersion" variable
	srcVersion="2.3.9"
	srcSha256="$(curl -sSL "https://github.com/postgis/postgis/archive/$srcVersion.tar.gz" | sha256sum | awk '{ print $1 }')"
	jsonObjectPrivateSha256="$(curl -sSL "https://raw.githubusercontent.com/json-c/json-c/master/json_object_private.h" | sha256sum | awk '{ print $1 }')"

	(
		set -x
		cp Dockerfile.template initdb-postgis.sh update-postgis.sh README.md "$version/"
		mv "$version/Dockerfile.template" "$version/Dockerfile"
		sed -i 's/%%PG_MAJOR%%/'"$pg_major"'/g; s/%%POSTGIS_VERSION%%/'"$srcVersion"'/g; s/%%POSTGIS_SHA256%%/'"$srcSha256"'/g; s/%%JSON_OBJECT_PRIVATE_SHA256%%/'"$jsonObjectPrivateSha256"'/g' "$version/Dockerfile"
	)

	travisEnv='\n  - VERSION='"$version$travisEnv"
done
travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml
