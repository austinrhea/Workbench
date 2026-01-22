# Workflow Example: ServiceNow → Snowflake Data Pipeline

This document demonstrates the **Research → Plan → Implement** workflow using a realistic ETL scenario: ingesting incident data from ServiceNow into Snowflake via Matillion, with a table summary feature.

## What You'll Learn

- How `/workflow` assesses tasks and routes to appropriate phases
- How state evolves through `STATE.md` at each phase
- How approval gates work between phases
- Realistic code examples for the pipeline

---

## The Scenario

**Goal**: Build a data pipeline that:
1. Extracts incident records from ServiceNow REST API
2. Transforms and loads data via Matillion ETL
3. Stores in Snowflake with RAW → STAGING → DWH pattern
4. Provides a table summary view for monitoring

---

## Starting the Workflow

### The Prompt

```
/workflow Build a data pipeline to ingest ServiceNow incident data into Snowflake
using Matillion ETL. Include a table summary feature that shows row counts,
data freshness, and quality metrics.
```

### Task Assessment

The workflow skill assesses the task:

```markdown
## Task Assessment

**Task**: ServiceNow → Snowflake pipeline with Matillion ETL and table summary
**Type**: Feature (new functionality)
**Scope**: Medium — multiple components across three systems

**Path**: research → plan → implement

**Rationale**:
- Involves external systems (ServiceNow API, Matillion, Snowflake)
- Requires understanding existing patterns before implementation
- Multi-step with architectural decisions

Proceed?
```

User responds: **yes**

### Initial STATE.md

```yaml
---
task: "ServiceNow → Snowflake pipeline with Matillion ETL and table summary"
objective: "Build end-to-end data pipeline with monitoring"
status: in_progress
phase: research
path: research,plan,implement
context_percent: 10
last_updated: 2026-01-22
---

## Original Prompt
> Build a data pipeline to ingest ServiceNow incident data into Snowflake
> using Matillion ETL. Include a table summary feature that shows row counts,
> data freshness, and quality metrics.

## Scope
**Doing**: Design and implement ETL pipeline with summary view
**Not doing**: Production deployment, alerting, CI/CD

## Progress
- [ ] Research: ServiceNow API, Matillion patterns, Snowflake schema
- [ ] Plan: Implementation steps
- [ ] Implement: Build the pipeline

## Decisions
[None yet]

## Blockers
[None]

## Key Files
[To be discovered]

## Checkpoint
Fresh start.

## Next Steps
Starting research phase
```

---

## Phase 1: Research

The workflow invokes `/research`:

```
Skill(skill="research", args="Map ServiceNow API, Matillion ETL patterns, Snowflake schema design")
```

### Research Findings

#### ServiceNow REST API

**Endpoint**: `https://{instance}.service-now.com/api/now/table/incident`

```bash
# Example API call
curl -X GET \
  "https://myinstance.service-now.com/api/now/table/incident?sysparm_limit=100&sysparm_query=sys_updated_on>2026-01-21" \
  -H "Authorization: Basic ${ENCODED_CREDS}" \
  -H "Accept: application/json"
```

**Response structure**:
```json
{
  "result": [
    {
      "sys_id": "abc123def456",
      "number": "INC0010001",
      "state": "2",
      "priority": "3",
      "short_description": "Cannot access email",
      "assigned_to": {
        "display_value": "John Smith",
        "link": "https://instance.service-now.com/api/now/table/sys_user/xyz789"
      },
      "sys_created_on": "2026-01-15 09:30:00",
      "sys_updated_on": "2026-01-22 14:15:00"
    }
  ]
}
```

#### Matillion ETL Components

| Component | Purpose |
|-----------|---------|
| API Query | Pull from ServiceNow REST API |
| Table Output | Load raw JSON to Snowflake VARIANT |
| SQL Script | FLATTEN + MERGE to target tables |

**Job structure**:
```
[Orchestration Job]
    └── [API Query: ServiceNow]
            → [Table Output: RAW.INCIDENT_JSON]
    └── [SQL Script: Transform & Merge]
```

#### Snowflake Schema Pattern

