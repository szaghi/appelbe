#!/usr/bin/env bash
# Run every reproduction driver built by `fobis build` (exe/appelbe_*) and plot results/ with gnuplot.
set -euo pipefail
cd "$(dirname "$0")/.."
for d in exe/appelbe_*; do
  echo "== $d"
  "./$d"
done
for g in scripts/*.gp; do
  echo "== gnuplot $g"
  gnuplot "$g"
done
