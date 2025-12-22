# LogiTrack Database Setup Guide

## Quick Setup (Recommended)

### Step 1: Create Oracle User

Run as SYSTEM or SYS user:

```bash
cd database
sqlplus system/password@database @create_user.sql
```

Or in SQL*Plus:
```sql
-- Connect as SYSTEM
sqlplus system/password@database

-- Run user creation script
@create_user.sql
```

**Default credentials created:**
- Username: `logitrack`
- Password: `logitrack123`

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

### Step 3: Configure Backend

Update `backend/.env` file:

```env
DB_HOST=localhost
DB_PORT=1521
DB_SERVICE=ORCL
DB_USER=logitrack
DB_PASSWORD=logitrack123
SESSION_SECRET=your_secret_key_change_in_production
PORT=5000
```

## Custom User Credentials

If you want to use different credentials, edit `create_user.sql`:

```sql
-- Change username
CREATE USER your_username IDENTIFIED BY your_password;

-- Update all references from 'logitrack' to 'your_username'
```

Then update `backend/.env` accordingly.

## Verification

After installation, verify everything works:

```sql
-- Connect as logitrack
sqlplus logitrack/logitrack123@database

-- Check tables
SELECT COUNT(*) FROM user_tables;
-- Should return 8

-- Check package
SELECT object_name FROM user_objects WHERE object_type = 'PACKAGE';
-- Should show PKG_LOGITRACK

-- Check test users
SELECT nom_utilisateur, role FROM utilisateurs;
-- Should show: admin, gest1, liv1
```

## Troubleshooting

### "User already exists"
If the user already exists, you can either:
1. Drop and recreate: Uncomment the DROP USER line in `create_user.sql`
2. Use existing user: Skip Step 1 and go directly to Step 2

### "Insufficient privileges"
Make sure you're running `create_user.sql` as SYSTEM or SYS user.

### "Table or view does not exist"
Make sure you ran `install.sql` after creating the user.

## Complete Setup Order

1. ✅ Create user: `@create_user.sql` (as SYSTEM)
2. ✅ Install schema: `@install.sql` (as logitrack)
3. ✅ Configure backend: Update `backend/.env`
4. ✅ Install dependencies: `npm install` in backend and frontend
5. ✅ Start backend: `npm start` in backend folder
6. ✅ Start frontend: `npm start` in frontend folder

## Test Accounts

After installation, you can login to the application with:

| Role | Username | Password |
|------|----------|----------|
| Admin | `admin` | `admin123` |
| Gestionnaire | `gest1` | `gest123` |
| Livreur | `liv1` | `liv123` |



