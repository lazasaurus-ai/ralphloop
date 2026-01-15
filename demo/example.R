devtools::load_all()
library(ellmer)
library(ralphloop)

# Create a Bedrock-backed ellmer chat client
# You can also register tools in your ellmer client
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)


init_ralphloop(
  prompt = "Refactor calculate_average() and add unit tests",
  plan = TRUE,
  completion_promise = "ALL TESTS PASS",
  enforce_promise = TRUE,
  max_iterations = 10
)


# Run the loop
ralphloop_status()
ralph_loop(chat_client)
