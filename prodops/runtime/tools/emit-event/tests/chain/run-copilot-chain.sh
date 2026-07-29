#!/usr/bin/env bash
# Bootstrap → Hack Chain Runner — Copilot player
# EXP-015 Iteration 6: Copilot must run this script independently.
#
# Usage:
#   bash run-copilot-chain.sh [--work-item-id <id>] [--iteration-id <id>]
#                             [--incomplete-hack] [--evidence-dir <dir>]

set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec bash "$SCRIPT_DIR/run-chain.sh" --player copilot "$@"
