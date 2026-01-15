#' Display ralphloop status
#'
#' Shows the current state of the ralphloop session, including
#' iteration count, plan progress, and task prompt.
#'
#' @param path Path to the state file (defaults to .ralphloop/ralphloop.local.md)
#' @return A list containing the state information (invisibly)
#' @export
ralphloop_status <- function(path = NULL) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  if (!file.exists(state_path)) {
    message("\u2139\ufe0f  No active ralphloop state found.")
    return(invisible(NULL))
  }
  
  state <- read_ralphloop_state(state_path)
  meta <- state$meta
  prompt <- state$prompt
  work_dir <- meta$work_dir
  plan_path <- file.path(work_dir, "plan.md")
  
  cat("\n\U0001F50D ralphloop status\n")
  cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
  cat(sprintf("Active:              %s\n", meta$active))
  cat(sprintf("Iteration:           %s\n", meta$iteration))
  cat(sprintf(
    "Max iterations:      %s\n",
    ifelse(meta$max_iterations > 0, meta$max_iterations, "unlimited")
  ))
  cat(sprintf("Completion promise:  %s\n", meta$completion_promise))
  cat(sprintf("Enforce promise:     %s\n", meta$enforce_promise))
  cat(sprintf("Plan enabled:        %s\n", meta$plan))
  cat(sprintf("Step enforcement:    %s\n", meta$step_enforcement %||% "N/A"))
  cat(sprintf("Started at (UTC):    %s\n", meta$started_at))
  cat(sprintf("Output base dir:     %s\n", meta$output_dir))
  cat(sprintf("Work directory:      %s\n", meta$work_dir))
  cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
  
  # Show plan progress if plan exists
  if (file.exists(plan_path)) {
    cat("\n\U0001F4CB Plan progress\n")
    cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
    steps <- parse_plan(plan_path)
    for (step in steps) {
      status <- if (step$complete) "\u2713" else "\u25cb"
      cat(sprintf("  %s %s\n", status, step$text))
    }
    completed <- sum(sapply(steps, function(s) s$complete))
    cat(sprintf("\n  Progress: %d/%d steps\n", completed, length(steps)))
    cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
  }
  
  cat("\n\U0001F4CC Task prompt\n")
  cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n")
  cat(trimws(prompt), "\n")
  cat("\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\u2500\n\n")
  
  invisible(
    list(
      meta = meta,
      prompt = prompt,
      output_dir = meta$output_dir,
      work_dir = meta$work_dir,
      path = state_path
    )
  )
}

#' Cancel the active ralphloop
#'
#' Marks the current ralphloop session as inactive.
#'
#' @param path Path to the state file (defaults to .ralphloop/ralphloop.local.md)
#' @return NULL (invisibly)
#' @export
cancel_ralphloop <- function(path = NULL) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  if (!file.exists(state_path)) {
    message("\u2139\ufe0f  No active ralphloop state found.")
    return(invisible(NULL))
  }
  
  state <- read_ralphloop_state(state_path)
  state$meta$active <- FALSE
  write_ralphloop_state(state, state_path)
  
  # Promote final output if there were any iterations
  if (state$meta$iteration > 0) {
    promote_final(state$meta$work_dir, state$meta$iteration, "cancelled")
  }
  
  message("\U0001F6D1 Ralph loop cancelled")
  invisible(NULL)
}
