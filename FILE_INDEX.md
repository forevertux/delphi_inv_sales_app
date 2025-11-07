# File Index - Inventory & Sales Management System

Complete file listing and description for the project.

## 📁 Project Structure Overview

```
sales_inventory/
├── Core Application Files (3)
├── Database Files (1)
├── Documentation Files (4)
├── Source Code Files (22)
│   ├── DataModules (2)
│   ├── Entities (5)
│   ├── Services (5)
│   ├── Forms (10)
│   └── Utils (4)
└── Test Files (2)

Total Files: 35+
```

---

## 📄 Core Application Files

### Main Project Files

| File | Lines | Purpose |
|------|-------|---------|
| `InventorySales.dpr` | ~50 | Main program entry point, uses clauses |
| `InventorySales.dproj` | ~200 | Delphi project configuration (multi-platform) |
| `InventorySales.ini.sample` | ~60 | Configuration template for database and app settings |

**Key Features:**
- Multi-platform support (Win32, Win64, macOS, Android, iOS)
- FireDAC component integration
- Debug and Release configurations
- Platform-specific deployment settings

---

## 🗄️ Database Files

### Database Schema

| File | Lines | Purpose |
|------|-------|---------|
| `database/schema.sql` | ~500 | Complete database schema for all platforms |

**Contents:**
- **Tables (8)**: Users, Products, Categories, Branches, Sales, SaleItems, SyncLog
- **Views (2)**: vw_ProductStockStatus, vw_SalesSummary
- **Stored Procedures**: sp_ProcessSale
- **Triggers**: Inventory update, totals calculation
- **Indexes**: Performance optimization
- **Sample Data**: 3 users, 5 products, 5 categories, 1 branch

**Database Support:**
- SQL Server 2014+
- MySQL 5.7+
- PostgreSQL 10+
- Oracle 12c+
- SQLite 3+

---

## 📚 Documentation Files

### User & Developer Documentation

| File | Size | Purpose |
|------|------|---------|
| `README.md` | 15KB | Complete user guide, features, installation |
| `QUICKSTART.md` | 12KB | 5-minute quick start guide |
| `PROJECT_SUMMARY.md` | 18KB | Complete project summary, all stories completed |
| `docs/DEPLOYMENT_GUIDE.md` | 25KB | Comprehensive deployment instructions |
| `FILE_INDEX.md` | This file | Complete file listing and descriptions |

**Documentation Coverage:**
- Installation and setup
- User guide and tutorials
- Deployment procedures (Desktop, Mobile, Server)
- Security hardening
- Troubleshooting
- API integration
- Maintenance procedures

---

## 💾 Source Code - Data Access Layer

### DataModules (Database Connectivity)

| File | Lines | Purpose |
|------|-------|---------|
| `src/DataModules/DatabaseModule.pas` | ~400 | FireDAC database connection manager |
| `src/DataModules/DatabaseModule.dfm` | ~50 | DataModule visual design |

**Features:**
- Multi-database support (SQL Server, MySQL, PostgreSQL, Oracle, SQLite)
- Connection pooling and management
- Transaction support (BeginTrans, CommitTrans, Rollback)
- Automatic offline mode switching (mobile)
- Configuration file integration
- Local SQLite database creation
- Query components (qryGeneral, qryProducts, qrySales, qryUsers, qryReports)

**Key Methods:**
- `Connect()` - Establishes database connection
- `Disconnect()` - Closes connection
- `ExecuteSQL()` - Executes SQL commands
- `ExecuteQuery()` - Runs SELECT queries
- `GetLastInsertID()` - Retrieves auto-generated IDs
- `SwitchToOfflineMode()` - Mobile offline support
- `SwitchToOnlineMode()` - Restore online connection

---

## 🏗️ Source Code - Entity Classes

### Entities (Domain Models)

| File | Lines | Purpose |
|------|-------|---------|
| `src/Entities/UserEntity.pas` | ~150 | User entity with role-based permissions |
| `src/Entities/ProductEntity.pas` | ~200 | Product entity with stock management |
| `src/Entities/SaleEntity.pas` | ~300 | Sale and SaleItem entities with calculations |
| `src/Entities/CategoryEntity.pas` | ~80 | Category entity |
| `src/Entities/BranchEntity.pas` | ~100 | Branch entity with address handling |

