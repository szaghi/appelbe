#!/usr/bin/env bash
# Run every reproduction driver built by `fobis build` (bin/appelbe_*) and plot results/ with gnuplot.
set -euo pipefail
cd "$(dirname "$0")/.."
for d in bin/appelbe_*; do
  echo "== $d"
  "./$d"
done
for g in scripts/*.gp; do
  echo "== gnuplot $g"
  gnuplot "$g"
done
