# Inventory & Sales Management System

A cross-platform Inventory and Sales Management application built with Delphi FMX that enables multi-branch companies to manage products, track sales, generate reports, and synchronize data in real-time.

## Features

### ✅ Core Modules Implemented

#### 1. User Authentication & Authorization (Story 4)
- Multi-user authentication with password hashing (SHA256)
- Role-based access control (Admin, Manager, Employee)
- Session management for mobile and desktop
- Password change and reset functionality
- User management (CRUD operations)

#### 2. Inventory Management (Story 1)
- Complete CRUD operations for products
- Product categories and branches support
- Stock level tracking (min/max levels)
- Low stock and out-of-stock alerts
- Barcode and SKU support
- Profit margin calculations
- Product search and filtering

#### 3. Sales Management (Story 2)
- Record sales transactions with multiple items
- Automatic inventory updates after sales
- Customer information tracking
- Multiple payment methods (Cash, Card, Mobile, Bank)
- Discount and tax calculations
- Sale number auto-generation
- Transaction history and reporting

#### 4. Reporting & Analytics (Story 3)
- Comprehensive sales reports with date ranges
- Inventory status reports
- Top-selling products analysis
- Sales by category and employee
- Daily and monthly sales charts
- Profit analysis and margin reports
- Export to CSV (PDF export ready for integration)

#### 5. Offline Synchronization
- SQLite local database for offline mode
- Automatic sync when connection restored
- Change tracking with SyncLog
- Conflict resolution (server-wins strategy)
- Device identification and tracking
- Background sync support for mobile

## Technology Stack

- **Framework**: Delphi FMX (FireMonkey)
- **Platforms**: Windows, macOS, Android, iOS
- **Database**: SQL Server, MySQL, PostgreSQL, Oracle, SQLite
- **Data Access**: FireDAC
- **Testing**: DUnitX

## Project Structure

```
sales_inventory/
├── src/
│   ├── DataModules/
│   │   ├── DatabaseModule.pas/dfm    # FireDAC database connectivity
│   ├── Entities/
│   │   ├── UserEntity.pas            # User entity class
│   │   ├── ProductEntity.pas         # Product entity class
│   │   ├── SaleEntity.pas            # Sale & SaleItem entity classes
│   │   ├── CategoryEntity.pas        # Category entity class
│   │   └── BranchEntity.pas          # Branch entity class
│   ├── Services/
│   │   ├── AuthService.pas           # Authentication & user management
│   │   ├── ProductService.pas        # Product CRUD operations
│   │   ├── SalesService.pas          # Sales transaction processing
│   │   ├── ReportService.pas         # Reporting & analytics
│   │   └── SyncService.pas           # Offline synchronization
│   ├── Forms/
│   │   ├── LoginForm.pas/fmx         # Login screen
│   │   ├── MainForm.pas/fmx          # Main dashboard
│   │   ├── InventoryForm.pas/fmx     # Product management
│   │   ├── SalesForm.pas/fmx         # Sales transactions
│   │   └── ReportsForm.pas/fmx       # Reports & analytics
│   └── Utils/
│       ├── Constants.pas              # Application constants
│       ├── HashUtils.pas              # Password hashing utilities
│       ├── ValidationUtils.pas        # Input validation
│       └── DateTimeUtils.pas          # Date/time formatting
├── database/
│   └── schema.sql                     # Database schema with sample data
├── tests/
│   ├── TestAuthService.pas            # Authentication tests
│   └── TestProductService.pas         # Product service tests
├── docs/
├── InventorySales.dpr                 # Main project file
├── InventorySales.dproj               # Project configuration
├── InventorySales.ini.sample          # Configuration template
└── README.md                          # This file
```

## Installation & Setup

### Prerequisites

- Delphi 10.4 Sydney or later (with FMX support)
- One of the supported database servers:
  - SQL Server 2014+
  - MySQL 5.7+
  - PostgreSQL 10+
  - Oracle 12c+
  - SQLite 3+

### Database Setup

