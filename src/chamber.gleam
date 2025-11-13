import debate

pub type Bill {
  Bill(id: String, title: String, summary: String)
}

pub type Chamber {
  Chamber(bill: Bill, debate: debate.DebateState)
}

pub fn new(bill: Bill, senator_ids: List(String)) -> Chamber {
  Chamber(bill: bill, debate: debate.new(senator_ids))
}

pub fn submit_speech(
  chamber: Chamber,
  senator_id: String,
  text: String,
) -> Chamber {
  case debate.propose_speech(chamber.debate, senator_id, text) {
    Ok(new_debate) -> Chamber(..chamber, debate: new_debate)
    Error(_) -> chamber
  }
}

pub fn advance(chamber: Chamber) -> Chamber {
  Chamber(..chamber, debate: debate.advance(chamber.debate))
}

pub fn current_debate(chamber: Chamber) -> debate.DebateState {
  chamber.debate
}
