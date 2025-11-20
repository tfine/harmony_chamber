# AGATA Time Legislation System

## Overview

This document describes the time-legislation system added to Harmony Chamber for the AGATA project. This system runs **parallel to** the existing 100-senator debate simulation and focuses on governing Todd Fine and Delaney Mills' time in 5-15 minute micro-blocks.

## Architecture

### Core Modules (New)

1. **`src/time_bill.gleam`** - Time bill and micro-block data types
2. **`src/human_status.gleam`** - Human status reporting and parsing
3. **`src/resource_state.gleam`** - Budget and time tracking

### Integration Points (Reused)

- **`src/memory.gleam`** - Vector storage for time bills and reports
- **`src/llm_client.gleam`** - LLM calls for Senate agents
- **`src/senators.gleam`** - Same 100 AGATA senators used for time legislation
- **`src/vector_store.gleam`** - Pinecone integration (same index, different metadata)

## Key Concepts

### 1. Time Bills

A `TimeBill` is legislation that governs specific micro-blocks of human work:

```gleam
TimeBill(
  id: String,                          // e.g., "TB-2025-001"
  title: String,                       // e.g., "Morning Farm Survey"
  purpose: String,                     // Clear action statement
  pillar_links: List(Pillar),         // Farm, Film, Music, etc.
  time_horizon: TimeHorizon,          // ThisHour, Today, ThisWeek, etc.
  created_at: String,
  effective_at: String,
  proposers: List(senators.Senator),  // Which senators proposed this
  micro_blocks: List(MicroBlock),     // The actual work blocks
  status: TimeBillStatus,             // Proposed, Active, InProgress, etc.
  budget_thinking: Option(BudgetThinking),
)
```

### 2. Micro-Blocks

Each `MicroBlock` represents 5-15 minutes of focused work:

```gleam
MicroBlock(
  duration_minutes: Int,              // Typically 5, 10, or 15
  assignees: BlockAssignees,          // Who does what
  instructions: List(String),         // Step-by-step tasks
  expected_artifacts: List(String),   // Files, notes, etc.
  limitation_note: String,            // Awareness of human constraints
  reflection_prompts: List(String),   // Post-block questions
  completion: Option(BlockCompletion), // Filled in after work
)
```

### 3. Human Status Reports

Todd and Delaney report their state using a standardized format:

```markdown
## STATUS
Time (local): 2025-01-15 09:30 AM
Block length preference: 10
Location: AGATA farmhouse
Todd_energy: medium
Delaney_energy: high
Todd_mood: focused
Delaney_mood: energized
Physical_state: at desk with coffee
Internet_tools: laptop, good wifi

Immediate_needs_Todd:
- Review yesterday's notes
- Check email

Immediate_needs_Delaney:
- none

Current_tasks_on_mind:
- Farm survey planning
- Film equipment inventory

Hard_constraints_next_2_3_hours:
- Todd has call at 11 AM
```

### 4. Block Reports

After completing a block, they report what happened:

```markdown
## BLOCK REPORT
Time (local): 2025-01-15 09:45 AM
Block actually used: 12
Todd_energy: medium
Delaney_energy: high

What_got_done:
- Reviewed farm survey notes
- Listed 3 priority areas
- Created draft checklist

Where_got_stuck:
- Need to verify property boundaries

New_needs_or_tasks:
- Get county GIS maps
- Talk to neighbor about fence line
```

### 5. Resource Tracking

The system tracks:

- **Budget**: Starting with $2000, conceptual allocations
- **Time**: Minutes by person, by pillar, total blocks completed
- **Allocations**: Budget categories (farm_tools, travel, etc.)

```gleam
ResourceState(
  available_budget: 2000.0,
  allocations: Dict(String, Float),
  time_tracking: TimeTracking(...),
  last_updated: String,
)
```

## Data Flow

### 1. Status Report → Time Bill Creation

```
Todd/Delaney submit STATUS
    ↓
Parse with human_status.parse_status()
    ↓
Senate agents receive context
    ↓
Senate debates and creates TimeBill
    ↓
TimeBill stored and embedded in Pinecone
```

### 2. Time Bill → Execution → Report

```
Active TimeBill retrieved
    ↓
Todd/Delaney work on MicroBlock
    ↓
Submit BLOCK REPORT
    ↓
Parse with human_status.parse_block_report()
    ↓
Update MicroBlock.completion
    ↓
Update ResourceState time tracking
    ↓
Store report in Pinecone for memory
```

## Pinecone Integration

### Metadata Strategy

Time legislation uses the **same Pinecone index** as traditional bills, differentiated by metadata:

**Time Bill Metadata:**
```json
{
  "kind": "time_bill",
  "bill_id": "TB-2025-001",
  "bill_title": "Morning Farm Survey",
  "time_horizon": "this_hour",
  "pillars": ["farm"],
  "assignees": ["todd", "delaney"],
  "duration_minutes": 10,
  "status": "active"
}
```