**UserEntity Features:**
- Properties: UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID
- Permission methods: IsAdmin(), IsManager(), IsEmployee()
- Access control: CanAccessInventory(), CanAccessSales(), CanAccessReports()
- Role constants: ROLE_ADMIN (1), ROLE_MANAGER (2), ROLE_EMPLOYEE (3)

**ProductEntity Features:**
- Properties: ProductID, ProductCode, ProductName, CategoryID, UnitPrice, CostPrice, Quantity
- Stock methods: GetStockStatus(), IsLowStock(), IsOutOfStock(), IsOverStock()
- Business logic: GetProfitMargin(), CanSell(Quantity)
- Validation: Positive prices, valid quantities

**SaleEntity Features:**
- TSale: Main sale transaction header
- TSaleItem: Individual line items
- Auto-calculation: CalculateLineTotal(), CalculateTotals()
- Support: Discounts, taxes, multiple payment methods
- Methods: AddItem(), RemoveItem(), GetItemCount(), GetTotalQuantity()

**CategoryEntity Features:**
- Properties: CategoryID, CategoryCode, CategoryName, Description
- Metadata: IsActive, CreatedAt, UpdatedAt

**BranchEntity Features:**
- Properties: BranchID, BranchCode, BranchName, Address, City, Country
- Methods: GetFullAddress() - formats complete address

---

## ⚙️ Source Code - Service Layer

### Services (Business Logic)

| File | Lines | Purpose |
|------|-------|---------|
| `src/Services/AuthService.pas` | ~500 | Authentication and user management |
| `src/Services/ProductService.pas` | ~600 | Product CRUD operations |
| `src/Services/SalesService.pas` | ~700 | Sales transaction processing |
| `src/Services/ReportService.pas` | ~800 | Reporting and analytics |
| `src/Services/SyncService.pas` | ~600 | Offline synchronization |

**AuthService - User & Authentication:**
- `Login(Username, Password)` - Authenticates user
- `Logout()` - Ends session
- `ValidateSession()` - Checks active session
- `ChangePassword()` - Updates user password
- `ResetPassword()` - Admin password reset
- `CreateUser()`, `UpdateUser()`, `DeleteUser()` - User management
- `GetUserByID()`, `GetUserByUsername()`, `GetAllUsers()` - User queries
- Global instance: `AuthService.CurrentUser`

**ProductService - Inventory Management:**
- `CreateProduct()`, `UpdateProduct()`, `DeleteProduct()` - Product CRUD
- `GetProductByID()`, `GetProductByCode()`, `GetProductByBarcode()` - Product retrieval
- `GetAllProducts()`, `GetProductsByCategory()`, `GetProductsByBranch()` - Filtered queries
- `GetLowStockProducts()` - Stock alerts
- `SearchProducts()` - Full-text search
- `UpdateStock()`, `CheckStock()` - Stock management
- Permission checks using AuthService.CurrentUser

**SalesService - Transaction Processing:**
- `CreateSale(Sale)` - Process complete sale with transaction
- `GetSaleByID()`, `GetSaleByNumber()` - Sale retrieval
- `GetSalesByDateRange()`, `GetSalesByBranch()`, `GetSalesByEmployee()` - Filtered queries
- `GetTodaysSales()` - Today's transactions
- `GenerateSaleNumber()` - Auto-generate sale number (SALE+YYYYMMDD+seq)
- `CancelSale()` - Reverse transaction and restore inventory
- `ValidateSaleItems()` - Stock availability check
- Automatic inventory updates with rollback on error

**ReportService - Analytics & Reporting:**
- `GetSalesReport()` - Detailed sales transactions
- `GetInventoryReport()` - Current stock status
- `GetTopSellingProducts()` - Best performers
- `GetSalesByCategory()` - Category analysis
- `GetSalesByEmployee()` - Employee performance
- `GetDailySalesChart()`, `GetMonthlySalesChart()` - Chart data
- `GetLowStockReport()`, `GetOutOfStockReport()` - Stock alerts
- `GetProfitAnalysis()` - Profitability metrics
- `ExportToCSV()` - CSV export (functional)
- `ExportToPDF()` - PDF export (stub, ready for integration)
- Complex SQL with JOINs, GROUP BY, aggregations

**SyncService - Offline Synchronization:**
- `SyncToServer()` - Upload local changes
- `SyncFromServer()` - Download server updates
- `FullSync()` - Bidirectional sync
- `LogChange()` - Track changes for sync
- `GetPendingChanges()` - Unsynced records
- `MarkAsSynced()`, `ClearSyncLog()` - Sync management
- `GetLastSyncTime()`, `SetLastSyncTime()` - Metadata
- `HandleConflict()` - Conflict resolution (server wins)
- Platform-specific device ID
- RESTful API integration ready

