FROM ruby:2.2.6

# Run Docker In Docker
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
# CMD ["wrapdocker"]

RUN mkdir -p /src
WORKDIR /src

COPY . ./

RUN gem build debify.gemspec
RUN gem install -N conjur-debify-1.6.0.gem

ENTRYPOINT ["wrapdocker", "debify"]
