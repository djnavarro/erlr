
#' Builds an exposure-response plot for a logistic regression model
#'
#' @param data Observed data
#' @param exposure Exposure variable (unquoted)
#' @param response Response variable (unquoted)
#' @param color_by Stratification variable used for color and fill (unquoted)
#' @param boxes_by Stratification variable to define groups for boxplots (unquoted)
#' @param labels Named list of labels
#' @param bins Number of exposure bins (not counting placebo)
#' @param style Character string: "jitter" (the default) or "dotplot"
#' @param panel Character string: "upper", "lower", or "both" (the default)
#' @param conf_level Confidence level for Clopper-Pearson intervals
#' @param object Partially constructed plot (has S3 class `erlr_plot`)
#' @param ... Other arguments
#'
#' @returns Plot object of class `erlr_plot`
#'
#' @examples
#' lr_data |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_add_model() |> 
#'   lr_plot_add_quantiles() |> 
#'   lr_plot_add_boxplot(quartile_1) |> 
#'   print()
#' 
#' lr_data |> 
#'   lr_plot(exposure_1, response_1, sex) |> 
#'   lr_plot_add_model() |> 
#'   lr_plot_add_quantiles() |> 
#'   lr_plot_add_strips() |> 
#'   lr_plot_add_boxplot(quartile_1) |> 
#'   print()  
#' 
#' lr_data[1:70,] |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_add_model() |> 
#'   lr_plot_add_quantiles(bins = 6) |> 
#'   lr_plot_add_strips(sex, style = "dotplot") |> 
#'   lr_plot_add_boxplot(quartile_1) |> 
#'   lr_plot_add_boxplot(sex) |> 
#'   print(box_height = 2)
#' 
#' @name lr_plot
NULL


# setup -----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot <- function(data, exposure, response, color_by = NULL, labels = NULL, ...) {

  # empty plot object
  object <- structure(
    list(
      data    = list(observed = NULL, predicted = NULL),
      name    = list(exposure = NULL, response = NULL, strata = NULL),
      label   = list(exposure = NULL, response = NULL, strata = NULL),
      formula = NULL,
      model   = NULL,
      plot    = list(base = NULL, strip = list(lower = NULL, upper = NULL), box = list()),
      info    = list(),
      output  = NULL
    ),
    class = "erlr_plot"
  )

  # store observed data
  object$data$observed <- data

  # store variable names
  object$name$exposure <- rlang::as_name(rlang::enquo(exposure))
  object$name$response <- rlang::as_name(rlang::enquo(response)) 
  strata_name <- rlang::enquo(color_by)
  if (!rlang::quo_is_null(strata_name)) object$name$strata <- rlang::as_name(strata_name)
  
  # fallback for variable labels, using attributes
  if (is.null(labels)) labels <- list(exposure = NULL, response = NULL, strata = NULL)
  object$label$exposure <- labels$exposure %||% get_label(object$data$observed[[object$name$exposure]])
  object$label$response <- labels$response %||% get_label(object$data$observed[[object$name$response]])
  if (!is.null(object$name$strata)) {
    object$label$strata <- labels$strata   %||% get_label(object$data$observed[[object$name$strata]])
  }

  # start populating the miscellaneous information store
  object$info$exposure_min   <- min(object$data$observed[[object$name$exposure]], na.rm = TRUE)
  object$info$exposure_max   <- max(object$data$observed[[object$name$exposure]], na.rm = TRUE)
  object$info$exposure_prd   <- seq(object$info$exposure_min, object$info$exposure_max, length.out = 300)
  object$info$format_p       <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$info$format_percent <- scales::label_percent(accuracy = 1)
  object$info$n_bins         <- NA_integer_
  object$info$n_boxes        <- numeric()
  object$info$quantiles      <- NULL
  object$info$plot_size      <- numeric()

  # initialise the base plot
  object$plot$base <- ggplot2::ggplot() +
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


# model -----------------------------------------------------------------------

