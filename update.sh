#!/bin/bash
# Derived from https://github.com/docker-library/postgres/blob/master/update.sh
set -e

cd "$(dirname "$(readlink -f "$BASH_SOURCE")")"

versions=( "$@" )
if [ ${#versions[@]} -eq 0 ]; then
	versions=( */Dockerfile )
fi
versions=( "${versions[@]%/Dockerfile}" )

packagesUrl='http://apt.postgresql.org/pub/repos/apt/dists/stretch-pgdg/main/binary-amd64/Packages'
packages="$(echo "$packagesUrl" | sed -r 's/[^a-zA-Z.-]+/-/g')"
curl -sSL "${packagesUrl}.bz2" | bunzip2 > "$packages"

travisEnv=
for version in "${versions[@]}"; do
	IFS=- read pg_major postgis_major <<< "$version"

	fullVersion="$(grep -m1 -A10 "^Package: postgresql-$pg_major-postgis-$postgis_major\$" "$packages" | grep -m1 '^Version: ' | cut -d' ' -f2)"
	[ -z "$fullVersion" ] && { echo >&2 "Unable to find package for PostGIS $postgis_major on Postgres $pg_major"; exit 1; }
	(
		set -x
		cp Dockerfile.template initdb-postgis.sh update-postgis.sh README.md "$version/"
		mv "$version/Dockerfile.template" "$version/Dockerfile"
		sed -i 's/%%PG_MAJOR%%/'$pg_major'/g; s/%%POSTGIS_MAJOR%%/'$postgis_major'/g; s/%%POSTGIS_VERSION%%/'$fullVersion'/g' "$version/Dockerfile"
	)

	travisEnv='\n  - VERSION='"$version$travisEnv"
done
travis="$(awk -v 'RS=\n\n' '$1 == "env:" { $0 = "env:'"$travisEnv"'" } { printf "%s%s", $0, RS }' .travis.yml)"
echo "$travis" > .travis.yml

rm "$packages"
