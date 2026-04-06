
#' Builds an exposure-response plot for a logistic regression model
#'
#' @param data Observed data
#' @param exposure Exposure variable (one variable, unquoted)
#' @param response Response variable (one variable, unquoted)
#' @param stratify_by Stratification variable used for color and fill (one variable, unquoted)
#' @param group_by Grouping variables to define groups for distribution plots (a tidyselection of variables)
#' @param keep_strata Logical, indicating whether this component should keep the color stratification
#' @param labels Named list of labels
#' @param bins Number of exposure bins (not counting placebo)
#' @param style Character string: "jitter" (the default) or "dotplot"
#' @param panel Character string: "upper", "lower", or "both" (the default)
#' @param conf_level Confidence level
#' @param object Partially constructed plot (has S3 class `erlr_plot`)
#'
#' @returns Plot object of class `erlr_plot`
#'
#' @examples
#' lr_data |> 
#'   lr_plot(exposure_1, response_1) |> 
#'   lr_plot_show_model() |> 
#'   lr_plot_show_quantiles() |> 
#'   lr_plot_show_groups(quartile_1) |> 
#'   plot()
#'  
#' plt <- lr_data |> 
#'   lr_plot(exposure_1, response_1, stratify_by = sex) |> 
#'   lr_plot_show_model(keep_strata = FALSE) |> 
#'   lr_plot_show_quantiles(bins = 3) |> 
#'   lr_plot_show_datastrip() |> 
#'   lr_plot_show_groups(group_by = c(quartile_1, dose), keep_strata = FALSE)
#' 
#' print(plt)
#' plot(plt)
#' 
#' @name lr_plot
NULL

# setup -----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot <- function(data, exposure, response, stratify_by = NULL) {

  # empty plot object
  object <- structure(
    list(
      data  = NULL,
      exposure = define_plot_variable(role = "exposure"),
      response = define_plot_variable(role = "response"),
      strata = define_plot_variable(role = "strata"),
      part = list(
        model    = NULL, 
        quantile = NULL, 
        strip    = NULL,
        group    = NULL
      ),
      plot = list(
        base = NULL, 
        strip = NULL, 
        group = NULL
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
  strata_name <- rlang::enquo(stratify_by)
  if (!rlang::quo_is_null(strata_name)) object$strata$name <- rlang::as_name(strata_name)
  
  # store (default) variable labels
  object$exposure$label <- get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$name)) {
    object$strata$label <- get_label(object$data[[object$strata$name]]) %||% object$strata$name
  }

  # store limits
  object$exposure$limits <- range(object$data[[object$exposure$name]])
  object$response$limits <- c(0, 1)
  if (!is.null(object$strata$name)) {
    object$strata$limits <- unique(object$data[[object$strata$name]])
  }

  # stylistic information
  object$style$format_p <- scales::label_pvalue(accuracy = .001, add_p = TRUE)
  object$style$format_percent <- scales::label_percent(accuracy = 1)
  object$style$height <- list(base = 6, strip = 2, group = 3) 
  object$style$theme_base <- function() {
    ggplot2::theme_bw()
  }
  object$style$theme_args <- function() {
    ggplot2::theme(
      panel.border = ggplot2::element_rect(
        fill = NA, 
        color = "grey80", 
        linewidth = .5
      ),
      legend.position = "bottom"
    ) 
  }
 
  return(object)
}

#' @rdname lr_plot
#' @export
lr_plot_style <- function(object, labels) {
  return(object)
}



# model -----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_model <- function(object, keep_strata = NULL, conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  
  object$part$model <- list()
  object$part$model$stratify <- keep_strata

  # model formula
  fml <- paste(object$response$name, object$exposure$name, sep = " ~ ")
  if (object$part$model$stratify == TRUE) {
    fml <- paste(fml, object$strata$name, sep = " + ")
  }
  object$part$model$formula <- stats::as.formula(fml)

  # model
  object$part$model$glm <- lr_model(
    formula = object$part$model$formula, 
    data = object$data
  )

  if (is.null(object$strata$name) || object$part$model$stratify == FALSE) {
    # without strata, report a single p-value, for the slope 
    # TODO: replace this with the anova
    object$part$model$p_value <- summary(object$part$model$glm)$coefficients[2, "Pr(>|z|)"]
  }
  object$part$model$conf_level <- conf_level
  object$part$model$predictions <- get_model_predictions(object)
  
  return(object)
}

