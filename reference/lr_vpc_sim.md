# VPC simulations for logistic regression models

VPC simulations for logistic regression models

## Usage

``` r
lr_vpc_sim(object, nsim = 100, seed = NULL)
```

## Arguments

- object:

  Logistic regression model

- nsim:

  Number of replicates

- seed:

  RNG state

## Value

A data frame or tibble

## Examples

``` r
mod <- lr_model(ae2 ~ aucss + sex, lr_data)
sim <- lr_vpc_sim(mod)
#> Using seed = 5612
sim
#> # A tibble: 30,000 × 5
#>       ae2 aucss sex    row_id sim_id
#>     <dbl> <dbl> <fct>   <int>  <int>
#>  1 0.347   673. Male        1      1
#>  2 0.993  2806. Female      2      1
#>  3 0.144     0  Female      3      1
#>  4 0.740  1169. Female      4      1
#>  5 0.206   377. Male        5      1
#>  6 0.270   327. Female      6      1
#>  7 0.0944    0  Male        7      1
#>  8 0.757  1208. Female      8      1
#>  9 0.0944    0  Male        9      1
#> 10 0.237   254. Female     10      1
#> # ℹ 29,990 more rows
```
