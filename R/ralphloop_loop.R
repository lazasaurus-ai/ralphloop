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
# Main Ralph loop
# ------------------------------------------------------------
ralph_loop <- function(chat_client, path = NULL) {
  state_path <- path %||% ".ralphloop/ralphloop.local.md"
  
  state <- read_ralphloop_state(state_path)
  meta <- state$meta
  prompt <- state$prompt
  work_dir <- meta$work_dir
  
  # ---- Optional planning step (runs ONCE) ----
  if (isTRUE(meta$plan) && meta$iteration == 1) {
    message("🧭 Generating plan.md")
    
    plan_text <- run_llm(
      chat_client,
      paste(
        "Create a concise, actionable plan or checklist for the following task.",
        "Do not write code yet.",
        "",
        "Task:",
        prompt,
        sep = "\n"
      )
    )
    
    writeLines(plan_text, file.path(work_dir, "plan.md"))
  }
  
  # ---- Prepare effective prompt (with optional promise injection) ----
  effective_prompt <- inject_completion_promise(
    prompt,
    meta$completion_promise
  )
  
  # ---- Main iteration loop ----
  repeat {
    if (!isTRUE(meta$active)) break
    
    message(sprintf("🔄 Iteration %s", meta$iteration))
    
    output <- run_llm(chat_client, effective_prompt)
    
    out_file <- file.path(
      work_dir,
      sprintf("iteration-%s.md", meta$iteration)
    )
    
    writeLines(output, out_file)
    
    # ---- Enforce completion promise (optional semantic stop) ----
    if (isTRUE(meta$enforce_promise) &&
        detect_completion_promise(output, meta$completion_promise)) {
      
      message("🛑 Completion promise detected — stopping loop")
      meta$active <- FALSE
      write_ralphloop_state(list(meta = meta, prompt = prompt))
      break
    }
    
    # ---- Max iteration guard ----
    if (meta$max_iterations > 0 &&
        meta$iteration >= meta$max_iterations) {
      
      message("🛑 Max iterations reached")
      meta$active <- FALSE
      write_ralphloop_state(list(meta = meta, prompt = prompt))
      break
    }
    
    # ---- Increment iteration and persist state ----
    meta$iteration <- meta$iteration + 1
    write_ralphloop_state(list(meta = meta, prompt = prompt))
  }
  
  invisible(NULL)
}
