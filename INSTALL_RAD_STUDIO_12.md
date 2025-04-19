# Installation and Compilation Guide - RAD Studio 12 Athens (Windows 11)

## ✅ System Requirements

- **Windows 11** (64-bit)
- **RAD Studio 12 Athens** (Delphi)
- **4GB RAM** minimum (8GB recommended)
- **2GB free disk space**
- **SQL Server** / **MySQL** / **PostgreSQL** or just **SQLite** (for quick testing)

---

## 📥 Step 1: Clone the Project

```bash
# Open Command Prompt or PowerShell
cd C:\Projects
git clone git@github.com:forevertux/delphi_inv_sales_app.git
cd delphi_inv_sales_app
```

Or download ZIP from GitHub:
```
https://github.com/forevertux/delphi_inv_sales_app/archive/refs/heads/master.zip
```

---

## 🔧 Step 2: Open Project in RAD Studio 12

1. **Launch RAD Studio 12 Athens**
2. **File → Open Project...** (Ctrl+F11)
3. Navigate to: `C:\Projects\delphi_inv_sales_app\InventorySales.dproj`
4. Click **Open**

RAD Studio will load the project with all sources.

---

## ⚙️ Step 3: Configure Target Platform

1. In **Project Manager**, right-click on `InventorySales.exe`
2. Select **Target Platforms**
3. Enable:
   - ✅ **Windows 32-bit** (Win32)
   - ✅ **Windows 64-bit** (Win64) - recommended

4. For first compilation, use **Win32** (faster)

---

## 🗄️ Step 4: Configure Database

### Option A: SQLite (FASTEST - for testing)

1. **Copy configuration file:**
   ```bash
   copy InventorySales.ini.sample InventorySales.ini
   ```

2. **Edit `InventorySales.ini`:**
   ```ini
   [Database]
   Type=SQLite
   Database=C:\Projects\delphi_inv_sales_app\data\inventory.db
   ```

3. **Create data directory:**
   ```bash
   mkdir data
   ```

4. **Done!** SQLite will auto-initialize on first run.

### Option B: SQL Server (for production)

1. **Create database:**
   ```sql
   -- Open SQL Server Management Studio (SSMS)
   -- Or use sqlcmd:

   sqlcmd -S localhost -Q "CREATE DATABASE InventorySales"
   ```

2. **Run schema:**
   ```bash
   sqlcmd -S localhost -d InventorySales -i database\schema.sql
   ```

3. **Edit `InventorySales.ini`:**
   ```ini
   [Database]
   Type=SQLServer
   Server=localhost
   Database=InventorySales
   Username=sa
   Password=YourPassword
   WindowsAuth=False
   ```

### Option C: MySQL

1. **Create database:**
   ```sql
   mysql -u root -p
   CREATE DATABASE inventory_sales CHARACTER SET utf8mb4;
   exit;
   ```

2. **Run schema:**
   ```bash
   mysql -u root -p inventory_sales < database\schema.sql
   ```

3. **Edit `InventorySales.ini`:**
   ```ini
   [Database]
   Type=MySQL
   Server=localhost
   Database=inventory_sales
   Username=root
   Password=YourPassword
   Port=3306
   ```

---

## 🔨 Step 5: Compile the Project

### Standard Compilation:

1. Select **Debug** configuration (for testing)
2. **Project → Build InventorySales** (Ctrl+F9)
3. Wait for compilation to complete

### Check Output:

```
Compiling InventorySales.dpr
Compiling DatabaseModule.pas
Compiling UserEntity.pas
...
Success!

Output: C:\Projects\delphi_inv_sales_app\Win32\Debug\InventorySales.exe
```

### Optimized Build (Release):

```
1. Select "Release" configuration
2. Project → Build InventorySales
3. Optimized EXE: Win32\Release\InventorySales.exe
```

---

## ▶️ Step 6: Run the Application

### From RAD Studio:

1. Press **F9** (Run) or click green ▶️ button
2. Application will launch

### From Explorer:

```
C:\Projects\delphi_inv_sales_app\Win32\Debug\InventorySales.exe
```

### Login:

```
Username: admin
Password: Admin@123
```

✅ **Success!** Application is running on Windows 11 with RAD Studio 12.

---

## 🐛 Common Issues and Solutions

### ❌ Error: "Unit not found: DatabaseModule"

**Cause:** Missing search paths

**Solution:**
```
1. Project → Options
2. Building → Delphi Compiler → Search path
3. Add:
   $(ProjectDir)src\DataModules;
   $(ProjectDir)src\Entities;
   $(ProjectDir)src\Services;
   $(ProjectDir)src\Forms;
   $(ProjectDir)src\Utils
```

