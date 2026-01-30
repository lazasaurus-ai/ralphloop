test_that("state write/read round-trips", {
  state_path <- tempfile(fileext = ".md")

  state <- list(
    meta = list(active = TRUE, iteration = 1, work_dir = "work"),
    prompt = "hello"
  )

  ralphloop:::write_ralphloop_state(state, path = state_path)
  read_back <- ralphloop:::read_ralphloop_state(state_path)

  expect_true(isTRUE(read_back$meta$active))
  expect_equal(read_back$meta$iteration, 1)
  expect_equal(read_back$prompt, "hello")
})

test_that("completion promise detection works", {
  expect_false(ralphloop:::detect_completion_promise("hi", NULL))
  expect_false(ralphloop:::detect_completion_promise("hi", "null"))
  expect_true(ralphloop:::detect_completion_promise("<promise>OK</promise>", "OK"))
  expect_false(ralphloop:::detect_completion_promise("<promise>OK</promise>", "NO"))
})

