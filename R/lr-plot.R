
#' Builds an exposure-response plot for a logistic regression model
#'
#' @param data Observed data
#' @param exposure Exposure variable (unquoted)
#' @param response Response variable (unquoted)
#' @param bins Number of exposure bins (not counting placebo)
#' @param panel Character string: "upper", "lower", or "both" (the default)
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

lr_plot_setup <- function(data, exp_name, rsp_name, ...) {

  object <- list(
    data    = list(observed = data, predicted = NULL),
    name    = list(exposure = exp_name, response = rsp_name),
    label   = list(exposure = NULL, response = NULL),
    formula = NULL,
    model   = NULL,
    plot    = list(base = NULL, strip = list(lower = NULL, upper = NULL), box = list()),
    info    = list(),
    output  = NULL
  )

  object$label <- list(
    exposure = attr(object$data$observed[[object$name$exposure]], "label"),
    response = attr(object$data$observed[[object$name$response]], "label")
  )

  object$formula <- stats::as.formula(paste(
    object$name$response, 
    object$name$exposure, 
    sep = "~"
  ))

  object$model <- lr_model(
    formula = object$formula, 
    data = object$data$observed
  )

  object$info$exposure_min <- min(object$data$observed[[object$name$exposure]], na.rm = TRUE)
  object$info$exposure_max <- max(object$data$observed[[object$name$exposure]], na.rm = TRUE)
  object$info$exposure_prd <- seq(object$info$exposure_min, object$info$exposure_max, length.out = 100)
  object$info$model_p   <- summary(object$model)$coefficients[2, "Pr(>|z|)"]
  object$info$format_p  <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$info$format_percent <- scales::label_percent(accuracy = 1)
  object$info$n_bins    <- NA_integer_
  object$info$n_boxes   <- numeric()
  object$info$quantiles <- NULL
  object$info$plot_size <- numeric()

  object$data$predicted <- lr_predict(
    object$model, 
    stats::setNames(data.frame(object$info$exposure_prd), object$name$exposure)
  )
  
  return(structure(.Data = object, class = "erlr_plot"))
}

lr_plot_base_p <- function(object) {

  corner_dist <- object$data$predicted |> 
    dplyr::select(dplyr::all_of(c(object$name$exposure, "fit_resp"))) |> 
    dplyr::rename(y = fit_resp, x = .data[[object$name$exposure]]) |> 
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

  corner_p <- names(sort(corner_dist)[4])
  pval <- tibble::tibble(
    lbl = object$info$format_p(object$info$model_p), 
    cnr = corner_p
  )

  if (corner_p == "tl") {
    return(ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.05), y = I(.95), label = lbl),
      hjust = 0, vjust = 1
    ))
  }

  if (corner_p == "tr") {
    return(ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.95), y = I(.95), label = lbl),
      hjust = 1, vjust = 1
    ))
  }

  if (corner_p == "bl") {
    return(ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.05), y = I(.05), label = lbl),
      hjust = 0, vjust = 0
    ))
  }

  if (corner_p == "br") {
    return(ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.95), y = I(.05), label = lbl),
      hjust = 1, vjust = 0
    ))
  }
      
}

