import gleam/string

pub type Message {
  DirectMessage(from: String, to: String, body: String)
  PublicComment(from: String, body: String)
  PressInquiry(from: String, body: String)
  ArchivistMemo(body: String)
  SystemNotice(body: String)
}

pub fn is_relevant_for(message: Message, senator_id: String) -> Bool {
  case message {
    DirectMessage(_, to, _) -> to == senator_id
    _ -> True
  }
}

pub fn short_summary(message: Message) -> String {
  case message {
    DirectMessage(from, _, body) ->
      "Direct message from " <> from <> ": " <> snippet(body)
    PublicComment(from, body) ->
      "Public comment by " <> from <> ": " <> snippet(body)
    PressInquiry(from, body) -> "Press inquiry (" <> from <> "): " <> snippet(body)
    ArchivistMemo(body) -> "Archivist memo: " <> snippet(body)
    SystemNotice(body) -> "System notice: " <> snippet(body)
  }
}

fn snippet(body: String) -> String {
  let cleaned = string.trim(body)

  case string.length(cleaned) > 160 {
    True -> string.slice(cleaned, 0, 157) <> "..."
    False -> cleaned
  }
}
