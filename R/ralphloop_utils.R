# ------------------------------------------------------------
# Utility functions for ralphloop
# ------------------------------------------------------------

#' Null coalescing operator
#'
#' Returns the left-hand side if it is not NULL, otherwise returns
#' the right-hand side.
#'
#' @param x Left-hand side value
#' @param y Right-hand side value (default)
#' @return x if not NULL, otherwise y
#' @keywords internal
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}
