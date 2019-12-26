# Build from the same version of ubuntu as phusion/baseimage
FROM ubuntu:18.04

RUN apt-get update -y && \
    apt-get install -y build-essential \
                       git \
                       libffi-dev \
                       libpq5 \
                       libpq-dev \
                       ruby2.5 \
                       ruby2.5-dev

RUN gem install --no-document bundler:1.17.3 \
                              fpm

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
    BUNDLE_BIN="$GEM_HOME/bin" \
    BUNDLE_SILENCE_ROOT_WARNING=1 \
    BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" && \
    chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

RUN mkdir /src

ENTRYPOINT [ "/package.sh" ]

COPY debify_utils.sh /
COPY package.sh      /
