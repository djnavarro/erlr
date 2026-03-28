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
mod <- lr_model(response ~ exposure + sex, lr_data)
sim <- lr_vpc_sim(mod)
sim
#> # A tibble: 30,000 × 5
#>    response exposure sex    row_id sim_id
#>       <dbl>    <dbl> <fct>   <int>  <int>
#>  1    0.898    148.  Male        1      1
#>  2    0.797     79.7 Male        2      1
#>  3    0.949    212.  Male        3      1
#>  4    0.954    236.  Female      4      1
#>  5    0.565      0   Female      5      1
#>  6    0.780     71.0 Male        6      1
#>  7    0.922    173.  Male        7      1
#>  8    0.848    123.  Female      8      1
#>  9    0.606      0   Male        9      1
#> 10    0.915    165.  Male       10      1
#> # ℹ 29,990 more rows
```
