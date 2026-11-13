#!/usr/bin/env python3
"""Mechanical first pass for converting an EPI 553 R Markdown lecture to Quarto.

Usage:
    python3 tools/convert/rmd_to_qmd.py SOURCE.Rmd TARGET.qmd FRONTMATTER.yml

What it does (judgment calls are left for the hand pass described in MIGRATION.md):
  * replaces the YAML header with FRONTMATTER.yml (no output: block);
  * shifts headings down one level when the source uses top-level `#` headings;
  * removes `---` horizontal rules outside code;
  * changes magrittr `%>%` to native `|>` inside R code chunks;
  * turns blockquotes that start with a bold label (`> **Tip:** ...`) into callouts;
  * converts Rmd chunk options to `#|` YAML lines (via knitr::convert_chunk_header,
    run afterwards by the caller with uvr's R).
It prints the remaining items that need a human: em dashes, `.` pipe placeholders,
absolute paths, saveRDS/readRDS/read_xpt calls, cache=TRUE, Sys.Date().
"""
import re
import sys

CALLOUT_TYPES = [
    (r"caution|caveat|warning|watch[- ]out|pitfall|common mistake", "warning"),
    (r"important|key|remember|practical significance|take[- ]?away", "important"),
    (r"tip|interpretation|hint|try", "tip"),
]


def callout_type(label):
    low = label.lower()
    for pattern, kind in CALLOUT_TYPES:
        if re.search(pattern, low):
            return kind
    return "note"


def main(src, dst, fm_path):
    lines = open(src, encoding="utf-8").read().split("\n")
    # Drop the source YAML header.
    if lines and lines[0].strip() == "---":
        end = lines.index("---", 1)
        lines = lines[end + 1:]
    front = open(fm_path, encoding="utf-8").read().rstrip("\n").split("\n")

    in_code = False
    heading_levels = []
    for ln in lines:
        if ln.startswith("```"):
            in_code = not in_code
            continue
        if not in_code:
            m = re.match(r"^(#{1,6})\s", ln)
            if m:
                heading_levels.append(len(m.group(1)))
    shift = 1 if heading_levels and min(heading_levels) == 1 else 0

    out = []
    in_code = False
    is_r = False
    i = 0
    while i < len(lines):
        ln = lines[i]
        if ln.startswith("```"):
            if not in_code:
                is_r = bool(re.match(r"^```\{r", ln))
            in_code = not in_code
            out.append(ln)
            i += 1
            continue
        if in_code:
            out.append(ln.replace("%>%", "|>") if is_r else ln)
            i += 1
            continue
        if ln.strip() == "---":
            i += 1
            continue
        if shift and re.match(r"^#{1,5}\s", ln):
            out.append("#" + ln)
            i += 1
            continue
        m = re.match(r"^>\s*\*\*(.+?)\*\*:?\s*(.*)$", ln)
        if m:
            label = m.group(1).rstrip(":").strip()
            body = [m.group(2).lstrip(": ").strip()]
            i += 1
            while i < len(lines) and lines[i].startswith(">"):
                body.append(re.sub(r"^>\s?", "", lines[i]))
                i += 1
            while body and not body[-1].strip():
                body.pop()
            out.append("::: {.callout-%s}" % callout_type(label))
            out.append("## " + label)
            out.append("")
            out.extend(body)
            out.append(":::")
            continue
        out.append(ln)
        i += 1

    # Pandoc needs a blank line before a list or a code chunk that follows a
    # paragraph; without one the list runs into the paragraph as plain text.
    spaced = []
    in_code = False
    list_item = re.compile(r"^(\s*)([-*+]|\d+[.)])\s")
    for ln in out:
        prev = spaced[-1] if spaced else ""
        if ln.startswith("```") and not in_code:
            if prev.strip():
                spaced.append("")
            in_code = True
            spaced.append(ln)
            continue
        if ln.startswith("```") and in_code:
            in_code = False
            spaced.append(ln)
            continue
        if (not in_code and list_item.match(ln) and prev.strip()
                and not list_item.match(prev) and not prev.startswith(" ")
                and not prev.startswith(":::")):
            spaced.append("")
        spaced.append(ln)
    out = spaced

    text = "\n".join(["---"] + front + ["---", ""] + out).rstrip("\n") + "\n"
    text = re.sub(r"\n{3,}", "\n\n", text)
    open(dst, "w", encoding="utf-8").write(text)

    checks = {
        "em dash": r"—",
        "pipe placeholder": r"(data\s*=\s*\.[\s,)]|\(\.\)|\.\$|\{\s*\.\s*\}|\. \|>)",
        "absolute path": r"/Users/",
        "saved data": r"saveRDS|write_rds|readRDS|read_rds|read_xpt",
        "cache": r"cache\s*=\s*TRUE",
        "Sys.Date": r"Sys\.Date",
    }
    final = text.split("\n")
    print(f"wrote {dst} ({len(final)} lines, headings shifted: {bool(shift)})")
    for name, pat in checks.items():
        hits = [n + 1 for n, l in enumerate(final) if re.search(pat, l)]
        if hits:
            shown = ", ".join(map(str, hits[:25])) + (" ..." if len(hits) > 25 else "")
            print(f"  {name}: {len(hits)} line(s): {shown}")


if __name__ == "__main__":
    main(*sys.argv[1:4])
