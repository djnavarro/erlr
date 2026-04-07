
.part_model <- function(object, stratify, style, conf_level) {
  
  part_model <- list()
  config <- list()

  # model formula
  fml <- paste(object$response$name, object$exposure$name, sep = " ~ ")
  if (stratify == TRUE) fml <- paste(fml, object$strata$name, sep = " + ")
  config$formula <- stats::as.formula(fml)

  # model object
  config$glm <- lr_model(formula = config$formula, data = object$data)

  # model summary
  # TODO: should this be moved to the builder function? It's quite specific.
  # also needs to be extended to work when a stratification variable is present
  if (is.null(object$strata$name) || stratify == FALSE) {
    config$p_value <- summary(config$glm)$coefficients[2, "Pr(>|z|)"]
  }

  # confidence level
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
  config$builder$summary <- build_summary_pvalue # TODO: how to allow custom summary without breaking the style arg

  # store and return
  part_model$stratify <- stratify
  part_model$config <- config

  return(part_model)
}


.part_group <- function(object, group_cols, stratify, style, bins) {

  part_group <- list()
  part_group$stratify <- stratify
  part_group$config <- list()

  for(g in group_cols) {

    config <- list()
    if (style == "boxplot") config$builder <- build_group_boxplot
    if (style == "violin")  config$builder <- build_group_violin

    # data 
    dat <- object$data

    # create factor from continuous grouping variables
    if (is.numeric(dat[[g]])) {
      new_g <- paste0(".", g, "_quantile")
      new_g_sym <- dplyr::sym(new_g)
      if (g == object$exposure$name) {
        dat <- dat |> 
          dplyr::mutate(
            {{new_g_sym}} := .data[[g]] |> 
              cut_exposure_quantile() |> 
              .set_label(.get_label(dat[[g]]) %||% g)
          )
        
      } else {
        dat <- dat |> 
          dplyr::mutate(
            {{new_g_sym}} := .data[[g]] |> 
              cut_quantile() |> 
              .set_label(.get_label(dat[[g]]) %||% g)
          )
      }
      g <- new_g
    }

    # store the variable names used for grouping
    if (stratify)  config$groupings <- c(g, object$strata$name)
    if (!stratify) config$groupings <- g

    # store information about the y-axis variable
    config$y <- .plot_variable(
      name = g,
      label = .get_label(dat[[g]]) %||% g,
      role = paste("group", g, sep = "_")
    )

    # store sample size information (for merge into plot labels)
    config$counts <- dat |> 
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
    config$data <- dat |> 
      dplyr::select(dplyr::all_of(c(config$groupings, object$exposure$name))) |> 
      dplyr::left_join(config$counts, by = config$groupings)
    
    part_group$config[[g]] <- config
  }

  return(part_group)
}