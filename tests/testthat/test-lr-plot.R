
test_that("lr_plot_setup creates an erlr_plot", {
  expect_no_error(lr_plot_setup(lr_data, "exposure_1", "response_1"))
  plt <- lr_plot_setup(lr_data, "exposure_1", "response_1")
  expect_s3_class(plt, "erlr_plot")
  expect_named(plt, c("data", "name", "label", "formula", "model", "plot", "info", "output"))
  expect_type(plt$data, "list")
  expect_type(plt$name, "list")
  expect_type(plt$label, "list")
  expect_named(plt$data, c("observed", "predicted"))
  expect_named(plt$name, c("exposure", "response"))
  expect_named(plt$label, c("exposure", "response"))
  expect_s3_class(plt$formula, "formula")
  expect_s3_class(plt$model, "erlr_glm")
  expect_s3_class(plt$model, "glm")
  expect_type(plt$plot, "list")
  expect_named(plt$plot, c("base", "strip", "box"))
  expect_type(plt$info, "list")
  expect_null(plt$output)
})

test_that("lr_plot creates a base ggplot", {
  expect_no_error(lr_data |> lr_plot(exposure_1, response_1))
  plt <- lr_data |> lr_plot(exposure_1, response_1)
  expect_s3_class(plt, "erlr_plot")
  expect_true(inherits(plt$plot$base, "ggplot"))
})

test_that("lr_plot + lr_plot_add_quantiles creates a base ggplot", {
  base_plt <- lr_data |> lr_plot(exposure_1, response_1)
  expect_no_error(base_plt |> lr_plot_add_quantiles(bins = 4))
  plt <- base_plt |> lr_plot_add_quantiles(bins = 4)
  expect_s3_class(plt, "erlr_plot")
  expect_true(inherits(plt$plot$base, "ggplot"))
})

test_that("lr_add_boxplot creates a box ggplot", {
  base_plt <- lr_data |> lr_plot(exposure_1, response_1)
  expect_no_error(base_plt |> lr_plot_add_quantiles(bins = 4))
  plt <- base_plt |> lr_plot_add_boxplot(group_by = quartile_1) 
  expect_s3_class(plt, "erlr_plot")
  expect_true(inherits(plt$plot$box[[1]], "ggplot"))
  expect_equal(plt$plot$base, base_plt$plot$base)
})

test_that("lr_plot_add_jitter_strips creates a strip ggplot", {
  base_plt <- lr_data |> lr_plot(exposure_1, response_1)
  expect_no_error(base_plt |> lr_plot_add_jitter_strips(color_by = sex))
  plt <- base_plt |> lr_plot_add_jitter_strips(color_by = sex)
  expect_s3_class(plt, "erlr_plot")
  expect_true(inherits(plt$plot$strip$upper, "ggplot"))
  expect_true(inherits(plt$plot$strip$lower, "ggplot"))
  expect_equal(plt$plot$base, base_plt$plot$base)
})

test_that("lr_plot_add_dotplot_strips creates a strip ggplot", {
  base_plt <- lr_data |> lr_plot(exposure_1, response_1)
  expect_no_error(base_plt |> lr_plot_add_dotplot_strips(color_by = sex))
  plt <- base_plt |> lr_plot_add_dotplot_strips(color_by = sex)
  expect_s3_class(plt, "erlr_plot")
  expect_true(inherits(plt$plot$strip$upper, "ggplot"))
  expect_true(inherits(plt$plot$strip$lower, "ggplot"))
  expect_equal(plt$plot$base, base_plt$plot$base)
})

test_that("lr_plot_build assembles plots", {
  base_plt <- lr_data |> 
    lr_plot(exposure_1, response_1) |> 
    lr_plot_add_quantiles(bins = 4) |> 
    lr_plot_add_dotplot_strips(color_by = sex) |> 
    lr_plot_add_boxplot(group_by = quartile_1)
  expect_no_error(base_plt |> lr_plot_build())

  plt1 <- base_plt |> lr_plot_build()
  expect_true(inherits(plt1$output, "ggplot"))
  expect_true(inherits(plt1$output, "patchwork"))
  expect_equal(plt1$info$plot_size, c(1, 6, 1, 3))

  plt2 <- base_plt |> lr_plot_build(base_height = 4, strip_height = 4, box_height = 4)
  expect_true(inherits(plt2$output, "ggplot"))
  expect_true(inherits(plt2$output, "patchwork"))
  expect_equal(plt2$info$plot_size, c(2, 4, 2, 4))
})