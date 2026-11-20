---
title: Install the GUI
---

# Install the GUI

`appelbe-gui` comes ready to run: one archive per system, attached to each
[release](https://github.com/szaghi/appelbe/releases). Nothing else needs installing: no compiler, no Homebrew, no
libraries. The archive holds the program, a `README.txt`, an example $f_0$ table (`examples/`) and the licences
(`licenses/`).

| System | Archive | Needs |
|---|---|---|
| macOS, Apple Silicon (M1 and later) | `appelbe-gui-vX.Y.Z-macos-arm64.zip` | macOS 15 Sequoia or newer |
| Windows | `appelbe-gui-vX.Y.Z-windows-x86_64.zip` | Windows 10 or 11, 64-bit |
| Linux | `appelbe-gui-vX.Y.Z-linux-x86_64.tar.gz` | 64-bit, glibc 2.38 or newer (Debian 13, Ubuntu 24.04, Fedora 39 and later), a desktop with X11 or Wayland |

The repository is private for now: the release's files download only for someone logged in to GitHub with access to
it.

## macOS

1. Download the `.zip` and double-click it: Finder unpacks it into a folder.
2. Move `appelbe-gui.app` from that folder to **Applications**.
3. Double-click it. The first time, macOS refuses to open it: *"appelbe-gui" cannot be opened because Apple cannot
   verify it*. The program is not signed by Apple (signing needs a paid Apple developer account); this message is
   what macOS shows for any such program downloaded from the internet. Click **Done** (not *Move to Trash*).
4. Open **System Settings → Privacy & Security**, scroll down to *Security*: it says *"appelbe-gui" was blocked to
   protect your Mac*. Click **Open Anyway**, confirm with your password or Touch ID, then **Open**.
5. From then on it opens with a double-click like any other program.

On macOS 15 Sequoia and later, a right click → *Open* no longer skips the refusal: step 4 is the way. A Mac with an Intel
processor cannot run this package (ask for an x86_64 build).

## Windows

1. Download the `.zip`, right click → **Extract All...**.
2. Double-click `appelbe-gui.exe` in the extracted folder.
3. The first time, Windows may show *Windows protected your PC* (SmartScreen: the program is not signed). Click
   **More info**, then **Run anyway**.

## Linux

```bash
tar xzf appelbe-gui-vX.Y.Z-linux-x86_64.tar.gz
cd appelbe-gui-vX.Y.Z-linux-x86_64
./appelbe-gui
```

`ldd --version` prints your glibc: the program needs the version in its `README.txt` or newer. With an older glibc it
stops at once with *version 'GLIBC_2.38' not found*; then [build it](gui#build) from the sources.

How to use it: [Using the GUI](gui-user), also in the program (**Help → User guide**).

## If something does not work

- `appelbe-gui --self-test` (from a terminal; on macOS
  `/Applications/appelbe-gui.app/Contents/MacOS/appelbe-gui --self-test`) checks the program without opening a window:
  each panel, a solve, a scan, a picture. It ends with `self-test: ok`, or names what failed.
- **No window, or a black one** (an old graphics driver without OpenGL 3, a remote desktop): run
  `appelbe-gui --remote 8080` and open the address it prints (with its access token) in a web browser on the same
  machine. The program is the same, drawn in the browser.
- To report a problem, send the session (**File → Save session...**) and the output of `--self-test`.