### ❌ Error: "FireDAC driver not found"

**Cause:** Database driver missing

**Solution for SQLite:**
```
FireDAC for SQLite is included in RAD Studio 12 - no installation needed
```

**Solution for SQL Server:**
```
1. Install SQL Server Native Client
   Download: https://www.microsoft.com/en-us/download/details.aspx?id=50402
2. Restart RAD Studio
```

**Solution for MySQL:**
```
1. Install MySQL Connector/C
   Download: https://dev.mysql.com/downloads/connector/c/
2. Copy libmysql.dll to application directory
```

### ❌ Error: "Cannot open file InventorySales.ini"

**Cause:** Configuration file missing

**Solution:**
```bash
copy InventorySales.ini.sample InventorySales.ini
```

Then edit `InventorySales.ini` with your settings.

### ❌ Application crashes on startup

**Cause:** Database not accessible

**Checks:**
1. SQL Server running? `services.msc` → SQL Server
2. Correct password in `InventorySales.ini`?
3. Database exists? Check in SSMS
4. Firewall blocking? Temporarily disable

**Quick test with SQLite:**
```ini
[Database]
Type=SQLite
Database=C:\temp\test.db
```

### ❌ Compilation error: "Duplicate resource"

**Cause:** Duplicate .res files

**Solution:**
```
1. Project → Clean
2. Manually delete: Win32\Debug\*.res
3. Project → Build
```

### ❌ FMX Forms not loading correctly

**Cause:** Missing style

**Solution:**
```
1. Project → Options → Application → Appearance
2. Select: Windows (for Windows 11)
3. Rebuild
```

---

## 📊 Quick Testing (2 minutes)

After compilation, test main features:

### 1. Login
```
Username: admin
Password: Admin@123
✅ Should enter the application
```

### 2. Add a Product
```
1. Tab: Inventory
2. Click: Add Product
3. Fill in:
   - Product Code: TEST001
   - Product Name: Test Product
   - Category: Electronics (from dropdown)
   - Unit Price: 99.99
   - Quantity: 50
4. Save
✅ Product appears in grid
```

### 3. Process a Sale
```
1. Tab: Sales
2. Search: TEST001
3. Quantity: 5
4. Add to Cart
5. Payment: Cash
6. Process Sale
✅ Success message
✅ Inventory updates (50 → 45)
```

### 4. Generate Report
```
1. Tab: Reports
2. Report Type: Sales Report
3. Date Range: Today
4. Generate Report
✅ Sale appears in report
5. Export CSV
✅ CSV file generated
```

**If everything works → Installation complete! 🎉**

---

## 🚀 Next Steps

### Deployment (Distribution)

1. **Compile Release:**
   ```
   Configuration: Release
   Platform: Win64 (for modern Windows)
   Build
   ```

2. **Collect files:**
   ```
   Win64\Release\InventorySales.exe
   InventorySales.ini.sample → InventorySales.ini
   database\schema.sql
   README.md
   ```

3. **Create Installer (optional):**
   ```
   Use Inno Setup:
   Download: https://jrsoftware.org/isdl.php

   Installation script in docs\DEPLOYMENT_GUIDE.md
   ```

### Customization

1. **Change logo:**
   ```
   Project → Options → Application → Icons
   Add your icon (256x256 PNG/ICO)
   ```

2. **Change version:**
   ```
   Project → Options → Version Info
   Version: 1.0.0 → 1.1.0
   Company Name: Your company name
   ```

3. **Add new features:**
   ```
   - Create new forms in src\Forms\
   - Add services in src\Services\
   - Update schema in database\schema.sql
   ```

---

## 📞 Support

### Complete Documentation:
- **README.md** - Complete guide
- **QUICKSTART.md** - Quick start
- **DEPLOYMENT_GUIDE.md** - Detailed deployment
- **FILE_INDEX.md** - File reference

### Issues?
- Check logs in: `%USERPROFILE%\Documents\InventorySales.log`
- GitHub Issues: https://github.com/forevertux/delphi_inv_sales_app/issues

---

## ✅ Final Checklist

Verify you have completed:

- [ ] RAD Studio 12 installed
- [ ] Project cloned from GitHub
- [ ] Project opened in IDE
- [ ] Platform configured (Win32/Win64)
- [ ] Database configured
- [ ] `InventorySales.ini` created and edited
- [ ] Project compiled successfully
- [ ] Application runs
- [ ] Login works
- [ ] Features tested

**If all checked → You're ready! 🎊**

---

**Version:** 1.0.0
**Compatible:** RAD Studio 12 Athens
**Platform:** Windows 11
**Author:** forever_tux
**Date:** October 2025
