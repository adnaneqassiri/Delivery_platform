# Quick Start Guide

## 🚀 Fast Setup (3 Steps)

### 1️⃣ Create User (Run as SYSTEM/SYS)

```bash
cd database
sqlplus system/password@database @create_user.sql
```

**Creates:**
- User: `logitrack`
- Password: `logitrack123`

### 2️⃣ Install Database (Run as logitrack)

```bash
sqlplus logitrack/logitrack123@database @install.sql
```

**Installs:**
- All tables, sequences, triggers
- Package with business logic
- Views for reporting
- Test data

### 3️⃣ Configure Backend

Edit `backend/.env`:

```env
DB_USER=logitrack
DB_PASSWORD=logitrack123
```

## ✅ Done!

Now you can:
- Start backend: `cd backend && npm start`
- Start frontend: `cd frontend && npm start`
- Login with: `admin` / `admin123`

## 📝 Notes

- User creation only needs to be done once
- If user exists, skip Step 1
- All scripts use consistent naming: `logitrack` user, `PKG_LOGITRACK` package



