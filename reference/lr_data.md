# Sample simulated data for logistic regression exposure-response models with covariates

Sample simulated data for logistic regression exposure-response models
with covariates

## Usage

``` r
lr_data
```

## Format

A data frame with columns:

- id:

  Identifier

- dose:

  Nominal dose, units not specified

- exposure_1:

  Exposure 1 value, units and metric not specified

- quartile_1:

  Exposure 1 quartile, with placebo group separate

- response_1:

  Binary response 1 value

- response_2:

  Binary response 2 value

- sex:

  Sex

## Details

This simulated dataset is entirely synthetic You can find the data
generating code in the package source code

## Examples

``` r
lr_data
#> # A tibble: 300 × 7
#>       id  dose exposure_1 quartile_1 response_1 response_2 sex   
#>    <int> <dbl>      <dbl> <fct>           <dbl>      <dbl> <fct> 
#>  1     1   100      148.  Q3                  1          1 Male  
#>  2     2   100       79.7 Q1                  1          0 Male  
#>  3     3   200      212.  Q3                  1          0 Male  
#>  4     4   200      236.  Q3                  0          0 Female
#>  5     5     0        0   Placebo             1          0 Male  
#>  6     6   200       71.0 Q1                  1          0 Female
#>  7     7   100      173.  Q3                  1          0 Male  
#>  8     8   100      123.  Q2                  0          0 Female
#>  9     9     0        0   Placebo             0          0 Male  
#> 10    10   200      165.  Q3                  1          0 Female
#> # ℹ 290 more rows
```
