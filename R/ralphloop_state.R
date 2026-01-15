ralphloop_state_path <- function() {
  ".ralphloop/ralphloop.local.md"
}

read_ralphloop_state <- function() {
  lines <- readLines(ralphloop_state_path(), warn = FALSE)
  idx <- which(lines == "---")
  
  meta <- yaml::yaml.load(
    paste(lines[(idx[1] + 1):(idx[2] - 1)], collapse = "\n")
  )
  
  prompt <- paste(lines[(idx[2] + 1):length(lines)], collapse = "\n")
  
  list(meta = meta, prompt = prompt)
}

write_ralphloop_state <- function(state) {
  dir.create(".ralphloop", showWarnings = FALSE)
  
  yaml_block <- yaml::as.yaml(state$meta)
  
  writeLines(
    c(
      "---",
      yaml_block,
      "---",
      "",
      state$prompt
    ),
    ralphloop_state_path()
  )
}
