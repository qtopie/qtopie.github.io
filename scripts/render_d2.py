#!/usr/bin/env python3
import argparse
import hashlib
import subprocess
from pathlib import Path
import sys


def build_output_name(code: str, theme: str) -> str:
    digest = hashlib.md5(f"{code}|theme={theme}".encode("utf-8")).hexdigest()
    return f"d2-{digest}.svg"


def read_code(input_file: str | None) -> str:
    if input_file:
        return Path(input_file).read_text(encoding="utf-8")
    return sys.stdin.read()


def compile_d2(code: str, d2_bin: str, theme: str, output_file: Path) -> None:
    output_file.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [d2_bin, "--theme", theme, "-", str(output_file)],
        input=code,
        text=True,
        check=True,
    )


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Render D2 to static/diagrams with Hugo-compatible hash name."
    )
    parser.add_argument("--theme", default="0", help="D2 theme id, default: 0")
    parser.add_argument(
        "--input-file",
        help="Read D2 source from file; if omitted, read from stdin",
    )
    parser.add_argument(
        "--static-dir",
        default="static/diagrams",
        help="Output directory for generated SVG files",
    )
    parser.add_argument("--d2-bin", default="d2", help="D2 CLI executable path")
    parser.add_argument(
        "--print-only",
        action="store_true",
        help="Only print target file path; do not run d2",
    )
    args = parser.parse_args()

    code = read_code(args.input_file)
    filename = build_output_name(code, args.theme)
    output_file = Path(args.static_dir) / filename

    if not args.print_only:
        compile_d2(code, args.d2_bin, args.theme, output_file)

    print(output_file.as_posix())
    return 0


if __name__ == "__main__":
    raise SystemExit(main())