**Status Report Metadata:**
```json
{
  "kind": "human_status",
  "timestamp": "2025-01-15T09:30:00",
  "todd_energy": "medium",
  "delaney_energy": "high",
  "block_preference": 10
}
```

**Block Report Metadata:**
```json
{
  "kind": "block_report",
  "bill_id": "TB-2025-001",
  "timestamp": "2025-01-15T09:45:00",
  "actual_minutes": 12,
  "completed": true
}
```

### Query Patterns

1. **Get recent status**: Filter by `kind: "human_status"`, sort by timestamp
2. **Get active time bills**: Filter by `kind: "time_bill"` AND `status: "active"`
3. **Get block history**: Filter by `kind: "block_report"`, group by bill_id
4. **Pillar-specific work**: Filter by `pillars` array contains target pillar

## Senate Agent Behavior

### Time Legislation Prompts

Senate agents receive specialized prompts for time legislation:

**Context includes:**
- Latest human status report
- Recent block reports (what worked, what didn't)
- Current resource state (budget, time spent)
- Relevant past time bills from memory

**Output format:**
```json
{
  "bill_id": "TB-2025-001",
  "title": "Morning Farm Survey",
  "purpose": "Document current farm state for planning",
  "pillar_links": ["farm"],
  "time_horizon": "this_hour",
  "micro_blocks": [
    {
      "duration_minutes": 10,
      "assignees": {
        "todd_tasks": ["Walk north field", "Take 5 photos"],
        "delaney_tasks": ["Review yesterday's notes"],
        "joint_tasks": ["Discuss findings"]
      },
      "instructions": [
        "1. Todd: Walk north field perimeter",
        "2. Todd: Photo any issues or changes",
        "3. Delaney: Pull up yesterday's notes",
        "4. Both: 2-minute sync on observations"
      ],
      "expected_artifacts": [
        "5 photos of north field",
        "Bullet list of observations",
        "Updated priority list"
      ],
      "limitation_note": "Todd has call at 11 AM, keep block short",
      "reflection_prompts": [
        "What surprised you?",
        "What needs immediate attention?",
        "What can wait until next week?"
      ]
    }
  ],
  "budget_thinking": {
    "estimated_cost": 0.0,
    "category": "farm_operations",
    "notes": "No cost, using existing resources"
  }
}
```

## Implementation Status

### ✅ Completed

1. **Core data types** (`time_bill.gleam`)
   - TimeBill, MicroBlock, BlockAssignees
   - Pillar, TimeHorizon, TimeBillStatus enums
   - EnergyLevel tracking
   - Validation functions

2. **Human status system** (`human_status.gleam`)
   - HumanStatus and BlockReport types
   - Markdown parsing for STATUS and BLOCK REPORT
   - Formatting functions for output
   - Bullet point extraction

3. **Resource tracking** (`resource_state.gleam`)
   - Budget allocation and spending
   - Time tracking by person and pillar
   - Summary and reporting functions

### 🚧 Next Steps

4. **Time Senate session logic** (`src/time_senate.gleam`)
   - Session management for time bills
   - Active bill tracking
   - Completion workflows

5. **LLM prompts** (`src/time_prompts.gleam`)
   - Senate agent prompts for time legislation
   - Context assembly from status + memory
   - Output parsing and validation

### 🧭 AI Governance Layer

- **Autopilot + Time Charter**: The running Senate debates the "AGATA Time Priorities Charter" while issuing micro-block bills. Heavy amendments are encouraged so principles stay explicit as new work arrives.
- **Immediate orders**: Each status submission seeds a fallback time bill so humans always receive an actionable block even if long-form debate is still in flight.
- **Persistence**: Time-session state, bills, and reports are held in the time session manager and can be snapshotted alongside the main chamber to survive restarts.
- **Fragments-first UI**: The time page updates in small fragments (order banner, timeline, sidebar) to keep instructions visible without jarring full-page refreshes.

6. **API routes** (`src/time_api.gleam`)
   - POST /time/status - Submit status report
   - POST /time/report - Submit block report
   - GET /time/current - Get current active time bill
   - GET /time/history - Get past time bills
   - GET /time/resources - Get resource state

7. **Memory integration**
   - Extend `memory.gleam` to handle time bill storage
   - Add time-specific query functions
   - Implement embedding for status/reports

8. **Demo/testing**
   - Create `src/time_demo.gleam` with example flow
   - Mock status reports and time bills
   - Verify Pinecone storage and retrieval

## Usage Example

### Scenario: Morning Farm Work

**1. Todd and Delaney submit status:**
```gleam
let status_text = "
## STATUS
Time (local): 2025-01-15 09:00 AM
Block length preference: 10
Location: AGATA farmhouse
Todd_energy: medium
Delaney_energy: high
...
"

let status = human_status.parse_status(status_text)
// Store in Pinecone for Senate context
```

**2. Senate creates time bill:**
```gleam
let bill = TimeBill(
  id: "TB-2025-001",
  title: "Morning Farm Survey - North Field",
  purpose: "Document current state for spring planning",
  pillar_links: [Farm],
  time_horizon: ThisHour,
  micro_blocks: [
    MicroBlock(
      duration_minutes: 10,
      assignees: BlockAssignees(
        todd_tasks: ["Walk perimeter", "Take photos"],
        delaney_tasks: ["Review notes"],
        joint_tasks: ["2-min sync"],
      ),
      ...
    )
  ],
  ...
)
```

**3. They complete the work and report:**
```gleam
let report_text = "
## BLOCK REPORT
Time (local): 2025-01-15 09:12 AM
Block actually used: 12
Todd_energy: medium
Delaney_energy: high

What_got_done:
- Walked north field perimeter
- Took 7 photos of fence issues
- Reviewed yesterday's notes
- Had sync discussion

Where_got_stuck:
- none

New_needs_or_tasks:
- Schedule fence repair
- Get quotes from contractors
"

let report = human_status.parse_block_report(report_text)
// Update bill completion
// Update resource state
// Store in Pinecone
```

**4. Resource state updated:**
```gleam
let new_state = resource_state.record_time(
  state,
  minutes: 12,
  todd_worked: True,
  delaney_worked: True,
  pillar: Some(Farm),
)
// Todd: 12 minutes, Delaney: 12 minutes
// Farm pillar: 12 minutes
// Total blocks: 1
```

## Design Principles

### 1. Human-Limits-First
- Micro-blocks sized for tired humans
- Energy levels tracked and respected
- Breaks and self-care normalized

### 2. Tiny, Verifiable Increments
- Every block produces concrete artifacts
- No vague tasks without outputs
- Always tie work to notes or files

### 3. Traceability
- Every decision links to a Senate bill
- Every report links to a time block
- Resource changes tracked over time

### 4. Extensibility
- Generic enough for other projects
- Easy to add new resource types
- Pillar system accommodates growth

### 5. Separation of Concerns
- Domain logic separate from LLM prompts
- Parsing separate from storage
- API separate from business logic

## Integration with Existing System

### Coexistence Strategy

The time legislation system **does not replace** the traditional Senate simulation. Both can run simultaneously:

**Traditional Mode:**
- 100 AGATA senators debate policy bills
- Bills about farm plans, film projects, governance
- Longer time horizons (weeks, months, years)
- Stored in Pinecone with `kind: "debate_speech"` or `kind: "bill"`

**Time Legislation Mode:**
- Same 100 senators govern micro-blocks
- Bills about immediate work (5-15 minutes)
- Short time horizons (this hour, today)
- Stored in Pinecone with `kind: "time_bill"` or `kind: "block_report"`

**Shared Infrastructure:**
- Same Pinecone index (different metadata)
- Same LLM client and retry logic
- Same senator roster and biographies
- Same memory/embedding system

### Mode Selection

Future implementation will support:
- Environment variable: `HARMONY_MODE=debate|time|both`
- Separate API routes for each mode
- Unified web UI showing both streams
- Cross-references between policy bills and time bills

## Future Enhancements

### Phase 2: Advanced Features

1. **Predictive scheduling**
   - Learn from past blocks to suggest optimal times
   - Predict energy levels based on patterns
   - Recommend break timing

2. **Multi-person coordination**
   - Handle conflicts when both need same resource
   - Suggest parallel vs. sequential work
   - Optimize for joint tasks

3. **Budget integration**
   - Real accounting system integration
   - Automatic expense tracking
   - Budget alerts and forecasting

4. **External integrations**
   - Calendar sync (Google, Outlook)
   - Task management (Todoist, Asana)
   - Time tracking (Toggl, Harvest)

### Phase 3: Scaling

1. **More humans**
   - Support for residents, volunteers, visitors
   - Role-based permissions
   - Team coordination

2. **More resources**
   - Land allocation
   - Equipment scheduling
   - Material inventory

3. **Long-term planning**
   - Link micro-blocks to quarterly goals
   - Track progress on multi-month projects
   - Generate reports for funders

## Conclusion

This time legislation system provides a robust, elegant foundation for governing human time and resources through AI Senate agents. It preserves the existing Senate simulation while adding practical, immediate governance capabilities focused on Todd and Delaney's daily work at AGATA.

The system is designed to be:
- **Simple**: Clear data types, straightforward workflows
- **Elegant**: Reuses existing infrastructure, minimal duplication
- **Extensible**: Easy to add features, resources, and people
- **Traceable**: Every decision and action is logged and retrievable

Next steps involve implementing the session logic, LLM prompts, and API routes to make this system fully operational.
