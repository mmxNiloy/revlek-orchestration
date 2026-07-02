#!/usr/bin/env bash

set -e  # Exit on error

PROJECT_NAME="revlek"
COMPOSE_FILE="docker-compose.yml"

echo "[1/4] Using project: ${PROJECT_NAME}"
echo "[2/4] Pulling latest images..."
docker compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" pull

echo "[3/4] Rebuilding and restarting containers..."
docker compose -f "${COMPOSE_FILE}" -p "${PROJECT_NAME}" up -d --build

echo "[4/4] Cleanup: Removing old, unused images..."
docker image prune -f

echo "✅ Services for '${PROJECT_NAME}' redeployed successfully!"