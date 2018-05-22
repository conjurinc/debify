function bundle_clean() {
  ruby_version="$(ruby -v | grep -o '[0-9]\.[0-9]\.[0-9]')"

  if [ -d vendor/bundle ]; then
    chmod og+r -R vendor/bundle # some gems have broken perms

    # some cleanup
    rm -rf vendor/bundle/ruby/${ruby_version}/cache
    rm -rf vendor/bundle/ruby/${ruby_version}/gems/*/{test,spec,examples,example,contrib,doc,ext,sample}
  fi
}

# Remove files from the current directory that also exist in another given
# directory. For example, say in the current directory there is:
#    foo
#    bar/baz
#    bar/xyzzy
#    bacon
#    people/phlebas
# and in dir2 there is
#    bacon
#    alice
#    people/phlebas
#    bar/xyzzy
# then after running `remove_matching dir2` current directory will be left with only:
#    foo
#    bar/baz
# Note it probably isn't 100% fool-proof, so don't launch it out to space or something.
function remove_matching() {
  find "$1" -type f -print0 | sed -ze "s@^$1@.@" | xargs -0 rm -f
  find . -type d -empty -delete
}
