#!/usr/bin/env python3
"""Finalize a rendered submission PDF with Korean document metadata."""

from __future__ import annotations

import argparse
from pathlib import Path

from pypdf import PdfWriter
from pypdf.generic import NameObject, TextStringObject


def finalize(input_path: Path, output_path: Path) -> None:
    writer = PdfWriter(clone_from=input_path)
    writer.root_object[NameObject("/Lang")] = TextStringObject("ko-KR")
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("wb") as output:
        writer.write(output)


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("input", type=Path)
    parser.add_argument("output", type=Path)
    args = parser.parse_args()
    finalize(args.input, args.output)
    print(args.output.resolve())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
