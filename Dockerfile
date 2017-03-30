FROM ruby:2.2.6

RUN mkdir -p /src/lib/conjur/debify
WORKDIR /src

COPY Gemfile debify.gemspec /src/
COPY lib/conjur/debify/version.rb /src/lib/conjur/debify/version.rb
RUN bundle

COPY . /src/

ENTRYPOINT ["bundle", "exec", "debify"]
