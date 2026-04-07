
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
#' @param style Character string used to specify the partial builder for this component
#' @param panel Character string: "upper", "lower", or "both" (the default)
#' @param conf_level Confidence level
#' @param object Partially constructed plot (has S3 class `erlr_plot`)
#'
#' @returns Plot object of class `erlr_plot`
#'
#' @examples
#' lr_data |> 
#'   lr_plot(aucss, ae1) |> 
#'   lr_plot_show_model() |> 
#'   lr_plot_show_quantiles() |> 
#'   lr_plot_show_groups(dose) |> 
#'   plot()
#'  
#' plt <- lr_data |> 
#'   lr_plot(aucss, ae2, stratify_by = sex) |> 
#'   lr_plot_show_model(keep_strata = FALSE) |> 
#'   lr_plot_show_quantiles(bins = 3) |> 
#'   lr_plot_show_datastrip() |> 
#'   lr_plot_show_groups(group_by = c(treatment, dose), keep_strata = FALSE)
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
      exposure = .plot_variable(role = "exposure"),
      response = .plot_variable(role = "response"),
      strata = .plot_variable(role = "strata"),
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
  object$exposure$label <- .get_label(object$data[[object$exposure$name]]) %||% object$exposure$name
  object$response$label <- .get_label(object$data[[object$response$name]]) %||% object$response$name    
  if (!is.null(object$strata$name)) {
    object$strata$label <- .get_label(object$data[[object$strata$name]]) %||% object$strata$name
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
  object$style$theme_base <- function() ggplot2::theme_bw()
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
  object$style$draw_key <- ggplot2::draw_key_rect
 
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
lr_plot_show_model <- function(object, keep_strata = NULL, style = "ribbonline", conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  
  object$part$model <- list()
  stratify <- keep_strata
  config <- list()

  # model formula
  fml <- paste(object$response$name, object$exposure$name, sep = " ~ ")
  if (stratify == TRUE) fml <- paste(fml, object$strata$name, sep = " + ")
  config$formula <- stats::as.formula(fml)

  # model object
  config$glm <- lr_model(formula = config$formula, data = object$data)

  # model summary
  if (is.null(object$strata$name) || stratify == FALSE) {
    config$p_value <- summary(config$glm)$coefficients[2, "Pr(>|z|)"]
  }
  config$conf_level <- conf_level

  # model predictions
  config$predictions <- .get_model_predictions(
    config$glm, 
    config$conf_level, 
    object$exposure, 
    object$strata, 
    stratify
  )
  
  # visual distance from corners (used for placement of summary)
  config$corner_distance <- config$predictions |> 
    dplyr::select(dplyr::all_of(c(object$exposure$name, "fit_resp"))) |> 
    dplyr::rename(y = fit_resp, x = .data[[object$exposure$name]]) |> 
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

  config$builder <- list()
  if (style == "ribbonline") config$builder$model <- build_model_ribbonline
  if (style == "spaghetti")  config$builder$model <- build_model_spaghetti
  config$builder$summary <- build_summary_pvalue

  # store and return
  object$part$model$stratify <- stratify
  object$part$model$config <- config
  return(object)
}

# quantiles -------------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_quantiles <- function(object, keep_strata = NULL, bins = 4, conf_level = 0.95) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)

  object$part$quantile <- list()
  stratify <- keep_strata
  config <- list()

  config$n_quantiles <- bins
  config$conf_level <- conf_level

  config$summary <- object$data |>
    dplyr::mutate(
      response = .data[[object$response$name]],
      exposure_bins = cut_exposure_quantile(
        x = .data[[object$exposure$name]], 
        n = config$n_quantiles
      ),
      strata = .get_strata_values(.data, object$strata$name)   
    ) |> 
    dplyr::summarise(
      n1 = sum(.data[[object$response$name]] == 1, na.rm = TRUE),
      n0 = sum(.data[[object$response$name]] == 0, na.rm = TRUE),
      x_mid = mean(.data[[object$exposure$name]], na.rm = TRUE),
      y_mid = n1 / (n0 + n1),
      y_mid_lbl = object$style$format_percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, config$conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, config$conf_level)["upper"],
      y_lwr_lbl = ci_lower - 0.05,
      y_upr_lbl = ci_upper + 0.05,
      y_lbl = dplyr::if_else(y_lwr_lbl > 1 - y_upr_lbl, y_lwr_lbl, y_upr_lbl),
      .by = c("exposure_bins", "strata")
    )
  
  config$builder <- build_quantile_errorbar
  
  # store and return
  object$part$quantile$stratify <- stratify
  object$part$quantile$config <- config
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
  
  config <- list()
  config$style <- style
  config$panel <- panel
  config$seed  <- 1234L
  
  if (style == "jitter") config$builder <- build_datastrip_jitter

  if (panel %in% c("lower", "both")) config$lower <- TRUE
  if (panel %in% c("upper", "both")) config$upper <- TRUE

  object$part$strip$config <- config 
  return(object)
}


