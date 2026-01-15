init_ralphloop <- function(
    prompt,
    max_iterations = 0,
    completion_promise = NULL,
    enforce_promise = FALSE,
    plan = FALSE,
    output_dir = NULL
) {
  if (enforce_promise && is.null(completion_promise)) {
    stop("enforce_promise = TRUE requires a completion_promise.")
  }
  
  base_output_dir <- output_dir %||% getwd()
  work_dir <- file.path(base_output_dir, "work")
  
  dir.create(".ralphloop", showWarnings = FALSE, recursive = TRUE)
  dir.create(work_dir, showWarnings = FALSE, recursive = TRUE)
  
  state <- list(
    meta = list(
      active = TRUE,
      iteration = 1,
      max_iterations = max_iterations,
      completion_promise = completion_promise %||% "null",
      enforce_promise = enforce_promise,
      plan = plan,
      started_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      output_dir = normalizePath(base_output_dir, winslash = "/", mustWork = FALSE),
      work_dir = normalizePath(work_dir, winslash = "/", mustWork = FALSE)
    ),
    prompt = prompt
  )
  
  write_ralphloop_state(state)
  
  invisible(state)
}