1. **Create the database**:
   ```sql
   -- For SQL Server
   CREATE DATABASE InventorySales;

   -- For MySQL
   CREATE DATABASE inventory_sales;

   -- For PostgreSQL
   CREATE DATABASE inventory_sales;
   ```

2. **Run the schema script**:
   ```bash
   # Navigate to database directory
   cd database

   # Execute schema.sql on your database
   # SQL Server:
   sqlcmd -S localhost -d InventorySales -i schema.sql

   # MySQL:
   mysql -u root -p inventory_sales < schema.sql

   # PostgreSQL:
   psql -U postgres -d inventory_sales -f schema.sql
   ```

3. **Verify installation**:
   - Check that all tables are created: `Users`, `Products`, `Sales`, `SaleItems`, `Categories`, `Branches`, `SyncLog`
   - Verify sample data is loaded (default users, categories, products)

### Application Configuration

1. **Copy the configuration template**:
   ```bash
   cp InventorySales.ini.sample InventorySales.ini
   ```

2. **Edit `InventorySales.ini`**:
   ```ini
   [Database]
   Type=SQLServer
   Server=localhost
   Database=InventorySales
   Username=sa
   Password=YourPassword
   WindowsAuth=False
   ```

3. **Configure other settings** (optional):
   - Sync server URL
   - Auto-sync interval
   - Report export path
   - Mobile offline settings

### Running the Application

1. **Open in Delphi**:
   - Open `InventorySales.dproj` in Delphi IDE
   - Select target platform (Win32, Win64, Android, iOS, macOS)

2. **Build and run**:
   - Press F9 or click Run
   - Login with default credentials:
     - **Admin**: `admin` / `Admin@123`
     - **Manager**: `manager` / `Manager@123`
     - **Employee**: `employee` / `Employee@123`

## Default User Credentials

| Username | Password | Role | Permissions |
|----------|----------|------|-------------|
| admin | Admin@123 | Administrator | Full access to all modules |
| manager | Manager@123 | Manager | Access to inventory, sales, reports |
| employee | Employee@123 | Employee | Access to sales and inventory (read-only) |

**⚠️ Important**: Change these default passwords in production!

## User Roles & Permissions

### Administrator
- Full access to all modules
- User management (create, edit, delete users)
- Product management (create, edit, delete products)
- Sales processing
- All reports access
- System configuration

### Manager
- Product management (create, edit)
- Sales processing
- Reports access (sales, inventory, analytics)
- Cannot delete products or manage users

### Employee
- View products and inventory
- Process sales transactions
- Limited report access
- No administrative functions

## Usage Guide

### Inventory Management

1. **Add New Product**:
   - Navigate to Inventory tab
   - Click "Add Product" button
   - Fill in product details (code, name, price, quantity)
   - Select category and branch
   - Save

2. **Update Stock Levels**:
   - Search or select product from grid
   - Click "Edit" button
   - Update quantity
   - Save changes

3. **Monitor Low Stock**:
   - Set minimum stock levels for products
   - System automatically flags low stock items
   - View low stock report in Reports tab

### Sales Processing

1. **Create New Sale**:
   - Navigate to Sales tab
   - Search and add products to cart
   - Enter quantity for each product
   - Apply discounts/taxes if needed
   - Enter customer information (optional)
   - Select payment method
   - Click "Process Sale"

2. **View Sales History**:
   - Navigate to Reports tab
   - Select "Sales Report"
   - Choose date range
   - Click "Generate Report"

### Reporting

Available reports:
- **Sales Report**: Detailed sales transactions
- **Inventory Report**: Current stock status
- **Top Selling Products**: Best performers
- **Sales by Category**: Category-wise analysis
- **Sales by Employee**: Employee performance
- **Low Stock Report**: Items needing reorder
- **Out of Stock Report**: Items to restock
- **Profit Analysis**: Profitability metrics

**Export Options**:
- CSV export (fully functional)
- PDF export (ready for integration with reporting library)

### Offline Mode (Mobile/Tablet)

1. **Enable Offline Mode**:
   - Application automatically switches to SQLite when network unavailable
   - All operations continue working offline

2. **Synchronization**:
   - Changes are logged in SyncLog table
   - Auto-sync when connection restored
   - Manual sync via Sync button in toolbar

