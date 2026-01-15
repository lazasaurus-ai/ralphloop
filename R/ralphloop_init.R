#' Initialize a ralphloop session
#'
#' Sets up the state file and work directory for a new ralphloop session.
#'
#' @param prompt The task prompt for the LLM to work on
#' @param max_iterations Maximum number of iterations (0 = unlimited)
#' @param completion_promise A string that signals task completion when output by the LLM
#' @param enforce_promise If TRUE, stop the loop when the completion promise is detected
#' @param plan If TRUE, generate a structured plan before iteration
#' @param step_enforcement If TRUE (and plan = TRUE), enforce step-by-step iteration
#' @param output_dir Base directory for output files (defaults to current working directory)
#' @return The initial state (invisibly)
#' @export
init_ralphloop <- function(
    prompt,
    max_iterations = 0,
    completion_promise = NULL,
    enforce_promise = FALSE,
    plan = FALSE,
    step_enforcement = TRUE,
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
      step_enforcement = step_enforcement,
      started_at = format(Sys.time(), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
      output_dir = normalizePath(base_output_dir, winslash = "/", mustWork = FALSE),
      work_dir = normalizePath(work_dir, winslash = "/", mustWork = FALSE)
    ),
    prompt = prompt
  )
  
  write_ralphloop_state(state)
  
  invisible(state)
}
