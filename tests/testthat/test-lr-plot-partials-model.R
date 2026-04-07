
test_that("build_model_ribbonline returns geom + coord", {
  p1 <- lr_plot(lr_data, aucss, ae1)
  p2 <- lr_plot(lr_data, aucss, ae1, sex)

  expect_no_error(p1 |> lr_plot_show_model(style = "ribbonline"))
  expect_no_error(p2 |> lr_plot_show_model(style = "ribbonline"))

  p1 <- p1 |> lr_plot_show_model(style = "ribbonline")
  p2 <- p2 |> lr_plot_show_model(style = "ribbonline")

  expect_no_error(
    build_model_ribbonline(
      data = p1$data,
      config = p1$part$model$config,
      stratify = p1$part$model$stratify,
      exposure = p1$exposure,
      response = p1$response,
      strata = p1$strata,
      style = p1$style
    )
  )
  expect_no_error(
    build_model_ribbonline(
      data = p2$data,
      config = p2$part$model$config,
      stratify = p2$part$model$stratify,
      exposure = p2$exposure,
      response = p2$response,
      strata = p2$strata,
      style = p2$style
    )
  )

  p1_out <- build_model_ribbonline(
      data = p1$data,
      config = p1$part$model$config,
      stratify = p1$part$model$stratify,
      exposure = p1$exposure,
      response = p1$response,
      strata = p1$strata,
      style = p1$style
    )
  p2_out <- build_model_ribbonline(
      data = p2$data,
      config = p2$part$model$config,
      stratify = p2$part$model$stratify,
      exposure = p2$exposure,
      response = p2$response,
      strata = p2$strata,
      style = p2$style
    )

  expect_length(p1_out, 2)
  expect_length(p2_out, 2)

  expect_true(inherits(p1_out[[1]], "LayerInstance"))
  expect_true(inherits(p1_out[[2]], "LayerInstance"))

  expect_true(inherits(p2_out[[1]], "LayerInstance"))
  expect_true(inherits(p2_out[[2]], "LayerInstance"))
})