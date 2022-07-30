FROM elixir:1.13-alpine AS builder

RUN mix local.hex --force
RUN mix local.rebar --force

ADD . /workspace/
WORKDIR /workspace

RUN MIX_ENV=prod mix deps.get
RUN MIX_ENV=prod mix release

FROM alpine:latest AS runner

RUN apk add --no-cache openssl ncurses-libs libgcc libstdc++

COPY --from=builder /workspace/_build/prod/rel/idlebot /opt/idlebot
ADD docker/docker-entrypoint.sh /docker-entrypoint.sh

VOLUME /config
ENV IDLEBOT_ENV_FILE="/config/idlebot.env"

ENTRYPOINT ["/bin/sh", "/docker-entrypoint.sh"]
CMD ["start"]
