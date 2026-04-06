# Fit a logistic regression function

Fit a logistic regression function

## Usage

``` r
lr_model(formula, data, ...)
```

## Arguments

- formula:

  Model formula

- data:

  Data set

- ...:

  Other arguments passed to [`glm()`](https://rdrr.io/r/stats/glm.html)

## Value

A glm object

## Examples

``` r
mod <- lr_model(ae1 ~ aucss, lr_data)
mod
#> 
#> Call:  stats::glm(formula = formula, family = stats::binomial(link = "logit"), 
#>     data = data)
#> 
#> Coefficients:
#> (Intercept)        aucss  
#>   -1.791383     0.005497  
#> 
#> Degrees of Freedom: 299 Total (i.e. Null);  298 Residual
#> Null Deviance:       402.1 
#> Residual Deviance: 193.4     AIC: 197.4
```
