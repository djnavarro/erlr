
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