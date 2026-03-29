
# available as an R package: https://erlr.djnavarro.net
# it also works as a standalone script

# simple helpers ----------------------------------------------------------

#' Logit and inverse logit functions
#'
#' @param x Numeric vector
#' @returns Numeric vector
#' @examples
#' logit(lr_data$exposure_1)
#' invlogit(lr_data$response_1)
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
#' mod <- lr_model(response_1 ~ exposure_1, lr_data)
#' mod
#' 
lr_model <- function(formula, data, ...) {
  mod <- stats::glm(formula = formula, data = data, family = stats::binomial(link = "logit"), ...)
  class(mod) <- c("erlr_glm", class(mod)) # append class in case new methods are required
  mod$erlr <- list(type = "logistic") # internal "erlr" list to store erlr-specific info
  mod
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


# plotting helpers --------------------------------------------------------

# used during plots
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

#' Builds an exposure-response plot for a logistic regression model
#'
#' @param data Observed data
#' @param exposure Exposure variable (unquoted)
#' @param response Response variable (unquoted)
#' @param bins Number of exposure bins (not counting placebo)
#' @param conf_level Confidence level for Clopper-Pearson intervals
#' @param color_by Variable (unquoted) to assign colors to strip plot dots
#' @param group_by Variable (unquoted) to use to stratify exposure boxplots
#' @param object Partially constructed plot (has S3 class `erlr_plot`)
#' @param ... Other arguments
#'
#' @returns Plot object of class `erlr_plot`
#'
#' @examples
#' lr_data |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_add_quantiles(bins = 4) |> 
#'   lr_plot_add_boxplot(group_by = quartile_1) |> 
#'   print()
#' 
#' lr_data |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_add_quantiles(bins = 4) |> 
#'   lr_plot_add_jitter_strips(color_by = sex) |> 
#'   lr_plot_add_boxplot(group_by = quartile_1) |> 
#'   print()  
#' 
#' lr_data[1:70,] |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_add_quantiles(bins = 4) |> 
#'   lr_plot_add_dotplot_strips(color_by = sex) |> 
#'   lr_plot_add_boxplot(group_by = quartile_1) |> 
#'   lr_plot_add_boxplot(group_by = sex) |> 
#'   print(box_height = 2)
#' 
#' @name lr_plot
NULL

#' @rdname lr_plot
#' @export
lr_plot <- function(data, exposure, response, ...) {

  object <- list(
    obs_data = data,
    prd_data = NULL,
    exp_name = rlang::as_name(rlang::enquo(exposure)),
    rsp_name = rlang::as_name(rlang::enquo(response)),
    bins = NULL,
    theme_args = list(...)
  )
  object$formula <- stats::as.formula(paste(object$rsp_name, object$exp_name, sep = "~"))
  object$model <- lr_model(formula = object$formula, data = object$obs_data)
  object$exp_lbl = attr(object$obs_data[[object$exp_name]], "label")
  object$rsp_lbl = attr(object$obs_data[[object$rsp_name]], "label")
  object$xlim <- range(data[[object$exp_name]])

  rng <- range(object$obs_data[[object$exp_name]])
  prd <- data.frame(x = seq(rng[1], rng[2], length.out = 100))
  names(prd) <- object$exp_name 
  object$prd_data <- lr_predict(object$model, prd)

  smm <- summary(object$model)
  object$model_p <- smm$coefficients[2, "Pr(>|z|)"]
  p_value <- scales::label_pvalue(accuracy = .001, add_p = TRUE)

  object$corner_dist <- object$prd_data |> 
    dplyr::select(dplyr::all_of(c(object$exp_name, "fit_resp"))) |> 
    dplyr::rename(y = fit_resp, x = .data[[object$exp_name]]) |> 
    dplyr::mutate(
      x = x / sum(x),
      tl_dist = sqrt(x^2 + (1-y)^2),
      tr_dist = sqrt((1-x)^2 + (1-y)^2),
      bl_dist = sqrt(x^2 + y^2),
      br_dist = sqrt((1-x)^2 + y^2)
    ) |> 
    dplyr::summarise(
      tl = min(tl_dist, na.rm = TRUE),
      tr = min(tr_dist, na.rm = TRUE),
      bl = min(bl_dist, na.rm = TRUE),
      br = min(br_dist, na.rm = TRUE)
    ) |> 
    unlist()

  corner_p <- names(sort(object$corner_dist)[4])

  layer_p <- function(cnr) {
    pval <- tibble::tibble(
      lbl = p_value(object$model_p),
      cnr = cnr
    )
    if (cnr == "tl") {
      return(ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(x = I(.05), y = I(.95), label = lbl),
        hjust = 0, vjust = 1
      ))
    }
    if (cnr == "tr") {
      return(ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(x = I(.95), y = I(.95), label = lbl),
        hjust = 1, vjust = 1
      ))
    }
    if (cnr == "bl") {
      return(ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(x = I(.05), y = I(.05), label = lbl),
        hjust = 0, vjust = 0
      ))
    }
    if (cnr == "br") {
      return(ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(x = I(.95), y = I(.05), label = lbl),
        hjust = 1, vjust = 0
      ))
    }
  }

  object$base <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = object$prd_data,
      mapping = ggplot2::aes(
        x = .data[[object$exp_name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey50",
      alpha = .5
    ) +
    ggplot2::geom_path(
      data = object$prd_data,
      mapping = ggplot2::aes(.data[[object$exp_name]], fit_resp),
      linewidth = 1
    ) +
    layer_p(corner_p) +
    ggplot2::scale_y_continuous(
      oob = scales::oob_keep, 
      expand = ggplot2::expansion(mult = .01, add = 0)
    )  +
    ggplot2::coord_cartesian(xlim = object$xlim, ylim = c(0, 1), clip = "off") +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    ) + 
    ggplot2::labs(
      x = attr(object$obs_data[[object$exp_name]], "label"),
      y = attr(object$obs_data[[object$rsp_name]], "label")
    )
  
  object$strip <- list(upper = NULL, lower = NULL)
  object$box <- NULL  
  object$n_boxes <- numeric()

  return(structure(.Data = object, class = "erlr_plot"))
}

