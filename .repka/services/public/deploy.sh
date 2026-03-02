#!/bin/bash

docker pull caddy:builder
docker compose build && docker compose down && docker compose up -d
