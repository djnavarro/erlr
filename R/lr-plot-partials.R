
#' Partial builders for logistic regression plots
#'
#' @param data The original data frame
#' @param config Configuration for the specific plot
#' @param stratify Logical indicating whether to stratify
#' @param exposure Exposure variable
#' @param response Response variable
#' @param strata Stratification variable
#' @param style Style components
#'
#' @details Things we can have partials for:
#' 
#' - model
#' - summary
#' - quantile
#' - datastrip
#' - group
#' 
#' Arguments are standardised to allow users to write their own 
#' as needed
#' 
#' @returns A geom, or a list of geoms. More precisely, a list of
#' objects that can be added to a ggplot2 plot. The expectation is
#' that these objects will be added to a partially-constructed plot
#' which, at a minimum, already has the base theme applied. For 
#' "model", "summary", and "quantile", the pieces will be added to
#' a plot that already has a coord that sets the axis limits. For
#' the "datastrip" and "group" plots, the plot object does not yet
#' have a coord. The expectation, however, is that the builder will
#' supply an x-axis limit that is consistent with the base plot. That
#' is, since all component plots use the exposure variable for the
#' x-axis, they should use the values stored in `exposure$limits` tp
#' set the x-axis limits.   
#' 
#' @name lr_partial
#' 
NULL

# datastrip partials ----------------------------------------------------------

#' @rdname lr_partial
#' @export
build_datastrip_jitter <- function(data, config, stratify, exposure, response, strata, style) {

  if (config$panel == "upper") dat <- data |> dplyr::filter(.data[[response$name]] == 1)
  if (config$panel == "lower") dat <- data |> dplyr::filter(.data[[response$name]] == 0)
  
  if (stratify == TRUE) {
    .set_label(dat[[strata$name]], strata$label)
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = 0, 
      color = .data[[strata$name]]
    )
  } 
  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = 0
    )
  }

  withr::with_seed( # TODO: setting seed here isn't correct
    seed = config$seed,
    code = {
      geoms <- list( 
        ggplot2::geom_jitter(
          data = dat,
          mapping = plot_map,
          width = 0,
          height = 0.1,
          size = 1,
          key_glyph = style$draw_key
        ),
        ggplot2::coord_cartesian(
          xlim = exposure$limits, 
          ylim = c(-0.1, 0.1), 
          clip = "off"
        ),
        ggplot2::scale_y_continuous(
          breaks = NULL, 
          minor_breaks = NULL
        )
      )
    }
  )

  return(geoms)
}

# group partials --------------------------------------------------------------

#' @rdname lr_partial
#' @export
build_group_boxplot <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl
    )
  } 
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(
      x = .data[[exposure$name]], 
      y = lvl, 
      fill = .data[[strata$name]]
    )
  }

  geoms <- list(
    ggplot2::geom_boxplot(
      data = config$data,
      mapping = plot_map,
      alpha = .5, 
      key_glyph = style$draw_key
    ),
    ggplot2::coord_cartesian(
      xlim = exposure$limits, 
      clip = "off"
    ) 
  )

  return(geoms)
}

# model partials --------------------------------------------------------------

# model partials should return a geom or a list of geoms

#' @rdname lr_partial
#' @export
build_model_ribbonline <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey40",
      alpha = .25,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )
  }

  if (stratify == TRUE) {

    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        fill = .data[[strata$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      alpha = .25,
      key_glyph = style$draw_key
    )

    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = style$draw_key
    )    
  }
  
  geoms <- list(model_ribbon, model_line)
  return(geoms)
}


# summary partials --------------------------------------------------------------

# summary partials should return a geom or a list of geoms

#' @rdname lr_partial
#' @export
build_summary_pvalue <- function(data, config, stratify, exposure, response, strata, style) {

  corner <- names(sort(config$corner_distance)[4])
  summary_data <- tibble::tibble(lbl = style$format_p(config$p_value))

  if (corner == "top_left") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.05), y = I(.95), label = lbl),
      hjust = 0, vjust = 1, show.legend = FALSE
    )
  }

  if (corner == "top_right") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.95), y = I(.95), label = lbl),
      hjust = 1, vjust = 1, show.legend = FALSE
    )
  }

  if (corner == "bottom_left") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.05), y = I(.05), label = lbl),
      hjust = 0, vjust = 0, show.legend = FALSE
    )
  }

  if (corner == "bottom_right") {
    geoms <- ggplot2::geom_label(
      data = summary_data,
      mapping = ggplot2::aes(x = I(.95), y = I(.05), label = lbl),
      hjust = 1, vjust = 0, show.legend = FALSE
    )
  }
  
  return(geoms)
}


# quantile partials --------------------------------------------------------------

# quantile partials should return a geom or a list of geoms

#' @rdname lr_partial
#' @export
build_quantile_errorbar <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {

    point <- ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_mid),
      inherit.aes = FALSE,
      size = 2,
      key_glyph = style$draw_key
    )

    bar <- ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      inherit.aes = FALSE,
      key_glyph = style$draw_key
    )

    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3,
      show.legend = FALSE
    )
  }

  if (stratify == TRUE) {

    point <- ggplot2::geom_point(
      data = config$summary,
      mapping = ggplot2::aes(
        x = x_mid, 
        y = y_mid,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = 2,
      key_glyph = style$draw_key
    )
    
    bar <- ggplot2::geom_errorbar(
      data = config$summary,
      mapping = ggplot2::aes(
        x = x_mid, 
        ymin = ci_lower, 
        ymax = ci_upper,
        color = .data[["strata"]]  
      ),
      inherit.aes = FALSE,
      width = 0.025 * (exposure$limits[2] - exposure$limits[1]),
      key_glyph = style$draw_key
    )
    
    label <- ggplot2::geom_text(
      data = config$summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3,
      show.legend = FALSE
    ) 
  }

  geoms <- list(point, bar, label)
  return(geoms)
}

