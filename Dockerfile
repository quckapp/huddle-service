FROM elixir:1.15-alpine AS builder

WORKDIR /app

RUN apk add --no-cache build-base git

COPY mix.exs ./
RUN mix local.hex --force && mix local.rebar --force
RUN mix deps.get --only prod
RUN mix deps.compile

COPY config config
COPY lib lib

ENV MIX_ENV=prod
RUN mix compile
RUN mix release

FROM alpine:3.18

RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

COPY --from=builder /app/_build/prod/rel/huddle_service ./

ENV PORT=4005
EXPOSE 4005

CMD ["bin/huddle_service", "start"]
