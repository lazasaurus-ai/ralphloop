#' Detect completion promise token
#'
#' Internal helper used when `enforce_promise = TRUE` to stop the loop once the
#' LLM output contains the exact `<promise>...</promise>` token.
#'
#' @param output The LLM output text
#' @param promise The promise statement string
#' @return TRUE if the promise token is present, otherwise FALSE
#' @keywords internal
detect_completion_promise <- function(output, promise) {
  if (is.null(promise) || identical(promise, "null")) {
    return(FALSE)
  }
  
  token <- paste0("<promise>", promise, "</promise>")
  grepl(token, output, fixed = TRUE)
}
