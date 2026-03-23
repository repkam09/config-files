#!/bin/bash

docker pull caddy:builder
docker pull caddy:latest

docker run --rm -v ./Caddyfile:/etc/caddy/Caddyfile caddy:latest caddy fmt --overwrite /etc/caddy/Caddyfile

docker compose build && docker compose down && docker compose up -d
