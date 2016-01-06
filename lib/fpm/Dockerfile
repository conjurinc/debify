FROM ruby:2.0

RUN apt-get update -y && apt-get install -y build-essential

RUN gem install --no-rdoc --no-ri bundler fpm

RUN mkdir /src

COPY debify_utils.sh /
COPY package.sh      /

ENTRYPOINT [ "/package.sh" ]
