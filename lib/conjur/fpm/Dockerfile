# Build from the same version of ubuntu as phusion/baseimage
FROM cyberark/phusion-ruby-fips:0.11-latest

RUN apt-get update -y && \
    apt-get dist-upgrade -y && \
    apt-get install -y build-essential \
                       git \
                       libffi-dev \
                       rpm

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
