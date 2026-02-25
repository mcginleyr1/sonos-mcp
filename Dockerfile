# Builder
FROM hexpm/elixir:1.19.5-erlang-28.3.2-debian-bookworm-20260223-slim AS builder

ENV MIX_ENV=prod

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

COPY config config
COPY lib lib
RUN mix compile && mix release

# Runner
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libstdc++6 libncurses5 libssl3 locales && \
    rm -rf /var/lib/apt/lists/* && \
    sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

COPY --from=builder /app/_build/prod/rel/sonos_mcp /app

ENV RELEASE_DISTRIBUTION=none
CMD ["/app/bin/sonos_mcp", "start"]
