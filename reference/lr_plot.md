# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, ...)

lr_plot_add_quantiles(object, bins = 4, conf.level = 0.95)

lr_plot_add_strips(object, color = NULL)

# S3 method for class 'erlr_plot'
print(x, ...)
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

- color:

  Variable (unquoted) to assign colors to strip plot dots

## Value

Plot object of class `erlr_plot`

## Examples

``` r
# add example here
```