---

## 🎨 Source Code - User Interface

### Forms (FMX UI)

| File Pair | Lines | Purpose |
|-----------|-------|---------|
| `src/Forms/LoginForm.pas/.fmx` | 200 + 150 | Login screen with authentication |
| `src/Forms/MainForm.pas/.fmx` | 300 + 200 | Main dashboard with tabs |
| `src/Forms/InventoryForm.pas/.fmx` | 400 + 250 | Product management grid |
| `src/Forms/SalesForm.pas/.fmx` | 500 + 300 | Sales transaction processing |
| `src/Forms/ReportsForm.pas/.fmx` | 450 + 250 | Reports and analytics |

**LoginForm - Authentication UI:**
- Username/Password fields (TEdit)
- Remember Me checkbox with INI persistence
- Error label for messages
- Enter key support
- Auto-center on show
- Navigates to MainForm on success

**MainForm - Dashboard:**
- TabControl with 5 tabs: Dashboard, Inventory, Sales, Reports, Users
- Top toolbar: User info, Logout, Sync status
- Dashboard cards: Total Sales, Today's Revenue, Low Stock Alert
- Role-based tab visibility (Users tab for Admin only)
- Auto-refresh on tab change
- Sync status display

**InventoryForm - Product Management:**
- TStringGrid with 8 columns (Code, Name, Category, Qty, Price, Cost, Status, Barcode)
- Search functionality (real-time filter)
- Category dropdown filter
- Add, Edit, Delete buttons (permission-based)
- Double-click to edit
- Confirmation dialogs for delete
- Stock status color coding

**SalesForm - Transaction Processing:**
- Product search with TListBox results
- Quantity input (numeric)
- Add to Cart button with validation
- Cart grid (Product, Qty, Price, Discount, Tax, Total)
- Remove item from cart
- Customer name/phone (optional)
- Payment method combo (Cash, Card, Mobile, Bank)
- Real-time totals: Subtotal, Tax, Discount, Total
- Process Sale with confirmation
- Clear/New Sale button
- Stock validation before adding

**ReportsForm - Analytics Interface:**
- Report type combo (8 report types)
- Date range pickers (Start/End)
- Branch filter dropdown
- Generate Report button
- Dynamic TStringGrid (auto-adjusts columns)
- Export CSV button (functional)
- Export PDF button (placeholder)
- Report types: Sales, Inventory, Top Products, by Category, by Employee, Low Stock, Out of Stock, Profit Analysis

**Common UI Features:**
- Cross-platform FMX compatibility
- TLayout for responsive design
- Touch-friendly controls (44px minimum)
- Material Design colors
- Proper memory management
- Error handling with ShowMessage
- Service layer integration

---

## 🛠️ Source Code - Utilities

### Utils (Helper Functions)

| File | Lines | Purpose |
|------|-------|---------|
| `src/Utils/Constants.pas` | ~150 | Application constants and enums |
| `src/Utils/HashUtils.pas` | ~50 | Password hashing utilities |
| `src/Utils/ValidationUtils.pas` | ~120 | Input validation functions |
| `src/Utils/DateTimeUtils.pas` | ~100 | Date/time formatting helpers |

**Constants.pas:**
- Role constants: ROLE_ADMIN, ROLE_MANAGER, ROLE_EMPLOYEE
- Payment methods: PAYMENT_CASH, PAYMENT_CARD, PAYMENT_MOBILE
- Payment status: PAYMENT_PAID, PAYMENT_PENDING, PAYMENT_PARTIAL
- Stock status: STOCK_OUTOFSTOCK, STOCK_LOW, STOCK_NORMAL, STOCK_OVERSTOCK
- Sync status: SYNC_PENDING, SYNC_SUCCESS, SYNC_FAILED
- Operations: OP_INSERT, OP_UPDATE, OP_DELETE
- Default values: Tax%, Discount%, Min password length
- Date formats: DB and display formats
- User messages: Login, save, delete, error messages
- Helper functions: GetRoleName(), GetStockStatus()

**HashUtils.pas:**
- `HashPassword(Password)` - SHA256 hashing
- `VerifyPassword(Password, Hash)` - Password verification
- `GenerateSalt()` - GUID-based salt generation
- `HashWithSalt(Password, Salt)` - Salted hashing
- Ready for bcrypt/scrypt upgrade

