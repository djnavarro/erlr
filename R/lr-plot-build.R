
# builders for the three plot types -------------------------------------------

build_base_plot <- function(object) {
  base <- ggplot2::ggplot() +
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
      build_model_ribbon(object) +
      build_model_line(object) +
      build_model_p(object)
  }
  if (!is.null(object$part$quantile)) {
    base <- base + build_quantiles(object)
  }
  return(base)
}

build_strip_plot <- function(object) {
  builder <- object$part$strip$builder
  strip <- list()
  if (object$part$strip$upper) strip$upper <- builder(object, "upper")
  if (object$part$strip$lower) strip$lower <- builder(object, "lower")
  return(strip)
}


build_group_plot <- function(object) {
  strata <- object$strata$group
  group <- list()

  for(g in names(object$part$group)) {

    if (is.null(strata$name)) {
      group[[g]] <- ggplot2::ggplot(
        data = object$part$group[[g]]$data,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]],
          y = lvl
        )
      )
    } else {
      group[[g]] <- ggplot2::ggplot(
        data = object$part$group[[g]]$data,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]],
          y = lvl,
          fill = .data[[strata$name]]
        )
      )
    }

    group[[g]] <- group[[g]] +
      ggplot2::geom_boxplot(alpha = .5) +
      ggplot2::coord_cartesian(
        xlim = object$exposure$limits, 
        clip = "off"
      ) 
  }
  
  return(group)  
}


# specific buildiers: base plot model -----------------------------------------

build_model_ribbon <- function(object) {
  strata <- object$strata$model
  if (is.null(strata$name)) {
    return(
      ggplot2::geom_ribbon(
        data = object$part$model$predictions,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]],
          ymin = ci_lower,
          ymax = ci_upper
        ),
        fill = "grey40",
        alpha = .25
      )
    )
  }
  ggplot2::geom_ribbon(
    data = object$part$model$predictions,
    mapping = ggplot2::aes(
      x = .data[[object$exposure$name]],
      fill = .data[[strata$name]],
      ymin = ci_lower,
      ymax = ci_upper
    ),
    alpha = .25
  )
}

build_model_line <- function(object) {
  strata <- object$strata$model
  if (is.null(strata$name)) {
    return(
      ggplot2::geom_path(
        data = object$part$model$predictions,
        mapping = ggplot2::aes(
          x = .data[[object$exposure$name]], 
          y = fit_resp
        ),
        linewidth = 1
      )
    )
  }
  ggplot2::geom_path(
    data = object$part$model$predictions,
    mapping = ggplot2::aes(
      x = .data[[object$exposure$name]], 
      y = fit_resp,
      color = .data[[strata$name]]
    ),
    linewidth = 1
  )
}

build_model_p <- function(object) {
  strata <- object$strata$model

  distance_from_corners <- object$part$model$predictions |> 
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

  which_corner <- names(sort(distance_from_corners)[4])
  pval <- tibble::tibble(
    lbl = object$style$format_p(object$part$model$p_value), 
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

# specific buildiers: base plot quantile --------------------------------------

build_quantiles <- function(object) {
  strata <- object$strata$quantile
  quantile_summary <- object$part$quantile$summary

  if (is.null(strata$name)) {
    return(
      list(
        ggplot2::geom_point(
          data = quantile_summary,
          mapping = ggplot2::aes(x = x_mid, y = y_mid),
          inherit.aes = FALSE,
          size = 2
        ),
        ggplot2::geom_errorbar(
          data = quantile_summary,
          mapping = ggplot2::aes(x = x_mid, ymin = ci_lower, ymax = ci_upper),
          inherit.aes = FALSE,
          width = 0.025 * (object$exposure$limits[2] - object$exposure$limits[1])
        ),
        ggplot2::geom_text(
          data = quantile_summary,
          mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
          inherit.aes = FALSE,
          size = 3
        )
      )
    )
  }
  list(
    ggplot2::geom_point(
      data = quantile_summary,
      mapping = ggplot2::aes(
        x = x_mid, 
        y = y_mid,
        color = .data[["strata"]]
      ),
      inherit.aes = FALSE,
      size = 2
    ),
    ggplot2::geom_errorbar(
      data = quantile_summary,
      mapping = ggplot2::aes(
        x = x_mid, 
        ymin = ci_lower, 
        ymax = ci_upper,
        color = .data[["strata"]]  
      ),
      inherit.aes = FALSE,
      width = 0.025 * (object$exposure$limits[2] - object$exposure$limits[1])
    ),
    ggplot2::geom_text(
      data = quantile_summary,
      mapping = ggplot2::aes(x = x_mid, y = y_lbl, label = y_mid_lbl),
      inherit.aes = FALSE,
      size = 3
    ) 
  )
}

# specific buildiers: strip plot ----------------------------------------------

build_strip_jitter <- function(object, panel) {
  strata <- object$strata$strip
  is_upr <- panel == "upper"
  if (is_upr)  dd <- object$data |> dplyr::filter(.data[[object$response$name]] == 1)
  if (!is_upr) dd <- object$data |> dplyr::filter(.data[[object$response$name]] == 0)
  
  if (!is.null(strata$name)) {
    set_label(dd[[strata$name]], strata$label)
    plt_mapping <- ggplot2::aes(x = .data[[object$exposure$name]], y = 0, color = .data[[strata$name]])
  } else {
    plt_mapping <- ggplot2::aes(x = .data[[object$exposure$name]], y = 0)
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
      xlim = object$exposure$limits, 
      ylim = c(-0.1, 0.1), 
      clip = "off"
    ) + 
    ggplot2::scale_y_continuous(breaks = NULL, minor_breaks = NULL)
  
}

# composition/polishing steps -------------------------------------------------

polish_margins <- function(object) {

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
  if (!is.null(p$group)) {
    for(g in seq_along(p$group)) {
      p$group[[g]] + ggplot2::theme(margins = margins)
    }
  }

  return(p)
}

polish_labels <- function(object) {
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

  if (!is.null(p$group)) {
    for(g in names(p$group)) {
      p$group[[g]] <- p$group[[g]] + ggplot2::labs(
        x = object$exposure$label,
        y = object$part$group[[g]]$y$label
      )
    }
  }

  return(p)
}

polish_arrangement <- function(object) {
  
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
  
  if (!is.null(object$plot$group)) {
    group_n <- purrr::map_dbl(object$part$group, \(bb) bb$n_groups)
    group_prop <- group_n / sum(group_n)
    for(g in seq_along(object$plot$group)) {
      ind <- ind + 1L
      plot_list[[ind]] <- object$plot$group[[g]]
      plot_size[ind] <- object$style$height$group * group_prop[g]
    }
  }

  return(list(plots = plot_list, heights = plot_size))
}


