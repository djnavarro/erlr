
test_that("build_datastrip_jitter returns geom + coord + yscale", {
  p1 <- lr_plot(lr_data, aucss, ae1)
  p2 <- lr_plot(lr_data, aucss, ae1, sex)

  expect_no_error(p1 |> lr_plot_show_datastrip(style = "jitter"))
  expect_no_error(p2 |> lr_plot_show_datastrip(style = "jitter"))

  p1 <- p1 |> lr_plot_show_datastrip(style = "jitter")
  p2 <- p2 |> lr_plot_show_datastrip(style = "jitter")

  config1 <- p1$part$group$strip$config
  config2 <- p2$part$group$strip$config

  config1$panel <- "upper"
  config2$panel <- "upper"

  expect_no_error(
    build_datastrip_jitter(
      data = p1$data,
      config = config1,
      stratify = p1$part$strip$stratify,
      exposure = p1$exposure,
      response = p1$response,
      strata = p1$strata,
      style = p1$style
    )
  )
  expect_no_error(
    build_datastrip_jitter(
      data = p2$data,
      config = config2,
      stratify = p2$part$strip$stratify,
      exposure = p2$exposure,
      response = p2$response,
      strata = p2$strata,
      style = p2$style
    )
  )

  p1_out <- build_datastrip_jitter(
      data = p1$data,
      config = config1,
      stratify = p1$part$strip$stratify,
      exposure = p1$exposure,
      response = p1$response,
      strata = p1$strata,
      style = p1$style
    )
  p2_out <- build_datastrip_jitter(
      data = p2$data,
      config = config2,
      stratify = p2$part$strip$stratify,
      exposure = p2$exposure,
      response = p2$response,
      strata = p2$strata,
      style = p2$style
    )

  expect_length(p1_out, 3)
  expect_length(p2_out, 3)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "CoordCartesian"))
  expect_true(inherits(p1_out[[3]], "ScaleContinuousPosition"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "CoordCartesian"))
  expect_true(inherits(p2_out[[3]], "ScaleContinuousPosition"))
})

