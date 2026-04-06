# Cut a continuous variable into quantiles

Cut a continuous variable into quantiles

## Usage

``` r
cut_exposure_quantile(x, n = 4, is_placebo = NULL)

cut_quantile(x, n = 4)
```

## Arguments

- x:

  Numeric vector

- n:

  Number of bins

- is_placebo:

  Logical vector indicating placebo samples

## Value

A factor

## Examples

``` r
cut_quantile(lr_data$weight) 
#>   [1] Q4 Q1 Q1 Q1 Q4 Q4 Q3 Q1 Q4 Q1 Q4 Q1 Q2 Q2 Q2 Q3 Q3 Q3 Q3 Q4 Q4 Q3 Q4 Q2 Q2
#>  [26] Q2 Q4 Q4 Q1 Q1 Q1 Q3 Q3 Q1 Q1 Q3 Q3 Q2 Q2 Q2 Q2 Q4 Q4 Q3 Q2 Q2 Q4 Q1 Q2 Q1
#>  [51] Q2 Q2 Q1 Q3 Q1 Q4 Q2 Q4 Q4 Q1 Q3 Q1 Q2 Q3 Q3 Q4 Q2 Q1 Q4 Q2 Q3 Q1 Q1 Q4 Q3
#>  [76] Q4 Q1 Q1 Q4 Q4 Q4 Q2 Q3 Q4 Q4 Q3 Q1 Q4 Q3 Q3 Q1 Q1 Q1 Q3 Q2 Q1 Q1 Q2 Q1 Q2
#> [101] Q4 Q4 Q3 Q3 Q1 Q1 Q1 Q2 Q4 Q3 Q2 Q3 Q3 Q4 Q3 Q1 Q1 Q3 Q2 Q1 Q1 Q2 Q2 Q1 Q3
#> [126] Q4 Q1 Q2 Q2 Q1 Q4 Q3 Q4 Q4 Q1 Q4 Q1 Q2 Q3 Q3 Q3 Q3 Q2 Q1 Q2 Q2 Q3 Q2 Q2 Q3
#> [151] Q3 Q1 Q2 Q2 Q3 Q2 Q4 Q4 Q2 Q4 Q1 Q4 Q4 Q2 Q3 Q2 Q1 Q4 Q1 Q3 Q1 Q4 Q2 Q2 Q1
#> [176] Q3 Q4 Q3 Q2 Q3 Q4 Q3 Q2 Q1 Q4 Q1 Q2 Q3 Q1 Q1 Q2 Q3 Q1 Q3 Q1 Q3 Q3 Q4 Q1 Q3
#> [201] Q2 Q2 Q1 Q3 Q4 Q1 Q1 Q1 Q1 Q3 Q1 Q2 Q3 Q4 Q1 Q4 Q3 Q3 Q2 Q3 Q4 Q1 Q3 Q3 Q4
#> [226] Q2 Q2 Q4 Q1 Q2 Q2 Q4 Q4 Q1 Q4 Q3 Q2 Q3 Q4 Q3 Q2 Q1 Q3 Q3 Q2 Q4 Q4 Q3 Q4 Q3
#> [251] Q1 Q2 Q4 Q4 Q2 Q4 Q4 Q1 Q4 Q3 Q3 Q1 Q2 Q4 Q4 Q2 Q1 Q1 Q4 Q4 Q3 Q2 Q2 Q3 Q2
#> [276] Q2 Q1 Q1 Q1 Q2 Q3 Q3 Q2 Q1 Q4 Q3 Q4 Q3 Q1 Q4 Q1 Q2 Q1 Q3 Q1 Q3 Q2 Q4 Q3 Q1
#> Levels: Q1 Q2 Q3 Q4
cut_exposure_quantile(lr_data$aucss)
#>   [1] Q2      Q4      Placebo Q3      Q1      Q1      Placebo Q3      Placebo
#>  [10] Q1      Q4      Q1      Q3      Placebo Q3      Q1      Q2      Placebo
#>  [19] Q1      Placebo Placebo Q3      Placebo Placebo Q3      Q3      Placebo
#>  [28] Placebo Q3      Q4      Q2      Q2      Q1      Q3      Q3      Placebo
#>  [37] Q1      Q3      Q1      Q3      Placebo Q4      Q3      Q2      Q2     
#>  [46] Q2      Q3      Q1      Placebo Q4      Q4      Placebo Placebo Q2     
#>  [55] Placebo Q4      Q1      Q4      Q2      Placebo Q4      Q2      Q4     
#>  [64] Q1      Placebo Placebo Q2      Q2      Placebo Q3      Placebo Q4     
#>  [73] Q3      Q4      Q1      Q4      Placebo Placebo Q3      Q4      Q2     
#>  [82] Q2      Q4      Placebo Placebo Placebo Placebo Q3      Placebo Q2     
#>  [91] Q3      Q1      Q1      Q4      Placebo Q1      Placebo Placebo Placebo
#> [100] Q1      Q2      Q4      Q3      Q2      Q2      Q1      Q4      Placebo
#> [109] Q3      Q4      Placebo Q4      Q2      Q1      Q3      Placebo Placebo
#> [118] Q1      Q4      Q1      Q1      Placebo Q4      Q1      Placebo Placebo
#> [127] Q1      Q4      Q3      Q2      Q3      Q3      Q3      Q1      Placebo
#> [136] Q1      Q2      Placebo Q3      Placebo Q2      Placebo Q1      Placebo
#> [145] Q3      Q4      Q4      Q4      Placebo Q4      Placebo Q2      Placebo
#> [154] Q3      Q3      Q3      Q2      Q4      Q2      Q1      Placebo Placebo
#> [163] Q2      Q4      Q1      Q1      Placebo Q1      Placebo Placebo Q3     
#> [172] Q1      Q3      Q1      Placebo Q3      Q2      Q4      Q2      Q3     
#> [181] Q4      Q2      Q3      Placebo Q2      Placebo Placebo Placebo Q4     
#> [190] Q2      Q3      Q2      Q3      Q4      Q3      Placebo Q2      Placebo
#> [199] Q2      Q2      Q4      Q4      Q4      Q1      Q4      Placebo Placebo
#> [208] Q4      Placebo Placebo Q3      Q2      Placebo Q2      Q2      Placebo
#> [217] Placebo Q2      Q3      Q1      Q4      Placebo Q4      Placebo Q2     
#> [226] Placebo Q4      Placebo Placebo Q3      Q1      Q2      Q1      Q2     
#> [235] Placebo Q1      Q4      Placebo Q4      Q4      Q2      Q3      Placebo
#> [244] Q1      Q1      Placebo Q4      Q3      Placebo Placebo Q2      Q1     
#> [253] Q1      Q4      Q1      Placebo Placebo Placebo Q1      Placebo Q2     
#> [262] Q1      Q2      Placebo Placebo Q3      Q1      Q2      Q3      Placebo
#> [271] Placebo Q4      Q3      Placebo Q2      Q3      Placebo Q2      Q3     
#> [280] Q1      Placebo Placebo Q4      Q1      Q1      Placebo Q4      Placebo
#> [289] Placebo Placebo Placebo Placebo Q2      Q4      Placebo Placebo Placebo
#> [298] Placebo Q3      Q1     
#> Levels: Placebo Q1 Q2 Q3 Q4
```
