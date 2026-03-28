# Plot VPC simulations for logistic regression models

Plot VPC simulations for logistic regression models

## Usage

``` r
lr_vpc_plot(object, sim, group_by, conf_level = 0.95)
```

## Arguments

- object:

  Logistic regression model

- sim:

  VPC simulations

- group_by:

  Variable (unquoted) to stratify predictions

- conf_level:

  Confidence level

## Value

A ggplot2 object

## Examples

``` r
mod <- lr_model(response ~ exposure + sex, lr_data)
sim <- lr_vpc_sim(mod)
lr_vpc_plot(mod, sim, group_by = exposure)

lr_vpc_plot(mod, sim, group_by = sex)

```
