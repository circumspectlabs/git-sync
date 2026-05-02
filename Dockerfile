ARG GO_VERSION=1.26.2
ARG ALPINE_VERSION=3.23

FROM golang:${GO_VERSION}-alpine${ALPINE_VERSION} AS builder

RUN apk add --no-cache                          \
        git                                     \
        binutils                                \
        openssh-client

ARG GIT_SYNC_VERSION=4.6.0
RUN cd /tmp                                  && \
    git clone --depth 1 --branch v${GIT_SYNC_VERSION} https://github.com/kubernetes/git-sync && \
    cd git-sync                              && \
    go build -ldflags "-s -w -X '$(cat go.mod | head -1 | awk '{print $2}')/pkg/version.VERSION=${GIT_SYNC_VERSION}'" . && \
    strip -g -S -d --strip-debug ./git-sync  && \
    mv ./git-sync /usr/local/bin/git-sync    && \
    chmod 0755 /usr/local/bin/git-sync       && \
    /usr/local/bin/git-sync --version        && \
    /usr/local/bin/git-sync --help

ARG GOSU_VERSION=1.19
RUN cd /tmp                                  && \
    git clone --depth 1 --branch ${GOSU_VERSION} https://github.com/tianon/gosu && \
    cd gosu                                  && \
    go build -ldflags "-s -w" .              && \
    strip -g -S -d --strip-debug ./gosu      && \
    mv ./gosu /usr/local/bin/gosu            && \
    chmod 0755 /usr/local/bin/gosu           && \
    /usr/local/bin/gosu --version            && \
    /usr/local/bin/gosu --help

FROM alpine:${ALPINE_VERSION}

RUN apk add --no-cache                          \
        bash                                    \
        ca-certificates                         \
        curl                                    \
        git                                     \
        git-lfs                                 \
        openssh-client                       && \
    mkdir /.ssh /data                        && \
    chmod 0755 /.ssh /data                   && \
    chown 65534:65534 /.ssh /data

COPY --from=builder --chmod=0755 --chown=root:root /usr/local/bin/git-sync /usr/local/bin/git-sync
COPY --link --from=builder --chmod=0755 --chown=root:root /usr/local/bin/gosu /usr/local/bin/gosu
COPY --link --chown=root:root --chmod=0755 entrypoint.sh /usr/local/bin/entrypoint.sh

USER 65534:65534
ENTRYPOINT ["entrypoint.sh", "git-sync"]
CMD ["--help"]
