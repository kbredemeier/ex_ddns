from elixir AS builder

ARG MIX_ENV=prod

MAINTAINER Kristopher Bredemeier <k.bredemeier@gmail.com>


RUN \
    apt-get update && \
    apt-get upgrade -y && \
    mix local.hex --force && \
    mix local.rebar --force

WORKDIR /app

COPY . .

RUN \
    mix deps.get && \
    mix release --env=$MIX_ENV


FROM alpine:latest

ARG MIX_ENV=prod

RUN \
    apk --no-cache --update upgrade && \
    apk add --no-cache --update \
      bash \
      ncurses-libs \
      zlib \
      openssl \
      ca-certificates

WORKDIR /app

# Copy build over from the builder container
COPY --from=builder /app/_build/$MIX_ENV/rel/ex_ddns .

CMD ["./bin/ex_ddns", "foreground"]