```
SERVICENOW_DW (Database)
├── RAW (Schema)
│   └── INCIDENT_JSON       -- VARIANT landing
├── STAGING (Schema)
│   └── STG_INCIDENT        -- Flattened, typed
└── DWH (Schema)
    ├── DIM_INCIDENT        -- Conformed dimension
    └── V_INCIDENT_SUMMARY  -- Monitoring view
```

### Gate

```markdown
## Research Complete

**Findings**: Mapped all three layers — ServiceNow API returns nested JSON,
Matillion loads to VARIANT, Snowflake FLATTEN + MERGE for incremental loads.

**Key decision**: Use SCD Type 1 (overwrite) for simplicity.

Ready to plan?
```

User responds: **yes**

### STATE.md After Research

```yaml
---
task: "ServiceNow → Snowflake pipeline with Matillion ETL and table summary"
status: in_progress
phase: plan
path: research,plan,implement
context_percent: 25
last_updated: 2026-01-22
---

## Progress
- [x] Research: ServiceNow API, Matillion patterns, Snowflake schema
- [ ] Plan: Implementation steps
- [ ] Implement: Build the pipeline

## Decisions
- Use `incident` table as source (most common ITSM use case)
- RAW → STAGING → DWH schema pattern
- SCD Type 1 (overwrite) for dimension
- Table summary via SQL view

## Key Files
- ServiceNow API: `/api/now/table/incident`
- Snowflake: `SERVICENOW_DW.DWH.DIM_INCIDENT`
```

---

## Phase 2: Plan

The workflow invokes `/plan`:

```
Skill(skill="plan", args="Create implementation plan for ServiceNow → Snowflake pipeline")
```

### Implementation Plan

#### Phase 1: Snowflake Schema Setup

```sql
-- Step 1.1: Create database and schemas
CREATE DATABASE IF NOT EXISTS SERVICENOW_DW;
CREATE SCHEMA IF NOT EXISTS SERVICENOW_DW.RAW;
CREATE SCHEMA IF NOT EXISTS SERVICENOW_DW.STAGING;
CREATE SCHEMA IF NOT EXISTS SERVICENOW_DW.DWH;

-- Step 1.2: Create RAW landing table
CREATE OR REPLACE TABLE RAW.INCIDENT_JSON (
    load_id     STRING DEFAULT UUID_STRING(),
    load_ts     TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP(),
    data        VARIANT
);

-- Step 1.3: Create STAGING table
CREATE OR REPLACE TABLE STAGING.STG_INCIDENT (
    sys_id              STRING PRIMARY KEY,
    number              STRING,
    state               STRING,
    priority            INT,
    short_description   STRING,
    assigned_to         STRING,
    assignment_group    STRING,
    sys_created_on      TIMESTAMP_NTZ,
    sys_updated_on      TIMESTAMP_NTZ,
    _loaded_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);

-- Step 1.4: Create DWH dimension table
CREATE OR REPLACE TABLE DWH.DIM_INCIDENT (
    incident_key        INT AUTOINCREMENT PRIMARY KEY,
    sys_id              STRING UNIQUE,
    number              STRING,
    state               STRING,
    state_name          STRING,
    priority            INT,
    priority_name       STRING,
    short_description   STRING,
    assigned_to         STRING,
    assignment_group    STRING,
    created_date        DATE,
    updated_date        DATE,
    sys_created_on      TIMESTAMP_NTZ,
    sys_updated_on      TIMESTAMP_NTZ,
    _loaded_at          TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
```

#### Phase 2: Matillion ETL Jobs

**Orchestration Job**: `ORCH_INCIDENT_PIPELINE`
```
[Start]
  → [API Query: SNOW_INCIDENT_EXTRACT]
  → [SQL Script: TRANSFORM_AND_MERGE]
  → [End Success]
```

**API Query Configuration**:
- Profile: ServiceNow REST
- URL: `/api/now/table/incident`
- Parameters: `sysparm_limit=1000`, `sysparm_query=sys_updated_on>${last_run}`
- Target: `RAW.INCIDENT_JSON.data`

#### Phase 3: Transform & Load

