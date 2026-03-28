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
```
