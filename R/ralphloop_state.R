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
}

read_ralphloop_state <- function(path = ".ralphloop/ralphloop.local.md") {
  if (!file.exists(path)) {
    stop("No ralphloop state file found.")
  }
  
  lines <- readLines(path, warn = FALSE)
  idx <- which(lines == "---")
  
  meta <- yaml::yaml.load(
    paste(lines[(idx[1] + 1):(idx[2] - 1)], collapse = "\n")
  )
  
  prompt <- paste(lines[(idx[2] + 1):length(lines)], collapse = "\n")
  
  list(meta = meta, prompt = prompt)
}