```sql
-- Step 3.1: Flatten JSON and merge to staging
MERGE INTO STAGING.STG_INCIDENT tgt
USING (
    SELECT
        f.value:sys_id::STRING AS sys_id,
        f.value:number::STRING AS number,
        f.value:state::STRING AS state,
        f.value:priority::INT AS priority,
        f.value:short_description::STRING AS short_description,
        f.value:assigned_to.display_value::STRING AS assigned_to,
        f.value:assignment_group.display_value::STRING AS assignment_group,
        f.value:sys_created_on::TIMESTAMP_NTZ AS sys_created_on,
        f.value:sys_updated_on::TIMESTAMP_NTZ AS sys_updated_on
    FROM RAW.INCIDENT_JSON,
    LATERAL FLATTEN(input => data:result) f
    WHERE load_ts >= DATEADD(hour, -2, CURRENT_TIMESTAMP())
) src
ON tgt.sys_id = src.sys_id
WHEN MATCHED THEN UPDATE SET
    number = src.number,
    state = src.state,
    priority = src.priority,
    short_description = src.short_description,
    assigned_to = src.assigned_to,
    assignment_group = src.assignment_group,
    sys_created_on = src.sys_created_on,
    sys_updated_on = src.sys_updated_on,
    _loaded_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    sys_id, number, state, priority, short_description,
    assigned_to, assignment_group, sys_created_on, sys_updated_on
) VALUES (
    src.sys_id, src.number, src.state, src.priority, src.short_description,
    src.assigned_to, src.assignment_group, src.sys_created_on, src.sys_updated_on
);

-- Step 3.2: Load to dimension with enrichment
MERGE INTO DWH.DIM_INCIDENT tgt
USING (
    SELECT
        sys_id,
        number,
        state,
        CASE state
            WHEN '1' THEN 'New'
            WHEN '2' THEN 'In Progress'
            WHEN '3' THEN 'On Hold'
            WHEN '6' THEN 'Resolved'
            WHEN '7' THEN 'Closed'
            ELSE 'Unknown'
        END AS state_name,
        priority,
        CASE priority
            WHEN 1 THEN 'Critical'
            WHEN 2 THEN 'High'
            WHEN 3 THEN 'Moderate'
            WHEN 4 THEN 'Low'
            WHEN 5 THEN 'Planning'
            ELSE 'Unknown'
        END AS priority_name,
        short_description,
        assigned_to,
        assignment_group,
        DATE(sys_created_on) AS created_date,
        DATE(sys_updated_on) AS updated_date,
        sys_created_on,
        sys_updated_on
    FROM STAGING.STG_INCIDENT
) src
ON tgt.sys_id = src.sys_id
WHEN MATCHED THEN UPDATE SET
    number = src.number,
    state = src.state,
    state_name = src.state_name,
    priority = src.priority,
    priority_name = src.priority_name,
    short_description = src.short_description,
    assigned_to = src.assigned_to,
    assignment_group = src.assignment_group,
    created_date = src.created_date,
    updated_date = src.updated_date,
    sys_created_on = src.sys_created_on,
    sys_updated_on = src.sys_updated_on,
    _loaded_at = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN INSERT (
    sys_id, number, state, state_name, priority, priority_name,
    short_description, assigned_to, assignment_group,
    created_date, updated_date, sys_created_on, sys_updated_on
) VALUES (
    src.sys_id, src.number, src.state, src.state_name, src.priority, src.priority_name,
    src.short_description, src.assigned_to, src.assignment_group,
    src.created_date, src.updated_date, src.sys_created_on, src.sys_updated_on
);
```

#### Phase 4: Table Summary View

