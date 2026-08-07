#!/usr/bin/env python3
"""Static integrity checks for the gp3ml paper workspace.

This script does not execute R. It verifies manuscript structure, citations,
portable paths, local file references, code delimiters, and optional Pandoc
parsing. Runtime package and manuscript checks remain the responsibility of
paper/R/validate-paper.R.
"""
from __future__ import annotations

import csv
import re
import shutil
import subprocess
import sys
from collections import Counter
from pathlib import Path

import yaml


PAPER_DIR = Path(__file__).resolve().parent
ROOT = PAPER_DIR.parent
RMD = PAPER_DIR / "gp3ml-paper.Rmd"
BIB = PAPER_DIR / "references.bib"


def report(name: str, status: str, detail: str) -> dict[str, str]:
    return {"check": name, "status": status, "detail": detail}


def strip_r_strings_and_comments(source: str) -> tuple[str, str]:
    output: list[str] = []
    state = "code"
    quote = ""
    i = 0
    while i < len(source):
        char = source[i]
        if state == "code":
            if char == "#":
                state = "comment"
                output.append(" ")
            elif char in {'"', "'", "`"}:
                state = "string"
                quote = char
                output.append(" ")
            else:
                output.append(char)
        elif state == "comment":
            if char == "\n":
                state = "code"
                output.append("\n")
            else:
                output.append(" ")
        else:
            if char == "\\":
                output.append(" ")
                i += 1
                if i < len(source):
                    output.append(" ")
            elif char == quote:
                state = "code"
                output.append(" ")
            elif char == "\n":
                output.append("\n")
            else:
                output.append(" ")
        i += 1
    return "".join(output), state


def balanced_r_delimiters(source: str) -> tuple[bool, str]:
    stripped, state = strip_r_strings_and_comments(source)
    if state != "code":
        return False, f"unterminated parser state: {state}"
    pairs = {")": "(", "]": "[", "}": "{"}
    stack: list[tuple[str, int]] = []
    for index, char in enumerate(stripped):
        if char in "([{":
            stack.append((char, index))
        elif char in ")]}":
            if not stack or stack[-1][0] != pairs[char]:
                return False, f"mismatched delimiter {char!r} at offset {index}"
            stack.pop()
    if stack:
        return False, f"{len(stack)} unclosed delimiter(s)"
    return True, "balanced after removing strings and comments"


def extract_chunks(lines: list[str]) -> tuple[list[tuple[str, str]], bool]:
    chunks: list[tuple[str, str]] = []
    active_label: str | None = None
    active_code: list[str] = []
    for line in lines:
        if active_label is None and line.startswith("```{r"):
            match = re.match(r"```\{r\s*([^,}\s]*)", line)
            active_label = match.group(1) if match else ""
            active_code = []
        elif active_label is not None and line.strip() == "```":
            chunks.append((active_label, "\n".join(active_code)))
            active_label = None
            active_code = []
        elif active_label is not None:
            active_code.append(line)
    return chunks, active_label is None


def bibliography_keys(text: str) -> set[str]:
    return set(re.findall(r"@[A-Za-z]+\s*\{\s*([^,\s]+)", text, flags=re.I))


def citation_keys(text: str) -> set[str]:
    # Restrict extraction to bracketed Pandoc citations so email addresses are
    # not mistaken for citation keys.
    keys: set[str] = set()
    for group in re.findall(r"\[([^\]]*@[A-Za-z0-9_:.\-]+[^\]]*)\]", text):
        keys.update(re.findall(r"@([A-Za-z0-9_:.\-]+)", group))
    return keys


