import debate
import gleam/result
import llm_client
import prompts
import senators
import session

/// Bridge layer between debate orchestration and AI backends.
/// Today this delegates to `llm_client`, but it can later route to an
/// Agent SDK sidecar without changing the rest of the system.
pub fn request_debate_decision(
  senator: senators.Senator,
  current_session: session.Session,
) -> Result(debate.DebateDecision, llm_client.LlmError) {
  let prompt = prompts.senator_debate_prompt(senator, current_session)

  use body <- result.try(llm_client.call_llm(prompt))
  llm_client.parse_debate_decision(body)
}
