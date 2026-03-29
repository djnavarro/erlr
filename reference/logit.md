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
logit((1:9)/10)
#> [1] -2.1972246 -1.3862944 -0.8472979 -0.4054651  0.0000000  0.4054651  0.8472979
#> [8]  1.3862944  2.1972246
invlogit(-3:3)
#> [1] 0.04742587 0.11920292 0.26894142 0.50000000 0.73105858 0.88079708 0.95257413
logit(invlogit(-3:3))
#> [1] -3 -2 -1  0  1  2  3
```
