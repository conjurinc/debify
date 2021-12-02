FROM ruby:2.6-stretch

RUN apt-get update -qq && \
    apt-get dist-upgrade -qqy && \
    apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl
    
# Install Docker client tools
ENV DOCKERVERSION=20.10.0
RUN curl -fsSLO https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKERVERSION}.tgz \
  && tar xzvf docker-${DOCKERVERSION}.tgz --strip 1 \
                 -C /usr/local/bin docker/docker \
  && rm docker-${DOCKERVERSION}.tgz

RUN mkdir -p /debify
WORKDIR /debify

COPY . ./

RUN gem install bundler:2.2.30
RUN gem build debify.gemspec

ARG VERSION
RUN gem install -N conjur-debify-${VERSION}.gem

ARG CONJUR_APPLIANCE_URL
ENV CONJUR_APPLIANCE_URL ${CONJUR_APPLIANCE_URL:-https://conjurops.itp.conjur.net}
ENV CONJUR_ACCOUNT ${CONJUR_ACCOUNT:-conjur}
ENV CONJUR_VERSION ${CONJUR_VERSION:-5}

ENTRYPOINT ["/debify/distrib/entrypoint.sh"]
