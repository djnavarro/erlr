
# builders for the three plot types -------------------------------------------

.build_base_plot <- function(object) {

  base <- ggplot2::ggplot() +
    object$style$theme_base() +
    ggplot2::scale_y_continuous(
      oob = scales::oob_keep, 
      expand = ggplot2::expansion(mult = .01, add = 0)
    )  +
    ggplot2::coord_cartesian(
      xlim = object$exposure$limits, 
      ylim = object$response$limits, 
      clip = "off"
    ) 
  if (!is.null(object$part$model)) {
    base <- base + 
      .build_model_ribbon(object) +
      .build_model_line(object) +
      .build_model_summary(object)
  }
  if (!is.null(object$part$quantile)) {
    base <- base + .build_quantiles(object)
  }

  return(base)
}

.build_strip_plot <- function(object) {

  config <- object$part$strip$config
  strip <- list()
  if (config$upper) strip$upper <- config$builder(object, "upper")
  if (config$lower) strip$lower <- config$builder(object, "lower")
  
  return(strip)
}

.build_group_plot <- function(object) {

  strata   <- object$strata
  config   <- object$part$group$config
  stratify <- object$part$group$stratify
  group <- list()

  for(g in names(config)) {

    if (stratify == FALSE) {
      group[[g]] <- ggplot2::ggplot(
        data = config[[g]]$data,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]],
          y = lvl
        )
      )
    } 
    
    if (stratify == TRUE) {
      group[[g]] <- ggplot2::ggplot(
        data = config[[g]]$data,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]],
          y = lvl,
          fill = .data[[strata$name]]
        )
      )
    }

    group[[g]] <- group[[g]] +
      object$style$theme_base() +
      ggplot2::geom_boxplot(
        alpha = .5,
        key_glyph = object$style$draw_key
      ) +
      ggplot2::coord_cartesian(
        xlim = object$exposure$limits, 
        clip = "off"
      ) 
  }
  
  return(group)  
}


# specific buildiers: base plot model -----------------------------------------

.build_model_ribbon <- function(object) {

  strata   <- object$strata
  stratify <- object$part$model$stratify
  config   <- object$part$model$config

  if (stratify == FALSE) {
    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[object$exposure$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      fill = "grey40",
      alpha = .25,
      key_glyph = object$style$draw_key
    )
  }

  if (stratify == TRUE) {
    model_ribbon <- ggplot2::geom_ribbon(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[object$exposure$name]],
        fill = .data[[strata$name]],
        ymin = ci_lower,
        ymax = ci_upper
      ),
      alpha = .25,
      key_glyph = object$style$draw_key
    )
  } 

  return(model_ribbon)
}

.build_model_line <- function(object) {

  strata   <- object$strata
  stratify <- object$part$model$stratify
  config   <- object$part$model$config

  if (stratify == FALSE) {
    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[object$exposure$name]], 
        y = fit_resp
      ),
      linewidth = 1,
      key_glyph = object$style$draw_key
    )
  }

  if (stratify == TRUE) {
    model_line <- ggplot2::geom_path(
      data = config$predictions,
      mapping = ggplot2::aes(
        x = .data[[object$exposure$name]], 
        y = fit_resp,
        color = .data[[strata$name]]
      ),
      linewidth = 1,
      key_glyph = object$style$draw_key
    )
  }

  return(model_line)
}

.build_model_summary <- function(object) {

  strata   <- object$strata
  stratify <- object$part$model$stratify
  config   <- object$part$model$config

  which_corner <- names(sort(config$corner_distance)[4])
  pval <- tibble::tibble(lbl = object$style$format_p(config$p_value))

  if (which_corner == "top_left") {
    model_summary <- ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.05), y = I(.95), label = lbl),
      hjust = 0, vjust = 1, show.legend = FALSE
    )
  }

  if (which_corner == "top_right") {
    model_summary <- ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.95), y = I(.95), label = lbl),
      hjust = 1, vjust = 1, show.legend = FALSE
    )
  }

  if (which_corner == "bottom_left") {
    model_summary <- ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.05), y = I(.05), label = lbl),
      hjust = 0, vjust = 0, show.legend = FALSE
    )
  }

  if (which_corner == "bottom_right") {
    model_summary <- ggplot2::geom_label(
      data = pval,
      mapping = ggplot2::aes(x = I(.95), y = I(.05), label = lbl),
      hjust = 1, vjust = 0, show.legend = FALSE
    )
  }

  return(model_summary)
}

# specific buildiers: base plot quantile --------------------------------------

.build_quantiles <- function(object) {

  strata   <- object$strata
  stratify <- object$part$quantile$stratify
  config   <- object$part$quantile$config

  if (stratify == FALSE) {
    quantile_geoms <- list(
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(x = x_mid, y = y_mid),
        inherit.aes = FALSE,
        size = 2,
        key_glyph = object$style$draw_key
      ),
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
        width = 0.025 * (object$exposure$limits[2] - object$exposure$limits[1]),
        inherit.aes = FALSE,
        key_glyph = object$style$draw_key
      ),
      ggplot2::geom_text(
        data = config$summary,
        mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
        inherit.aes = FALSE,
        size = 3,
        show.legend = FALSE
      )
    )
  }

  if (stratify == TRUE) {
    quantile_geoms <- list(
      ggplot2::geom_point(
        data = config$summary,
        mapping = ggplot2::aes(
          x = x_mid, 
          y = y_mid,
          color = .data[["strata"]]
        ),
        inherit.aes = FALSE,
        size = 2,
        key_glyph = object$style$draw_key
      ),
      ggplot2::geom_errorbar(
        data = config$summary,
        mapping = ggplot2::aes(
          x = x_mid, 
          ymin = ci_lower, 
          ymax = ci_upper,
          color = .data[["strata"]]  
        ),
        inherit.aes = FALSE,
        width = 0.025 * (object$exposure$limits[2] - object$exposure$limits[1]),
        key_glyph = object$style$draw_key
      ),
      ggplot2::geom_text(
        data = config$summary,
        mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
        inherit.aes = FALSE,
        size = 3,
        show.legend = FALSE
      ) 
    ) 
  }

  return(quantile_geoms)
}

