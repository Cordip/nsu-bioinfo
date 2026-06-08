#!/usr/bin/env python3
"""Extract mapped read percentage from `samtools flagstat` default output."""

from __future__ import annotations

import re
import sys
from pathlib import Path


MAPPED_RE = re.compile(
    r"^\d+\s+\+\s+\d+\s+mapped\s+\((?P<percent>\d+(?:\.\d+)?)%\s*:\s*[^)]*\)$"
)


def parse_mapped_percent(text: str) -> float:
    for line in text.splitlines():
        match = MAPPED_RE.match(line.strip())
        if match:
            return float(match.group("percent"))

    raise ValueError("mapped percentage line was not found")


def main(argv: list[str]) -> int:
    if len(argv) != 2:
        print(f"usage: {Path(argv[0]).name} FLAGSTAT_TXT", file=sys.stderr)
        return 2

    flagstat_path = Path(argv[1])

    try:
        mapped_percent = parse_mapped_percent(flagstat_path.read_text(encoding="utf-8"))
    except OSError as exc:
        print(f"failed to read {flagstat_path}: {exc}", file=sys.stderr)
        return 2
    except ValueError as exc:
        print(f"failed to parse {flagstat_path}: {exc}", file=sys.stderr)
        return 1

    print(f"{mapped_percent:.2f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main(sys.argv))
