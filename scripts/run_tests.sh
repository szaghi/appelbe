#!/usr/bin/env bash
# Run every test program built by `fobis build` (exe/test_*); stop at the first failure.
set -euo pipefail
cd "$(dirname "$0")/.."
for t in exe/test_*; do
  echo "== $t"
  "./$t"
done
