import gleam/float
import gleam/int
import gleam/result

/// Inputs for scoring a rollout of a constitution-built website.
/// The site is assumed to be generated from the final legislation text and
/// shipped via OpenAI calls funded from our budget.
pub type WebRolloutInput {
  WebRolloutInput(
    /// Distinct visitors during the evaluation window.
    unique_visitors: Int,
    /// 0.0-1.0 share of visitors we consider verified/human.
    verified_ratio: Float,
    /// Average engaged time on site in seconds (not counting bounces).
    mean_engaged_seconds: Float,
    /// 0.0-1.0 completion rate for the key flow (e.g., submit/opt-in/download).
    completion_rate: Float,
    /// Token cost incurred for LLM generation/serving.
    infra_cost_tokens: Float,
    /// Token budget allocated to this rollout.
    budget_tokens: Float,
  )
}

/// Compute a traffic/impact score that rewards verified engagement and goal
/// completion, scaled by visitor volume, and penalised for cost overruns.
///
/// - Volume: square-rooted to dampen spikes from botnets.
/// - Quality: weighted blend of verified share, completion rate, and dwell.
/// - Cost: if infra tokens exceed budget, the score is linearly penalised.
pub fn web_rollout_score(input: WebRolloutInput) -> Float {
  let WebRolloutInput(
    unique_visitors: visitors,
    verified_ratio: verified,
    mean_engaged_seconds: dwell,
    completion_rate: completion,
    infra_cost_tokens: cost,
    budget_tokens: budget,
  ) = input

  let volume = visitors |> int.to_float |> float.square_root |> result.unwrap(0.0)

  let dwell_factor = case dwell >. 60.0 {
    True -> 1.0
    False -> dwell /. 60.0
  }

  let quality =
    0.5 *. clamp01(verified)
    +. 0.35 *. clamp01(completion)
    +. 0.15 *. clamp01(dwell_factor)

  let overrun = case budget >. 0.0 {
    True -> float.max(0.0, { cost -. budget } /. budget)
    False -> 0.0
  }

  let cost_penalty = float.max(0.0, 1.0 -. overrun)

  volume *. quality *. cost_penalty
}

fn clamp01(value: Float) -> Float {
  case value <. 0.0 {
    True -> 0.0
    False -> case value >. 1.0 {
      True -> 1.0
      False -> value
    }
  }
}
