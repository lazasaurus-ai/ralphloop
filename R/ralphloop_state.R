#' Write ralphloop state
#'
#' Persists loop metadata and the user prompt to a simple markdown file with a
#' YAML front-matter block.
#'
#' @param state A list with components `meta` (list) and `prompt` (character)
#' @param path State file path
#' @return NULL (invisibly)
#' @keywords internal
write_ralphloop_state <- function(state, path = ".ralphloop/ralphloop.local.md") {
  meta_yaml <- yaml::as.yaml(state$meta)
  
  content <- c(
    "---",
    trimws(meta_yaml),
    "---",
    "",
    state$prompt
  )
  
  writeLines(content, path)
  invisible(NULL)
}

#' Read ralphloop state
#'
#' @param path State file path
#' @return A list with components `meta` and `prompt`
#' @keywords internal
read_ralphloop_state <- function(path = ".ralphloop/ralphloop.local.md") {
  if (!file.exists(path)) {
    stop("No ralphloop state file found.")
  }
  
  lines <- readLines(path, warn = FALSE)
  idx <- which(lines == "---")
  if (length(idx) < 2) {
    stop("Invalid state file: missing YAML front-matter delimiters ('---').")
  }
  
  meta <- yaml::yaml.load(
    paste(lines[(idx[1] + 1):(idx[2] - 1)], collapse = "\n")
  )
  
  prompt_lines <- lines[(idx[2] + 1):length(lines)]
  # Allow an optional single blank line after the YAML front-matter
  if (length(prompt_lines) > 0 && identical(prompt_lines[[1]], "")) {
    prompt_lines <- prompt_lines[-1]
  }
  prompt <- paste(prompt_lines, collapse = "\n")
  
  list(meta = meta, prompt = prompt)
}
