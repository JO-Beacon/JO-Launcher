#!/usr/bin/env python3
"""Export the Windows application icon (.ico) from the SVG master.

The .ico is a build product and is not tracked by git. Run this after changing
assets/icon/app-icon-plateless.svg:

    python tools/export-icons.py

Every frame is rasterised separately at its native pixel size through a
headless Edge/Chrome window -- no 1024px master is downscaled, so the 16-32px
frames keep clean edges.

Requirements: Python 3.8+, Pillow, and Edge or Chrome installed.
"""

from __future__ import annotations

import argparse
import io
import os
import shutil
import struct
import subprocess
import sys
import tempfile
from pathlib import Path

DEFAULT_SIZES = (16, 20, 24, 32, 40, 48, 64, 96, 128, 256)

BROWSERS = (
    r"C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Microsoft\Edge\Application\msedge.exe",
    r"C:\Program Files\Google\Chrome\Application\chrome.exe",
    r"C:\Program Files (x86)\Google\Chrome\Application\chrome.exe",
)

ROOT = Path(__file__).resolve().parent.parent


def find_browser() -> str | None:
    for candidate in BROWSERS:
        if os.path.isfile(candidate):
            return candidate
    for name in ("msedge", "chrome", "chromium", "google-chrome"):
        found = shutil.which(name)
        if found:
            return found
    return None


def render(svg: Path, size: int, workdir: Path, browser: str):
    from PIL import Image

    uri = svg.as_uri()
    html = workdir / f"frame-{size}.html"
    html.write_text(
        "<!doctype html><meta charset='utf-8'>"
        "<style>html,body{margin:0;padding:0;background:transparent;overflow:hidden}"
        f"img{{display:block;width:{size}px;height:{size}px}}</style>"
        f'<img src="{uri}">',
        encoding="utf-8",
    )
    shot = workdir / f"frame-{size}.png"
    cmd = [
        browser,
        "--headless=new",
        "--disable-gpu",
        "--hide-scrollbars",
        "--no-first-run",
        "--disable-extensions",
        "--force-device-scale-factor=1",
        "--default-background-color=00000000",
        f"--user-data-dir={workdir / '_profile'}",
        f"--window-size={size},{size}",
        f"--screenshot={shot}",
        html.as_uri(),
    ]
    result = subprocess.run(cmd, capture_output=True, timeout=120)
    if not shot.is_file():
        snippet = result.stderr.decode("utf-8", "replace")[:400]
        sys.exit(f"render failed at {size}px: {snippet}")
    image = Image.open(shot).convert("RGBA")
    if image.size != (size, size):
        image = image.resize((size, size), Image.LANCZOS)
    return image


def write_ico(images, path: Path) -> int:
    blobs = []
    for image in images:
        buffer = io.BytesIO()
        image.save(buffer, format="PNG", optimize=True)
        blobs.append(buffer.getvalue())

    header = struct.pack("<HHH", 0, 1, len(images))
    offset = 6 + 16 * len(images)
    entries = b""
    for image, blob in zip(images, blobs):
        width, height = image.size
        entries += struct.pack(
            "<BBBBHHII",
            0 if width >= 256 else width,
            0 if height >= 256 else height,
            0,
            0,
            1,
            32,
            len(blob),
            offset,
        )
        offset += len(blob)

    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(header + entries + b"".join(blobs))
    return path.stat().st_size


def contact_sheet(images, path: Path, gap: int = 8, pad: int = 8) -> None:
    from PIL import Image

    width = sum(image.size[0] for image in images) + gap * (len(images) - 1) + pad * 2
    height = max(image.size[1] for image in images) + pad * 2
    sheet = Image.new("RGBA", (width, height), (255, 255, 255, 255))
    x = pad
    for image in images:
        sheet.alpha_composite(image, (x, (height - image.size[1]) // 2))
        x += image.size[0] + gap
    sheet.save(path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Export the Windows .ico from an SVG master.")
    parser.add_argument(
        "--source",
        default=str(ROOT / "assets" / "icon" / "app-icon-plateless.svg"),
        help="square SVG or PNG master (default: assets/icon/app-icon-plateless.svg)",
    )
    parser.add_argument(
        "--out",
        default=str(ROOT / "platform" / "win32" / "app.ico"),
        help="output .ico path (default: platform/win32/app.ico)",
    )
    parser.add_argument(
        "--sizes",
        default=",".join(str(size) for size in DEFAULT_SIZES),
        help="comma separated frame sizes",
    )
    parser.add_argument("--preview", help="also write a size-ladder PNG here")
    args = parser.parse_args()

    try:
        from PIL import Image  # noqa: F401
    except ImportError:
        sys.exit("Pillow is required: python -m pip install pillow")

    source = Path(args.source).resolve()
    if not source.is_file():
        sys.exit(f"source not found: {source}")
    if source.suffix.lower() != ".svg":
        sys.exit("this script only rasterises SVG sources")
    sizes = [int(item) for item in args.sizes.split(",") if item.strip()]
    out = Path(args.out).resolve()

    browser = find_browser()
    if not browser:
        sys.exit("no Edge/Chrome found; install either one or export a PNG master by hand")

    print(f"source : {source}")
    print(f"output : {out}")
    print(f"frames : {'/'.join(map(str, sizes))}")

    workdir = Path(tempfile.mkdtemp(prefix="export-icons-"))
    try:
        images = [render(source, size, workdir, browser) for size in sorted(sizes)]
        written = write_ico(images, out)
        print(f"wrote  : {out.name}  {written} B  {len(images)} frames")
        if args.preview:
            contact_sheet(images, Path(args.preview).resolve())
            print(f"preview: {Path(args.preview).resolve()}")
    finally:
        shutil.rmtree(workdir, ignore_errors=True)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
