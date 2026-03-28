
.cut_exposure_quantile <- function(exposure, n = 4, is_placebo = NULL) {
  if (is.null(is_placebo)) is_placebo <- exposure == 0
  breaks <- tibble::tibble(exposure, is_placebo) |>
    dplyr::filter(!is_placebo) |>
    dplyr::pull(exposure) |>
    stats::quantile(probs = (0:n)/n, na.rm = TRUE)
  exp_bin <- as.numeric(dplyr::case_when(
    is_placebo ~ "0",
    is.na(exposure) ~ NA_character_,
    TRUE ~ cut(exposure, breaks, labels = 1:n, include.lowest = TRUE)
  ))
  exp_quantile <- exp_bin |>
    factor(levels = 0:n, labels = c("Placebo", paste0("Q", 1:n)))  
  return(exp_quantile)
}

.make_lr_data <- function(seed) {
  set.seed(seed)
  n <- 300L
  lr_dat <- tibble::tibble(
    id = 1:n,
    dose = sample(rep(c(0, 100, 200), c(n/3, n/3, n/3))),
    exposure = stats::qlnorm(p = stats::runif(n, .05, .95)) * dose,
    exposure_quartile = .cut_exposure_quantile(exposure),
    response = as.numeric(logit(stats::runif(n)) < exposure/100 - .1),
    sex = factor(sample(rep(c("Male", "Female"), c(n/2, n/2))))
  )
  attr(lr_dat$id, "label") <- "Subject ID"
  attr(lr_dat$dose, "label") <- "Dose"
  attr(lr_dat$exposure, "label") <- "Exposure"
  attr(lr_dat$exposure_quartile, "label") <- "Exposure Group"
  attr(lr_dat$response, "label") <- "Response"
  attr(lr_dat$sex, "label") <- "Sex"
  return(lr_dat)
}

# lr_dat <- .make_lr_data(seed = 2407L)
# usethis::use_data(lr_dat, overwrite = TRUE)

#' Sample simulated data for logistic regression exposure-response models with covariates.
#'
#' @name lr_dat
#' @format A data frame with columns:
#' \describe{
#' \item{id}{Identifier}
#' \item{dose}{Nominal dose, units not specified}
#' \item{exposure}{Exposure value, units and metric not specified}
#' \item{exposure_quartile}{Exposure quartile, with placebo group separate}
#' \item{response}{Continuous response value (units not specified)}
#' \item{sex}{Sex}
#' }
#' @details
#'
#' This simulated dataset is entirely synthetic
#' You can find the data generating code in the package source code
#'
#' @examples
#' lr_dat
"lr_dat"

