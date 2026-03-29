test_that("lr_model works", {
  expect_no_error(lr_model(response ~ exposure + sex, lr_data))
  mod1 <- lr_model(response ~ exposure + sex, lr_data)
  expect_s3_class(mod1, "glm")
})

test_that("lr_simulator returns a function", {
  mod1 <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
  expect_no_error(lr_simulator(mod1))
  mod1_sim <- lr_simulator(mod1)
  expect_type(mod1_sim, "closure")
})

test_that("lr_simulator works", {

  # simulator setup
  mod1 <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
  par1 <- coef(mod1)
  mod1_sim <- lr_simulator(mod1)

  # no counterfactuals
  p1 <- mod1_sim(param = par1, data = lr_data) 
  p2 <- unname(predict(mod1, type = "response")) # same result
  expect_equal(p1, p2)

  # user modifies the data set
  lr_data2 <- lr_data[1:20, ]
  p3 <- mod1_sim(param = par1, data = lr_data2) 
  p4 <- unname(predict(mod1, newdata = lr_data2, type = "response")) # same result
  expect_equal(p3, p4)

  # user modifies the parameters
  par2 <- par1
  int1 <- par1["(Intercept)"]
  par2["(Intercept)"] <- 0
  p5 <- mod1_sim(param = par2, data = lr_data)
  expect_equal(logit(p1), logit(p5) + int1)
  
})

