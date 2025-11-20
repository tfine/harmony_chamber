# Verification Guide for Senator Agent Memory Fix

## Quick Verification Steps

### 1. Check the Code Changes
The following files were modified:
- ✅ `src/senator_process.gleam` - Agents now save their own messages
- ✅ `src/chamber.gleam` - Removed orchestrator-level memory calls
- ✅ `src/agent_bridge.gleam` - Fallback path also saves to memory
- ✅ `src/memory_worker.gleam` - Removed (was unused duplicate)

### 2. Verify Compilation
```bash
gleam build
# Should compile successfully ✅
```

### 3. Run Tests
```bash
gleam test
# All tests should pass ✅
```

### 4. Test with Live System (if Pinecone is configured)

Set up environment variables:
```bash
export HARMONY_MEMORY_MODE=production
export PINECONE_API_KEY=your_key
export PINECONE_ENVIRONMENT=your_env
export PINECONE_INDEX=your_index
export OPENAI_API_KEY=your_key
```

Run the application and watch for these log messages:

**Expected Logs:**
```
INFO [memory]: Sending debate turn to memory worker for <senator_id> #<turn_index>
INFO [memory]: Memory worker received StoreTurn for <senator_id> #<turn_index>
INFO [memory]: Stored memory turn <senator_id> #<turn_index> (<bill_id>)
```

### 5. Verify in Pinecone Dashboard

After running a debate session:
1. Log into Pinecone console
2. Check your index for new vectors
3. Vector IDs should follow pattern: `<senator_id>-<bill_id>-<turn_index>`
4. Metadata should include:
   - `senator_id`
   - `senator_name`
   - `bill_id`
   - `bill_title`
   - `content` (the speech)
   - `kind` (should be "debate_speech")
   - `turn_index`
   - `vote_intent`
   - `purpose`
   - `procedure`

### 6. Check for Errors

Monitor logs for any error messages:
```bash
# Should NOT see these errors:
ERROR [memory]: ALERT: Failed to store turn: ...
ERROR [memory]: ALERT: Failed to embed speech: ...
```

## Architecture Verification

### Agent Path (when senator agent exists)
```
Senator Agent (senator_process.gleam)
  ↓ Makes LLM decision via agent_bridge
  ↓ Saves own debate turn to memory
  ↓ Sends to memory worker via process.send()
  ↓
Memory Worker (in memory.gleam)
  ↓ Embeds speech text
  ↓ Creates vector with metadata
  ↓ Upserts to Pinecone
```

### Fallback Path (when no agent exists)
```
Chamber (chamber.gleam)
  ↓ Calls agent_bridge directly
  ↓
Agent Bridge (agent_bridge.gleam)
  ↓ Makes LLM decision
  ↓ Saves debate turn to memory
  ↓ Sends to memory worker via process.send()
  ↓
Memory Worker (in memory.gleam)
  ↓ Embeds speech text
  ↓ Creates vector with metadata
  ↓ Upserts to Pinecone
```

## Key Improvements

1. **Autonomous Agents**: Senator agents now handle their own memory persistence
2. **Consistent Behavior**: Both agent and non-agent paths save to Pinecone
3. **Clean Architecture**: Clear separation between orchestration and agent behavior
4. **No Breaking Changes**: External API remains the same, only internal implementation changed

## Troubleshooting

### If messages aren't being saved:

1. Check `HARMONY_MEMORY_MODE` is set to `production`
2. Verify Pinecone credentials are correct
3. Check logs for embedding or vector store errors
4. Ensure the memory worker process is running (check logs for "Memory worker started")
5. Verify network connectivity to Pinecone API

### If you see duplicate saves:

This should NOT happen anymore since we removed the chamber-level saves. If you see duplicates:
1. Check if there are multiple instances running
2. Verify the chamber.gleam changes were applied correctly
3. Check for any custom code that might be calling memory.add_debate_turn()

## Success Criteria

✅ Code compiles without errors
✅ All tests pass
✅ Logs show "Memory worker received StoreTurn" messages
✅ Logs show "Stored memory turn" success messages
✅ Pinecone index contains new vectors with correct metadata
✅ No error messages in logs about failed memory operations