#' @rdname lr_plot
#' @export
lr_plot <- function(data, exposure, response, ...) {

  exp_name <- rlang::as_name(rlang::enquo(exposure))
  rsp_name <- rlang::as_name(rlang::enquo(response))
  object <- lr_plot_setup(data, exp_name, rsp_name, ...)

  object$plot$base <- ggplot2::ggplot() +
    ggplot2::geom_ribbon(
      data = object$data$predicted,
      mapping = ggplot2::aes(
        x = .data[[object$name$exposure]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey50",
      alpha = .5
    ) +
    ggplot2::geom_path(
      data = object$data$predicted,
      mapping = ggplot2::aes(
        x = .data[[object$name$exposure]], 
        y = fit_resp
      ),
      linewidth = 1
    ) +
    lr_plot_base_p(object) +
    ggplot2::scale_y_continuous(
      oob = scales::oob_keep, 
      expand = ggplot2::expansion(mult = .01, add = 0)
    )  +
    ggplot2::coord_cartesian(
      xlim = c(object$info$exposure_min, object$info$exposure_max), 
      ylim = c(0, 1), 
      clip = "off"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(
      panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5),
    ) + 
    ggplot2::labs(
      x = object$label$exposure,
      y = object$label$response
    ) +
    NULL
  
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_add_quantiles <- function(object, bins = 4, conf_level = 0.95) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")

  object$info$n_bins <- bins
  object$data$observed[[".bins"]] <- cut_exposure_quantile(
    exposure = object$data$observed[[object$name$exposure]], 
    n = object$info$n_bins
  )

  object$info$quantiles <- object$data$observed |> 
    dplyr::summarise(
      n1 = sum(.data[[object$name$response]] == 1, na.rm = TRUE),
      n0 = sum(.data[[object$name$response]] == 0, na.rm = TRUE),
      x_mid = mean(.data[[object$name$exposure]], na.rm = TRUE),
      y_mid = n1 / (n0 + n1),
      y_mid_lbl = object$info$format_percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"],
      y_lwr_lbl = ci_lower - 0.05,
      y_upr_lbl = ci_upper + 0.05,
      y_lbl = dplyr::if_else(y_lwr_lbl > 1 - y_upr_lbl, y_lwr_lbl, y_upr_lbl),
      .by = ".bins"
    )

  object$plot$base <- object$plot$base + 
    ggplot2::geom_point(
      data = object$info$quantiles,
      mapping = ggplot2::aes(x = x_mid, y = y_mid),
      inherit.aes = FALSE,
      size = 2
    ) + 
    ggplot2::geom_errorbar(
      data = object$info$quantiles,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
      inherit.aes = FALSE,
      width = 0.025 * (object$info$exposure_max - object$info$exposure_min)
    ) +
    ggplot2::geom_text(
      data = object$info$quantiles,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3
    ) +
    NULL
  
  return(object)
}

lr_strip_dot <- function(object, color_by, panel) {
  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 1)
  if (!is_upr) dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 0)
  nbin <- 100
  dd |> 
    ggplot2::ggplot() +
    ggplot2::geom_dotplot(
      mapping = ggplot2::aes(
        x = .data[[object$name$exposure]], 
        fill = {{color_by}}
      ),
      binwidth = (object$info$exposure_max - object$info$exposure_min) / nbin,
      dotsize = 1,
      method = "histodot",
      stackgroups = TRUE,
      #stackdir = if (is_upr) "up" else "down"
      stackdir = "centerwhole"
    ) +
    ggplot2::coord_cartesian(
      xlim = c(object$info$exposure_min, object$info$exposure_max), 
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
    ) +
    NULL
}

#' @rdname lr_plot
#' @export
lr_plot_add_dotplot_strips <- function(object, color_by = NULL, panel = "both") {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  color_by <- rlang::enquo(color_by)
  if (panel %in% c("lower", "both")) object$plot$strip$lower <- lr_strip_dot(object, !!color_by, "lower")
  if (panel %in% c("upper", "both")) object$plot$strip$upper <- lr_strip_dot(object, !!color_by, "upper")
  return(object)
}

lr_strip_jitter <- function(object, color_by, panel) {
  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 1)
  if (!is_upr) dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 0)
  dd |> 
    ggplot2::ggplot() +
    ggplot2::geom_jitter(
      mapping = ggplot2::aes(
        x = .data[[object$name$exposure]], 
        y = 0, # the panel has its own scale 
        color = {{color_by}}
      ),
      width = 0,
      height = 0.1,
      size = 1
    ) +
    ggplot2::coord_cartesian(
      xlim = c(object$info$exposure_min, object$info$exposure_max), 
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
    ) + 
    NULL
}

