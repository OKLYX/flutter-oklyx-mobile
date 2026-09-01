#!/usr/bin/env bash
#
# Branch-aware Flutter runner: resolves the backend server from the current git
# branch and injects it as --dart-define=API_BASE_URL, then runs flutter with
# whatever args you pass through.
#
# Branch -> backend server:
#   - main                     -> existing/original API server (http://100.77.112.35:8083)
#   - everything else (local,
#     develop, feature/*)      -> DEV server (https://api-dev.oclyx.com)
#
# Only a build/deploy off `main` points the app at the existing production
# server; every other branch (and local dev) stays on the DEV server.
#
# Usage:
#   scripts/flutter_env.sh run                  # run on the DEV server (unless on main)
#   scripts/flutter_env.sh build apk --release  # build; picks server from branch
#   scripts/flutter_env.sh build ipa --release
#
# Override the branch detection explicitly when needed:
#   APP_ENV=prod scripts/flutter_env.sh build apk --release
#   APP_ENV=dev  scripts/flutter_env.sh run
set -euo pipefail

DEV_URL="https://api-dev.oclyx.com"
PROD_URL="http://100.77.112.35:8083"

# Resolve environment: explicit APP_ENV wins, otherwise derive from git branch.
env="${APP_ENV:-}"
if [[ -z "$env" ]]; then
  branch="$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo unknown)"
  if [[ "$branch" == "main" ]]; then
    env="prod"
  else
    env="dev"
  fi
fi

if [[ "$env" == "prod" ]]; then
  base_url="$PROD_URL"
else
  base_url="$DEV_URL"
fi

echo "[flutter_env] branch=${branch:-<APP_ENV override>} env=${env} API_BASE_URL=${base_url}"
exec flutter "$@" --dart-define=API_BASE_URL="${base_url}"