lr_contextual_strata <- function(object, strata) {
  strata_quo <- rlang::enquo(strata)
  strata_val <- rlang::eval_tidy(
    rlang::quo_set_env(
      quo = strata_quo, 
      env = rlang::as_environment(object$data$observed)
    )
  )
  if (rlang::quo_is_null(strata_quo)) { # if strata is NULL
    strata_name  <- NULL
    strata_label <- NULL
  } else if (rlang::quo_is_symbol(strata_quo)) { # if strata is a variable name
    strata_name <- rlang::as_name(strata_quo)
    strata_label <- get_label(object$data$observed[[strata_name]])
  } else if (strata_val == "inherit") { # use cached value
    strata_name <- object$name$strata
    strata_label <- object$label$strata
  } 
  return(list(name = strata_name, label = strata_label))
}

#' @rdname lr_plot
#' @export
lr_plot_add_model <- function(object, color_by = "inherit") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  strata <- lr_contextual_strata(object, !!rlang::enquo(color_by))

  # model formula
  fml <- paste(object$name$response, object$name$exposure, sep = " ~ ")
  if (!is.null(strata$name)) fml <- paste(fml, strata$name, sep = " + ")
  object$formula <- stats::as.formula(fml)

  # model
  object$model <- lr_model(
    formula = object$formula, 
    data = object$data$observed
  )

  # p-value is different depending on stratification: currently only supported when no strata
  if (is.null(strata$name)) {
    object$info$model_p <- summary(object$model)$coefficients[2, "Pr(>|z|)"]
  }

  # model predictions data
  pred_dat <- stats::setNames(
    data.frame(object$info$exposure_prd), 
    object$name$exposure
  )
  if (!is.null(strata$name)) {
    pred_dat <- dplyr::cross_join(
      pred_dat, 
      stats::setNames(
        data.frame(unique(object$data$observed[[strata$name]])), 
        strata$name
      )
    )
  }
  object$data$predicted <- lr_predict(object$model, pred_dat)

  object$plot$base <- object$plot$base +  
    lr_plot_model_ribbon(object, strata) +
    lr_plot_model_line(object, strata) +
    lr_plot_model_p(object, strata)
  
  if (!is.null(strata$name)) {
    object$plot$base <- object$plot$base +
      ggplot2::labs(color = strata$label, fill = strata$label)
  }

  return(object)
}

lr_plot_model_ribbon <- function(object, strata) {
  if (is.null(strata$name)) {
    return(
      ggplot2::geom_ribbon(
        data = object$data$predicted,
        mapping = ggplot2::aes(
          x = .data[[object$name$exposure]],
          ymin = ci_lower,
          ymax = ci_upper
        ),
        fill = "grey40",
        alpha = .25
      )
    )
  }
  ggplot2::geom_ribbon(
    data = object$data$predicted,
    mapping = ggplot2::aes(
      x = .data[[object$name$exposure]],
      fill = .data[[strata$name]],
      ymin = ci_lower,
      ymax = ci_upper
    ),
    alpha = .25
  )
}

lr_plot_model_line <- function(object, strata) {
  if (is.null(strata$name)) {
    return(
      ggplot2::geom_path(
        data = object$data$predicted,
        mapping = ggplot2::aes(
          x = .data[[object$name$exposure]], 
          y = fit_resp
        ),
        linewidth = 1
      )
    )
  }
  ggplot2::geom_path(
    data = object$data$predicted,
    mapping = ggplot2::aes(
      x = .data[[object$name$exposure]], 
      y = fit_resp,
      color = .data[[strata$name]]
    ),
    linewidth = 1
  )
}

