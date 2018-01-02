FROM buildpack-deps:curl

ENV JFROG_CLI_OFFER_CONFIG=false
ENV JFROG_VERSION=1.13.1

RUN curl -kL \
    -o /usr/bin/jfrog \
    https://bintray.com/jfrog/jfrog-cli-go/download_file?file_path=${JFROG_VERSION}%2Fjfrog-cli-linux-amd64%2Fjfrog && \
    chmod +x /usr/bin/jfrog

WORKDIR /src
