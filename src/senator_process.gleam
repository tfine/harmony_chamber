import agent_bridge
import debate
import envoy
import gleam/erlang/process
import gleam/int
import gleam/list
import intentions
import llm_client
import memory
import messages
import senators
import session

pub opaque type SenatorProcess {
  SenatorProcess(id: String, mailbox: process.Subject(Message))
}

type State {
  State(
    senator: senators.Senator,
    inbox: List(messages.Message),
    intentions: intentions.SenatorIntentions,
    memory: memory.Memory,
  )
}

pub type Message {
  Deliver(messages.Message)
  GetInbox(process.Subject(List(messages.Message)))
  RequestDecision(session.Session, process.Subject(Result(debate.DebateDecision, llm_client.LlmError)))
  SetPrimaryGoal(String)
  AddCommitment(String)
  AddConstituentPressure(String)
  GetIntentions(process.Subject(List(String)))
}

pub fn start(
  senator: senators.Senator,
  mem: memory.Memory,
) -> SenatorProcess {
  let mailbox = process.new_subject()

  let _pid =
    process.spawn(fn() {
      loop(
        mailbox,
        State(
          senator: senator,
          inbox: [],
          intentions: intentions.empty(),
          memory: mem,
        ),
      )
    })

  SenatorProcess(id: senator.id, mailbox: mailbox)
}

/// In a future iteration the chamber will call this instead of invoking the LLM
/// directly. We keep it available for experimentation without changing the
/// main HTTP flow yet.
pub fn request_decision(
  proc: SenatorProcess,
  sess: session.Session,
) -> Result(debate.DebateDecision, llm_client.LlmError) {
  let reply = process.new_subject()
  process.send(proc.mailbox, RequestDecision(sess, reply))
  case process.receive(reply, decision_timeout_ms()) {
    Ok(result) -> result
    Error(Nil) -> {
      let _ =
        process.spawn(fn() {
          case process.receive_forever(reply) {
            _ -> Nil
          }
        })
      Error(llm_client.HttpFailure(
        "Debate decision timed out after "
          <> int.to_string(decision_timeout_ms())
          <> "ms",
      ))
    }
  }
}

pub fn deliver_message(
  proc: SenatorProcess,
  message: messages.Message,
) -> Nil {
  process.send(proc.mailbox, Deliver(message))
}

pub fn inbox_snapshot(proc: SenatorProcess) -> List(messages.Message) {
  let reply = process.new_subject()
  process.send(proc.mailbox, GetInbox(reply))
  process.receive_forever(reply)
}

pub fn set_primary_goal(proc: SenatorProcess, goal: String) -> Nil {
  process.send(proc.mailbox, SetPrimaryGoal(goal))
}

pub fn add_commitment(proc: SenatorProcess, commitment: String) -> Nil {
  process.send(proc.mailbox, AddCommitment(commitment))
}

pub fn add_constituent_pressure(proc: SenatorProcess, note: String) -> Nil {
  process.send(proc.mailbox, AddConstituentPressure(note))
}

pub fn intentions_summary(proc: SenatorProcess) -> List(String) {
  let reply = process.new_subject()
  process.send(proc.mailbox, GetIntentions(reply))
  process.receive_forever(reply)
}

fn loop(
  mailbox: process.Subject(Message),
  state: State,
) -> Nil {
  case process.receive_forever(mailbox) {
    Deliver(message) ->
      loop(
        mailbox,
        State(..state, inbox: prune_inbox([message, ..state.inbox])),
      )

    GetInbox(reply) -> {
      process.send(reply, state.inbox)
      loop(mailbox, state)
    }

    SetPrimaryGoal(goal) ->
      loop(
        mailbox,
        State(
          ..state,
          intentions: intentions.set_primary_goal(state.intentions, goal),
        ),
      )

    AddCommitment(entry) ->
      loop(
        mailbox,
        State(
          ..state,
          intentions: intentions.add_commitment(state.intentions, entry),
        ),
      )

    AddConstituentPressure(entry) ->
      loop(
        mailbox,
        State(
          ..state,
          intentions: intentions.add_constituent_pressure(state.intentions, entry),
        ),
      )

    GetIntentions(reply) -> {
      process.send(reply, intentions.summary_lines(state.intentions))
      loop(mailbox, state)
    }

    RequestDecision(sess, reply) -> {
      let senator = state.senator
      let memory_handle = state.memory
      let summary = intentions.summary_lines(state.intentions)

      let _ =
        process.spawn(fn() {
          let decision =
            agent_bridge.request_debate_decision(
              senator,
              sess,
              memory_handle,
              summary,
            )
          process.send(reply, decision)
        })

      loop(mailbox, state)
    }
  }
}

fn decision_timeout_ms() -> Int {
  case envoy.get("HARMONY_SENATOR_DECISION_TIMEOUT_MS") {
    Ok(value) ->
      case int.parse(value) {
        Ok(parsed) -> parsed
        Error(_) -> 20000
      }
    Error(_) -> 20000
  }
}

fn prune_inbox(inbox: List(messages.Message)) -> List(messages.Message) {
  inbox
  |> list.take(10)
}
