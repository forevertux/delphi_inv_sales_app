unit ProductService;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Comp.Client, Data.DB,
  ProductEntity;

type
  TProductService = class
  private
    function GetProductFromQuery(Query: TFDQuery): TProduct;
  public
    constructor Create;
    destructor Destroy; override;

    function GetProductByID(ProductID: Integer): TProduct;
    function GetProductByCode(ProductCode: string): TProduct;
    function GetProductByBarcode(Barcode: string): TProduct;
    function GetAllProducts: TArray<TProduct>;
    function GetProductsByCategory(CategoryID: Integer): TArray<TProduct>;
    function GetProductsByBranch(BranchID: Integer): TArray<TProduct>;
    function GetLowStockProducts: TArray<TProduct>;
    function SearchProducts(SearchText: string): TArray<TProduct>;
    function CreateProduct(Product: TProduct): Boolean;
    function UpdateProduct(Product: TProduct): Boolean;
    function DeleteProduct(ProductID: Integer): Boolean;
    function UpdateStock(ProductID, Quantity: Integer): Boolean;
    function CheckStock(ProductID, RequestedQty: Integer): Boolean;
  end;

var
  GProductService: TProductService;

implementation

uses
  DatabaseModule, ValidationUtils, Constants, AuthService, FMX.Dialogs;

{ TProductService }

constructor TProductService.Create;
begin
  inherited Create;
end;

destructor TProductService.Destroy;
begin
  inherited Destroy;
end;

function TProductService.GetProductFromQuery(Query: TFDQuery): TProduct;
begin
  Result := TProduct.Create;
  Result.ProductID := Query.FieldByName('ProductID').AsInteger;
  Result.ProductCode := Query.FieldByName('ProductCode').AsString;
  Result.ProductName := Query.FieldByName('ProductName').AsString;

  if not Query.FieldByName('Description').IsNull then
    Result.Description := Query.FieldByName('Description').AsString;

  Result.CategoryID := Query.FieldByName('CategoryID').AsInteger;

  // Category name from JOIN if available
  if Query.FindField('CategoryName') <> nil then
    if not Query.FieldByName('CategoryName').IsNull then
      Result.CategoryName := Query.FieldByName('CategoryName').AsString;

  Result.UnitPrice := Query.FieldByName('UnitPrice').AsFloat;

  if not Query.FieldByName('CostPrice').IsNull then
    Result.CostPrice := Query.FieldByName('CostPrice').AsFloat;

  Result.Quantity := Query.FieldByName('Quantity').AsInteger;

  if not Query.FieldByName('MinStockLevel').IsNull then
    Result.MinStockLevel := Query.FieldByName('MinStockLevel').AsInteger;

  if not Query.FieldByName('MaxStockLevel').IsNull then
    Result.MaxStockLevel := Query.FieldByName('MaxStockLevel').AsInteger;

  if not Query.FieldByName('BranchID').IsNull then
    Result.BranchID := Query.FieldByName('BranchID').AsInteger;

  // Branch name from JOIN if available
  if Query.FindField('BranchName') <> nil then
    if not Query.FieldByName('BranchName').IsNull then
      Result.BranchName := Query.FieldByName('BranchName').AsString;

  if not Query.FieldByName('Barcode').IsNull then
    Result.Barcode := Query.FieldByName('Barcode').AsString;

  if not Query.FieldByName('SKU').IsNull then
    Result.SKU := Query.FieldByName('SKU').AsString;

  Result.IsActive := Query.FieldByName('IsActive').AsBoolean;

  if not Query.FieldByName('CreatedBy').IsNull then
    Result.CreatedBy := Query.FieldByName('CreatedBy').AsInteger;

  if not Query.FieldByName('CreatedAt').IsNull then
    Result.CreatedAt := Query.FieldByName('CreatedAt').AsDateTime;

  if not Query.FieldByName('UpdatedAt').IsNull then
    Result.UpdatedAt := Query.FieldByName('UpdatedAt').AsDateTime;
end;

