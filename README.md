# ralphloop

`ralphloop` provides a persistent, truth-based iterative loop for LLM-driven
development workflows using the `ellmer` R package.

Inspired by the Ralph loop pattern from Anthropic’s Claude Code.

## Example

```r
library(ellmer)
library(ralphloop)

chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

init_ralphloop(
  prompt = "Refactor the ETL pipeline and add tests",
  max_iterations = 10,
  completion_promise = "DONE"
)

ralph_loop(chat_client)

```

The loop continues until the completion promise is truthfully satisfied.





