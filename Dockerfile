FROM ruby:3.2

RUN apt-get update -qq && \
    apt-get upgrade -qqy && \
    apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install Docker client tools
ENV DOCKERVERSION=24.0.2
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

# Install Docker buildx
RUN curl -fsSLO https://download.docker.com/linux/debian/dists/bookworm/pool/stable/amd64/docker-buildx-plugin_0.11.2-1~debian.12~bookworm_amd64.deb \
    && dpkg -i docker-buildx-plugin*.deb \
    && rm docker-buildx-plugin*.deb

WORKDIR /debify

COPY . ./

RUN gem install --no-document bundler:2.4.14 && \
    gem build debify.gemspec && \
    gem install --no-document -N conjur-debify-*.gem

ARG VERSION
ARG CONJUR_APPLIANCE_URL
ENV CONJUR_APPLIANCE_URL=${CONJUR_APPLIANCE_URL:-https://conjurops.itp.conjur.net} \
    CONJUR_ACCOUNT=${CONJUR_ACCOUNT:-conjur} \
    CONJUR_VERSION=${CONJUR_VERSION:-5}

ENTRYPOINT ["/debify/distrib/entrypoint.sh"]
