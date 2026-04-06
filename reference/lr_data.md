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

- sex:

  Sex

- age:

  Age

- weight:

  Weight

- dose:

  Nominal dose, units not specified

- treatment:

  Treatment

- aucss:

  AUCss

- cmaxss:

  Cmax,ss

- ae1:

  Binary response 1 value

- ae2:

  Binary response 2 value

## Details

This simulated dataset is entirely synthetic You can find the data
generating code in the package source code

## Examples

``` r
lr_data
#> # A tibble: 300 × 10
#>       id sex      age weight  dose treatment aucss cmaxss   ae1   ae2
#>    <int> <fct>  <int>  <dbl> <dbl> <fct>     <dbl>  <dbl> <dbl> <dbl>
#>  1     1 Male      35     79   200 Drug       673.   97.3     0     1
#>  2     2 Female    22     58   200 Drug      2806.  301.      1     1
#>  3     3 Female    28     58     0 Placebo      0     0       0     0
#>  4     4 Female    18     57   100 Drug      1169.  198.      1     1
#>  5     5 Male      28     77   100 Drug       377.   51.4     0     0
#>  6     6 Female    19     76   200 Drug       327.   25.4     1     0
#>  7     7 Male      30     70     0 Placebo      0     0       0     0
#>  8     8 Female    34     60   100 Drug      1208.  133.      1     1
#>  9     9 Male      21     89     0 Placebo      0     0       0     0
#> 10    10 Female    34     56   200 Drug       254.   31.0     0     0
#> # ℹ 290 more rows
```
