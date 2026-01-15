ralphloop_status <- function(path = NULL) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  if (!file.exists(state_path)) {
    message("ℹ️  No active ralphloop state found.")
    return(invisible(NULL))
  }
  
  state <- read_ralphloop_state(state_path)
  meta <- state$meta
  prompt <- state$prompt
  
  cat("\n🔍 ralphloop status\n")
  cat("────────────────────────────────────────\n")
  cat(sprintf("Active:              %s\n", meta$active))
  cat(sprintf("Iteration:           %s\n", meta$iteration))
  cat(sprintf(
    "Max iterations:      %s\n",
    ifelse(meta$max_iterations > 0, meta$max_iterations, "unlimited")
  ))
  cat(sprintf("Completion promise:  %s\n", meta$completion_promise))
  cat(sprintf("Enforce promise:     %s\n", meta$enforce_promise))
  cat(sprintf("Plan enabled:        %s\n", meta$plan))
  cat(sprintf("Started at (UTC):    %s\n", meta$started_at))
  cat(sprintf("Output base dir:     %s\n", meta$output_dir))
  cat(sprintf("Work directory:      %s\n", meta$work_dir))
  cat("────────────────────────────────────────\n")
  
  cat("\n📌 Task prompt\n")
  cat("────────────────────────────────────────\n")
  cat(trimws(prompt), "\n")
  cat("────────────────────────────────────────\n\n")
  
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
