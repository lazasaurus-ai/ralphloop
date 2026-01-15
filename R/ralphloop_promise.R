promise_met <- function(output, promise) {
  if (is.null(promise) || promise == "null") {
    return(FALSE)
  }
  
  tag <- paste0("<promise>", promise, "</promise>")
  grepl(tag, output, fixed = TRUE)
}
