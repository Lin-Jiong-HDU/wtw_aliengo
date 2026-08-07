#!/bin/bash
# ============================================================
# WTW AlienGo Training Script
# Usage: bash run_train.sh
# ============================================================

set -e

# ---- Paths ----
REPO_ROOT="/mnt/data/yc/lj/gym/wtw_aliengo_repo"
VENV="/mnt/data/yc/lj/gym/wtw_venv"
OSS_BACKUP="/mnt/oss/lj/wtw_aliengo"
RUN_DIR="$REPO_ROOT/runs"
LOG_DIR="$REPO_ROOT/logs"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DEST="$OSS_BACKUP/$TIMESTAMP"

mkdir -p "$LOG_DIR" "$OSS_BACKUP" "$DEST"

# ---- Cleanup: always do a final sync on exit ----
sync_to_oss() {
    echo "[sync] Final sync to OSS..."
    cp "$LOG_DIR/train_$TIMESTAMP.log" "$DEST/" 2>/dev/null || true
    LATEST_RUN=$(ls -dt "$RUN_DIR"/gait-conditioned-agility/*/train_aliengo/*/ 2>/dev/null | head -1)
    if [ -n "$LATEST_RUN" ]; then
        mkdir -p "$DEST/run/"
        cp -r "$LATEST_RUN"/* "$DEST/run/" 2>/dev/null || true
        echo "[sync] Done: $DEST"
    fi
}
trap sync_to_oss EXIT

# ---- Background OSS sync every 5 minutes ----
(
    while true; do
        sleep 300  # 5 minutes
        echo "[sync] Periodic backup to OSS..."
        cp "$LOG_DIR/train_$TIMESTAMP.log" "$DEST/" 2>/dev/null || true
        LATEST_RUN=$(ls -dt "$RUN_DIR"/gait-conditioned-agility/*/train_aliengo/*/ 2>/dev/null | head -1)
        if [ -n "$LATEST_RUN" ]; then
            mkdir -p "$DEST/run/"
            cp -r "$LATEST_RUN"/* "$DEST/run/" 2>/dev/null || true
        fi
        echo "[sync] Backup done at $(date +%H:%M:%S)"
    done
) &
SYNC_PID=$!

# ---- Pull latest code ----
echo "[1/3] Pulling latest code..."
cd "$REPO_ROOT"
git pull

echo "[2/3] Starting training..."
echo "  Log:    $LOG_DIR/train_$TIMESTAMP.log"
echo "  OSS:    $DEST"
echo "  Sync interval: 5 min (PID=$SYNC_PID)"

# ---- Run training ----
cd "$REPO_ROOT"
"$VENV/bin/python" scripts/train_aliengo.py 2>&1 | tee "$LOG_DIR/train_$TIMESTAMP.log"

# ---- Training ended, kill sync and do final backup ----
kill $SYNC_PID 2>/dev/null || true
sync_to_oss
