test_that("lr_data is correctly formed", {
  lr_data2 <- make_lr_data(seed = 2407L)
  expect_equal(lr_data, lr_data2)
})