def main() -> int:
    checks: list[dict[str, str]] = []
    try:
        rmd_text = RMD.read_text(encoding="utf-8")
        lines = rmd_text.splitlines()
        if not lines or lines[0] != "---":
            raise ValueError("missing opening YAML delimiter")
        yaml_end = lines[1:].index("---") + 1
        metadata = yaml.safe_load("\n".join(lines[1:yaml_end]))
        required = {"title", "abstract", "author", "output", "bibliography", "keywords"}
        missing = sorted(required - set(metadata))
        if missing:
            raise ValueError("missing YAML fields: " + ", ".join(missing))
        abstract_words = re.findall(r"\b[\w–-]+\b", metadata["abstract"])
        if not 180 <= len(abstract_words) <= 230:
            raise ValueError(f"abstract has {len(abstract_words)} words")
        checks.append(report("YAML and abstract", "passed", f"Valid metadata; abstract has {len(abstract_words)} words."))
    except Exception as error:  # noqa: BLE001
        checks.append(report("YAML and abstract", "failed", str(error)))
        lines = []
        rmd_text = ""

    chunks, closed = extract_chunks(lines)
    labels = [label for label, _ in chunks]
    duplicates = sorted(label for label, count in Counter(labels).items() if count > 1)
    if closed and labels and not duplicates and all(labels):
        checks.append(report("R chunk structure", "passed", f"{len(labels)} uniquely labelled chunks; all fences closed."))
    else:
        checks.append(report("R chunk structure", "failed", f"closed={closed}; duplicates={duplicates}; empty={labels.count('')}"))

    r_sources = sorted((PAPER_DIR / "R").glob("*.R")) + [ROOT / "install_gp3ml_paper_workspace.R"]
    delimiter_failures: list[str] = []
    for path in r_sources:
        ok, detail = balanced_r_delimiters(path.read_text(encoding="utf-8"))
        if not ok:
            delimiter_failures.append(f"{path.relative_to(ROOT)}: {detail}")
    combined_chunks = "\n".join(code for _, code in chunks)
    ok, detail = balanced_r_delimiters(combined_chunks)
    if not ok:
        delimiter_failures.append(f"paper/gp3ml-paper.Rmd chunks: {detail}")
    if delimiter_failures:
        checks.append(report("R delimiter audit", "failed", " | ".join(delimiter_failures)))
    else:
        checks.append(report("R delimiter audit", "passed", f"Balanced delimiters in {len(r_sources)} R scripts and all manuscript chunks."))

    bib_text = BIB.read_text(encoding="utf-8") if BIB.exists() else ""
    cited = citation_keys(rmd_text)
    defined = bibliography_keys(bib_text)
    missing_citations = sorted(cited - defined)
    uncited = sorted(defined - cited)
    brace_balance = bib_text.count("{") - bib_text.count("}")
    if not missing_citations and not uncited and brace_balance == 0:
        checks.append(report("Bibliography coverage", "passed", f"All {len(defined)} entries are cited and every citation is defined."))
    else:
        checks.append(report("Bibliography coverage", "failed", f"missing={missing_citations}; uncited={uncited}; brace_balance={brace_balance}"))

    required_paths = [
        PAPER_DIR / "references.bib",
        PAPER_DIR / "data" / "evidence.csv",
        PAPER_DIR / "R" / "helpers.R",
        PAPER_DIR / "R" / "case-study.R",
        PAPER_DIR / "R" / "render-paper.R",
        PAPER_DIR / "R" / "render-preview.R",
        PAPER_DIR / "R" / "validate-paper.R",
        PAPER_DIR / "motivation-letter" / "motivation-letter.md",
    ]
    missing_paths = [str(path.relative_to(ROOT)) for path in required_paths if not path.exists()]
    if missing_paths:
        checks.append(report("Workspace files", "failed", "Missing: " + ", ".join(missing_paths)))
    else:
        checks.append(report("Workspace files", "passed", f"All {len(required_paths)} required files are present."))

    path_text = "\n".join(path.read_text(encoding="utf-8") for path in [RMD, *r_sources])
    absolute = re.findall(r"[A-Za-z]:[/\\](?:Users|Documents)[^\n\"']*", path_text)
    if absolute:
        checks.append(report("Path portability", "failed", f"Absolute Windows path(s): {absolute[:3]}"))
    else:
        checks.append(report("Path portability", "passed", "No user-specific absolute Windows paths in manuscript or R scripts."))

    evidence_path = PAPER_DIR / "data" / "evidence.csv"
    try:
        with evidence_path.open(encoding="utf-8", newline="") as handle:
            rows = list(csv.DictReader(handle))
        required_columns = {
            "claim", "source", "source_type", "persistent_identifier",
            "paper_section", "verification_status",
        }
        if not rows or set(rows[0]) != required_columns:
            raise ValueError("unexpected columns or no evidence rows")
        checks.append(report("Evidence table", "passed", f"{len(rows)} claim-to-source records with the required schema."))
    except Exception as error:  # noqa: BLE001
        checks.append(report("Evidence table", "failed", str(error)))

    pandoc = shutil.which("pandoc")
    if pandoc:
        output = PAPER_DIR / "output" / ".static-pandoc-audit.html"
        output.parent.mkdir(parents=True, exist_ok=True)
        process = subprocess.run(
            [
                pandoc,
                str(RMD),
                "--from=markdown+yaml_metadata_block",
                "--to=html5",
                "--citeproc",
                f"--bibliography={BIB}",
                "--standalone",
                f"--output={output}",
            ],
            cwd=PAPER_DIR,
            capture_output=True,
            text=True,
            check=False,
        )
        if process.returncode == 0:
            checks.append(report("Pandoc structural parse", "passed", "Markdown and citations parsed successfully without executing R."))
            output.unlink(missing_ok=True)
        else:
            checks.append(report("Pandoc structural parse", "failed", (process.stderr or process.stdout).strip()))
    else:
        checks.append(report("Pandoc structural parse", "not evaluated", "Pandoc is unavailable."))

    for check in checks:
        print(f"[{check['status'].upper()}] {check['check']}: {check['detail']}")
    return 1 if any(check["status"] == "failed" for check in checks) else 0


if __name__ == "__main__":
    sys.exit(main())
