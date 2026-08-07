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

# ---- Pull latest code ----
echo "[1/4] Pulling latest code..."
cd "$REPO_ROOT"
git pull

# ---- Setup timestamp ----
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
LOG_DIR="$REPO_ROOT/logs"
RUN_DIR="$REPO_ROOT/runs"
mkdir -p "$LOG_DIR" "$OSS_BACKUP"

echo "[2/4] Starting training..."
echo "  Log: $LOG_DIR/train_$TIMESTAMP.log"

# ---- Run training ----
cd "$REPO_ROOT"
"$VENV/bin/python" scripts/train_aliengo.py 2>&1 | tee "$LOG_DIR/train_$TIMESTAMP.log"

# ---- Copy results to OSS ----
echo ""
echo "[3/4] Training finished. Copying results to OSS..."
DEST="$OSS_BACKUP/$TIMESTAMP"
mkdir -p "$DEST"

# Copy log
cp "$LOG_DIR/train_$TIMESTAMP.log" "$DEST/"

# Copy the latest run directory (checkpoints + charts)
LATEST_RUN=$(ls -dt "$RUN_DIR"/gait-conditioned-agility/*/train_aliengo/*/ 2>/dev/null | head -1)
if [ -n "$LATEST_RUN" ]; then
    cp -r "$LATEST_RUN" "$DEST/run/"
    echo "  Checkpoints copied from: $LATEST_RUN"
else
    echo "  WARNING: No run directory found!"
fi

echo "[4/4] Done!"
echo "  Results saved to: $DEST"
ls -lh "$DEST/"
