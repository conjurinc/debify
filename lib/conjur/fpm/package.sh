#!/bin/bash -ex

source /debify_utils.sh

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
dev_package_name=conjur-"$project_name"-dev_"$version"_amd64.deb

# Build dev package first
echo Building $dev_package_name
prefix=/src/opt/conjur/project
cp -al $prefix /dev-pkg
cd $prefix
bundle --without development test
bundle clean
cd /dev-pkg
find $prefix -type f | sed -e "s@^$prefix@.@" | xargs rm -f
find . -type d -empty -delete
bundle_clean

if [ `ls | wc -l` -eq 0 ]; then
  echo No dev dependencies, skipping dev package
else
  fpm -s dir -t deb -n conjur-$project_name-dev -v $version -C . \
    --maintainer "Conjur Inc." \
    --vendor "Conjur Inc." \
    --license "Proprietary" \
    --url "https://www.conjur.net" \
    --deb-no-default-config-files \
    --deb-user conjur \
    --deb-group conjur \
    --depends "conjur-$project_name = $version" \
    --prefix /opt/conjur/$project_name \
    --description "Conjur $project_name service - development files"
fi

echo Building $package_name

mv /src/opt/conjur/project /src/opt/conjur/$project_name

cd /src/opt/conjur/$project_name

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
	--description "Conjur $project_name service" \
	"$@"

ls -al *.deb
