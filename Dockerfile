FROM golang:1.23.0-bookworm AS server

WORKDIR /work

COPY go.mod main.go /work/

RUN GOOS=linux GOARCH=arm64 go build -o http-server main.go

FROM bitnami/git:2-debian-12 AS contents

WORKDIR /work

RUN git clone \
        --depth=1 \
        --single-branch --branch=master \
        --no-tags \
        "https://github.com/designmodo/html-website-templates.git"
RUN rm -rf html-website-templates/{.git,images} \
    declare rootDir dirname; while read -r rootDir; do \
      dirname="$(tr '[:upper:]' '[:lower:]' <<< "${rootDir%% *}")" ; \
      mv "/work/html-website-templates/${rootDir}" "/work/${dirname}"; \
    done < <(find /work/html-website-templates -maxdepth 1 -mindepth 1 -type d -exec basename {} \;) && \
    rm -rf html-website-templates && \
    find /work -type f \( -name '*.php' -o -name '*.txt' -o -name '*.url' \) -exec rm {} \; && \
    find /work -maxdepth 3 -type d | sort | tee /work/all.txt

FROM debian:bookworm-slim

EXPOSE 8080
WORKDIR /work
COPY --from=contents /work/landing     /work/doc
COPY                 favicon.ico       /work/doc/
COPY --from=server   /work/http-server /work/

ENTRYPOINT ["/work/http-server", "-p", "8080", "-d", "/work/doc"]