```sql
-- Step 4.1: Create summary view
CREATE OR REPLACE VIEW DWH.V_INCIDENT_SUMMARY AS
SELECT
    'DWH.DIM_INCIDENT' AS table_name,
    COUNT(*) AS total_rows,
    MAX(sys_updated_on) AS data_freshness,
    DATEDIFF(minute, MAX(sys_updated_on), CURRENT_TIMESTAMP()) AS freshness_minutes,
    COUNT(DISTINCT state) AS distinct_states,
    COUNT(DISTINCT priority) AS distinct_priorities,
    COUNT(DISTINCT assigned_to) AS distinct_assignees,
    ROUND(100.0 * SUM(IFF(assigned_to IS NULL, 1, 0)) / NULLIF(COUNT(*), 0), 1) AS pct_unassigned,
    ROUND(100.0 * SUM(IFF(state IN ('6', '7'), 1, 0)) / NULLIF(COUNT(*), 0), 1) AS pct_resolved,
    MIN(sys_created_on) AS oldest_incident,
    MAX(sys_created_on) AS newest_incident,
    CURRENT_TIMESTAMP() AS summary_generated_at
FROM DWH.DIM_INCIDENT;

-- Step 4.2: Query the summary
SELECT * FROM DWH.V_INCIDENT_SUMMARY;
```

**Example output**:
```
TABLE_NAME        | TOTAL_ROWS | DATA_FRESHNESS      | FRESHNESS_MINUTES | PCT_UNASSIGNED | PCT_RESOLVED
------------------|------------|---------------------|-------------------|----------------|-------------
DWH.DIM_INCIDENT  | 45,231     | 2026-01-22 14:30:00 | 15                | 12.3           | 67.8
```

### Gate

```markdown
## Plan Complete

**Phases**: 4 (Schema → ETL Jobs → Transform → Summary)
**Steps**: 10 total
**Verification**: Each step has SQL that can be executed and validated

Approve to proceed?
```

User responds: **yes**

### STATE.md After Planning

```yaml
---
task: "ServiceNow → Snowflake pipeline with Matillion ETL and table summary"
status: in_progress
phase: implement
path: research,plan,implement
context_percent: 45
last_updated: 2026-01-22
---

## Progress
- [x] Research: ServiceNow API, Matillion patterns, Snowflake schema
- [x] Plan: Implementation steps (4 phases, 10 steps)
- [ ] Implement: Build the pipeline

## Decisions
- Use `incident` table as source
- RAW → STAGING → DWH schema pattern
- SCD Type 1 for dimension
- State/priority enrichment in DWH layer
- Summary view with freshness tracking
```

---

## Phase 3: Implementation

The workflow invokes `/implement`:

```
Skill(skill="implement", args="Execute the 4-phase pipeline implementation plan")
```

### Execution Summary

Implementation proceeds step-by-step with verification:

```markdown
## Phase 1 Complete: Schema Setup

### Completed
- [x] Created SERVICENOW_DW database
- [x] Created RAW, STAGING, DWH schemas
- [x] Created RAW.INCIDENT_JSON (VARIANT)
- [x] Created STAGING.STG_INCIDENT
- [x] Created DWH.DIM_INCIDENT

### Verified
- `SHOW TABLES IN DATABASE SERVICENOW_DW;` ✓ (3 tables)
- `DESC TABLE DWH.DIM_INCIDENT;` ✓ (15 columns)
```

```markdown
## Phase 2 Complete: Matillion ETL Jobs

### Completed
- [x] Created ORCH_INCIDENT_PIPELINE orchestration job
- [x] Configured API Query with ServiceNow profile
- [x] Added SQL Script component for transform

### Verified
- Job validates in Matillion ✓
- Sample run extracts 100 records ✓
```

```markdown
## Phase 3 Complete: Transform & Load

### Completed
- [x] MERGE to STAGING.STG_INCIDENT working
- [x] MERGE to DWH.DIM_INCIDENT with enrichment working

### Verified
- `SELECT COUNT(*) FROM STAGING.STG_INCIDENT;` → 45,231 ✓
- `SELECT COUNT(*) FROM DWH.DIM_INCIDENT;` → 45,231 ✓
- State/priority names populated ✓
```

```markdown
## Phase 4 Complete: Table Summary

### Completed
- [x] Created V_INCIDENT_SUMMARY view
- [x] Verified output format

### Verified
- Summary returns expected metrics ✓
- Freshness tracking working ✓
```

### Final Verification

```sql
-- Verify pipeline end-to-end
SELECT * FROM DWH.V_INCIDENT_SUMMARY;
```

