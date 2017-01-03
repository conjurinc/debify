FROM ruby:2.2.6

RUN mkdir -p /src
WORKDIR /src

COPY Gemfile debify.gemspec /src/
COPY lib /src/lib/
RUN bundle install

COPY . /src/

ENTRYPOINT ["bundle", "exec", "debify"]
