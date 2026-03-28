
<!-- README.md is generated from README.Rmd. Please edit that file -->

# erlr

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/erlr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/erlr/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

Provides estimation and plotting tools for exposure-response models that
use logistic regression for binary responses.

## Installation

You can install the development version of erlr like so:

``` r
pak::pak("djnavarro/erlr")
```

## Example

``` r
library(erlr)
library(tibble)

lr_dat
#> # A tibble: 300 × 6
#>       id  dose exposure exposure_quartile response sex   
#>    <int> <dbl>    <dbl> <fct>                <dbl> <fct> 
#>  1     1   100    112.  Q2                       1 Female
#>  2     2     0      0   Placebo                  0 Female
#>  3     3     0      0   Placebo                  1 Female
#>  4     4     0      0   Placebo                  1 Male  
#>  5     5     0      0   Placebo                  1 Female
#>  6     6     0      0   Placebo                  0 Female
#>  7     7     0      0   Placebo                  1 Female
#>  8     8   100     40.7 Q1                       1 Female
#>  9     9   100    204.  Q3                       1 Male  
#> 10    10     0      0   Placebo                  0 Female
#> # ℹ 290 more rows

mod <- lr_model(response ~ exposure, lr_dat)
mod
#> 
#> Call:  stats::glm(formula = formula, family = stats::binomial(link = "logit"), 
#>     data = data)
#> 
#> Coefficients:
#> (Intercept)     exposure  
#>     0.03472      0.00740  
#> 
#> Degrees of Freedom: 299 Total (i.e. Null);  298 Residual
#> Null Deviance:       379.1 
#> Residual Deviance: 338.7     AIC: 342.7
```
