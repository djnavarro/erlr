# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, color_by = NULL)

lr_plot_style(object, labels)

lr_plot_add_model(object, color_by = "inherit", conf_level = 0.95)

lr_plot_add_quantiles(
  object,
  color_by = "inherit",
  bins = 4,
  conf_level = 0.95
)

lr_plot_add_strips(
  object,
  color_by = "inherit",
  style = "jitter",
  panel = "both"
)

lr_plot_add_boxplot(object, boxes_by, color_by = "inherit")
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

  Confidence level for Clopper-Pearson intervals

- bins:

  Number of exposure bins (not counting placebo)

- style:

  Character string: "jitter" (the default) or "dotplot"

- panel:

  Character string: "upper", "lower", or "both" (the default)

- boxes_by:

  Stratification variables to define groups for boxplots (a
  tidyselection of variables)

## Value

Plot object of class `erlr_plot`

## Examples

``` r
lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_add_model() |> 
  lr_plot_add_quantiles() |> 
  lr_plot_add_boxplot(quartile_1) |> 
  print()
#> <erlr_plot>
#>   $data:      300 rows, 7 cols
#>   $exposure:  exposure_1
#>   $response:  response_1
#>   $strata:
#>     $model:     <none>
#>     $quantile:  <none>
#>     $box:       <none>
#>   $part:
#>     $model:     response_1 ~ exposure_1
#>     $quantile:  4 bins
#>     $box:       quartile_1

lr_data |> 
  lr_plot(exposure_1, response_1, sex) |> 
  lr_plot_add_model() |> 
  lr_plot_add_quantiles() |> 
  lr_plot_add_strips() |> 
  lr_plot_add_boxplot(quartile_1) |> 
  print()  
#> <erlr_plot>
#>   $data:      300 rows, 7 cols
#>   $exposure:  exposure_1
#>   $response:  response_1
#>   $strata:
#>     $model:     sex
#>     $quantile:  sex
#>     $strip:     sex
#>     $box:       sex
#>   $part:
#>     $model:     response_1 ~ exposure_1 + sex
#>     $quantile:  4 bins
#>     $strip:     jitter both
#>     $box:       quartile_1

lr_data[1:70,] |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_add_model() |> 
  lr_plot_add_quantiles(bins = 6) |> 
  lr_plot_add_strips(sex, style = "dotplot") |> 
  lr_plot_add_boxplot(quartile_1) |> 
  lr_plot_add_boxplot(sex) |> 
  print(box_height = 2)
#> <erlr_plot>
#>   $data:      70 rows, 7 cols
#>   $exposure:  exposure_1
#>   $response:  response_1
#>   $strata:
#>     $model:     <none>
#>     $quantile:  <none>
#>     $strip:     sex
#>     $box:       <none>
#>   $part:
#>     $model:     response_1 ~ exposure_1
#>     $quantile:  6 bins
#>     $strip:     dotplot both
#>     $box:       sex
```
