import debate
import envoy
import gleam/erlang/process
import gleam/int
import gleam/io
import gleam/string
import llm_client
import memory
import prompts
import senators
import session

/// Bridge layer between debate orchestration and AI backends.
/// Today this delegates to `llm_client`, but it can later route to an
/// Agent SDK sidecar without changing the rest of the system.
/// 
/// When used as a fallback (no agent exists), this function also saves
/// the debate turn to memory to ensure consistency.
pub fn request_debate_decision(
  senator: senators.Senator,
  current_session: session.Session,
  mem: memory.Memory,
  intentions: List(String),
) -> Result(debate.DebateDecision, llm_client.LlmError) {
  io.println("agent_bridge entering for " <> senator.id)
  let prompt =
    prompts.senator_debate_prompt(
      senator,
      current_session,
      memory_context(mem, senator, current_session),
      intentions,
    )

  log_request(senator, prompt)

  case llm_client.call_llm_with_timeout(prompt, debate_timeout_ms()) {
    Ok(body) -> {
      let decision = llm_client.parse_debate_decision(body)

      // Save debate turn to memory (for fallback path when no agent exists)
      case decision {
        Ok(debate.SpeakDecision(
          will_speak: _,
          speech: speech,
          vote_intent: intent,
          purpose: purpose,
          procedure: procedure,
          amendment_summary: _,
          amendment_rationale: _,
        )) -> {
          let _ =
            memory.add_debate_turn(
              mem,
              senator,
              current_session.bill,
              current_session.next_turn_index,
              speech,
              intent,
              purpose,
              procedure,
            )
          Nil
        }
        Error(_) -> Nil
      }

      decision
    }
    Error(error) -> Error(error)
  }
}

fn memory_context(
  mem: memory.Memory,
  senator: senators.Senator,
  sess: session.Session,
) -> List(memory.MemoryHit) {
  case memory.enabled(mem) {
    False -> []
    True -> recall_with_timeout(mem, senator, sess)
  }
}

fn recall_with_timeout(
  mem: memory.Memory,
  senator: senators.Senator,
  sess: session.Session,
) -> List(memory.MemoryHit) {
  let timeout = memory_context_timeout_ms()
  let reply = process.new_subject()
  let query = prompts.memory_query_text(sess)

  let _ =
    process.spawn(fn() {
      let outcome = memory.recall(mem, senator.id, sess.bill.id, query, 5)
      process.send(reply, outcome)
    })

  case process.receive(reply, timeout) {
    Ok(result) ->
      case result {
        Ok(hits) -> hits
        Error(error) -> {
          log_memory_failure(senator, error)
          []
        }
      }
    Error(Nil) -> {
      log_memory_timeout(senator, timeout)
      drain_late_memory_reply(reply)
      []
    }
  }
}

fn log_request(senator: senators.Senator, prompt: String) -> Nil {
  io.println(
    "LLM request for "
    <> senator.name
    <> " ("
    <> senator.id
    <> ") length="
    <> int.to_string(string.length(prompt)),
  )
}

fn debate_timeout_ms() -> Int {
  case envoy.get("HARMONY_DEBATE_LLM_TIMEOUT_MS") {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> 20_000
      }
    Error(_) -> 20_000
  }
}

fn memory_context_timeout_ms() -> Int {
  case envoy.get("HARMONY_MEMORY_CONTEXT_TIMEOUT_MS") {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> 3000
      }
    Error(_) -> 3000
  }
}

fn log_memory_failure(
  senator: senators.Senator,
  error: memory.MemoryError,
) -> Nil {
  io.print_error(
    "WARN [agent_bridge]: Memory recall failed for "
    <> senator.name
    <> " ("
    <> senator.id
    <> "): "
    <> memory.error_to_string(error)
    <> "\n",
  )
}

fn log_memory_timeout(senator: senators.Senator, timeout: Int) -> Nil {
  io.print_error(
    "WARN [agent_bridge]: Memory recall timed out for "
    <> senator.name
    <> " ("
    <> senator.id
    <> ") after "
    <> int.to_string(timeout)
    <> "ms — proceeding without memory context\n",
  )
}

fn drain_late_memory_reply(
  subject: process.Subject(Result(List(memory.MemoryHit), memory.MemoryError)),
) -> Nil {
  let _ =
    process.spawn(fn() {
      case process.receive_forever(subject) {
        _ -> Nil
      }
    })
  Nil
}
