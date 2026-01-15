# ------------------------------------------------------------
# Plan parsing and step management for ralphloop
# ------------------------------------------------------------

#' Generate a structured plan using the LLM
#'
#' Prompts the LLM to create a step-by-step plan in markdown checkbox format.
#'
#' @param chat_client An ellmer chat client
#' @param prompt The task prompt to create a plan for
#' @return The generated plan text
#' @keywords internal
generate_structured_plan <- function(chat_client, prompt) {
  plan_prompt <- glue::glue("
Create a step-by-step plan for the following task.

IMPORTANT: Use this EXACT format with markdown checkboxes:

# Plan

- [ ] Step 1: [First action]
- [ ] Step 2: [Second action]
- [ ] Step 3: [Third action]
...

Rules:
- Each step should be a single, concrete action
- Steps should be in logical execution order
- Use 5-10 steps for most tasks
- Do not include sub-steps or nested items

Task:
{prompt}
")
  
  run_llm(chat_client, plan_prompt)
}

#' Parse a plan.md file
#'
#' Reads a plan file and extracts steps with their completion status.
#'
#' @param plan_path Path to the plan.md file
#' @return A list of step objects, each with: index, complete, text, raw
#' @export
parse_plan <- function(plan_path) {
  if (!file.exists(plan_path)) {
    return(list())
  }
  
  lines <- readLines(plan_path, warn = FALSE)
  step_pattern <- "^- \\[([ xX])\\] (.+)$"
  
  step_lines <- grep(step_pattern, lines, value = TRUE)
  
  lapply(seq_along(step_lines), function(i) {
    line <- step_lines[i]
    m <- regmatches(line, regexec(step_pattern, line))[[1]]
    list(
      index = i,
      complete = tolower(m[2]) == "x",
      text = trimws(m[3]),
      raw = line
    )
  })
}

#' Get the next incomplete step from a plan
#'
#' @param plan_path Path to the plan.md file
#' @return The first incomplete step, or NULL if all complete
#' @export
get_next_step <- function(plan_path) {
  steps <- parse_plan(plan_path)
  incomplete <- Filter(function(s) !s$complete, steps)
  
  if (length(incomplete) == 0) {
    return(NULL)
  }
  
  incomplete[[1]]
}

#' Mark a step as complete in plan.md
#'
#' Updates the plan file to mark a specific step as complete.
#'
#' @param plan_path Path to the plan.md file
#' @param step_text The exact text of the step to mark complete
#' @return NULL (invisibly)
#' @export
mark_step_complete <- function(plan_path, step_text) {
  if (!file.exists(plan_path)) {
    warning("Plan file not found: ", plan_path)
    return(invisible(NULL))
  }
  
  lines <- readLines(plan_path, warn = FALSE)
  
  # Escape special regex characters in step_text
  escaped_text <- gsub("([.^$*+?{}\\[\\]\\\\|()])", "\\\\\\1", step_text)
  pattern <- sprintf("^- \\[ \\] %s$", escaped_text)
  
  for (i in seq_along(lines)) {
    if (grepl(pattern, lines[i])) {
      lines[i] <- sprintf("- [x] %s", step_text)
      break
    }
  }
  
  writeLines(lines, plan_path)
  invisible(NULL)
}

#' Check if all steps in a plan are complete
#'
#' @param plan_path Path to the plan.md file
#' @return TRUE if all steps are complete, FALSE otherwise
#' @export
all_steps_complete <- function(plan_path) {
  steps <- parse_plan(plan_path)
  
  if (length(steps) == 0) {
    return(FALSE)
  }
  
  # Use vapply for type safety
  all(vapply(steps, function(s) isTRUE(s$complete), logical(1)))
}

#' Get a summary of plan progress
#'
#' @param plan_path Path to the plan.md file
#' @return A formatted string showing progress
#' @export
get_plan_summary <- function(plan_path) {
  steps <- parse_plan(plan_path)
  
  if (length(steps) == 0) {
    return("Plan progress: 0/0 steps complete")
  }
  
  # Use vapply for type safety
  completed <- sum(vapply(steps, function(s) isTRUE(s$complete), logical(1)))
  total <- length(steps)
  
  sprintf("Plan progress: %d/%d steps complete", completed, total)
}

#' Inject step-scoped prompt with tool instructions
#'
#' Creates a prompt that focuses the LLM on a single step and
#' instructs it to use the available tools.
#'
#' @param base_prompt The original task prompt
#' @param step The current step object
#' @param plan_content The full plan.md content
#' @return The modified prompt
#' @keywords internal
inject_step_prompt_with_tools <- function(base_prompt, step, plan_content) {
  glue::glue("
## Original Task

{base_prompt}

## Current Plan Status

{plan_content}

## Your Assignment This Iteration

Complete ONLY this step: **{step$text}**

## Available Tools

You have access to these tools:
- `mark_step_complete(step_text)` - Mark a step as done when you finish it
- `get_plan_status()` - Check current plan progress
- `add_plan_step(step_text, after_step)` - Add a new step if needed
- `write_file(filename, content)` - Create/update files in the work directory
- `read_file(filename)` - Read existing files
- `list_files()` - See what files exist

## Instructions

1. Focus exclusively on completing: **{step$text}**
2. Use `write_file()` to create any code or documentation
3. When this step is fully complete, call `mark_step_complete('{step$text}')`
4. Do NOT proceed to subsequent steps
5. Do NOT skip ahead
")
}

#' Detect if a step was marked complete (fallback for tag-based detection)
#'
#' @param output The LLM output text
#' @param step_text The step text to look for
#' @return TRUE if the step_complete tag was found
#' @keywords internal
detect_step_complete <- function(output, step_text) {
  token <- sprintf("<step_complete>%s</step_complete>", step_text)
  grepl(token, output, fixed = TRUE)
}
