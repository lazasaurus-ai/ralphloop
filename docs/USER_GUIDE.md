# ralphloop User Guide

Complete guide to using the `ralphloop` package for LLM-driven iterative development in R.

## Table of Contents

1. [Installation](#installation)
2. [Quick Start](#quick-start)
3. [Directory Structure](#directory-structure)
4. [Core Functions](#core-functions)
5. [Common Workflows](#common-workflows)
6. [Advanced Usage](#advanced-usage)
7. [Troubleshooting](#troubleshooting)

---

## Installation

```r
# Install from GitHub (when available)
# devtools::install_github("your-username/ralphloop")

# For now, load from source
devtools::load_all()
library(ralphloop)
```

### Prerequisites

```r
# Install required packages
install.packages("ellmer")
install.packages("glue")
```

---

## Quick Start

### Basic Example

```r
library(ellmer)
library(ralphloop)

# 1. Create a chat client (choose your provider)
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# 2. Initialize a ralphloop session
init_ralphloop(
  prompt = "Create a simple R function to calculate fibonacci numbers",
  max_iterations = 5
)

# 3. Check status
ralphloop_status()

# 4. Run the loop
ralph_loop(chat_client)
```

That's it! The LLM will work on your task iteratively, with all progress saved to the `work/` directory.

---

## Directory Structure

### Default Structure

By default, ralphloop creates the following directory structure in your current working directory:

```
your-project/
├── .ralphloop/
│   └── ralphloop.local.md    # Internal state file (tracks progress)
└── work/
    ├── plan.md               # Generated plan (if plan = TRUE)
    ├── final.md              # Final output (promoted on completion)
    ├── iterations/           # All iteration logs
    │   ├── iteration-1.md
    │   ├── iteration-2.md
    │   └── ...
    └── [generated files]     # Any files created by LLM via write_file tool
```

### Custom Directory Structure

You can specify a custom base directory using the `output_dir` parameter:

```r
# Example 1: Use a specific project directory
init_ralphloop(
  prompt = "Build a web scraper",
  output_dir = "~/projects/web-scraper"
)

# This creates:
# ~/projects/web-scraper/
# ├── .ralphloop/
# │   └── ralphloop.local.md
# └── work/
#     ├── plan.md
#     └── iterations/
```

```r
# Example 2: Use an absolute Windows path
init_ralphloop(
  prompt = "Create data analysis scripts",
  output_dir = "C:/Users/username/Documents/data-project"
)

# This creates:
# C:/Users/username/Documents/data-project/
# ├── .ralphloop/
# └── work/
```

```r
# Example 3: Use a relative path
init_ralphloop(
  prompt = "Generate reports",
  output_dir = "./reports-project"
)

# This creates:
# ./reports-project/
# ├── .ralphloop/
# └── work/
```

### Important Notes

- **Base directory**: The `output_dir` parameter sets the base directory
- **Work directory**: The actual work directory is always `{output_dir}/work/`
- **State file**: The state file is always at `{output_dir}/.ralphloop/ralphloop.local.md`
- **Default behavior**: If `output_dir` is not specified, it defaults to `getwd()` (current working directory)

### Accessing Files

```r
# After initialization, you can access files like this:

# Read the plan
plan <- readLines("work/plan.md")

# Or with custom output_dir:
plan <- readLines("~/projects/my-project/work/plan.md")

# List all iterations
list.files("work/iterations")

# Read a specific iteration
iteration_3 <- readLines("work/iterations/iteration-3.md")

# Check generated files
list.files("work")
```

---

## Core Functions

### 1. `init_ralphloop()`

Initialize a new ralphloop session with your task.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `prompt` | character | *required* | The task description for the LLM |
| `max_iterations` | numeric | `0` | Maximum iterations (0 = unlimited) |
| `completion_promise` | character | `NULL` | String that signals completion when output by LLM |
| `enforce_promise` | logical | `FALSE` | Stop loop when promise is detected |
| `plan` | logical | `FALSE` | Generate a structured plan before iteration |
| `step_enforcement` | logical | `TRUE` | Enforce step-by-step iteration (requires `plan = TRUE`) |
| `output_dir` | character | `NULL` | Base directory for output (defaults to current working directory) |

#### Examples

**Simple task:**
```r
init_ralphloop(
  prompt = "Write a function to parse CSV files"
)
```

**With iteration limit:**
```r
init_ralphloop(
  prompt = "Refactor the data processing pipeline",
  max_iterations = 10
)
```

**With completion promise:**
```r
init_ralphloop(
  prompt = "Build a web scraper and test it",
  completion_promise = "ALL TESTS PASS",
  enforce_promise = TRUE,
  max_iterations = 15
)
```

**With structured plan:**
```r
init_ralphloop(
  prompt = "Create a Shiny dashboard for sales data",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 20
)
```

**Custom output directory:**
```r
# Work directory will be created at ~/projects/my-api/work/
init_ralphloop(
  prompt = "Generate API documentation",
  output_dir = "~/projects/my-api"
)

# Or use an absolute path
init_ralphloop(
  prompt = "Build a data pipeline",
  output_dir = "C:/Users/username/Documents/my-project"
)

# Or relative to current directory
init_ralphloop(
  prompt = "Create analysis scripts",
  output_dir = "./analysis-project"
)
```

**Note:** The `output_dir` parameter sets the base directory. The actual work directory will be `output_dir/work/`. If not specified, it defaults to the current working directory.

---

### 2. `ralph_loop()`

Execute the iterative development loop.

#### Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `chat_client` | ellmer_chat | *required* | An ellmer chat client object |
| `path` | character | `NULL` | Path to state file (defaults to `.ralphloop/ralphloop.local.md`) |
| `register_tools` | logical | `TRUE` | Register ralphloop tools with chat client |

#### Features

- **Automatic retry logic**: 5 retry attempts per step with exponential backoff (30s, 60s, 120s, 240s, 480s)
- **State persistence**: All progress saved to disk, resumable at any time
- **Tool support**: LLM can use tools to manage plan, read/write files, etc.
- **Progress tracking**: Clear console output showing current step and progress

#### Examples

**Basic usage:**
```r
ralph_loop(chat_client)
```

**Resume from specific state file:**
```r
ralph_loop(chat_client, path = "custom/path/ralphloop.local.md")
```

**Without tool registration** (if you've already registered tools):
```r
ralph_loop(chat_client, register_tools = FALSE)
```

---

### 3. `ralphloop_status()`

Display the current status of the ralphloop session.

#### Parameters

None.

#### Returns

Prints formatted status information including:
- Active status
- Current iteration number
- Max iterations
- Completion promise (if set)
- Plan and step enforcement settings
- Start time
- Output directories
- Task prompt

#### Example

```r
ralphloop_status()
```

**Output:**
```
🔍 ralphloop status
────────────────────────────────────────
Active:              TRUE
Iteration:           3
Max iterations:      10
Completion promise:  ALL TESTS PASS
Enforce promise:     TRUE
Plan enabled:        TRUE
Step enforcement:    TRUE
Started at (UTC):    2026-01-26T14:30:00Z
Output base dir:     /home/user/project
Work directory:      /home/user/project/work
────────────────────────────────────────

📌 Task prompt
────────────────────────────────────────
Build a data visualization dashboard
────────────────────────────────────────
```

---

### 4. `cancel_ralphloop()`

Cancel the current ralphloop session gracefully.

#### Parameters

None.

#### Example

```r
# Cancel the current session
cancel_ralphloop()

# Check status to confirm
ralphloop_status()
```

---

## Common Workflows

### Workflow 1: Simple Iterative Development

Use this for straightforward tasks without structured planning.

```r
library(ellmer)
library(ralphloop)

# Setup
chat_client <- ellmer::chat_openai(model = "gpt-4")

# Initialize
init_ralphloop(
  prompt = "Create a function to validate email addresses with regex",
  max_iterations = 5
)

# Run
ralph_loop(chat_client)

# Check results in work/ directory
list.files("work/iterations")
```

---

### Workflow 2: Plan-Driven Development

Use this for complex tasks that benefit from structured steps.

```r
library(ellmer)
library(ralphloop)

# Setup
chat_client <- ellmer::chat_anthropic(model = "claude-3-5-sonnet-20241022")

# Initialize with planning
init_ralphloop(
  prompt = "Build a REST API client for GitHub with authentication, 
           error handling, and rate limiting",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 20
)

# Check status
ralphloop_status()

# Run - LLM will generate a plan first, then work through steps
ralph_loop(chat_client)

# View the generated plan
cat(readLines("work/plan.md"), sep = "\n")
```

---

### Workflow 3: Test-Driven Development with Completion Promise

Use this when you want the loop to stop automatically when tests pass.

```r
library(ellmer)
library(ralphloop)

# Setup
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# Initialize with completion promise
init_ralphloop(
  prompt = "Refactor the data_processor() function and add comprehensive 
           unit tests using testthat. Ensure all tests pass.",
  plan = TRUE,
  step_enforcement = TRUE,
  completion_promise = "ALL TESTS PASS",
  enforce_promise = TRUE,
  max_iterations = 15
)

# Run
ralph_loop(chat_client)

# Loop will stop automatically when LLM outputs: <promise>ALL TESTS PASS</promise>
```

---

### Workflow 4: Custom Plan

Use this when you want to provide your own structured plan.

```r
library(ellmer)
library(ralphloop)

# 1. Create work directory
dir.create("work", showWarnings = FALSE)

# 2. Write your custom plan
plan_content <- "# Plan

- [ ] Step 1: Set up project structure with directories
- [ ] Step 2: Create database schema and migrations
- [ ] Step 3: Implement CRUD operations
- [ ] Step 4: Add input validation
- [ ] Step 5: Write integration tests
- [ ] Step 6: Add API documentation
"

writeLines(plan_content, "work/plan.md")

# 3. Initialize (plan will be detected and used)
init_ralphloop(
  prompt = "Build a user management system with database integration",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 20
)

# 4. Setup chat client
chat_client <- ellmer::chat_openai(model = "gpt-4-turbo")

# 5. Run
ralph_loop(chat_client)
```

---

### Workflow 5: Resuming After Interruption

If the loop stops due to rate limiting or other errors, simply run it again.

```r
library(ellmer)
library(ralphloop)

# Setup chat client
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# If loop was interrupted, just run again - it will resume automatically
ralph_loop(chat_client)

# The loop picks up from where it left off because state is preserved
```

**What happens during resume:**
- Reads the saved state from `.ralphloop/ralphloop.local.md`
- Continues from the last completed iteration
- Maintains all progress on the plan (if using plan mode)
- No work is lost!

---

### Workflow 6: Multiple Providers

You can switch between LLM providers between runs.

```r
library(ellmer)
library(ralphloop)

# Initialize task
init_ralphloop(
  prompt = "Create a data analysis report",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 10
)

# Start with OpenAI
chat_client_openai <- ellmer::chat_openai(model = "gpt-4")
ralph_loop(chat_client_openai)

# If you hit rate limits or want to switch, use a different provider
chat_client_anthropic <- ellmer::chat_anthropic(model = "claude-3-5-sonnet-20241022")
ralph_loop(chat_client_anthropic)

# Or use AWS Bedrock
chat_client_bedrock <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)
ralph_loop(chat_client_bedrock)
```

---

## Advanced Usage

### Working with Tools

When `plan = TRUE`, ralphloop registers several tools that the LLM can use:

#### Available Tools

1. **`mark_step_complete(step_text)`** - Mark a plan step as complete
2. **`get_plan_status()`** - Check current plan progress
3. **`add_plan_step(step_text, after_step)`** - Add a new step to the plan
4. **`write_file(filename, content)`** - Create/update files in work directory
5. **`read_file(filename)`** - Read existing files
6. **`list_files()`** - List files in work directory

#### Example: LLM Using Tools

```r
# Initialize with plan
init_ralphloop(
  prompt = "Build a simple calculator app",
  plan = TRUE,
  step_enforcement = TRUE,
  max_iterations = 10
)

# Run - LLM will use tools automatically
ralph_loop(chat_client)

# Example of what happens internally:
# Iteration 1:
#   LLM: "I'll create the calculator.R file"
#   Tool call: write_file("calculator.R", "add <- function(a, b) { a + b }")
#   Tool call: mark_step_complete("Step 1: Create basic arithmetic functions")
```

### Customizing Retry Behavior

The retry logic can be customized by modifying the `run_llm_with_retry()` function parameters:

```r
# Default behavior: 5 retries with 30s initial wait
# Wait times: 30s, 60s, 120s, 240s, 480s

# To customize, you would need to modify R/ralphloop_engine.R
# and change the default parameters:
run_llm_with_retry <- function(chat_client, message_text, 
                                max_retries = 5,      # Change this
                                initial_wait = 30) {  # Or this
  # ... function body
}
```

### Inspecting Iteration History

All iterations are saved to `work/iterations/`:

```r
# List all iterations
list.files("work/iterations")

# Read a specific iteration
iteration_3 <- readLines("work/iterations/iteration-3.md")
cat(iteration_3, sep = "\n")

# Compare iterations
iteration_1 <- readLines("work/iterations/iteration-1.md")
iteration_2 <- readLines("work/iterations/iteration-2.md")

# Use diff tools to see changes
# diffobj::diffFile("work/iterations/iteration-1.md", 
#                   "work/iterations/iteration-2.md")
```

### Monitoring Plan Progress

```r
# Read the current plan
plan <- readLines("work/plan.md")
cat(plan, sep = "\n")

# Parse plan programmatically
library(ralphloop)
steps <- parse_plan("work/plan.md")

# Check completion status
completed_steps <- Filter(function(s) s$complete, steps)
incomplete_steps <- Filter(function(s) !s$complete, steps)

cat(sprintf("Completed: %d/%d steps\n", 
            length(completed_steps), 
            length(steps)))
```

---

## Troubleshooting

### Issue: Rate Limiting (HTTP 429)

**Symptom:**
```
⚠️  Rate limit detected - Attempt 1/5 failed
Error: HTTP 429 Too Many Requests.
⏳ Waiting 30 seconds before retry...
```

**Solution:**
- The system will automatically retry up to 5 times per step
- If all retries fail, wait a few minutes and run `ralph_loop(chat_client)` again
- The loop state is preserved and will resume from where it stopped

### Issue: Expired Credentials

**Symptom:**
```
⚠️  API error - Attempt 1/5 failed
Error: HTTP 403 Forbidden.
ℹ The security token included in the request is expired
```

**Solution:**
1. Refresh your credentials
2. Create a new chat client with fresh credentials
3. Run `ralph_loop(chat_client)` again - it will resume automatically

```r
# Refresh credentials (example for AWS)
# aws sso login

# Create new client
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# Resume
ralph_loop(chat_client)
```

### Issue: Loop Not Stopping

**Symptom:**
Loop continues past max_iterations or doesn't detect completion promise.

**Solution:**
1. Check if `enforce_promise = TRUE` is set
2. Verify the completion promise string matches exactly what the LLM outputs
3. Check the iteration files to see if the promise was output:

```r
# Search for promise in iterations
iterations <- list.files("work/iterations", full.names = TRUE)
for (file in iterations) {
  content <- readLines(file)
  if (any(grepl("<promise>", content))) {
    cat("Promise found in:", file, "\n")
    cat(grep("<promise>", content, value = TRUE), "\n")
  }
}
```

### Issue: Plan Not Being Followed

**Symptom:**
LLM not working through plan steps sequentially.

**Solution:**
1. Ensure `step_enforcement = TRUE` is set
2. Check that `plan = TRUE` is set
3. Verify the plan file exists and has proper format:

```r
# Check plan format
plan <- readLines("work/plan.md")
cat(plan, sep = "\n")

# Should look like:
# # Plan
# 
# - [ ] Step 1: Description
# - [ ] Step 2: Description
# - [x] Step 3: Description (completed)
```

### Issue: Tools Not Working

**Symptom:**
LLM not using tools or tools not being registered.

**Solution:**
1. Ensure `plan = TRUE` (tools are only registered in plan mode)
2. Check that `register_tools = TRUE` in `ralph_loop()` call
3. Verify tools are registered:

```r
# Tools should be registered automatically, but you can check logs:
ralph_loop(chat_client)
# Look for: "📦 Registering ralphloop tools with chat client..."
# And: "📦 Registered 6 ralphloop tools"
```

### Issue: State File Corruption

**Symptom:**
Error reading state file or unexpected behavior.

**Solution:**
1. Check the state file:

```r
state <- readLines(".ralphloop/ralphloop.local.md")
cat(state, sep = "\n")
```

2. If corrupted, you can manually fix it or start fresh:

```r
# Backup old state
file.copy(".ralphloop/ralphloop.local.md", 
          ".ralphloop/ralphloop.local.md.backup")

# Start fresh
init_ralphloop(
  prompt = "Your task here",
  # ... other parameters
)
```

---

## Tips and Best Practices

### 1. Start with a Clear Prompt

**Good:**
```r
init_ralphloop(
  prompt = "Create a data validation function that:
           1. Checks for missing values
           2. Validates data types
           3. Returns a detailed report
           Include unit tests using testthat."
)
```

**Less Good:**
```r
init_ralphloop(
  prompt = "Make a validator"
)
```

### 2. Use Plans for Complex Tasks

For tasks with more than 3-4 steps, use plan mode:

```r
init_ralphloop(
  prompt = "Build a complete web scraping pipeline",
  plan = TRUE,
  step_enforcement = TRUE
)
```

### 3. Set Reasonable Iteration Limits

```r
# For simple tasks
max_iterations = 5

# For medium complexity
max_iterations = 10-15

# For complex projects
max_iterations = 20-30
```

### 4. Use Completion Promises for Test-Driven Development

```r
init_ralphloop(
  prompt = "Implement feature X with full test coverage",
  completion_promise = "ALL TESTS PASS",
  enforce_promise = TRUE
)
```

### 5. Review Iterations Regularly

```r
# After a few iterations, check progress
ralphloop_status()

# Read the latest iteration
latest <- list.files("work/iterations", full.names = TRUE)
latest <- latest[length(latest)]
cat(readLines(latest), sep = "\n")
```

### 6. Keep Work Directory Clean

```r
# Archive completed projects
if (dir.exists("work")) {
  archive_name <- sprintf("work_archive_%s", format(Sys.time(), "%Y%m%d_%H%M%S"))
  file.rename("work", archive_name)
}
```

---

## Additional Resources

- **ellmer documentation**: https://ellmer.tidyverse.org/
- **Example workflows**: See `demo/example.R` and `demo/retry_example.R`
- **Enhancement docs**: See `docs/rate-limiting-enhancement.md`

---

## Getting Help

If you encounter issues:

1. Check this guide's [Troubleshooting](#troubleshooting) section
2. Review the iteration files in `work/iterations/` to understand what happened
3. Check the state file in `.ralphloop/ralphloop.local.md`
4. Try running `ralphloop_status()` to see current state
5. Open an issue on GitHub with:
   - Your initialization parameters
   - The error message
   - Relevant iteration files
   - Your R and package versions

```r
# Get version info
sessionInfo()
packageVersion("ralphloop")
packageVersion("ellmer")
```
