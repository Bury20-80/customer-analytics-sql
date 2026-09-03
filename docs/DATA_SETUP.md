# Data Setup

## Dataset snapshot

This project uses a local PostgreSQL copy of the **Contoso 100K** dataset family.
The public Contoso Data Generator V2 repository is maintained by SQLBI:

`https://github.com/sql-bi/Contoso-Data-Generator-V2-Data`

The raw files are not redistributed in this repository. The analyzed snapshot is
identified by the following QA fingerprint:

- sales lines: 199,873
- distinct orders: 83,130
- purchasing customers: 49,487
- customer dimension rows: 104,990
- order dates: 2015-01-01 through 2024-04-20

If a different Contoso release is loaded, results can differ.

## Required PostgreSQL tables and columns

The analysis expects these existing tables:

```text
sales
  orderkey      integer/bigint
  customerkey   integer/bigint
  productkey    integer/bigint
  orderdate     date
  quantity      integer/numeric
  netprice      numeric
  unitcost      numeric
  exchangerate  numeric

customer
  customerkey   integer/bigint

product
  productkey    integer/bigint
  categoryname  text
```

Additional source columns are allowed but are not required by this project.

## Import process

If the Contoso tables already exist in PostgreSQL, no raw reload is required.
For a fresh CSV-based setup:

1. Create `sales`, `customer`, and `product` tables using types compatible with the columns above.
2. Import the matching Contoso CSV files with pgAdmin Import/Export or PostgreSQL `\copy`.
3. Normalize source column names to the lowercase names expected by the SQL files if your distribution uses different casing.
4. Run `sql/validation/01_raw_data_audit.sql` before creating analytical views.

The raw files are intentionally not committed to this repository.

## Database connection

Python reads connection settings from environment variables. Copy `.env.example`
to `.env` at the project root and set your local password, or leave `DB_PASSWORD`
unset to be prompted securely when a notebook connects.

```text
DB_HOST      default: localhost
DB_PORT      default: 5432
DB_NAME      default: contoso_100k
DB_USER      default: postgres
DB_PASSWORD  prompted securely if not set
```

The real `.env` file is ignored by Git; `.env.example` contains placeholders only.

## Execution order

1. Load the raw `sales`, `customer`, and `product` tables into PostgreSQL.
2. Run `sql/validation/01_raw_data_audit.sql` and resolve any non-zero issue counts.
3. Run, in order:
   - `sql/intermediate/01_fact_orders.sql`
   - `sql/intermediate/02_customer_metrics.sql`
   - `sql/intermediate/03_repeat_purchase_intervals.sql`
4. Run `sql/validation/02_order_grain_audit.sql`.
5. Run the SQL files in `sql/marts/` as needed.
6. Copy `.env.example` to `.env` and set the local PostgreSQL credentials if needed.
7. Create a Python environment and install `requirements.txt`.
8. Run notebooks in numerical order from `python/notebooks/`.

The first notebook performs assertions on grain, revenue reconciliation, foreign
keys, RFM ties, and purchase intervals before the presentation notebooks are used.
