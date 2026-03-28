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
#>  1     1   100    112.  Q2                       1 Female   0.860    0.146
#>  2     2     0      0   Placebo                  0 Female   0.0347   0.166
#>  3     3     0      0   Placebo                  1 Female   0.0347   0.166
#>  4     4     0      0   Placebo                  1 Male     0.0347   0.166
#>  5     5     0      0   Placebo                  1 Female   0.0347   0.166
#>  6     6     0      0   Placebo                  0 Female   0.0347   0.166
#>  7     7     0      0   Placebo                  1 Female   0.0347   0.166
#>  8     8   100     40.7 Q1                       1 Female   0.336    0.137
#>  9     9   100    204.  Q3                       1 Male     1.54     0.242
#> 10    10     0      0   Placebo                  0 Female   0.0347   0.166
#> # ℹ 290 more rows
#> # ℹ 3 more variables: fit_resp <dbl>, ci_lower <dbl>, ci_upper <dbl>
```
