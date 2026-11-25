---
id: 20250426161503
title: Database Node.js Setup Configuration Troubleshooting Guide
date: 2025-04-26 16:15
type: reference # note | concept | snippet | bug | journal | reference
status: stable # draft | stable | evergreen
tags: [database, nodejs, setup, configuration, troubleshooting]
links: []
---
# Log
- 2025-04-26 16:15 - Created note.

# Notes

# After mariadb install

**You never initialized MariaDB’s system database**, so it's failing because core tables like `mysql.user` don't exist yet.

---

Let's go step-by-step carefully:  
**(I’ll explain like I would to myself if I were setting up fresh.)**

---

### Step 1: First, check if `/var/lib/mysql/` is empty or messed up

Run:

```bash
ls -l /var/lib/mysql/
```

If it looks mostly **empty** or has only a few files (not proper database folders like `mysql`, `performance_schema`, etc.), that's expected.

---

### Step 2: Initialize MariaDB's data directory

Now run this command to initialize:

```bash
sudo mariadb-install-db --user=mysql --basedir=/usr --datadir=/var/lib/mysql
```

- `--user=mysql` → use the **special system user** `mysql` (it already exists on your Linux; **don't create a new user** manually)
- `--basedir=/usr` → base directory where MariaDB is installed
- `--datadir=/var/lib/mysql` → directory where MariaDB databases are stored

✅ **Important:** Always let MariaDB files (in `/var/lib/mysql`) belong to `mysql:mysql` user and group.  
Don't use your own user for this!

---

**If the command runs successfully, you'll see something like:**
> "Database initialized"  
> "Please make sure the MariaDB server is running with appropriate permissions."

---

### Step 3: Set permissions correctly

Even if the installer does it, just to be 100% sure, fix permissions manually:

```bash
sudo chown -R mysql:mysql /var/lib/mysql
sudo chmod 755 /var/lib/mysql
```

This makes sure MariaDB server can fully access its own files.

---

### Step 4: Start MariaDB server

Now start it:

```bash
sudo systemctl start mariadb
```

and check if it's running:

```bash
sudo systemctl status mariadb
```

✅ If everything is good, it should show `active (running)`!

---

### Step 5: Secure MariaDB installation (VERY recommended)

Now **secure** the installation:

```bash
sudo mariadb-secure-installation
```

It will ask:
- Set root password? → Yes
- Remove anonymous users? → Yes
- Disallow root login remotely? → Yes (good for security)
- Remove test database? → Yes
- Reload privilege tables? → Yes

After that, your MariaDB is fully ready for use.

---

### Quick Summary:

| Step | Action |
|:----|:-------|
| 1 | Check `/var/lib/mysql/` |
| 2 | Initialize with `mariadb-install-db` |
| 3 | Fix permissions: `mysql:mysql` |
| 4 | Start service |
| 5 | Secure installation |

---

Would you like me to also give you a **full copy-paste script** so you can run everything in one shot?  
It’ll save you time if you want to just do it fast. 🚀✨

(Just say yes if you want!)


# Creating Database using cli, because permissions to CREATE DATABASE, DROP DATABASE should not be given to nodejs or other applications. Principle of Least Privilege

Perfect, you gave me everything I need.  
Let's do a **super clean MariaDB setup** for your project based on your `.env` and `config`. 🚀

---

✅ **Step 1: Open MariaDB as root**

```bash
sudo mysql -u root -p
```
(enter your MariaDB root password)

---

✅ **Step 2: Create the database**

Let's name it something good. Example: `berufplattform_db`

```sql
CREATE DATABASE berufplattform_db;
```

---

✅ **Step 3: Create the user and give permissions**

You already have `berufplattf` and a password `berufplattf.db.password`,  
so let's just make sure it exists properly and has access:

```sql
CREATE USER 'berufplattf'@'localhost' IDENTIFIED BY 'berufplattf.db.password';
GRANT ALL PRIVILEGES ON berufplattform_db.* TO 'berufplattf'@'localhost';
FLUSH PRIVILEGES;
```

(If user already exists, MariaDB will say "user exists", no problem.)

---

✅ **Step 4: Update your code to use this database**

In your connection, **add the database** in the `createPool` like this:

```typescript
const pool = mariadb.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASS,
  database: 'berufplattform_db',   // <-- Add this line
  connectionLimit: 5,
});
```

(You can also put it in your `.env` if you want, e.g., `DB_DATABASE=berufplattform_db`.)

---

✅ **Step 5: (Optional) Clean your code**

No need to run `CREATE DATABASE IF NOT EXISTS` from code anymore, because you now create it manually.

Just check connection like you already do:

```typescript
if (conn) {
  console.log(`Connected! (id=${conn.threadId})`);
}
```

---

🔵 **Summary of your `.env` after setup:**

```
DB_HOST=localhost
DB_USER=berufplattf
DB_PASS=berufplattf.db.password
DB_DATABASE=berufplattform_db
```

And in code:

```typescript
database: process.env.DB_DATABASE,
```

---

✅ **Result:**  
Now your Node.js backend will directly connect to the **right database** with **correct permissions**.  
No "Access denied" errors anymore. 🎯

---

Would you like me to also show you a nice version of connection file (`db.ts`) with retry logic and error handling? (Production ready 🔥)  
It'll make your backend super solid. 🚀  
(only if you want!)


# me 
```
above one is good if we have not did this before CREATE DATABASE berufplattform_db;
and tried to do the same in nodejs code will it work
```

## chatgpt response

Good question — you're thinking smart. Let me explain it **clearly**:

---

### 👉 If you **don't create** the database manually (`CREATE DATABASE berufplattform_db;` in MariaDB)
and you try to do it **from Node.js code** like this:

```typescript
await conn.query("CREATE DATABASE IF NOT EXISTS berufplattform_db");
```

**It will only work IF your MariaDB user (`berufplattf`) has the permission to create databases** —  
this permission is called `CREATE` privilege **at global level**.

---

🔴 **But in your case, `berufplattf` does not have that permission yet.**  
That's why you saw this error before:

```
Access denied for user 'berufplattf'@'localhost' to database 'your_database_name'
```

Meaning —  
- Without `CREATE` privilege → **cannot create a new database** from Node.js.
- You can **only** connect to a database that already exists and you have access to.

---

### 🧠 Important:
- MariaDB **by default** does not give "create database" permissions to normal users (only to `root` or if you grant it manually).
- For production or clean projects, it's **better practice** to:
  - **Create the database manually once** (`CREATE DATABASE ...`).
  - **Connect to it** from your Node.js code (don't create from app code).
  
This avoids security issues too.

---

### 👉 In short:

| Situation | Will Node.js `CREATE DATABASE` Work? |
|:---|:---|
| `berufplattf` has `CREATE` privilege | ✅ Yes |
| `berufplattf` does NOT have `CREATE` privilege | ❌ No (access denied) |

In your current case — **❌ No**, it will not work **until you give special permission**.

---

### ✅ Best Solution for you:
✔ Manually create the database once.  
✔ Just **connect** from Node.js — no need to "create database" in code.

**(Exactly what we are setting up now.)**

---

Would you like me to also show how to **grant "CREATE" privilege** to your user if you still want to try creating database dynamically from code?  
(only if you want to make it flexible for future) 🚀


# me 
```
as i undersstand it is biggest security issue if we create it using nodejs codes but what if we want to scale do we use another tool or some other idea
```

## chatgpt response

Exactly — you understood the big picture very well. 🔥  
Let’s go a bit deeper (I'll keep it simple):

---

# 🛡 Why creating databases from Node.js app is bad (security-wise)
- If your Node.js app can create databases anytime (`CREATE DATABASE` permission) —  
  👉 if **your app gets hacked**, the hacker can create unlimited databases and crash your server.
- Normally, **production users** (`berufplattf`) are given very **limited permissions**:  
  Only `SELECT`, `INSERT`, `UPDATE`, `DELETE` on their own database.  
  (**Not CREATE DATABASE, DROP DATABASE, GRANT, etc.**)

This is called **Principle of Least Privilege** in security.

---

# 🚀 So how do real big apps and companies handle scaling?

When you scale a backend — **you don't create databases manually or from code**.  
Instead, you do one of these:

### 1. **Migrations Tools** (most common)
- Use a **migration tool** to manage database schema (tables, columns) automatically.
- Examples:
  - **Prisma Migrate** (for Node.js)
  - **TypeORM Migrations** (for TypeScript projects)
  - **Flyway**, **Liquibase** (for big enterprise apps)
- You run commands like:
  ```bash
  npx prisma migrate deploy
  ```
- It applies any new **table creations / changes** to your existing database safely.

**✅ Advantage:**  
No need for app code to "create" anything — the migration tool handles schema changes cleanly, and devs/admins control database structure.

---

### 2. **Infrastructure as Code (IaC)**
- Use tools like **Terraform**, **Pulumi**, **Ansible** to automatically set up:
  - Database servers
  - Databases
  - Users
  - Permissions
- This happens **outside** your app — at **cloud/server setup level**.

Example:  
Terraform script can create MariaDB instances on AWS, create database `berufplattform_db`, create user `berufplattf`, assign permissions — **all before** the app even runs.

---

### 3. **Admin Manual Creation (Simple Projects)**
- When you start a project manually, **you create database once manually**, and that's it.
- Then you only manage tables/data inside that database, no need to recreate databases every time.

(This is what you are doing now — **good for small and medium projects**.)

---

# 🧠 Final Tip for Scaling:
- Use **one fixed database** per app (for example, `berufplattform_db`).
- Inside that database, you can create as many **tables** as you want.
- Use **migrations** to add/change tables when app grows.
- **Never give your Node.js app global permissions** like `CREATE DATABASE`, `DROP DATABASE`, `GRANT`, etc.
- Only give it access to its own database.

✅ **Secure**  
✅ **Scalable**  
✅ **Professional architecture**

---

Would you also like me to quickly show you **how to set up simple migrations** for your current project (without complex tools like Prisma)?  
(very lightweight, useful even for small teams 🚀)

## chatgpt respone on do it 

Perfect, you are **building it the right way** — very clean setup! 🚀  
Now, let's **expand** it fully step-by-step so you have a complete backend skeleton, **ready to code controllers later**.

---

First answering your question:

# SQL Scripts vs ORM?  
✅ **SQL Scripts** (manual queries)  
- Full control (optimized queries)
- Faster for simple apps
- You already use `mariadb` module — so it's natural!

✅ **ORM (Object Relational Mapper)**  
- Easier for **big projects** (auto migrations, less manual work)
- Write in JavaScript/TypeScript instead of SQL
- Famous ones for Node.js:
  - **Prisma** (best with TypeScript — 🔥 recommended)
  - **Sequelize** (good but older)
  - **TypeORM** (heavier, less popular now)

🔵 **My suggestion:**  
Since you're early stage + want scalability later =  
👉 **use SQL scripts now** (mariadb package)  
👉 later if project grows very big, you can migrate to Prisma easily.

---
# Now, let’s design your project structure:

```
src/
├── controllers/
│   ├── usersController.ts
│   ├── companiesController.ts
│   ├── jobsController.ts
│   └── applicationsController.ts
│
├── models/
│   ├── usersModel.ts
│   ├── companiesModel.ts
│   ├── jobsModel.ts
│   └── applicationsModel.ts
│
├── routes/
│   ├── usersRoutes.ts
│   ├── companiesRoutes.ts
│   ├── jobsRoutes.ts
│   └── applicationsRoutes.ts
│   └── routes.ts (import all above and combine)
│
├── database/
│   ├── connection.ts
│   └── init.sql (if needed for table creation)
│
├── server.ts
├── config/
│   └── dbConfig.ts (optional for pooling config)
└── utils/
    └── helpers.ts (optional utils like password hash etc.)
```

---
# Database tables you will have:

| Table          | Purpose                                 |
|----------------|-----------------------------------------|
| `users`        | Job seekers data                        |
| `companies`    | Recruiter companies info                |
| `jobs`         | Job listings posted by companies        |
| `applications` | Links between users and jobs they apply |

---
# Basic example: **usersModel.ts**

```typescript
import pool from '../database/connection';

export const getAllUsers = async () => {
  const conn = await pool.getConnection();
  try {
    const rows = await conn.query('SELECT * FROM users');
    return rows;
  } finally {
    conn.release();
  }
};

export const createUser = async (userData: { name: string; email: string; password: string }) => {
  const conn = await pool.getConnection();
  try {
    const { name, email, password } = userData;
    await conn.query('INSERT INTO users (name, email, password) VALUES (?, ?, ?)', [name, email, password]);
  } finally {
    conn.release();
  }
};
```

---
# Basic example: **usersRoutes.ts**

```typescript
import express from 'express';
import * as usersController from '../controllers/usersController';

const router = express.Router();

router.get('/', usersController.getUsers);
router.post('/', usersController.registerUser);

export default router;
```

---
# Basic example: **usersController.ts**

```typescript
import { Request, Response } from 'express';
import * as usersModel from '../models/usersModel';

export const getUsers = async (req: Request, res: Response) => {
  try {
    const users = await usersModel.getAllUsers();
    res.json(users);
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};

export const registerUser = async (req: Request, res: Response) => {
  try {
    await usersModel.createUser(req.body);
    res.status(201).json({ message: 'User created!' });
  } catch (err) {
    res.status(500).json({ error: 'Server error' });
  }
};
```

---
# `routes.ts` (master route file)

```typescript
import express from 'express';
import usersRoutes from './usersRoutes';
import jobsRoutes from './jobsRoutes';
import applicationsRoutes from './applicationsRoutes';
import companiesRoutes from './companiesRoutes';

const router = express.Router();

router.use('/users', usersRoutes);
router.use('/companies', companiesRoutes);
router.use('/jobs', jobsRoutes);
router.use('/applications', applicationsRoutes);

export default router;
```

---

✅ In this way you will have  
→ clean models → clean controllers → clean routes → everything organized 🔥  

---
# Your platform motto (improved version ideas):

- "**Connecting Talent to Opportunities**"
- "**Bringing Job Seekers and Employers Together**"
- "**Where Talent Meets Opportunity**"
- "**Platform that connects great people to great companies**"
- "**Bridging the gap between job seekers and job creators**"

(choose the one you like — or I can suggest more!)

---

**Would you also like me to next:**
- 📋 Show you a **full SQL table creation script** (users, jobs, applications, companies) ready to import?  
- 🎯 Suggest **important features** you should add (admin dashboard, password reset, search filters etc)?

👉 Just tell me!  
We are building something *very powerful* here if you continue. 🚀
