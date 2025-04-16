unit TestProductService;

interface

uses
  DUnitX.TestFramework, ProductService, ProductEntity, AuthService, DatabaseModule;

type
  [TestFixture]
  TTestProductService = class
  private
    FProductService: TProductService;
    FTestProductID: Integer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestCreateProduct;
    [Test]
    procedure TestGetProductByID;
    [Test]
    procedure TestGetProductByCode;
    [Test]
    procedure TestGetProductByBarcode;
    [Test]
    procedure TestGetAllProducts;
    [Test]
    procedure TestGetProductsByCategory;
    [Test]
    procedure TestGetLowStockProducts;
    [Test]
    procedure TestSearchProducts;
    [Test]
    procedure TestUpdateProduct;
    [Test]
    procedure TestUpdateStock;
    [Test]
    procedure TestCheckStock;
    [Test]
    procedure TestDeleteProduct;
  end;

implementation

uses
  System.SysUtils, Constants;

procedure TTestProductService.Setup;
begin
  // Initialize database connection
  if not DMDatabase.IsConnected then
    DMDatabase.Connect;

  // Login as admin for testing
  GAuthService.Login('admin', 'Admin@123');

  FProductService := TProductService.Create;
  FTestProductID := 0;
end;

procedure TTestProductService.TearDown;
begin
  // Clean up test product if created
  if FTestProductID > 0 then
    FProductService.DeleteProduct(FTestProductID);

  FProductService.Free;
  GAuthService.Logout;
end;

procedure TTestProductService.TestCreateProduct;
var
  Product: TProduct;
  CreateResult: Boolean;
begin
  Product := TProduct.Create;
  try
    Product.ProductCode := 'TEST' + FormatDateTime('yyyymmddhhnnss', Now);
    Product.ProductName := 'Test Product';
    Product.Description := 'Test Description';
    Product.CategoryID := 1;
    Product.UnitPrice := 99.99;
    Product.CostPrice := 50.00;
    Product.Quantity := 100;
    Product.MinStockLevel := 10;
    Product.MaxStockLevel := 200;
    Product.BranchID := 1;
    Product.Barcode := 'BARCODE' + FormatDateTime('hhnnss', Now);

    CreateResult := FProductService.CreateProduct(Product);
    Assert.IsTrue(CreateResult, 'Product creation should succeed');

    // Store product ID for cleanup
    if CreateResult then
      FTestProductID := Product.ProductID;
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestGetProductByID;
var
  Product: TProduct;
begin
  Product := FProductService.GetProductByID(1); // Get first product
  try
    Assert.IsNotNull(Product, 'Product should be found');
    Assert.AreEqual(1, Product.ProductID, 'ProductID should be 1');
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestGetProductByCode;
var
  Product: TProduct;
begin
  Product := FProductService.GetProductByCode('PROD001');
  try
    Assert.IsNotNull(Product, 'Product should be found by code');
    Assert.AreEqual('PROD001', Product.ProductCode, 'Product code should match');
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestGetProductByBarcode;
var
  Product: TProduct;
begin
  Product := FProductService.GetProductByBarcode('1234567890123');
  try
    if Assigned(Product) then
    begin
      Assert.AreEqual('1234567890123', Product.Barcode, 'Barcode should match');
    end;
  finally
    if Assigned(Product) then
      Product.Free;
  end;
end;

procedure TTestProductService.TestGetAllProducts;
var
  Products: TArray<TProduct>;
  I: Integer;
begin
  Products := FProductService.GetAllProducts;
  Assert.IsTrue(Length(Products) > 0, 'Should return at least one product');

  // Clean up
  for I := Low(Products) to High(Products) do
    Products[I].Free;
end;

procedure TTestProductService.TestGetProductsByCategory;
var
  Products: TArray<TProduct>;
  I: Integer;
begin
  Products := FProductService.GetProductsByCategory(1);

  // Verify all returned products belong to category 1
  for I := Low(Products) to High(Products) do
  begin
    Assert.AreEqual(1, Products[I].CategoryID, 'All products should belong to category 1');
    Products[I].Free;
  end;
end;

procedure TTestProductService.TestGetLowStockProducts;
var
  Products: TArray<TProduct>;
  I: Integer;
