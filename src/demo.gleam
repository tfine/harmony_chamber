import llm_client
import prompts
import senators
import session

pub fn demo_senator_llm() -> Result(String, llm_client.LlmError) {
  case senators.all_senators() {
    [] -> Error(llm_client.HttpFailure("No senators available for demo"))
    [senator, ..] -> {
      let prompt =
        prompts.senator_debate_prompt(senator, sample_session())
      llm_client.call_llm(prompt)
    }
  }
}

fn sample_bill() -> session.Bill {
  session.Bill(
    id: "DEMO-001",
    title: "Example Infrastructure Update",
    summary: "A lightweight demonstration bill used by the Harmony Chamber demo helpers.",
  )
}

fn sample_session() -> session.Session {
  session.initial_session(sample_bill())
}
