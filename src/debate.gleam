import gleam/string
import senators

pub type VoteIntent {
  Yea
  Nay
  Abstain
  Undecided
}

pub type DebateDecision {
  SpeakDecision(
    will_speak: Bool,
    speech: String,
    vote_intent: VoteIntent,
    purpose: String,
    procedure: Procedure,
  )
}

pub type DebateTurn {
  DebateTurn(
    turn_index: Int,
    senator: senators.Senator,
    speech: String,
    vote_intent: VoteIntent,
    purpose: String,
    procedure: Procedure,
  )
}

pub type Procedure {
  NoProcedure
  CallVote
  ProposeAmendment
  UnknownProcedure(label: String)
}

pub fn vote_intent_from_label(label: String) -> Result(VoteIntent, String) {
  case string.lowercase(string.trim(label)) {
    "yea" -> Ok(Yea)
    "nay" -> Ok(Nay)
    "abstain" -> Ok(Abstain)
    "undecided" -> Ok(Undecided)
    other -> Error("Unknown vote_intent value: " <> other)
  }
}

pub fn vote_intent_label(intent: VoteIntent) -> String {
  case intent {
    Yea -> "Yea"
    Nay -> "Nay"
    Abstain -> "Abstain"
    Undecided -> "Undecided"
  }
}

pub fn procedure_from_label(label: String) -> Procedure {
  case string.lowercase(string.trim(label)) {
    "call_vote" -> CallVote
    "propose_amendment" -> ProposeAmendment
    "none" -> NoProcedure
    "" -> NoProcedure
    other -> UnknownProcedure(other)
  }
}

pub fn procedure_label(proc: Procedure) -> String {
  case proc {
    NoProcedure -> "none"
    CallVote -> "call_vote"
    ProposeAmendment -> "propose_amendment"
    UnknownProcedure(label) -> label
  }
}
