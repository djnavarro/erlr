# Clopper-Pearson confidence interval for binary data

Clopper-Pearson confidence interval for binary data

## Usage

``` r
clopper_pearson(x, n, conf_level = 0.95)
```

## Arguments

- x:

  Number of successes

- n:

  Total number of trials

- conf_level:

  Confidence level

## Value

Named numeric vector, with confidence level stored as an attribute

## Examples

``` r
clopper_pearson(1, 10)
#>       lower       upper 
#> 0.002528579 0.445016117 
#> attr(,"conf_level")
#> [1] 0.95
```