function TProductService.GetProductByID(ProductID: Integer): TProduct;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.ProductID = :ProductID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductID').AsInteger := ProductID;
    Query.Open;

    if not Query.IsEmpty then
      Result := GetProductFromQuery(Query);

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting product: ' + E.Message);
  end;
end;

function TProductService.GetProductByCode(ProductCode: string): TProduct;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.ProductCode = :ProductCode';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductCode').AsString := ProductCode;
    Query.Open;

    if not Query.IsEmpty then
      Result := GetProductFromQuery(Query);

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting product by code: ' + E.Message);
  end;
end;

function TProductService.GetProductByBarcode(Barcode: string): TProduct;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.Barcode = :Barcode';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Barcode').AsString := Barcode;
    Query.Open;

    if not Query.IsEmpty then
      Result := GetProductFromQuery(Query);

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting product by barcode: ' + E.Message);
  end;
end;

function TProductService.GetAllProducts: TArray<TProduct>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'ORDER BY p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetProductFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting products: ' + E.Message);
  end;
end;

function TProductService.GetProductsByCategory(CategoryID: Integer): TArray<TProduct>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.CategoryID = :CategoryID AND p.IsActive = 1 ' +
           'ORDER BY p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('CategoryID').AsInteger := CategoryID;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetProductFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting products by category: ' + E.Message);
  end;
end;

function TProductService.GetProductsByBranch(BranchID: Integer): TArray<TProduct>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.BranchID = :BranchID AND p.IsActive = 1 ' +
           'ORDER BY p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('BranchID').AsInteger := BranchID;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetProductFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting products by branch: ' + E.Message);
  end;
end;

function TProductService.GetLowStockProducts: TArray<TProduct>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE p.Quantity > 0 AND p.Quantity <= p.MinStockLevel AND p.IsActive = 1 ' +
           'ORDER BY p.Quantity ASC, p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetProductFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;
    Query.Close;
  except

    on E: Exception do
      ShowMessage('Error getting low stock products: ' + E.Message);
  end;
end;

function TProductService.SearchProducts(SearchText: string): TArray<TProduct>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
  SearchPattern: string;
begin
  SetLength(Result, 0);
  Count := 0;

  if IsEmptyOrWhiteSpace(SearchText) then
  begin
    Result := GetAllProducts;
    Exit;
  end;

  try
    Query := DMDatabase.qryProducts;
    SearchPattern := '%' + SearchText + '%';

    SQL := 'SELECT p.*, c.CategoryName, b.BranchName ' +
           'FROM Products p ' +
           'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
           'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
           'WHERE (p.ProductCode LIKE :SearchText ' +
           'OR p.ProductName LIKE :SearchText ' +
           'OR p.Barcode LIKE :SearchText ' +
           'OR p.SKU LIKE :SearchText ' +
           'OR p.Description LIKE :SearchText) ' +
           'AND p.IsActive = 1 ' +
           'ORDER BY p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SearchText').AsString := SearchPattern;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetProductFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error searching products: ' + E.Message);
  end;
end;

