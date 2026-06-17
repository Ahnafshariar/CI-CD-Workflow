#!/usr/bin/env bash
# =====================================================================
#  deploy.sh — deployment mechanism for the self-hosted runner.
#  Installs production dependencies and (re)starts the app under PM2,
#  then smoke-tests it. PM2 keeps the app running after the job ends.
# =====================================================================
set -euo pipefail

APP_NAME="ostad-node-app"
PORT="${PORT:-3000}"

echo "▶ Installing production dependencies..."
npm ci --omit=dev

echo "▶ (Re)starting '$APP_NAME' on port $PORT with PM2..."
pm2 delete "$APP_NAME" 2>/dev/null || true     # remove any previous instance
PORT="$PORT" pm2 start src/server.js --name "$APP_NAME"
pm2 save                                        # persist the process list

echo "▶ Smoke-testing the deployment..."
sleep 3
if curl -fsS "http://localhost:$PORT/api"; then
  echo ""
  echo "✓ Deployment successful — /api responded on port $PORT"
else
  echo "✗ Smoke test failed — the app is not responding on port $PORT" >&2
  pm2 logs "$APP_NAME" --lines 20 --nostream || true
  exit 1
fi
