
# vpc helpers -------------------------------------------------------------

#' VPC simulations for logistic regression models
#'
#' @param object Logistic regression model
#' @param nsim Number of replicates
#' @param seed RNG state
#'
#' @returns A data frame or tibble
#'
#' @export
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
#' sim <- lr_vpc_sim(mod)
#' sim
#' 
lr_vpc_sim <- function(object, nsim = 100, seed = NULL) {
  if (is.null(seed)) {
    seed <- .pick_seed()
    rlang::inform(paste("Using seed =", seed))
  }
  withr::with_seed(
    seed = seed, 
    code = {
      sim <- .lr_vpc_sim(object = object, nsim = nsim)
    }
  )
  return(sim)
}

.lr_vpc_sim <- function(object, nsim) {
  ff <- object$formula
  vv <- all.vars(ff)
  exp_var <- vv[2]
  rsp_var <- vv[1]
  fn <- lr_simulator(object)
  dd <- object$data[, vv]
  par <- mvtnorm::rmvnorm(
    n = nsim, 
    mean = stats::coef(object),
    sigma = stats::vcov(object)
  )
  sim <- list()
  for (ii in 1:nsim) {
    dd_sim <- dd |> 
      dplyr::mutate(
        row_id = dplyr::row_number(),
        sim_id = ii
      )
    dd_sim[[rsp_var]] <- fn(param = par[ii,], dd_sim)
    sim[[ii]] <- dd_sim
  }
  sim <- dplyr::bind_rows(sim)
  return(sim)
}

#' Plot VPC simulations for logistic regression models
#'
#' @param object Logistic regression model
#' @param sim VPC simulations
#' @param group_by Variable (unquoted) to stratify predictions
#' @param conf_level Confidence level
#'
#' @returns A ggplot2 object
#'
#' @examples
#' mod <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
#' sim <- lr_vpc_sim(mod)
#' lr_vpc_plot(mod, sim, group_by = exposure_1)
#' lr_vpc_plot(mod, sim, group_by = sex)
#' 
#' @export
#' 
lr_vpc_plot <- function(object, sim, group_by, conf_level = 0.95) {

  ff <- object$formula
  ll <- purrr::imap(object$data, \(x,l) attr(x, "label"))
  vv <- all.vars(ff)
  exp_var <- vv[2]
  rsp_var <- vv[1]
  grp_var <- rlang::as_name(rlang::enquo(group_by))
  obs <- object$data[, vv] |> 
    dplyr::mutate(
      row_id = dplyr::row_number(),
      sim_id = 0L
    )
  dat <- dplyr::bind_rows(
    Observed = obs,
    Simulated = sim,
    .id = "Source"
  )

  if (is.numeric(dat[[grp_var]])) {
    if (grp_var == exp_var) dat[[".is_placebo"]] <- dat[[exp_var]] == 0
    if (grp_var != exp_var) dat[[".is_placebo"]] <- rep(FALSE, nrow(dat))
    dat <- dat |> dplyr::mutate(
      .quantile = cut_exposure_quantile(
        exposure = .data[[grp_var]], n = 4, 
        is_placebo = .data[[".is_placebo"]]
      ),
      .by = "Source"
    )
    ll[[".quantile"]] <- ll[[grp_var]]
    grp_var <- ".quantile"
  }

  percent <- scales::label_percent(accuracy = 1)
  smm_obs <- dat |>
    dplyr::filter(Source == "Observed") |> 
    dplyr::summarise(
      n1 = sum(!!dplyr::sym(rsp_var) == 1, na.rm = TRUE),
      n0 = sum(!!dplyr::sym(rsp_var) == 0, na.rm = TRUE),
      y_mid = mean(.data[[rsp_var]], na.rm = TRUE),
      y_mid_lbl = percent(n1 / (n0 + n1)),
      ci_lower = clopper_pearson(n1, n0 + n1, conf_level)["lower"], 
      ci_upper = clopper_pearson(n1, n0 + n1, conf_level)["upper"], 
      .by = c("Source", grp_var)
    ) |> 
    dplyr::select(-n1, -n0)

  alpha <- (1 - conf_level)/2
  smm_sim <- dat |> 
    dplyr::filter(Source == "Simulated") |> 
    dplyr::summarise(
      y = mean(.data[[rsp_var]], na.rm = TRUE),
      .by = c("Source", grp_var, "sim_id")
    ) |> 
    dplyr::summarise(
      y_mid = mean(y, na.rm = TRUE),
      y_mid_lbl = percent(y_mid),
      ci_lower = stats::quantile(y, probs = alpha, na.rm = TRUE), 
      ci_upper = stats::quantile(y, probs = 1 - alpha, na.rm = TRUE), 
      .by = c("Source", grp_var)
    )

  smm <- dplyr::bind_rows(smm_obs, smm_sim)
  attr(smm[["y_mid"]], "label") <- ll[[rsp_var]]
  attr(smm[[grp_var]], "label") <- ll[[grp_var]]

  plt <- smm |> 
    ggplot2::ggplot(ggplot2::aes(
      x = .data[[grp_var]], 
      y = y_mid,
      color = Source
    )) +
    ggplot2::geom_errorbar(
      ggplot2::aes(
        ymin = ci_lower,
        ymax = ci_upper
      ),
      position = ggplot2::position_dodge2(width = .2),
      width = .2
    ) + 
    ggplot2::geom_point(
      position = ggplot2::position_dodge2(width = .2),
      size = 2
    ) +
    ggplot2::theme_bw() + 
    NULL

  return(plt)
}
