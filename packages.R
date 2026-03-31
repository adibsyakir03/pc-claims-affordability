# packages.R — install all R dependencies for this project
# Run this once before executing any analysis scripts:
#   source("packages.R")

pkgs <- c(
  "DBI",           # database interface (connects R to MySQL)
  "RMySQL",        # MySQL driver for DBI
  "ChainLadder",   # actuarial loss development & IBNR methods
  "actuar",        # actuarial mathematics & distributions
  "dplyr",         # data manipulation
  "tidyr",         # reshaping data (long <-> wide for triangles)
  "ggplot2",       # visualisation
  "scales",        # number formatting in ggplot2
  "readr",         # fast CSV reading
  "writexl",       # export to Excel
  "knitr",         # report generation
  "rmarkdown"      # R Markdown documents
)

install_if_missing <- function(p) {
  if (!requireNamespace(p, quietly = TRUE)) {
    install.packages(p, repos = "https://cloud.r-project.org")
  }
}

invisible(lapply(pkgs, install_if_missing))
message("All packages ready.")
