#!/usr/bin/env bash


# Run this script once to create the container

# Then use 
#     docker start dev-postgres
# to start it (detached)

# View output with
#     docker logs -f dev-postgres

# Start a bash session
#     docker exec -ti dev-postgres bash

docker create \
	--name dev-postgres \
	-e POSTGRES_PASSWORD=RProfiler \
	--mount "src=dev-postres-vol,dst=/var/lib/postgresql/data" \
  -p 5432:5432 \
  postgres
