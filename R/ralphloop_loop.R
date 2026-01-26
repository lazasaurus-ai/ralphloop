# ------------------------------------------------------------
# Inject completion promise instructions into the prompt
# ------------------------------------------------------------
inject_completion_promise <- function(prompt, promise) {
  if (is.null(promise) || identical(promise, "null")) {
    return(prompt)
  }
  
  paste(
    prompt,
    "",
    "IMPORTANT:",
    "When the task is fully complete and the statement below is TRUE,",
    "output the following EXACTLY (including tags):",
    "",
    paste0("<promise>", promise, "</promise>"),
    "",
    "Do NOT output this unless the statement is completely true.",
    sep = "\n"
  )
}

# ------------------------------------------------------------
# Main Ralph loop (Tool-Based)
# ------------------------------------------------------------
#' Run the Ralph loop
#'
#' Executes the iterative development loop, optionally with plan-aware
#' step enforcement and tool support. Automatically handles API errors
#' (including rate limiting) with exponential backoff retry logic
#' (5 attempts per step with 30, 60, 120, 240, and 480 second delays).
#'
#' @param chat_client An ellmer chat client
#' @param path Path to the state file (defaults to .ralphloop/ralphloop.local.md)
#' @param register_tools If TRUE (default), register ralphloop tools with the chat client
#' @return NULL (invisibly)
#' @export
ralph_loop <- function(chat_client, path = NULL, register_tools = TRUE) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  state <- read_ralphloop_state(state_path)
  meta <- state$meta
  prompt <- state$prompt
  work_dir <- meta$work_dir
  plan_path <- file.path(work_dir, "plan.md")
  iterations_dir <- file.path(work_dir, "iterations")
  
  # Create iterations subdirectory
  dir.create(iterations_dir, showWarnings = FALSE, recursive = TRUE)
  
  # Track completion reason for final promotion
  completion_reason <- NULL
  
  # ---- Optional planning step (runs ONCE on iteration 1) ----
  # NOTE: This must happen BEFORE registering tools, otherwise the LLM
  # will use write_file tool instead of returning the plan text
  if (isTRUE(meta$plan) && meta$iteration == 1 && !file.exists(plan_path)) {
    message("\U0001F9ED Generating structured plan.md")
    
    plan_text <- generate_structured_plan(chat_client, prompt)
    writeLines(plan_text, plan_path)
    
    message("\U0001F4CB Plan created:")
    cat(plan_text, "\n")
  }
  
  # ---- Register tools with the chat client (if plan mode) ----
  # NOTE: Tools are registered AFTER plan generation to avoid the LLM
  # using write_file during plan creation
  if (isTRUE(meta$plan) && isTRUE(register_tools)) {
    message("\U0001F4E6 Registering ralphloop tools with chat client...")
    register_ralphloop_tools(chat_client, work_dir)
  }
  
  # ---- Main iteration loop ----
  # Track the last iteration that actually produced output
  last_completed_iteration <- meta$iteration - 1
  
  repeat {
    if (!isTRUE(meta$active)) break
    
    current_step <- NULL
    
    # ---- Plan-aware mode with tools ----
    if (isTRUE(meta$plan) && isTRUE(meta$step_enforcement) && file.exists(plan_path)) {
      
      # Re-read plan to check current state (LLM may have updated it via tools)
      if (all_steps_complete(plan_path)) {
        message("\u2705 All plan steps complete")
        
        if (isTRUE(meta$enforce_promise)) {
          # Continue to wait for completion promise
          message("\u23f3 Waiting for completion promise...")
          effective_prompt <- inject_completion_promise(prompt, meta$completion_promise)
        } else {
          # Stop the loop - plan is done
          # Use last_completed_iteration since we haven't run this iteration yet
          completion_reason <- "plan_complete"
          meta$active <- FALSE
          write_ralphloop_state(list(meta = meta, prompt = prompt))
          break
        }
      } else {
        # Get next step and create step-scoped prompt WITH tool instructions
        current_step <- get_next_step(plan_path)
        plan_content <- paste(readLines(plan_path, warn = FALSE), collapse = "\n")
        
        message(sprintf("\U0001F504 Iteration %s \u2014 Working on: %s", meta$iteration, current_step$text))
        message(get_plan_summary(plan_path))
        
        # Use tool-aware prompt injection
        effective_prompt <- inject_step_prompt_with_tools(prompt, current_step, plan_content)
        
        # Also inject completion promise if we're on the last step and enforce_promise is TRUE
        if (isTRUE(meta$enforce_promise)) {
          remaining_steps <- Filter(function(s) !s$complete, parse_plan(plan_path))
          if (length(remaining_steps) == 1) {
            effective_prompt <- paste(
              effective_prompt,
              "",
              "NOTE: This is the FINAL step. When complete, also output:",
              sprintf("<promise>%s</promise>", meta$completion_promise),
              sep = "\n"
            )
          }
        }
      }
    } else {
      # ---- Free-form mode (original behavior) ----
      message(sprintf("\U0001F504 Iteration %s", meta$iteration))
      effective_prompt <- inject_completion_promise(prompt, meta$completion_promise)
    }
    
    # ---- Run LLM (with tool support) ----
    # The chat client will automatically handle tool calls
    output <- run_llm(chat_client, effective_prompt)
    
    # ---- Write iteration file to iterations/ subdirectory ----
    out_file <- file.path(iterations_dir, sprintf("iteration-%s.md", meta$iteration))
    writeLines(output, out_file)
    
    # Track this as the last completed iteration
    last_completed_iteration <- meta$iteration
    
    # ---- Check for step completion (re-read plan.md) ----
    # With tools, the LLM updates plan.md directly via mark_step_complete tool
    # We just need to verify the plan was updated
    if (!is.null(current_step) && file.exists(plan_path)) {
      # Re-read the plan to see if the step was marked complete
      updated_steps <- parse_plan(plan_path)
      
      if (length(updated_steps) > 0) {
        step_now_complete <- any(vapply(updated_steps, function(s) {
          isTRUE(s$text == current_step$text && s$complete)
        }, logical(1)))
        
        if (step_now_complete) {
          message(sprintf("\u2713 Step complete: %s", current_step$text))
        } else {
          message("\u26a0\ufe0f  Step not marked complete \u2014 LLM may not have called mark_step_complete tool")
        }
      }
    }
    
    # ---- Enforce completion promise (optional semantic stop) ----
    if (isTRUE(meta$enforce_promise) &&
        detect_completion_promise(output, meta$completion_promise)) {
      
      message("\U0001F6D1 Completion promise detected \u2014 stopping loop")
      completion_reason <- "promise"
      meta$active <- FALSE
      write_ralphloop_state(list(meta = meta, prompt = prompt))
      break
    }
    
    # ---- Max iteration guard ----
    if (meta$max_iterations > 0 &&
        meta$iteration >= meta$max_iterations) {
      
      message("\U0001F6D1 Max iterations reached")
      completion_reason <- "max_iterations"
      meta$active <- FALSE
      write_ralphloop_state(list(meta = meta, prompt = prompt))
      break
    }
    
    # ---- Increment iteration and persist state ----
    meta$iteration <- meta$iteration + 1
    write_ralphloop_state(list(meta = meta, prompt = prompt))
  }
  
  # ---- Promote final output ----
  # Use last_completed_iteration to ensure we promote the actual last iteration
  # (not meta$iteration which may have been incremented or point to a non-existent iteration)
  if (!is.null(completion_reason) && last_completed_iteration >= 1) {
    promote_final(work_dir, last_completed_iteration, completion_reason)
  }
  
  invisible(NULL)
}
