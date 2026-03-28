

make_lr_data <- function(seed) {
  set.seed(seed)
  n <- 300L
  lr_data <- tibble::tibble(
    id = 1:n,
    dose = sample(rep(c(0, 100, 200), c(n/3, n/3, n/3))),
    exposure = stats::qlnorm(p = stats::runif(n, .05, .95)) * dose,
    quartile = cut_exposure_quantile(exposure),
    response = as.numeric(logit(stats::runif(n)) < exposure/100 - .1),
    sex = factor(sample(rep(c("Male", "Female"), c(n/2, n/2))))
  )
  attr(lr_data$id, "label") <- "Subject ID"
  attr(lr_data$dose, "label") <- "Dose"
  attr(lr_data$exposure, "label") <- "Exposure"
  attr(lr_data$quartile, "label") <- "Exposure Quartile"
  attr(lr_data$response, "label") <- "Response"
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
#' \item{exposure}{Exposure value, units and metric not specified}
#' \item{quartile}{Exposure quartile, with placebo group separate}
#' \item{response}{Continuous response value (units not specified)}
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

