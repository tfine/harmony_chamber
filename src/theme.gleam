import gleam/option.{type Option, None, Some}
import gleam/string
import wisp

pub type Theme {
  Classic
  Terminal
  Blossom
  Signal
  Orbit
  Romance
}

/// Determine the preferred theme from a request's query parameters. Defaults
/// to `Classic` when no explicit preference is supplied.
pub fn from_request(request: wisp.Request) -> Theme {
  wisp.get_query(request)
  |> from_query_params
}

pub fn from_query_params(params: List(#(String, String))) -> Theme {
  case theme_param(params) {
    Some(value) -> from_string(value)
    None -> Classic
  }
}

pub fn from_string(value: String) -> Theme {
  case string.lowercase(value) {
    "terminal" | "hacker" | "bbs" -> Terminal
    "blossom" | "hello_kitty" | "petal" -> Blossom
    "signal" | "bundes" | "germanic" -> Signal
    "orbit" | "station" | "space" -> Orbit
    "romance" | "valentine" | "lipstick" -> Romance
    _ -> Classic
  }
}

pub fn slug(theme: Theme) -> String {
  case theme {
    Classic -> "classic"
    Terminal -> "terminal"
    Blossom -> "blossom"
    Signal -> "signal"
    Orbit -> "orbit"
    Romance -> "romance"
  }
}

pub fn label(theme: Theme) -> String {
  case theme {
    Classic -> "Classic parchment"
    Terminal -> "Terminal glow"
    Blossom -> "Blossom pink"
    Signal -> "Signal tricolor"
    Orbit -> "Orbital command"
    Romance -> "Velvet romance"
  }
}

pub fn body_class(theme: Theme) -> String {
  case theme {
    Classic -> "theme-classic"
    Terminal -> "theme-terminal"
    Blossom -> "theme-blossom"
    Signal -> "theme-signal"
    Orbit -> "theme-orbit"
    Romance -> "theme-romance"
  }
}

pub fn query_suffix(theme: Theme) -> String {
  case theme {
    Classic -> ""
    Terminal -> "?theme=" <> slug(theme)
    Blossom -> "?theme=" <> slug(theme)
    Signal -> "?theme=" <> slug(theme)
    Orbit -> "?theme=" <> slug(theme)
    Romance -> "?theme=" <> slug(theme)
  }
}

pub fn available() -> List(Theme) {
  [Classic, Terminal, Blossom, Signal, Orbit, Romance]
}

fn theme_param(params: List(#(String, String))) -> Option(String) {
  case params {
    [] -> None
    [#(key, value), ..rest] ->
      case key == "theme" {
        True -> Some(value)
        False -> theme_param(rest)
      }
  }
}
