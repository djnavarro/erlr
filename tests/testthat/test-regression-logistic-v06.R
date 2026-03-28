test_that("lr_model works", {
  expect_no_error(lr_model(response ~ exposure + sex, lr_dat))
  mod1 <- lr_model(response ~ exposure + sex, lr_dat)
  expect_s3_class(mod1, "glm")
})

test_that("lr_simulator returns a function", {
  mod1 <- lr_model(response ~ exposure + sex, lr_dat)
  expect_no_error(lr_simulator(mod1))
  mod1_sim <- lr_simulator(mod1)
  expect_type(mod1_sim, "closure")
})

test_that("lr_simulator works", {

  # simulator setup
  mod1 <- lr_model(response ~ exposure + sex, lr_dat)
  par1 <- coef(mod1)
  mod1_sim <- lr_simulator(mod1)

  # no counterfactuals
  p1 <- mod1_sim(param = par1, data = lr_dat) 
  p2 <- unname(predict(mod1, type = "response")) # same result
  expect_equal(p1, p2)

  # user modifies the data set
  lr_dat2 <- lr_dat[1:20, ]
  p3 <- mod1_sim(param = par1, data = lr_dat2) 
  p4 <- unname(predict(mod1, newdata = lr_dat2, type = "response")) # same result
  expect_equal(p3, p4)

  # user modifies the parameters
  par2 <- par1
  int1 <- par1["(Intercept)"]
  par2["(Intercept)"] <- 0
  p5 <- mod1_sim(param = par2, data = lr_dat)
  expect_equal(logit(p1), logit(p5) + int1)
  
})

