# API Error Retry Enhancement for ralphloop

## Summary

Added automatic retry logic with exponential backoff to handle transient API errors including rate limiting across all LLM providers. Each step gets 5 fresh retry attempts.

## Changes Made

### 1. Enhanced `R/ralphloop_engine.R`

- Created new function [`run_llm_with_retry()`](R/ralphloop_engine.R:12) that wraps API calls with retry logic
- Modified [`run_llm()`](R/ralphloop_engine.R:1) to use the new retry wrapper
- Implements exponential backoff: 30s, 60s, 120s, 240s, 480s wait times across **5 retry attempts per step**
- Detects rate limit errors by checking for common patterns: "429", "Too Many Requests", "Too many tokens", "rate limit", "throttle"
- **Generic approach**: Retries ANY API error, not just rate limits (provider-agnostic)
- **Per-step retry counter**: Each step gets 5 fresh retry attempts (counter resets between steps)
- Provides clear user feedback during retries with emoji indicators and actual error messages
- After exhausting retries, displays helpful message to run `ralph_loop(chat_client)` again

### 2. Updated Documentation

- Updated [`ralph_loop()`](R/ralphloop_loop.R:26) function documentation to mention 5 retry attempts per step
- Added new section in [`README.md`](README.md:91) explaining automatic retry with exponential backoff
- Created [`demo/retry_example.R`](demo/retry_example.R:1) to demonstrate the retry functionality

## How It Works

When ANY API error occurs (not just rate limits):

1. **First retry**: Waits 30 seconds, then retries
2. **Second retry**: Waits 60 seconds, then retries  
3. **Third retry**: Waits 120 seconds, then retries
4. **Fourth retry**: Waits 240 seconds (4 minutes), then retries
5. **Fifth retry**: Waits 480 seconds (8 minutes), then retries
6. **After all retries fail**: Displays error message and suggests running `ralph_loop(chat_client)` again

**Important**: The retry counter resets for each step, so if Step 1 uses 2 retries, Step 2 still gets 5 fresh retry attempts.

The loop state is always preserved, so users can safely resume by calling `ralph_loop(chat_client)` again.

## User Experience

### Before
```
Error in `req_perform_connection()`:
! HTTP 429 Too Many Requests.
ℹ Too many tokens, please wait before trying again.
```
User had to manually wait and restart.

### After (Rate Limit)
```
⚠️  Rate limit detected - Attempt 1/5 failed
Error: HTTP 429 Too Many Requests.
⏳ Waiting 30 seconds before retry...
```

### After (Generic Error)
```
⚠️  API error - Attempt 1/5 failed
Error: Connection timeout
⏳ Waiting 30 seconds before retry...
```

If all retries fail:
```
❌ All retry attempts exhausted

Final error encountered:
HTTP 429 Too Many Requests.

🔄 Try running ralph_loop(chat_client) again to continue
The loop state is preserved and will resume from where it stopped.
```

## Benefits

1. **Provider-agnostic**: Works with OpenAI, Anthropic, AWS Bedrock, and any other ellmer-supported provider
2. **Generic retry**: Handles ANY transient error, not just rate limits
3. **Per-step retries**: Each step gets 5 fresh retry attempts (counter resets between steps)
4. **Automatic handling**: No manual intervention needed for temporary issues
5. **Exponential backoff**: Respects API rate limits with increasing wait times (up to 8 minutes)
6. **State preservation**: Loop can always be resumed from where it stopped
7. **Clear feedback**: Users see the actual error message and retry progress
8. **Configurable**: `max_retries` and `initial_wait` parameters can be adjusted if needed

## Testing

The retry logic applies to all LLM API calls in ralphloop:
- Main iteration loop in [`ralph_loop()`](R/ralphloop_loop.R:36)
- Plan generation in [`generate_structured_plan()`](R/ralphloop_plan.R:13)

Both use [`run_llm()`](R/ralphloop_engine.R:1) which now includes retry logic.

## Provider-Specific Rate Limit Patterns

The retry logic detects rate limits from various providers:
- **AWS Bedrock**: "Too many tokens", "throttl"
- **OpenAI**: "429", "rate limit"
- **Anthropic**: "429", "rate_limit_error"
- **Generic HTTP**: "Too Many Requests"

All other errors are also retried, making the system resilient to transient network issues.

## Comparison to Other Tools

While I don't have specific information about Kilo Code's retry logic, the 5 retry attempts with exponential backoff (totaling up to ~15 minutes of wait time per step) is a generous approach that should handle most rate limiting scenarios gracefully.
