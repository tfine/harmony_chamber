# Senator Agent Memory Fix

## Problem
Senator agents were created as autonomous actors with their own memory references, but they weren't actually using them to save their own messages to Pinecone. Instead, the chamber orchestrator was handling memory persistence, which broke the agent encapsulation pattern.

## Root Cause
- Senator processes (`senator_process.gleam`) had memory references but didn't persist their own debate turns
- The chamber orchestrator (`chamber.gleam`) was calling `memory.add_debate_turn()` after receiving decisions from agents
- This meant agents weren't truly autonomous - they relied on external code to save their state

## Solution
Made senator agents fully autonomous by having them save their own messages to Pinecone:

### 1. **src/senator_process.gleam** - Agents delegate to agent_bridge
- Modified the `RequestDecision` message handler
- Agents delegate to `agent_bridge.request_debate_decision()` which handles both LLM calls and memory saving
- Uses the agent's own `state.memory` reference passed to agent_bridge
- Ensures consistent behavior through centralized agent_bridge logic

### 2. **src/chamber.gleam** - Removed orchestrator-level memory calls
- Removed `memory.add_debate_turn()` calls from `step_debate_round()` 
- Removed `memory.add_debate_turn()` calls from `step_vote_round()`
- Chamber now only orchestrates debate flow, doesn't handle agent persistence
- Added comments explaining that memory saving is handled by agents

### 3. **src/agent_bridge.gleam** - Fallback path also saves to memory
- When `agent_bridge.request_debate_decision()` is called (fallback when no agent exists)
- Now also saves debate turns to memory after getting LLM response
- Ensures consistency whether using agents or direct LLM calls
- Both code paths now properly persist to Pinecone

### 4. **src/memory_worker.gleam** - Removed unused file
- This file was a duplicate/outdated implementation
- Not imported anywhere in the codebase
- The actual memory worker is implemented inside `memory.gleam`
- Deleted to avoid confusion

## Benefits
1. **Centralized Logic**: All memory saving happens in `agent_bridge.gleam`, avoiding duplication
2. **Consistent Behavior**: Both agent and non-agent paths use the same code path through agent_bridge
3. **Better Architecture**: Clear separation of concerns - agent_bridge handles LLM+memory, chamber orchestrates debate flow
4. **No Duplicates**: Fixed the issue where messages were being saved twice (once by agent, once by bridge)
5. **Maintainability**: Single source of truth for memory persistence logic

## Testing
- Code compiles successfully with `gleam build`
- Memory worker will receive messages from agents via `process.send()`
- Messages will be persisted to Pinecone asynchronously
- Check logs for "Memory worker received StoreTurn" messages to verify

## Next Steps
1. Run the application and verify messages are being saved to Pinecone
2. Check logs to confirm memory worker is receiving and processing messages
3. Query Pinecone to verify debate turns and intentions are being stored correctly
4. Monitor for any errors in the memory persistence pipeline
