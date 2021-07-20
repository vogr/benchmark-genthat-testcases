#!/usr/bin/env bash

docker create \
  --name gather_data \
  --mount "type=bind,src=/home/vogier/PRL-PRG/TestAll,dst=/app,readonly" \
  r_postgres
