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
