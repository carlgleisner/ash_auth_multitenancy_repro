#!/bin/bash

# Somehow these directories were owned by root after upgrading to Elixir 1.18
sudo chown -R vscode /tmp/mix_lock
sudo chown -R vscode /tmp/mix_pubsub

# Mix
mix local.hex --force

mix local.rebar --force

mix archive.install hex phx_new --force

mix archive.install hex igniter_new --force