# quantiles -------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_quantiles <- function(object, keep_strata = NULL, bins = 4, conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$quantile <- list()
  object$part$quantile$stratify <- keep_strata
  object$part$quantile$n_quantiles <- bins
  object$part$quantile$summary <- object$data |>
    dplyr::mutate(
      response = .data[[object$response$name]],
      exposure_bins = cut_exposure_quantile(
        exposure = .data[[object$exposure$name]], 
        n = object$part$quantile$n_quantiles
      ),
      strata = get_strata_values(.data, object$strata$name)   
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

# strips ----------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_datastrip <- function(object, keep_strata = NULL, style = "jitter", panel = "both") {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$strip <- list()
  object$part$strip$stratify <- keep_strata
  object$part$strip$style <- style
  object$part$strip$panel <- panel
  
  if (style == "jitter")  object$part$strip$builder <- build_strip_jitter
  #if (style == "dotplot") object$part$strip$builder <- build_strip_dot

  if (panel %in% c("lower", "both")) object$part$strip$lower <- TRUE
  if (panel %in% c("upper", "both")) object$part$strip$upper <- TRUE
  return(object)

}


# groups plot -----------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_groups <- function(object, group_by, keep_strata = NULL) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  group_cols <- tidyselect::eval_select(rlang::enquo(group_by), object$data) 

  object$part$group <- list()
  object$part$group$stratify <- keep_strata
  object$part$group$var <- list()
  for(g in names(group_cols)) {
    if (keep_strata)  groupings <- c(g, object$strata$name)
    if (!keep_strata) groupings <- g
    object$part$group$var[[g]] <- list()
    object$part$group$var[[g]]$y <- define_plot_variable(
      name = g,
      label = get_label(object$data[[g]]) %||% g,
      role = paste("group", g, sep = "_")
    )
    object$part$group$var[[g]]$counts <- object$data |> 
      dplyr::summarise(
        n   = sum(!is.na(.data[[object$exposure$name]])),
        lbl = paste0("N=", n),
        .by = groupings
      ) |> 
      dplyr::mutate(lvl = paste0(.data[[g]], " (", lbl, ")")) |> 
      dplyr::arrange(.data[[g]])
    object$part$group$var[[g]]$n_groups <- nrow(object$part$group$var[[g]]$counts)
    object$part$group$var[[g]]$data <- object$data |> 
      dplyr::select(dplyr::all_of(c(groupings, object$exposure$name))) |> 
      dplyr::left_join(
        object$part$group$var[[g]]$counts,
        by = groupings
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
  cat("  $strata:    ", x$strata$name  %||% "<none>", "\n", sep = "")
  if (any(part_set)) {
    cat("  $part:\n")
    if (part_set["model"])    cat("    $model:     ", deparse(x$part$model$formula), "\n", sep = "")
    if (part_set["quantile"]) cat("    $quantile:  ", x$part$quantile$n_quantiles, " bins\n", sep = "")
    if (part_set["strip"])    cat("    $strip:     ", x$part$strip$style, " ", x$part$strip$panel, "\n", sep = "")
    if (part_set["group"])    cat("    $group:     ", paste(names(x$part$group$var), collapse = ", "), "\n", sep = "")
  }
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.erlr_plot <- function(x, y = NULL, ...) {
  object <- lr_plot_build(x)
  suppressWarnings(plot(object$output))
}

# top level build function ----------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_build <- function(object) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  
  # build
  if (!is.null(object$part$model) | !is.null(object$part$quantile)) object$plot$base <- build_base_plot(object)
  if (!is.null(object$part$strip)) object$plot$strip <- build_strip_plot(object)
  if (!is.null(object$part$group)) object$plot$group <- build_group_plot(object)

  # polish
  object$plot <- polish_margins(object)
  object$plot <- polish_labels(object)
  composition <- polish_arrangement(object)
  composition <- polish_legends(object, composition)
  composition <- polish_theme(object, composition)

  # output
  if (length(composition$heights) == 1) {
    object$output <- object$plot$base
  } else {
    object$output <- patchwork::wrap_plots(
      composition$plots, 
      ncol = 1, 
      heights = composition$info$size,
      guides = "collect",
      axes = "collect"
    ) + patchwork::plot_annotation(
      theme = object$style$theme_args()
    )
  }

  return(object)
}
