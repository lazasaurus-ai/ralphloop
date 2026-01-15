# ------------------------------------------------------------
# Final output promotion for ralphloop
# ------------------------------------------------------------

#' Promote final iteration to final.md
#'
#' Copies the last iteration output to final.md with an appropriate
#' header indicating how the loop completed.
#'
#' @param work_dir Path to the work directory
#' @param iteration The iteration number to promote
#' @param reason The reason for completion: "promise", "plan_complete",
#'   "max_iterations", or "cancelled"
#' @return The path to final.md (invisibly), or NULL if promotion failed
#' @export
promote_final <- function(work_dir, iteration, reason = "promise") {
  if (iteration < 1) {
    message("\u26a0\ufe0f  No iterations to promote")
    return(invisible(NULL))
  }
  
  last_file <- file.path(work_dir, sprintf("iteration-%s.md", iteration))
  
  if (!file.exists(last_file)) {
    message(sprintf("\u26a0\ufe0f  Iteration file not found: %s", last_file))
    return(invisible(NULL))
  }
  
  final_file <- file.path(work_dir, "final.md")
  
  header <- switch(reason,
    "promise" = "# Final Output\n\n> \u2705 Completion promise satisfied\n\n---\n\n",
    "plan_complete" = "# Final Output\n\n> \u2705 All plan steps completed\n\n---\n\n",
    "max_iterations" = "# Final Output\n\n> \u26a0\ufe0f Max iterations reached (may be incomplete)\n\n---\n\n",
    "cancelled" = "# Final Output\n\n> \U0001F6D1 Loop cancelled by user\n\n---\n\n",
    "# Final Output\n\n---\n\n"
  )
  
  content <- readLines(last_file, warn = FALSE)
  writeLines(c(header, content), final_file)
  
  message(sprintf("\U0001F4C4 Promoted iteration %s to final.md (%s)", iteration, reason))
  
  invisible(final_file)
}
