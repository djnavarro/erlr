
<!-- README.md is generated from README.Rmd. Please edit that file -->

# erlr

<!-- badges: start -->

<!-- badges: end -->

Provides estimation and plotting tools for exposure-response models that
use logistic regression for binary responses.

## Installation

You can install the development version of erlr like so:

``` r
pak::pak("djnavarro/erlr")
```

## Example

``` r
library(erlr)

lr_dat
#>     dose   exposure exposure_quartile response    sex
#> 1    100  111.55189                Q2        0 Female
#> 2      0    0.00000           Placebo        0 Female
#> 3      0    0.00000           Placebo        0 Female
#> 4      0    0.00000           Placebo        0   Male
#> 5      0    0.00000           Placebo        0 Female
#> 6      0    0.00000           Placebo        0 Female
#> 7      0    0.00000           Placebo        0 Female
#> 8    100   40.65926                Q1        0 Female
#> 9    100  203.88518                Q3        0   Male
#> 10     0    0.00000           Placebo        0 Female
#> 11   100   51.88691                Q1        0 Female
#> 12     0    0.00000           Placebo        0   Male
#> 13   100  165.67325                Q3        0   Male
#> 14   100  126.30733                Q2        0   Male
#> 15   200  218.89425                Q3        0   Male
#> 16     0    0.00000           Placebo        0   Male
#> 17   200   90.19709                Q2        0 Female
#> 18   100  199.31161                Q3        0 Female
#> 19     0    0.00000           Placebo        0 Female
#> 20     0    0.00000           Placebo        0   Male
#> 21   200  222.94760                Q3        0   Male
#> 22     0    0.00000           Placebo        0   Male
#> 23   200  343.77959                Q4        0   Male
#> 24     0    0.00000           Placebo        0 Female
#> 25     0    0.00000           Placebo        0 Female
#> 26   200  146.90701                Q3        0   Male
#> 27   200  756.99998                Q4        1   Male
#> 28   200  275.71541                Q4        0   Male
#> 29   100   27.69680                Q1        0 Female
#> 30   200   92.04781                Q2        0 Female
#> 31   100   21.30199                Q1        0   Male
#> 32   200   82.54796                Q2        0   Male
#> 33   100  157.75768                Q3        0   Male
#> 34     0    0.00000           Placebo        0   Male
#> 35   100   91.79893                Q2        0 Female
#> 36     0    0.00000           Placebo        0 Female
#> 37   200  293.90143                Q4        0 Female
#> 38   100  152.11188                Q3        0 Female
#> 39   100   84.29481                Q2        0   Male
#> 40     0    0.00000           Placebo        0 Female
#> 41     0    0.00000           Placebo        0 Female
#> 42   100   61.06305                Q1        0 Female
#> 43     0    0.00000           Placebo        0 Female
#> 44   200  543.12401                Q4        1   Male
#> 45     0    0.00000           Placebo        0 Female
#> 46   200  396.75000                Q4        0 Female
#> 47   200   39.67610                Q1        0   Male
#> 48   200  238.83375                Q3        0 Female
#> 49   100  275.48498                Q4        0 Female
#> 50   100  192.21151                Q3        0   Male
#> 51   100  163.81238                Q3        0   Male
#> 52   100  139.54164                Q2        0   Male
#> 53   200   78.22778                Q2        0   Male
#> 54   200  142.50574                Q3        0 Female
#> 55     0    0.00000           Placebo        0 Female
#> 56   200   62.84082                Q1        0 Female
#> 57   100   74.13249                Q2        0 Female
#> 58   100   37.07576                Q1        0 Female
#> 59   100  208.53833                Q3        0 Female
#> 60   100   44.15589                Q1        0 Female
#> 61   100   89.77532                Q2        0 Female
#> 62     0    0.00000           Placebo        0   Male
#> 63   100  104.34328                Q2        0   Male
#> 64   100  240.26683                Q4        0   Male
#> 65   100   32.47810                Q1        0   Male
#> 66   100  120.24052                Q2        0   Male
#> 67   200  455.42355                Q4        0 Female
#> 68   200  267.37534                Q4        0   Male
#> 69   200  486.90675                Q4        0   Male
#> 70   200  414.56886                Q4        0 Female
#> 71   200  366.86304                Q4        0   Male
#> 72     0    0.00000           Placebo        0   Male
#> 73   100  469.56879                Q4        0   Male
#> 74   100  250.62535                Q4        0 Female
#> 75   100  183.15276                Q3        0   Male
#> 76   100   35.76436                Q1        0 Female
#> 77     0    0.00000           Placebo        0   Male
#> 78   100   92.11046                Q2        0 Female
#> 79   100  124.14909                Q2        0 Female
#> 80   200 1034.18209                Q4        1   Male
#> 81   200   94.09617                Q2        0   Male
#> 82     0    0.00000           Placebo        0 Female
#> 83     0    0.00000           Placebo        0   Male
#> 84   100  106.50861                Q2        0 Female
#> 85     0    0.00000           Placebo        0   Male
#> 86     0    0.00000           Placebo        0   Male
#> 87   100   96.99361                Q2        0 Female
#> 88   100  123.10869                Q2        0 Female
#> 89   100  205.05880                Q3        0   Male
#> 90   200  205.26519                Q3        0   Male
#> 91   200  259.73269                Q4        0 Female
#> 92     0    0.00000           Placebo        0 Female
#> 93   100   67.43428                Q1        0 Female
#> 94   200   43.49793                Q1        0   Male
#> 95   200  170.34694                Q3        0 Female
#> 96   100  144.17120                Q3        0   Male
#> 97   200   66.55879                Q1        0 Female
#> 98   200  988.61648                Q4        1   Male
#> 99     0    0.00000           Placebo        0 Female
#> 100    0    0.00000           Placebo        0 Female
#> 101  200  563.37874                Q4        1 Female
#> 102    0    0.00000           Placebo        0 Female
#> 103    0    0.00000           Placebo        0   Male
#> 104  200  433.03595                Q4        0   Male
#> 105  200  588.99808                Q4        1   Male
#> 106  200  392.55827                Q4        0   Male
#> 107  200  198.59572                Q3        0   Male
#> 108  200  134.29971                Q2        0 Female
#> 109    0    0.00000           Placebo        0   Male
#> 110  200  166.61190                Q3        0 Female
#> 111  200  869.77139                Q4        1 Female
#> 112    0    0.00000           Placebo        0   Male
#> 113  200   97.75351                Q2        0 Female
#> 114  200  197.85098                Q3        0   Male
#> 115  200   50.29258                Q1        0   Male
#> 116  100   71.19140                Q1        0   Male
#> 117  200  242.35810                Q4        0 Female
#> 118    0    0.00000           Placebo        0   Male
#> 119    0    0.00000           Placebo        0 Female
#> 120  200  349.75054                Q4        0   Male
#> 121    0    0.00000           Placebo        0 Female
#> 122  200   64.73852                Q1        0   Male
#> 123  100  146.82299                Q3        0 Female
#> 124  100   33.19839                Q1        0 Female
#> 125    0    0.00000           Placebo        0 Female
#> 126  200  427.08575                Q4        0 Female
#> 127  200   46.15303                Q1        0   Male
#> 128    0    0.00000           Placebo        0   Male
#> 129  100   54.10360                Q1        0   Male
#> 130    0    0.00000           Placebo        0   Male
#> 131  100   52.50267                Q1        0 Female
#> 132  100   68.80287                Q1        0   Male
#> 133    0    0.00000           Placebo        0   Male
#> 134  200  151.49934                Q3        0 Female
#> 135    0    0.00000           Placebo        0 Female
#> 136  100   24.52591                Q1        0 Female
#> 137  200   83.62726                Q2        0   Male
#> 138    0    0.00000           Placebo        0 Female
#> 139  200   73.46164                Q2        0   Male
#> 140  200  945.07711                Q4        1 Female
#> 141    0    0.00000           Placebo        0   Male
#> 142  100   37.59868                Q1        0   Male
#> 143    0    0.00000           Placebo        0   Male
#> 144  100   59.44929                Q1        0   Male
#> 145  200   65.65270                Q1        0 Female
#> 146  100   76.13372                Q2        0   Male
#> 147  100   36.68597                Q1        0 Female
#> 148  200  115.35945                Q2        0   Male
#> 149  100   59.13808                Q1        0 Female
#> 150  200   58.48380                Q1        0   Male
#> 151  200  126.85555                Q2        0   Male
#> 152    0    0.00000           Placebo        0 Female
#> 153  200   76.69886                Q2        0   Male
#> 154  200  327.86470                Q4        0 Female
#> 155    0    0.00000           Placebo        0 Female
#> 156  100  134.37763                Q2        0   Male
#> 157    0    0.00000           Placebo        0 Female
#> 158  200  194.66743                Q3        0 Female
#> 159  100  186.81136                Q3        0 Female
#> 160  200  191.38986                Q3        0   Male
#> 161  200  200.97863                Q3        0   Male
#> 162  200  507.27105                Q4        1 Female
#> 163  100  166.67287                Q3        0   Male
#> 164    0    0.00000           Placebo        0   Male
#> 165    0    0.00000           Placebo        0   Male
#> 166    0    0.00000           Placebo        0   Male
#> 167  100   45.75928                Q1        0   Male
#> 168    0    0.00000           Placebo        0 Female
#> 169    0    0.00000           Placebo        0   Male
#> 170    0    0.00000           Placebo        0   Male
#> 171  100  296.48759                Q4        0   Male
#> 172  200  332.44876                Q4        0   Male
#> 173    0    0.00000           Placebo        0   Male
#> 174    0    0.00000           Placebo        0 Female
#> 175  200  199.73924                Q3        0 Female
#> 176  200  219.70589                Q3        0   Male
#> 177  200  115.01788                Q2        0   Male
#> 178  100  174.32523                Q3        0   Male
#> 179  100   50.66201                Q1        0   Male
#> 180  100  247.91514                Q4        0   Male
#> 181  100  154.78600                Q3        0 Female
#> 182  100   61.03912                Q1        0   Male
#> 183    0    0.00000           Placebo        0   Male
#> 184    0    0.00000           Placebo        0   Male
#> 185    0    0.00000           Placebo        0   Male
#> 186    0    0.00000           Placebo        0   Male
#> 187    0    0.00000           Placebo        0 Female
#> 188    0    0.00000           Placebo        0 Female
#> 189  100  258.79019                Q4        0 Female
#> 190    0    0.00000           Placebo        0   Male
#> 191  100  115.46453                Q2        0 Female
#> 192    0    0.00000           Placebo        0 Female
#> 193    0    0.00000           Placebo        0 Female
#> 194  100   48.19937                Q1        0 Female
#> 195    0    0.00000           Placebo        0 Female
#> 196    0    0.00000           Placebo        0   Male
#> 197  100  127.09695                Q2        0   Male
#> 198  100  299.08190                Q4        0   Male
#> 199  200  809.19135                Q4        1   Male
#> 200  200  148.09347                Q3        0 Female
#> 201  100   26.30412                Q1        0 Female
#> 202  200   55.00925                Q1        0 Female
#> 203  200  125.89968                Q2        0 Female
#> 204  100  104.67258                Q2        0 Female
#> 205  200  584.54690                Q4        1   Male
#> 206  200   41.00180                Q1        0 Female
#> 207  200  253.61640                Q4        0   Male
#> 208  100   62.93459                Q1        0 Female
#> 209  100   31.89097                Q1        0 Female
#> 210  100  228.11336                Q3        0   Male
#> 211  100   48.91644                Q1        0   Male
#> 212  200  122.60488                Q2        0 Female
#> 213    0    0.00000           Placebo        0 Female
#> 214    0    0.00000           Placebo        0 Female
#> 215    0    0.00000           Placebo        0   Male
#> 216  200  426.26520                Q4        0 Female
#> 217    0    0.00000           Placebo        0   Male
#> 218    0    0.00000           Placebo        0 Female
#> 219    0    0.00000           Placebo        0 Female
#> 220  200  102.89463                Q2        0 Female
#> 221  100   51.77528                Q1        0   Male
#> 222  100   41.60319                Q1        0 Female
#> 223    0    0.00000           Placebo        0   Male
#> 224  200  285.22123                Q4        0 Female
#> 225  100   43.71702                Q1        0   Male
#> 226    0    0.00000           Placebo        0 Female
#> 227  100  110.41097                Q2        0 Female
#> 228  100  312.46345                Q4        0 Female
#> 229  100   93.51398                Q2        0   Male
#> 230  200  147.42607                Q3        0 Female
#> 231    0    0.00000           Placebo        0   Male
#> 232  100  436.11581                Q4        0   Male
#> 233    0    0.00000           Placebo        0   Male
#> 234    0    0.00000           Placebo        0   Male
#> 235  200  166.55007                Q3        0 Female
#> 236  100   59.98141                Q1        0 Female
#> 237  200  162.81878                Q3        0 Female
#> 238    0    0.00000           Placebo        0   Male
#> 239  200  344.94453                Q4        0   Male
#> 240    0    0.00000           Placebo        0 Female
#> 241  200  142.13862                Q2        0 Female
#> 242  200  158.33817                Q3        0 Female
#> 243    0    0.00000           Placebo        0 Female
#> 244    0    0.00000           Placebo        0   Male
#> 245    0    0.00000           Placebo        0   Male
#> 246    0    0.00000           Placebo        0 Female
#> 247  200  132.60336                Q2        0 Female
#> 248  100  305.30781                Q4        0   Male
#> 249  200  102.23203                Q2        0   Male
#> 250  200  150.22464                Q3        0   Male
#> 251  200  615.37692                Q4        1   Male
#> 252  100  227.68914                Q3        0   Male
#> 253  200  199.18618                Q3        0 Female
#> 254  100   57.28975                Q1        0 Female
#> 255  100   84.98456                Q2        0   Male
#> 256  200  428.06570                Q4        0   Male
#> 257    0    0.00000           Placebo        0 Female
#> 258  200  124.70314                Q2        0   Male
#> 259    0    0.00000           Placebo        0 Female
#> 260  200  210.33938                Q3        0   Male
#> 261    0    0.00000           Placebo        0 Female
#> 262    0    0.00000           Placebo        0 Female
#> 263    0    0.00000           Placebo        0 Female
#> 264    0    0.00000           Placebo        0 Female
#> 265  200  157.21678                Q3        0 Female
#> 266  200  458.30158                Q4        0 Female
#> 267  100  236.46630                Q3        0 Female
#> 268    0    0.00000           Placebo        0   Male
#> 269  100  223.96588                Q3        0 Female
#> 270    0    0.00000           Placebo        0   Male
#> 271    0    0.00000           Placebo        0   Male
#> 272  100  144.28610                Q3        0 Female
#> 273  200   72.43780                Q2        0   Male
#> 274  200   53.33558                Q1        0 Female
#> 275    0    0.00000           Placebo        0   Male
#> 276    0    0.00000           Placebo        0 Female
#> 277  100   71.93362                Q2        0 Female
#> 278  200   45.72752                Q1        0   Male
#> 279  100   55.61209                Q1        0   Male
#> 280  100  116.33390                Q2        0   Male
#> 281  100   90.02569                Q2        0   Male
#> 282    0    0.00000           Placebo        0 Female
#> 283  100  260.67037                Q4        0   Male
#> 284  100  179.37874                Q3        0   Male
#> 285  100  111.44745                Q2        0 Female
#> 286  100   26.95460                Q1        0 Female
#> 287    0    0.00000           Placebo        0   Male
#> 288  100  265.22214                Q4        0 Female
#> 289  200  680.74008                Q4        1 Female
#> 290  200   86.17841                Q2        0   Male
#> 291  200  175.43896                Q3        0 Female
#> 292  200  163.81253                Q3        0 Female
#> 293  200  111.92096                Q2        0 Female
#> 294  100   22.26835                Q1        0   Male
#> 295    0    0.00000           Placebo        0 Female
#> 296  100  175.92261                Q3        0   Male
#> 297  100   48.91244                Q1        0   Male
#> 298  100  115.65791                Q2        0   Male
#> 299    0    0.00000           Placebo        0 Female
#> 300  200  494.98723                Q4        0   Male

mod <- lr_model(response ~ exposure, lr_dat)
#> Warning: glm.fit: algorithm did not converge
#> Warning: glm.fit: fitted probabilities numerically 0 or 1 occurred
mod
#> 
#> Call:  stats::glm(formula = formula, family = stats::binomial(link = "logit"), 
#>     data = data)
#> 
#> Coefficients:
#> (Intercept)     exposure  
#>   -1254.641        2.504  
#> 
#> Degrees of Freedom: 299 Total (i.e. Null);  298 Residual
#> Null Deviance:       107 
#> Residual Deviance: 8.458e-07     AIC: 4
```
