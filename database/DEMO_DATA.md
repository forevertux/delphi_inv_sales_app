# Demo data (SQLite)

## What gets loaded

- **2 branches** (Bucharest, Cluj)
- **6 categories** (Electronics, Clothing, Food, Office, Home, General)
- **4 users** (see passwords below)
- **20 products** (`DEMO001` … `DEMO020`) with varied stock (including low/out of stock)
- **8 sample sales** with line items (for Reports / Dashboard)

## Demo logins

| User     | Password     | Role      |
|----------|--------------|-----------|
| admin    | Admin@123    | Admin     |
| manager  | Manager@123  | Manager   |
| employee | Employee@123 | Employee  |
| employee2| Employee@123 | Employee (Cluj) |

## Automatic load

On startup, if demo data was not loaded yet, the app runs `demo_data_sqlite.sql` automatically (SQLite only).

## Manual load (admin)

Dashboard → **Load Demo Data** (visible when logged in as admin).

## Deploy files (required)

Copy the `database` folder next to your EXE, for example:

```
Win32\Debug\
  InventorySales.exe
  database\
    schema_sqlite.sql
    demo_data_sqlite.sql
```

## Fresh database

To reset everything and reload schema + demo:

1. Close the app
2. Delete `data\inventory.db` (path from `InventorySales.ini`)
3. Start the app again

## Reload demo only

Use **Load Demo Data** on the dashboard (admin). This replaces demo products/sales and keeps your schema.
