# Sample simulated data for logistic regression exposure-response models with covariates.

Sample simulated data for logistic regression exposure-response models
with covariates.

## Usage

``` r
lr_dat
```

## Format

A data frame with columns:

- id:

  Identifier

- dose:

  Nominal dose, units not specified

- exposure:

  Exposure value, units and metric not specified

- exposure_quartile:

  Exposure quartile, with placebo group separate

- response:

  Continuous response value (units not specified)

- sex:

  Sex

## Details

This simulated dataset is entirely synthetic You can find the data
generating code in the package source code

## Examples

``` r
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
```
