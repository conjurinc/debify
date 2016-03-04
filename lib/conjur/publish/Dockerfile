FROM buildpack-deps:curl

RUN curl -kL \
    -o /usr/bin/art \
    https://bintray.com/artifact/download/jfrog/artifactory-cli-go/1.2.1/artifactory-cli-linux-amd64/art && \
    chmod +x /usr/bin/art

WORKDIR /src