# groups plot -----------------------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_show_groups <- function(object, group_by, style = "boxplot", keep_strata = NULL) {

  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  if (is.null(keep_strata)) keep_strata <- !is.null(object$strata$name)
  group_cols <- tidyselect::eval_select(rlang::enquo(group_by), object$data) 

  object$part$group <- list()
  object$part$group$stratify <- keep_strata
  object$part$group$config <- list()

  for(g in names(group_cols)) {

    config <- list()
    if (style == "boxplot") config$builder <- build_group_boxplot
    if (style == "violin")  config$builder <- build_group_violin

    # store the variable names used for grouping
    if (keep_strata)  config$groupings <- c(g, object$strata$name)
    if (!keep_strata) config$groupings <- g

    # store information about the y-axis variable
    config$y <- .plot_variable(
      name = g,
      label = .get_label(object$data[[g]]) %||% g,
      role = paste("group", g, sep = "_")
    )

    # store sample size information (for merge into plot labels)
    config$counts <- object$data |> 
      dplyr::summarise(
        n   = sum(!is.na(.data[[object$exposure$name]])),
        lbl = paste0("N=", n),
        .by = config$groupings
      ) |> 
      dplyr::mutate(lvl = paste0(.data[[g]], " (", lbl, ")")) |> 
      dplyr::arrange(.data[[g]])

    # store the number of groups plotted on the y-axis
    config$n_groups <- nrow(config$counts)

    # store a modified data set to use for plotting
    config$data <- object$data |> 
      dplyr::select(dplyr::all_of(c(config$groupings, object$exposure$name))) |> 
      dplyr::left_join(config$counts, by = config$groupings)
    
    object$part$group$config[[g]] <- config
  }

  return(object)  
}

# plot/print ------------------------------------------------------------------

#' @exportS3Method base::print
print.erlr_plot <- function(x, ...) {

  part_set <- !purrr::map_lgl(x$part, is.null)
  plot_set <- !purrr::map_lgl(x$plot, is.null)

  cat("<erlr_plot>\n")
  cat("  plot variables:\n")
  cat("    - exposure:        ", x$exposure$name  %||% "<none>", "\n", sep = "")
  cat("    - response:        ", x$response$name  %||% "<none>", "\n", sep = "")
  cat("    - stratification:  ", x$strata$name    %||% "<none>", "\n", sep = "")
  
  if (any(part_set)) {
    cat("  plot components:\n")
    if (part_set["model"])    cat("    - model:           ", deparse(x$part$model$config$formula), "\n", sep = "")
    if (part_set["quantile"]) cat("    - quantile:        ", x$part$quantile$config$n_quantiles, " bins\n", sep = "")
    if (part_set["strip"])    cat("    - strip:           ", x$part$strip$config$style, " ", x$part$strip$config$panel, "\n", sep = "")
    if (part_set["group"])    cat("    - group:           ", paste(names(x$part$group$config), collapse = ", "), "\n", sep = "")
  } else {
    cat("  plot components: <none>\n")
  }

  if (any(plot_set)) {
    cat("  plots built:\n")
    if (plot_set["base"])   cat("    - model\n", sep = "")
    if (plot_set["strip"])  cat("    - strip\n", sep = "")
    if (plot_set["group"])  cat("    - group\n", sep = "")
  } else {
    cat("  plots built: <none>\n")
  }

  if (is.null(x$output))  cat("  output built: no")
  if (!is.null(x$output)) cat("  output built: yes")
  
  return(invisible(x))
}

#' @exportS3Method graphics::plot
plot.erlr_plot <- function(x, y = NULL, ...) {
  object <- lr_plot_build(x)
  plot(object$output)
}

# top level build function ----------------------------------------------------

#' @rdname lr_plot
#' @export
lr_plot_build <- function(object) {
  if (!inherits(object, "erlr_plot")) rlang::abort("`object` must be an erlr plot object")
  
  # build
  if (!is.null(object$part$model) | !is.null(object$part$quantile)) object$plot$base <- .build_base_plot(object)
  if (!is.null(object$part$strip)) object$plot$strip <- .build_strip_plot(object)
  if (!is.null(object$part$group)) object$plot$group <- .build_group_plot(object)

  # polish
  object$plot <- .polish_margins(object)
  object$plot <- .polish_labels(object)
  composition <- .polish_arrangement(object)
  composition <- .polish_legends(object, composition)
  composition <- .polish_theme(object, composition)

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


# miscellaneous helpers -------------------------------------------------------

.plot_variable <- function(name = NULL, label = NULL, limits = NULL, role = NULL) {
  list(name = name, label = label, limits = limits,role = role)
}

.get_strata_values <- function(data, name) {
  if (is.null(name)) return(NA)
  data[[name]]
}

.get_model_predictions <- function(mod, conf_level, exposure, strata, stratify) {

  pred_dat <- seq(exposure$limits[1], exposure$limits[2], length.out = 300L) |> 
    data.frame() |> .set_names(exposure$name)
  
  if (stratify) pred_dat <- pred_dat |> 
    dplyr::cross_join(data.frame(strata$limits) |> .set_names(strata$name))

  model_predictions <- lr_predict(object = mod, newdata = pred_dat, conf_level = conf_level)
  return(model_predictions)
}
