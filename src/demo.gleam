import debate
import llm_client
import prompts
import session

pub fn demo_senator_llm() -> Result(String, llm_client.LlmError) {
  case session.roster() {
    [] -> Error(llm_client.HttpFailure("No senators available for demo"))
    [senator, ..] -> {
      let chamber_state = session.seeded_chamber()
      let recent = debate.last_n(chamber_state.debate, 3)
      let prompt =
        prompts.compose_senator_prompt(senator, chamber_state, recent)
      llm_client.call_llm(prompt)
    }
  }
}
