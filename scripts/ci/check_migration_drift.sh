#!/usr/bin/env bash
set -euo pipefail

# Requires: supabase CLI linked to target project (see migration-drift.yml).
# Fails when local migration files are not applied on the linked remote.

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

if [[ -z "${SUPABASE_ACCESS_TOKEN:-}" || -z "${SUPABASE_PROJECT_REF:-}" ]]; then
  echo "Skip: set SUPABASE_ACCESS_TOKEN and SUPABASE_PROJECT_REF repository secrets."
  exit 0
fi

if ! command -v supabase >/dev/null 2>&1; then
  echo "supabase CLI not found" >&2
  exit 1
fi

echo "Listing local vs remote migration status..."
list_output="$(supabase migration list --linked 2>&1)" || {
  echo "$list_output" >&2
  exit 1
}

echo "$list_output"

pending_local="$(
  echo "$list_output" \
    | awk 'NF >= 2 && $2 == "" && $1 ~ /^[0-9]{14}$/ { print $1 }'
)"

if [[ -n "$pending_local" ]]; then
  echo "Migration drift detected — local migrations not applied on remote:" >&2
  echo "$pending_local" >&2
  exit 1
fi

echo "No migration drift — linked remote matches local migration chain."
