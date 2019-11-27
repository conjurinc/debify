# Build from the same version of ubuntu as phusion/baseimage
FROM ubuntu:18.04

RUN apt-get update -y && \
    apt-get install -y software-properties-common && \
    apt-add-repository -y ppa:brightbox/ruby-ng && \
    apt-get update -y && \
    apt-get install -y build-essential git libpq5 libpq-dev ruby2.3 ruby2.3-dev libffi-dev


# Configure bundler and gem the way the ruby:2.3 Dockerfile does, as of
# https://github.com/docker-library/ruby/blob/c88f3a67da720bfa9fb1717960d90fd5db11c757/2.3/Dockerfile#L41-L54
ENV BUNDLER_VERSION 1.11.2

RUN gem install --no-rdoc --no-ri bundler:$BUNDLER_VERSION ruby-xz:0.2.3 fpm

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN mkdir /src

ENTRYPOINT [ "/package.sh" ]

COPY debify_utils.sh /
COPY package.sh      /

