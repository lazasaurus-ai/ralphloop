detect_completion_promise <- function(output, promise) {
  if (is.null(promise) || identical(promise, "null")) {
    return(FALSE)
  }
  
  token <- paste0("<promise>", promise, "</promise>")
  grepl(token, output, fixed = TRUE)
}
