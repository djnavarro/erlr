# Logit and inverse logit functions

Logit and inverse logit functions

## Usage

``` r
logit(x)

invlogit(x)
```

## Arguments

- x:

  Numeric vector

## Value

Numeric vector

## Examples

``` r
logit(lr_data$exposure)
#> Warning: Unknown or uninitialised column: `exposure`.
#> numeric(0)
invlogit(lr_data$response)
#> Warning: Unknown or uninitialised column: `response`.
#> Error in -x: invalid argument to unary operator
```