**ValidationUtils.pas:**
- `IsValidEmail(Email)` - Email regex validation
- `IsValidPhone(Phone)` - Phone number validation
- `IsValidPassword(Password)` - Password strength
- `IsPositiveNumber(Value)` - Numeric validation
- `IsValidQuantity()`, `IsValidPrice()` - Business rules
- `IsEmptyOrWhiteSpace()` - String validation
- `ValidateRequired()` - Required field check
- `ValidateNumericRange()` - Range validation
- `ValidateLength()` - String length validation
- Returns error messages for user feedback

**DateTimeUtils.pas:**
- `FormatDateTimeForDB()` - Database format (YYYY-MM-DD HH:MM:SS)
- `FormatDateForDB()` - Date only (YYYY-MM-DD)
- `FormatDateTimeForDisplay()` - User format (DD/MM/YYYY HH:MM)
- `FormatDateForDisplay()` - Display date (DD/MM/YYYY)
- `ParseDBDateTime()` - Parse database datetime
- `GetCurrentDateTime()`, `GetCurrentDate()` - Current time
- `GetStartOfDay()`, `GetEndOfDay()` - Day boundaries
- `GetStartOfMonth()`, `GetEndOfMonth()` - Month boundaries
- `DaysBetween()` - Date difference
- `IsToday()`, `IsThisMonth()` - Date comparisons

---

## 🧪 Test Files

### Unit Tests (DUnitX)

| File | Lines | Purpose |
|------|-------|---------|
| `tests/TestAuthService.pas` | ~400 | Authentication service tests |
| `tests/TestProductService.pas` | ~450 | Product service tests |

**TestAuthService - 14 Test Methods:**
- `TestLoginWithValidCredentials` - Valid login
- `TestLoginWithInvalidCredentials` - Failed login
- `TestLoginWithEmptyUsername` - Validation
- `TestLoginWithEmptyPassword` - Validation
- `TestLogout` - Session termination
- `TestValidateSession` - Session validation
- `TestChangePassword` - Password update
- `TestCreateUser` - User creation
- `TestUpdateUser` - User modification
- `TestDeleteUser` - Soft delete
- `TestGetUserByID` - User retrieval
- `TestGetUserByUsername` - Username search
- `TestGetAllUsers` - List all users
- `TestResetPassword` - Admin password reset

**TestProductService - 12 Test Methods:**
- `TestCreateProduct` - Product creation
- `TestGetProductByID` - Product retrieval
- `TestGetProductByCode` - Code search
- `TestGetProductByBarcode` - Barcode scan
- `TestGetAllProducts` - List all
- `TestGetProductsByCategory` - Category filter
- `TestGetLowStockProducts` - Stock alerts
- `TestSearchProducts` - Text search
- `TestUpdateProduct` - Product update
- `TestUpdateStock` - Stock adjustment
- `TestCheckStock` - Availability check
- `TestDeleteProduct` - Soft delete

**Test Features:**
- Setup/TearDown methods
- Database integration tests
- Permission testing
- Validation testing
- Error handling tests
- Data integrity checks
- Cleanup after tests

---

## 📊 File Statistics

### Code Metrics

| Category | Files | Total Lines |
|----------|-------|-------------|
| Core Application | 3 | ~300 |
| Database Schema | 1 | ~500 |
| Documentation | 5 | ~15,000 words |
| DataModules | 2 | ~450 |
| Entities | 5 | ~800 |
| Services | 5 | ~3,200 |
| Forms (Code) | 5 | ~1,850 |
| Forms (FMX) | 5 | ~1,150 |
| Utils | 4 | ~420 |
| Tests | 2 | ~850 |
| **Total** | **37** | **~9,520** |

### Platform Support

| Platform | Status | Deployment |
|----------|--------|------------|
| Windows 32-bit | ✅ Ready | Standalone EXE |
| Windows 64-bit | ✅ Ready | Standalone EXE |
| macOS 64-bit | ✅ Ready | App Bundle |
| Android | ✅ Ready | APK/AAB |
| iOS | ✅ Ready | IPA |

### Database Support

| Database | Status | Version |
|----------|--------|---------|
| SQL Server | ✅ Full | 2014+ |
| MySQL | ✅ Full | 5.7+ |
| PostgreSQL | ✅ Full | 10+ |
| Oracle | ✅ Full | 12c+ |
| SQLite | ✅ Full | 3+ |