function TProductService.CreateProduct(Product: TProduct): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  ErrorMsg: string;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanEditProduct then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Validate input
    if not ValidateRequired(Product.ProductCode, 'Product Code', ErrorMsg) then
    begin
      ShowMessage(ErrorMsg);
      Exit;
    end;

    if not ValidateRequired(Product.ProductName, 'Product Name', ErrorMsg) then
    begin
      ShowMessage(ErrorMsg);
      Exit;
    end;

    if not IsValidPrice(Product.UnitPrice) then
    begin
      ShowMessage('Unit price must be a positive number');
      Exit;
    end;

    if not IsValidPrice(Product.CostPrice) then
    begin
      ShowMessage('Cost price must be a positive number');
      Exit;
    end;

    if not IsValidQuantity(Product.Quantity) then
    begin
      ShowMessage('Quantity must be a positive number');
      Exit;
    end;

    if Product.CategoryID <= 0 then
    begin
      ShowMessage('Please select a category');
      Exit;
    end;

    // Check for duplicate product code
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT COUNT(*) AS cnt FROM Products WHERE ProductCode = :ProductCode';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductCode').AsString := Product.ProductCode;
    Query.Open;

    if Query.FieldByName('cnt').AsInteger > 0 then
    begin
      ShowMessage('Product code already exists');
      Query.Close;
      Exit;
    end;
    Query.Close;

    // Check for duplicate barcode if provided
    if not IsEmptyOrWhiteSpace(Product.Barcode) then
    begin
      SQL := 'SELECT COUNT(*) AS cnt FROM Products WHERE Barcode = :Barcode';
      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('Barcode').AsString := Product.Barcode;
      Query.Open;

      if Query.FieldByName('cnt').AsInteger > 0 then
      begin
        ShowMessage('Barcode already exists');
        Query.Close;
        Exit;
      end;
      Query.Close;
    end;

    // Insert product
    SQL := 'INSERT INTO Products (ProductCode, ProductName, Description, CategoryID, ' +
           'UnitPrice, CostPrice, Quantity, MinStockLevel, MaxStockLevel, BranchID, ' +
           'Barcode, SKU, IsActive, CreatedBy) ' +
           'VALUES (:ProductCode, :ProductName, :Description, :CategoryID, ' +
           ':UnitPrice, :CostPrice, :Quantity, :MinStockLevel, :MaxStockLevel, :BranchID, ' +
           ':Barcode, :SKU, :IsActive, :CreatedBy)';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductCode').AsString := Product.ProductCode;
    Query.ParamByName('ProductName').AsString := Product.ProductName;
    Query.ParamByName('Description').AsString := Product.Description;
    Query.ParamByName('CategoryID').AsInteger := Product.CategoryID;
    Query.ParamByName('UnitPrice').AsFloat := Product.UnitPrice;
    Query.ParamByName('CostPrice').AsFloat := Product.CostPrice;
    Query.ParamByName('Quantity').AsInteger := Product.Quantity;
    Query.ParamByName('MinStockLevel').AsInteger := Product.MinStockLevel;
    Query.ParamByName('MaxStockLevel').AsInteger := Product.MaxStockLevel;

    if Product.BranchID > 0 then
      Query.ParamByName('BranchID').AsInteger := Product.BranchID
    else
      Query.ParamByName('BranchID').Clear;

    Query.ParamByName('Barcode').AsString := Product.Barcode;
    Query.ParamByName('SKU').AsString := Product.SKU;
    Query.ParamByName('IsActive').AsBoolean := Product.IsActive;
    Query.ParamByName('CreatedBy').AsInteger := GAuthService.CurrentUser.UserID;
    Query.ExecSQL;

    Result := True;
    ShowMessage(MSG_SAVE_SUCCESS);
  except
    on E: Exception do
      ShowMessage('Error creating product: ' + E.Message);
  end;
end;

