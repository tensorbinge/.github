#!/bin/sh
set -e
hugo version | grep -q 'v0\.166\.0' || {
  echo "Hugo 0.166.0 is required (found: $(hugo version | cut -d' ' -f1-2))"; exit 1
}
hugo --minify --gc
git add -A
git commit -m "${1:-Publish $(date +%F)}"
git push
