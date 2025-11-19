import debate
import gleam/result
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
) -> Result(debate.DebateDecision, llm_client.LlmError) {
  let prompt =
    prompts.senator_debate_prompt(
      senator,
      current_session,
      memory_context(mem, senator, current_session),
    )

  use body <- result.try(llm_client.call_llm(prompt))
  llm_client.parse_debate_decision(body)
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
