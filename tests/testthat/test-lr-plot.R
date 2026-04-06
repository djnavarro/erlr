
test_that("lr_plot creates an erlr_plot (minimal)", {
  expect_no_error(lr_plot(lr_data, exposure_1, response_1))
  plt <- lr_plot(lr_data, exposure_1, response_1)
  expect_s3_class(plt, "erlr_plot")
})

test_that("lr_plot creates an erlr_plot (all parts)", {
  expect_no_error(
    lr_data |> 
      lr_plot(exposure_1, response_1) |> 
      lr_plot_show_model() |> 
      lr_plot_show_quantiles()  |> 
      lr_plot_show_datastrip()  |> 
      lr_plot_show_groups(c(quartile_1, dose))
  )
  plt <- lr_data |> 
    lr_plot(exposure_1, response_1) |> 
    lr_plot_show_model() |> 
    lr_plot_show_quantiles()  |> 
    lr_plot_show_datastrip()  |> 
    lr_plot_show_groups(c(quartile_1, dose))
  expect_s3_class(plt, "erlr_plot")
})

test_that("lr_plot creates an erlr_plot (all parts, all strata)", {
  expect_no_error(
    lr_data |> 
      lr_plot(exposure_1, response_1, sex) |> 
      lr_plot_show_model() |> 
      lr_plot_show_quantiles()  |> 
      lr_plot_show_datastrip()  |> 
      lr_plot_show_groups(c(quartile_1, dose))
  )
  plt <- lr_data |> 
    lr_plot(exposure_1, response_1, sex) |> 
    lr_plot_show_model() |> 
    lr_plot_show_quantiles()  |> 
    lr_plot_show_datastrip()  |> 
    lr_plot_show_groups(c(quartile_1, dose))
  expect_s3_class(plt, "erlr_plot")
})

plt1 <- lr_data |>
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() 

plt2 <- lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles()  |> 
  lr_plot_show_datastrip()

plt3 <- lr_data |> 
  lr_plot(exposure_1, response_1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles()  |> 
  lr_plot_show_datastrip()  |> 
  lr_plot_show_groups(c(quartile_1, dose))

test_that("lr_plot_build does not error", {
  expect_no_error(lr_plot_build(plt1))
  expect_no_error(lr_plot_build(plt2))
  expect_no_error(lr_plot_build(plt3))
})

test_that("lr_plot_build constructs ggplot2 objects", {
  plt1_built <- lr_plot_build(plt1)
  plt2_built <- lr_plot_build(plt2)
  plt3_built <- lr_plot_build(plt3)

  plt1_built_gg <- plt1_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)
  plt2_built_gg <- plt2_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)
  plt3_built_gg <- plt3_built$plot |> purrr::list_flatten() |> purrr::map_lgl(ggplot2::is_ggplot)

  expect_equal(
    plt1_built_gg, 
    c(base = TRUE, strip = FALSE, group = FALSE)
  )
  expect_equal(
    plt2_built_gg, 
    c(base = TRUE, strip_upper = TRUE, strip_lower = TRUE, group = FALSE)
  )
  expect_equal(
    plt3_built_gg, 
    c(base = TRUE, strip_upper = TRUE, strip_lower = TRUE, group_quartile_1 = TRUE, group_dose = TRUE)
  )
})



