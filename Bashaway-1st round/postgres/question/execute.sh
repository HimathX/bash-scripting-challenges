#!/bin/bash
docker rm -f postgres-bashaway 2>/dev/null || true
sleep 3
docker run -d --name postgres-bashaway \
  -e POSTGRES_PASSWORD=bashaway2025 \
  -e POSTGRES_DB=vectordb \
  -p 5432:5432 \
  postgres:16

sleep 15

docker exec postgres-bashaway sh -c "
apt-get update > /dev/null 2>&1
apt-get install -y postgresql-server-dev-16 git build-essential > /dev/null 2>&1
cd /tmp
git clone --branch v0.5.1 https://github.com/pgvector/pgvector.git > /dev/null 2>&1
cd pgvector
make > /dev/null 2>&1
make install > /dev/null 2>&1
"

sleep 10

docker exec postgres-bashaway psql -U postgres -d vectordb -c "CREATE EXTENSION vector"
docker exec postgres-bashaway psql -U postgres -d vectordb -c "CREATE TABLE embeddings (id SERIAL PRIMARY KEY, vec vector(3))"
docker exec postgres-bashaway psql -U postgres -d vectordb -c "INSERT INTO embeddings (vec) VALUES ('[1.0, 2.0, 3.0]'), ('[4.0, 5.0, 6.0]'), ('[7.0, 8.0, 9.0]')"
