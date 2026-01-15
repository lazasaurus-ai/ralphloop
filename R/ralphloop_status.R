ralphloop_status <- function(path = NULL) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  if (!file.exists(state_path)) {
    message("ℹ️  No active ralphloop state found.")
    return(invisible(NULL))
  }
  
  lines <- readLines(state_path, warn = FALSE)
  idx <- which(lines == "---")
  
  if (length(idx) < 2) {
    stop("Invalid ralphloop state file: missing YAML frontmatter.")
  }
  
  meta <- yaml::yaml.load(
    paste(lines[(idx[1] + 1):(idx[2] - 1)], collapse = "\n")
  )
  
  prompt <- paste(lines[(idx[2] + 1):length(lines)], collapse = "\n")
  
  # Resolve paths safely
  output_dir <- meta$output_dir %||% getwd()
  work_dir <- meta$work_dir %||% file.path(output_dir, "work")
  
  
  # Pretty status output
  cat("\n🔍 ralphloop status\n")
  cat("────────────────────────────────────────\n")
  cat(sprintf("Active:              %s\n", meta$active))
  cat(sprintf("Iteration:           %s\n", meta$iteration))
  cat(sprintf(
    "Max iterations:      %s\n",
    ifelse(meta$max_iterations > 0, meta$max_iterations, "unlimited")
  ))
  cat(sprintf(
    "Completion promise:  %s\n",
    meta$completion_promise %||% "none"
  ))
  cat(sprintf("Started at (UTC):    %s\n", meta$started_at))
  cat(sprintf("Output base dir:     %s\n", output_dir))
  cat(sprintf("Work directory:      %s\n", work_dir))
  cat("────────────────────────────────────────\n")
  
  cat("\n📌 Task prompt\n")
  cat("────────────────────────────────────────\n")
  cat(trimws(prompt), "\n")
  cat("────────────────────────────────────────\n\n")
  
  invisible(
    list(
      meta = meta,
      prompt = prompt,
      output_dir = output_dir,
      work_dir = work_dir,
      path = state_path
    )
  )
}
