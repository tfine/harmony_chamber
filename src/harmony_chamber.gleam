import gleam/erlang/process
import mist
import wisp
import wisp/wisp_mist

/// A minimal Wisp request handler.
///
/// Takes a Wisp `Request` and returns a `Response`.
fn handle_request(_req: wisp.Request) -> wisp.Response {
  let html =
    "<!doctype html>
     <html>
       <head>
         <meta charset=\"utf-8\" />
         <title>Harmony Chamber v0</title>
       </head>
       <body>
         <h1>Harmony Chamber v0</h1>
         <p>The multi-agent chamber is online.</p>
       </body>
     </html>"

  // Return a 200 OK HTML response with that body
  wisp.html_response(html, 200)
}

/// Main entry point.
///
/// Starts a Mist HTTP server using Wisp and then sleeps forever so it stays alive.
pub fn main() {
  // Enable Wisp's logger for nicer logs
  wisp.configure_logger()

  let secret_key_base = "dev_secret_key_change_me"

  // Build and start the HTTP server on 0.0.0.0:8080
  let assert Ok(_) =
    handle_request
    |> wisp_mist.handler(secret_key_base)
    |> mist.new
    |> mist.bind("0.0.0.0")
    |> mist.port(8080)
    |> mist.start

  // Keep the main process alive forever (server runs in its own process)
  process.sleep_forever()
}
