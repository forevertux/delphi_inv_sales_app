-- ============================================
-- Demo data for Inventory & Sales (SQLite)
-- Version 2 — English (US)
-- ============================================
-- Logins: admin / Admin@123 | manager / Manager@123 | employee / Employee@123
-- ============================================

-- Always apply English labels to core rows (fixes legacy Romanian DBs)
UPDATE Branches SET BranchCode = 'MAIN', BranchName = 'Head Office',
  Address = '100 Main Street', City = 'New York', Country = 'USA',
  Phone = '+1-212-555-0100', IsActive = 1 WHERE BranchID = 1;

UPDATE Categories SET CategoryCode = 'GEN', CategoryName = 'General',
  Description = 'General merchandise', IsActive = 1 WHERE CategoryID = 1;

UPDATE Users SET FullName = 'System Administrator', Email = 'admin@demo.local',
  Phone = '+1-555-0001', RoleID = 1, BranchID = 1, IsActive = 1 WHERE Username = 'admin';

UPDATE Users SET FullName = 'Mary Johnson', Email = 'manager@demo.local',
  Phone = '+1-555-0002', RoleID = 2, BranchID = 1, IsActive = 1 WHERE Username = 'manager';

UPDATE Users SET FullName = 'John Smith', Email = 'employee@demo.local',
  Phone = '+1-555-0003', RoleID = 3, BranchID = 1, IsActive = 1 WHERE Username = 'employee';

UPDATE Users SET FullName = 'Sarah Davis', Email = 'sarah@demo.local',
  Phone = '+1-555-0004', RoleID = 3, BranchID = 2, IsActive = 1 WHERE Username = 'employee2';

-- Branches
INSERT OR REPLACE INTO Branches (BranchID, BranchCode, BranchName, Address, City, Country, Phone, IsActive)
VALUES (1, 'MAIN', 'Head Office', '100 Main Street', 'New York', 'USA', '+1-212-555-0100', 1);

INSERT OR REPLACE INTO Branches (BranchID, BranchCode, BranchName, Address, City, Country, Phone, IsActive)
VALUES (2, 'WEST', 'West Branch', '500 Market Street', 'San Francisco', 'USA', '+1-415-555-0200', 1);

-- Categories
INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(1, 'GEN', 'General', 'General merchandise', 1);

INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(2, 'ELEC', 'Electronics', 'Computers and accessories', 1);

INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(3, 'CLTH', 'Clothing', 'Apparel and accessories', 1);

INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(4, 'FOOD', 'Food & Beverage', 'Food and drinks', 1);

INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(5, 'OFFC', 'Office Supplies', 'Office and stationery', 1);

INSERT OR REPLACE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(6, 'HOME', 'Home & Garden', 'Home and garden items', 1);

-- Users
INSERT OR REPLACE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (1, 'admin', 'E86F78A8A3CAF0B60D8E74E5942AA6D86DC150CD3C03338AEF25B7D2D7E3ACC7',
  'System Administrator', 'admin@demo.local', '+1-555-0001', 1, 1, 1);

INSERT OR REPLACE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (2, 'manager', 'E8392925A98C9C22795D1FC5D0DFEE5B9A6943F6B768EC5A2A0C077E5ED119CF',
  'Mary Johnson', 'manager@demo.local', '+1-555-0002', 2, 1, 1);

INSERT OR REPLACE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (3, 'employee', 'B4BD29480AB196FAA782E0D4ECD10C2F4212814105227E5F7992F5BF4B212A64',
  'John Smith', 'employee@demo.local', '+1-555-0003', 3, 1, 1);

INSERT OR REPLACE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (4, 'employee2', 'B4BD29480AB196FAA782E0D4ECD10C2F4212814105227E5F7992F5BF4B212A64',
  'Sarah Davis', 'sarah@demo.local', '+1-555-0004', 3, 2, 1);

-- Products (English labels; update existing DEMO rows, then insert missing)
UPDATE Products SET ProductName = 'Dell Latitude 5540 Laptop', Description = 'Business laptop 15.6 inch',
  CategoryID = 2, UnitPrice = 1299.00, CostPrice = 980.00, Quantity = 12, MinStockLevel = 3, MaxStockLevel = 30,
  BranchID = 1, Barcode = '5901234567001', IsActive = 1 WHERE ProductCode = 'DEMO001';

UPDATE Products SET ProductName = 'Logitech M650 Wireless Mouse', Description = 'Ergonomic wireless mouse',
  CategoryID = 2, UnitPrice = 29.99, CostPrice = 15.00, Quantity = 85, MinStockLevel = 15, MaxStockLevel = 150,
  BranchID = 1, Barcode = '5901234567002', IsActive = 1 WHERE ProductCode = 'DEMO002';

