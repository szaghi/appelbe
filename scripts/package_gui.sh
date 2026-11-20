#!/usr/bin/env bash
# Package appelbe-gui for users (issue #2): the program built by `fobis build -f fobos-gui --mode gui-release-gnu`
# (bin/gui-release/), its README, an example f0 table and every licence, as one archive per platform:
#
#   linux    appelbe-gui-vX.Y.Z-linux-x86_64.tar.gz     appelbe-gui, README.txt, examples/, licenses/
#   macos    appelbe-gui-vX.Y.Z-macos-arm64.zip         appelbe-gui.app (Contents/MacOS, Info.plist, Resources), README.txt
#   windows  appelbe-gui-vX.Y.Z-windows-x86_64.zip      appelbe-gui.exe, README.txt, examples/, licenses/
#
# Usage: scripts/package_gui.sh [--version X.Y.Z] [--out DIR] [--binary FILE]
# Run from the repository root, after the release build. The platform is the running one (uname). Before archiving it
# checks that the program needs no library of the build machine: on Linux `ldd` lists only glibc's; on macOS
# `otool -L` lists only /usr/lib and /System (no Homebrew path); on Windows `objdump -p` lists only Windows' DLLs. A
# failed check stops the script (exit 1). The archive's name is printed on the last line.
set -euo pipefail

version=$(sed 's/^v//' VERSION)
out=build/package
binary=""
while [ $# -gt 0 ]; do
  case "$1" in
    --version) version="${2#v}"; shift 2 ;;
    --out)     out="$2"; shift 2 ;;
    --binary)  binary="$2"; shift 2 ;;
    -h|--help) sed -n '2,15p' "$0"; exit 0 ;;
    *) echo "package_gui.sh: unknown argument $1" >&2; exit 2 ;;
  esac
done

case "$(uname -s)" in
  Linux)                platform=linux ;;
  Darwin)               platform=macos ;;
  MINGW*|MSYS*|CYGWIN*) platform=windows ;;
  *) echo "package_gui.sh: unknown platform $(uname -s)" >&2; exit 2 ;;
esac
arch=$(uname -m)
case "$arch" in arm64|aarch64) arch=arm64 ;; x86_64|amd64) arch=x86_64 ;; esac
exe=appelbe-gui ; [ "$platform" = windows ] && exe=appelbe-gui.exe
[ -n "$binary" ] || binary="bin/gui-release/$exe"
[ -x "$binary" ] || { echo "package_gui.sh: no $binary: fobis build -f fobos-gui --mode gui-release-gnu first" >&2; exit 1; }
figure=src/gui/third_party/figure
[ -d "$figure/share/licenses" ] || { echo "package_gui.sh: no $figure/share/licenses: fobis fetch -f fobos-gui first" >&2; exit 1; }

name="appelbe-gui-v$version-$platform-$arch"
stage="$out/$name"
rm -rf "$stage"
mkdir -p "$stage"

fail() { echo "package_gui.sh: $*" >&2; exit 1; }

