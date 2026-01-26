run_llm <- function(chat_client, prompt, context = NULL) {
  message_text <- paste(
    c(context, prompt),
    collapse = "\n\n"
  )
  
  response <- run_llm_with_retry(chat_client, message_text)
  
  as.character(response)
}

# ------------------------------------------------------------
# Run LLM with retry logic for rate limiting and transient errors
# ------------------------------------------------------------
run_llm_with_retry <- function(chat_client, message_text, 
                                max_retries = 3, 
                                initial_wait = 30) {
  attempt <- 1
  
  while (attempt <= max_retries) {
    tryCatch({
      # Attempt the API call
      response <- chat_client$chat(message_text)
      return(response)
      
    }, error = function(e) {
      error_msg <- conditionMessage(e)
      
      # Check if this is a rate limit error (common patterns across providers)
      is_rate_limit <- grepl("429|Too Many Requests|Too many tokens|rate limit|throttl", 
                             error_msg, ignore.case = TRUE)
      
      if (attempt < max_retries) {
        # Calculate wait time with exponential backoff
        wait_time <- initial_wait * (2 ^ (attempt - 1))
        
        if (is_rate_limit) {
          message(sprintf(
            "\u26a0\ufe0f  Rate limit detected - Attempt %d/%d failed",
            attempt, max_retries
          ))
        } else {
          message(sprintf(
            "\u26a0\ufe0f  API error - Attempt %d/%d failed",
            attempt, max_retries
          ))
        }
        
        message(sprintf("Error: %s", error_msg))
        message(sprintf(
          "\u23f3 Waiting %d seconds before retry...",
          wait_time
        ))
        
        Sys.sleep(wait_time)
        attempt <<- attempt + 1
        
      } else {
        # Final retry exhausted
        message("\u274c All retry attempts exhausted")
        message("\nFinal error encountered:")
        message(error_msg)
        message("\n\U0001F504 Try running ralph_loop(chat_client) again to continue")
        message("The loop state is preserved and will resume from where it stopped.")
        stop(e)
      }
    })
  }
}
