function bundle_clean() {
  ruby_version="$(ruby -v | grep -o '[0-9]\.[0-9]\.[0-9]')"

  chmod og+r -R vendor/bundle # some gems have broken perms

  # some cleanup
  rm -rf vendor/bundle/ruby/${ruby_version}/cache
  rm -rf vendor/bundle/ruby/${ruby_version}/gems/*/{test,spec,examples,example,contrib,doc,ext,sample}
}
