#!/usr/bin/env bash
#
# Flutter runner that injects the backend server as --dart-define=API_BASE_URL,
# then runs flutter with whatever args you pass through.
#
# Backend server:
#   - default (any branch) -> PROD server (https://api.oclyx.com)
#   - APP_ENV=dev          -> DEV server  (https://api-dev.oclyx.com)
#
# Usage:
#   scripts/flutter_env.sh run                  # run on the PROD server
#   scripts/flutter_env.sh build apk --release
#   scripts/flutter_env.sh build ipa --release
#   APP_ENV=dev scripts/flutter_env.sh run      # run on the DEV server
set -euo pipefail

DEV_URL="https://api-dev.oclyx.com"
PROD_URL="https://api.oclyx.com"

env="${APP_ENV:-prod}"

if [[ "$env" == "dev" ]]; then
  base_url="$DEV_URL"
else
  base_url="$PROD_URL"
fi

echo "[flutter_env] env=${env} API_BASE_URL=${base_url}"
exec flutter "$@" --dart-define=API_BASE_URL="${base_url}"
