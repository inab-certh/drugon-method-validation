# Method validation for the DRUGon project

## Setup

The project uses `renv` for controlling the R-environment. To set it up run:

```r
renv::restore()
```

## Execution

First, update `.Rprofile` file with your local settings.

For the execution we first need to generate the required cohorts of controls. In this case we are using the OHDSI
Methods Benchmark set of positive and negative controls. To generate the set in your database run:

```bash
Rscript code/run.R
```

To execute the SCCS analyses run:

```bash
Rscript code/run_sccs_analysis.R
```

To execute the SCC analyses run:

```bash
Rscript code/run_scc_analysis.R
```

To collect all generated results run:

```bash
Rscript code/collect_results.R
```
