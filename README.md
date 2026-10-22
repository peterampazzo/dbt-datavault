# datavault4dbt — Fabric Lakehouse (dbt-fabricspark) test project

Standalone dbt project used to validate the `fabricspark` platform support in
[datavault4dbt](https://github.com/ScalefreeCOM/datavault4dbt) against a real
Microsoft Fabric Lakehouse via the Livy API.

The package under test is pulled from the fork branch
`peterampazzo/datavault4dbt@feature/fabricspark-support` (see `packages.yml`);
for local development against a sibling checkout, switch to `local: ../datavault4dbt`.

## How to run

```bash
# 1. Fill in your Fabric ids
cp .env.example .env   # then edit .env

# 2. Load environment + venv
set -a; source .env; set +a
source .venv/bin/activate
export DBT_PROFILES_DIR=.

# 3. Azure CLI login (needed for `authentication: CLI`)
#    Fabric trial tenants have no Azure subscription and personal accounts
#    live in their own tenant: pass the tenant id explicitly.
#    Tenant id: Fabric portal -> ? (Help) -> About Fabric -> Tenant URL (?ctid=...)
az login --tenant <tenant-id> --allow-no-subscriptions
az account get-access-token --resource https://api.fabric.microsoft.com --query expiresOn

# 4. Install the package and check the connection
dbt deps
dbt debug
```

`profiles.yml` lives in the repo root, hence `DBT_PROFILES_DIR=.`.
The `dev` target uses `method: livy` + `authentication: CLI` against a
schema-enabled Lakehouse (`schema: dv_test`, different from the lakehouse name —
required by the adapter to infer schema-enabled mode at parse time).

## Fabric capability probes

Run via `dbt run-operation` against the schema-enabled Lakehouse (`Lakehouse`,
schema `dv_test`) on 2026-10-22. Probe macros live in `macros/probes.sql`
(`probe_schema_setup`, `probe_version`, `probe_qualify`, `probe_qualify_cte`,
`probe_column_mapping`, `probe_drop_rename_column`, `probe_nocm_drop_only`,
`probe_functions`, `probe_casing`, `probe_cleanup`).

**dbt debug:** all checks passed (profile + project valid, `connection ok`,
Livy session start ~30s).

**Runtime:** `SELECT version()` → `4.1.1 871477cdf7e6486245912fc4bec81d05b46e9761`
(Fabric Spark, Delta Lake). `SET spark.databricks.delta.properties.defaults.columnMapping.mode`
→ `<undefined>` (column mapping NOT on by default).

| Probe | Statement | Result | Notes / exact error |
| --- | --- | --- | --- |
| QUALIFY | `SELECT * FROM dv_test.probe_q QUALIFY ROW_NUMBER() OVER (PARTITION BY hk ORDER BY ldts) = 1` | **FAIL** | `[PARSE_SYNTAX_ERROR] Syntax error at or near 'ROW_NUMBER'. SQLSTATE: 42601 (line 1, pos 38)` — QUALIFY must be rewritten as a `ROW_NUMBER() ... AS rn` + `WHERE rn = 1` CTE (postgres pattern). |
| ROW_NUMBER CTE | `WITH probe_q_prep AS (SELECT ..., ROW_NUMBER() OVER (...) AS rn FROM ...) SELECT ... WHERE rn = 1` | PASS | Returns expected 2 rows — the postgres-style fallback works on Fabric Spark. |
| Column mapping | `ALTER TABLE dv_test.probe_cm SET TBLPROPERTIES ('delta.columnMapping.mode'='name','delta.minReaderVersion'='2','delta.minWriterVersion'='5')` | PASS | Accepted on a Delta table. |
| Add column | `ALTER TABLE ... ADD COLUMNS (new_col STRING)` | PASS | |
| Rename column (mapped) | `ALTER TABLE ... RENAME COLUMN new_col TO renamed_col` | PASS | |
| Drop column (mapped) | `ALTER TABLE ... DROP COLUMN renamed_col` | PASS | |
| Drop missing column | `ALTER TABLE ... DROP COLUMN IF EXISTS does_not_exist` | PASS | `IF EXISTS` supported. |
| Rename column (unmapped) | `ALTER TABLE dv_test.probe_nocm RENAME COLUMN extra_col TO renamed_col` | **FAIL** | `[DELTA_UNSUPPORTED_RENAME_COLUMN] Column rename is not supported for your Delta table. Please enable Column Mapping ... requires at least protocol (2, 5)` — column mapping IS required for rename on Fabric. |
| Drop column (unmapped) | `ALTER TABLE dv_test.probe_nocm DROP COLUMN extra_col` | **FAIL** | `[DELTA_UNSUPPORTED_DROP_COLUMN] DROP COLUMN is not supported ... enable Column Mapping ... protocol (2, 5)` — same requirement. |
| Functions | `current_timestamp()`, `md5`, `sha2(…,256)`, `CAST(1 AS STRING)`, `upper(trim())`, `concat_ws`, `to_date('0001-01-01')` | PASS | All return expected values. `to_date` gives `0001-01-01`. |
| Year-0001 timestamp | `TO_TIMESTAMP('0001-01-01 00:00:01','yyyy-MM-dd HH:mm:ss')` | PASS (display artifact only) | Inline Livy result displays `0000-12-30T00:00:01Z` (Julian→Gregorian rebase in result serialization), BUT once stored in a Delta table it round-trips correctly: `probe_ts` returns `eq=True`, `fmt=0001-01-01 00:00:01`, `CAST AS STRING=0001-01-01 00:00:01` (see `probe_ts` below). Ghost-record `beginning_of_all_times` of `0001-01-01` is SAFE as a TIMESTAMP. |
| Casing | `CREATE TABLE dv_test.probe_case (MixedCase INT, lower_case INT)` + `DESCRIBE` | PASS | `DESCRIBE` reports `MixedCase int`, `lower_case int` — casing preserved in metastore. `SELECT MixedCase`, `` SELECT `MixedCase` ``, and `SELECT mixedcase` ALL succeed (Spark resolves case-insensitively by default). |

**Known limitation hit during probing:** each `dbt run-operation` starts a new
Fabric high-concurrency (HC) session; on the trial capacity this quickly hits
`[TooManyRequestsForCapacity] HTTP 430` ("spark overall capacity compute
limit"). `retry_all` retries did not help (session create itself fails).
Workaround: space out runs / wait ~10 min for HC sessions to idle out, or ask
capacity admin to cancel jobs in the Monitoring hub. `high_concurrency: false`
fell back to a plain Livy session but failed with the opaque "cannot create a
livy session" while capacity was saturated.

**Rehash implication:** `delta.columnMapping.mode` is NOT enabled by default
(SET … = `<undefined>`), and RENAME/DROP COLUMN both require it — so the
databricks rehash macros' `SET TBLPROPERTIES ('delta.columnMapping.mode'='name')`
is *required* on Fabric, not optional. Caveat remains: column mapping can break
the SQL analytics endpoint for that table.

## Test project structure

Seeds (`seeds/`, explicit `column_types` in `seeds/schema.yml`) carry `ldts`
+ `rsrc` and two batches: `2024-01-01 00:00:00` and `2024-01-02 00:00:00`.

- `nation.csv` — 5 nations; batch 2 changes `n_comment` of germany.
- `customer.csv` — batch 1: 8 customers; batch 2: 5 unchanged, #6 new
  `c_address`, #7 new `c_nationkey` (link/effectivity change), #8 removed,
  #9 new.
- `orders.csv` — 10 orders batch 1, +3 (111–113) batch 2; immutable for
  nh_link/nh_sat.
- `customer_phone.csv` — 9 phone rows over customers 1–4; batch 2 adds
  `fax` for customer 1 (multi-active).
- `ref_currency.csv` — 4 currencies; batch 2 renames EUR and adds CHF.

`models/source/src_<seed>.sql` views filter
`ldts <= TIMESTAMP '{{ var("load_until", "2024-01-02 00:00:00") }}'` so the same
seeds simulate batch 1 and batch 2. `src_nation_latest` is a dedup helper view
used by the `prejoined_columns` join in `stg_customer` (joining an undeduped
source would multiply rows across batches).

Stage views (`models/stage/`): `stg_nation`, `stg_customer` (hashkeys
`hk_customer_h`, `hk_nation_h`, `hk_customer_nation_l`, hashdiff
`hd_customer_n_s`, derived column `country_code`, prejoin of `n_name`),
`stg_orders` (`hk_order_h`, `hk_customer_h`, `hk_order_nh_l`,
`hd_order_nh_s`), `stg_customer_phone` (`multi_active_config` on
`phone_type`, `hd_customer_phone_ma_s`), `stg_ref_currency`
(`hd_currency_rs`). Ghost records on (default).

Raw vault (`models/raw_vault/`): `nation_h`, `customer_h` (multi-source hub:
`stg_customer` + `stg_orders`, `bk_columns: [o_custkey]` on orders),
`customer_nation_l`, `order_nh_l`, `customer_n_s`, `customer_n_s_v1`,
`customer_phone_ma_s`, `customer_phone_ma_s_v1`, `order_nh_s`,
`customer_nation_es` (`source_is_single_batch: false` — required param),
`customer_rts`, `currency_rh`, `currency_rs`, `currency_rs_v1`,
`currency_rt`, `control_snap_v0` (start 2024-01-01, daily 00:00:00),
`control_snap_v1`, `customer_pit` (post-hook `clean_up_pit`).

> **`rsrc_static` note:** for multi-source entities the value must be a `LIKE`
> pattern matching the *stage's* `rsrc` values — it is used to look up the
> per-source high-water mark inside the target table, not injected as the
> stored `rsrc`. Using arbitrary strings (e.g. `TPC_H.Customer` while the stage
> emits `seed/customer`) silently yields an empty HWM lookup and the incremental
> run inserts nothing.

Tests: `models/raw_vault/schema.yml` (`unique` + `not_null` on all hub/link
hashkeys) + singular tests in `tests/` (`no_dup_*` uniqueness on
(hashkey, ldts), `count_*` row-count assertions parameterized on
`var("load_until")`).

### Expected row counts (incl. 2 ghost rows)

| Model | batch 1 | batch 2 | Notes |
| --- | --- | --- | --- |
| nation_h | 7 | 7 | 5 + 2 ghost |
| customer_h | 10 | 11 | 8/9 business + 2 ghost; #9 arrives via both sources |
| customer_nation_l | 10 | 12 | +1 changed nation (#7), +1 new customer |
| order_nh_l | 12 | 15 | 10/13 orders + 2 ghost |
| customer_n_s | 10 | 13 | +2 changed (#6 address, #7 nation), +1 new (#9) |
| customer_phone_ma_s | 11 | 15 | cust-1's 4 phones re-insert at batch 2 (set-level hashdiff changes when `fax` is added) |
| order_nh_s | 12 | 15 | nh_sat on immutable orders |
| customer_nation_es | 10* | 12 | eff sat: #7 old link deactivated, new link activated, #8 deactivated, #9 activated |
| currency_rh | 6 | 7 | 4/5 + 2 ghost |
| currency_rs | 6 | 8 | +1 changed (EUR), +1 new (CHF) |
| customer_rts | 22* | 27 | appearance tracking over both sources |
| customer_pit | — | ~1600 | pointer rows over control_snap_v1 windows |
| control_snap_v0 | 1026 | 1026 | daily snapshots from 2024-01-01 |

\* inferred from seed data, not directly asserted by a test.

## Run results (2026-10-22)

Environment: venv, `set -a; source .env; set +a`, `DBT_PROFILES_DIR=.`,
`DBT_FABRICSPARK_SKIP_OPTIMIZE=1`.

```bash
dbt parse          # PASS (0 errors)
dbt seed           # PASS=5  (customer 16, customer_phone 19, nation 10,
                   #          orders 13, ref_currency 9)
dbt build --vars '{load_until: "2024-01-01 00:00:00"}' --exclude resource_type:seed
                   # PASS=51 WARN=0 ERROR=0 SKIP=0 TOTAL=51
dbt build --vars '{load_until: "2024-01-02 00:00:00"}' --exclude resource_type:seed
                   # PASS=51 WARN=0 ERROR=0 SKIP=0 TOTAL=51
dbt run-operation rehash_single_hub --args '{hub: customer_h, hashkey: hk_customer_h, business_keys: c_custkey, overwrite_hash_values: true}'
                   # PASS — column mapping enabled, MERGE, rename OK
dbt run-operation rehash_single_satellite --args '{satellite: customer_n_s, hashkey: hk_customer_h, hashdiff: hd_customer_n_s, payload: [c_address, c_phone, c_acctbal, c_mktsegment, c_comment, c_nationkey], parent_entity: customer_h, business_keys: c_custkey, overwrite_hash_values: true}'
                   # PASS — column mapping, ALTER ADD, MERGE, overwrite, drop OK
dbt run-operation probe_ts
                   # eq=True fmt=0001-01-01 00:00:01 s=0001-01-01 00:00:01
                   # ghost ldts: SYSTEM=0001-01-01 00:00:01, ERROR=8888-12-31 23:59:59
                   # -> year-0001 TIMESTAMPs round-trip correctly when stored;
                   #    the earlier 0000-12-30 was a Livy display artifact.
```

Failures fixed along the way:

1. `stg_customer` — `'dict object' has no attribute 'aliases'`: used the
   list form of `prejoined_columns`; fixed by using the documented dict form
   (`<name>: {ref_model, bk, this_column_name, ref_column_name}`) and pointing
   it at a deduped `src_nation_latest` view.
2. `currency_rt` — `UNRESOLVED_COLUMN s_1.ledts`: `ref_table`'s
   `ref_satellites` must reference the **v1** satellite (`currency_rs_v1`),
   which carries `ledts`, not the v0 table.
3. `customer_pit` post-hook — `[DELTA_UNSUPPORTED_SUBQUERY] Subqueries are not
   supported in the DELETE`: **fork fix** —
   `fabricspark__clean_up_pit` in `macros/hooks/clean_up_pits.sql` now emits a
   single `MERGE INTO <pit> USING (SELECT sdts FROM <snapshot_relation> WHERE
   is_active) active_snapshots ON pit.sdts = active_snapshots.sdts WHEN NOT
   MATCHED BY SOURCE THEN DELETE` instead of `DELETE ... WHERE sdts NOT IN
   (subquery)`. Same semantics, single statement, no subquery in DELETE.
   Verified: `dbt build --select customer_pit` PASS, Livy returned
   `num_deleted_rows=0` (all snapshots still active), row count unchanged at
   1760.
4. `customer_h` batch-2 incremental inserted nothing: `rsrc_static` values
   didn't match stage `rsrc` values (see note above). Test-project fix.

### Capacity notes

Fabric trial capacity is exhausted by lingering HC sessions
(`[TooManyRequestsForCapacity] HTTP 430` at session create). The adapter does
not always close them; list sessions via
`GET /v1/workspaces/{ws}/lakehouses/{lh}/livySessions` and cancel stale ones
via `POST /v1/workspaces/{ws}/items/{lh}/jobs/instances/{jobInstanceId}/cancel`
(HTTP 202). After cancelling, builds proceed normally.

## Multi-lakehouse layout (target `multi`)

A second profile target `multi` spreads the project across three lakehouses in
the same workspace. The Spark session stays bound to the profile lakehouse
(LH_Silver); `+database` on folders redirects objects cross-lakehouse. All
three lakehouses are schema-enabled (`properties.defaultSchema: dbo` via
`GET /v1/workspaces/{ws}/lakehouses/{id}`).

| Folder / resource | dev | multi |
| --- | --- | --- |
| seeds | Lakehouse.dv_test | LH_Bronze.raw |
| models/source | Lakehouse.dv_test | LH_Silver.dv_stage |
| models/stage | Lakehouse.dv_test | LH_Silver.dv_stage |
| models/raw_vault | Lakehouse.dv_test | LH_Silver.raw_vault |
| models/business_vault (control_snap_v0/v1, customer_pit) | Lakehouse.dv_test | LH_Gold.business_vault |

Config is expressed as target-conditional Jinja in `dbt_project.yml`, e.g.
`+database: "{{ env_var('FABRIC_SILVER_LAKEHOUSE_NAME') if target.name == 'multi' else target.lakehouse }}"`
and `+schema: "{{ 'raw_vault' if target.name == 'multi' else target.schema }}"`.
Jinja in `dbt_project.yml` `+database`/`+schema` worked fine (no per-model
fallback needed). New env vars: `FABRIC_{BRONZE,SILVER,GOLD}_LAKEHOUSE_{ID,NAME}`.

Adapter behaviour discovered (`dbt-fabricspark` 1.13.7):

- `generate_database_name` returns `config.database` when set, else
  `target.lakehouse` — so `+database: LH_X` renders `LH_X.<schema>.<table>`
  while the session remains bound to the profile lakehouse.
- `generate_schema_name` is lakehouse-aware: **when a node sets `database`,
  the custom schema is used verbatim (NO `<target>_<custom>` concatenation)**;
  when `database` is not set it falls back to default dbt
  `generate_schema_name_for_env` behaviour. No `generate_schema_name`
  override was needed.
- Schemas are auto-created (`CREATE DATABASE IF NOT EXISTS lakehouse.schema`)
  on livy — `raw`, `dv_stage`, `raw_vault`, `business_vault` were created
  implicitly in the remote lakehouses.
- Cross-lakehouse reads (Silver `src_*`/`stg_*` views reading `LH_Bronze.raw.*`
  seeds) and cross-lakehouse DDL in run-operations (rehash on
  `LH_Silver.raw_vault.*`) both work from the Silver-bound session.
- The `clean_up_pit` post-hook resolved `{{ this }}` correctly to
  `LH_Gold`.`business_vault`.customer_pit` — log evidence:
  `MERGE INTO LH_Gold.business_vault.customer_pit pit USING (SELECT sdts FROM
  LH_Gold.business_vault.control_snap_v1 ...)`.
- `high_concurrency: false` + `reuse_session: true` persists the session to
  `livy-session-id.txt` and all commands reused it
  ("Reused existing Fabric session from file") — no per-command session churn.

### multi run results (2026-10-22)

```bash
dbt parse --target multi        # PASS
dbt ls   --target multi --resource-type model --resource-type seed \
         --output json --output-keys name database schema
dbt seed --target multi         # PASS=5 (16/19/10/13/9 rows -> LH_Bronze.raw)
dbt build --target multi --exclude resource_type:seed \
    --vars '{load_until: "2024-01-01 00:00:00"}'   # PASS=51 ERROR=0
dbt build --target multi --exclude resource_type:seed \
    --vars '{load_until: "2024-01-02 00:00:00"}'   # PASS=51 ERROR=0
dbt run-operation --target multi rehash_single_hub \
    --args '{hub: customer_h, hashkey: hk_customer_h, business_keys: c_custkey, overwrite_hash_values: true}'         # PASS
dbt run-operation --target multi rehash_single_satellite \
    --args '{satellite: customer_n_s, ...}'                                                                        # PASS
dbt run-operation --target multi rehash_single_hub \
    --args '{hub: nation_h, hashkey: hk_nation_h, business_keys: n_nationkey, overwrite_hash_values: true}'          # PASS
dbt run-operation --target multi probe_placement
```

`dbt ls --target multi` placement (name / database / schema):

```
control_snap_v0/1, customer_pit            LH_Gold    business_vault
raw_vault models (hubs, links, sats, refs) LH_Silver  raw_vault
src_*/stg_* views                          LH_Silver  dv_stage
seeds                                      LH_Bronze  raw
```

`SHOW TABLES` output (`probe_placement`):

```
-- LH_Bronze.raw --            customer, customer_phone, nation, orders, ref_currency
-- LH_Silver.dv_stage --       src_* x6, stg_* x5
-- LH_Silver.raw_vault --      all 15 raw-vault entities
-- LH_Gold.business_vault --   control_snap_v0, control_snap_v1, customer_pit
```

Nothing landed in the wrong lakehouse; `dev` target still renders everything
to `Lakehouse.dv_test` (verified via `dbt ls --target dev`: all nodes
database=Lakehouse, schema=dv_test).

## Versions

- dbt-core: 1.12.5
- dbt-fabricspark: 1.13.7 (installed with the `cli` extra)
- Python: 3.12
