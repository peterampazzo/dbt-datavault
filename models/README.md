# Reading the Data Vault models

Start with a single customer and follow this path:

```text
src_customer → stg_customer → customer_h       identity: which customer?
                           → customer_n_s     history: what changed and when loaded?
                           → customer_nation_l relationships: which nations were observed?

customer_n_s → customer_n_s_v1                 calculated validity intervals
customer_h + satellites + control_snap_v1
            → customer_pit                    pointers to records at a snapshot
```

`source/` exposes the test batches. `stage/` prepares hashes, metadata and
payloads. `raw_vault/` captures identities, relationships and history.
`business_vault/` contains snapshot calendars and point-in-time helpers.
This is a feature-validation project: several models are parallel variants
for exercising macro options, rather than additional business entities.

## SQL configuration and YAML documentation

Each `.sql` file configures its materialization, defines `yaml_metadata`,
and calls a datavault4dbt macro that generates SQL. That embedded YAML
contains **macro inputs**, such as the parent key, payload and source model.

The adjacent `schema.yml` contains **dbt model properties**: descriptions,
column documentation and tests. dbt does not require a YAML file for every
SQL model. One properties file can describe an entire folder, and its name
does not have to be `schema.yml`. Its `name` entries must match the SQL
filenames without `.sql`.

Read [raw vault documentation](raw_vault/schema.yml) and
[business vault documentation](business_vault/schema.yml) alongside the SQL.
Model descriptions explain purpose, row grain (what one row represents),
inputs and variant behavior. Column descriptions explain the principal keys
and temporal fields; they are not an exhaustive schema contract.

## Names used in this project

| Suffix | Meaning | What a row generally represents here |
| --- | --- | --- |
| `_h` | Hub | One distinct business identity |
| `_l` | Link | One distinct relationship or dependent-child combination |
| `_s` | Satellite, normally v0 | One captured version of a parent's attributes |
| `_s_v1` | Temporal satellite view | A v0 record with calculated end timestamp/current flag |
| `_ma_s` | Multi-active satellite | One entry within a parent's captured set, such as a phone type |
| `_es` | Effectivity satellite | A relationship activity change |
| `_rts` | Record-tracking satellite | A key observed in a source at a load timestamp |
| `_nh_l`, `_nh_s` | Non-historized link/satellite | An immutable event or its attached payload |
| `_rh`, `_rs`, `_rt` | Reference hub/satellite/table | Reference identities, their history, or a lookup over that history |
| `_pit` | Point-in-time table | A parent/snapshot combination with satellite join pointers |

Variant suffixes are local conventions: `_ms` means multiple sources, `_ng`
means a ghost-record-related variant, `_sb` selects the single-batch option,
and `_keys` omits satellite payload. `_all` and `_any` select PIT satellite
coverage rules. `_bounded` supplies explicit snapshot calendar boundaries.
The exact options are described in each model's YAML.

## Keys and time

- A business key such as `c_custkey` identifies an entity in the source.
- `hk_*` is a hashkey used to identify and join an entity or relationship.
- `hd_*` is a hashdiff used to detect payload changes.
- `ldts` records when data was loaded. In this fixture it comes from the seed
  batches, allowing historical loads to be replayed.
- `ledts` is the calculated end of a loaded version in v1 views.
- `rsrc` identifies the record source.
- `sdts` is a snapshot timestamp used by calendars, PITs and snapshot lookups.

A customer's hashkey can appear in many satellite rows. Join a satellite
using the parent key **and the required version**, rather than assuming the
hashkey alone selects a single row. PITs provide the relevant satellite key
and load-timestamp pointers for a snapshot. Multi-active phone data can
still yield several phone types for that customer/version.

Load history is different from business-effective history: `ldts` describes
when a change was captured, which can differ from when it happened in the
source business.

Stages normally generate unknown and error **ghost records**, identified
by the configured `SYSTEM` and `ERROR` record sources. These are synthetic
fallback rows, so counts can include more rows than there are real entities.
The `_ng` variants exercise behavior without some of these fallbacks.

## Browse the documentation

After loading the environment and activating the virtual environment as
described in the project README:

```bash
dbt docs generate --profiles-dir . --target multi
dbt docs serve --port 8080
```

`docs generate` builds the documentation artifacts and queries Fabric for
catalog metadata; it needs a working connection. Choose the target whose
tables you want to inspect. The site shows descriptions, columns, tests
and the model dependency graph.

For a local parse check without executing models or querying the catalog:

```bash
dbt parse --profiles-dir . --target multi
```
