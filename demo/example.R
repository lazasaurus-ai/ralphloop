devtools::load_all()
library(ellmer)
library(ralphloop)

chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

init_ralphloop(
  prompt = "Write a simple R function and add unit tests",
  max_iterations = 3,
  completion_promise = "DONE"
)

ralphloop_status()
ralph_loop(chat_client)
