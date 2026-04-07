
# partials should take standardised arguments:
# - exposure
# - response
# - strata
# - stratify
# - config
# - style

# datastrip partials ----------------------------------------------------------

# datastrip partials should return a ggplot2 plot object

.datastrip_jitter <- function(data, config, stratify, exposure, response, strata, style) {

  is_upr <- config$panel == "upper"
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
      plt <- dat |> 
        ggplot2::ggplot() +
        style$theme_base() +
        ggplot2::geom_jitter(
          mapping = plot_map,
          width = 0,
          height = 0.1,
          size = 1,
          key_glyph = style$draw_key
        ) +
        ggplot2::coord_cartesian(
          xlim = exposure$limits, 
          ylim = c(-0.1, 0.1), 
          clip = "off"
        ) + 
        ggplot2::scale_y_continuous(
          breaks = NULL, 
          minor_breaks = NULL
        )
    }
  )

  return(plt)
}

# group partials --------------------------------------------------------------

# group partials should return a ggplot2 plot object

.group_boxplot <- function(data, config, stratify, exposure, response, strata, style) {

  if (stratify == FALSE) {
    plot_map <- ggplot2::aes(x = .data[[exposure$name]], y = lvl)
  } 
  if (stratify == TRUE) {
    plot_map <- ggplot2::aes(x = .data[[exposure$name]], y = lvl, fill = .data[[strata$name]])
  }

  plt <- config$data |> 
    ggplot2::ggplot(mapping = plot_map) + 
    style$theme_base() +
    ggplot2::geom_boxplot(alpha = .5, key_glyph = style$draw_key) +
    ggplot2::coord_cartesian(xlim = exposure$limits, clip = "off") 
  
  return(plt)
}
