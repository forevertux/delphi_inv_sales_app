-- ============================================
-- Demo data for Inventory & Sales (SQLite)
-- Safe to run multiple times (INSERT OR IGNORE)
-- ============================================
-- Demo logins:
--   admin    / Admin@123
--   manager  / Manager@123
--   employee / Employee@123
-- ============================================

-- Branches
INSERT OR IGNORE INTO Branches (BranchID, BranchCode, BranchName, Address, City, Country, Phone, IsActive)
VALUES (1, 'MAIN', 'Sediu Central', 'Calea Victoriei 100', 'Bucuresti', 'Romania', '+40-21-0000001', 1);

INSERT OR IGNORE INTO Branches (BranchID, BranchCode, BranchName, Address, City, Country, Phone, IsActive)
VALUES (2, 'CLUJ', 'Filiala Cluj', 'Str. Memorandumului 28', 'Cluj-Napoca', 'Romania', '+40-264-000002', 1);

-- Categories
INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(1, 'GEN', 'General', 'Produse generale', 1);

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(2, 'ELEC', 'Electronice', 'Dispozitive si accesorii IT', 1);

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(3, 'IMBR', 'Imbracaminte', 'Haine si accesorii', 1);

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(4, 'ALIM', 'Alimente', 'Produse alimentare', 1);

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(5, 'BIRO', 'Birotica', 'Materiale de birou', 1);

INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName, Description, IsActive) VALUES
(6, 'CASA', 'Casa & Gradina', 'Articole pentru casa', 1);

-- Users (SHA256 UTF-8, same as Delphi THashSHA2)
INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (1, 'admin', 'E86F78A8A3CAF0B60D8E74E5942AA6D86DC150CD3C03338AEF25B7D2D7E3ACC7',
  'Administrator Sistem', 'admin@demo.local', '+40-700-000001', 1, 1, 1);

INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (2, 'manager', 'E8392925A98C9C22795D1FC5D0DFEE5B9A6943F6B768EC5A2A0C077E5ED119CF',
  'Maria Ionescu', 'manager@demo.local', '+40-700-000002', 2, 1, 1);

INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (3, 'employee', 'B4BD29480AB196FAA782E0D4ECD10C2F4212814105227E5F7992F5BF4B212A64',
  'Andrei Popescu', 'employee@demo.local', '+40-700-000003', 3, 1, 1);

INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive)
VALUES (4, 'employee2', 'B4BD29480AB196FAA782E0D4ECD10C2F4212814105227E5F7992F5BF4B212A64',
  'Elena Dumitrescu', 'elena@demo.local', '+40-700-000004', 3, 2, 1);

-- Products
INSERT OR IGNORE INTO Products (ProductCode, ProductName, Description, CategoryID, UnitPrice, CostPrice, Quantity, MinStockLevel, MaxStockLevel, BranchID, Barcode, CreatedBy, IsActive) VALUES
('DEMO001', 'Laptop Dell Latitude 5540', 'Laptop business 15.6 inch', 2, 5499.00, 4200.00, 12, 3, 30, 1, '5901234567001', 1, 1),
('DEMO002', 'Mouse wireless Logitech M650', 'Mouse ergonomic wireless', 2, 89.99, 45.00, 85, 15, 150, 1, '5901234567002', 1, 1),
('DEMO003', 'Tastatura mecanica Keychron K2', 'Tastatura mecanica Bluetooth', 2, 449.00, 280.00, 22, 5, 40, 1, '5901234567003', 1, 1),
('DEMO004', 'Monitor LG 27 inch 4K', 'Monitor IPS 27 inch', 2, 1899.00, 1400.00, 8, 2, 20, 1, '5901234567004', 1, 1),
('DEMO005', 'USB-C Hub 7-in-1', 'Hub USB-C cu HDMI si card reader', 2, 129.99, 65.00, 45, 10, 80, 1, '5901234567005', 1, 1),
('DEMO006', 'Tricou bumbac alb M', 'Tricou 100% bumbac', 3, 49.99, 22.00, 120, 20, 200, 1, '5901234567010', 1, 1),
('DEMO007', 'Jeans barbati albastru 32', 'Jeans regular fit', 3, 189.99, 95.00, 38, 8, 60, 1, '5901234567011', 1, 1),
('DEMO008', 'Geaca de iarna L', 'Geaca impermeabila', 3, 399.00, 220.00, 15, 4, 25, 1, '5901234567012', 1, 1),
('DEMO009', 'Cafea boabe Arabica 1kg', 'Cafea proaspat prajita', 4, 54.99, 28.00, 6, 10, 50, 1, '5901234567020', 1, 1),
('DEMO010', 'Apa minerala 2L x6', 'Pachet 6 sticle apa', 4, 18.99, 9.50, 180, 30, 300, 1, '5901234567021', 1, 1),
('DEMO011', 'Ciocolata neagra 100g', 'Ciocolata 85% cacao', 4, 12.49, 5.50, 95, 20, 150, 1, '5901234567022', 1, 1),
('DEMO012', 'Hartie A4 500 coli', 'Hartie copiator A4 80g', 5, 24.99, 14.00, 14, 10, 100, 1, '5901234567030', 1, 1),
('DEMO013', 'Pix Bic Cristal set 50', 'Set pixuri albastre', 5, 19.99, 8.00, 2, 10, 80, 1, '5901234567031', 1, 1),
('DEMO014', 'Dosar plastic A4', 'Dosar cu elastic', 5, 3.99, 1.20, 250, 50, 500, 1, '5901234567032', 1, 1),
('DEMO015', 'Scaun birou ergonomic', 'Scaun reglabil pe inaltime', 6, 899.00, 520.00, 9, 3, 15, 1, '5901234567040', 1, 1),
('DEMO016', 'Lampa birou LED', 'Lampa LED reglabila', 6, 159.99, 80.00, 0, 5, 30, 1, '5901234567041', 1, 1),
('DEMO017', 'Pachet curatenie birou', 'Kit curatenie birou', 6, 45.00, 22.00, 33, 8, 60, 1, '5901234567042', 1, 1),
('DEMO018', 'Laptop HP ProBook Cluj', 'Laptop filiala Cluj', 2, 4299.00, 3500.00, 5, 2, 12, 2, '5901234567050', 2, 1),
('DEMO019', 'Imprimanta laser Brother', 'Imprimanta monocrom A4', 2, 749.00, 480.00, 7, 2, 15, 1, '5901234567051', 1, 1),
('DEMO020', 'Caiet A5 dictando', 'Caiet 80 file', 5, 8.99, 3.50, 4, 15, 120, 1, '5901234567052', 1, 1);