# the libraries the program loads must all be the system's
case "$platform" in
  linux)
    deps=$(ldd "$binary" | awk '{print $1}')
    bad=$(echo "$deps" | grep -v -E '^(linux-vdso\.so|/lib64/ld-linux|libc\.so|libm\.so|libmvec\.so|libdl\.so|libpthread\.so|librt\.so)' || true)
    [ -z "$bad" ] || fail "the program needs libraries a user may not have: $bad"
    glibc=$(objdump -T "$binary" | grep -o 'GLIBC_[0-9.]*' | sed 's/GLIBC_//' | sort -V -u | tail -1)
    requirement="Linux x86_64 with glibc $glibc or newer (ldd --version shows it), and a desktop with X11 or Wayland."
    start="Start: unpack the archive and run ./appelbe-gui (or double-click it in a file manager that runs programs)."
    ;;
  macos)
    deps=$(otool -L "$binary" | tail -n +2 | awk '{print $1}')
    bad=$(echo "$deps" | grep -v -E '^(/usr/lib/|/System/Library/)' || true)
    [ -z "$bad" ] || fail "the program needs libraries outside the system (Homebrew?): $bad"
    built_min=$(otool -l "$binary" | awk '/LC_BUILD_VERSION/{f=1} f&&/minos/{print $2; exit}')
    requirement="macOS $built_min or newer on Apple Silicon (arm64)."
    start=$(cat <<'TXT'
Start (the first time): unzip, move appelbe-gui.app to Applications, then
double-click it. macOS refuses it the first time ("cannot verify the
developer": the program is not signed by Apple). Then open System Settings >
Privacy & Security, scroll down to "appelbe-gui was blocked", and click Open
Anyway, then Open. From then on it opens with a double-click.
TXT
)
    ;;
  windows)
    deps=$(objdump -p "$binary" | awk '/DLL Name:/{print $3}')
    bad=$(echo "$deps" | grep -v -i -E '^(kernel32|user32|gdi32|winmm|imm32|ole32|oleaut32|version|advapi32|setupapi|shell32|ws2_32|uuid|opengl32|msvcrt|ucrtbase|cfgmgr32|dwmapi|shcore|comdlg32|bcrypt|api-ms-win-[a-z0-9-]+)\.dll$' || true)
    [ -z "$bad" ] || fail "the program needs DLLs a user may not have (MSYS2's?): $bad"
    requirement="Windows 10 or 11, x86_64."
    start=$(cat <<'TXT'
Start: unzip, then double-click appelbe-gui.exe. Windows may warn "Windows
protected your PC" (the program is not signed): click More info, then Run
anyway.
TXT
)
    ;;
esac
echo "libraries the program loads (all the system's):"
echo "$deps" | sed 's/^/  /'

# README, the example table, the licences
readme="$stage/README.txt"
# a plain loop, not awk -v: macOS's awk refuses a value of several lines (the start-up steps)
sed -e "s|@VERSION@|$version|g" -e "s|@PLATFORM@|$platform $arch|g" src/gui/share/README.txt \
  | while IFS= read -r line; do
      if [ "$line" = "@START@" ]; then
        printf 'Requires: %s\n\n%s\n' "$requirement" "$start"
      else
        printf '%s\n' "$line"
      fi
    done > "$readme"
mkdir -p "$stage/examples" "$stage/licenses/appelbe" "$stage/licenses/figure"
cp src/gui/share/f0_two_temperature.dat "$stage/examples/"
cp LICENSE.gpl3.md "$stage/licenses/appelbe/"
cp "$figure/LICENSE.mit.md" "$figure/THIRD_PARTY.md" "$stage/licenses/figure/"
cp -R "$figure/share/licenses/." "$stage/licenses/figure/"

case "$platform" in
  linux)
    cp "$binary" "$stage/appelbe-gui"
    archive="$out/$name.tar.gz"
    tar -C "$out" -czf "$archive" "$name"
    ;;
  windows)
    cp "$binary" "$stage/appelbe-gui.exe"
    archive="$out/$name.zip"
    (cd "$out" && python3 -m zipfile -c "$name.zip" "$name")
    ;;
  macos)
    app="$stage/appelbe-gui.app"
    mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
    cp "$binary" "$app/Contents/MacOS/appelbe-gui"
    sed -e "s|@VERSION@|$version|g" -e "s|@MACOS_MIN@|$built_min|g" src/gui/share/macos/Info.plist > "$app/Contents/Info.plist"
    # the examples and licences inside the bundle too: the .app alone is complete
    cp -R "$stage/examples" "$stage/licenses" "$readme" "$app/Contents/Resources/"
    # an ad-hoc signature of the whole bundle: unsigned by Apple, but consistent, so that macOS offers "Open Anyway"
    # instead of reporting the app as damaged
    codesign --force --deep --sign - "$app"
    codesign --verify --deep --strict "$app"
    archive="$out/$name.zip"
    (cd "$out" && ditto -c -k --keepParent "$name" "$name.zip")
    ;;
esac
echo "requires: $requirement"
echo "$archive"
