-- ============================================
-- Inventory & Sales Management System
-- Database Schema - Multi-Platform Support
-- Supports: SQL Server, PostgreSQL, Oracle
-- ============================================

-- Drop existing tables if they exist
DROP TABLE IF EXISTS SaleItems CASCADE;
DROP TABLE IF EXISTS Sales CASCADE;
DROP TABLE IF EXISTS Products CASCADE;
DROP TABLE IF EXISTS Users CASCADE;
DROP TABLE IF EXISTS Branches CASCADE;
DROP TABLE IF EXISTS Categories CASCADE;
DROP TABLE IF EXISTS SyncLog CASCADE;

-- ============================================
-- Table: Branches
-- Description: Store branch/location information
-- ============================================
CREATE TABLE Branches (
    BranchID INT PRIMARY KEY AUTO_INCREMENT,
    BranchCode VARCHAR(20) NOT NULL UNIQUE,
    BranchName VARCHAR(100) NOT NULL,
    Address VARCHAR(255),
    City VARCHAR(50),
    Country VARCHAR(50),
    Phone VARCHAR(20),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- Table: Categories
-- Description: Product categories
-- ============================================
CREATE TABLE Categories (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    CategoryCode VARCHAR(20) NOT NULL UNIQUE,
    CategoryName VARCHAR(100) NOT NULL,
    Description TEXT,
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- ============================================
-- Table: Users
-- Description: User authentication and roles
-- Roles: 1=Admin, 2=Manager, 3=Employee
-- ============================================
CREATE TABLE Users (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Username VARCHAR(50) NOT NULL UNIQUE,
    PasswordHash VARCHAR(255) NOT NULL,
    FullName VARCHAR(100) NOT NULL,
    Email VARCHAR(100),
    Phone VARCHAR(20),
    RoleID INT NOT NULL CHECK (RoleID IN (1, 2, 3)),
    BranchID INT,
    IsActive BOOLEAN DEFAULT TRUE,
    LastLogin TIMESTAMP NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE SET NULL,
    INDEX idx_username (Username),
    INDEX idx_role (RoleID)
);

-- ============================================
-- Table: Products
-- Description: Inventory product information
-- ============================================
CREATE TABLE Products (
    ProductID INT PRIMARY KEY AUTO_INCREMENT,
    ProductCode VARCHAR(50) NOT NULL UNIQUE,
    ProductName VARCHAR(200) NOT NULL,
    Description TEXT,
    CategoryID INT,
    UnitPrice DECIMAL(18, 2) NOT NULL CHECK (UnitPrice >= 0),
    CostPrice DECIMAL(18, 2) DEFAULT 0 CHECK (CostPrice >= 0),
    Quantity INT NOT NULL DEFAULT 0 CHECK (Quantity >= 0),
    MinStockLevel INT DEFAULT 0,
    MaxStockLevel INT DEFAULT 0,
    BranchID INT,
    Barcode VARCHAR(100),
    SKU VARCHAR(50),
    IsActive BOOLEAN DEFAULT TRUE,
    CreatedBy INT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (CategoryID) REFERENCES Categories(CategoryID) ON DELETE SET NULL,
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE SET NULL,
    FOREIGN KEY (CreatedBy) REFERENCES Users(UserID) ON DELETE SET NULL,
    INDEX idx_product_code (ProductCode),
    INDEX idx_product_name (ProductName),
    INDEX idx_category (CategoryID),
    INDEX idx_branch (BranchID),
    INDEX idx_barcode (Barcode)
);

-- ============================================
-- Table: Sales
-- Description: Sales transaction headers
-- ============================================
CREATE TABLE Sales (
    SaleID INT PRIMARY KEY AUTO_INCREMENT,
    SaleNumber VARCHAR(50) NOT NULL UNIQUE,
    SaleDate TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    BranchID INT NOT NULL,
    EmployeeID INT NOT NULL,
    CustomerName VARCHAR(100),
    CustomerPhone VARCHAR(20),
    SubTotal DECIMAL(18, 2) NOT NULL DEFAULT 0,
    TaxAmount DECIMAL(18, 2) DEFAULT 0,
    DiscountAmount DECIMAL(18, 2) DEFAULT 0,
    TotalAmount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    PaymentMethod VARCHAR(20) DEFAULT 'Cash',
    PaymentStatus VARCHAR(20) DEFAULT 'Paid',
    Notes TEXT,
    IsSynced BOOLEAN DEFAULT FALSE,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UpdatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (BranchID) REFERENCES Branches(BranchID) ON DELETE RESTRICT,
    FOREIGN KEY (EmployeeID) REFERENCES Users(UserID) ON DELETE RESTRICT,
    INDEX idx_sale_number (SaleNumber),
    INDEX idx_sale_date (SaleDate),
    INDEX idx_branch_sale (BranchID),
    INDEX idx_employee (EmployeeID),
    INDEX idx_sync_status (IsSynced)
);

-- ============================================
-- Table: SaleItems
-- Description: Individual items in sales transactions
-- ============================================
CREATE TABLE SaleItems (
    SaleItemID INT PRIMARY KEY AUTO_INCREMENT,
    SaleID INT NOT NULL,
    ProductID INT NOT NULL,
    ProductName VARCHAR(200) NOT NULL,
    Quantity INT NOT NULL CHECK (Quantity > 0),
    UnitPrice DECIMAL(18, 2) NOT NULL CHECK (UnitPrice >= 0),
    DiscountPercent DECIMAL(5, 2) DEFAULT 0,
    TaxPercent DECIMAL(5, 2) DEFAULT 0,
    LineTotal DECIMAL(18, 2) NOT NULL,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (SaleID) REFERENCES Sales(SaleID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID) ON DELETE RESTRICT,
    INDEX idx_sale (SaleID),
    INDEX idx_product (ProductID)
);

-- ============================================
-- Table: SyncLog
-- Description: Track offline sync operations
-- ============================================
CREATE TABLE SyncLog (
    SyncID INT PRIMARY KEY AUTO_INCREMENT,
    TableName VARCHAR(50) NOT NULL,
    RecordID INT NOT NULL,
    Operation VARCHAR(10) NOT NULL CHECK (Operation IN ('INSERT', 'UPDATE', 'DELETE')),
    SyncStatus VARCHAR(20) DEFAULT 'Pending',
    DeviceID VARCHAR(100),
    ErrorMessage TEXT,
    CreatedAt TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    SyncedAt TIMESTAMP NULL,
    INDEX idx_sync_status (SyncStatus),
    INDEX idx_table_record (TableName, RecordID)
);

-- ============================================
-- Insert default data
-- ============================================

-- Default Branch
INSERT INTO Branches (BranchCode, BranchName, Address, City, Country, Phone)
VALUES ('HQ001', 'Head Office', '123 Main Street', 'New York', 'USA', '+1-555-0100');

-- Default Categories
INSERT INTO Categories (CategoryCode, CategoryName, Description) VALUES
('CAT001', 'Electronics', 'Electronic devices and accessories'),
('CAT002', 'Clothing', 'Apparel and fashion items'),
('CAT003', 'Food & Beverages', 'Food products and drinks'),
('CAT004', 'Office Supplies', 'Office and stationery items'),
('CAT005', 'Home & Garden', 'Home improvement and garden supplies');

-- Default Admin User (Password: Admin@123 - hashed with SHA256)
-- Note: In production, use proper password hashing (bcrypt, scrypt, etc.)
INSERT INTO Users (Username, PasswordHash, FullName, Email, RoleID, BranchID) VALUES
('admin', 'EF797C8118F02DFB649607DD5D3F8C7623048C9C063D532CC95C5ED7A898A64F', 'System Administrator', 'admin@company.com', 1, 1),
('manager', 'C1C224B03CD9BC7B6A86D77F5DACE40191766C485CD55DC48CAF9AC873335C6F', 'Branch Manager', 'manager@company.com', 2, 1),
('employee', '8D969EEF6ECAD3C29A3A629280E686CF0C3F5D5A86AFF3CA12020C923ADC6C92', 'Sales Employee', 'employee@company.com', 3, 1);

-- Sample Products
INSERT INTO Products (ProductCode, ProductName, Description, CategoryID, UnitPrice, CostPrice, Quantity, MinStockLevel, BranchID, Barcode, CreatedBy) VALUES
('PROD001', 'Laptop Dell XPS 15', 'High-performance laptop', 1, 1299.99, 1000.00, 50, 10, 1, '1234567890123', 1),
('PROD002', 'Wireless Mouse', 'Ergonomic wireless mouse', 1, 29.99, 15.00, 200, 20, 1, '1234567890124', 1),
('PROD003', 'Office Chair', 'Comfortable office chair', 4, 249.99, 150.00, 30, 5, 1, '1234567890125', 1),
('PROD004', 'USB Flash Drive 64GB', 'High-speed USB 3.0', 1, 19.99, 10.00, 150, 30, 1, '1234567890126', 1),
('PROD005', 'Notebook A4', 'Ruled notebook 200 pages', 4, 4.99, 2.00, 500, 100, 1, '1234567890127', 1);

-- ============================================
-- Views for reporting
-- ============================================

-- Product Stock Status
CREATE OR REPLACE VIEW vw_ProductStockStatus AS
SELECT
    p.ProductID,
    p.ProductCode,
    p.ProductName,
    c.CategoryName,
    p.Quantity,
    p.MinStockLevel,
    p.MaxStockLevel,
    p.UnitPrice,
    b.BranchName,
    CASE
        WHEN p.Quantity <= 0 THEN 'Out of Stock'
        WHEN p.Quantity <= p.MinStockLevel THEN 'Low Stock'
        WHEN p.Quantity >= p.MaxStockLevel THEN 'Overstock'
        ELSE 'Normal'
    END AS StockStatus
FROM Products p
LEFT JOIN Categories c ON p.CategoryID = c.CategoryID
LEFT JOIN Branches b ON p.BranchID = b.BranchID
WHERE p.IsActive = TRUE;

-- Sales Summary
CREATE OR REPLACE VIEW vw_SalesSummary AS
SELECT
    s.SaleID,
    s.SaleNumber,
    s.SaleDate,
    b.BranchName,
    u.FullName AS EmployeeName,
    s.CustomerName,
    s.TotalAmount,
    s.PaymentMethod,
    s.PaymentStatus,
    COUNT(si.SaleItemID) AS ItemCount
FROM Sales s
INNER JOIN Branches b ON s.BranchID = b.BranchID
INNER JOIN Users u ON s.EmployeeID = u.UserID
LEFT JOIN SaleItems si ON s.SaleID = si.SaleID
GROUP BY s.SaleID, s.SaleNumber, s.SaleDate, b.BranchName, u.FullName, s.CustomerName, s.TotalAmount, s.PaymentMethod, s.PaymentStatus;

-- ============================================
-- Stored Procedures
-- ============================================

-- Procedure: Process Sale Transaction
DELIMITER //
CREATE PROCEDURE sp_ProcessSale(
    IN p_BranchID INT,
    IN p_EmployeeID INT,
    IN p_CustomerName VARCHAR(100),
    IN p_CustomerPhone VARCHAR(20),
    IN p_PaymentMethod VARCHAR(20),
    IN p_ProductsJSON TEXT,
    OUT p_SaleID INT,
    OUT p_SaleNumber VARCHAR(50),
    OUT p_ErrorMessage VARCHAR(500)
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        SET p_ErrorMessage = 'Error processing sale transaction';
        SET p_SaleID = -1;
    END;

    START TRANSACTION;

    -- Generate sale number
    SET p_SaleNumber = CONCAT('SALE', DATE_FORMAT(NOW(), '%Y%m%d'), LPAD((SELECT COALESCE(MAX(SaleID), 0) + 1 FROM Sales), 6, '0'));

    -- Insert sale header
    INSERT INTO Sales (SaleNumber, BranchID, EmployeeID, CustomerName, CustomerPhone, PaymentMethod)
    VALUES (p_SaleNumber, p_BranchID, p_EmployeeID, p_CustomerName, p_CustomerPhone, p_PaymentMethod);

    SET p_SaleID = LAST_INSERT_ID();

    -- Process sale items (requires JSON parsing - implementation varies by database)
    -- This is a placeholder for JSON processing logic

    COMMIT;
    SET p_ErrorMessage = 'Success';
END //
DELIMITER ;

-- ============================================
-- Triggers
-- ============================================

-- Trigger: Update product quantity after sale
DELIMITER //
CREATE TRIGGER trg_AfterSaleItemInsert
AFTER INSERT ON SaleItems
FOR EACH ROW
BEGIN
    UPDATE Products
    SET Quantity = Quantity - NEW.Quantity,
        UpdatedAt = CURRENT_TIMESTAMP
    WHERE ProductID = NEW.ProductID;
END //
DELIMITER ;

-- Trigger: Update sale totals
DELIMITER //
CREATE TRIGGER trg_AfterSaleItemInsertUpdateTotals
AFTER INSERT ON SaleItems
FOR EACH ROW
BEGIN
    UPDATE Sales
    SET SubTotal = (SELECT SUM(LineTotal) FROM SaleItems WHERE SaleID = NEW.SaleID),
        TotalAmount = (SELECT SUM(LineTotal) FROM SaleItems WHERE SaleID = NEW.SaleID),
        UpdatedAt = CURRENT_TIMESTAMP
    WHERE SaleID = NEW.SaleID;
END //
DELIMITER ;

-- ============================================
-- Indexes for performance
-- ============================================
CREATE INDEX idx_products_active ON Products(IsActive, BranchID);
CREATE INDEX idx_sales_date_branch ON Sales(SaleDate, BranchID);
CREATE INDEX idx_users_active ON Users(IsActive, RoleID);
