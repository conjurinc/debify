function bundle_clean() {
        chmod og+r -R vendor/bundle # some gems have broken perms

        gem install bundler --no-rdoc --no-ri --install-dir ./vendor/bundle/ruby/2.0.0

        # some cleanup
        rm -rf vendor/bundle/ruby/2.0.0/cache
        rm -rf vendor/bundle/ruby/2.0.0/gems/*/{test,spec,examples,example,contrib,doc,ext,sample}
        
        # Ruby 2.0 is ruby2.0 in ubuntu, fix shebangs
        sed -i -e '1 c #!/usr/bin/env ruby2.0' vendor/bundle/ruby/2.0.0/bin/*
}
