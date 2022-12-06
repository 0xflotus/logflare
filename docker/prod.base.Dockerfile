FROM elixir:1.12

ENV MIX_ENV prod

COPY ./ /logflare
WORKDIR /logflare

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
RUN echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get update

RUN apt-get install -y nodejs yarn

RUN apt-get install tini

WORKDIR /logflare

RUN mix local.rebar --force
RUN mix local.hex --force

RUN mix deps.get
RUN mix compile

RUN cd /logflare/assets && yarn

WORKDIR /logflare
