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
mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
sim <- lr_vpc_sim(mod)
sim
#> # A tibble: 30,000 × 5
#>    response_1 exposure_1 sex    row_id sim_id
#>         <dbl>      <dbl> <fct>   <int>  <int>
#>  1      0.917      148.  Male        1      1
#>  2      0.842       79.7 Male        2      1
#>  3      0.956      212.  Male        3      1
#>  4      0.930      236.  Female      4      1
#>  5      0.694        0   Male        5      1
#>  6      0.694       71.0 Female      6      1
#>  7      0.936      173.  Male        7      1
#>  8      0.799      123.  Female      8      1
#>  9      0.694        0   Male        9      1
#> 10      0.861      165.  Female     10      1
#> # ℹ 29,990 more rows
```
