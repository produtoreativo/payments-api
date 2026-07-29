#!/usr/bin/env bash
# Bootstrap → Hack Chain Runner — Codex player
# EXP-015 Iteration 6: Codex must run this script independently.
#
# Usage:
#   bash run-codex-chain.sh [--work-item-id <id>] [--iteration-id <id>]
#                           [--incomplete-hack] [--evidence-dir <dir>]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/run-chain.sh" --player codex "$@"
