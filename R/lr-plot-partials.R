

.datastrip_jitter <- function(object, panel, seed = 6433) {
  strata <- object$strata
  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data |> dplyr::filter(.data[[object$response$name]] == 1)
  if (!is_upr) dd <- object$data |> dplyr::filter(.data[[object$response$name]] == 0)
  
  if (object$part$strip$stratify == TRUE) {
    .set_label(dd[[strata$name]], strata$label)
    plt_mapping <- ggplot2::aes(x = .data[[object$exposure$name]], y = 0, color = .data[[strata$name]])
  } else {
    plt_mapping <- ggplot2::aes(x = .data[[object$exposure$name]], y = 0)
  }

  withr::with_seed(
    seed = seed,
    code = {
      plt <- dd |> 
        ggplot2::ggplot() +
        object$style$theme_base() +
        ggplot2::geom_jitter(
          mapping = plt_mapping,
          width = 0,
          height = 0.1,
          size = 1,
          key_glyph = object$style$draw_key
        ) +
        ggplot2::coord_cartesian(
          xlim = object$exposure$limits, 
          ylim = c(-0.1, 0.1), 
          clip = "off"
        ) + 
        ggplot2::scale_y_continuous(breaks = NULL, minor_breaks = NULL)
    }
  )

  return(plt)
}
