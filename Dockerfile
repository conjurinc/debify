FROM ruby:2.2.6

RUN mkdir -p /src
WORKDIR /src

COPY . ./

RUN gem build debify.gemspec
RUN gem install conjur-debify-1.6.0.gem

ENTRYPOINT ["debify"]
