#!/bin/sh
# Runs one SO3 measurement block (168 passes) of the A-B-B-A series:
# builds the given app in profile mode, drives the workflow via
# integration_test and writes the tap logs to LOG_DIR.
# usage: ./run-so3-block.sh <block-nr> <rfw|baseline>
#
# DEVICE is the id of the device to run on, logs go to <LOG_DIR>/so3-logs:
#   DEVICE=your-device-id ./run-so3-block.sh 1 rfw
BLOCK=$1
APP=$2
LOG_DIR="${LOG_DIR:-.}"
DEVICE="${DEVICE:?set your device id}"
mkdir -p "$LOG_DIR/so3-logs"
LOG="$(cd "$LOG_DIR/so3-logs" && pwd)/block${BLOCK}-${APP}.log"

cd "$(dirname "$0")/${APP}-client" || exit 1
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/so3_test.dart \
  --profile \
  --dart-define=SO3_PASSES=168 \
  -d "$DEVICE" 2>&1 | tee "$LOG"