lr_plot_model_p <- function(object, strata) {

  distance_from_corners <- object$data$predicted |> 
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
      top_left     = min(tl_dist, na.rm = TRUE),
      top_right    = min(tr_dist, na.rm = TRUE),
      bottom_left  = min(bl_dist, na.rm = TRUE),
      bottom_right = min(br_dist, na.rm = TRUE)
    ) |> 
    unlist()

  which_corner <- names(sort(distance_from_corners)[4])
  pval <- tibble::tibble(
    lbl = object$info$format_p(object$info$model_p), 
    cnr = which_corner
  )

  if (which_corner == "top_left") {
    return(
      ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(
          x = I(.05), 
          y = I(.95), 
          label = lbl
        ),
        hjust = 0, 
        vjust = 1
      )
    )
  }

  if (which_corner == "top_right") {
    return(
      ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(
          x = I(.95), 
          y = I(.95), 
          label = lbl
        ),
        hjust = 1, 
        vjust = 1
      )
    )
  }

  if (which_corner == "bottom_left") {
    return(ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(
        x = I(.05), 
        y = I(.05), 
        label = lbl
      ),
      hjust = 0, 
      vjust = 0
    ))
  }

  if (which_corner == "bottom_right") {
    return(
      ggplot2::geom_label(
        data = pval,
        mapping = ggplot2::aes(
          x = I(.95), 
          y = I(.05), 
          label = lbl
        ),
        hjust = 1, 
        vjust = 0
      )
    )
  }   

}


# quantiles -------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_quantiles <- function(object, color_by = "inherit", bins = 4, conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  strata <- lr_contextual_strata(object, !!rlang::enquo(color_by))

  object$info$n_bins <- bins
  object$data$observed[[".bins"]] <- cut_exposure_quantile(
    exposure = object$data$observed[[object$name$exposure]], 
    n = object$info$n_bins
  )

  # unstratified version
  if (is.null(strata$name)) {

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

  }

  # stratified version
  if (!is.null(strata$name)) {

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
        .by = c(".bins", strata$name)
      )
    
    object$plot$base <- object$plot$base + 
      ggplot2::geom_point(
        data = object$info$quantiles,
        mapping = ggplot2::aes(
          x = x_mid, 
          y = y_mid,
          color = .data[[strata$name]]
        ),
        inherit.aes = FALSE,
        size = 2
      ) + 
      ggplot2::geom_errorbar(
        data = object$info$quantiles,
        mapping = ggplot2::aes(
          x = x_mid, 
          ymin = ci_lower, 
          ymax = ci_upper,
          color = .data[[strata$name]]  
        ),
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

  }
  
  return(object)
}


# strips ----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_strips <- function(object, color_by = "inherit", style = "jitter", panel = "both") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  strata <- lr_contextual_strata(object, !!rlang::enquo(color_by))
  
  if (style == "jitter") lr_strip <- lr_strip_jitter
  if (style == "dotplot") lr_strip <- lr_strip_dot

  if (panel %in% c("lower", "both")) object$plot$strip$lower <- lr_strip(object, strata, "lower")
  if (panel %in% c("upper", "both")) object$plot$strip$upper <- lr_strip(object, strata, "upper")
  return(object)
}

