# Quick Start Guide - Inventory & Sales Management System

Get up and running with the Inventory & Sales Management System in 15 minutes!

## 🚀 5-Minute Setup

### Step 1: Database Setup (2 minutes)

Choose your database and run the schema:

**Option A: SQL Server**
```bash
# Create database
sqlcmd -S localhost -Q "CREATE DATABASE InventorySales"

# Run schema
cd database
sqlcmd -S localhost -d InventorySales -i schema.sql
```

**Option B: MySQL**
```bash
# Create database
mysql -u root -p -e "CREATE DATABASE inventory_sales"

# Run schema
cd database
mysql -u root -p inventory_sales < schema.sql
```

**Option C: SQLite (Easiest for testing)**
```bash
# No setup needed - will auto-create on first run
# Just configure in Step 2
```

### Step 2: Configure Application (1 minute)

1. Copy configuration template:
   ```bash
   cp InventorySales.ini.sample InventorySales.ini
   ```

2. Edit `InventorySales.ini`:
   ```ini
   [Database]
   Type=SQLServer          # or MySQL, PostgreSQL, SQLite
   Server=localhost
   Database=InventorySales
   Username=sa
   Password=YourPassword
   ```

### Step 3: Run the Application (30 seconds)

**From Delphi IDE:**
```
1. Open InventorySales.dproj
2. Press F9 (Run)
```

**From Executable:**
```bash
# Windows
InventorySales.exe

# macOS
open InventorySales.app
```

### Step 4: Login (30 seconds)

Use default credentials:
```
Username: admin
Password: Admin@123
```

🎉 **You're ready to go!**

---

## 📱 Mobile Quick Start

### Android

1. **Enable Developer Mode** on your device
2. **Connect device** via USB
3. **In Delphi**:
   - Select Android platform
   - Press F9 to deploy and run
4. **Login** with `admin` / `Admin@123`

### iOS

1. **Connect iOS device** via USB
2. **Configure provisioning profile** in Delphi
3. **In Delphi**:
   - Select iOS platform
   - Press F9 to deploy and run
4. **Login** with `admin` / `Admin@123`

---

## 🎯 First Tasks - 5 Minutes

### 1. Add Your First Product (1 minute)

1. Navigate to **Inventory** tab
2. Click **Add Product**
3. Fill in:
   ```
   Product Code: PROD001
   Product Name: My First Product
   Category: Select from dropdown
   Unit Price: 99.99
   Quantity: 100
   ```
4. Click **Save**

### 2. Process Your First Sale (2 minutes)

1. Navigate to **Sales** tab
2. Search for product in search box
3. Enter quantity: `5`
4. Click **Add to Cart**
5. Review cart items
6. Enter customer info (optional):
   ```
   Name: John Doe
   Phone: +1234567890
   ```
7. Select Payment Method: `Cash`
8. Click **Process Sale**

✅ Your inventory is automatically updated!

### 3. View Your First Report (2 minutes)

1. Navigate to **Reports** tab
2. Select Report Type: `Sales Report`
3. Choose date range: `Today`
4. Click **Generate Report**
5. View sales data in grid
6. Click **Export CSV** to save report

---

## 👥 User Management - 3 Minutes

### Create New User (Admin only)

1. Navigate to **Users** tab
2. Click **Add User**
3. Fill in details:
   ```
   Username: newuser
   Full Name: New User
   Email: user@company.com
   Role: Employee (or Manager/Admin)
   Branch: Select from dropdown
   Password: SecurePass123
   ```
4. Click **Save**

### Test New User

1. Click **Logout**
2. Login with new credentials
3. Notice role-based UI changes:
   - **Employee**: Can't see Users tab
   - **Manager**: Can't delete products
   - **Admin**: Full access

---

## 🔄 Offline Mode (Mobile) - 2 Minutes

### Enable Offline Mode

1. **Turn off WiFi/Data** on mobile device
2. Open application
3. Notice status: **"Offline Mode"**
4. All features work normally!

### Test Offline Sale

1. Navigate to **Sales** tab
2. Add products to cart
3. Process sale normally
4. Sale saved to local database

### Sync When Online

1. **Turn on WiFi/Data**
2. Click **Sync** button in toolbar
3. Watch changes upload to server
4. Status changes to **"Online Mode"**

---

## 📊 Sample Scenarios

### Scenario 1: Low Stock Alert

```
1. Go to Inventory
2. Find product with quantity < minimum stock
3. Product shows "Low Stock" status in red
4. Go to Reports → Low Stock Report
5. See all items needing reorder
6. Export report for purchasing
```

### Scenario 2: Daily Sales Summary

```
1. Go to Reports
2. Select "Sales Report"
3. Date Range: Today
4. Click Generate Report
5. View all today's transactions
6. Check totals at bottom
7. Export to CSV for accounting
```

### Scenario 3: Employee Performance

```
1. Go to Reports
2. Select "Sales by Employee"
3. Date Range: This Month
4. Click Generate Report
5. See sales count and revenue per employee
6. Identify top performers
```

### Scenario 4: Product Search

```
1. Go to Inventory
2. Use search box: "Laptop"
3. See matching products instantly
4. Click product to edit
5. Update quantity
6. Save changes
```

---

## ⚡ Power User Tips

### Keyboard Shortcuts

- `Enter` - Submit login form
- `Ctrl+N` - New product/sale (where applicable)
- `Delete` - Delete selected item (with confirmation)
- `F5` - Refresh current view
- `Esc` - Close dialog/cancel operation

### Quick Actions

**Inventory:**
- **Double-click** product row to edit
- **Right-click** for context menu (future)
- **Type to search** - search as you type

