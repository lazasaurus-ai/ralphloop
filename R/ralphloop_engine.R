run_llm <- function(chat_client, prompt, context = NULL) {
  message_text <- paste(
    c(context, prompt),
    collapse = "\n\n"
  )
  
  response <- chat_client$chat(message_text)
  
  as.character(response)
}