UPDATE Products SET ProductName = 'Keychron K2 Mechanical Keyboard', Description = 'Mechanical keyboard Bluetooth',
  CategoryID = 2, UnitPrice = 89.00, CostPrice = 55.00, Quantity = 22, MinStockLevel = 5, MaxStockLevel = 40,
  BranchID = 1, Barcode = '5901234567003', IsActive = 1 WHERE ProductCode = 'DEMO003';

UPDATE Products SET ProductName = 'LG 27 inch 4K Monitor', Description = 'IPS monitor 27 inch',
  CategoryID = 2, UnitPrice = 399.00, CostPrice = 290.00, Quantity = 8, MinStockLevel = 2, MaxStockLevel = 20,
  BranchID = 1, Barcode = '5901234567004', IsActive = 1 WHERE ProductCode = 'DEMO004';

UPDATE Products SET ProductName = 'USB-C Hub 7-in-1', Description = 'USB-C hub with HDMI and card reader',
  CategoryID = 2, UnitPrice = 49.99, CostPrice = 25.00, Quantity = 45, MinStockLevel = 10, MaxStockLevel = 80,
  BranchID = 1, Barcode = '5901234567005', IsActive = 1 WHERE ProductCode = 'DEMO005';

UPDATE Products SET ProductName = 'Cotton T-Shirt White M', Description = '100% cotton t-shirt',
  CategoryID = 3, UnitPrice = 19.99, CostPrice = 9.00, Quantity = 120, MinStockLevel = 20, MaxStockLevel = 200,
  BranchID = 1, Barcode = '5901234567010', IsActive = 1 WHERE ProductCode = 'DEMO006';

UPDATE Products SET ProductName = 'Men Blue Jeans 32', Description = 'Regular fit jeans',
  CategoryID = 3, UnitPrice = 59.99, CostPrice = 32.00, Quantity = 38, MinStockLevel = 8, MaxStockLevel = 60,
  BranchID = 1, Barcode = '5901234567011', IsActive = 1 WHERE ProductCode = 'DEMO007';

UPDATE Products SET ProductName = 'Winter Jacket L', Description = 'Waterproof jacket',
  CategoryID = 3, UnitPrice = 129.00, CostPrice = 75.00, Quantity = 15, MinStockLevel = 4, MaxStockLevel = 25,
  BranchID = 1, Barcode = '5901234567012', IsActive = 1 WHERE ProductCode = 'DEMO008';

UPDATE Products SET ProductName = 'Arabica Coffee Beans 1kg', Description = 'Fresh roasted coffee',
  CategoryID = 4, UnitPrice = 24.99, CostPrice = 12.00, Quantity = 6, MinStockLevel = 10, MaxStockLevel = 50,
  BranchID = 1, Barcode = '5901234567020', IsActive = 1 WHERE ProductCode = 'DEMO009';

UPDATE Products SET ProductName = 'Mineral Water 2L x6', Description = 'Pack of 6 bottles',
  CategoryID = 4, UnitPrice = 8.99, CostPrice = 4.50, Quantity = 180, MinStockLevel = 30, MaxStockLevel = 300,
  BranchID = 1, Barcode = '5901234567021', IsActive = 1 WHERE ProductCode = 'DEMO010';

UPDATE Products SET ProductName = 'Dark Chocolate 100g', Description = '85% cacao chocolate',
  CategoryID = 4, UnitPrice = 4.49, CostPrice = 2.00, Quantity = 95, MinStockLevel = 20, MaxStockLevel = 150,
  BranchID = 1, Barcode = '5901234567022', IsActive = 1 WHERE ProductCode = 'DEMO011';

UPDATE Products SET ProductName = 'A4 Copy Paper 500 sheets', Description = '80g copy paper',
  CategoryID = 5, UnitPrice = 9.99, CostPrice = 5.50, Quantity = 14, MinStockLevel = 10, MaxStockLevel = 100,
  BranchID = 1, Barcode = '5901234567030', IsActive = 1 WHERE ProductCode = 'DEMO012';

UPDATE Products SET ProductName = 'Bic Cristal Pen Set 50', Description = 'Blue ballpoint pens',
  CategoryID = 5, UnitPrice = 12.99, CostPrice = 6.00, Quantity = 2, MinStockLevel = 10, MaxStockLevel = 80,
  BranchID = 1, Barcode = '5901234567031', IsActive = 1 WHERE ProductCode = 'DEMO013';

UPDATE Products SET ProductName = 'A4 Plastic Folder', Description = 'Elastic closure folder',
  CategoryID = 5, UnitPrice = 1.99, CostPrice = 0.75, Quantity = 250, MinStockLevel = 50, MaxStockLevel = 500,
  BranchID = 1, Barcode = '5901234567032', IsActive = 1 WHERE ProductCode = 'DEMO014';

