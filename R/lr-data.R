

.make_lr_data <- function(seed) {
  n <- 300L
  withr::with_seed(
    seed = seed,
    code = {
      lr_data <- tibble::tibble(
        id = 1:n,
        sex = factor(sample(rep(c("Male", "Female"), c(n/2, n/2)))),
        age = sample(18:35, size = n, replace = TRUE)
      ) |> 
        dplyr::mutate(
          weight = dplyr::if_else(
            condition = sex == "Male",
            true = (stats::runif(dplyr::n(), .05, .95)) |>
              stats::qlnorm(meanlog = 4.284, sdlog = 0.164) |> 
              round(),
            false = (stats::runif(dplyr::n(), .05, .95)) |>
              stats::qlnorm(meanlog = 4.114, sdlog = 0.164) |> 
              round()
          ),
          .by = sex
        ) |> 
        dplyr::mutate(
          dose = sample(rep(c(0, 100, 200), c(n/3, n/3, n/3))),
          treatment = factor(dose == 0, levels = c(TRUE, FALSE), labels = c("Placebo", "Drug")),
          aucss = (stats::runif(n, .05, .95)) |>
            stats::qlnorm() |>
            (\(x) x * (dose + 10 * weight))() |> 
            (\(x) dplyr::if_else(dose == 0, 0, x))() |> 
            round(digits = 3),
          cmaxss = (exp(log(aucss/10) + stats::rnorm(n)/3) + stats::rnorm(n)) |> 
            (\(x) dplyr::if_else(dose == 0, 0, x))() |> 
            round(digits = 3),
          ae1 = as.numeric(logit(stats::runif(n)) < aucss/200 - 2 + 1 * as.numeric(sex=="Female")),
          ae2 = as.numeric(logit(stats::runif(n)) < aucss/500 - 2.0),
        )
    }
  )
  attr(lr_data$id, "label") <- "Subject"
  attr(lr_data$sex, "label") <- "Sex"
  attr(lr_data$age, "label") <- "Age"
  attr(lr_data$weight, "label") <- "Weight"
  attr(lr_data$dose, "label") <- "Dose"
  attr(lr_data$treatment, "label") <- "Treatment"
  attr(lr_data$aucss, "label") <- "AUCss"
  attr(lr_data$cmaxss, "label") <- "Cmax,ss"
  attr(lr_data$ae1, "label") <- "Response 1"
  attr(lr_data$ae2, "label") <- "Response 2"
  return(lr_data)
}

#lr_data <- .make_lr_data(seed = 2407L)
#usethis::use_data(lr_data, overwrite = TRUE)

#' Sample simulated data for logistic regression exposure-response models with covariates
#'
#' @name lr_data
#' @format A data frame with columns:
#' \describe{
#' \item{id}{Identifier}
#' \item{sex}{Sex}
#' \item{age}{Age}
#' \item{weight}{Weight}
#' \item{dose}{Nominal dose, units not specified}
#' \item{treatment}{Treatment}
#' \item{aucss}{AUCss}
#' \item{cmaxss}{Cmax,ss}
#' \item{ae1}{Binary response 1 value}
#' \item{ae2}{Binary response 2 value}
#' }
#' @details
#'
#' This simulated dataset is entirely synthetic
#' You can find the data generating code in the package source code
#'
#' @examples
#' lr_data
"lr_data"

