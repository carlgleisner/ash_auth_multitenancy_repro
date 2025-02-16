ARG ELIXIR_VERSION=1.18.1
ARG OTP_VERSION=27.2
ARG DEBIAN_VERSION=bullseye-20250113-slim

ARG IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
FROM ${IMAGE}

# This Dockerfile adds a non-root user with sudo access. Update the “remoteUser” property in
# devcontainer.json to use it. More info: https://aka.ms/vscode-remote/containers/non-root-user.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID

# Options for common package install script

# Settings for Phoenix
ARG PHOENIX_VERSION="1.7.19"

# Set environment variables
#
# The database is not on localhost but in the service db as defined in docker-compose.yml
ENV DATABASE_HOST=db
# Make container services reachable by binding to 0.0.0.0 instead of 127.0.0.1
ENV BIND_ADDRESS=0.0.0.0

# Install needed packages and setup non-root user. Use a separate RUN statement to add your own dependencies.
RUN apt-get update \
  && export DEBIAN_FRONTEND=noninteractive \
  && apt-get -y install --no-install-recommends curl ca-certificates 2>&1 \
  && apt-get install -y build-essential \
  && apt-get install -y inotify-tools dirmngr \
  && apt-get install -y postgresql-client \
  # && apt-get install -y xmlstarlet \
  # && apt-get -y install python3-pip \
  # && apt-get install -y inotify-tools gnupg2 dirmngr gpg gawk \
  # Clean up
  && apt-get autoremove -y \
  && apt-get clean -y \
  && rm -rf /var/lib/apt/lists/* /tmp/common-setup.sh /tmp/node-setup.sh

RUN mix local.hex --force \
  && mix local.rebar --force \
  && mix archive.install --force hex phx_new ${PHOENIX_VERSION}

RUN apt-get update \
  && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Phoenix framework conveniences
RUN echo "alias phx='mix phx.server'" >> /etc/bash.bashrc
RUN echo "alias ixs='iex -S mix phx.server'" >> /etc/bash.bashrc
RUN echo "alias ci='./ci.sh'" >> /etc/bash.bashrc
RUN echo "alias upd='mix deps.update --all'" >> /etc/bash.bashrc
RUN echo "alias nuke='rm -rf deps _build doc && mix deps.get && mix ash.reset'" >> /etc/bash.bashrc