3. **Conflict Resolution**:
   - Server-wins strategy by default
   - Can be customized in SyncService.pas

## Development

### Running Tests

```bash
# Run DUnitX tests
dunit-console InventorySales_Tests.dproj
```

Test coverage includes:
- Authentication service tests
- Product service tests
- Sales service tests (add as needed)
- Validation utilities tests

### Adding New Features

1. **Create Entity Class**: Add to `src/Entities/`
2. **Create Service**: Add to `src/Services/`
3. **Update UI Forms**: Modify or create forms in `src/Forms/`
4. **Add Tests**: Create test file in `tests/`
5. **Update Documentation**: Update this README

### Database Migration

To add new tables or columns:

1. Create migration SQL script in `database/migrations/`
2. Test on development database
3. Update entity classes
4. Update service layer
5. Document changes

## Deployment

### Desktop (Windows/macOS)

1. **Build Release**:
   - Select Release configuration
   - Build for target platform (Win32/Win64/macOS)

2. **Package**:
   - Include executable
   - Include `InventorySales.ini.sample`
   - Include database schema
   - Include documentation

3. **Installer** (optional):
   - Use Inno Setup (Windows) or DMG (macOS)

### Mobile (Android/iOS)

1. **Configure Mobile Settings**:
   - Set app icons and splash screens
   - Configure permissions (network, storage)
   - Set version and build numbers

2. **Build APK/IPA**:
   - Select Android/iOS platform
   - Configure deployment profile
   - Build and deploy

3. **Distribution**:
   - Google Play Store (Android)
   - Apple App Store (iOS)
   - Enterprise distribution

## Troubleshooting

### Database Connection Issues

**Problem**: Cannot connect to database

**Solutions**:
1. Verify database server is running
2. Check connection parameters in `InventorySales.ini`
3. Ensure user has proper database permissions
4. Test connection using database client tools

### Offline Sync Issues

**Problem**: Sync fails or data not syncing

**Solutions**:
1. Check server URL in configuration
2. Verify network connectivity
3. Check SyncLog table for error messages
4. Clear sync log and retry: `DELETE FROM SyncLog WHERE SyncStatus = 'Failed'`

### Permission Errors

**Problem**: User cannot access certain features

**Solutions**:
1. Verify user role in database
2. Check role-based permissions in code
3. Logout and login again to refresh session
4. Contact administrator to update user role

## Security Considerations

### Production Deployment

1. **Change Default Passwords**:
   ```sql
   -- Update admin password
   UPDATE Users SET PasswordHash = 'NewHashedPassword' WHERE Username = 'admin';
   ```

2. **Enable HTTPS**:
   - Use SSL/TLS for database connections
   - HTTPS for sync server API

3. **Implement Stronger Hashing**:
   - Replace SHA256 with bcrypt or scrypt
   - Add password salting
   - Update `HashUtils.pas`

4. **Network Security**:
   - Use VPN for remote database access
   - Implement API authentication tokens
   - Enable database encryption at rest

5. **Access Control**:
   - Regular password rotation
   - Account lockout after failed attempts
   - Session timeout enforcement
   - Audit logging

## API Integration (Future)

The sync service is designed to work with RESTful APIs. Expected endpoints:

- `POST /api/sync/upload` - Upload pending changes
- `GET /api/sync/download` - Download server changes
- `POST /api/auth/login` - Remote authentication
- `GET /api/products` - Get products list
- `POST /api/sales` - Create sale transaction

## Contributing

1. Fork the repository
2. Create feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to branch (`git push origin feature/AmazingFeature`)
5. Open Pull Request

## License

This project is proprietary software. All rights reserved.

## Support

For support and questions:
- Email: support@yourcompany.com
- Documentation: See `docs/` folder
- Issue Tracker: [GitHub Issues](https://github.com/yourrepo/issues)

## Acknowledgments

- Delphi FMX Framework by Embarcadero
- FireDAC database components
- DUnitX testing framework
- Community contributors

---

**Version**: 1.0.0
**Last Updated**: October 2025
**Author**: forever_tux
# Project

