ralph_loop <- function(
    chat_client,
    context = "Continue improving the existing work. Do not restate the task."
) {
  stopifnot(
    inherits(chat_client, "Chat"),
    inherits(chat_client, "R6")
  )
  
  repeat {
    state <- read_ralphloop_state()
    meta <- state$meta
    if (!isTRUE(meta$active)) {
      message("Ralph loop inactive. Exiting.")
      break
    }
    
    message(glue::glue("🔄 Iteration {meta$iteration}"))
    
    output <- run_llm(
      chat_client = chat_client,
      prompt = state$prompt,
      context = context
    )
    
    writeLines(
      output,
      file.path(
        meta$work_dir,
        glue::glue("iteration-{meta$iteration}.md")
      )
    )
    
    
    if (promise_met(output, meta$completion_promise)) {
      message("✅ Completion promise satisfied")
      meta$active <- FALSE
      state$meta <- meta
      write_ralphloop_state(state)
      break
    }
    
    if (meta$max_iterations > 0 &&
        meta$iteration >= meta$max_iterations) {
      message("🛑 Max iterations reached")
      meta$active <- FALSE
      state$meta <- meta
      write_ralphloop_state(state)
      break
    }
    
    meta$iteration <- meta$iteration + 1
    state$meta <- meta
    write_ralphloop_state(state)
  }
}
