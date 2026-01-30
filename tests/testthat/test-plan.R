test_that("plan parsing and completion utilities work", {
  plan_path <- tempfile(fileext = ".md")
  writeLines(c(
    "# Plan",
    "",
    "- [ ] Step 1: Do thing",
    "- [x] Step 2: Done thing"
  ), plan_path)

  steps <- parse_plan(plan_path)
  expect_length(steps, 2)
  expect_false(steps[[1]]$complete)
  expect_true(steps[[2]]$complete)
  expect_equal(get_next_step(plan_path)$text, "Step 1: Do thing")
  expect_false(all_steps_complete(plan_path))

  mark_step_complete(plan_path, "Step 1: Do thing")
  expect_true(all_steps_complete(plan_path))
  expect_match(get_plan_summary(plan_path), "2/2")
})

