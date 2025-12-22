# LogiTrack Database Scripts

This folder contains all SQL scripts needed to set up the LogiTrack database.

## Scripts Overview

| Script | Description |
|--------|-------------|
| `create_user.sql` | **First!** Creates Oracle user with privileges (run as SYSTEM) |
| `00_drop_all.sql` | Drops all database objects (use to start fresh) |
| `01_sequences.sql` | Creates all sequences for auto-increment IDs |
| `02_tables.sql` | Creates all tables with constraints |
| `03_triggers.sql` | Creates all triggers (auto-ID, price calculation, status updates) |
| `04_package.sql` | Creates the `pkg_logitrack` package (spec and body) |
| `05_views.sql` | Creates all views (KPI dashboard, details views) |
| `06_test_data.sql` | Inserts test data (users, entrepots, clients, colis) |
| `install.sql` | **Master script** - runs all scripts in order |

## Quick Start

### Step 1: Create Oracle User (First Time Only)

Run as SYSTEM or SYS user:

```bash
sqlplus system/password@database @create_user.sql
```

This creates user `logitrack` with password `logitrack123`.

### Step 2: Install Database Schema

Connect as the new user and run installation:

```bash
sqlplus logitrack/logitrack123@database @install.sql
```

Or in SQL*Plus:
```sql
-- Connect as logitrack
sqlplus logitrack/logitrack123@database

-- Run installation
@install.sql
```

This will run all scripts in the correct order.

### Option 2: Install Step by Step

If you prefer to run scripts individually:

```sql
@01_sequences.sql
@02_tables.sql
@03_triggers.sql
@04_package.sql
@05_views.sql
@06_test_data.sql
```

### Option 3: Fresh Start

If you need to drop everything and start fresh:

```sql
@00_drop_all.sql
@install.sql
```

## Installation Order

The scripts **must** be run in this order:

1. **Sequences** - Required for auto-increment IDs
2. **Tables** - Creates the database structure
3. **Triggers** - Adds business logic triggers
4. **Package** - Creates stored procedures
5. **Views** - Creates reporting views
6. **Test Data** - Inserts sample data

## Test Accounts

After running `06_test_data.sql`, you can login with:

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `admin123` |
| Gestionnaire | `gest1` | `gest123` |
| Livreur | `liv1` | `liv123` |

## Database Objects Created

### Sequences (8)
- `seq_utilisateurs`
- `seq_entrepots`
- `seq_vehicules`
- `seq_clients`
- `seq_livraisons`
- `seq_colis`
- `seq_hist_colis`
- `seq_hist_liv`

### Tables (8)
- `utilisateurs` - Users with roles
- `entrepots` - Warehouses
- `vehicules` - Vehicles
- `clients` - Clients
- `livraisons` - Deliveries
- `colis` - Packages
- `historique_statut_colis` - Package status history
- `historique_statut_livraisons` - Delivery status history

### Triggers (11)
- Auto-ID triggers (8)
- Price calculation and auto-assignment trigger
- Cancellation trigger
- Delivery departure trigger
- Delivery arrival trigger

### Package
- `pkg_logitrack` - Contains all business logic procedures

### Views (4)
- `v_livraisons_details` - Detailed delivery information
- `v_colis_details` - Detailed package information
- `v_vehicules_entrepots` - Vehicle and warehouse info
- `v_kpi_dashboard` - KPI metrics

## Troubleshooting

### Error: "table or view does not exist"
- Make sure you ran scripts in order
- Check that previous scripts completed successfully

### Error: "sequence does not exist"
- Run `01_sequences.sql` first

### Error: "package body does not exist"
- Make sure `04_package.sql` ran successfully
- The package spec must be created before the body

### Error: "constraint violation"
- You may be trying to insert duplicate data
- Use `00_drop_all.sql` to start fresh

## Notes

- All scripts include `COMMIT` statements
- Scripts use `PROMPT` for user feedback
- The installation is idempotent (can be run multiple times if you drop first)
- Test data includes sample entrepots, vehicles, clients, and colis

## Requirements

- Oracle Database 12c or higher
- SQL*Plus or SQL Developer
- Sufficient privileges to create tables, sequences, triggers, packages, and views

