
#' Builds an exposure-response plot for a logistic regression model
#'
#' @param data Observed data
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted)
#' @param color_by Stratification variable used for color and fill (one variable, unquoted)
#' @param boxes_by Stratification variables to define groups for boxplots (a tidyselection of variables)
#' @param labels Named list of labels
#' @param bins Number of exposure bins (not counting placebo)
#' @param style Character string: "jitter" (the default) or "dotplot"
#' @param panel Character string: "upper", "lower", or "both" (the default)
#' @param conf_level Confidence level for Clopper-Pearson intervals
#' @param object Partially constructed plot (has S3 class `erlr_plot`)
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

erlr_variable <- function(name = NULL, label = NULL, limits = NULL, role = NULL) {
  structure(
    list(
      name = name, 
      label = label, 
      limits = limits,
      role = role
    ),
    class = "erlr_plot_variable"
  )
}

#' @exportS3Method base::print
print.erlr_plot_variable <- function(x, ...) {
  if (is.null(x$name)) { cat("<", x$role, "> NULL\n", sep = "")
  } else {cat("<", x$role, "> ", x$name, "\n", sep = "")}
  return(invisible(x))
}

#' @rdname lr_plot
#' @export
lr_plot <- function(data, exposure, response, color_by = NULL) {

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = erlr_variable(role = "exposure"),
      response = erlr_variable(role = "response"),
      strata = list(
        default  = erlr_variable(role = "default_strata"),
        model    = erlr_variable(role = "model_strata"),
        quantile = erlr_variable(role = "quantile_strata"),
        strip    = erlr_variable(role = "strip_strata"),
        box      = erlr_variable(role = "box_strata")
      ), 
      part = list(
        model    = NULL, 
        quantile = NULL, 
        strip    = NULL,
        box      = NULL
      ),
      plot = list(
        base = NULL, 
        strip = NULL, 
        box = NULL
      ),
      style = list(),
      output = NULL 
    ),
    class = "erlr_plot"
  )

  # store observed data
  object$data <- data

  # store variable names
  object$exposure$name <- rlang::as_name(rlang::enquo(exposure))
  object$response$name <- rlang::as_name(rlang::enquo(response)) 
  strata_name <- rlang::enquo(color_by)
  if (!rlang::quo_is_null(strata_name)) object$strata$default$name <- rlang::as_name(strata_name)
  
  # store (default) variable labels
  object$exposure$label <- get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$default$name)) {
    object$strata$default$label <- get_label(object$data[[object$strata$default$name]]) %||% 
      object$strata$default$name
  }

  # store limits
  object$exposure$limits <- range(object$data[[object$exposure$name]])
  object$response$limits <- c(0, 1)
  if (!is.null(object$strata$default$name)) {
    object$strata$default$limits <- unique(object$data[[object$strata$default$name]])
  }

  # stylistic information
  object$style$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$style$format_percent <- scales::label_percent(accuracy = 1)
  object$style$height <- list(base = 6, strip = 2, box = 3) 
  object$style$theme <- function(object) {
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
 
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_style <- function(object, labels) {
  return(object)
}

# construct a stratum variable within the local context
contextual_strata <- function(object, strata, context) {
  strata_quo <- rlang::enquo(strata)
  strata_val <- rlang::eval_tidy(
    rlang::quo_set_env(
      quo = strata_quo, 
      env = rlang::as_environment(object$data)
    )
  )
  if (rlang::quo_is_null(strata_quo)) { # if strata is NULL
    strata_name   <- NULL
    strata_label  <- NULL
    strata_limits <- NULL
  } else if (rlang::quo_is_symbol(strata_quo)) { # if strata is a variable name
    strata_name   <- rlang::as_name(strata_quo)
    strata_label  <- get_label(object$data[[strata_name]]) %||% strata_name
    strata_limits <- unique(strata_val)
  } else if (strata_val == "inherit") { # use cached value
    strata_name   <- object$strata$default$name
    strata_label  <- object$strata$default$label
    strata_limits <- object$strata$default$limits
  } 
  return(erlr_variable(
    name = strata_name, 
    label = strata_label, 
    limits = strata_limits,
    role = context
  ))
}


# model -----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_model <- function(object, color_by = "inherit", conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  object$part$model <- list()
  object$strata$model <- contextual_strata(object, {{color_by}}, "model_strata")

  # model formula
  fml <- paste(object$response$name, object$exposure$name, sep = " ~ ")
  if (!is.null(object$strata$model$name)) {
    fml <- paste(fml, object$strata$model$name, sep = " + ")
  }
  object$part$model$formula <- stats::as.formula(fml)

  # model
  object$part$model$glm <- lr_model(
    formula = object$part$model$formula, 
    data = object$data
  )

  # p-value is different depending on stratification: currently only supported when no strata
  if (is.null(object$strata$model$name)) {
    object$part$model$p_value <- summary(object$part$model$glm)$coefficients[2, "Pr(>|z|)"]
  }
  object$part$model$conf_level <- conf_level
  object$part$model$predictions <- model_predictions(object)
  
  return(object)
}

