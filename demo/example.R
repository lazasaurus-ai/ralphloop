# ------------------------------------------------------------
# ralphloop Demo Examples
# ------------------------------------------------------------

devtools::load_all()
library(ellmer)
library(ralphloop)

# Create a Bedrock-backed ellmer chat client
# You can also use chat_openai(), chat_anthropic(), etc.
chat_client <- ellmer::chat_aws_bedrock(
  model = "anthropic.claude-3-5-sonnet-20240620-v1:0"
)

# ============================================================
# Example 1: Basic Plan-Aware Step Enforcement (NEW!)
# ============================================================
# This example demonstrates the new step-by-step iteration
# where the LLM works through a structured plan.

init_ralphloop(
  prompt = "Build a simple todo list web app with HTML, CSS, and JavaScript",
  plan = TRUE,                # Generate a structured plan
  step_enforcement = TRUE,    # Enforce step-by-step iteration
  max_iterations = 15
)

# Check the status
ralphloop_status()

# Run the loop - LLM will:
# 1. Generate a plan with checkbox steps
# 2. Work on one step at a time
# 3. Use tools to mark steps complete
# 4. Create files in the work/ directory
ralph_loop(chat_client)

# ============================================================
# Example 2: Plan with Completion Promise
# ============================================================
# Combines step enforcement with a completion promise.
# Loop stops when the promise is detected.

init_ralphloop(
  prompt = "Refactor calculate_average() and add unit tests",
  plan = TRUE,
  step_enforcement = TRUE,
  completion_promise = "ALL TESTS PASS",
  enforce_promise = TRUE,
  max_iterations = 10
)

ralphloop_status()
ralph_loop(chat_client)

# ============================================================
# Example 3: Free-form Iteration (Original Behavior)
# ============================================================
# No plan, just iterative improvement until max iterations
# or completion promise.

init_ralphloop(
  prompt = "Write a Python function to calculate fibonacci numbers",
  plan = FALSE,
  completion_promise = "IMPLEMENTATION COMPLETE",
  enforce_promise = TRUE,
  max_iterations = 5
)

ralphloop_status()
ralph_loop(chat_client)

# ============================================================
# Example 4: Plan Without Step Enforcement
# ============================================================
# Generates a plan for reference but doesn't enforce
# step-by-step iteration.

init_ralphloop(
  prompt = "Create a REST API design document",
  plan = TRUE,
  step_enforcement = FALSE,  # Plan is generated but not enforced
  max_iterations = 3
)

ralphloop_status()
ralph_loop(chat_client)

# ============================================================
# Utility Functions
# ============================================================

# Check status at any time
ralphloop_status()

# Cancel the loop if needed
# cancel_ralphloop()

# After completion, check the work/ directory:
# - plan.md: The structured plan with checkboxes
# - iteration-N.md: Output from each iteration
# - final.md: The promoted final output
# - Any files created by the LLM via write_file tool
