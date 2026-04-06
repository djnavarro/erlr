
<!-- README.md is generated from README.Rmd. Please edit that file -->

# erlr

<!-- badges: start -->

[![R-CMD-check](https://github.com/djnavarro/erlr/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/djnavarro/erlr/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/djnavarro/erlr/graph/badge.svg)](https://app.codecov.io/gh/djnavarro/erlr)
[![Lifecycle:
experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://lifecycle.r-lib.org/articles/stages.html#experimental)
<!-- badges: end -->

Provides estimation and plotting tools for exposure-response models that
use logistic regression for binary responses. It is mostly intended as a
convenience package: the core tools are wrappers around `glm()`, and the
plotting tools use ggplot2 and patchwork to build typical plots used in
exposure-response modelling.

## Installation

You can install the development version of erlr like so:

``` r
pak::pak("djnavarro/erlr")
```

## Models

``` r
library(erlr)
library(tibble)

lr_data
#> # A tibble: 300 × 7
#>       id  dose exposure_1 quartile_1 response_1 response_2 sex   
#>    <int> <dbl>      <dbl> <fct>           <dbl>      <dbl> <fct> 
#>  1     1   100      148.  Q3                  1          1 Male  
#>  2     2   100       79.7 Q1                  1          0 Male  
#>  3     3   200      212.  Q3                  1          0 Male  
#>  4     4   200      236.  Q3                  0          0 Female
#>  5     5     0        0   Placebo             1          0 Male  
#>  6     6   200       71.0 Q1                  1          0 Female
#>  7     7   100      173.  Q3                  1          0 Male  
#>  8     8   100      123.  Q2                  0          0 Female
#>  9     9     0        0   Placebo             0          0 Male  
#> 10    10   200      165.  Q3                  1          0 Female
#> # ℹ 290 more rows

mod <- lr_model(response_1 ~ exposure_1, lr_data)
mod
#> 
#> Call:  stats::glm(formula = formula, family = stats::binomial(link = "logit"), 
#>     data = data)
#> 
#> Coefficients:
#> (Intercept)   exposure_1  
#>     0.15078      0.01112  
#> 
#> Degrees of Freedom: 299 Total (i.e. Null);  298 Residual
#> Null Deviance:       341.7 
#> Residual Deviance: 283.9     AIC: 287.9
```

## Plots

``` r
lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles() |> 
  lr_plot_show_groups(dose) |> 
  plot()
```

<img src="man/figures/README-lr-plot-1.png" width="100%" />

``` r

plt <- lr_data |> 
   lr_plot(exposure_1, response_1, stratify_by = sex) |> 
   lr_plot_show_model(keep_strata = FALSE) |> 
   lr_plot_show_quantiles(bins = 3) |> 
   lr_plot_show_datastrip() |> 
   lr_plot_show_groups(group_by = c(quartile_1, dose), keep_strata = FALSE)

print(plt)
#> <erlr_plot>
#>   $data:      300 rows, 7 cols
#>   $exposure:  exposure_1
#>   $response:  response_1
#>   $strata:    sex
#>   $part:
#>     $model:     response_1 ~ exposure_1
#>     $quantile:  3 bins
#>     $strip:     jitter both
#>     $group:     quartile_1, dose
plot(plt)
```

<img src="man/figures/README-lr-plot-2.png" width="100%" />

## Stepwise covariate modelling

``` r
mod1 <- lr_model(response_1 ~ exposure_1 + sex + dose, lr_data)
mod2 <- lr_scm_backward(mod1, candidates = c("sex", "dose"))
lr_scm_history(mod2)
#> # A tibble: 4 × 11
#>   iteration attempt step       action term_tested model_tested   model_converged
#>       <int>   <int> <chr>      <chr>  <chr>       <chr>          <lgl>          
#> 1         0       0 base model <NA>   <NA>        response_1 ~ … TRUE           
#> 2         1       1 backward   remove ~dose       response_1 ~ … TRUE           
#> 3         1       2 backward   remove ~sex        response_1 ~ … TRUE           
#> 4         2       3 backward   remove ~sex        response_1 ~ … TRUE           
#> # ℹ 4 more variables: term_p_value <dbl>, model_aic <dbl>, model_bic <dbl>,
#> #   model_updated <int>
```

## VPC/Simulation

``` r
mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
sim <- lr_vpc_sim(mod, seed = 1234)
sim
#> # A tibble: 30,000 × 5
#>    response_1 exposure_1 sex    row_id sim_id
#>         <dbl>      <dbl> <fct>   <int>  <int>
#>  1      0.918      148.  Male        1      1
#>  2      0.823       79.7 Male        2      1
#>  3      0.962      212.  Male        3      1
#>  4      0.929      236.  Female      4      1
#>  5      0.625        0   Male        5      1
#>  6      0.611       71.0 Female      6      1
#>  7      0.940      173.  Male        7      1
#>  8      0.755      123.  Female      8      1
#>  9      0.625        0   Male        9      1
#> 10      0.841      165.  Female     10      1
#> # ℹ 29,990 more rows

lr_vpc_plot(mod, sim, group_by = exposure_1)
```

<img src="man/figures/README-lr-vpc-1.png" width="100%" />

``` r
lr_vpc_plot(mod, sim, group_by = sex)
```

<img src="man/figures/README-lr-vpc-2.png" width="100%" />
