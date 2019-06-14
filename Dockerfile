FROM alpine AS borg

ARG BORG_VERSION=1.1.10
ARG BORGMATIC_VERSION=1.3.6

# https://borgbackup.readthedocs.io/en/stable/installation.html#dependencies
RUN apk add --upgrade --no-cache \
      acl-dev \
      attr-dev \
      build-base \
      fuse-dev \
      python3-dev \
      linux-headers \
      openssl-dev

RUN python3 -m venv /app && /app/bin/pip install \
      borgbackup==${BORG_VERSION} \
      borgmatic==${BORGMATIC_VERSION} \
      llfuse \
      prometheus_client



FROM alpine
MAINTAINER nicph

RUN apk --update --no-cache add \
      libacl \
      libattr \
      fuse \
      openssl \
      python3 \
      openssh-client

COPY --from=borg /app /app
COPY env.sh /etc/profile.d/
COPY entrypoint borg_exporter /app/bin/

ENV BORG_BASE_DIR=/borg

VOLUME /borg
VOLUME /etc/borgmatic.d

ENTRYPOINT ["/app/bin/entrypoint"]