**Sales:**
- **Barcode scan** - enter barcode and press Enter
- **Enter quantity** - type number and press Enter
- **Quick payment** - defaults to Cash

**Reports:**
- **Date shortcuts** - Today, This Week, This Month
- **Quick export** - Right-click → Export
- **Print preview** - Select all → Ctrl+P

### Batch Operations

**Bulk Product Import:**
```
1. Prepare CSV with columns:
   ProductCode,ProductName,Category,Price,Quantity
2. Go to Inventory → Import
3. Select CSV file
4. Map columns
5. Click Import
```
*(Feature ready for implementation)*

**Bulk Price Update:**
```sql
-- Direct SQL for admin users
UPDATE Products
SET UnitPrice = UnitPrice * 1.1
WHERE CategoryID = 1;
```

---

## 🐛 Quick Troubleshooting

### Can't Login?

```
✓ Check username/password (case-sensitive)
✓ Verify database connection
✓ Check InventorySales.ini settings
✓ Ensure database has Users table
✓ Try default: admin / Admin@123
```

### Database Connection Failed?

```
✓ Database server running?
✓ Firewall blocking port?
✓ Credentials correct in .ini file?
✓ Network connectivity OK?
✓ Try SQLite for testing: Type=SQLite
```

### Inventory Not Updating After Sale?

```
✓ Check sale was successful
✓ Verify product exists
✓ Check SaleItems table has records
✓ Review database triggers
✓ Check error logs
```

### Sync Not Working (Mobile)?

```
✓ Internet connection active?
✓ Server URL correct in config?
✓ Check SyncLog table for errors
✓ Try manual sync button
✓ Clear sync log and retry
```

### Report Shows No Data?

```
✓ Correct date range selected?
✓ Data exists in database?
✓ Branch filter not too restrictive?
✓ User has report permissions?
✓ Check query in ReportService
```

---

## 📚 Quick Reference

### Default Credentials

| Username | Password | Role | Access Level |
|----------|----------|------|--------------|
| admin | Admin@123 | Administrator | Full access |
| manager | Manager@123 | Manager | No user mgmt |
| employee | Employee@123 | Employee | Sales only |

### Database Tables

| Table | Purpose |
|-------|---------|
| Users | User accounts and roles |
| Products | Inventory items |
| Categories | Product categories |
| Branches | Store locations |
| Sales | Sale transactions |
| SaleItems | Items in sales |
| SyncLog | Offline sync tracking |

### File Locations

| Platform | Config Location |
|----------|-----------------|
| Windows | `C:\Users\[User]\Documents\InventorySales.ini` |
| macOS | `~/Documents/InventorySales.ini` |
| Android | `/storage/emulated/0/Documents/InventorySales.ini` |
| iOS | `App Documents/InventorySales.ini` |

### Support Resources

- 📖 **Full Documentation**: README.md
- 🚀 **Deployment Guide**: docs/DEPLOYMENT_GUIDE.md
- 📊 **Project Summary**: PROJECT_SUMMARY.md
- 💻 **Database Schema**: database/schema.sql
- 🧪 **Run Tests**: tests/*.pas

---

## 🎯 Next Steps

### For Administrators

1. ✅ Change default passwords
2. ✅ Create user accounts for team
3. ✅ Set up branches and categories
4. ✅ Import initial product catalog
5. ✅ Configure backup schedule
6. ✅ Set up sync server (for mobile)

### For Developers

1. ✅ Review codebase structure
2. ✅ Run unit tests
3. ✅ Customize UI themes
4. ✅ Add custom reports
5. ✅ Integrate payment gateway
6. ✅ Add barcode scanner

### For End Users

1. ✅ Complete training session
2. ✅ Practice sample transactions
3. ✅ Learn report generation
4. ✅ Test offline mode (mobile)
5. ✅ Familiarize with shortcuts
6. ✅ Review user manual

---

## 💡 Pro Tips

### Performance

- **Desktop**: Direct database connection is fastest
- **Mobile**: Use offline mode for better UX
- **Reports**: Limit date ranges for large datasets
- **Sync**: Schedule during off-peak hours

### Security

- **Change default passwords** immediately
- **Use HTTPS** for sync server
- **Enable Windows Auth** for SQL Server if possible
- **Regular backups** - daily minimum
- **Audit logs** - review weekly

### Best Practices

- **Naming Convention**: Use consistent product codes
- **Categories**: Keep category tree shallow (2-3 levels max)
- **Stock Levels**: Set realistic min/max values
- **Sync**: Sync mobile devices at start/end of shift
- **Reports**: Export daily sales for accounting

---

## 🆘 Getting Help

### Built-in Help

1. **Hover tooltips** on buttons and fields
2. **Error messages** provide specific guidance
3. **Validation** highlights issues in real-time

### Documentation

- **README.md** - Complete user guide
- **DEPLOYMENT_GUIDE.md** - Setup instructions
- **PROJECT_SUMMARY.md** - Technical overview

### Support Channels

- 📧 **Email**: support@yourcompany.com
- 📞 **Phone**: +1-555-0100
- 🌐 **Website**: https://yourcompany.com/support
- 💬 **Forum**: https://forum.yourcompany.com

### Emergency

- 🚨 **Emergency Support**: +1-555-0911
- 🔧 **IT Helpdesk**: extension 2000
- 📱 **After Hours**: support@yourcompany.com

---

## 🎉 Success!

You're now ready to use the Inventory & Sales Management System!

**Quick Checklist:**
- ✅ Database configured
- ✅ Application running
- ✅ Logged in successfully
- ✅ First product added
- ✅ First sale processed
- ✅ First report generated

**Next:** Explore advanced features in the full documentation!

---

**Happy Selling! 🛍️📊**

*Version 1.0.0 | Last Updated: October 2025*
