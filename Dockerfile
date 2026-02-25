# Builder
FROM hexpm/elixir:1.19.5-erlang-28.3.2-debian-bookworm-20260223-slim AS builder

ENV MIX_ENV=prod

WORKDIR /app

RUN mix local.hex --force && mix local.rebar --force

COPY mix.exs mix.lock ./
RUN mix deps.get --only prod && mix deps.compile

COPY lib lib
RUN mix compile && mix release

# Runner
FROM debian:bookworm-slim

RUN apt-get update && \
    apt-get install -y --no-install-recommends libstdc++6 libncurses5 libssl3 && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /app/_build/prod/rel/sonosex /app

CMD ["/app/bin/sonosex", "start"]