model_predictions <- function(object) {

  pred_dat <- seq(
    from = object$exposure$limits[1], 
    to = object$exposure$limits[2], 
    length.out = 300L
  ) |> 
    data.frame() |> 
    set_names(object$exposure$name)
  
  if (!is.null(object$strata$model$name)) {
    pred_dat <- pred_dat |> 
      dplyr::cross_join(
        data.frame(object$strata$model$limits) |> 
        set_names(object$strata$model$name)
      )
  }

  lr_predict(
    object = object$part$model$glm,
    newdata = pred_dat, 
    conf_level = object$part$model$conf_level
  )
}


# quantiles -------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_quantiles <- function(object, color_by = "inherit", bins = 4, conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  object$strata$quantile <- contextual_strata(object, {{color_by}}, "quantile_strata")

  object$part$quantile <- list()
  object$part$quantile$n_quantiles <- bins
  object$part$quantile$summary <- object$data |>
    dplyr::mutate(
      response = .data[[object$response$name]],
      exposure_bins = cut_exposure_quantile(
        exposure = .data[[object$exposure$name]], 
        n = object$part$quantile$n_quantiles
      ),
      strata = strata_values(.data, object$strata$quantile$name)   
    ) |> 
    dplyr::summarise(
      n1 = sum(.data[[object$response$name]] == 1, na.rm = TRUE),
      n0 = sum(.data[[object$response$name]] == 0, na.rm = TRUE),
      x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
      y_mid = n1 / (n0 + n1),
      y_mid_lbl = object$style$format_percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"],
      y_lwr_lbl = ci_lower - 0.05,
      y_upr_lbl = ci_upper + 0.05,
      y_lbl = dplyr::if_else(y_lwr_lbl > 1 - y_upr_lbl, y_lwr_lbl, y_upr_lbl),
      .by = c("exposure_bins", "strata")
    )
  
  return(object)
}

strata_values <- function(data, name) {
  if (is.null(name)) return(NA)
  data[[name]]
}

# strips ----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_strips <- function(object, color_by = "inherit", style = "jitter", panel = "both") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  object$strata$strip <- contextual_strata(object, {{color_by}}, "strip_strata")

  object$part$strip <- list()
  object$part$strip$style <- style
  object$part$strip$panel <- panel
  
  if (style == "jitter")  object$part$strip$builder <- build_strip_jitter
  if (style == "dotplot") object$part$strip$builder <- build_strip_dot

  if (panel %in% c("lower", "both")) object$part$strip$lower <- TRUE
  if (panel %in% c("upper", "both")) object$part$strip$upper <- TRUE
  return(object)

}



# boxplot ---------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_add_boxplot <- function(object, boxes_by, color_by = "inherit") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  object$strata$box <- contextual_strata(object, {{color_by}}, "box_strata")
  box_cols <- tidyselect::eval_select(rlang::enquo(boxes_by), object$data) 

  object$part$box <- list()
  for(b in names(box_cols)) {
    object$part$box[[b]] <- list()
    object$part$box[[b]]$counts <- object$data |> 
      dplyr::summarise(
        n   = sum(!is.na(.data[[object$exposure$name]])),
        lbl = paste0("N=", n),
        .by = dplyr::all_of(c(b, object$strata$box$name))
      ) |> 
      dplyr::mutate(
        lvl = paste0(.data[[b]], " (", lbl, ")")
      ) |> 
      dplyr::arrange(.data[[b]])
    object$part$box[[b]]$n_boxes <- nrow(object$part$box[[b]]$counts)
    object$part$box[[b]]$data <- object$data |> 
      dplyr::select(dplyr::all_of(c(b, object$strata$box$name, object$exposure$name))) |> 
      dplyr::left_join(
        object$part$box[[b]]$counts,
        by = c(b, object$strata$box$name)
      )
  }

  return(object)  
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.erlr_plot <- function(x, ...) {
  part_set <- !purrr::map_lgl(x$part, is.null)
  cat("<erlr_plot>\n")
  cat("  $data:      ", nrow(x$data), " rows, ", ncol(x$data), " cols\n", sep = "")
  cat("  $exposure:  ", x$exposure$name %||% "<none>", "\n", sep = "")
  cat("  $response:  ", x$response$name  %||% "<none>", "\n", sep = "")
  if (any(part_set)) {
    cat("  $strata:\n")
    if (part_set["model"])    cat("    $model:     ", x$strata$model$name %||% "<none>", "\n", sep = "")
    if (part_set["quantile"]) cat("    $quantile:  ", x$strata$quantile$name %||% "<none>", "\n", sep = "")
    if (part_set["strip"])    cat("    $strip:     ", x$strata$strip$name %||% "<none>", "\n", sep = "")
    if (part_set["box"])      cat("    $box:       ", x$strata$box$name %||% "<none>", "\n", sep = "")
  }
  if (any(part_set)) {
    cat("  $part:\n")
    if (part_set["model"])    cat("    $model:     ", deparse(x$part$model$formula), "\n", sep = "")
    if (part_set["quantile"]) cat("    $quantile:  ", x$part$quantile$n_quantiles, " bins\n", sep = "")
    if (part_set["strip"])    cat("    $strip:     ", x$part$strip$style, " ", x$part$strip$panel, "\n", sep = "")
    if (part_set["box"])      cat("    $box:       ", paste(names(x$part$box), collapse = ", "), "\n", sep = "")
  }
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.erlr_plot <- function(x, y = NULL, ...) {
  object <- lr_plot_build(x)
  suppressWarnings(plot(object$output))
}


lr_plot_build <- function(object) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  
  if (!is.null(object$part$model) | !is.null(object$part$quantile)) object$plot$base <- build_plot_base(object)
  if (!is.null(object$part$strip)) object$plot$strip <- build_plot_strip(object)
  if (!is.null(object$part$box)) object$plot$box <- build_plot_box(object)

  object$plot <- adjust_margins(object)
  object$plot <- apply_labels(object)
  composition <- compose_plots(object)

  if (length(composition$heights) == 1) {
    object$output <- object$plot$base
  } else {
    object$output <- patchwork::wrap_plots(
      composition$plots, 
      ncol = 1, 
      heights = composition$heights,
      guides = "collect",
      axes = "collect"
    )
  }

  return(object)
}

