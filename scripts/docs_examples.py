"""Build and run the documentation examples, regenerating everything the pages include from them.

Layout (all under ``docs/examples/``):

- ``src/*.F90``: example programs (hand-written), with marker comments
  ``!run ID COMMAND`` (a run shown in the pages, its output captured) and ``!region NAME`` ... ``!endregion NAME``
  (a part of the program included on its own);
- ``snippets/``: generated, each source without the markers (``<stem>.F90``) and each region, dedented
  (``<stem>-<region>.F90``);
- ``output/``: generated, ``<ID>.txt`` holding ``$ COMMAND`` and the standard output and error of the run.

The library is built with ``fobis build --mode static-gnu`` (``lib/libappelbe.a``); each example is compiled against it, then
its runs happen in a scratch directory (``build/docs-examples``, git-ignored). The outputs depend on the sources only,
so a changed snippet or output in ``git diff`` means the documented behaviour changed.

Usage (from the repository root)::

    python3 scripts/docs_examples.py
"""

from __future__ import annotations

import logging
import os
import re
import shutil
import subprocess
from pathlib import Path

log = logging.getLogger(__name__)

ROOT = Path(__file__).resolve().parent.parent
EXAMPLES = ROOT / "docs" / "examples"
SOURCES = EXAMPLES / "src"
SNIPPETS = EXAMPLES / "snippets"
OUTPUT = EXAMPLES / "output"
BUILD = ROOT / "build" / "docs-examples"
FC = os.environ.get("FC", "gfortran")
FLAGS = ["-O2", "-frealloc-lhs", "-ffree-line-length-132"]

RUN = re.compile(r"^\s*!run\s+(\S+)\s+(.+)$")
REGION = re.compile(r"^\s*!(end)?region\s+(\S+)\s*$")


def library() -> Path:
    """Build the static library.

    Returns
    -------
    Path
        lib/libappelbe.a (its modules are in lib/mod).
    """
    subprocess.run(["fobis", "build", "--mode", "static-gnu"], cwd=ROOT, check=True, capture_output=True)
    return ROOT / "lib" / "libappelbe.a"


def split(source: Path) -> tuple[list[str], dict[str, list[str]], list[tuple[str, str]]]:
    """Strip the markers of an example and collect its regions and runs.

    Parameters
    ----------
    source : Path
        Example program.

    Returns
    -------
    tuple[list[str], dict[str, list[str]], list[tuple[str, str]]]
        Clean lines, region lines by name, (run id, command) pairs.
    """
    clean: list[str] = []
    regions: dict[str, list[str]] = {}
    open_regions: list[str] = []
    runs: list[tuple[str, str]] = []
    for line in source.read_text().splitlines():
        if match := RUN.match(line):
            runs.append((match.group(1), match.group(2)))
            continue
        if match := REGION.match(line):
            name = match.group(2)
            if match.group(1):
                open_regions.remove(name)
            else:
                open_regions.append(name)
                regions[name] = []
            continue
        clean.append(line)
        for name in open_regions:
            regions[name].append(line)
    if open_regions:
        raise SystemExit(f"docs_examples: {source.name}: unclosed regions {open_regions}")
    return clean, regions, runs


def dedent(lines: list[str]) -> list[str]:
    """Remove the common leading indentation.

    Parameters
    ----------
    lines : list[str]
        Lines.

    Returns
    -------
    list[str]
        Dedented lines.
    """
    width = min((len(x) - len(x.lstrip()) for x in lines if x.strip()), default=0)
    return [x[width:] for x in lines]


def main() -> None:
    """Regenerate snippets and outputs of every example."""
    logging.basicConfig(level=logging.INFO, format="%(message)s")
    archive = library()
    for directory in (SNIPPETS, OUTPUT):
        shutil.rmtree(directory, ignore_errors=True)
        directory.mkdir(parents=True)
    shutil.rmtree(BUILD, ignore_errors=True)
    (BUILD / "run").mkdir(parents=True)
    for source in sorted(SOURCES.glob("*.F90")):
        clean, regions, runs = split(source)
        (SNIPPETS / source.name).write_text("\n".join(clean) + "\n")
        for name, lines in regions.items():
            (SNIPPETS / f"{source.stem}-{name}.F90").write_text("\n".join(dedent(lines)) + "\n")
        program = BUILD / source.name
        program.write_text("\n".join(clean) + "\n")
        subprocess.run([FC, *FLAGS, "-J", str(BUILD), "-I", str(ROOT / "lib" / "mod"), str(program), str(archive),
                        "-o", str(BUILD / "run" / source.stem)], check=True, cwd=BUILD)
        for run_id, command in runs:
            result = subprocess.run(["bash", "-c", command], cwd=BUILD / "run", capture_output=True, text=True,
                                    check=False, env={"PATH": os.environ["PATH"], "LC_ALL": "C"})
            if result.returncode != 0:
                raise SystemExit(f"docs_examples: {run_id} failed:\n{result.stdout}{result.stderr}")
            (OUTPUT / f"{run_id}.txt").write_text(f"$ {command}\n{result.stdout}{result.stderr}")
            log.info("%s: %s", run_id, command)


if __name__ == "__main__":
    main()
