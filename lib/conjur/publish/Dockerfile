FROM alpine:3.3

RUN apk --update upgrade && \
    apk add ca-certificates && \
    update-ca-certificates && \
    rm -rf /var/cache/apk/*

RUN wget -O /usr/bin/art \
    https://bintray.com/artifact/download/jfrog/artifactory-cli-go/1.2.1/artifactory-cli-linux-amd64/art && \
    chmod +x /usr/bin/art

WORKDIR /src
