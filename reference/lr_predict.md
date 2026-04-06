# Predictions and confidence intervals for logistic regression

Predictions and confidence intervals for logistic regression

## Usage

``` r
lr_predict(object, newdata = NULL, conf_level = 0.95)
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
mod <- lr_model(ae1 ~ aucss, lr_data)
prd <- lr_predict(mod, lr_data)
prd
#> # A tibble: 300 × 15
#>       id sex      age weight  dose treatment aucss cmaxss   ae1   ae2 fit_link
#>    <int> <fct>  <int>  <dbl> <dbl> <fct>     <dbl>  <dbl> <dbl> <dbl>    <dbl>
#>  1     1 Male      35     79   200 Drug       673.   97.3     0     1  1.91   
#>  2     2 Female    22     58   200 Drug      2806.  301.      1     1 13.6    
#>  3     3 Female    28     58     0 Placebo      0     0       0     0 -1.79   
#>  4     4 Female    18     57   100 Drug      1169.  198.      1     1  4.64   
#>  5     5 Male      28     77   100 Drug       377.   51.4     0     0  0.283  
#>  6     6 Female    19     76   200 Drug       327.   25.4     1     0  0.00668
#>  7     7 Male      30     70     0 Placebo      0     0       0     0 -1.79   
#>  8     8 Female    34     60   100 Drug      1208.  133.      1     1  4.85   
#>  9     9 Male      21     89     0 Placebo      0     0       0     0 -1.79   
#> 10    10 Female    34     56   200 Drug       254.   31.0     0     0 -0.397  
#> # ℹ 290 more rows
#> # ℹ 4 more variables: se_link <dbl>, fit_resp <dbl>, ci_lower <dbl>,
#> #   ci_upper <dbl>
```
