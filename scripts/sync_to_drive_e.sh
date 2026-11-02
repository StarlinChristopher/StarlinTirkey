#!/usr/bin/env bash
set -Eeuo pipefail

SOURCE_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
DEST_ROOT="${DRIVE_SYNC_ROOT:-/mnt/e/StarlinTirkey/repository}"
LOG_DIR="/mnt/e/StarlinTirkey/logs"
LOG_FILE="${DRIVE_SYNC_LOG:-${LOG_DIR}/sync_$(date +%Y%m%d).log}"
LOCK_FILE="/mnt/e/StarlinTirkey/.repository-sync.lock"
DRY_RUN=()

if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=(--dry-run)
elif [[ $# -gt 0 ]]; then
  echo "Usage: $0 [--dry-run]" >&2
  exit 2
fi

if [[ ! -d /mnt/e ]]; then
  echo "Drive E: is not mounted at /mnt/e; refusing to sync." >&2
  exit 1
fi

mkdir -p "$DEST_ROOT" "$(dirname "$LOG_FILE")"
exec 9>"$LOCK_FILE"
if ! flock -n 9; then
  echo "A Drive E: repository sync is already running; skipping this run."
  exit 0
fi

{
  printf '[%s] Syncing %s to %s\n' "$(date --iso-8601=seconds)" "$SOURCE_ROOT" "$DEST_ROOT"
  rsync --archive --human-readable --itemize-changes "${DRY_RUN[@]}" \
    --exclude='.git' \
    --exclude='node_modules/' \
    --exclude='.venv/' \
    --exclude='__pycache__/' \
    --exclude='.cache/' \
    --exclude='.turbo/' \
    --exclude='dist/' \
    --exclude='build/' \
    --exclude='coverage/' \
    --include='.env.example' \
    --include='.env.*.example' \
    --exclude='.env' \
    --exclude='.env.*' \
    --exclude='*.pem' \
    --exclude='*.key' \
    --exclude='*.pfx' \
    --exclude='*.p12' \
    --exclude='*.secret' \
    --exclude='*.secrets' \
    --exclude='*.vhdx' \
    --exclude='*.sqlite' \
    --exclude='*.sqlite3' \
    --exclude='*.db' \
    --exclude='*.db-*' \
    --exclude='*.log' \
    --exclude='backups/' \
    --exclude='data/' \
    --exclude='DockerDesktopVMM/' \
    --exclude='OllamaModels/' \
    --exclude='ollama_models/' \
    --exclude='WSL/' \
    --exclude='Docker/wsl/' \
    "$SOURCE_ROOT/" "$DEST_ROOT/"
  printf '[%s] Sync completed; no destination files were deleted.\n' "$(date --iso-8601=seconds)"
} >>"$LOG_FILE" 2>&1