function TProductService.UpdateProduct(Product: TProduct): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  ErrorMsg: string;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanEditProduct then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Validate input
    if not ValidateRequired(Product.ProductName, 'Product Name', ErrorMsg) then
    begin
      ShowMessage(ErrorMsg);
      Exit;
    end;

    if not IsValidPrice(Product.UnitPrice) then
    begin
      ShowMessage('Unit price must be a positive number');
      Exit;
    end;

    if not IsValidPrice(Product.CostPrice) then
    begin
      ShowMessage('Cost price must be a positive number');
      Exit;
    end;

    if not IsValidQuantity(Product.Quantity) then
    begin
      ShowMessage('Quantity must be a positive number');
      Exit;
    end;

    if Product.CategoryID <= 0 then
    begin
      ShowMessage('Please select a category');
      Exit;
    end;

    // Check for duplicate barcode if provided
    if not IsEmptyOrWhiteSpace(Product.Barcode) then
    begin
      Query := DMDatabase.qryProducts;
      SQL := 'SELECT COUNT(*) AS cnt FROM Products WHERE Barcode = :Barcode AND ProductID <> :ProductID';
      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('Barcode').AsString := Product.Barcode;
      Query.ParamByName('ProductID').AsInteger := Product.ProductID;
      Query.Open;

      if Query.FieldByName('cnt').AsInteger > 0 then
      begin
        ShowMessage('Barcode already exists');
        Query.Close;
        Exit;
      end;
      Query.Close;
    end;

    // Update product
    Query := DMDatabase.qryProducts;
    SQL := 'UPDATE Products SET ProductName = :ProductName, Description = :Description, ' +
           'CategoryID = :CategoryID, UnitPrice = :UnitPrice, CostPrice = :CostPrice, ' +
           'Quantity = :Quantity, MinStockLevel = :MinStockLevel, MaxStockLevel = :MaxStockLevel, ' +
           'BranchID = :BranchID, Barcode = :Barcode, SKU = :SKU, IsActive = :IsActive, ' +
           'UpdatedAt = CURRENT_TIMESTAMP ' +
           'WHERE ProductID = :ProductID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductName').AsString := Product.ProductName;
    Query.ParamByName('Description').AsString := Product.Description;
    Query.ParamByName('CategoryID').AsInteger := Product.CategoryID;
    Query.ParamByName('UnitPrice').AsFloat := Product.UnitPrice;
    Query.ParamByName('CostPrice').AsFloat := Product.CostPrice;
    Query.ParamByName('Quantity').AsInteger := Product.Quantity;
    Query.ParamByName('MinStockLevel').AsInteger := Product.MinStockLevel;
    Query.ParamByName('MaxStockLevel').AsInteger := Product.MaxStockLevel;

    if Product.BranchID > 0 then
      Query.ParamByName('BranchID').AsInteger := Product.BranchID
    else
      Query.ParamByName('BranchID').Clear;

    Query.ParamByName('Barcode').AsString := Product.Barcode;
    Query.ParamByName('SKU').AsString := Product.SKU;
    Query.ParamByName('IsActive').AsBoolean := Product.IsActive;
    Query.ParamByName('ProductID').AsInteger := Product.ProductID;
    Query.ExecSQL;

    Result := Query.RowsAffected > 0;

    if Result then
      ShowMessage(MSG_UPDATE_SUCCESS);
  except
    on E: Exception do
      ShowMessage('Error updating product: ' + E.Message);
  end;
end;

function TProductService.DeleteProduct(ProductID: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanDeleteProduct then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Soft delete (set IsActive = False)
    Query := DMDatabase.qryProducts;
    SQL := 'UPDATE Products SET IsActive = 0, UpdatedAt = CURRENT_TIMESTAMP WHERE ProductID = :ProductID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductID').AsInteger := ProductID;
    Query.ExecSQL;

    Result := Query.RowsAffected > 0;

    if Result then
      ShowMessage(MSG_DELETE_SUCCESS);
  except
    on E: Exception do
      ShowMessage('Error deleting product: ' + E.Message);
  end;
end;

function TProductService.UpdateStock(ProductID, Quantity: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanEditProduct then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Update stock quantity
    Query := DMDatabase.qryProducts;
    SQL := 'UPDATE Products SET Quantity = Quantity + :Quantity, UpdatedAt = CURRENT_TIMESTAMP ' +
           'WHERE ProductID = :ProductID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Quantity').AsInteger := Quantity;
    Query.ParamByName('ProductID').AsInteger := ProductID;
    Query.ExecSQL;

    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
      ShowMessage('Error updating stock: ' + E.Message);
  end;
end;

function TProductService.CheckStock(ProductID, RequestedQty: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  AvailableQty: Integer;
begin
  Result := False;

  try
    Query := DMDatabase.qryProducts;
    SQL := 'SELECT Quantity FROM Products WHERE ProductID = :ProductID AND IsActive = 1';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('ProductID').AsInteger := ProductID;
    Query.Open;

    if not Query.IsEmpty then
    begin
      AvailableQty := Query.FieldByName('Quantity').AsInteger;
      Result := AvailableQty >= RequestedQty;
    end;

    Query.Close;
  except
    on E: Exception do
    begin
      ShowMessage('Error checking stock: ' + E.Message);
      Result := False;
    end;
  end;
end;

initialization
  GProductService := TProductService.Create;

finalization
  GProductService.Free;

end.
