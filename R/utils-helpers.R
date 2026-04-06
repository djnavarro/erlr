
`%||%` <- function(x, y) {
  if (is.null(x)) return(y)
  x
}

.get_label <- function(x) attr(x, "label")
.set_label <- function(x, lbl) {attr(x, "label") <- lbl; x}
.set_names <- function(x, nm) {names(x) <- nm; x}

.pick_seed <- function() {999 + sample.int(9000, size = 1L)}

.as_erlr <- function(mod) {
  class(mod) <- c("erlr_glm", class(mod)) # append class in case new methods are required
  mod$erlr <- list(type = "logistic") # internal "erlr" list to store erlr-specific info
  mod
}

# simple helpers ----------------------------------------------------------

#' Logit and inverse logit functions
#'
#' @param x Numeric vector
#' @returns Numeric vector
#' @examples
#' logit((1:9)/10)
#' invlogit(-3:3)
#' logit(invlogit(-3:3))
#' @name logit
NULL

#' @export
#' @rdname logit
logit <- function(x) log(x / (1-x))

#' @export
#' @rdname logit
invlogit <- function(x) 1 / (1 + exp(-x))

#' Clopper-Pearson confidence interval for binary data
#'
#' @param x Number of successes
#' @param n Total number of trials
#' @param conf_level Confidence level
#'
#' @returns Named numeric vector, with confidence level stored as an attribute
#'
#' @export
#' @examples
#' clopper_pearson(1, 10)
#' 
clopper_pearson <- function(x, n, conf_level = 0.95) {
  alpha <- 1 - conf_level
  lower <- if (x > 0) stats::qbeta(alpha/2, x, n - x + 1) else 0
  upper <- if (x < n) stats::qbeta(1 - alpha/2, x + 1, n - x) else 1
  ci <- c(lower = lower, upper = upper)
  attr(ci, "conf_level") <- conf_level
  return(ci)
}


#' Cut a continuous variable into quantiles
#'
#' @param x Numeric vector
#' @param n Number of bins
#' @param is_placebo Logical vector indicating placebo samples
#'
#' @returns A factor
#'
#' @name cut_quantile
#' @examples
#' cut_quantile(lr_data$weight) 
#' cut_exposure_quantile(lr_data$aucss)
#' 
NULL

#' @export
#' @rdname cut_quantile
cut_exposure_quantile <- function(x, n = 4, is_placebo = NULL) {
  if (is.null(is_placebo)) is_placebo <- x == 0
  breaks <- tibble::tibble(x, is_placebo) |>
    dplyr::filter(!is_placebo) |>
    dplyr::pull(x) |>
    stats::quantile(probs = (0:n)/n, na.rm = TRUE)
  exp_bin <- as.numeric(dplyr::case_when(
    is_placebo ~ "0",
    is.na(x) ~ NA_character_,
    TRUE ~ cut(x, breaks, labels = 1:n, include.lowest = TRUE)
  ))
  exp_quantile <- exp_bin |>
    factor(levels = 0:n, labels = c("Placebo", paste0("Q", 1:n)))  
  return(exp_quantile)
}

#' @export
#' @rdname cut_quantile
cut_quantile <- function(x, n = 4) {
  breaks <- stats::quantile(x, probs = (0:n)/n, na.rm = TRUE)
  bin_num <- as.numeric(cut(x, breaks, labels = 1:n, include.lowest = TRUE))
  bin_fct <- factor(bin_num, levels = 1:n, labels = paste0("Q", 1:n)) 
  return(bin_fct)
}

