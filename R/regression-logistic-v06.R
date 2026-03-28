
# available as an R package: https://erlr.djnavarro.net
# it also works as a standalone script

# simple helpers ----------------------------------------------------------

#' Logit and inverse logit functions
#'
#' @param x Numeric vector
#' @returns Numeric vector
#' @examples
#' logit(lr_data$exposure)
#' invlogit(lr_data$response)
#' @name logit
NULL

#' @export
#' @rdname logit
logit <- function(x) log(x / (1-x))

#' @export
#' @rdname logit
invlogit <- function(x) 1 / (1 + exp(-x))


# modelling helpers -------------------------------------------------------

#' Fit a logistic regression function
#'
#' @param formula Model formula
#' @param data Data set
#' @param ... Other arguments passed to `glm()`
#' @returns A glm object
#' @export
#' @examples
#' mod <- lr_model(response ~ exposure, lr_data)
#' 
lr_model <- function(formula, data, ...) {
  stats::glm(formula = formula, data = data, family = stats::binomial(link = "logit"), ...)
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
#' mod <- lr_model(response ~ exposure, lr_data)
#' lr_predict(mod, lr_data)
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
#' mod1 <- lr_model(response ~ exposure + sex, lr_data)
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


# plotting helpers --------------------------------------------------------

#' Builds an exposure-response plot for a logistic regression model
#'
#' @param obs_data Observed data
#' @param prd_data Prediction data
#' @param exposure Exposure variable (unquoted)
#' @param response Response variable (unquoted)
#' @param exp_bins Exposure bin variable (unquoted)
#' @param shade description
#' @param plt description
#' @param ... Other arguments
#'
#' @returns A plot
#'
#' @examples
#' # add example here
#' @name lr_plot

#' @export
#' @rdname lr_plot
lr_plot <- function(obs_data,    # observed data for the points 
                    prd_data,    # prediction data for the lines & ribbon
                    exposure,    # exposure variable (unquoted)
                    response,    # response variable (unquoted)
                    exp_bins,    # exposure quantiles variable (unquoted)
                    ...          # passed to theme()
                    ) {
  plt <- list(
    obs_data = obs_data,
    prd_data = prd_data, 
    exp_name = rlang::as_name(rlang::enquo(exposure)),
    rsp_name = rlang::as_name(rlang::enquo(response))
  )
  plt$exp_lbl = attr(obs_data[[plt$exp_name]], "label")
  plt$rsp_lbl = attr(obs_data[[plt$rsp_name]], "label")
  plt$xlim <- range(c(
    obs_data[[plt$exp_name]], 
    prd_data[[plt$exp_name]]
  ))
  plt$theme_args <- list(...)
  
  return(plt)
}

#' @rdname lr_plot
#' @export
lr_plot_add_base <- function(plt) {

  plt$base <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = plt$prd_data,
      mapping = ggplot2::aes(
        x = !!dplyr::sym(plt$exp_name),
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey50",
      alpha = .5
    ) +
    ggplot2::geom_path(
      data = plt$prd_data,
      mapping = ggplot2::aes(!!dplyr::sym(plt$exp_name), fit_resp),
      linewidth = 1
    ) +
    ggplot2::scale_y_continuous(oob = scales::oob_keep, expand = c(0, 0)) +
    ggplot2::coord_cartesian(xlim = plt$xlim, ylim = c(0, 1), clip = "off") +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    ) + 
    ggplot2::labs(
      x = attr(plt$obs_data[[plt$exp_name]], "label"),
      y = attr(plt$obs_data[[plt$rsp_name]], "label")
    )

  return(plt)
}

#' @rdname lr_plot
#' @export
lr_plot_add_strips <- function(plt, shade = NULL) {

  plot_strip <- function(dd) {
    is_upr <- dplyr::pull(dd, !!dplyr::sym(plt$rsp_name))[1] == 1
    nbin <- 100
    dd |> 
      ggplot2::ggplot() +
      ggplot2::geom_dotplot(
        mapping = ggplot2::aes(x = !!dplyr::sym(plt$exp_name), fill = {{shade}}),
        binwidth = (plt$xlim[2] - plt$xlim[1]) / nbin,
        dotsize = 1,
        method = "histodot",
        stackgroups = TRUE,
        #stackdir = if (is_upr) "up" else "down"
        stackdir = "centerwhole"
    ) +
    ggplot2::coord_cartesian(xlim = plt$xlim, clip = "off") +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.grid.major.y = ggplot2::element_blank(),
      panel.grid.minor.y = ggplot2::element_blank(),
      axis.title.y = ggplot2::element_blank(),
      axis.ticks.y = ggplot2::element_blank(),
      axis.text.y = ggplot2::element_blank(),
      panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    )
  }
    
  plt$upper_strip <- plt$obs_data |> dplyr::filter(!!dplyr::sym(plt$rsp_name) == 1) |> plot_strip()
  plt$lower_strip <- plt$obs_data |> dplyr::filter(!!dplyr::sym(plt$rsp_name) == 0) |> plot_strip()

  return(plt)
}
    
#' @rdname lr_plot
#' @export
lr_plot_build <- function(plt) {

  margins <- ggplot2::margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
  zero_pt <- ggplot2::unit(0, "pt")

  base_margins <- margins
  upper_strip_margins <- margins
  lower_strip_margins <- margins

  if (!is.null(plt$upper_strip)) {
    base_margins[1] <- zero_pt
    upper_strip_margins[3] <- zero_pt
  }
  if (!is.null(plt$lower_strip)) {
    base_margins[3] <- zero_pt
    lower_strip_margins[1] <- zero_pt
  }

  # normally "collect" in wrap_plots() would detect that plt_upr
  # and plt_lwr have the same guide for fill aesthetic, and 
  # remove duplicates. however, because plt_mid doesn't have a
  # fill aesthetic the automatic collection doesn't work here. 
  # so we manually remove the duplicated guide for one of the 
  # two strip plots
  plt$lower_strip <- plt$lower_strip +  ggplot2::guides(fill = ggplot2::guide_none())

  plt_merged <- patchwork::wrap_plots(
    plt$upper_strip + ggplot2::theme(margins = upper_strip_margins), 
    plt$base + ggplot2::theme(margins = base_margins), 
    plt$lower_strip + ggplot2::theme(margins = lower_strip_margins), 
    ncol = 1, 
    heights = c(1, 4, 1),
    guides = "collect",
    axes = "collect"
  )

  return(plt_merged)
}

# mod2 <- lr_model(rsp ~ exp, dat3)
# rng <- range(dat3$exp)
# prd <- tibble::tibble(exp = seq(rng[1], rng[2], length.out = 100))
# prd <- lr_predict(mod2, prd)
# set_label <- function(x, lbl) {attr(x, "label") <- lbl; x}
# dat4 <- dat3 |> 
#   dplyr::mutate(
#     exp = set_label(exp, "Exposure"),
#     rsp = set_label(rsp, "Response"),
#     sex = set_label(sex, "Sex")
#   )

# lr_plot(
#   obs_data = dat4, 
#   prd_data = prd, 
#   exposure = exp, 
#   response = rsp
# ) |> 
#   lr_plot_add_base() |> 
#   lr_plot_add_strips(shade = sex) |> 
#   lr_plot_build()