UPDATE Products SET ProductName = 'Ergonomic Office Chair', Description = 'Height adjustable chair',
  CategoryID = 6, UnitPrice = 299.00, CostPrice = 180.00, Quantity = 9, MinStockLevel = 3, MaxStockLevel = 15,
  BranchID = 1, Barcode = '5901234567040', IsActive = 1 WHERE ProductCode = 'DEMO015';

UPDATE Products SET ProductName = 'LED Desk Lamp', Description = 'Adjustable LED lamp',
  CategoryID = 6, UnitPrice = 39.99, CostPrice = 22.00, Quantity = 0, MinStockLevel = 5, MaxStockLevel = 30,
  BranchID = 1, Barcode = '5901234567041', IsActive = 1 WHERE ProductCode = 'DEMO016';

UPDATE Products SET ProductName = 'Office Cleaning Kit', Description = 'Desk cleaning supplies',
  CategoryID = 6, UnitPrice = 18.00, CostPrice = 9.00, Quantity = 33, MinStockLevel = 8, MaxStockLevel = 60,
  BranchID = 1, Barcode = '5901234567042', IsActive = 1 WHERE ProductCode = 'DEMO017';

UPDATE Products SET ProductName = 'HP ProBook Laptop West', Description = 'Branch stock laptop',
  CategoryID = 2, UnitPrice = 1099.00, CostPrice = 850.00, Quantity = 5, MinStockLevel = 2, MaxStockLevel = 12,
  BranchID = 2, Barcode = '5901234567050', IsActive = 1 WHERE ProductCode = 'DEMO018';

UPDATE Products SET ProductName = 'Brother Laser Printer', Description = 'Monochrome A4 printer',
  CategoryID = 2, UnitPrice = 249.00, CostPrice = 165.00, Quantity = 7, MinStockLevel = 2, MaxStockLevel = 15,
  BranchID = 1, Barcode = '5901234567051', IsActive = 1 WHERE ProductCode = 'DEMO019';

UPDATE Products SET ProductName = 'A5 Ruled Notebook', Description = '80 sheet notebook',
  CategoryID = 5, UnitPrice = 3.99, CostPrice = 1.50, Quantity = 4, MinStockLevel = 15, MaxStockLevel = 120,
  BranchID = 1, Barcode = '5901234567052', IsActive = 1 WHERE ProductCode = 'DEMO020';

INSERT OR IGNORE INTO Products (ProductCode, ProductName, Description, CategoryID, UnitPrice, CostPrice, Quantity, MinStockLevel, MaxStockLevel, BranchID, Barcode, CreatedBy, IsActive) VALUES
('DEMO001', 'Dell Latitude 5540 Laptop', 'Business laptop 15.6 inch', 2, 1299.00, 980.00, 12, 3, 30, 1, '5901234567001', 1, 1),
('DEMO002', 'Logitech M650 Wireless Mouse', 'Ergonomic wireless mouse', 2, 29.99, 15.00, 85, 15, 150, 1, '5901234567002', 1, 1),
('DEMO003', 'Keychron K2 Mechanical Keyboard', 'Mechanical keyboard Bluetooth', 2, 89.00, 55.00, 22, 5, 40, 1, '5901234567003', 1, 1),
('DEMO004', 'LG 27 inch 4K Monitor', 'IPS monitor 27 inch', 2, 399.00, 290.00, 8, 2, 20, 1, '5901234567004', 1, 1),
('DEMO005', 'USB-C Hub 7-in-1', 'USB-C hub with HDMI and card reader', 2, 49.99, 25.00, 45, 10, 80, 1, '5901234567005', 1, 1),
('DEMO006', 'Cotton T-Shirt White M', '100% cotton t-shirt', 3, 19.99, 9.00, 120, 20, 200, 1, '5901234567010', 1, 1),
('DEMO007', 'Men Blue Jeans 32', 'Regular fit jeans', 3, 59.99, 32.00, 38, 8, 60, 1, '5901234567011', 1, 1),
('DEMO008', 'Winter Jacket L', 'Waterproof jacket', 3, 129.00, 75.00, 15, 4, 25, 1, '5901234567012', 1, 1),
('DEMO009', 'Arabica Coffee Beans 1kg', 'Fresh roasted coffee', 4, 24.99, 12.00, 6, 10, 50, 1, '5901234567020', 1, 1),
('DEMO010', 'Mineral Water 2L x6', 'Pack of 6 bottles', 4, 8.99, 4.50, 180, 30, 300, 1, '5901234567021', 1, 1),
('DEMO011', 'Dark Chocolate 100g', '85% cacao chocolate', 4, 4.49, 2.00, 95, 20, 150, 1, '5901234567022', 1, 1),
('DEMO012', 'A4 Copy Paper 500 sheets', '80g copy paper', 5, 9.99, 5.50, 14, 10, 100, 1, '5901234567030', 1, 1),
('DEMO013', 'Bic Cristal Pen Set 50', 'Blue ballpoint pens', 5, 12.99, 6.00, 2, 10, 80, 1, '5901234567031', 1, 1),
('DEMO014', 'A4 Plastic Folder', 'Elastic closure folder', 5, 1.99, 0.75, 250, 50, 500, 1, '5901234567032', 1, 1),
('DEMO015', 'Ergonomic Office Chair', 'Height adjustable chair', 6, 299.00, 180.00, 9, 3, 15, 1, '5901234567040', 1, 1),
('DEMO016', 'LED Desk Lamp', 'Adjustable LED lamp', 6, 39.99, 22.00, 0, 5, 30, 1, '5901234567041', 1, 1),
('DEMO017', 'Office Cleaning Kit', 'Desk cleaning supplies', 6, 18.00, 9.00, 33, 8, 60, 1, '5901234567042', 1, 1),
('DEMO018', 'HP ProBook Laptop West', 'Branch stock laptop', 2, 1099.00, 850.00, 5, 2, 12, 2, '5901234567050', 2, 1),
('DEMO019', 'Brother Laser Printer', 'Monochrome A4 printer', 2, 249.00, 165.00, 7, 2, 15, 1, '5901234567051', 1, 1),
('DEMO020', 'A5 Ruled Notebook', '80 sheet notebook', 5, 3.99, 1.50, 4, 15, 120, 1, '5901234567052', 1, 1);

