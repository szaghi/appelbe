#!/usr/bin/env bash
# Build the reproduction report: generate numbers/tables from results/ and compile report/appelbe_report.pdf.
# Run `fobis rule --ex figures` first so that results/ reflects the current code.
set -euo pipefail
cd "$(dirname "$0")/.."
for f in validation.dat solvers.dat convergence.dat fig2.dat fig3_summary.dat fig4.dat fig5_Te01keV.dat fig6.dat \
         sec5_advection.dat sec5_carbon.dat sec5_gradient.dat; do
  [[ -f "results/$f" ]] || { echo "results/$f missing: run 'fobis rule --ex figures' first" >&2; exit 1; }
done
python3 scripts/report_numbers.py
cd report
# force pdflatex: a user ~/.latexmkrc may remap $pdflatex (e.g. to xelatex)
latexmk -pdf -e '$pdflatex=q/pdflatex %O %S/' -interaction=nonstopmode -halt-on-error appelbe_report.tex
echo "report: report/appelbe_report.pdf"