adjust_margins <- function(object) {

  p <- object$plot

  margins <- ggplot2::margin(t = 5.5, r = 5.5, b = 5.5, l = 5.5, unit = "pt")
  zero_pt <- ggplot2::unit(0, "pt")

  base_mar <- margins
  uppr_mar <- margins
  lowr_mar <- margins

  if (!is.null(p$strip$upper)) {
    base_mar[1] <- zero_pt
    uppr_mar[3] <- zero_pt
  }
  if (!is.null(p$strip$lower)) {
    base_mar[3] <- zero_pt
    lowr_mar[1] <- zero_pt
  }

  p$base <- p$base + ggplot2::theme(margins = base_mar)
  if (!is.null(p$strip$upper)) p$strip$upper <- p$strip$upper + ggplot2::theme(margins = uppr_mar)
  if (!is.null(p$strip$lower)) p$strip$lower <- p$strip$lower + ggplot2::theme(margins = lowr_mar)
  if (!is.null(p$box)) {
    for(b in seq_along(p$box)) {
      p$box[[b]] + ggplot2::theme(margins = margins)
    }
  }

  return(p)
}

apply_labels <- function(object) {
  p <- object$plot

  p$base <- p$base + ggplot2::labs(
    x = object$exposure$label,
    y = object$response$label
  )

  if (!is.null(p$strip)) {
    if (!is.null(p$strip$upper)) {
      p$strip$upper <- p$strip$upper + ggplot2::labs(
        x = object$exposure$label,
        y = NULL
      )
    }
    if (!is.null(p$strip$lower)) {
      p$strip$lower <- p$strip$lower + ggplot2::labs(
        x = object$exposure$label,
        y = NULL
      )
    }
  }

  if (!is.null(p$box)) {
    for(bb in names(p$box)) {
      p$box[[bb]] <- p$box[[bb]] + ggplot2::labs(
        x = object$exposure$label
      )
    }
  }

  return(p)
}

compose_plots <- function(object) {
  
  plot_list <- list()
  plot_size <- numeric()
  ind <- 0L

  if (!is.null(object$plot$strip$upper)) {
    ind <- ind + 1L
    plot_list[[ind]] <- object$plot$strip$upper
    plot_size[ind] <- object$style$height$strip / 2
  }

  ind <- ind + 1L
  plot_list[[ind]] <- object$plot$base
  plot_size[ind] <- object$style$height$base

  if (!is.null(object$plot$strip$lower)) {
    ind <- ind + 1L
    plot_list[[ind]] <- object$plot$strip$lower
    plot_size[ind] <- object$style$height$strip / 2
  }
  
  if (!is.null(object$plot$box)) {
    box_n <- purrr::map_dbl(object$part$box, \(bb) bb$n_boxes)
    box_prop <- box_n / sum(box_n)
    for(b in seq_along(object$plot$box)) {
      ind <- ind + 1L
      plot_list[[ind]] <- object$plot$box[[b]]
      plot_size[ind] <- object$style$height$box * box_prop[b]
    }
  }

  return(list(plots = plot_list, heights = plot_size))
}

