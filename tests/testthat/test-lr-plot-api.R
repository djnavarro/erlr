
test_that("lr_plot creates an erlr_plot (minimal)", {
  expect_no_error(lr_plot(lr_data, aucss, ae1))
  plt <- lr_plot(lr_data, aucss, ae1)
  expect_s3_class(plt, "erlr_plot")
})

test_that("lr_plot creates an erlr_plot (all parts)", {
  expect_no_error(
    lr_data |> 
      dplyr::mutate(dose = factor(dose)) |> 
      lr_plot(aucss, ae1) |> 
      lr_plot_show_model() |> 
      lr_plot_show_quantiles()  |> 
      lr_plot_show_datastrip()  |> 
      lr_plot_show_groups(c(treatment, dose))
  )
  plt <- lr_data |> 
    dplyr::mutate(dose = factor(dose)) |> 
    lr_plot(aucss, ae1) |> 
    lr_plot_show_model() |> 
    lr_plot_show_quantiles()  |> 
    lr_plot_show_datastrip()  |> 
    lr_plot_show_groups(c(treatment, dose))
  expect_s3_class(plt, "erlr_plot")
})

test_that("lr_plot creates an erlr_plot (all parts, all strata)", {
  expect_no_error(
    lr_data |> 
      dplyr::mutate(dose = factor(dose)) |> 
      lr_plot(aucss, ae1, sex) |> 
      lr_plot_show_model() |> 
      lr_plot_show_quantiles()  |> 
      lr_plot_show_datastrip()  |> 
      lr_plot_show_groups(c(treatment, dose))
  )
  plt <- lr_data |> 
    dplyr::mutate(dose = factor(dose)) |> 
    lr_plot(aucss, ae1, sex) |> 
    lr_plot_show_model() |> 
    lr_plot_show_quantiles()  |> 
    lr_plot_show_datastrip()  |> 
    lr_plot_show_groups(c(treatment, dose))
  expect_s3_class(plt, "erlr_plot")
})

plt1 <- lr_data |>
  lr_plot(aucss, ae1) |> 
  lr_plot_show_model() 

plt2 <- lr_data |> 
  lr_plot(aucss, ae1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles()  |> 
  lr_plot_show_datastrip()

plt3 <- lr_data |> 
  dplyr::mutate(dose = factor(dose)) |> 
  lr_plot(aucss, ae1) |> 
  lr_plot_show_model() |> 
  lr_plot_show_quantiles()  |> 
  lr_plot_show_datastrip()  |> 
  lr_plot_show_groups(c(treatment, dose))

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
    c(base = TRUE, strip_upper = TRUE, strip_lower = TRUE, group_treatment = TRUE, group_dose = TRUE)
  )
})

test_that("print method works as expected", {
  print_quiet <- purrr::quietly(print.erlr_plot)

  expect_no_error(print_quiet(plt1))
  expect_no_error(print_quiet(plt2))
  expect_no_error(print_quiet(plt3))

  printout1 <- print_quiet(plt1)
  printout2 <- print_quiet(plt2)
  printout3 <- print_quiet(plt3)

  expect_equal(printout1$result, plt1)
  expect_equal(printout2$result, plt2)
  expect_equal(printout3$result, plt3)

  expect_equal(printout1$warnings, character())
  expect_equal(printout2$warnings, character())
  expect_equal(printout3$warnings, character())

  expect_equal(printout1$messages, character())
  expect_equal(printout2$messages, character())
  expect_equal(printout3$messages, character())

  outlines1 <- strsplit(printout1$output, split = "\n")[[1]]
  outlines2 <- strsplit(printout2$output, split = "\n")[[1]]
  outlines3 <- strsplit(printout3$output, split = "\n")[[1]]

  expect_length(outlines1, 9)
  expect_length(outlines2, 11)
  expect_length(outlines3, 12) 

})

