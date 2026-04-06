
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

clopper_pearson <- function(x, n, conf_level = 0.95) {
  alpha <- 1 - conf_level
  lower <- if (x > 0) stats::qbeta(alpha/2, x, n - x + 1) else 0
  upper <- if (x < n) stats::qbeta(1 - alpha/2, x + 1, n - x) else 1
  return(c(lower = lower, upper = upper))
}

cut_exposure_quantile <- function(exposure, n = 4, is_placebo = NULL) {
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
