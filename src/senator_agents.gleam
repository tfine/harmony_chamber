import gleam/dict.{type Dict}
import gleam/list
import gleam/option.{type Option, None, Some}
import memory
import senator_process
import senators

pub type Registry {
  Registry(processes: Dict(String, senator_process.SenatorProcess))
}

pub fn empty() -> Registry {
  Registry(processes: dict.new())
}

pub fn start(
  roster: List(senators.Senator),
  mem: memory.Memory,
) -> Registry {
  let processes =
    roster
    |> list.fold(dict.new(), fn(acc, senator) {
      let process = senator_process.start(senator, mem)
      dict.insert(acc, senator.id, process)
    })

  Registry(processes: processes)
}

pub fn get(
  registry: Registry,
  senator_id: String,
) -> Option(senator_process.SenatorProcess) {
  case dict.get(registry.processes, senator_id) {
    Ok(proc) -> Some(proc)
    Error(Nil) -> None
  }
}

pub fn intentions_for(registry: Registry, senator_id: String) -> List(String) {
  case get(registry, senator_id) {
    Some(proc) -> senator_process.intentions_summary(proc)
    None -> []
  }
}
