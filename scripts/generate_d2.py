#!/usr/bin/env python3
import argparse
import hashlib
import os
import re
import subprocess
import sys
from pathlib import Path


def extract_d2_blocks(content: str) -> list[tuple[str, str]]:
    """
    Extracts (d2_code, theme) tuples from markdown content.
    Handles standard blocks, attribute blocks, and blocks nested in blockquotes/lists.
    """
    blocks = []
    lines = content.splitlines()
    in_block = False
    is_quoted = False
    curr_theme = "0"
    curr_lines = []

    # Matches opening code fence like:
    # ```d2
    # ```d2 {theme=1}
    # ```d2 theme="1"
    # > ```d2
    #    > ```d2
    fence_start_pattern = re.compile(
        r"^(?P<quote>\s*(?:>[ \t]*)+)?(?P<indent>[ \t]*)```d2(?P<header>[ \t]*\{[^}]*\}|[ \t]+.*)?\s*$"
    )
    fence_close_pattern = re.compile(r"^(?:\s*(?:>[ \t]*)+)?[ \t]*```\s*$")
    quote_prefix_pattern = re.compile(r"^\s*>+[ \t]?")

    for line in lines:
        if not in_block:
            m = fence_start_pattern.match(line)
            if m:
                in_block = True
                is_quoted = bool(m.group("quote"))
                header = m.group("header") or ""
                curr_theme = "0"
                tm = re.search(r"theme\s*=\s*\"?([^\s\"}]+)\"?", header)
                if tm:
                    curr_theme = tm.group(1)
                curr_lines = []
                continue
        else:
            if fence_close_pattern.match(line):
                code = "\n".join(curr_lines)
                blocks.append((code, curr_theme))
                in_block = False
                continue
            else:
                if is_quoted:
                    line = quote_prefix_pattern.sub("", line)
                curr_lines.append(line)

    return blocks


def normalize_d2_code(code: str) -> str:
    """Matches Hugo render-codeblock-d2.html normalization logic exactly."""
    # 1. Normalize line endings (\r\n -> \n, \r -> \n)
    c = code.replace("\r\n", "\n").replace("\r", "\n")
    # 2. Normalize tabs to 4 spaces
    c = c.replace("\t", "    ")
    # 3. Remove leading and trailing blank lines (Hugo: \A(?:[ \t]*\n)+ and (?:\n[ \t]*)+\z)
    c = re.sub(r"^(?:[ \t]*\n)+", "", c)
    c = re.sub(r"(?:\n[ \t]*)+$", "", c)
    return c


def compute_hash(normalized_code: str, theme: str) -> str:
    hash_input = f"{normalized_code}\n|theme={theme}"
    return hashlib.md5(hash_input.encode("utf-8")).hexdigest()


def process_file(
    md_path: Path, out_dir: Path, d2_bin: str
) -> tuple[set[str], int, int]:
    """
    Processes a single markdown file, compiles missing D2 SVGs.
    Returns (set of expected svg filenames, compiled_count, skipped_count).
    """
    expected_svgs = set()
    compiled = 0
    skipped = 0

    try:
        content = md_path.read_text(encoding="utf-8")
    except Exception as e:
        print(f"warn: failed to read {md_path}: {e}", file=sys.stderr)
        return expected_svgs, 0, 0

    blocks = extract_d2_blocks(content)
    for idx, (raw_code, theme) in enumerate(blocks, 1):
        norm_code = normalize_d2_code(raw_code)
        h = compute_hash(norm_code, theme)
        svg_filename = f"d2-{h}.svg"
        expected_svgs.add(svg_filename)
        svg_path = out_dir / svg_filename

        if svg_path.is_file():
            skipped += 1
            continue

        # Compile SVG
        try:
            out_dir.mkdir(parents=True, exist_ok=True)
            subprocess.run(
                [d2_bin, "--theme", theme, "-", str(svg_path)],
                input=norm_code,
                text=True,
                check=True,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.PIPE,
            )
            # Ensure permissions
            svg_path.chmod(0o644)
            print(f"gen:  {md_path}#{idx} (theme={theme}) -> {svg_filename}")
            compiled += 1
        except subprocess.CalledProcessError as e:
            err_msg = (
                e.stderr.decode("utf-8", errors="replace")
                if isinstance(e.stderr, bytes)
                else str(e.stderr)
            )
            print(
                f"error: failed to compile D2 in {md_path}#{idx}:\n{err_msg}",
                file=sys.stderr,
            )

    return expected_svgs, compiled, skipped


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate D2 diagram SVGs for Hugo.")
    parser.add_argument("files", nargs="*", help="Specific markdown files to process")
    parser.add_argument(
        "--root-dir",
        default=str(Path(__file__).resolve().parent.parent),
        help="Root directory of the project",
    )
    parser.add_argument(
        "--out-dir",
        help="Output directory for SVGs (default: <root>/static/diagrams)",
    )
    parser.add_argument("--d2-bin", default="d2", help="D2 executable path")
    parser.add_argument(
        "--no-cleanup", action="store_true", help="Do not remove unused SVG files"
    )
    args = parser.parse_args()

    root_dir = Path(args.root_dir).resolve()
    out_dir = (
        Path(args.out_dir).resolve()
        if args.out_dir
        else root_dir / "static" / "diagrams"
    )
    out_dir.mkdir(parents=True, exist_ok=True)

    if args.files:
        files = [Path(f).resolve() for f in args.files if Path(f).is_file()]
        is_full_scan = False
    else:
        # Full scan
        files = sorted(
            list(root_dir.glob("posts/**/*.md"))
            + list(root_dir.glob("content/**/*.md"))
        )
        is_full_scan = True

    all_expected_svgs: set[str] = set()
    total_compiled = 0
    total_skipped = 0

    for f in files:
        expected, comp, skip = process_file(f, out_dir, args.d2_bin)
        all_expected_svgs.update(expected)
        total_compiled += comp
        total_skipped += skip

    # Cleanup unused files only on full scan
    if is_full_scan and not args.no_cleanup:
        existing_svgs = {p.name for p in out_dir.glob("d2-*.svg")}
        unused = existing_svgs - all_expected_svgs
        if unused:
            print(f"Cleaning up {len(unused)} unused diagram(s)...")
            for u in sorted(unused):
                (out_dir / u).unlink(missing_ok=True)
                print(f"rm:   {u} (unused)")

    if total_compiled > 0:
        print(
            f"D2 generation complete: {total_compiled} compiled, {total_skipped} skipped."
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