clopper_pearson <- function(x, n, conf_level = 0.95) {
  alpha <- 1 - conf_level
  lower <- if (x > 0) stats::qbeta(alpha/2, x, n - x + 1) else 0
  upper <- if (x < n) stats::qbeta(1 - alpha/2, x + 1, n - x) else 1
  return(c(lower = lower, upper = upper))
}

#' @rdname lr_plot
#' @export
lr_plot_add_quantiles <- function(object, bins = 4, conf_level = 0.95) {

  percent <- scales::label_percent(accuracy = 1)
  object$bins <- bins
  object$obs_data[[".bins"]] <- cut_exposure_quantile(
    exposure = object$obs_data[[object$exp_name]], 
    n = bins
  )

  object$quantiles <- object$obs_data |> 
    dplyr::summarise(
      n1 = sum(.data[[object$rsp_name]] == 1, na.rm = TRUE),
      n0 = sum(.data[[object$rsp_name]] == 0, na.rm = TRUE),
      x_mid = mean(.data[[object$exp_name]], na.rm = TRUE),
      y_mid = n1 / (n0 + n1),
      y_mid_lbl = percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"],
      y_lwr_lbl = ci_lower - 0.05,
      y_upr_lbl = ci_upper + 0.05,
      y_lbl = dplyr::if_else(y_lwr_lbl > 1 - y_upr_lbl, y_lwr_lbl, y_upr_lbl),
      .by = ".bins"
    )

  object$base <- object$base + 
    ggplot2::geom_point(
      data = object$quantiles,
      mapping = ggplot2::aes(x_mid, y_mid),
      inherit.aes = FALSE,
      size = 2
    ) + 
    ggplot2::geom_errorbar(
      data = object$quantiles,
      mapping = ggplot2::aes(x_mid, ymin = ci_lower, ymax = ci_upper),
      inherit.aes = FALSE,
      width = 0.025 * (object$xlim[2] - object$xlim[1])
    ) +
    ggplot2::geom_text(
      data = object$quantiles,
      mapping = ggplot2::aes(x_mid, y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3
    )
  
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_add_dotplot_strips <- function(object, color_by = NULL) {

  strip <- function(dd) {
    is_upr <- dplyr::pull(dd, .data[[object$rsp_name]])[1] == 1
    nbin <- 100
    dd |> 
      ggplot2::ggplot() +
      ggplot2::geom_dotplot(
        mapping = ggplot2::aes(
          x = .data[[object$exp_name]], 
          fill = {{color_by}}
        ),
        binwidth = (object$xlim[2] - object$xlim[1]) / nbin,
        dotsize = 1,
        method = "histodot",
        stackgroups = TRUE,
        #stackdir = if (is_upr) "up" else "down"
        stackdir = "centerwhole"
    ) +
    ggplot2::coord_cartesian(xlim = object$xlim, clip = "off") +
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
    
  object$strip <- list(
    upper = object$obs_data |> dplyr::filter(.data[[object$rsp_name]] == 1) |> strip(),
    lower = object$obs_data |> dplyr::filter(.data[[object$rsp_name]] == 0) |> strip()
  )
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_add_jitter_strips <- function(object, color_by = NULL) {

  strip <- function(dd) {
    is_upr <- dplyr::pull(dd, .data[[object$rsp_name]])[1] == 1
    dd |> 
      ggplot2::ggplot() +
      ggplot2::geom_jitter(
        mapping = ggplot2::aes(
          x = .data[[object$exp_name]], 
          y = 0, # the panel has its own scale 
          color = {{color_by}}
        ),
        width = 0,
        height = 0.1,
        size = 1
    ) +
    ggplot2::coord_cartesian(
      xlim = object$xlim, 
      ylim = c(-0.1, 0.1),
      clip = "off"
    ) +
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
    
  object$strip <- list(
    upper = object$obs_data |> dplyr::filter(.data[[object$rsp_name]] == 1) |> strip(),
    lower = object$obs_data |> dplyr::filter(.data[[object$rsp_name]] == 0) |> strip()
  )
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_add_boxplot <- function(object, group_by) {

  grp <- rlang::as_name(rlang::enquo(group_by))
  plt <- object$obs_data |> 
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[object$exp_name]],
      y = {{group_by}}
    )) + 
    ggplot2::geom_boxplot() + 
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    )

  if (is.null(object$box)) object$box <- list()
  pos <- length(object$box) + 1L
  object$box[[pos]] <- plt
  object$n_boxes <- c(
    object$n_boxes, 
    length(unique(object$obs_data[[grp]]))
  )
  return(object)  
}
    
lr_plot_build <- function(object, base_height = 4, strip_height = 2, box_height = 2) {
  if (is.null(object$base)) return(invisible(object))

  margins <- ggplot2::margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
  zero_pt <- ggplot2::unit(0, "pt")

  base_margins <- margins
  upper_strip_margins <- margins
  lower_strip_margins <- margins

  if (!is.null(object$strip$upper)) {
    base_margins[1] <- zero_pt
    upper_strip_margins[3] <- zero_pt
  }
  if (!is.null(object$strip$lower)) {
    base_margins[3] <- zero_pt
    lower_strip_margins[1] <- zero_pt
  }

  plt_list <- list(base = object$base + ggplot2::theme(margins = base_margins))
  plt_size <- base_height

  if (!is.null(object$strip$upper)) {
    plt_list <- c(
      list(upper = object$strip$upper + ggplot2::theme(margins = upper_strip_margins)),
      plt_list
    )
    plt_size <- c(strip_height / 2, plt_size)
  }

  if (!is.null(object$strip$lower)) {
    plt_list <- c(
      plt_list,
      list(lower = object$strip$lower + 
        ggplot2::theme(margins = lower_strip_margins) + 
        ggplot2::guides(  # avoid duplication
          fill = ggplot2::guide_none(),
          color = ggplot2::guide_none()
        )
      )
    )
    plt_size <- c(plt_size, strip_height / 2)
  }

  if (!is.null(object$box)) {
    for(b in seq_along(object$box)) {
      plt_list <- c(
        plt_list,
        list(object$box[[b]] + ggplot2::theme(margins = margins))
      )
      box_prop <- object$n_boxes[b] / sum(object$n_boxes)
      plt_size <- c(plt_size, box_height * box_prop)
    }
  }

  if (length(plt_list) == 1) return(object$base)

  plt_merged <- patchwork::wrap_plots(
    plt_list, 
    ncol = 1, 
    heights = plt_size,
    guides = "collect",
    axes = "collect"
  )
  return(plt_merged)
}

#' @exportS3Method base::print
print.erlr_plot <- function(x, ...) lr_plot_build(x, ...)

# vpc helpers -------------------------------------------------------------

#' VPC simulations for logistic regression models
#'
#' @param object Logistic regression model
#' @param nsim Number of replicates
#' @param seed RNG state
#'
#' @returns A data frame or tibble
#'
#' @export
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
#' sim <- lr_vpc_sim(mod)
#' sim
#' 
lr_vpc_sim <- function(object, nsim = 100, seed = NULL) {

  ff <- object$formula
  vv <- all.vars(ff)
  exp_var <- vv[2]
  rsp_var <- vv[1]
  fn <- lr_simulator(object)
  dd <- object$data[, vv]

  if (!is.null(seed)) set.seed(seed)
  par <- mvtnorm::rmvnorm(
    n = nsim, 
    mean = stats::coef(object),
    sigma = stats::vcov(object)
  )
  sim <- list()
  for (ii in 1:nsim) {
    dd_sim <- dd |> 
      dplyr::mutate(
        row_id = dplyr::row_number(),
        sim_id = ii
      )
    dd_sim[[rsp_var]] <- fn(param = par[ii,], dd_sim)
    sim[[ii]] <- dd_sim
  }
  sim <- dplyr::bind_rows(sim)

  return(sim)
}

#' Plot VPC simulations for logistic regression models
#'
#' @param object Logistic regression model
#' @param sim VPC simulations
#' @param group_by Variable (unquoted) to stratify predictions
#' @param conf_level Confidence level
#'
#' @returns A ggplot2 object
#'
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
#' sim <- lr_vpc_sim(mod)
#' lr_vpc_plot(mod, sim, group_by = exposure_1)
#' lr_vpc_plot(mod, sim, group_by = sex)
#' 
#' @export
#' 
lr_vpc_plot <- function(object, sim, group_by, conf_level = 0.95) {

  ff <- object$formula
  vv <- all.vars(ff)
  exp_var <- vv[2]
  rsp_var <- vv[1]
  grp_var <- rlang::as_name(rlang::enquo(group_by))
  obs <- object$data[, vv] |> 
    dplyr::mutate(
      row_id = dplyr::row_number(),
      sim_id = 0L
    )
  dat <- dplyr::bind_rows(
    Observed = obs,
    Simulated = sim,
    .id = "Source"
  )

  if (is.numeric(dat[[grp_var]])) {
    if (grp_var == exp_var) dat[[".is_placebo"]] <- dat[[exp_var]] == 0
    if (grp_var != exp_var) dat[[".is_placebo"]] <- rep(FALSE, nrow(dat))

    dat <- dat |> dplyr::mutate(
      .quantile = cut_exposure_quantile(
        exposure = .data[[grp_var]], 
        n = 4, 
        is_placebo = .data[[".is_placebo"]]
      ),
      .by = "Source"
    )
    attr(dat[[".quantile"]], "label") <- attr(dat[[grp_var]], "label")
    grp_var <- ".quantile"
  }

  percent <- scales::label_percent(accuracy = 1)
  smm_obs <- dat |>
    dplyr::filter(Source == "Observed") |> 
    dplyr::summarise(
      n1 = sum(!!dplyr::sym(rsp_var) == 1, na.rm = TRUE),
      n0 = sum(!!dplyr::sym(rsp_var) == 0, na.rm = TRUE),
      y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
      y_mid_lbl = percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"], 
      .by = c("Source", grp_var)
    ) |> 
    dplyr::select(-n1, -n0)

  alpha <- (1 - conf_level)/2
  smm_sim <- dat |> 
    dplyr::filter(Source == "Simulated") |> 
    dplyr::summarise(
      y = mean(.data[[rsp_var]], na.rm = TRUE),
      .by = c("Source", grp_var, "sim_id")
    ) |> 
    dplyr::summarise(
      y_mid = mean(y, na.rm = TRUE),
      y_mid_lbl = percent(y_mid),
      ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE), 
      ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE), 
      .by = c("Source", grp_var)
    )

  smm <- dplyr::bind_rows(smm_obs, smm_sim)

  plt <- smm |> 
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[grp_var]], 
      y = y_mid,
      color = Source
    )) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = ci_lower,
        ymax = ci_upper
      ),
      position = ggplot2::position_dodge2(width = .2),
      width = .2
    ) + 
    ggplot2::geom_point(
      position = ggplot2::position_dodge2(width = .2),
      size = 2
    ) +
    ggplot2::theme_bw()

  return(plt)
}
