test_that(".part_group discretises continuous grouping variables", {
  plt1 <- lr_data |> lr_plot(aucss, ae1)
  plt2 <- lr_data |> lr_plot(aucss, ae1, sex)

  expect_no_error(plt1 |> lr_plot_show_groups(aucss))
  expect_no_error(plt2 |> lr_plot_show_groups(aucss))
  expect_no_error(plt1 |> lr_plot_show_groups(weight))
  expect_no_error(plt2 |> lr_plot_show_groups(weight))

  plt1a <- plt1 |> lr_plot_show_groups(aucss)
  plt2a <- plt2 |> lr_plot_show_groups(aucss)
  plt1w <- plt1 |> lr_plot_show_groups(weight)
  plt2w <- plt2 |> lr_plot_show_groups(weight)
  
  expect_type(plt1a$part$group, "list")
  expect_type(plt2a$part$group, "list")
  expect_type(plt1w$part$group, "list")
  expect_type(plt2w$part$group, "list")

  grp1a <- plt1a$part$group
  grp2a <- plt2a$part$group
  grp1w <- plt1w$part$group
  grp2w <- plt2w$part$group

  expect_named(grp1a, c("stratify", "config"))
  expect_named(grp2a, c("stratify", "config"))
  expect_named(grp1w, c("stratify", "config"))
  expect_named(grp2w, c("stratify", "config"))

  cfg1a <- grp1a$config
  cfg2a <- grp2a$config
  cfg1w <- grp1w$config
  cfg2w <- grp2w$config

  expect_length(cfg1a, 1)
  expect_length(cfg2a, 1)
  expect_length(cfg1w, 1)
  expect_length(cfg2w, 1)

  expect_named(cfg1a[[1]]$data, c(".aucss_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2a[[1]]$data, c(".aucss_quantile", "sex", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg1w[[1]]$data, c(".weight_quantile", "aucss", "n", "lbl", "lvl"))
  expect_named(cfg2w[[1]]$data, c(".weight_quantile", "sex", "aucss", "n", "lbl", "lvl"))

  fct1a <- cfg1a[[1]]$data[[1]]
  fct2a <- cfg2a[[1]]$data[[1]]
  fct1w <- cfg1w[[1]]$data[[1]]
  fct2w <- cfg2w[[1]]$data[[1]]

  expect_s3_class(fct1a, "factor")
  expect_s3_class(fct2a, "factor")
  expect_s3_class(fct1w, "factor")
  expect_s3_class(fct2w, "factor")

  expect_equal(attr(fct1a, "label"), attr(lr_data$aucss, "label"))
  expect_equal(attr(fct2a, "label"), attr(lr_data$aucss, "label"))
  expect_equal(attr(fct1w, "label"), attr(lr_data$weight, "label"))
  expect_equal(attr(fct2w, "label"), attr(lr_data$weight, "label"))

})
