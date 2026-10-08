#!/bin/bash
# Render the R lectures (runs R locally, stores results in _freeze/) and extract the R script
# students download. Run this on your Mac after changing an r-lecture-*.qmd, then commit.
set -e
cd "$(dirname "$0")/.."
for f in ski3011/r-lecture-*.qmd; do
  n=$(basename "$f" .qmd)            # r-lecture-3
  week=${n##*-}                       # 3
  mkdir -p "materials/ski3011/week-$week"
  quarto render "$f"
  # the downloadable script: all R code of the lecture, without the text
  out="materials/ski3011/week-$week/$n.R"
  Rscript -e "invisible(knitr::purl('$f', output='$out', documentation=0, quiet=TRUE))"
  # remove the code-annotation markers (# <1>) and add a header
  sed -i '' -E 's/[[:space:]]*# <[0-9]+>$//' "$out"
  { printf '### SKI3011 %s\n### Explanation and output: https://ucm.meta-research.nl/ski3011/%s.html\n### Type and run every line yourself.\n\n' "$n" "$n"; cat "$out"; } > "$out.tmp" && mv "$out.tmp" "$out"
done
