test_that("lr_vpc_sim works", {
  mod <- lr_model(ae1 ~ aucss + sex, lr_data)
  expect_no_error(lr_vpc_sim(mod, nsim = 2))
  sim <- lr_vpc_sim(mod, nsim = 2)
  expect_s3_class(sim, "data.frame")
  expect_named(sim, c("ae1", "aucss", "sex", "row_id", "sim_id"))
  expect_equal(nrow(sim), nrow(lr_data) * 2)
})

test_that("lr_vpc_plot returns a ggplot", {
  mod <- lr_model(ae1 ~ aucss + sex, lr_data)
  sim <- lr_vpc_sim(mod, nsim = 5)
  expect_no_error(lr_vpc_plot(mod, sim, group_by = aucss))
  p1 <- lr_vpc_plot(mod, sim, group_by = aucss)
  p2 <- lr_vpc_plot(mod, sim, group_by = sex)
  expect_true(inherits(p1, "ggplot"))
  expect_true(inherits(p2, "ggplot"))
})