-- Remove legacy Romanian branch code if present
DELETE FROM Branches WHERE BranchCode = 'CLUJ' AND BranchID <> 2;

-- Sales
INSERT OR IGNORE INTO Sales (SaleID, SaleNumber, SaleDate, BranchID, EmployeeID, CustomerName, CustomerPhone, SubTotal, DiscountAmount, TaxAmount, TotalAmount, PaymentMethod, PaymentStatus, IsSynced) VALUES
(1, 'SALE202505150001', datetime('now', '-16 days'), 1, 3, 'Robert Miller', '+1-555-1001', 1328.99, 0, 0, 1328.99, 'Card', 'Paid', 1),
(2, 'SALE202505180002', datetime('now', '-13 days'), 1, 3, 'Lisa Anderson', '+1-555-1002', 67.96, 0, 0, 67.96, 'Cash', 'Paid', 1),
(3, 'SALE202505200003', datetime('now', '-11 days'), 1, 4, 'Acme Corp', '+1-555-2000', 399.00, 20.00, 0, 379.00, 'Bank Transfer', 'Paid', 1),
(4, 'SALE202505220004', datetime('now', '-9 days'), 1, 3, 'Mike Thompson', '+1-555-1003', 13.47, 0, 0, 13.47, 'Cash', 'Paid', 1),
(5, 'SALE202505250005', datetime('now', '-6 days'), 1, 2, 'Design Studio LLC', '+1-555-1004', 387.99, 0, 0, 387.99, 'Card', 'Paid', 1),
(6, 'SALE202505280006', datetime('now', '-3 days'), 2, 4, 'Bay College', '+1-555-3000', 1099.00, 0, 0, 1099.00, 'Card', 'Paid', 1),
(7, 'SALE202505300007', datetime('now', '-1 days'), 1, 3, 'Walk-in Customer', NULL, 17.98, 0, 0, 17.98, 'Cash', 'Paid', 1),
(8, 'SALE202506010008', datetime('now', '-6 hours'), 1, 3, 'Emily Clark', '+1-555-1005', 299.00, 0, 0, 299.00, 'Mobile', 'Paid', 1);

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 1, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO001';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 1, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO002';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 2, p.ProductID, p.ProductName, 2, p.UnitPrice, 0, 0, p.UnitPrice * 2 FROM Products p WHERE p.ProductCode = 'DEMO006';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 2, p.ProductID, p.ProductName, 2, p.UnitPrice, 0, 0, p.UnitPrice * 2 FROM Products p WHERE p.ProductCode = 'DEMO010';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 3, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO004';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 4, p.ProductID, p.ProductName, 3, p.UnitPrice, 0, 0, p.UnitPrice * 3 FROM Products p WHERE p.ProductCode = 'DEMO011';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 5, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO015';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 5, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO003';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 6, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO018';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 7, p.ProductID, p.ProductName, 2, p.UnitPrice, 0, 0, p.UnitPrice * 2 FROM Products p WHERE p.ProductCode = 'DEMO010';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 8, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO015';

INSERT OR REPLACE INTO SyncMetadata (MetaKey, MetaValue, UpdatedAt)
VALUES ('DemoDataVersion', '2', CURRENT_TIMESTAMP);
