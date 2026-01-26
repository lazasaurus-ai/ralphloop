# ------------------------------------------------------------
# ralphloop Retry Logic Demo
# ------------------------------------------------------------
# This example demonstrates the automatic retry logic for
# handling HTTP 429 rate limit errors with exponential backoff.

devtools::load_all()
library(ellmer)
library(ralphloop)

# Create a chat client (adjust model as needed)
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# Initialize a simple task
init_ralphloop(
  prompt = "Create a simple hello world function in R",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 5
)

# Run the loop
# If you encounter HTTP 429 errors, the loop will:
# 1. Wait 30 seconds and retry (attempt 1)
# 2. Wait 60 seconds and retry (attempt 2)
# 3. Wait 120 seconds and retry (attempt 3)
# 4. If all retries fail, display error and suggest running ralph_loop(chat_client) again
ralph_loop(chat_client)

# If the loop stops due to rate limiting, simply run it again:
# ralph_loop(chat_client)
# 
# The loop will pick up where it left off because the state is preserved!
