test_that(".lr_add_term works", {
  mod1 <- lr_model(response_1 ~ exposure_1, lr_data)
  expect_no_error(.lr_add_term(mod1, ~sex, quiet = TRUE))
  mod2 <- .lr_add_term(mod1, ~sex, quiet = TRUE)
  expect_equal(deparse(mod2$formula), "response_1 ~ exposure_1 + sex")
  expect_equal(length(coef(mod2)), length(coef(mod1)) + 1L)
})

test_that(".lr_remove_term works", {
  mod2 <- lr_model(response_1 ~ exposure_1 + sex, lr_data)
  expect_no_error(.lr_remove_term(mod2, ~sex, quiet = TRUE))
  mod1 <- .lr_remove_term(mod2, ~sex, quiet = TRUE)
  expect_equal(deparse(mod1$formula), "response_1 ~ exposure_1")
  expect_equal(length(coef(mod2)), length(coef(mod1)) + 1L)
})

test_that("lr_scm_history works when no scm called", {
  mod1 <- lr_model(response_1 ~ exposure_1, lr_data)
  expect_no_error(lr_scm_history(mod1))
  hh <- lr_scm_history(mod1)
  expect_s3_class(hh, "data.frame")
  expect_equal(nrow(hh), 1L)
  expect_named(hh, c(
    "iteration", "attempt", "step", "action", "term_tested", "model_tested",
    "model_converged", "term_p_value", "model_aic", "model_bic", "model_updated"
  ))
  expect_equal(hh$iteration, 0L)
})

test_that(".lr_once_forward works", {
  mod1 <- lr_model(response_1 ~ exposure_1, lr_data)
  expect_no_error(.lr_once_forward(mod1, candidates = c("sex", "dose"), threshold = .01))
  mod2 <- .lr_once_forward(mod1, candidates = c("sex", "dose"), threshold = .01)
  hh1 <- lr_scm_history(mod1)
  hh2 <- lr_scm_history(mod2)
  expect_equal(nrow(hh1) + 2L, nrow(hh2))
})

test_that(".lr_once_backward works", {
  mod1 <- lr_model(response_1 ~ exposure_1 + sex + dose, lr_data)
  expect_no_error(.lr_once_backward(mod1, candidates = c("sex", "dose"), threshold = .001))
  mod2 <- .lr_once_backward(mod1, candidates = c("sex", "dose"), threshold = .001)
  hh1 <- lr_scm_history(mod1)
  hh2 <- lr_scm_history(mod2)
  expect_equal(nrow(hh1) + 2L, nrow(hh2))
})

test_that("lr_scm_forward works", {
  mod1 <- lr_model(response_1 ~ exposure_1, lr_data)
  expect_no_error(lr_scm_forward(mod1, candidates = c("sex", "dose"), threshold = .01))
  mod2 <- lr_scm_forward(mod1, candidates = c("sex", "dose"), threshold = .01)
  hh1 <- lr_scm_history(mod1)
  hh2 <- lr_scm_history(mod2)
  expect_equal(nrow(hh1) + 2L, nrow(hh2)) 
  expect_equal(max(hh2$iteration), 1L)
})

test_that("lr_scm_backward works", {
  mod1 <- lr_model(response_1 ~ exposure_1 + sex + dose, lr_data)
  expect_no_error(lr_scm_backward(mod1, candidates = c("sex", "dose"), threshold = .001))
  mod2 <- lr_scm_backward(mod1, candidates = c("sex", "dose"), threshold = .001)
  hh1 <- lr_scm_history(mod1)
  hh2 <- lr_scm_history(mod2)
  expect_equal(nrow(hh1) + 3L, nrow(hh2))
  expect_equal(max(hh2$iteration), 2L)
})