#' @rdname lr_plot
#' @export
lr_plot_add_jitter_strips <- function(object, color_by = NULL, panel = "both") {
  color_by <- rlang::enquo(color_by)
  if (panel %in% c("lower", "both")) object$plot$strip$lower <- lr_strip_jitter(object, !!color_by, "lower")
  if (panel %in% c("upper", "both")) object$plot$strip$upper <- lr_strip_jitter(object, !!color_by, "upper")
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_add_boxplot <- function(object, group_by) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")

  grp <- rlang::as_name(rlang::enquo(group_by))

  cnt <- object$data$observed |> 
    dplyr::summarise(
      x = max(.data[[object$name$exposure]], na.rm = TRUE),
      x_off = x + .025 * (object$info$exposure_max - object$info$exposure_min),
      n = sum(!is.na(.data[[object$name$exposure]])),
      lbl = paste0("N=", n),
      .by = {{group_by}}
    ) |> 
    dplyr::mutate(lvl = paste0({{group_by}}, " (", lbl, ")")) |> 
    dplyr::arrange({{group_by}}) # sort by factor order to allow label merge
   
  # drop missing levels, and preserve the label metadata
  plt_data <- object$data$observed
  ll <- attr(plt_data[[grp]], "label")
  plt_data <- plt_data |> dplyr::mutate({{group_by}} := droplevels({{group_by}}))
  levels(plt_data[[grp]]) <- cnt$lvl
  attr(plt_data[[grp]], "label") <- ll

  plt <- plt_data |> 
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[object$name$exposure]], 
      y = {{group_by}}
    )) + 
    ggplot2::geom_boxplot() +
    ggplot2::coord_cartesian(
      xlim = c(object$info$exposure_min, object$info$exposure_max), 
      clip = "off"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5)) +
    NULL

  pos <- length(object$plot$box) + 1L
  object$plot$box[[pos]] <- plt
  object$info$n_boxes <- c(object$info$n_boxes, length(unique(plt_data[[grp]])))
  return(object)  
}
    
lr_plot_build <- function(object, base_height = 6, strip_height = 2, box_height = 3) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")

  margins <- ggplot2::margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
  zero_pt <- ggplot2::unit(0, "pt")

  base_margins <- margins
  upper_strip_margins <- margins
  lower_strip_margins <- margins

  if (!is.null(object$plot$strip$upper)) {
    base_margins[1] <- zero_pt
    upper_strip_margins[3] <- zero_pt
  }
  if (!is.null(object$plot$strip$lower)) {
    base_margins[3] <- zero_pt
    lower_strip_margins[1] <- zero_pt
  }

  plot_list <- list(base = object$plot$base + ggplot2::theme(margins = base_margins))
  object$info$plot_size <- base_height

  if (!is.null(object$plot$strip$upper)) {
    plot_list <- c(
      list(upper = object$plot$strip$upper + ggplot2::theme(margins = upper_strip_margins)),
      plot_list
    )
    object$info$plot_size <- c(strip_height / 2, object$info$plot_size)
  }

  if (!is.null(object$plot$strip$lower)) {
    plot_list <- c(
      plot_list,
      list(lower = object$plot$strip$lower + 
        ggplot2::theme(margins = lower_strip_margins) + 
        ggplot2::guides(  # avoid duplication
          fill = ggplot2::guide_none(),
          color = ggplot2::guide_none()
        )
      )
    )
    object$info$plot_size <- c(object$info$plot_size, strip_height / 2)
  }

  if (!is.null(object$plot$box)) {
    for(b in seq_along(object$plot$box)) {
      plot_list <- c(
        plot_list,
        list(object$plot$box[[b]] + ggplot2::theme(margins = margins))
      )
      box_prop <- object$info$n_boxes[b] / sum(object$info$n_boxes)
      object$info$plot_size <- c(object$info$plot_size, box_height * box_prop)
    }
  }


  if (length(plot_list) == 1) {
    object$output <- object$plot$base
  } else {
    # suppress patchwork warning
    out <- patchwork::wrap_plots(
      plot_list, 
      ncol = 1, 
      heights = object$info$plot_size,
      guides = "collect",
      axes = "collect"
    )
    object$output <- out
  }
  return(object)
}

#' @exportS3Method base::print
print.erlr_plot <- function(x, ...) {
  object <- lr_plot_build(x, ...)
  suppressWarnings(print(object$output)) # TODO: remove once patchwork okay
}
