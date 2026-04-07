test_that(".part_model constructs the correct data structure", {
  plt1 <- lr_data |> lr_plot(aucss, ae1)
  plt2 <- lr_data |> lr_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> lr_plot_show_model())
  expect_no_error(plt2 |> lr_plot_show_model())

  plt1 <- plt1 |> lr_plot_show_model()
  plt2 <- plt2 |> lr_plot_show_model()
  
  expect_type(plt1$part$model, "list")
  expect_type(plt2$part$model, "list")

  expect_named(plt1$part$model, c("stratify", "config"))
  expect_named(plt2$part$model, c("stratify", "config"))

  expect_equal(plt1$part$model$stratify, FALSE)
  expect_equal(plt2$part$model$stratify, TRUE)

  cfg1 <- plt1$part$model$config
  cfg2 <- plt1$part$model$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 7)
  expect_length(cfg2, 7)

  cfg_names <- c(
    "formula", "glm", "p_value", "conf_level", 
    "predictions", "corner_distance", "builder"
  ) 
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)

})

test_that(".part_quantile constructs the correct data structure", {
  plt1 <- lr_data |> lr_plot(aucss, ae1)
  plt2 <- lr_data |> lr_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> lr_plot_show_quantiles())
  expect_no_error(plt2 |> lr_plot_show_quantiles())

  plt1 <- plt1 |> lr_plot_show_quantiles()
  plt2 <- plt2 |> lr_plot_show_quantiles()
  
  expect_type(plt1$part$quantile, "list")
  expect_type(plt2$part$quantile, "list")

  expect_named(plt1$part$quantile, c("stratify", "config"))
  expect_named(plt2$part$quantile, c("stratify", "config"))

  expect_equal(plt1$part$quantile$stratify, FALSE)
  expect_equal(plt2$part$quantile$stratify, TRUE)

  cfg1 <- plt1$part$quantile$config
  cfg2 <- plt2$part$quantile$config

  expect_type(cfg1, "list")
  expect_type(cfg2, "list")

  expect_length(cfg1, 4)
  expect_length(cfg2, 4)

  cfg_names <- c("n_quantiles", "conf_level", "summary", "builder")
  expect_named(cfg1, cfg_names)
  expect_named(cfg2, cfg_names)

  smm1 <- cfg1$summary
  smm2 <- cfg2$summary

  expect_s3_class(smm1, "data.frame")
  expect_s3_class(smm2, "data.frame")

  smm_names <- c(
    "exposure_bins", "strata", "n1", "n0",           
    "x_mid", "y_mid", "y_mid_lbl", "ci_lower",     
    "ci_upper", "y_lwr_lbl", "y_upr_lbl", "y_lbl"     
  )

  expect_named(smm1, smm_names)
  expect_named(smm2, smm_names)

  expect_equal(unique(smm1$strata), NA)
  expect_equal(as.character(unique(smm2$strata)), c("Male", "Female"))

})

test_that(".part_group constructs the correct data structure", {
  plt1 <- lr_data |> lr_plot(aucss, ae1)
  plt2 <- lr_data |> lr_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> lr_plot_show_groups(aucss))
  expect_no_error(plt2 |> lr_plot_show_groups(aucss))
  expect_no_error(plt1 |> lr_plot_show_groups(weight))
  expect_no_error(plt2 |> lr_plot_show_groups(weight))
  expect_no_error(plt1 |> lr_plot_show_groups(sex))
  #expect_no_error(plt2 |> lr_plot_show_groups(sex))

  plt1a <- plt1 |> lr_plot_show_groups(aucss)
  plt2a <- plt2 |> lr_plot_show_groups(aucss)
  plt1w <- plt1 |> lr_plot_show_groups(weight)
  plt2w <- plt2 |> lr_plot_show_groups(weight)
  plt1s <- plt1 |> lr_plot_show_groups(sex)
  #plt2s <- plt2 |> lr_plot_show_groups(sex)
  
  expect_type(plt1a$part$group, "list")
  expect_type(plt2a$part$group, "list")
  expect_type(plt1w$part$group, "list")
  expect_type(plt2w$part$group, "list")
  expect_type(plt1s$part$group, "list")
  #expect_type(plt2s$part$group, "list")

  grp1a <- plt1a$part$group
  grp2a <- plt2a$part$group
  grp1w <- plt1w$part$group
  grp2w <- plt2w$part$group
  grp1s <- plt1s$part$group
  #grp2s <- plt2s$part$group

  expect_named(grp1a, c("stratify", "config"))
  expect_named(grp2a, c("stratify", "config"))
  expect_named(grp1w, c("stratify", "config"))
  expect_named(grp2w, c("stratify", "config"))
  expect_named(grp1s, c("stratify", "config"))
  #expect_named(grp2s, c("stratify", "config"))

  cfg1a <- grp1a$config
  cfg2a <- grp2a$config
  cfg1w <- grp1w$config
  cfg2w <- grp2w$config
  cfg1s <- grp1s$config
  #cfg2s <- grp2s$config

  expect_length(cfg1a, 1)
  expect_length(cfg2a, 1)
  expect_length(cfg1w, 1)
  expect_length(cfg2w, 1)
  expect_length(cfg1s, 1)
  #expect_length(cfg2s, 1)

  expect_named(cfg1a[[1]]$data, c(".aucss_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2a[[1]]$data, c(".aucss_quantile", "sex", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg1w[[1]]$data, c(".weight_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2w[[1]]$data, c(".weight_quantile", "sex", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg1s[[1]]$data, c("sex", "aucss", "n", "lbl", "lvl"))
  #expect_named(cfg2s[[1]]$data, c(".weight_quantile", "sex", "aucss", "n", "lbl", "lvl"))

  fct1a <- cfg1a[[1]]$data[[1]]
  fct2a <- cfg2a[[1]]$data[[1]]
  fct1w <- cfg1w[[1]]$data[[1]]
  fct2w <- cfg2w[[1]]$data[[1]]
  fct1s <- cfg1s[[1]]$data[[1]]
  #fct2s <- cfg2s[[1]]$data[[1]]

  expect_s3_class(fct1a, "factor")
  expect_s3_class(fct2a, "factor")
  expect_s3_class(fct1w, "factor")
  expect_s3_class(fct2w, "factor")
  expect_s3_class(fct1s, "factor")
  #expect_s3_class(fct2s, "factor")

  expect_equal(attr(fct1a, "label"), attr(lr_data$aucss, "label"))
  expect_equal(attr(fct2a, "label"), attr(lr_data$aucss, "label"))
  expect_equal(attr(fct1w, "label"), attr(lr_data$weight, "label"))
  expect_equal(attr(fct2w, "label"), attr(lr_data$weight, "label"))
  expect_equal(attr(fct1s, "label"), attr(lr_data$sex, "label"))
  #expect_equal(attr(fct2s, "label"), attr(lr_data$sex, "label"))

})
