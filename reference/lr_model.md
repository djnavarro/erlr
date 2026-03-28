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
```
