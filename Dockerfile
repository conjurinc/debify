FROM ruby:2.6

### DockerInDocker support is take from
### https://github.com/jpetazzo/dind/blob/master/Dockerfile . I
### elected to base this image on ruby, then pull in the (slightly
### outdated) support for DockerInDocker. Creation of the official
### docker:dind image much more complicated and didn't lend itself to
### also running ruby.

RUN apt-get update -qq && apt-get install -qqy \
    apt-transport-https \
    ca-certificates \
    curl \
    lxc \
    iptables
    
# Install Docker from Docker Inc. repositories.
RUN curl -sSL https://get.docker.com/ | sh

# Install the magic wrapper.
RUN curl -sSL -o /usr/local/bin/wrapdocker https://raw.githubusercontent.com/jpetazzo/dind/master/wrapdocker
RUN chmod +x /usr/local/bin/wrapdocker

# Define additional metadata for our image.
VOLUME /var/lib/docker

### End of DockerInDocker support

RUN mkdir -p /debify
WORKDIR /debify

COPY . ./

RUN gem build debify.gemspec

ARG VERSION
RUN gem install -N conjur-debify-${VERSION}.gem

ARG CONJUR_APPLIANCE_URL
ENV CONJUR_APPLIANCE_URL ${CONJUR_APPLIANCE_URL:-https://conjur-master-v2.itp.conjur.net/api}
ENV CONJUR_ACCOUNT ${CONJUR_ACCOUNT:-conjur}
ENV CONJUR_VERSION ${CONJUR_VERSION:-4}

ENTRYPOINT ["/debify/distrib/entrypoint.sh"]
