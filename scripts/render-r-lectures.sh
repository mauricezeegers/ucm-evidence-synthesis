#!/bin/bash
# Render the R lectures (runs R locally, stores the output in _freeze/) and write the commented
# R script students download and run line by line. Run on your Mac after changing an
# r-lecture-*.qmd, then commit.
set -e
cd "$(dirname "$0")/.."
for f in ski3011/r-lecture-*.qmd; do
  n=$(basename "$f" .qmd)            # r-lecture-3
  week=${n##*-}                       # 3
  mkdir -p "materials/ski3011/week-$week"
  quarto render "$f"
  python3 scripts/qmd_to_r.py "$f" "materials/ski3011/week-$week/$n.R"
done
rm -rf ski3011/*_files               # leftovers of rendering a single page
