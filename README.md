# harmony_chamber

[![Package Version](https://img.shields.io/hexpm/v/harmony_chamber)](https://hex.pm/packages/harmony_chamber)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/harmony_chamber/)

ai governance in new harmony

REMEMBER to set:

HARMONY_MAX_LLM_CALLS
PINECONE_API_KEY
PINECONE_ENVIRONMENT
PINECONE_INDEX

```sh
gleam add harmony_chamber@1
```
```gleam
import harmony_chamber

pub fn main() -> Nil {
  // TODO: An example of the project in use
}
```

Further documentation can be found at <https://hexdocs.pm/harmony_chamber>.

## Development

```sh
gleam run   # Run the project
gleam test  # Run the tests
```

Senator public pages are available at `/senators` once the server is running. Constituents can leave notes via `/senators/{id}/notes`.
