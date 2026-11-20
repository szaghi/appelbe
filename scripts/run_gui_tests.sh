#!/usr/bin/env bash
# Run the GUI's headless tests: every test_gui_* executable in DIR (default exe/gui), from the repository root (the
# tests read src/gui/share/). Build first: fobis build -f fobos-gui --mode gui-tests-gnu (exe/gui) or gui-tests-gnu-debug
# (exe/gui-debug). Prints PASS/FAIL per program and exits non-zero on any failure.
set -u
dir="${1:-exe/gui}"
pass=0; fail=0
shopt -s nullglob
tests=("$dir"/test_gui_*)
if [ ${#tests[@]} -eq 0 ]; then
  echo "no test_gui_* in $dir: build first (fobis build -f fobos-gui --mode gui-tests-gnu)" >&2
  exit 1
fi
for t in "${tests[@]}"; do
  [ -x "$t" ] || continue
  name=$(basename "$t")
  if "$t" > "$dir/$name.log" 2>&1; then
    echo "  PASS  $name"; pass=$((pass + 1))
  else
    echo "  FAIL  $name (log: $dir/$name.log)"; grep -E "^FAIL|Error|error" "$dir/$name.log" | head -5; fail=$((fail + 1))
  fi
done
echo
echo "$pass/$((pass + fail)) passed"
[ "$fail" -eq 0 ]
