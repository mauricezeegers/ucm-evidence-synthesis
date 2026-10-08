"""Turn an R lecture (.qmd) into a commented R script that students run line by line in RStudio.

Text becomes comments, `## Heading` becomes an RStudio section ("# Heading ----"), code stays code.
Usage: python3 scripts/qmd_to_r.py ski3011/r-lecture-3.qmd materials/ski3011/week-3/r-lecture-3.R
"""
import re
import sys
import textwrap

src, out = sys.argv[1], sys.argv[2]
text = open(src, encoding="utf-8").read()

# front matter: keep the title for the header, drop the rest
title = ""
if text.startswith("---"):
    _, fm, text = text.split("---", 2)
    m = re.search(r'^title:\s*"?(.*?)"?\s*$', fm, re.M)
    title = m.group(1) if m else ""


def plain(line):
    """Markdown to plain comment text."""
    line = re.sub(r"\[([^\]]+)\]\([^)]*\)(\{[^}]*\})?", r"\1", line)   # links: keep the text
    line = line.replace("**", "").replace("`", "")
    return line


lines = [f"### {title}",
         "### UCM SKI3011 Evidence Synthesis 2 · https://ucm.meta-research.nl",
         "### Run this script line by line: put the cursor on a line and press Cmd+Enter (Mac) or Ctrl+Enter (Windows).",
         ""]
in_code = False
chunk = []
for raw in text.splitlines():
    if raw.startswith("```"):
        if not in_code and raw.startswith("```{r"):
            in_code, chunk = True, []
        elif in_code:
            in_code = False
            # chunks marked "#| include: false" only prepare the web page (e.g. folders)
            if not any(c.replace(" ", "") == "#|include:false" for c in chunk):
                lines.extend(c for c in chunk if not c.startswith("#|"))
                lines.append("")
        continue
    if in_code:
        chunk.append(raw)
        continue
    if raw.startswith("Download the R script") or "Download the R script" in raw:
        continue
    if raw.startswith("## "):
        lines.append(f"# {raw[3:].strip()} ----")
        continue
    if raw.strip() == "":
        if lines and lines[-1] != "":
            lines.append("")
        continue
    for w in textwrap.wrap(plain(raw), width=88):
        lines.append(f"# {w}")

open(out, "w", encoding="utf-8").write("\n".join(lines).rstrip() + "\n")
