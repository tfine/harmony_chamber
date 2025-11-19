import debate
import envoy
import gleam/int
import gleam/io
import llm_client
import memory
import prompts
import senators
import session

/// Bridge layer between debate orchestration and AI backends.
/// Today this delegates to `llm_client`, but it can later route to an
/// Agent SDK sidecar without changing the rest of the system.
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
    Ok(body) -> llm_client.parse_debate_decision(body)
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
    True ->
      case memory.recall(
        mem,
        senator.id,
        sess.bill.id,
        prompts.memory_query_text(sess),
        5,
      ) {
        Ok(hits) -> hits
        Error(_) -> []
      }
  }
}

fn log_request(senator: senators.Senator, prompt: String) -> Nil {
  io.println(
    "LLM request for "
      <> senator.name
      <> " ("
      <> senator.id
      <> "):\n"
      <> prompt
      <> "\n---",
  )
}
fn debate_timeout_ms() -> Int {
  case envoy.get("HARMONY_DEBATE_LLM_TIMEOUT_MS") {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> 20000
      }
    Error(_) -> 20000
  }
}
