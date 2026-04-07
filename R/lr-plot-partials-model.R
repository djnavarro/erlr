

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




#' @rdname lr_partial
#' @export
build_model_spaghetti <- function(data, config, stratify, exposure, response, strata, style) {

  fn <- lr_simulator(config$glm)

  nsim <- 100L
  seed <- config$seed
  if (is.null(seed)) {
    seed <- .pick_seed()
    rlang::inform(paste("Using seed =", seed))
  }
  withr::with_seed(
    seed = seed,
    code = {
      par <- mvtnorm::rmvnorm(
        n = nsim, 
        mean = stats::coef(config$glm),
        sigma = stats::vcov(config$glm)
      )
    }
  )

  sim <- list()
  for (ii in 1:nsim) {
    dd_sim <- config$prediction |> 
      dplyr::select(dplyr::all_of(c(exposure$name, "fit_resp", strata$name))) |> 
      dplyr::mutate(row_id = dplyr::row_number(), sim_id = ii)
    dd_sim[[response$name]] <- 1
    dd_sim$fit_resp <- fn(param = par[ii,], dd_sim)
    dd_sim[[response$name]] <- NULL
    sim[[ii]] <- dd_sim
  }
  sim <- dplyr::bind_rows(sim)

  if (stratify == FALSE) {

    model_spaghetti <- ggplot2::geom_path(
      data = sim,
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[["fit_resp"]],
        group = .data[["sim_id"]]
      ),
      fill = "grey40",
      alpha = .1,
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

    model_spaghetti <- ggplot2::geom_path(
      data = sim |> 
        dplyr::mutate(sim_id2 = paste(.data[["sim_id"]], .data[[strata$name]])),
      mapping = ggplot2::aes(
        x = .data[[exposure$name]],
        y = .data[["fit_resp"]],
        color = .data[[strata$name]],
        group = .data[["sim_id2"]]
      ),
      fill = "grey40",
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
  
  geoms <- list(model_spaghetti, model_line)
  return(geoms)
}
