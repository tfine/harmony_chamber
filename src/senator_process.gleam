import agent_bridge
import debate
import gleam/erlang/process
import gleam/list
import llm_client
import messages
import senators
import session

pub opaque type SenatorProcess {
  SenatorProcess(id: String, mailbox: process.Subject(Message))
}

type State {
  State(senator: senators.Senator, inbox: List(messages.Message))
}

pub type Message {
  Deliver(messages.Message)
  GetInbox(process.Subject(List(messages.Message)))
  RequestDecision(session.Session, process.Subject(Result(debate.DebateDecision, llm_client.LlmError)))
}

pub fn start(senator: senators.Senator) -> SenatorProcess {
  let mailbox = process.new_subject()

  let _pid =
    process.spawn(fn() {
      loop(mailbox, State(senator: senator, inbox: []))
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
  process.receive_forever(reply)
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

fn loop(
  mailbox: process.Subject(Message),
  state: State,
) -> Nil {
  case process.receive_forever(mailbox) {
    Deliver(message) ->
      loop(
        mailbox,
        State(
          senator: state.senator,
          inbox: prune_inbox([message, ..state.inbox]),
        ),
      )

    GetInbox(reply) -> {
      process.send(reply, state.inbox)
      loop(mailbox, state)
    }

    RequestDecision(sess, reply) -> {
      // Delegate to the bridge for now; this isolates LLM wiring from the
      // orchestrator so we can later swap in an Agent SDK call.
      let decision = agent_bridge.request_debate_decision(state.senator, sess)
      process.send(reply, decision)
      loop(mailbox, state)
    }
  }
}

fn prune_inbox(inbox: List(messages.Message)) -> List(messages.Message) {
  inbox
  |> list.take(10)
}
