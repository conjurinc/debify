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

for i in "$@"; do
  case $i in
  -ft=* | --file-type=*)
    file_type="${i#*=}"
    shift
    ;;
  --architecture=*)
    architecture="${i#*=}"
    shift
    ;;
  esac
done

if [ -z "$file_type" ]; then
  echo "No file type given. Using deb"
  file_type=deb
fi

if [ -z "$architecture" ]; then
  echo "No architecture given. Using amd64"
  file_type=amd64
fi

echo Project Name is $project_name
echo Version is $version
echo file_type is $file_type
echo architecture is $architecture
echo uname: $(uname -a)
echo params at the end are $@

# Build dev package first
prefix=/src/opt/conjur/project
cd $prefix
bundle config set --local deployment 'true' && \
bundle config set --local path 'vendor/bundle' && \
bundle
cp -al $prefix /dev-pkg
bundle config set --local without 'development test'
bundle clean
cd /dev-pkg
remove_matching $prefix
bundle_clean

if [ $(ls | wc -l) -eq 0 ]; then
  echo No dev dependencies, skipping dev package
else
  echo "Building conjur-$project_name-dev $file_type package"

  fpm \
    -s dir \
    -t $file_type \
    -a $architecture \
    -n conjur-$project_name-dev \
    -v $version \
    -C . \
    --maintainer "CyberArk Software, Inc." \
    --vendor "CyberArk Software, Inc." \
    --license "Proprietary" \
    --url "https://www.cyberark.com" \
    --deb-no-default-config-files \
    --deb-dist "whatever" \
    --$file_type-user conjur \
    --$file_type-group conjur \
    --depends "conjur-$project_name = $version" \
    --prefix /opt/conjur/$project_name \
    --description "Conjur $project_name service - development files"
fi

mv /src/opt/conjur/project /src/opt/conjur/$project_name

cd /src/opt/conjur/$project_name

bundle_clean

cd /src

mkdir -p opt/conjur/etc

/debify.sh

[ -d opt/conjur/"$project_name"/distrib ] && mv opt/conjur/"$project_name"/distrib /

echo "Building conjur-$project_name $file_type package"

fpm \
  -s dir \
  -t $file_type \
  -a $architecture \
  -n conjur-$project_name \
  -v $version \
  -C . \
  --maintainer "CyberArk Software, Inc." \
  --vendor "CyberArk Software, Inc." \
  --license "Proprietary" \
  --url "https://www.cyberark.com" \
  --config-files opt/conjur/etc \
  --deb-no-default-config-files \
  --deb-dist "whatever" \
  --$file_type-user conjur \
  --$file_type-group conjur \
  --description "Conjur $project_name service" \
  "$@"

ls -l
