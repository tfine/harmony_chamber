import gleam/list
import gleam/string

pub type DebateTurn {
  DebateTurn(id: Int, senator_id: String, text: String)
}

pub type Phase {
  Ongoing
  VoteRequested
  Voting
  Completed
}

pub type DebateState {
  DebateState(
    queue: List(String),
    transcript: List(DebateTurn),
    next_id: Int,
    phase: Phase,
  )
}

pub fn new(initial_queue: List(String)) -> DebateState {
  DebateState(queue: initial_queue, transcript: [], next_id: 1, phase: Ongoing)
}

pub fn propose_speech(
  state: DebateState,
  senator_id: String,
  text: String,
) -> Result(DebateState, String) {
  let cleaned = string.trim(text)

  case cleaned {
    "" -> Error("Speech text cannot be empty")
    _ -> propose_for_phase(state, senator_id, cleaned)
  }
}

fn propose_for_phase(
  state: DebateState,
  senator_id: String,
  text: String,
) -> Result(DebateState, String) {
  case state.phase {
    Completed -> Error("The debate has concluded.")
    Voting -> Error("Voting is in progress; speeches are closed.")
    _ -> enforce_queue(state, senator_id, text)
  }
}

fn enforce_queue(
  state: DebateState,
  senator_id: String,
  text: String,
) -> Result(DebateState, String) {
  case state.queue {
    [] -> Error("No senators remain in the speaking queue.")
    [current, ..] ->
      case current == senator_id {
        True -> Ok(record_speech(state, senator_id, text))
        False -> Error("It is not this senator's turn to speak.")
      }
  }
}

fn record_speech(
  state: DebateState,
  senator_id: String,
  text: String,
) -> DebateState {
  let turn = DebateTurn(id: state.next_id, senator_id: senator_id, text: text)
  let updated =
    DebateState(
      queue: rotate_queue(state.queue),
      transcript: append_turn(state.transcript, turn),
      next_id: state.next_id + 1,
      phase: state.phase,
    )

  case content_requests_vote(text) {
    True -> request_vote(updated)
    False -> updated
  }
}

pub fn advance(state: DebateState) -> DebateState {
  case state.phase {
    Ongoing -> DebateState(..state, queue: rotate_queue(state.queue))
    VoteRequested -> DebateState(..state, phase: Voting)
    Voting -> DebateState(..state, phase: Completed)
    Completed -> state
  }
}

pub fn transcript(state: DebateState) -> List(DebateTurn) {
  state.transcript
}

pub fn last_n(state: DebateState, count: Int) -> List(DebateTurn) {
  case count <= 0 {
    True -> []
    False ->
      state.transcript
      |> list.reverse
      |> list.take(count)
      |> list.reverse
  }
}

pub fn request_vote(state: DebateState) -> DebateState {
  case state.phase {
    Ongoing -> DebateState(..state, phase: VoteRequested)
    _ -> state
  }
}

pub fn content_requests_vote(text: String) -> Bool {
  let lower = string.lowercase(text)
  let cues = [
    "call for a vote",
    "request a vote",
    "move to vote",
    "call the question",
    "move the question",
  ]

  list.any(cues, fn(cue) { string.contains(lower, cue) })
}

fn rotate_queue(queue: List(String)) -> List(String) {
  case queue {
    [] -> []
    [head, ..tail] -> append_item(tail, head)
  }
}

fn append_turn(existing: List(DebateTurn), turn: DebateTurn) -> List(DebateTurn) {
  append_item(existing, turn)
}

fn append_item(list_: List(a), value: a) -> List(a) {
  case list_ {
    [] -> [value]
    [head, ..tail] -> [head, ..append_item(tail, value)]
  }
}
