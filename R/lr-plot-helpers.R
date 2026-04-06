
define_plot_variable <- function(name = NULL, label = NULL, limits = NULL, role = NULL) {
  list(
    name = name, 
    label = label, 
    limits = limits,
    role = role
  )
}

define_part_strata <- function(object, strata, context) {
  strata_quo <- rlang::enquo(strata)
  strata_val <- rlang::eval_tidy(
    rlang::quo_set_env(
      quo = strata_quo, 
      env = rlang::as_environment(object$data)
    )
  )
  if (rlang::quo_is_null(strata_quo)) { # if strata is NULL
    strata_name   <- NULL
    strata_label  <- NULL
    strata_limits <- NULL
  } else if (rlang::quo_is_symbol(strata_quo)) { # if strata is a variable name
    strata_name   <- rlang::as_name(strata_quo)
    strata_label  <- get_label(object$data[[strata_name]]) %||% strata_name
    strata_limits <- unique(strata_val)
  } else if (strata_val == "inherit") { # use cached value
    strata_name   <- object$strata$default$name
    strata_label  <- object$strata$default$label
    strata_limits <- object$strata$default$limits
  } 
  return(define_plot_variable(
    name = strata_name, 
    label = strata_label, 
    limits = strata_limits,
    role = context
  ))
}

get_strata_values <- function(data, name) {
  if (is.null(name)) return(NA)
  data[[name]]
}

get_model_predictions <- function(object) {

  pred_dat <- seq(
    from = object$exposure$limits[1], 
    to = object$exposure$limits[2], 
    length.out = 300L
  ) |> 
    data.frame() |> 
    set_names(object$exposure$name)
  
  if (!is.null(object$strata$model$name)) {
    pred_dat <- pred_dat |> 
      dplyr::cross_join(
        data.frame(object$strata$model$limits) |> 
        set_names(object$strata$model$name)
      )
  }

  lr_predict(
    object = object$part$model$glm,
    newdata = pred_dat, 
    conf_level = object$part$model$conf_level
  )
}