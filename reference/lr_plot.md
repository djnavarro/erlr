# Builds an exposure-response plot for a logistic regression model

Builds an exposure-response plot for a logistic regression model

## Usage

``` r
lr_plot(data, exposure, response, stratify_by = NULL)

lr_plot_style(object, labels)

lr_plot_show_model(object, keep_strata = NULL, conf_level = 0.95)

lr_plot_show_quantiles(object, keep_strata = NULL, bins = 4, conf_level = 0.95)

lr_plot_show_datastrip(
  object,
  keep_strata = NULL,
  style = "jitter",
  panel = "both"
)

lr_plot_show_groups(object, group_by, keep_strata = NULL)

lr_plot_build(object)
```

## Arguments

- data:

  Observed data

- exposure:

  Exposure variable (one variable, unquoted)

- response:

  Response variable (one variable, unquoted)

- stratify_by:

  Stratification variable used for color and fill (one variable,
  unquoted)

- object:

  Partially constructed plot (has S3 class `erlr_plot`)

- labels:

  Named list of labels

- keep_strata:

  Logical, indicating whether this component should keep the color
  stratification

- conf_level:

  Confidence level

- bins:

  Number of exposure bins (not counting placebo)

- style:

  Character string: "jitter" (the default) or "dotplot"

- panel:

  Character string: "upper", "lower", or "both" (the default)

- group_by:

  Grouping variables to define groups for distribution plots (a
  tidyselection of variables)

## Value

Plot object of class `erlr_plot`

## Examples

``` r
lr_data |> 
  lr_plot(aucss, ae1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles() |> 
  lr_plot_show_groups(dose) |> 
  plot()

 
plt <- lr_data |> 
  lr_plot(aucss, ae2, stratify_by = sex) |> 
  lr_plot_show_model(keep_strata = FALSE) |> 
  lr_plot_show_quantiles(bins = 3) |> 
  lr_plot_show_datastrip() |> 
  lr_plot_show_groups(group_by = c(treatment, dose), keep_strata = FALSE)

print(plt)
#> <erlr_plot>
#>   $data:      300 rows, 10 cols
#>   $exposure:  aucss
#>   $response:  ae2
#>   $strata:    sex
#>   $part:
#>     $model:     ae2 ~ aucss
#>     $quantile:  3 bins
#>     $strip:     jitter both
#>     $group:     treatment, dose
plot(plt)

```
