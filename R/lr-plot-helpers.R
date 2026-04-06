
.plot_variable <- function(name = NULL, label = NULL, limits = NULL, role = NULL) {
  list(
    name = name, 
    label = label, 
    limits = limits,
    role = role
  )
}

.get_strata_values <- function(data, name) {
  if (is.null(name)) return(NA)
  data[[name]]
}

.get_model_predictions <- function(object) {

  pred_dat <- seq(
    from = object$exposure$limits[1], 
    to = object$exposure$limits[2], 
    length.out = 300L
  ) |> 
    data.frame() |> 
    .set_names(object$exposure$name)
  
  if (!is.null(object$strata$name)) {
    pred_dat <- pred_dat |> 
      dplyr::cross_join(
        data.frame(object$strata$limits) |> 
        .set_names(object$strata$name)
      )
  }

  lr_predict(
    object = object$part$model$glm,
    newdata = pred_dat, 
    conf_level = object$part$model$conf_level
  )
}