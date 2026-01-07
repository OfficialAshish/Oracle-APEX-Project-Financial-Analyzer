# Project Margin Manager (Margin Mystery Solver)

![Oracle APEX](https://img.shields.io/badge/Oracle-APEX-orange) ![Oracle Database](https://img.shields.io/badge/Database-Oracle%2023ai-red) ![Status](https://img.shields.io/badge/Status-Active-brightgreen)

## 📋 Overview

**Project Margin Manager** is a centralized financial analysis system built on **Oracle APEX** and **Oracle 23ai**. 

* **Live Demo:** [Click here to access](https://oracleapex.com/ords/r/ashish_9/project-mystery232120/dashboard)
* **Demo Credentials:**
* **Username:** `ashish`
* **Password:** `Ashish.1`
Organizations often face challenges with disorganized data spread across multiple files, leading to manual errors and a lack of real-time visibility into project profitability. This solution serves as a unified financial command center that unifies data sources, automates margin calculations, and utilizes **Generative AI** to provide conversational insights into financial data.

## 🚀 Key Features

* **Unified Data Sources:** Consolidates project revenue, employee costs, and effort data into a single source of truth.
* **Automated Financials:** PL/SQL procedures automatically calculate Total Cost, Revenue, and Gross Margins, eliminating 80% of manual calculation time.
* **Real-Time Dashboards:** Live visibility into project profitability and business unit performance.
* **AI-Powered Insights:** Built on **Oracle 23ai**, allowing users to query data using natural language (e.g., "Which projects had the lowest margin last quarter?").*(currently disabled)*
* **Role-Based Security:** Pre-configured access control for Admins, Managers, and PMO users.

## 🛠 Tech Stack

* **Frontend:** Oracle APEX (Low-code platform)
* **Database:** Oracle Database 23ai
* **Logic:** PL/SQL (Stored Procedures for automation)
* **AI Integration:** Oracle 23ai Vector/Generative AI capabilities

---

## 📂 Repository Contents

* `f[app_id].zip`: The Oracle APEX application export file.
* `setup_objects.sql`: The DDL and DML scripts to create tables, sequences, and procedures.
* `sample_data/`: Templates for the Excel files required for the application.

---

## ⚙️ Installation Guide

Follow these steps to set up the application in your Oracle APEX environment.

### Prerequisites
* An Oracle Cloud or On-Premise environment with **Oracle APEX** installed.
* **Oracle 23ai** is required for the AI/Select AI features to function correctly.(currently disabled, so *(Optional)*)

### Step 1: Database Objects Setup
1.  Login to your Oracle APEX Workspace.
2.  Navigate to **SQL Workshop** → **SQL Scripts**.
3.  Upload the `setup_objects.sql` file provided in this repository.
4.  Run the script.
5.  **Verify:** Ensure there are no errors in the execution results.

### Step 2: Import the Application
1.  From the APEX Home Page, go to **App Builder**.
2.  Click **Import**.
3.  Drag and drop the `.zip` application file from this repository.
4.  Keep all default settings and click **Next**.
5.  **Install** the application.

### Step 3: Security Configuration
1.  After installation, proceed to **Edit Application**.
2.  Navigate to **Shared Components** → **Security Module** → **Application Access Control**.
3.  Add a User Role Assignment.
4.  Assign the **Administrator** role to your workspace admin user.
5.  *(Optional)* Create other users in "Manage Users and Groups" and assign them specific application roles here.

### Step 4: Data Initialization
1.  Run the application.
2.  Navigate to the **Data Upload** section (or equivalent page in the app).
3.  Upload the **three required Excel files** (Revenue, Costs, Efforts) using the templates provided in the `sample_data` folder.
4.  Once uploaded, the PL/SQL automation will trigger, and dashboards will populate automatically.

---
---

## ⚙️ Handling Excel Import & Schema Customization
This is a great addition to your documentation. Handling Excel data variations is one of the most common challenges in APEX development.

I have drafted a new section below called **"Handling Excel Import & Schema Customization"** that you can insert directly into your `README.md` (recommended placement is right after the **Installation Guide** or as a sub-section of **Data Initialization**).

---

## 🛠 Troubleshooting: Excel Import & Schema Customization

Because different organizations use different Excel formats, you may encounter mapping errors during the initial data load. If your source files do not perfectly match the provided templates, follow these steps to redefine the data definitions.

### 1. Modify Table Structures

If your data contains extra essential columns or lacks certain fields, update the database tables first:

* Navigate to **SQL Workshop** → **Object Browser**.
* Select the relevant table (e.g., `PROJECT_REVENUE` or `EMPLOYEE_COSTS`).
* Use the **Table** tab to **Add Column** or **Drop Column** to match your Excel headers.
* *Alternatively*, run an `ALTER TABLE` command in **SQL Commands**.

### 2. Redefine Data Load Definitions

If you change the columns, you must update the APEX Data Profile:

1. Go to **Shared Components** → **Data Sources** → **Data Load Definitions**.
2. Select the definition corresponding to the file you are uploading.
3. Under **Column Mapping**, ensure every Excel header is correctly mapped to the updated table column.
4. If the mapping is too far off, delete the existing definition and use the **Create** wizard to sample your specific Excel file.

### 3. Re-generating the Data Load Page

If the "Data Upload" page in the application is not reflecting your changes:

1. Delete the existing Data Load page in **App Builder**.
2. Click **Create Page** → **Plug-in / Data Loading**.
3. Choose the **Data Load Definition** you updated in Step 2.
4. This will generate a "Quick Data Loading" interface specifically tuned to your new Excel structure.

> [!TIP]
> **Minimalist Approach:** You do not need to upload every column in your Excel. You can modify your Excel files to remove non-essential data; just ensure that the **Data Load Definition** in APEX only expects the columns remaining in your file.

---

### Why this helps:

* **Flexibility:** It acknowledges that "one size doesn't fit all" for financial data.
* **Clarity:** It gives the user a specific path (**Shared Components** -> **Data Load Definitions**) which is often the "hidden" fix for import errors.
* **Scalability:** It encourages users to use the native APEX Data Loader wizard, which is much more robust than manual parsing.

**Would you like me to help you draft the specific `ALTER TABLE` scripts for any new columns you're planning to add?**
---

## 📚 Maintenance: How to Export
*If you make changes to the application and wish to contribute or back it up, follow these steps:*

1.  Go to **Application** → **Home Page**.
2.  Navigate to **Export/Import** → **Export**.
3.  On the settings page, configure:
    * **Export Format:** Readable Format (YAML/JSON if available, or split SQL)
    * **Build Status Override:** Run and Build Application
4.  Click **Export Application**.

--- 
