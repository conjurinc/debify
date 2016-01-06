#!/bin/bash -ex

project_name=$1
shift
version=$1
shift

if [ -z "$project_name" ]; then
	echo Project name argument is required
	exit 1
fi
if [ -z "$version" ]; then
	echo Version argument is required
	exit 1
fi

package_name=conjur-"$project_name"_"$version"_amd64.deb

echo Building $package_name

mv /src/opt/conjur/project /src/opt/conjur/$project_name

cd /src/opt/conjur/$project_name

source /debify_utils.sh
bundle_clean

cd /src

mkdir -p opt/conjur/etc

/debify.sh

[ -d opt/conjur/"$project_name"/distrib ] && mv opt/conjur/"$project_name"/distrib /

fpm -s dir -t deb -n conjur-$project_name -v $version -C . \
	--maintainer "Conjur Inc." \
	--vendor "Conjur Inc." \
	--license "Proprietary" \
	--url "https://www.conjur.net" \
	--deb-no-default-config-files \
	--config-files opt/conjur/etc \
	--deb-user conjur \
	--deb-group conjur \
	--depends ruby2.0 \
	--description "Conjur $project_name service" \
	"$@"

ls -al *.deb

cp *.deb /dist/
