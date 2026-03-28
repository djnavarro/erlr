# Predictions and confidence intervals for logistic regression

Predictions and confidence intervals for logistic regression

## Usage

``` r
lr_predict(object, newdata, conf_level = 0.95)
```

## Arguments

- object:

  A logistic regression model

- newdata:

  Data frame containing cases to be predicted

- conf_level:

  Confidence level for the intervals

## Value

A tibble

## Examples

``` r
mod <- lr_model(response ~ exposure, lr_dat)
lr_predict(mod, lr_dat)
#> # A tibble: 300 × 11
#>       id  dose exposure exposure_quartile response sex    fit_link se_link
#>    <int> <dbl>    <dbl> <fct>                <dbl> <fct>     <dbl>   <dbl>
#>  1     1   100    148.  Q3                       1 Male      1.80    0.248
#>  2     2   100     79.7 Q1                       1 Male      1.04    0.157
#>  3     3   200    212.  Q3                       1 Male      2.50    0.362
#>  4     4   200    236.  Q3                       0 Female    2.77    0.407
#>  5     5     0      0   Placebo                  1 Female    0.151   0.177
#>  6     6   200     71.0 Q1                       1 Male      0.940   0.151
#>  7     7   100    173.  Q3                       1 Male      2.08    0.292
#>  8     8   100    123.  Q2                       0 Female    1.52    0.209
#>  9     9     0      0   Placebo                  0 Male      0.151   0.177
#> 10    10   200    165.  Q3                       1 Male      1.99    0.277
#> # ℹ 290 more rows
#> # ℹ 3 more variables: fit_resp <dbl>, ci_lower <dbl>, ci_upper <dbl>
```
