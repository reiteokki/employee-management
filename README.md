# Employee Management - Monorepo

## 📂 Project Structure

- **`backend/`** → Node.js Express API
- **`frontend/`** → Flutter app
- **`database/`** → MySQL schema + seed data

---

## ⚙️ Requirements

Make sure you have installed:

- [Node.js](https://nodejs.org/) (LTS version recommended)
- [Flutter](https://docs.flutter.dev/get-started/install) (latest stable)
- [MySQL](https://dev.mysql.com/downloads/)
- [Git](https://git-scm.com/)

---

## 🗄 Database Setup

1. Start your MySQL server.

2. Create a new database:

   ```sql
   CREATE DATABASE organization_db;
   ```

3. Import schema and seed data:

   ```bash
   mysql -u root -p organization_db < database/schema.sql
   mysql -u root -p organization_db < database/seed.sql
   ```

4. Verify tables:

   ```sql
   USE organization_db;
   SHOW TABLES;
   ```

---

## 🔙 Backend (Express API)

1. Navigate to backend folder:

   ```bash
   cd backend
   ```

2. Install dependencies:

   ```bash
   npm install
   ```

3. Configure environment variables:
   Create `.env` in `backend/` with:

   ```env
   PORT=5000
   DB_HOST=localhost
   DB_USER=root
   DB_PASS=your_mysql_password
   DB_NAME=organization_db
   JWT_SECRET=supersecretkey
   ```

4. Run the server:

   ```bash
   npm run dev
   ```

   API should now be running at:
   👉 `http://localhost:5000`

---

## 📱 Frontend (Flutter App)

1. Navigate to frontend folder:

   ```bash
   cd frontend
   ```

2. Get dependencies:

   ```bash
   flutter pub get
   ```

3. Run the app on simulator/emulator:

   ```bash
   flutter run
   ```

   > ⚠️ Ensure your backend API URL in the Flutter project is pointing to your local server:

   - `http://10.0.2.2:5000` → Android Emulator
   - `http://localhost:5000` → iOS Simulator

---

## 🚀 Workflow

1. Start **MySQL server**
2. Seed the database (`schema.sql` + `seed.sql`)
3. Run **backend** (`npm run dev`)
4. Run **frontend** (`flutter run`)
