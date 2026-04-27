<div align="center">

# 🎓 UniSphere — University Management System

### Full-Stack Web Application with Role-Based Access Control

![HTML](https://img.shields.io/badge/Frontend-HTML%20%7C%20CSS%20%7C%20JS-orange?style=for-the-badge)
![SQL](https://img.shields.io/badge/Backend-SQL-blue?style=for-the-badge)
![Status](https://img.shields.io/badge/Status-Production--Ready-success?style=for-the-badge)
![UI](https://img.shields.io/badge/UI-Modern%20Dashboard-purple?style=for-the-badge)

---

> A modern **University Management System** with multi-role access, real-time data handling, and an intuitive dashboard UI for academic administration.

</div>

---

## 🌐 Overview

**UniSphere** is a full-stack web application designed to streamline university operations. It supports **Admin, Staff, and Student roles**, enabling efficient management of attendance, academic records, and institutional workflows.

### 🚀 Key Features

```
┌──────────────────────────────────────────────────────────────┐
│  ✅ Role-Based Access Control (Admin · Staff · Student)      │
│  ✅ Attendance Tracking System                              │
│  ✅ Academic Records Management                             │
│  ✅ Real-Time Dashboard with Analytics                      │
│  ✅ Responsive & Modern UI Design                           │
│  ✅ Optimized SQL Queries for Performance                   │
└──────────────────────────────────────────────────────────────┘
```

---

## 🏗️ System Architecture

```
Frontend (HTML/CSS/JS)
        │
        ▼
Authentication Layer (RBAC Logic)
        │
        ▼
Backend (SQL Database)
        │
        ▼
Data Storage (Students · Staff · Attendance · Records)
```

---

## 🎨 UI Highlights

* Split-screen **modern login page**
* Dynamic **role-based dashboards**
* Sidebar navigation with **real-time stats**
* Interactive tables and attendance grids
* Clean design system using CSS variables

---

## 📂 Repository Structure

```
UniSphere/
│
├── 📄 index.html        ← Login & Entry UI
├── 🎨 style.css         ← Global styles & dashboard UI
├── 🗄️ schema.sql        ← Database schema
│
├── 📁 js/
│   └── auth.js          ← Authentication & role logic
│
└── README.md
```

---

## 🔐 Role-Based Access System

| Role        | Permissions                                 |
| ----------- | ------------------------------------------- |
| 👑 Admin    | Full system control, manage users & records |
| 👨‍🏫 Staff | Manage attendance & student data            |
| 🎓 Student  | View records and attendance                 |

---

## ⚡ Core Functionalities

### 📊 Dashboard

* Real-time statistics
* Role-specific views
* Activity tracking

### 📝 Attendance Management

* Mark and track attendance
* Visual attendance indicators
* Performance insights

### 📚 Records Management

* Store and retrieve student data
* Organized tabular interface
* Fast SQL-backed queries

---

## 🛠️ Tech Stack

| Layer        | Technology                             |
| ------------ | -------------------------------------- |
| Frontend     | HTML, CSS, JavaScript                  |
| Styling      | Custom CSS (Design System + Variables) |
| Backend      | SQL                                    |
| Architecture | Role-Based Access Control (RBAC)       |

---

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/your-username/unisphere.git
cd unisphere
```

### 2. Setup Database

```sql
-- Run schema.sql in your SQL environment
```

### 3. Run the App

* Open `index.html` in your browser

---

## 🔑 Demo Login Roles

Use the built-in demo switcher:

* Admin
* Teacher
* Student

---

## 📈 Performance Optimizations

* Efficient SQL queries for **real-time data retrieval**
* Lightweight frontend for **fast rendering**
* Scalable UI architecture using reusable components

---

## 🎯 Future Enhancements

* 🔔 Notifications system
* 📱 Mobile responsiveness improvements
* 🌐 API integration (Node.js / Flask)
* 📊 Advanced analytics dashboard
* 🔐 Secure authentication (JWT / OAuth)

---


</div>
