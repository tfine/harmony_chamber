import chamber
import debate
import demo
import gleam/dynamic/decode
import gleam/http
import gleam/json
import gleam/list
import gleam/result
import gleam/string
import llm_client
import prompts
import senators
import session
import wisp

pub fn handle_state(request: wisp.Request) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let roster = session.roster()
    let chamber_state = session.seeded_chamber()
    let payload = encode_state(chamber_state, roster)
    wisp.json_response(json.to_string(payload), 200)
  })
}

pub fn handle_propose_speech(request: wisp.Request) -> wisp.Response {
  wisp.require_method(request, http.Post, fn() {
    wisp.require_string_body(request, fn(body) {
      case decode_propose_payload(body) {
        Ok(payload) -> process_proposal(payload)
        Error(message) -> json_error(message, 400)
      }
    })
  })
}

pub fn handle_demo_llm(request: wisp.Request) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    case demo.demo_senator_llm() {
      Ok(text) ->
        json.object([#("speech", json.string(text))])
        |> json.to_string
        |> fn(body) { wisp.json_response(body, 200) }
      Error(error) -> llm_error_response(error)
    }
  })
}

fn process_proposal(payload: ProposePayload) -> wisp.Response {
  let chamber_state = session.seeded_chamber()
  let roster = session.roster()

  case
    debate.propose_speech(
      chamber_state.debate,
      payload.senator_id,
      payload.text,
    )
  {
    Ok(new_debate) -> {
      json.object([
        #("phase", json.string(prompts.phase_slug(new_debate.phase))),
        #("transcript", encode_transcript(new_debate.transcript, roster)),
      ])
      |> json.to_string
      |> fn(body) { wisp.json_response(body, 200) }
    }
    Error(reason) -> json_error(reason, 422)
  }
}

fn encode_state(
  chamber_state: chamber.Chamber,
  roster: List(senators.Senator),
) -> json.Json {
  json.object([
    #("bill", encode_bill(chamber_state.bill)),
    #("phase", json.string(prompts.phase_slug(chamber_state.debate.phase))),
    #("next_id", json.int(chamber_state.debate.next_id)),
    #("queue", json.array(chamber_state.debate.queue, json.string)),
    #("transcript", encode_transcript(chamber_state.debate.transcript, roster)),
    #("senators", encode_senators(roster)),
  ])
}

fn encode_bill(bill: chamber.Bill) -> json.Json {
  json.object([
    #("id", json.string(bill.id)),
    #("title", json.string(bill.title)),
    #("summary", json.string(bill.summary)),
  ])
}

fn encode_transcript(
  turns: List(debate.DebateTurn),
  roster: List(senators.Senator),
) -> json.Json {
  turns
  |> json.array(fn(turn) {
    json.object([
      #("id", json.int(turn.id)),
      #("senator_id", json.string(turn.senator_id)),
      #("senator_name", json.string(senator_name(turn.senator_id, roster))),
      #("text", json.string(turn.text)),
    ])
  })
}

fn encode_senators(roster: List(senators.Senator)) -> json.Json {
  roster
  |> json.array(fn(senator) {
    json.object([
      #("id", json.string(senator.id)),
      #("name", json.string(senator.name)),
      #("state", json.string(senator.state)),
      #("biography", json.string(senator.biography)),
    ])
  })
}

fn senator_name(id: String, roster: List(senators.Senator)) -> String {
  case roster {
    [] -> id
    [head, ..tail] ->
      case head.id == id {
        True -> head.name
        False -> senator_name(id, tail)
      }
  }
}

type ProposePayload {
  ProposePayload(senator_id: String, text: String)
}

fn decode_propose_payload(body: String) -> Result(ProposePayload, String) {
  let decoder = {
    use senator_id <- decode.field("senator_id", decode.string)
    use text <- decode.field("text", decode.string)
    decode.success(ProposePayload(senator_id:, text:))
  }

  json.parse(body, decoder)
  |> result.map_error(json_error_message)
}

fn json_error_message(error: json.DecodeError) -> String {
  case error {
    json.UnexpectedEndOfInput -> "Unexpected end of JSON input"
    json.UnexpectedByte(detail) -> "Unexpected byte: " <> detail
    json.UnexpectedSequence(detail) -> "Unexpected sequence: " <> detail
    json.UnableToDecode(errors) ->
      errors
      |> list.map(fn(err) {
        let decode.DecodeError(expected:, found:, path:) = err
        let location = case path {
          [] -> ""
          _ -> " at " <> string.join(path, with: ".")
        }
        "Expected " <> expected <> " but found " <> found <> location
      })
      |> string.join(", ")
  }
}

fn json_error(message: String, status: Int) -> wisp.Response {
  json.object([#("error", json.string(message))])
  |> json.to_string
  |> fn(body) { wisp.json_response(body, status) }
}

fn llm_error_response(error: llm_client.LlmError) -> wisp.Response {
  case error {
    llm_client.MissingApiKey ->
      json_error("Missing OPENAI_API_KEY environment variable", 500)
    llm_client.HttpFailure(reason) -> json_error(reason, 502)
    llm_client.DecodeFailure(reason) -> json_error(reason, 500)
  }
}