begin
  Products := FProductService.GetLowStockProducts;

  // Verify all returned products are low stock
  for I := Low(Products) to High(Products) do
  begin
    Assert.IsTrue(Products[I].Quantity <= Products[I].MinStockLevel,
                  'Product should be at or below minimum stock level');
    Products[I].Free;
  end;
end;

procedure TTestProductService.TestSearchProducts;
var
  Products: TArray<TProduct>;
  I: Integer;
begin
  Products := FProductService.SearchProducts('Laptop');

  // At least one product should contain 'Laptop' in the name
  if Length(Products) > 0 then
    Assert.IsTrue(Pos('Laptop', Products[0].ProductName) > 0,
                  'Search result should contain search term');

  // Clean up
  for I := Low(Products) to High(Products) do
    Products[I].Free;
end;

procedure TTestProductService.TestUpdateProduct;
var
  Product: TProduct;
  UpdateResult: Boolean;
begin
  // Create test product first
  TestCreateProduct;

  // Get the created product
  Product := FProductService.GetProductByID(FTestProductID);
  try
    if Assigned(Product) then
    begin
      Product.ProductName := 'Updated Test Product';
      Product.UnitPrice := 149.99;
      Product.Quantity := 150;

      UpdateResult := FProductService.UpdateProduct(Product);
      Assert.IsTrue(UpdateResult, 'Product update should succeed');

      // Verify update
      Product.Free;
      Product := FProductService.GetProductByID(FTestProductID);
      Assert.AreEqual('Updated Test Product', Product.ProductName, 'Product name should be updated');
      Assert.AreEqual(149.99, Product.UnitPrice, 0.01, 'Price should be updated');
    end;
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestUpdateStock;
var
  Product: TProduct;
  UpdateResult: Boolean;
  OriginalQuantity: Integer;
begin
  // Get existing product
  Product := FProductService.GetProductByID(1);
  try
    OriginalQuantity := Product.Quantity;

    // Update stock (add 10)
    UpdateResult := FProductService.UpdateStock(1, OriginalQuantity + 10);
    Assert.IsTrue(UpdateResult, 'Stock update should succeed');

    // Verify stock updated
    Product.Free;
    Product := FProductService.GetProductByID(1);
    Assert.AreEqual(OriginalQuantity + 10, Product.Quantity, 'Quantity should be updated');

    // Restore original quantity
    FProductService.UpdateStock(1, OriginalQuantity);
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestCheckStock;
var
  Product: TProduct;
  HasStock: Boolean;
begin
  Product := FProductService.GetProductByID(1);
  try
    // Check if stock is available (request less than available)
    HasStock := FProductService.CheckStock(1, 1);
    Assert.IsTrue(HasStock, 'Should have stock available');

    // Check if insufficient stock (request more than available)
    HasStock := FProductService.CheckStock(1, Product.Quantity + 100);
    Assert.IsFalse(HasStock, 'Should not have sufficient stock');
  finally
    Product.Free;
  end;
end;

procedure TTestProductService.TestDeleteProduct;
var
  Product: TProduct;
  DeleteResult: Boolean;
  ProductID: Integer;
begin
  // Create a product to delete
  Product := TProduct.Create;
  try
    Product.ProductCode := 'DEL' + FormatDateTime('yyyymmddhhnnss', Now);
    Product.ProductName := 'Product to Delete';
    Product.CategoryID := 1;
    Product.UnitPrice := 50.00;
    Product.CostPrice := 25.00;
    Product.Quantity := 50;
    Product.BranchID := 1;

    if FProductService.CreateProduct(Product) then
    begin
      ProductID := Product.ProductID;

      // Delete the product
      DeleteResult := FProductService.DeleteProduct(ProductID);
      Assert.IsTrue(DeleteResult, 'Product deletion should succeed');

      // Verify product is soft-deleted (IsActive = False)
      Product.Free;
      Product := FProductService.GetProductByID(ProductID);
      // Product should not be found in active products
      Assert.IsNull(Product, 'Deleted product should not be found');
    end;
  finally
    if Assigned(Product) then
      Product.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProductService);

end.
