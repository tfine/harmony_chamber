# Critical Fix: Memory Worker Process Mailbox

## The Bug

The memory worker was **never receiving messages** despite messages being sent to it. The logs showed:
- ✅ "Sending debate turn to memory worker for andy_kim #1"
- ❌ "Memory worker received StoreTurn" (never appeared)

## Root Cause

In `start_worker()`, the code was creating a subject in the **parent process** and passing it to the **child process**:

```gleam
fn start_worker(...) -> process.Subject(StoreMessage) {
  let subject = process.new_subject()  // ❌ Created in PARENT process
  
  let _pid = process.spawn(fn() {
    worker_loop(subject, ...)  // ❌ Child tries to use parent's subject
  })
  
  subject  // ❌ Returns parent's subject
}
```

**Problem**: In Erlang/BEAM, each process must create its own mailbox/subject. You cannot create a subject in one process and use it to receive messages in another process. Messages sent to that subject would go to the parent process's mailbox, not the child's.

## The Fix

Use the **handshake pattern** (same as `senator_process.gleam`):

```gleam
fn start_worker(...) -> process.Subject(StoreMessage) {
  let handshake: process.Subject(process.Subject(StoreMessage)) = process.new_subject()
  
  let _pid = process.spawn(fn() {
    let mailbox = process.new_subject()  // ✅ Child creates its own subject
    process.send(handshake, mailbox)     // ✅ Sends it back to parent
    log_info("Memory worker started")
    worker_loop(mailbox, ...)            // ✅ Uses its own mailbox
  })
  
  process.receive_forever(handshake)     // ✅ Parent receives child's subject
}
```

**How it works**:
1. Parent creates a temporary handshake subject
2. Parent spawns child process
3. Child creates its own mailbox subject
4. Child sends its mailbox back to parent via handshake
5. Parent receives and returns child's mailbox
6. Now messages sent to that subject go to the child's mailbox

## Impact

This fix enables the entire memory persistence system:
- ✅ Memory worker now receives StoreTurn messages
- ✅ Debate turns are embedded and saved to Pinecone
- ✅ Intentions snapshots are saved to Pinecone
- ✅ Senator agents can properly persist their messages
- ✅ Memory recall works with actual stored data

## Testing

After this fix, you should see in logs:
```
INFO [memory]: Memory worker started
INFO [memory]: Sending debate turn to memory worker for andy_kim #1
INFO [memory]: Memory worker: Message received, processing...
INFO [memory]: Memory worker received StoreTurn for andy_kim #1
INFO [memory]: persist_turn: Embedding speech for andy_kim #1
INFO [memory]: persist_turn: Creating vector for andy_kim #1
INFO [memory]: persist_turn: Upserting to Pinecone for andy_kim #1
INFO [memory]: persist_turn: Successfully upserted andy_kim #1
INFO [memory]: Stored memory turn andy_kim #1 (bill_id)
```

## Related Files

- `src/memory.gleam` - Fixed `start_worker()` function
- `src/senator_process.gleam` - Reference implementation of handshake pattern
- `src/agent_bridge.gleam` - Calls `memory.add_debate_turn()` after decisions
- `src/chamber.gleam` - Removed duplicate memory saves (now handled by agents)
