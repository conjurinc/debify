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

# Build dev package first
prefix=/src/opt/conjur/project
cp -al $prefix /dev-pkg
cd $prefix
bundle --without development test
bundle clean
cp /usr/local/bundle/config .bundle/config # bundler for some reason stores config there...
cd /dev-pkg
remove_matching $prefix
bundle_clean

if [ `ls | wc -l` -eq 0 ]; then
  echo No dev dependencies, skipping dev package
else
  for file_type in deb rpm
  do
    echo "Building conjur-$project_name-dev $file_type package"

    fpm \
    -s dir \
    -t $file_type \
    -n conjur-$project_name-dev \
    -v $version \
    -C . \
    --maintainer "Conjur Inc." \
    --vendor "Conjur Inc." \
    --license "Proprietary" \
    --url "https://www.conjur.net" \
    --deb-no-default-config-files \
    --$file_type-user conjur \
    --$file_type-group conjur \
    --depends "conjur-$project_name = $version" \
    --prefix /opt/conjur/$project_name \
    --description "Conjur $project_name service - development files"
  done
fi

mv /src/opt/conjur/project /src/opt/conjur/$project_name

cd /src/opt/conjur/$project_name

bundle_clean

cd /src

mkdir -p opt/conjur/etc

/debify.sh

[ -d opt/conjur/"$project_name"/distrib ] && mv opt/conjur/"$project_name"/distrib /

for file_type in deb rpm
do
  echo "Building conjur-$project_name-dev $file_type package"

  fpm \
  -s dir \
  -t $file_type \
  -n conjur-$project_name \
  -v $version \
  -C . \
	--maintainer "Conjur Inc." \
	--vendor "Conjur Inc." \
	--license "Proprietary" \
	--url "https://www.conjur.net" \
	--config-files opt/conjur/etc \
	--deb-no-default-config-files \
	--$file_type-user conjur \
	--$file_type-group conjur \
	--description "Conjur $project_name service" \
	"$@"
done

ls -al *.{deb,rpm}
