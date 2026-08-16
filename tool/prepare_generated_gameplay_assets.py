#!/usr/bin/env python3
"""Normalize generated gameplay sprites without changing their artwork.

Image generation occasionally returns an RGB PNG with a pure black matte even
when transparency was requested.  This tool removes only matte pixels connected
to the canvas edge, preserves enclosed dark outlines, downsizes with Lanczos,
and writes deterministic RGBA PNGs for the Flutter bundle.
"""

from __future__ import annotations

import argparse
from collections import deque
from pathlib import Path

from PIL import Image


def _edge_matte_mask(image: Image.Image, threshold: int = 34) -> bytearray:
    rgb = image.convert("RGB")
    width, height = rgb.size
    pixels = rgb.load()
    mask = bytearray(width * height)
    queue: deque[tuple[int, int]] = deque()

    def is_matte(pixel: tuple[int, int, int]) -> bool:
        darkest = min(pixel)
        lightest = max(pixel)
        is_black = lightest <= threshold
        is_checkerboard = darkest >= 178 and lightest - darkest <= 18
        return is_black or is_checkerboard

    def enqueue(x: int, y: int) -> None:
        index = y * width + x
        if mask[index] or not is_matte(pixels[x, y]):
            return
        mask[index] = 1
        queue.append((x, y))

    for x in range(width):
        enqueue(x, 0)
        enqueue(x, height - 1)
    for y in range(height):
        enqueue(0, y)
        enqueue(width - 1, y)

    while queue:
        x, y = queue.popleft()
        if x > 0:
            enqueue(x - 1, y)
        if x + 1 < width:
            enqueue(x + 1, y)
        if y > 0:
            enqueue(x, y - 1)
        if y + 1 < height:
            enqueue(x, y + 1)
    return mask


def normalize(source: Path, destination: Path, max_side: int) -> None:
    with Image.open(source) as original:
        rgba = original.convert("RGBA")
        # Some generators encode an opaque black matte even in an RGBA file,
        # while others return already-transparent black edge pixels.  Applying
        # the edge-connected mask in both cases safely handles both encodings.
        mask = _edge_matte_mask(original)
        alpha = rgba.getchannel("A")
        alpha_pixels = alpha.load()
        width, height = rgba.size
        for index, is_matte in enumerate(mask):
            if is_matte:
                alpha_pixels[index % width, index // width] = 0
        rgba.putalpha(alpha)
        rgba.thumbnail((max_side, max_side), Image.Resampling.LANCZOS)
        destination.parent.mkdir(parents=True, exist_ok=True)
        rgba.save(destination, format="PNG", optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("destination", type=Path)
    parser.add_argument("--max-side", type=int, default=768)
    args = parser.parse_args()
    normalize(args.source, args.destination, args.max_side)


if __name__ == "__main__":
    main()