lr_strip_dot <- function(object, strata, panel) {

  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 1)
  if (!is_upr) dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 0)
  
  if (!is.null(strata$name)) {
    set_label(dd[[strata$name]], strata$label)
    plt_mapping <- ggplot2::aes(
      x = .data[[object$name$exposure]], 
      fill = .data[[strata$name]]
    )
  } else {
    plt_mapping <- ggplot2::aes(x = .data[[object$name$exposure]])
  }
  
  nbin <- 100
  dd |> 
    ggplot2::ggplot() +
    ggplot2::geom_dotplot(
      mapping = plt_mapping,
      binwidth = (object$info$exposure_max - object$info$exposure_min) / nbin,
      dotsize = 1,
      method = "histodot",
      stackgroups = TRUE,
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

lr_strip_jitter <- function(object, strata, panel) {

  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 1)
  if (!is_upr) dd <- object$data$observed |> dplyr::filter(.data[[object$name$response]] == 0)
  
  if (!is.null(strata$name)) {
    set_label(dd[[strata$name]], strata$label)
    plt_mapping <- ggplot2::aes(
      x = .data[[object$name$exposure]], 
      y = 0,
      color = .data[[strata$name]]
    )
  } else {
    plt_mapping <- ggplot2::aes(x = .data[[object$name$exposure]], y = 0)
  }

  dd |> 
    ggplot2::ggplot() +
    ggplot2::geom_jitter(
      mapping = plt_mapping,
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


# boxplot ---------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_boxplot <- function(object, boxes_by, color_by = "inherit") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  strata <- lr_contextual_strata(object, !!rlang::enquo(color_by))

  boxby_name <- rlang::as_name(rlang::enquo(boxes_by))

  cnt <- object$data$observed |> 
    dplyr::summarise(
      x = max(.data[[object$name$exposure]], na.rm = TRUE),
      x_off = x + .025 * (object$info$exposure_max - object$info$exposure_min),
      n = sum(!is.na(.data[[object$name$exposure]])),
      lbl = paste0("N=", n),
      .by = {{boxes_by}}
    ) |> 
    dplyr::mutate(lvl = paste0({{boxes_by}}, " (", lbl, ")")) |> 
    dplyr::arrange({{boxes_by}}) # sort by factor order to allow label merge
   
  # drop missing levels, and preserve the label metadata
  plt_data <- object$data$observed
  ll <- attr(plt_data[[boxby_name]], "label")
  plt_data <- plt_data |> dplyr::mutate({{boxes_by}} := droplevels({{boxes_by}}))
  levels(plt_data[[boxby_name]]) <- cnt$lvl
  attr(plt_data[[boxby_name]], "label") <- ll

  if (is.null(strata$name)) {
    plt_mapping <- ggplot2::aes(
      x = .data[[object$name$exposure]], 
      y = .data[[boxby_name]]
    )
  } else {
    plt_mapping <- ggplot2::aes(
      x = .data[[object$name$exposure]], 
      y = .data[[boxby_name]],
      fill = .data[[strata$name]]
    )
  }

  plt <- plt_data |> 
    ggplot2::ggplot(plt_mapping) + 
    ggplot2::geom_boxplot(alpha = .5) +
    ggplot2::coord_cartesian(
      xlim = c(object$info$exposure_min, object$info$exposure_max), 
      clip = "off"
    ) +
    ggplot2::theme_bw() +
    ggplot2::theme(panel.border = ggplot2::element_rect(fill = NA, color = "grey80", linewidth = .5)) +
    NULL

  if (!is.null(strata$name)) {
    fml <- stats::as.formula(paste0(strata$name, " ~ ."))
    plt <- plt + ggplot2::facet_grid(fml)
  }

  pos <- length(object$plot$box) + 1L
  object$plot$box[[pos]] <- plt
  object$info$n_boxes <- c(object$info$n_boxes, length(unique(plt_data[[boxby_name]])))
  return(object)  
}


# build/print -----------------------------------------------------------------

#' @exportS3Method base::print
print.erlr_plot <- function(x, plot = TRUE, ...) {
  object <- lr_plot_build(x, ...)

  if (is.null(object$output) || plot == FALSE) {
    cat("<erlr_plot>\n")
    cat("- exposure variable:", object$name$exposure, "\n")
    cat("- response variable:", object$name$response, "\n")
    if (!is.null(object$name$color)) {
      cat("- stratification variable (color):", object$name$color, "\n")
    }
    plot_names <- character()
    if (!is.null(object$plot$base)) plot_names <- c(plot_names, "base")
    if (!is.null(object$plot$strip$lower)) plot_names <- c(plot_names, "lower strip")
    if (!is.null(object$plot$strip$upper)) plot_names <- c(plot_names, "upper strip")
    if (length(object$plot$box) != 0L) plot_names <- c(plot_names, "boxplot")    
    if (length(plot_names) > 0L) {
      cat("- specified plot components:", paste(plot_names, collapse = ", "), "\n")
    } else {
      cat("- no plot components specified\n")
    }
    return(invisible(object))
  }

  suppressWarnings(print(object$output)) # TODO: remove once patchwork okay
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

