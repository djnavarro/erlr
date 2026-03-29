# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, ...)

lr_plot_add_quantiles(object, bins = 4, conf_level = 0.95)

lr_plot_add_dotplot_strips(object, color_by = NULL)

lr_plot_add_jitter_strips(object, color_by = NULL)

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
lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_add_quantiles(bins = 4) |> 
  lr_plot_add_boxplot(group_by = quartile) |> 
  print()
#> Error in ggplot2::geom_boxplot(): Problem while computing aesthetics.
#> ℹ Error occurred in the 1st layer.
#> Caused by error:
#> ! object 'quartile' not found

lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_add_quantiles(bins = 4) |> 
  lr_plot_add_jitter_strips(color_by = sex) |> 
  lr_plot_add_boxplot(group_by = quartile) |> 
  print()  
#> Error in ggplot2::geom_boxplot(): Problem while computing aesthetics.
#> ℹ Error occurred in the 1st layer.
#> Caused by error:
#> ! object 'quartile' not found

lr_data[1:70,] |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_add_quantiles(bins = 4) |> 
  lr_plot_add_dotplot_strips(color_by = sex) |> 
  lr_plot_add_boxplot(group_by = quartile) |> 
  lr_plot_add_boxplot(group_by = sex) |> 
  print(box_height = 2)
#> Error in ggplot2::geom_boxplot(): Problem while computing aesthetics.
#> ℹ Error occurred in the 1st layer.
#> Caused by error:
#> ! object 'quartile' not found
```
