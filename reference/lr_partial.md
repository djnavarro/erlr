# Partial builders for logistic regression plots

Partial builders for logistic regression plots

## Usage

``` r
build_datastrip_jitter(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

build_group_boxplot(data, config, stratify, exposure, response, strata, style)

build_model_ribbonline(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)

build_summary_pvalue(data, config, stratify, exposure, response, strata, style)

build_quantile_errorbar(
  data,
  config,
  stratify,
  exposure,
  response,
  strata,
  style
)
```

## Arguments

- data:

  The original data frame

- config:

  Configuration for the specific plot

- stratify:

  Logical indicating whether to stratify

- exposure:

  Exposure variable

- response:

  Response variable

- strata:

  Stratification variable

- style:

  Style components

## Value

A ggplot2 object, a geom, or a list of geoms
