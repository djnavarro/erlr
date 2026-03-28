# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, ...)

lr_plot_add_quantiles(object, bins = 4, conf_level = 0.95)

lr_plot_add_strips(object, color_by = NULL)

lr_plot_add_boxplot(object, group_by)
```

## Arguments

- data:

  Observed data

- exposure:

  Exposure variable (unquoted)

- response:

  Response variable (unquoted)

- ...:

  Other arguments

- object:

  Partially constructed plot (has S3 class `erlr_plot`)

- bins:

  Number of exposure bins (not counting placebo)

- conf_level:

  Confidence level for Clopper-Pearson intervals

- color_by:

  Variable (unquoted) to assign colors to strip plot dots

- group_by:

  Variable (unquoted) to use to stratify exposure boxplots

## Value

Plot object of class `erlr_plot`

## Examples

``` r
# add example here
```