Output:
```
┌──────────────────┬────────────┬─────────────────────┬───────────────────┬────────────────┬──────────────┐
│ TABLE_NAME       │ TOTAL_ROWS │ DATA_FRESHNESS      │ FRESHNESS_MINUTES │ PCT_UNASSIGNED │ PCT_RESOLVED │
├──────────────────┼────────────┼─────────────────────┼───────────────────┼────────────────┼──────────────┤
│ DWH.DIM_INCIDENT │ 45,231     │ 2026-01-22 14:45:00 │ 5                 │ 12.3           │ 67.8         │
└──────────────────┴────────────┴─────────────────────┴───────────────────┴────────────────┴──────────────┘
```

### Gate

```markdown
## Implementation Complete

### Deliverables
- [x] Snowflake schema (RAW → STAGING → DWH)
- [x] Matillion ETL job (API Query → Transform → Load)
- [x] Table summary view with quality metrics

### Verification Checklist
| Check | Status | Evidence |
|-------|--------|----------|
| Exists | ✓ | All tables/views created |
| Substantive | ✓ | Data flows end-to-end, 45K rows |
| Wired | ✓ | Summary view queries DIM table |

Implementation complete. Please verify.
```

### Final STATE.md

```yaml
---
task: "ServiceNow → Snowflake pipeline with Matillion ETL and table summary"
objective: "Build end-to-end data pipeline with monitoring"
status: complete
phase: idle
path:
context_percent: 60
last_updated: 2026-01-22
---

## Original Prompt
> Build a data pipeline to ingest ServiceNow incident data into Snowflake
> using Matillion ETL. Include a table summary feature.

## Scope
**Doing**: Design and implement ETL pipeline with summary view
**Not doing**: Production deployment, alerting, CI/CD

## Progress
- [x] Research: ServiceNow API, Matillion patterns, Snowflake schema
- [x] Plan: Implementation steps (4 phases, 10 steps)
- [x] Implement: Build the pipeline

## Decisions
- Use `incident` table as source
- RAW → STAGING → DWH schema pattern
- SCD Type 1 for dimension
- State/priority enrichment in DWH layer
- Summary view with freshness tracking

## Learnings
- ServiceNow API returns nested JSON — use LATERAL FLATTEN
- VARIANT columns need explicit casting for comparisons
- Summary view should include freshness_minutes for monitoring

## Key Files
- Snowflake: `SERVICENOW_DW.DWH.DIM_INCIDENT`
- Snowflake: `SERVICENOW_DW.DWH.V_INCIDENT_SUMMARY`
- Matillion: `ORCH_INCIDENT_PIPELINE`

## Checkpoint
Pipeline complete and verified.

## Next Steps
Task complete. Consider adding:
- Scheduled execution in Matillion
- Alerting on freshness threshold
- Additional tables (change_request, cmdb_ci)
```

---

## Key Takeaways

### What the Workflow System Provides

| Feature | Benefit |
|---------|---------|
| **Task Assessment** | Routes to appropriate path based on complexity |
| **Approval Gates** | Human review at high-leverage moments |
| **STATE.md Tracking** | Resume from any point, full context preservation |
| **Phase Isolation** | Research errors caught before planning, plan errors before coding |
| **Orchestration** | Automatic phase transitions after approval |

### When to Use Full Workflow

| Scenario | Path |
|----------|------|
| New feature, unclear scope | research → plan → implement |
| Bug or error | debug → (implement if needed) |
| Simple, obvious fix | Quick fix (direct) |
| Refactoring | research → plan → implement |

### Error Cascade Prevention

```
Research errors cascade 1000x → catch early with research phase
Planning errors cascade 100x  → catch with plan review
Code errors are localized     → implement phase handles these
```

---

## References

- [Workflow Concepts](../agent_docs/workflow.md) — R→P→I details, gates, deviation rules
- [Context Management](../agent_docs/context.md) — STATE.md patterns, compaction
- [12-Factor Agent Principles](../agent_docs/principles.md) — Orchestration patterns
- [ServiceNow Table API](https://docs.servicenow.com) — Official API documentation
- [Snowflake FLATTEN](https://docs.snowflake.com/en/sql-reference/functions/flatten) — JSON handling
