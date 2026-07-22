## Submission

This is a new submission.

## Test environments

- Windows 11 x64 (build 26200), R 4.6.1 (2026-06-24 ucrt)
- GitHub Actions: four checks passed

## R CMD check results

Remote-enabled `R CMD check --as-cran`:

- 0 errors
- 0 warnings
- 1 NOTE

The NOTE is the expected CRAN incoming-feasibility result for a new
submission:

```
* checking CRAN incoming feasibility ... NOTE
New submission
```

A second strict `R CMD check --as-cran`, with CRAN incoming checks
disabled but all package, dependency, example, test, and manual checks
enabled, completed with:

- 0 errors
- 0 warnings
- 0 notes

`_R_CHECK_FORCE_SUGGESTS_=true` was used, with `keras3` 1.5.1
available from an isolated temporary library.

## Additional comments

The pkgdown site is live at
https://stefanosbalaskas.github.io/gp3ml/.

No DOI, CRAN URL, or CRAN acceptance status is claimed.
