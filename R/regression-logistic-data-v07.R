

make_lr_data <- function(seed) {
  set.seed(seed)
  n <- 300L
  lr_data <- tibble::tibble(
    id = 1:n,
    dose = sample(rep(c(0, 100, 200), c(n/3, n/3, n/3))),
    exposure_1 = stats::qlnorm(p = stats::runif(n, .05, .95)) * dose,
    quartile_1 = cut_exposure_quantile(exposure_1),
    response_1 = as.numeric(logit(stats::runif(n)) < exposure_1/100 - 0.1),
    response_2 = as.numeric(logit(stats::runif(n)) < exposure_1/500 - 2.0),
    sex = factor(sample(rep(c("Male", "Female"), c(n/2, n/2))))
  )
  attr(lr_data$id, "label") <- "Subject ID"
  attr(lr_data$dose, "label") <- "Dose"
  attr(lr_data$exposure_1, "label") <- "Exposure 1"
  attr(lr_data$quartile_1, "label") <- "Exp. 1 Quartile"
  attr(lr_data$response_1, "label") <- "Response 1"
  attr(lr_data$response_2, "label") <- "Response 2"
  attr(lr_data$sex, "label") <- "Sex"
  return(lr_data)
}

#lr_data <- make_lr_data(seed = 2407L)
#usethis::use_data(lr_data, overwrite = TRUE)

#' Sample simulated data for logistic regression exposure-response models with covariates.
#'
#' @name lr_data
#' @format A data frame with columns:
#' \describe{
#' \item{id}{Identifier}
#' \item{dose}{Nominal dose, units not specified}
#' \item{exposure_1}{Exposure 1 value, units and metric not specified}
#' \item{quartile_1}{Exposure 1 quartile, with placebo group separate}
#' \item{response_1}{Binary response 1 value}
#' \item{response_2}{Binary response 2 value}
#' \item{sex}{Sex}
#' }
#' @details
#'
#' This simulated dataset is entirely synthetic
#' You can find the data generating code in the package source code
#'
#' @examples
#' lr_data
"lr_data"

