import api
import gleam/erlang/process
import gleam/http
import html_renderer
import mist
import session
import wisp
import wisp/wisp_mist

fn handle_request(request: wisp.Request) -> wisp.Response {
  case wisp.path_segments(request) {
    [] -> handle_home(request)
    ["api", "state"] -> api.handle_state(request)
    ["api", "propose_speech"] -> api.handle_propose_speech(request)
    ["api", "demo_llm"] -> api.handle_demo_llm(request)
    _ -> wisp.not_found()
  }
}

fn handle_home(request: wisp.Request) -> wisp.Response {
  wisp.require_method(request, http.Get, fn() {
    let roster = session.roster()
    let chamber_state = session.seeded_chamber()
    let page = html_renderer.render_page(chamber_state, roster)

    wisp.html_response(page, 200)
  })
}

pub fn main() {
  wisp.configure_logger()

  let secret_key_base = "dev_secret_key_change_me"

  let assert Ok(_) =
    handle_request
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8080)
    |> mist.start

  process.sleep_forever()
}
