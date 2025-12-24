hey

# LogiTrack - Logistics Management System

A full-stack web application for managing logistics and deliveries with role-based access control.

## Tech Stack

- **Frontend**: React 18, Tailwind CSS, React Router
- **Backend**: Node.js, Express.js
- **Database**: Oracle Database
- **Authentication**: Express-session (server-side sessions)

## Project Structure

```
oracle_cursor/
├── backend/          # Express.js API server
├── frontend/         # React application
└── README.md
```

## Setup Instructions

### Prerequisites

- Node.js (v14 or higher)
- Oracle Database with the provided schema
- Oracle Instant Client (for oracledb package)

### Backend Setup

1. Navigate to the backend directory:
```bash
cd backend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the backend directory:
```env
DB_HOST=localhost
DB_PORT=1521
DB_SERVICE=ORCL
DB_USER=your_username
DB_PASSWORD=your_password
SESSION_SECRET=your_secret_key_change_in_production
PORT=5000
```

4. Start the server:
```bash
npm start
# or for development with auto-reload:
npm run dev
```

The backend server will run on `http://localhost:5000`

### Frontend Setup

1. Navigate to the frontend directory:
```bash
cd frontend
```

2. Install dependencies:
```bash
npm install
```

3. Create a `.env` file in the frontend directory:
```env
REACT_APP_API_URL=http://localhost:5000/api
```

4. Start the development server:
```bash
npm start
```

The frontend will run on `http://localhost:3000`

## Database Setup

All database scripts are located in the `database/` folder.

### Quick Installation (2 Steps)

**Step 1: Create User** (Run as SYSTEM/SYS)
```bash
cd database
sqlplus system/password@database @create_user.sql
```

**Step 2: Install Schema** (Run as logitrack user)
```bash
sqlplus logitrack/logitrack123@database @install.sql
```

This will automatically:
1. Create user `logitrack` with all privileges
2. Create sequences
3. Create tables
4. Create triggers
5. Create package (pkg_logitrack)
6. Create views
7. Insert test data

**Default credentials:**
- Database user: `logitrack` / `logitrack123`
- App login: `admin` / `admin123`

For detailed instructions, see [database/README.md](database/README.md)

## Default Test Accounts

After running the database setup script, you can login with:

- **Admin**: username: `admin`, password: `admin123`
- **Gestionnaire**: username: `gest1`, password: `gest123`
- **Livreur**: username: `liv1`, password: `liv123`

## Features

### Admin Role
- View KPIs dashboard
- Manage users (create, update, activate/deactivate)
- Manage clients
- Manage entrepots

### Gestionnaire Role
- View colis statistics
- Add and manage colis
- Change colis status
- Mark colis as recovered
- Manage clients

### Livreur Role
- View assigned livraisons
- Take available livraisons
- Deliver livraisons
- View delivery statistics

## API Endpoints

### Authentication
- `POST /api/auth/login` - Login
- `POST /api/auth/logout` - Logout
- `GET /api/auth/me` - Get current user

### Admin
- `GET /api/admin/kpis` - Get KPIs
- `GET /api/admin/users` - List users
- `POST /api/admin/users` - Create user
- `PUT /api/admin/users/:id` - Update user
- `GET /api/admin/clients` - List clients
- `POST /api/admin/clients` - Create client
- `GET /api/admin/entrepots` - List entrepots
- `POST /api/admin/entrepots` - Create entrepot

### Gestionnaire
- `GET /api/gestionnaire/colis` - List colis
- `POST /api/gestionnaire/colis` - Add colis
- `PUT /api/gestionnaire/colis/:id/statut` - Update colis status
- `POST /api/gestionnaire/colis/recuperer` - Mark colis as recovered
- `GET /api/gestionnaire/clients` - List clients
- `POST /api/gestionnaire/clients` - Create client
- `GET /api/gestionnaire/entrepots` - List entrepots

### Livreur
- `GET /api/livreur/livraisons/disponibles` - List available livraisons
- `POST /api/livreur/livraisons/:id/prendre` - Take livraison
- `GET /api/livreur/livraisons/mes-livraisons` - List my livraisons
- `POST /api/livreur/livraisons/:id/livrer` - Deliver livraison
- `GET /api/livreur/vehicules` - List available vehicles

## Notes

- All business logic is handled by Oracle database (triggers and packages)
- The backend acts as a thin API layer
- Session-based authentication is used
- CORS is configured for development (localhost:3000)

## License

This project is for academic/demonstration purposes.

