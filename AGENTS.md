# AGENTS.md — datavault4dbt on Microsoft Fabric Lakehouse (dbt-fabricspark)

Guidance for humans and coding agents working in this repository. Read this
before `README.md` (operations, run results, change scenarios, feature matrix)
and `models/README.md` (how to read the models).

## What this repository is

A dbt project that proves the [datavault4dbt](https://github.com/ScalefreeCOM/datavault4dbt)
package works on a Microsoft Fabric **Lakehouse** through Microsoft's
`dbt-fabricspark` adapter (Spark SQL + Delta via the Livy API). It is:

- the validation suite for the upstream PR adding the `fabricspark` adapter
  to datavault4dbt (fork: `peterampazzo/datavault4dbt`, branch
  `feature/fabricspark-support`, pulled by `packages.yml`);
- a reproducible CI target for the package maintainers;
- a reference for building a Data Vault on Fabric with this stack.

It is **not** a production vault. Data is a tiny TPC-H extract (`seeds/`),
loaded in two batches so incremental behaviour can be tested.

Not the same thing: `dbt-fabric` / Fabric **Warehouse** (T-SQL). datavault4dbt
already supports that as adapter `fabric`. This project is Lakehouse/Spark only.

## Data Vault in two minutes (as modelled here)

Data Vault 2.0 splits a warehouse into three kinds of raw-vault tables, loaded
insert-only from a hashed staging layer:

| Entity | Holds | Grain | Example here |
|---|---|---|---|
| **Hub** `*_h` | one row per business key | business key | `customer_h` (`c_custkey`) |
| **Link** `*_l` | one row per relationship between hubs | combination of hub keys (+ dependent child keys) | `customer_nation_l`, `order_line_l` |
| **Satellite** `*_s` | descriptive attributes and their history | parent hashkey + load timestamp | `customer_n_s` |

Everything hangs off hashes:

- `hk_<entity>`: **hashkey**, hash of the business key(s); the surrogate key.
- `hd_<satellite>`: **hashdiff**, hash of the payload; a new satellite row is
  inserted only when it changes.
- `ldts`: load timestamp (when the row arrived); `rsrc`: record source string.
- **Ghost records**: two synthetic rows per entity (`unknown`, `error`) with
  `ldts` = `0001-01-01` so PIT joins never lose a key. Expected counts in the
  README include them ("+2").

Layers in this project:

```
seeds (CSV)  ->  models/source (views, batch filter via var load_until)
             ->  models/stage  (datavault4dbt `stage`: hashes, ghost records, derived/prejoined cols)
             ->  models/raw_vault (hubs, links, satellites, reference tables, record tracking)
             ->  models/business_vault (snapshot control tables, PIT tables)
```

Variants you will meet (suffix conventions in `models/README.md`):
`_v0` = raw insert-only satellite, `_v1` = view adding end-dating /
`IS_CURRENT`; `_ma_s` multi-active; `_nh_l`/`_nh_s` non-historized (transactional);
`_es` effectivity satellite; `_rts` record-tracking; `_rh`/`_rs`/`_rt` reference
hub/satellite/table; `_ms` multi-source; `_ng` no ghost records; `_pit` point-in-time.

Loading contract to keep in mind when editing models:

- Raw vault is **incremental, append-only**. Hubs/links insert unseen keys;
  satellites insert rows whose hashdiff differs from the latest one per key.
- A **high-water mark (HWM)** on `ldts` filters stage rows already loaded.
  Rows arriving with an older `ldts` than the HWM are silently dropped.
  `disable_hwm: true` lets them in, but on satellites it is **not idempotent**
  (re-running reinserts earlier versions). Package behaviour, not Fabric.
- `rsrc_static` in multi-source hubs/links must equal the literal `rsrc` the
  stage actually writes (e.g. `seed/phone`), otherwise HWM logic breaks.

## Environment and how to run

Prereqs: Python 3.12, Azure CLI, access to a Fabric workspace with
schema-enabled Lakehouse(s). No workspace yet (or only a personal email)?
README "0. Provision a Fabric sandbox" covers the trial, the Entra user for
personal accounts, the tenant id and the Lakehouse settings that cannot be
changed later. Secrets live only in `.env` (gitignored).

```bash
cp .env.example .env              # fill in workspace / lakehouse ids and names
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt   # dbt-core 1.12.5, dbt-fabricspark[cli] 1.13.9
set -a; source .env; set +a
export DBT_PROFILES_DIR=.
az login --tenant <tenant-id> --allow-no-subscriptions
dbt deps && dbt debug
```

Targets (`profiles.yml`):

| target | layout | notes |
|---|---|---|
| `dev` | one Lakehouse, schema `dv_test` (`DEV_SCHEMA`) | `high_concurrency: true` |
| `multi` | seeds -> Bronze `raw`, source/stage -> Silver `dv_stage`, raw vault -> Silver `raw_vault`, business vault -> Gold `business_vault` | session bound to Silver; `high_concurrency: false` |

Standard two-batch gate (this is what "green" means, 95/95 on both):

```bash
dbt seed  --target multi
dbt build --target multi --full-refresh --exclude resource_type:seed --vars '{load_until: "2024-01-01 00:00:00"}'
dbt build --target multi                --exclude resource_type:seed --vars '{load_until: "2024-01-02 00:00:00"}'
```

Option toggles are env vars (see `.env.example`): `DV_HASH=SHA2`,
`DV_IBOBA`, `DV_EAL`, `DV_COPY_RSRC_LDTS`. Change-scenario switches are dbt
vars (`scn_*`) read by `src_customer`, `stg_customer`, `customer_h`,
`customer_n_s` and `macros/scenario_overrides.sql`; the README runbook lists
the exact commands and observed outcomes.

Fabric capability probes (QUALIFY, column mapping, DDL, timestamps) are
run-operations in `macros/probes.sql` (`probe_schema_setup`, `probe_version`,
`probe_qualify`, `probe_column_mapping`, `probe_drop_rename_column`, ...,
`probe_cleanup`), e.g. `dbt run-operation probe_qualify --target dev`. The
README lists the expected outcome of each.

## Rules for working here

1. **One Fabric run at a time per lakehouse set.** Two concurrent sessions
   (another terminal, another agent) corrupt each other's counts.
2. **Never commit** `.env`, `.user.yml`, `livy-session-id.txt*`,
   `package-lock.yml` (follows the fork branch head on purpose), `target/`, `logs/`.
3. **Cancel Livy sessions when done.** Lingering sessions eat trial capacity and
   cause HTTP 430 on the next run. `dbt` reuses the id in `livy-session-id.txt`;
   delete the file after cancelling.
4. **Views capture vars at creation time.** When you change a `scn_*` or
   `load_until` var, rebuild the upstream `source`/`stage` views too (select
   them explicitly or use `+model` graph selectors); selecting only the vault
   table reuses the stale view.
5. **Expected counts are derived from the seeds, not from a run.** When adding
   a model, write the count/no-dup test in `tests/` first, with the number
   worked out by hand, then run. Update the README count tables.
6. **Keep the package diff out of this repo.** If a run proves a defect, decide
   whether it is (a) Fabric SQL, (b) the adapter, (c) the package on all
   platforms, or (d) a usage error. Only (a) belongs in the fork branch, as a
   minimal copy-from-databricks change. (b) and (c) become separate issues
   upstream; (d) becomes a README note.
7. Adapter facts that are easy to get wrong: `spark_config.name` is required;
   the profile `schema` must differ from the lakehouse name on schema-enabled
   lakehouses; `+database: <LakehouseName>` renders `LH.schema.table` while the
   session stays bound to the target lakehouse; `{{ this }}` is fully qualified.

## Known limitations (do not "fix" them silently)

- Fabric Spark has no `QUALIFY` and rejects `DELETE ... WHERE x NOT IN (subquery)`;
  the fork handles both. `RENAME/DROP COLUMN` need Delta column mapping, which
  the rehash operations enable per table (may affect SQL endpoint / Direct Lake
  readability of that table).
- `dbt-fabricspark` refuses `on_schema_change: sync_all_columns` column drops
  and emits a bare `alter table` when the add list is empty
  (`macros/scenario_overrides.sql` demonstrates the Fabric-side fix).
- datavault4dbt `stage` with `sequence:` or `include_source_columns: false`
  plus ghost records fails on every adapter (ghost CTEs omit the columns);
  worked around in `stg_lineitem` and `stg_customer_slim`.
- A static `rsrc: '!literal'` needs a source without an `rsrc` column.
- `disable_hwm` on satellites is non-idempotent (see above).

## Where things are

| Path | Purpose |
|---|---|
| `README.md` | run instructions, results, multi-lakehouse layout, change scenarios, feature matrix, versions |
| `models/README.md` | how to read the models, naming, keys and time |
| `models/*/schema.yml` | column documentation and model descriptions |
| `tests/` | singular tests: `count_*`, `no_dup_*`, `eq_*`, `hash_length_*`, PIT relationships |
| `macros/probes.sql` | Fabric capability probes |
| `macros/scenario_overrides.sql` | opt-in adapter override for the Delta DROP COLUMN scenario |
| `packages.yml` | datavault4dbt source (fork branch now; switch to the released package after merge) |
| `dbt_project.yml` | datavault4dbt global vars with `fabricspark` keys; per-target database/schema routing |
