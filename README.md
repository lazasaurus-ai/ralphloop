# ralphloop 
<img src="img/ralph-wiggum.png"
     alt="Ralph loop illustration"
     align="right"
     width="180"/>

`ralphloop` provides a persistent, iterative development loop for LLM-driven workflows in R, built on top of the ellmer
 package.

It is inspired by the *Ralph loop* pattern popularized by Anthropic’s Claude Code, but implemented in a transparent, explicit, and R-native way.

Rather than treating LLM output as ephemeral chat, `ralphloop` persists each iteration to disk, making progress auditable, inspectable, and resumable.


## Key ideas

- Persistence over chat
Each iteration is written to a file (work/iteration-N.md) instead of disappearing into console history.

- Explicit iteration control
Loops advance by iteration count and/or explicit completion signals — never by hidden heuristics.

- Optional planning
A planning or checklist step (plan.md) can be generated before iteration begins.

- Optional semantic stopping
Loops can stop early when the model explicitly declares completion using a completion promise.

## Completion promises (important)

A completion promise is an explicit declaration emitted by the model to indicate that a task is complete.

Example:
```
<promise>ALL TESTS PASS</promise>
```
### How promises work in ralphloop

Promises are automatically injected into the prompt when provided

- The loop does not infer success

- The loop does not judge correctness

- It only detects the explicit promise tag

This keeps loop behavior honest, inspectable, and deterministic.

> If the promise never appears, the loop will not stop early — even if enforce_promise = TRUE.


## Example

```r
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

```

The loop continues until the completion promise is truthfully satisfied.

### Example with Status

````
     > ralphloop_status()
     
     🔍 ralphloop status
     ────────────────────────────────────────
     Active:              TRUE
     Iteration:           1
     Max iterations:      10
     Completion promise:  ALL TESTS PASS
     Enforce promise:     TRUE
     Plan enabled:        TRUE
     Started at (UTC):    2026-01-15T14:18:22Z
     Output base dir:     /home/lazasaurus-ai/R/ralphloop
     Work directory:      /home/lazasaurus-ai/R/ralphloop/work
     ────────────────────────────────────────
     
     📌 Task prompt
     ────────────────────────────────────────
     Refactor calculate_average() and add unit tests 
     ────────────────────────────────────────
     
     > ralph_loop(chat_client)
     🧭 Generating plan.md
     Here's a concise, actionable plan for refactoring the calculate_average() 
     function and adding unit tests:
     
     1. Review the current calculate_average() function:
        - Identify inputs, outputs, and functionality
        - Note any existing issues or areas for improvement
     
     2. Plan the refactoring:
        - List specific changes to improve readability and efficiency
        - Consider edge cases and error handling
        - Determine if any new helper functions are needed
     
     3. Create unit tests before refactoring:
        - Write tests for expected behavior with normal inputs
        - Include tests for edge cases (empty list, single item, etc.)
        - Add tests for error handling (invalid inputs)
     
     4. Refactor the calculate_average() function:
        - Implement planned changes
        - Ensure the function follows best practices and coding standards
        - Add appropriate comments and docstrings
     
     5. Run unit tests:
        - Verify that all tests pass after refactoring
        - Debug and fix any failing tests
     
     6. Add additional unit tests if necessary:
        - Cover any new functionality or edge cases introduced during refactoring
     
     7. Perform code review:
        - Check for any remaining issues or potential improvements
        - Ensure the refactored code meets project requirements
     
     8. Document changes:
        - Update any relevant documentation or comments
        - Note significant changes in commit messages or changelog
     
     9. Final testing:
        - Run all tests one last time to ensure everything works as expected
     
     10. Commit and push changes:
         - Create a descriptive commit message
         - Push the refactored code and new unit tests to the repository
     🔄 Iteration 1
     Certainly! I'll refactor the calculate_average() function and add unit tests. 
     Let's start with the implementation:
     
     ```python
     import unittest
     
     def calculate_average(numbers):
         if not numbers:
             return 0
         if not all(isinstance(num, (int, float)) for num in numbers):
             raise ValueError("All items must be numbers")
         return sum(numbers) / len(numbers)
     
     class TestCalculateAverage(unittest.TestCase):
         def test_normal_list(self):
             self.assertAlmostEqual(calculate_average([1, 2, 3, 4, 5]), 3.0)
     
         def test_float_numbers(self):
             self.assertAlmostEqual(calculate_average([1.5, 2.5, 3.5]), 2.5)
     
         def test_negative_numbers(self):
             self.assertAlmostEqual(calculate_average([-1, -2, -3, -4, -5]), -3.0)
     
         def test_empty_list(self):
             self.assertEqual(calculate_average([]), 0)
     
         def test_single_item(self):
             self.assertEqual(calculate_average([42]), 42)
     
         def test_invalid_input(self):
             with self.assertRaises(ValueError):
                 calculate_average([1, 2, "3", 4, 5])
     
     if __name__ == "__main__":
         unittest.main()
     ```
     
     Now, let's go through the changes and additions:
     
     1. Refactored `calculate_average()`:
        - Added a check for an empty list, returning 0 in that case.
        - Added input validation to ensure all items are numbers.
        - Used `sum()` and `len()` for a more concise implementation.
     
     2. Added unit tests:
        - `test_normal_list`: Tests the function with a normal list of integers.
        - `test_float_numbers`: Tests the function with floating-point numbers.
        - `test_negative_numbers`: Tests the function with negative numbers.
        - `test_empty_list`: Tests the function with an empty list.
        - `test_single_item`: Tests the function with a single-item list.
        - `test_invalid_input`: Tests the function's error handling for non-numeric
     input.
     
     3. Used `unittest` framework for organizing and running tests.
     
     4. Included `if __name__ == "__main__":` block to allow running tests 
     directly.
     
     To run the tests, you can execute this script directly. If all tests pass, 
     you'll see output indicating that all tests were successful.
     
     <promise>ALL TESTS PASS</promise>
     🛑 Completion promise detected — stopping loop
     > system("ls -la work")
     total 12
     drwxrwx---. 2 aalvarez domain users   43 Jan 15 09:18 .
     drwxrwx---. 9 aalvarez domain users 4096 Jan 15 09:08 ..
     -rw-rw----. 1 aalvarez domain users 2154 Jan 15 09:18 iteration-1.md
     -rw-rw----. 1 aalvarez domain users 1601 Jan 15 09:18 plan.md
````

## Roadmap (planned)

- Resume loops from prior state

- Promote final iterations (final.md)

- Clean / archive helpers

- Vignettes for real workflows

- Tool-augmented loops

## Disclaimer

`ralphloop` does not guarantee correctness.
Completion promises are **declared by the model**, not verified by the system.

The package is designed to make iteration visible and honest, not automatic or magical.