---

## 🔍 Quick File Finder

### By Feature

**User Authentication:**
- Entity: `src/Entities/UserEntity.pas`
- Service: `src/Services/AuthService.pas`
- UI: `src/Forms/LoginForm.pas/.fmx`
- Tests: `tests/TestAuthService.pas`

**Inventory Management:**
- Entity: `src/Entities/ProductEntity.pas`, `CategoryEntity.pas`
- Service: `src/Services/ProductService.pas`
- UI: `src/Forms/InventoryForm.pas/.fmx`
- Tests: `tests/TestProductService.pas`

**Sales Processing:**
- Entity: `src/Entities/SaleEntity.pas`
- Service: `src/Services/SalesService.pas`
- UI: `src/Forms/SalesForm.pas/.fmx`

**Reports & Analytics:**
- Service: `src/Services/ReportService.pas`
- UI: `src/Forms/ReportsForm.pas/.fmx`

**Offline Sync:**
- Service: `src/Services/SyncService.pas`

**Database:**
- Schema: `database/schema.sql`
- Connection: `src/DataModules/DatabaseModule.pas/.dfm`

### By Task

**Setting up database:**
1. `database/schema.sql`
2. `InventorySales.ini.sample`

**Configuring application:**
1. `InventorySales.ini.sample`
2. `src/DataModules/DatabaseModule.pas`

**Adding new product:**
1. `src/Forms/InventoryForm.pas`
2. `src/Services/ProductService.pas`
3. `src/Entities/ProductEntity.pas`

**Processing sale:**
1. `src/Forms/SalesForm.pas`
2. `src/Services/SalesService.pas`
3. `src/Entities/SaleEntity.pas`

**Generating report:**
1. `src/Forms/ReportsForm.pas`
2. `src/Services/ReportService.pas`

**Mobile sync:**
1. `src/Services/SyncService.pas`
2. `src/DataModules/DatabaseModule.pas` (offline mode)

---

## 📝 Usage Examples

### Reading a File

**User Entity:**
```bash
# Read user entity definition
cat src/Entities/UserEntity.pas
```

**Login Form:**
```bash
# Read login implementation
cat src/Forms/LoginForm.pas
```

### Finding Code

**Search for login logic:**
```bash
grep -r "Login" src/Services/AuthService.pas
```

**Find all database queries:**
```bash
grep -r "SELECT" src/Services/*.pas
```

**Locate validation functions:**
```bash
grep -r "Validate" src/Utils/ValidationUtils.pas
```

### Running Tests

**Execute all tests:**
```bash
# In Delphi IDE
Test → Run All Tests

# Command line
dunit-console InventorySales_Tests.dproj
```

---

## 🎯 Maintenance Guide

### Regular Updates

**Weekly:**
- Review error logs (check FMX.Dialogs ShowMessage calls)
- Update test data in `database/schema.sql`

**Monthly:**
- Review and update documentation
- Add new test cases
- Performance optimization

**As Needed:**
- Add new entity classes in `src/Entities/`
- Add new services in `src/Services/`
- Add new forms in `src/Forms/`
- Update database schema

### Adding New Features

**New Entity:**
1. Create `src/Entities/NewEntity.pas`
2. Define properties and methods
3. Add to `InventorySales.dpr` uses clause

**New Service:**
1. Create `src/Services/NewService.pas`
2. Implement business logic
3. Add to `InventorySales.dpr` uses clause
4. Create tests in `tests/TestNewService.pas`

**New Form:**
1. Create `src/Forms/NewForm.pas/.fmx`
2. Design UI in FMX designer
3. Implement event handlers
4. Add to `InventorySales.dpr` uses clause

**New Report:**
1. Add SQL query to `src/Services/ReportService.pas`
2. Add to report type combo in `ReportsForm.pas`
3. Handle in `btnGenerateClick` event

---

## 🔗 Related Documentation

- **Installation**: See `README.md` → Installation & Setup
- **Deployment**: See `docs/DEPLOYMENT_GUIDE.md`
- **Quick Start**: See `QUICKSTART.md`
- **Project Summary**: See `PROJECT_SUMMARY.md`
- **Database Schema**: See `database/schema.sql` comments

---

**File Index Version**: 1.0.0
**Last Updated**: October 2025
**Total Files**: 37+
**Total Lines of Code**: ~9,520
**Documentation Words**: ~15,000
