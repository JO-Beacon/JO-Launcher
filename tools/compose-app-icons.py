#!/usr/bin/env python3
"""Compose the finished application icons from the cube master.

`assets/icon/cube.svg` is the single source of the drawing: the isometric cube,
the offset band and the drop shadow, with no base plate. Every shipped icon is
built from it, so the geometry only ever lives in one file:

    assets/icon/cube.svg                 master (no plate, 256x256 canvas)
      -> assets/icon/app-icon.svg            dark plate
      -> assets/icon/app-icon-light.svg      light plate
      -> assets/icon/app-icon-plateless.svg  no plate, canvas cropped to the cube

Rebuild after changing the master or the plate colours:

    python tools/compose-app-icons.py

Verify without writing anything:

    python tools/compose-app-icons.py --check

The dark plate colours live in the master's own `bg` gradient, so they stay next
to the drawing; the light pair is the one thing defined here. The plateless icon
is the one the executable ships, so `tools/export-icons.py` builds the .ico from
it by default. All three are tracked files, so a stale one has to be caught.
"""

from __future__ import annotations

import argparse
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ICON_DIR = ROOT / "assets" / "icon"
MASTER = ICON_DIR / "cube.svg"

PLATE = '<rect width="256" height="256" fill="url(#bg)"/>'
TILE_OPEN = '<g clip-path="url(#tile)">'

# 无底版：母版 + 画布收紧。窗口数值来自透明底渲染的实测包围盒
# （绘制范围 x 41..215, y 26..219，四周各留 4.83）。
PLATELESS_WINDOW = (26.67, 21.17, 202.66, 202.66)
PLATELESS_TOLERANCE = 2.0

# 成品文件名 -> 类型（dark / light / plateless）
VARIANTS: tuple[tuple[str, str], ...] = (
    ("app-icon.svg", "dark"),
    ("app-icon-light.svg", "light"),
    ("app-icon-plateless.svg", "plateless"),
)

LIGHT_STOPS = (("#15181E", "#F3F5F9"), ("#0B0D11", "#E4E8F0"))


def drawing_bounds(master: str) -> tuple[float, float, float, float]:
    """Bounds of the drawing geometry, transforms included, clip paths ignored."""
    drawing = master.split("</defs>", 1)[-1]
    xs: list[float] = []
    ys: list[float] = []
    for match in re.finditer(r'<path\b[^>]*\bd="([^"]+)"', drawing):
        numbers = [float(value) for value in re.findall(r"-?\d+(?:\.\d+)?", match.group(1))]
        xs.extend(numbers[0::2])
        ys.extend(numbers[1::2])
    if not xs or len(xs) != len(ys):
        raise SystemExit("could not read the drawing geometry")
    padding = 0.0
    for match in re.finditer(r'transform="translate\(\s*(-?[\d.]+)[,\s]+(-?[\d.]+)?\s*\)"', drawing):
        for value in match.groups():
            if value is not None:
                padding = max(padding, abs(float(value)))
    return min(xs) - padding, min(ys) - padding, max(xs) + padding, max(ys) + padding


def compose(master: str, kind: str) -> str:
    """Build one icon: plate versions insert the base, the plateless one crops."""
    if master.count(TILE_OPEN) != 1:
        raise SystemExit(f"expected exactly one {TILE_OPEN} in the master, found {master.count(TILE_OPEN)}")
    if PLATE in master:
        raise SystemExit("the master already contains a base plate; it must be the plate-free drawing")

    if kind == "plateless":
        left, top, width, height = PLATELESS_WINDOW
        x0, y0, x1, y1 = drawing_bounds(master)
        if (
            x0 < left - PLATELESS_TOLERANCE
            or y0 < top - PLATELESS_TOLERANCE
            or x1 > left + width + PLATELESS_TOLERANCE
            or y1 > top + height + PLATELESS_TOLERANCE
        ):
            raise SystemExit(
                "PLATELESS_WINDOW no longer contains the drawing "
                f"(drawing {x0:.2f},{y0:.2f}..{x1:.2f},{y1:.2f}); re-measure it"
            )
        header = re.search(r"<svg\b[^>]*>", master)
        if header is None:
            raise SystemExit("no <svg> header in the master")
        tag = header.group(0)
        new_tag = re.sub(r'\bwidth="[^"]*"', f'width="{width:g}"', tag, count=1)
        new_tag = re.sub(r'\bheight="[^"]*"', f'height="{height:g}"', new_tag, count=1)
        new_tag = re.sub(r"\bviewBox=\"[^\"]*\"", f'viewBox="{left:g} {top:g} {width:g} {height:g}"', new_tag, count=1)
        if new_tag == tag:
            raise SystemExit("the master's <svg> tag has no width/height/viewBox to rewrite")
        text = master.replace(tag, new_tag, 1)
        ET.fromstring(text)
        if "#5C8CC9" not in text:
            raise SystemExit("the plateless icon lost the cube faces")
        return text

    text = master.replace(TILE_OPEN, TILE_OPEN + PLATE, 1)

    if kind == "light":
        for old, new in LIGHT_STOPS:
            found = text.count(f'stop-color="{old}"')
            if found != 1:
                raise SystemExit(f'expected one stop-color="{old}" in the master, found {found}')
            text = text.replace(f'stop-color="{old}"', f'stop-color="{new}"', 1)

    if text.count(PLATE) != 1:
        raise SystemExit("base plate was not inserted exactly once")
    ET.fromstring(text)  # result must still be valid XML
    if "#5C8CC9" not in text:
        raise SystemExit("the composed icon lost the cube faces")
    return text


def main() -> int:
    parser = argparse.ArgumentParser(description="Compose the app icons from the cube master.")
    parser.add_argument("--check", action="store_true", help="only verify the icons match the master")
    args = parser.parse_args()

    if not MASTER.is_file():
        raise SystemExit(f"missing master: {MASTER}")
    master = MASTER.read_text(encoding="utf-8")

    stale: list[str] = []
    for name, kind in VARIANTS:
        target = ICON_DIR / name
        composed = compose(master, kind).encode("utf-8")
        if args.check:
            if not target.is_file():
                stale.append(f"{name} is missing")
            elif target.read_bytes() != composed:
                stale.append(f"{name} does not match the master")
        else:
            target.write_bytes(composed)
            print(f"{name:24s} {len(composed)} B  ({kind})")

    if not args.check:
        print(f"master                 {len(master.encode('utf-8'))} B  ({MASTER.name})")
        return 0

    if stale:
        for problem in stale:
            print(f"stale: {problem}")
        print("run: python tools/compose-app-icons.py")
        return 1
    print("app icons are up to date")
    return 0


if __name__ == "__main__":
    sys.exit(main())
