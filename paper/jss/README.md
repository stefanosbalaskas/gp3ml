# gp3ml JSS manuscript

This directory contains the Journal of Statistical Software manuscript track for gp3ml.

## Authoritative working files

- `article.tex`: JSS manuscript.
- `refs.bib`: manuscript bibliography.
- `code.R`: single standalone replication script.
- `code.html`: output created by `knitr::spin("code.R")`.
- `R/helpers.R` and `R/case-study.R`: frozen replication helpers copied from the validated paper workspace.
- `figures/`: figures reproduced by `code.R`.
- `output/`: machine-readable result tables reproduced by `code.R`.
- `render-jss.R`: local validation renderer; installs the repository source into a temporary library, runs the replication script, spins `code.html`, and compiles the JSS PDF.

The pristine JSS 3.6 template copies are retained as `article-template.tex`, `article-template.R`, and `refs-template.bib`.

## Local render

From the repository root:

```r
system2(
  file.path(R.home("bin"), "Rscript.exe"),
  c("--vanilla", "paper/jss/render-jss.R")
)
```

The renderer does not overwrite the user's installed gp3ml package.
