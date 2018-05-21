FROM ruby:2.4

RUN apt-get update -y && \
    apt-get install -y build-essential git libpq5 libpq-dev libffi-dev && \
    rm -rf /var/lib/apt/lists/*

ENV BUNDLER_VERSION 1.11.2
ENV FPM_VERSION 1.9.3

RUN gem install --no-rdoc --no-ri bundler:$BUNDLER_VERSION fpm:$FPM_VERSION

ENV GEM_HOME /usr/local/bundle
ENV BUNDLE_PATH="$GEM_HOME" \
	BUNDLE_BIN="$GEM_HOME/bin" \
	BUNDLE_SILENCE_ROOT_WARNING=1 \
	BUNDLE_APP_CONFIG="$GEM_HOME"
ENV PATH $BUNDLE_BIN:$PATH
RUN mkdir -p "$GEM_HOME" "$BUNDLE_BIN" /src \
	&& chmod 777 "$GEM_HOME" "$BUNDLE_BIN"

COPY debify_utils.sh /
COPY package.sh      /

ENTRYPOINT [ "/package.sh" ]
