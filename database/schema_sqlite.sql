-- ============================================
-- Inventory & Sales Management System
-- Database Schema - SQLite
-- ============================================

-- Branches table
CREATE TABLE IF NOT EXISTS Branches (
    BranchID INTEGER PRIMARY KEY AUTOINCREMENT,
    BranchCode TEXT NOT NULL UNIQUE,
    BranchName TEXT NOT NULL,
    Address TEXT,
    City TEXT,
    Country TEXT,
    Phone TEXT,
    IsActive INTEGER DEFAULT 1,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Categories table
CREATE TABLE IF NOT EXISTS Categories (
    CategoryID INTEGER PRIMARY KEY AUTOINCREMENT,
    CategoryCode TEXT NOT NULL UNIQUE,
    CategoryName TEXT NOT NULL,
    Description TEXT,
    IsActive INTEGER DEFAULT 1,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Users table
CREATE TABLE IF NOT EXISTS Users (
    UserID INTEGER PRIMARY KEY AUTOINCREMENT,
    Username TEXT NOT NULL UNIQUE,
    PasswordHash TEXT NOT NULL,
    FullName TEXT NOT NULL,
    Email TEXT,
    Phone TEXT,
    RoleID INTEGER NOT NULL CHECK (RoleID IN (1, 2, 3)),
    BranchID INTEGER,
    IsActive INTEGER DEFAULT 1,
    LastLogin DATETIME,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);

CREATE INDEX IF NOT EXISTS idx_users_username ON Users(Username);
CREATE INDEX IF NOT EXISTS idx_users_role ON Users(RoleID);

-- Products table
CREATE TABLE IF NOT EXISTS Products (
    ProductID INTEGER PRIMARY KEY AUTOINCREMENT,
    ProductCode TEXT NOT NULL UNIQUE,
    ProductName TEXT NOT NULL,
    Description TEXT,
    CategoryID INTEGER,
    UnitPrice REAL NOT NULL CHECK (UnitPrice >= 0),
    CostPrice REAL DEFAULT 0 CHECK (CostPrice >= 0),
    Quantity INTEGER NOT NULL DEFAULT 0 CHECK (Quantity >= 0),
    MinStockLevel INTEGER DEFAULT 0,
    MaxStockLevel INTEGER DEFAULT 0,
    BranchID INTEGER,
    Barcode TEXT,
    SKU TEXT,
    IsActive INTEGER DEFAULT 1,
    CreatedBy INTEGER,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID),
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID),
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserID)
);

CREATE INDEX IF NOT EXISTS idx_products_code ON Products(ProductCode);
CREATE INDEX IF NOT EXISTS idx_products_name ON Products(ProductName);
CREATE INDEX IF NOT EXISTS idx_products_category ON Products(CategoryID);
CREATE INDEX IF NOT EXISTS idx_products_branch ON Products(BranchID);
CREATE INDEX IF NOT EXISTS idx_products_barcode ON Products(Barcode);

-- Sales table
CREATE TABLE IF NOT EXISTS Sales (
    SaleID INTEGER PRIMARY KEY AUTOINCREMENT,
    SaleNumber TEXT NOT NULL UNIQUE,
    SaleDate DATETIME DEFAULT CURRENT_TIMESTAMP,
    EmployeeID INTEGER,
    BranchID INTEGER,
    CustomerName TEXT,
    CustomerEmail TEXT,
    CustomerPhone TEXT,
    SubTotal REAL NOT NULL DEFAULT 0,
    DiscountAmount REAL DEFAULT 0,
    TaxAmount REAL DEFAULT 0,
    TotalAmount REAL NOT NULL,
    PaymentMethod TEXT,
    PaymentStatus TEXT DEFAULT 'Paid',
    Notes TEXT,
    IsSynced INTEGER DEFAULT 0,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (EmployeeID) REFERENCES Users(UserID),
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID)
);

CREATE INDEX IF NOT EXISTS idx_sales_number ON Sales(SaleNumber);
CREATE INDEX IF NOT EXISTS idx_sales_date ON Sales(SaleDate);
CREATE INDEX IF NOT EXISTS idx_sales_employee ON Sales(EmployeeID);
CREATE INDEX IF NOT EXISTS idx_sales_branch ON Sales(BranchID);

-- SaleItems table
CREATE TABLE IF NOT EXISTS SaleItems (
    SaleItemID INTEGER PRIMARY KEY AUTOINCREMENT,
    SaleID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    ProductCode TEXT,
    ProductName TEXT,
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    UnitPrice REAL NOT NULL,
    Discount REAL DEFAULT 0,
    LineTotal REAL NOT NULL,
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

CREATE INDEX IF NOT EXISTS idx_saleitems_sale ON SaleItems(SaleID);
CREATE INDEX IF NOT EXISTS idx_saleitems_product ON SaleItems(ProductID);

-- SyncLog table
CREATE TABLE IF NOT EXISTS SyncLog (
    SyncID INTEGER PRIMARY KEY AUTOINCREMENT,
    TableName TEXT NOT NULL,
    RecordID INTEGER NOT NULL,
    Operation TEXT NOT NULL,
    SyncStatus TEXT DEFAULT 'Pending',
    ErrorMessage TEXT,
    DeviceID TEXT,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP,
    SyncedAt DATETIME
);

CREATE INDEX IF NOT EXISTS idx_synclog_status ON SyncLog(SyncStatus);
CREATE INDEX IF NOT EXISTS idx_synclog_table ON SyncLog(TableName, RecordID);

-- SyncMetadata table
CREATE TABLE IF NOT EXISTS SyncMetadata (
    MetaKey TEXT PRIMARY KEY,
    MetaValue TEXT,
    UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Insert default data
INSERT OR IGNORE INTO Branches (BranchID, BranchCode, BranchName, City, Country)
VALUES (1, 'MAIN', 'Main Branch', 'Bucharest', 'Romania');

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName)
VALUES (1, 'GEN', 'General');

-- Insert default admin user (password: Admin@123)
-- SHA256 hash of 'Admin@123'
INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, RoleID, BranchID)
VALUES (1, 'admin', '6B3A55E0261B0304143F805A24924D0C1C44524821305F31D9277843B8A10F4E', 'System Administrator', 1, 1);
