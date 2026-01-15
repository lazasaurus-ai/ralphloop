# ------------------------------------------------------------
# ellmer tool definitions for ralphloop
# ------------------------------------------------------------

#' Create ralphloop tools for ellmer chat client
#'
#' Factory function that creates tools scoped to the current work directory.
#' These tools allow the LLM to interact with the plan and file system.
#'
#' @param work_dir Path to the work directory containing plan.md
#' @return A list of ellmer tool definitions
#' @export
create_ralphloop_tools <- function(work_dir) {
  plan_path <- file.path(work_dir, "plan.md")
  
  list(
    # Tool to mark a step as complete
    tool_mark_step_complete = ellmer::tool(
      fun = function(step_text) {
        mark_step_complete(plan_path, step_text)
        steps <- parse_plan(plan_path)
        completed <- sum(vapply(steps, function(s) isTRUE(s$complete), logical(1)))
        total <- length(steps)
        sprintf("\u2713 Marked complete: %s\nProgress: %d/%d steps", step_text, completed, total)
      },
      name = "mark_step_complete",
      description = "Mark a plan step as complete. Call this when you have finished a step. The step_text must match exactly.",
      arguments = list(
        step_text = ellmer::type_string("The exact text of the step to mark complete, e.g. 'Step 1: Create HTML structure'")
      )
    ),
    
    # Tool to read the current plan status
    tool_get_plan_status = ellmer::tool(
      fun = function() {
        if (!file.exists(plan_path)) {
          return("No plan.md found")
        }
        paste(readLines(plan_path, warn = FALSE), collapse = "\n")
      },
      name = "get_plan_status",
      description = "Read the current plan.md to see which steps are complete and which are pending.",
      arguments = list()
    ),
    
    # Tool to add a new step to the plan
    tool_add_plan_step = ellmer::tool(
      fun = function(step_text, after_step = NULL) {
        if (!file.exists(plan_path)) {
          return("Error: No plan.md found")
        }
        
        lines <- readLines(plan_path, warn = FALSE)
        new_line <- sprintf("- [ ] %s", step_text)
        
        if (is.null(after_step)) {
          # Add at the end
          lines <- c(lines, new_line)
        } else {
          # Find the step to insert after
          idx <- grep(after_step, lines, fixed = TRUE)
          if (length(idx) > 0) {
            insert_pos <- idx[1]
            lines <- c(lines[1:insert_pos], new_line, lines[(insert_pos + 1):length(lines)])
          } else {
            lines <- c(lines, new_line)
          }
        }
        
        writeLines(lines, plan_path)
        sprintf("Added step: %s", step_text)
      },
      name = "add_plan_step",
      description = "Add a new step to the plan. Use this if you discover additional work is needed.",
      arguments = list(
        step_text = ellmer::type_string("The text of the new step to add"),
        after_step = ellmer::type_string("Optional: Insert after this step text. If NULL, adds at end.")
      )
    ),
    
    # Tool to write/update a file in the work directory
    tool_write_file = ellmer::tool(
      fun = function(filename, content) {
        file_path <- file.path(work_dir, filename)
        # Create subdirectories if needed
        dir.create(dirname(file_path), showWarnings = FALSE, recursive = TRUE)
        writeLines(content, file_path)
        sprintf("Wrote %d characters to %s", nchar(content), filename)
      },
      name = "write_file",
      description = "Write content to a file in the work directory. Use this to create code files, documentation, etc.",
      arguments = list(
        filename = ellmer::type_string("Name of the file to write (will be created in work directory)"),
        content = ellmer::type_string("The content to write to the file")
      )
    ),
    
    # Tool to read a file from the work directory
    tool_read_file = ellmer::tool(
      fun = function(filename) {
        file_path <- file.path(work_dir, filename)
        if (!file.exists(file_path)) {
          return(sprintf("Error: File not found: %s", filename))
        }
        paste(readLines(file_path, warn = FALSE), collapse = "\n")
      },
      name = "read_file",
      description = "Read the contents of a file in the work directory.",
      arguments = list(
        filename = ellmer::type_string("Name of the file to read")
      )
    ),
    
    # Tool to list files in the work directory
    tool_list_files = ellmer::tool(
      fun = function() {
        files <- list.files(work_dir, recursive = TRUE)
        if (length(files) == 0) {
          return("No files in work directory")
        }
        paste(files, collapse = "\n")
      },
      name = "list_files",
      description = "List all files in the work directory.",
      arguments = list()
    )
  )
}

#' Register ralphloop tools with an ellmer chat client
#'
#' Registers all ralphloop tools with the provided chat client,
#' allowing the LLM to update the plan and manage files.
#'
#' @param chat_client An ellmer chat client
#' @param work_dir Path to the work directory
#' @return The chat client (invisibly), with tools registered
#' @export
register_ralphloop_tools <- function(chat_client, work_dir) {
  tools <- create_ralphloop_tools(work_dir)
  
  for (tool in tools) {
    chat_client$register_tool(tool)
  }
  
  message(sprintf("\U0001F4E6 Registered %d ralphloop tools", length(tools)))
  invisible(chat_client)
}
