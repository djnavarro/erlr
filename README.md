
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

lr_data
#> # A tibble: 300 × 6
#>       id  dose exposure exposure_quartile response sex   
#>    <int> <dbl>    <dbl> <fct>                <dbl> <fct> 
#>  1     1   100    148.  Q3                       1 Male  
#>  2     2   100     79.7 Q1                       1 Male  
#>  3     3   200    212.  Q3                       1 Male  
#>  4     4   200    236.  Q3                       0 Female
#>  5     5     0      0   Placebo                  1 Female
#>  6     6   200     71.0 Q1                       1 Male  
#>  7     7   100    173.  Q3                       1 Male  
#>  8     8   100    123.  Q2                       0 Female
#>  9     9     0      0   Placebo                  0 Male  
#> 10    10   200    165.  Q3                       1 Male  
#> # ℹ 290 more rows

mod <- lr_model(response ~ exposure, lr_data)
mod
#> 
#> Call:  stats::glm(formula = formula, family = stats::binomial(link = "logit"), 
#>     data = data)
#> 
#> Coefficients:
#> (Intercept)     exposure  
#>     0.15078      0.01112  
#> 
#> Degrees of Freedom: 299 Total (i.e. Null);  298 Residual
#> Null Deviance:       341.7 
#> Residual Deviance: 283.9     AIC: 287.9
```
