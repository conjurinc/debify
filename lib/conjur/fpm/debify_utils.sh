function bundle_clean() {
  ruby_version="$(ruby -v | grep -o '[0-9]\.[0-9]\.[0-9]')"

  chmod og+r -R vendor/bundle # some gems have broken perms

  gem install bundler:1.11.2 --no-rdoc --no-ri --install-dir ./vendor/bundle/ruby/${ruby_version}

  # some cleanup
  rm -rf vendor/bundle/ruby/${ruby_version}/cache
  rm -rf vendor/bundle/ruby/${ruby_version}/gems/*/{test,spec,examples,example,contrib,doc,ext,sample}
}
