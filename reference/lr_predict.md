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
mod <- lr_model(response_1 ~ exposure_1, lr_data)
prd <- lr_predict(mod, lr_data)
prd
#> # A tibble: 300 × 12
#>       id  dose exposure_1 quartile_1 response_1 response_2 sex    fit_link
#>    <int> <dbl>      <dbl> <fct>           <dbl>      <dbl> <fct>     <dbl>
#>  1     1   100      148.  Q3                  1          1 Male      1.80 
#>  2     2   100       79.7 Q1                  1          0 Male      1.04 
#>  3     3   200      212.  Q3                  1          0 Male      2.50 
#>  4     4   200      236.  Q3                  0          0 Female    2.77 
#>  5     5     0        0   Placebo             1          0 Male      0.151
#>  6     6   200       71.0 Q1                  1          0 Female    0.940
#>  7     7   100      173.  Q3                  1          0 Male      2.08 
#>  8     8   100      123.  Q2                  0          0 Female    1.52 
#>  9     9     0        0   Placebo             0          0 Male      0.151
#> 10    10   200      165.  Q3                  1          0 Female    1.99 
#> # ℹ 290 more rows
#> # ℹ 4 more variables: se_link <dbl>, fit_resp <dbl>, ci_lower <dbl>,
#> #   ci_upper <dbl>
```
