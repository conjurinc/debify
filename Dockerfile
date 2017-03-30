FROM ruby:2.2.6

RUN mkdir -p /src
WORKDIR /src

COPY . /src/
RUN bundle

ENTRYPOINT ["bundle", "exec", "debify"]