-- Sales (historical demo transactions)
INSERT OR IGNORE INTO Sales (SaleID, SaleNumber, SaleDate, BranchID, EmployeeID, CustomerName, CustomerPhone, SubTotal, DiscountAmount, TaxAmount, TotalAmount, PaymentMethod, PaymentStatus, IsSynced) VALUES
(1, 'SALE202505150001', datetime('now', '-16 days'), 1, 3, 'Ion Vasilescu', '0721000001', 5588.99, 0, 0, 5588.99, 'Card', 'Paid', 1),
(2, 'SALE202505180002', datetime('now', '-13 days'), 1, 3, 'Ana Marinescu', '0721000002', 239.98, 0, 0, 239.98, 'Cash', 'Paid', 1),
(3, 'SALE202505200003', datetime('now', '-11 days'), 1, 4, 'SC Tech SRL', '0264000111', 1899.00, 50.00, 0, 1849.00, 'Bank Transfer', 'Paid', 1),
(4, 'SALE202505220004', datetime('now', '-9 days'), 1, 3, 'Mihai Georgescu', '0721000003', 74.97, 0, 0, 74.97, 'Cash', 'Paid', 1),
(5, 'SALE202505250005', datetime('now', '-6 days'), 1, 2, 'PFA Design Studio', '0721000004', 1048.98, 0, 0, 1048.98, 'Card', 'Paid', 1),
(6, 'SALE202505280006', datetime('now', '-3 days'), 2, 4, 'Universitate Cluj', '0264000222', 4299.00, 0, 0, 4299.00, 'Card', 'Paid', 1),
(7, 'SALE202505300007', datetime('now', '-1 days'), 1, 3, 'Walk-in Customer', NULL, 37.98, 0, 0, 37.98, 'Cash', 'Paid', 1),
(8, 'SALE202506010008', datetime('now', '-6 hours'), 1, 3, 'Elena Stan', '0721000005', 899.00, 0, 0, 899.00, 'Mobile', 'Paid', 1);

-- Sale items (resolve ProductID by ProductCode)
INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 1, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO001';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 1, p.ProductID, p.ProductName, 1, p.UnitPrice, 0, 0, p.UnitPrice FROM Products p WHERE p.ProductCode = 'DEMO002';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 2, p.ProductID, p.ProductName, 2, p.UnitPrice, 0, 0, p.UnitPrice * 2 FROM Products p WHERE p.ProductCode = 'DEMO006';

INSERT OR IGNORE INTO SaleItems (SaleID, ProductID, ProductName, Quantity, UnitPrice, DiscountPercent, TaxPercent, LineTotal)
SELECT 2, p.ProductID, p.ProductName, 2, p.UnitPrice, 0, 0, p.UnitPrice * 2 FROM Products p WHERE p.ProductCode = 'DEMO007';

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

-- Mark demo seed version
INSERT OR REPLACE INTO SyncMetadata (MetaKey, MetaValue, UpdatedAt)
VALUES ('DemoDataVersion', '1', CURRENT_TIMESTAMP);
