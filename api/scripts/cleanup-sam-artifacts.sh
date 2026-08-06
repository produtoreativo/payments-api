#!/usr/bin/env bash
# cleanup-sam-artifacts.sh — removes all SAM deployment artifacts from S3,
# keeping only the most recent object per prefix (staging, experiment, production).
#
# This is a reference project — no deployment history needs to be retained.
# Run after a deploy to free storage, or periodically as maintenance.
#
# Usage:
#   bash api/scripts/cleanup-sam-artifacts.sh [--dry-run]
#
# Prerequisites: aws CLI authenticated with s3:ListBucket + s3:DeleteObject on
# the SAM-managed bucket (aws-sam-cli-managed-*).

set -euo pipefail

DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

log() { echo "[cleanup-sam-artifacts] $*"; }

# Discover the SAM-managed bucket for this account/region
BUCKET=$(aws s3 ls 2>/dev/null \
  | grep "aws-sam-cli-managed" \
  | awk '{print $3}' \
  | head -1)

if [[ -z "$BUCKET" ]]; then
  log "No aws-sam-cli-managed-* bucket found. Nothing to clean."
  exit 0
fi

log "Bucket: $BUCKET"

PREFIXES=("payments-api/staging" "payments-api/experiment" "payments-api/production")
TOTAL_DELETED=0

for PREFIX in "${PREFIXES[@]}"; do
  log "Scanning prefix: $PREFIX/"

  # List all objects under this prefix, sorted by LastModified ascending
  OBJECTS=$(aws s3api list-objects-v2 \
    --bucket "$BUCKET" \
    --prefix "$PREFIX/" \
    --query 'Contents[].{Key:Key,LastModified:LastModified}' \
    --output json 2>/dev/null \
    | python3 -c "
import sys, json
items = json.load(sys.stdin)
if not items:
    sys.exit(0)
items.sort(key=lambda x: x['LastModified'])
# Print all but the last (most recent)
for item in items[:-1]:
    print(item['Key'])
" 2>/dev/null || true)

  if [[ -z "$OBJECTS" ]]; then
    log "  Nothing to delete under $PREFIX/"
    continue
  fi

  COUNT=$(echo "$OBJECTS" | wc -l | tr -d ' ')
  log "  Found $COUNT old artifact(s) to delete"

  while IFS= read -r KEY; do
    if [[ "$DRY_RUN" == "true" ]]; then
      log "  [dry-run] would delete: $KEY"
    else
      aws s3 rm "s3://${BUCKET}/${KEY}" --quiet
      log "  deleted: $KEY"
      ((TOTAL_DELETED++))
    fi
  done <<< "$OBJECTS"
done

if [[ "$DRY_RUN" == "true" ]]; then
  log "Dry-run complete — no objects deleted."
else
  log "Done. Total deleted: $TOTAL_DELETED object(s)."
fi
