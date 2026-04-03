

as_erlr <- function(mod) {
  class(mod) <- c("erlr_glm", class(mod)) # append class in case new methods are required
  mod$erlr <- list(type = "logistic") # internal "erlr" list to store erlr-specific info
  mod
}

#' Fit a logistic regression function
#'
#' @param formula Model formula
#' @param data Data set
#' @param ... Other arguments passed to `glm()`
#' @returns A glm object
#' @export
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1, lr_data)
#' mod
#' 
lr_model <- function(formula, data, ...) {
  mod <- stats::glm(formula = formula, data = data, family = stats::binomial(link = "logit"), ...)
  as_erlr(mod)
}

# extract model predictions and confidence intervals for a new data set.
# should work for any glm, not just logistic. adapted from:
# https://fromthebottomoftheheap.net/2018/12/10/confidence-intervals-for-glms/

#' Predictions and confidence intervals for logistic regression
#'
#' @param object A logistic regression model
#' @param newdata Data frame containing cases to be predicted
#' @param conf_level Confidence level for the intervals
#' @returns A tibble
#'
#' @export
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1, lr_data)
#' prd <- lr_predict(mod, lr_data)
#' prd
#' 
lr_predict <- function(object, newdata, conf_level = .95) {
  inverse_link <- stats::family(object)$linkinv
  z_scale <- -stats::qnorm((1 - conf_level)/2)
  out <- newdata |> 
    dplyr::bind_cols(
      stats::setNames(
        tibble::as_tibble(stats::predict(object, newdata, se.fit = TRUE, type = "link")[1:2]),
        c('fit_link','se_link')
      )
    ) |> 
    dplyr::mutate(
      fit_resp = inverse_link(fit_link),
      ci_lower = inverse_link(fit_link - (z_scale * se_link)),
      ci_upper = inverse_link(fit_link + (z_scale * se_link)),
    )
  return(out)
}

#' Simulate from a logistic regression model
#'
#' @param object A logistic regression model
#'
#' @returns A function with arguments `param`, `data`, and `type`.
#' - The `param` argument should be a vector of coefficients
#' - The `data` argument should be a data frame or tibble
#' - The `type` argument should be a string indicating the type
#'   of prediction to generate (defaults to `"response"`)
#'
#' Takes a fitted glm object as input and returns a function
#' that will evaluate the underlying structural model with
#' user-specified parameters or data (e.g., for VPCs or
#' other counterfactual simulation scenarios). In principle
#' this should work for glms more generally, not merely 
#' logistic regressions, but has not been tested except for
#' logistic regression models
#'  
#' @examples
#' mod1 <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
#' par1 <- coef(mod1)
#' mod1_sim <- lr_simulator(mod1)
#' 
#' # no counterfactuals
#' p1 <- mod1_sim(param = par1, data = lr_data) 
#' p2 <- unname(predict(mod1, type = "response")) # same result
#' 
#' # user modifies the data set
#' lr_data2 <- lr_data[1:20, ]
#' p3 <- mod1_sim(param = par1, data = lr_data2) 
#' p4 <- unname(predict(mod1, newdata = lr_data2, type = "response")) # same result
#' 
#' # user modifies the parameters
#' par2 <- par1
#' int1 <- par1["(Intercept)"]
#' par2["(Intercept)"] <- 0
#' p5 <- mod1_sim(param = par2, data = lr_data)
#' 
#' @export
#' 
lr_simulator <- function(object) {
  ff <- object$formula
  force(ff)
  function(param, data, type = "response") {
    mm <- stats::model.matrix(ff, data)
    pred <- as.vector(mm %*% param)
    if (type == "response") pred <- stats::family(object)$linkinv(pred)
    return(pred)
  }
}

