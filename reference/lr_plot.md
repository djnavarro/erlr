# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, color_by = NULL)

lr_plot_style(object, labels)

lr_plot_show_model(object, color_by = "inherit", conf_level = 0.95)

lr_plot_show_quantiles(
  object,
  color_by = "inherit",
  bins = 4,
  conf_level = 0.95
)

lr_plot_show_datastrip(
  object,
  color_by = "inherit",
  style = "jitter",
  panel = "both"
)

lr_plot_show_groups(object, group_by, color_by = "inherit")

lr_plot_build(object)
```

## Arguments

- data:

  Observed data

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted)

- color_by:

  Stratification variable used for color and fill (one variable,
  unquoted)

- object:

  Partially constructed plot (has S3 class `erlr_plot`)

- labels:

  Named list of labels

- conf_level:

  Confidence level

- bins:

  Number of exposure bins (not counting placebo)

- style:

  Character string: "jitter" (the default) or "dotplot"

- panel:

  Character string: "upper", "lower", or "both" (the default)

- group_by:

  Stratification variables to define groups for boxplots (a
  tidyselection of variables)

## Value

Plot object of class `erlr_plot`

## Examples

``` r
lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles() |> 
  lr_plot_show_groups(quartile_1) |> 
  plot()


lr_data |> 
  lr_plot(exposure_1, response_1, sex) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles() |> 
  lr_plot_show_datastrip() |> 
  lr_plot_show_groups(quartile_1) |> 
  plot()  


lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles(bins = 3) |> 
  lr_plot_show_datastrip(sex) |> 
  lr_plot_show_groups(c(quartile_1, sex)) |> 
  plot()

```
