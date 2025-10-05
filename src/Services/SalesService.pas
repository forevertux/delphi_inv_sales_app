unit SalesService;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Comp.Client, Data.DB,
  SaleEntity, System.Generics.Collections;

type
  TSalesService = class
  private
    function GetSaleFromQuery(Query: TFDQuery): TSale;
    function GetSaleItemFromQuery(Query: TFDQuery): TSaleItem;
    function GetNextSequenceNumber(const DatePart: string): Integer;
    function UpdateProductStock(ProductID, Quantity: Integer; IsReverse: Boolean): Boolean;
  public
    constructor Create;
    destructor Destroy; override;

    function CreateSale(Sale: TSale): Boolean;
    function GetSaleByID(SaleID: Integer): TSale;
    function GetSaleByNumber(SaleNumber: string): TSale;
    function GetSalesByDateRange(StartDate, EndDate: TDateTime): TArray<TSale>;
    function GetSalesByBranch(BranchID: Integer): TArray<TSale>;
    function GetSalesByEmployee(EmployeeID: Integer): TArray<TSale>;
    function GetTodaysSales: TArray<TSale>;
    function GenerateSaleNumber: string;
    function CancelSale(SaleID: Integer): Boolean;
    function GetSaleItems(SaleID: Integer): TArray<TSaleItem>;
    function ValidateSaleItems(Items: TSaleItemList): Boolean;
  end;

var
  GSalesService: TSalesService;

implementation

uses
  DatabaseModule, ValidationUtils, Constants, AuthService, FMX.Dialogs,
  ProductService;

{ TSalesService }

constructor TSalesService.Create;
begin
  inherited Create;
end;

destructor TSalesService.Destroy;
begin
  inherited Destroy;
end;

function TSalesService.GetSaleFromQuery(Query: TFDQuery): TSale;
begin
  Result := TSale.Create;
  Result.SaleID := Query.FieldByName('SaleID').AsInteger;
  Result.SaleNumber := Query.FieldByName('SaleNumber').AsString;
  Result.SaleDate := Query.FieldByName('SaleDate').AsDateTime;

  if not Query.FieldByName('BranchID').IsNull then
    Result.BranchID := Query.FieldByName('BranchID').AsInteger;

  // Branch name from JOIN if available
  if Query.FindField('BranchName') <> nil then
    if not Query.FieldByName('BranchName').IsNull then
      Result.BranchName := Query.FieldByName('BranchName').AsString;

  if not Query.FieldByName('EmployeeID').IsNull then
    Result.EmployeeID := Query.FieldByName('EmployeeID').AsInteger;

  // Employee name from JOIN if available
  if Query.FindField('EmployeeName') <> nil then
    if not Query.FieldByName('EmployeeName').IsNull then
      Result.EmployeeName := Query.FieldByName('EmployeeName').AsString;

  if not Query.FieldByName('CustomerName').IsNull then
    Result.CustomerName := Query.FieldByName('CustomerName').AsString;

  if not Query.FieldByName('CustomerPhone').IsNull then
    Result.CustomerPhone := Query.FieldByName('CustomerPhone').AsString;

  Result.SubTotal := Query.FieldByName('SubTotal').AsFloat;
  Result.TaxAmount := Query.FieldByName('TaxAmount').AsFloat;
  Result.DiscountAmount := Query.FieldByName('DiscountAmount').AsFloat;
  Result.TotalAmount := Query.FieldByName('TotalAmount').AsFloat;

  if not Query.FieldByName('PaymentMethod').IsNull then
    Result.PaymentMethod := Query.FieldByName('PaymentMethod').AsString;

  if not Query.FieldByName('PaymentStatus').IsNull then
    Result.PaymentStatus := Query.FieldByName('PaymentStatus').AsString;

  if not Query.FieldByName('Notes').IsNull then
    Result.Notes := Query.FieldByName('Notes').AsString;

  if not Query.FieldByName('IsSynced').IsNull then
    Result.IsSynced := Query.FieldByName('IsSynced').AsBoolean;

  if not Query.FieldByName('CreatedAt').IsNull then
    Result.CreatedAt := Query.FieldByName('CreatedAt').AsDateTime;

  if not Query.FieldByName('UpdatedAt').IsNull then
    Result.UpdatedAt := Query.FieldByName('UpdatedAt').AsDateTime;
end;

function TSalesService.GetSaleItemFromQuery(Query: TFDQuery): TSaleItem;
begin
  Result := TSaleItem.Create;
  Result.SaleItemID := Query.FieldByName('SaleItemID').AsInteger;
  Result.SaleID := Query.FieldByName('SaleID').AsInteger;
  Result.ProductID := Query.FieldByName('ProductID').AsInteger;

  // Product name from JOIN if available
  if Query.FindField('ProductName') <> nil then
    if not Query.FieldByName('ProductName').IsNull then
      Result.ProductName := Query.FieldByName('ProductName').AsString;

  Result.Quantity := Query.FieldByName('Quantity').AsInteger;
  Result.UnitPrice := Query.FieldByName('UnitPrice').AsFloat;

  if not Query.FieldByName('DiscountPercent').IsNull then
    Result.DiscountPercent := Query.FieldByName('DiscountPercent').AsFloat;

  if not Query.FieldByName('TaxPercent').IsNull then
    Result.TaxPercent := Query.FieldByName('TaxPercent').AsFloat;

  Result.LineTotal := Query.FieldByName('LineTotal').AsFloat;

  if not Query.FieldByName('CreatedAt').IsNull then
    Result.CreatedAt := Query.FieldByName('CreatedAt').AsDateTime;
end;

function TSalesService.GetNextSequenceNumber(const DatePart: string): Integer;
var
  Query: TFDQuery;
  SQL: string;
  MaxNumber: string;
  SeqNum: Integer;
begin
  Result := 1;

  try
    Query := DMDatabase.qryGeneral;
    SQL := 'SELECT MAX(SaleNumber) AS MaxNumber FROM Sales ' +
           'WHERE SaleNumber LIKE :Pattern';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Pattern').AsString := 'SALE' + DatePart + '%';
    Query.Open;

    if not Query.IsEmpty and not Query.FieldByName('MaxNumber').IsNull then
    begin
      MaxNumber := Query.FieldByName('MaxNumber').AsString;
      // Extract sequence number from SALE + YYYYMMDD + sequence
      if Length(MaxNumber) > 12 then
      begin
        SeqNum := StrToIntDef(Copy(MaxNumber, 13, Length(MaxNumber) - 12), 0);
        Result := SeqNum + 1;
      end;
    end;

    Query.Close;
  except
    on E: Exception do
    begin
      Result := 1;
    end;
  end;
end;

function TSalesService.GenerateSaleNumber: string;
var
  DatePart: string;
  SeqNum: Integer;
begin
  // Format: SALE + YYYYMMDD + sequence (4 digits)
  DatePart := FormatDateTime('YYYYMMDD', Now);
  SeqNum := GetNextSequenceNumber(DatePart);
  Result := Format('SALE%s%0.4d', [DatePart, SeqNum]);
end;

function TSalesService.UpdateProductStock(ProductID, Quantity: Integer; IsReverse: Boolean): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  AdjustmentQty: Integer;
begin
  Result := False;

  try
    // If reversing, add back to stock; otherwise subtract
    if IsReverse then
      AdjustmentQty := Quantity
    else
      AdjustmentQty := -Quantity;

    Query := DMDatabase.qryGeneral;
    SQL := 'UPDATE Products SET Quantity = Quantity + :Quantity, ' +
           'UpdatedAt = CURRENT_TIMESTAMP WHERE ProductID = :ProductID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Quantity').AsInteger := AdjustmentQty;
    Query.ParamByName('ProductID').AsInteger := ProductID;
    Query.ExecSQL;

    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
    begin
      Result := False;
    end;
  end;
end;

function TSalesService.ValidateSaleItems(Items: TSaleItemList): Boolean;
var
  Item: TSaleItem;
  ErrorMsg: string;
begin
  Result := False;

  if Items.Count = 0 then
  begin
    ShowMessage('Sale must have at least one item');
    Exit;
  end;

  for Item in Items do
  begin
    // Validate quantity
    if not IsValidQuantity(Item.Quantity) or (Item.Quantity <= 0) then
    begin
      ShowMessage('Invalid quantity for product: ' + Item.ProductName);
      Exit;
    end;

    // Validate unit price
    if not IsValidPrice(Item.UnitPrice) or (Item.UnitPrice <= 0) then
    begin
      ShowMessage('Invalid unit price for product: ' + Item.ProductName);
      Exit;
    end;

    // Check stock availability
    if not GProductService.CheckStock(Item.ProductID, Item.Quantity) then
    begin
      ShowMessage(Format('Insufficient stock for product: %s', [Item.ProductName]));
      Exit;
    end;
  end;

  Result := True;
end;

function TSalesService.CreateSale(Sale: TSale): Boolean;
var
  QuerySale: TFDQuery;
  QueryItem: TFDQuery;
  SQL: string;
  SaleID: Int64;
  Item: TSaleItem;
  ErrorMsg: string;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanProcessSale then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Validate sale data
    if IsEmptyOrWhiteSpace(Sale.SaleNumber) then
    begin
      ShowMessage('Sale number is required');
      Exit;
    end;

    if Sale.EmployeeID <= 0 then
    begin
      ShowMessage('Employee is required');
      Exit;
    end;

    if not IsValidPrice(Sale.TotalAmount) or (Sale.TotalAmount <= 0) then
    begin
      ShowMessage('Invalid total amount');
      Exit;
    end;

    // Validate sale items
    if not ValidateSaleItems(Sale.Items) then
      Exit;

    // Begin transaction
    DMDatabase.BeginTrans;
    try
      QuerySale := DMDatabase.qrySales;

      // Insert sale header
      SQL := 'INSERT INTO Sales (SaleNumber, SaleDate, BranchID, EmployeeID, ' +
             'CustomerName, CustomerPhone, SubTotal, TaxAmount, DiscountAmount, ' +
             'TotalAmount, PaymentMethod, PaymentStatus, Notes, IsSynced) ' +
             'VALUES (:SaleNumber, :SaleDate, :BranchID, :EmployeeID, ' +
             ':CustomerName, :CustomerPhone, :SubTotal, :TaxAmount, :DiscountAmount, ' +
             ':TotalAmount, :PaymentMethod, :PaymentStatus, :Notes, :IsSynced)';

      QuerySale.Close;
      QuerySale.SQL.Text := SQL;
      QuerySale.ParamByName('SaleNumber').AsString := Sale.SaleNumber;
      QuerySale.ParamByName('SaleDate').AsDateTime := Sale.SaleDate;

      if Sale.BranchID > 0 then
        QuerySale.ParamByName('BranchID').AsInteger := Sale.BranchID
      else
        QuerySale.ParamByName('BranchID').Clear;

      QuerySale.ParamByName('EmployeeID').AsInteger := Sale.EmployeeID;
      QuerySale.ParamByName('CustomerName').AsString := Sale.CustomerName;
      QuerySale.ParamByName('CustomerPhone').AsString := Sale.CustomerPhone;
      QuerySale.ParamByName('SubTotal').AsFloat := Sale.SubTotal;
      QuerySale.ParamByName('TaxAmount').AsFloat := Sale.TaxAmount;
      QuerySale.ParamByName('DiscountAmount').AsFloat := Sale.DiscountAmount;
      QuerySale.ParamByName('TotalAmount').AsFloat := Sale.TotalAmount;
      QuerySale.ParamByName('PaymentMethod').AsString := Sale.PaymentMethod;
      QuerySale.ParamByName('PaymentStatus').AsString := Sale.PaymentStatus;
      QuerySale.ParamByName('Notes').AsString := Sale.Notes;
      QuerySale.ParamByName('IsSynced').AsBoolean := Sale.IsSynced;
      QuerySale.ExecSQL;

      // Get the last inserted SaleID
      SaleID := DMDatabase.GetLastInsertID;

      if SaleID <= 0 then
      begin
        DMDatabase.RollbackTrans;
        ShowMessage('Failed to create sale record');
        Exit;
      end;

      // Insert sale items and update inventory
      QueryItem := DMDatabase.qryGeneral;

      for Item in Sale.Items do
      begin
        // Calculate line total
        Item.CalculateLineTotal;

        // Insert sale item
        SQL := 'INSERT INTO SaleItems (SaleID, ProductID, Quantity, UnitPrice, ' +
               'DiscountPercent, TaxPercent, LineTotal) ' +
               'VALUES (:SaleID, :ProductID, :Quantity, :UnitPrice, ' +
               ':DiscountPercent, :TaxPercent, :LineTotal)';

        QueryItem.Close;
        QueryItem.SQL.Text := SQL;
        QueryItem.ParamByName('SaleID').AsInteger := SaleID;
        QueryItem.ParamByName('ProductID').AsInteger := Item.ProductID;
        QueryItem.ParamByName('Quantity').AsInteger := Item.Quantity;
        QueryItem.ParamByName('UnitPrice').AsFloat := Item.UnitPrice;
        QueryItem.ParamByName('DiscountPercent').AsFloat := Item.DiscountPercent;
        QueryItem.ParamByName('TaxPercent').AsFloat := Item.TaxPercent;
        QueryItem.ParamByName('LineTotal').AsFloat := Item.LineTotal;
        QueryItem.ExecSQL;

        // Update product stock
        if not UpdateProductStock(Item.ProductID, Item.Quantity, False) then
        begin
          DMDatabase.RollbackTrans;
          ShowMessage('Failed to update product stock for: ' + Item.ProductName);
          Exit;
        end;
      end;

      // Commit transaction
      DMDatabase.CommitTrans;
      Result := True;
      ShowMessage(MSG_SAVE_SUCCESS);

    except
      on E: Exception do
      begin
        DMDatabase.RollbackTrans;
        ShowMessage('Error creating sale: ' + E.Message);
        Result := False;
      end;
    end;

  except
    on E: Exception do
      ShowMessage('Error creating sale: ' + E.Message);
  end;
end;

function TSalesService.GetSaleByID(SaleID: Integer): TSale;
var
  Query: TFDQuery;
  SQL: string;
  Items: TArray<TSaleItem>;
  Item: TSaleItem;
begin
  Result := nil;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE s.SaleID = :SaleID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SaleID').AsInteger := SaleID;
    Query.Open;

    if not Query.IsEmpty then
    begin
      Result := GetSaleFromQuery(Query);

      // Load sale items
      Items := GetSaleItems(SaleID);
      for Item in Items do
        Result.Items.Add(Item);
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sale: ' + E.Message);
  end;
end;

function TSalesService.GetSaleByNumber(SaleNumber: string): TSale;
var
  Query: TFDQuery;
  SQL: string;
  Items: TArray<TSaleItem>;
  Item: TSaleItem;
begin
  Result := nil;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE s.SaleNumber = :SaleNumber';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SaleNumber').AsString := SaleNumber;
    Query.Open;

    if not Query.IsEmpty then
    begin
      Result := GetSaleFromQuery(Query);

      // Load sale items
      Items := GetSaleItems(Result.SaleID);
      for Item in Items do
        Result.Items.Add(Item);
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sale by number: ' + E.Message);
  end;
end;

function TSalesService.GetSalesByDateRange(StartDate, EndDate: TDateTime): TArray<TSale>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE DATE(s.SaleDate) BETWEEN :StartDate AND :EndDate ' +
           'ORDER BY s.SaleDate DESC, s.SaleID DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetSaleFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sales by date range: ' + E.Message);
  end;
end;

function TSalesService.GetSalesByBranch(BranchID: Integer): TArray<TSale>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE s.BranchID = :BranchID ' +
           'ORDER BY s.SaleDate DESC, s.SaleID DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('BranchID').AsInteger := BranchID;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetSaleFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sales by branch: ' + E.Message);
  end;
end;

function TSalesService.GetSalesByEmployee(EmployeeID: Integer): TArray<TSale>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE s.EmployeeID = :EmployeeID ' +
           'ORDER BY s.SaleDate DESC, s.SaleID DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('EmployeeID').AsInteger := EmployeeID;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetSaleFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sales by employee: ' + E.Message);
  end;
end;

function TSalesService.GetTodaysSales: TArray<TSale>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qrySales;
    SQL := 'SELECT s.*, b.BranchName, u.FullName AS EmployeeName ' +
           'FROM Sales s ' +
           'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
           'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
           'WHERE DATE(s.SaleDate) = DATE(CURRENT_TIMESTAMP) ' +
           'ORDER BY s.SaleDate DESC, s.SaleID DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetSaleFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

    Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting today''s sales: ' + E.Message);
  end;
end;

function TSalesService.GetSaleItems(SaleID: Integer): TArray<TSaleItem>;
var
  Query: TFDQuery;
  SQL: string;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  try
    Query := DMDatabase.qryGeneral;
    SQL := 'SELECT si.*, p.ProductName ' +
           'FROM SaleItems si ' +
           'LEFT JOIN Products p ON si.ProductID = p.ProductID ' +
           'WHERE si.SaleID = :SaleID ' +
           'ORDER BY si.SaleItemID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SaleID').AsInteger := SaleID;
    Query.Open;

    Query.First;
    while not Query.Eof do
    begin
      SetLength(Result, Count + 1);
      Result[Count] := GetSaleItemFromQuery(Query);
      Inc(Count);
      Query.Next;
    end;

        Query.Close;
  except
    on E: Exception do
      ShowMessage('Error getting sale items: ' + E.Message);
  end;
end;

function TSalesService.CancelSale(SaleID: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  Items: TArray<TSaleItem>;
  Item: TSaleItem;
begin
  Result := False;

  // Check permissions
  if not GAuthService.CurrentUser.CanProcessSale then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  try
    // Begin transaction
    DMDatabase.BeginTrans;
    try
      // Get sale items first to reverse inventory
      Items := GetSaleItems(SaleID);

      if Length(Items) = 0 then
      begin
        DMDatabase.RollbackTrans;
        ShowMessage('Sale not found or already cancelled');
        Exit;
      end;

      // Reverse inventory for each item
      for Item in Items do
      begin
        if not UpdateProductStock(Item.ProductID, Item.Quantity, True) then
        begin
          DMDatabase.RollbackTrans;
          ShowMessage('Failed to reverse stock for product: ' + Item.ProductName);
          Exit;
        end;
      end;

      // Delete sale items
      Query := DMDatabase.qryGeneral;
      SQL := 'DELETE FROM SaleItems WHERE SaleID = :SaleID';

      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('SaleID').AsInteger := SaleID;
      Query.ExecSQL;

      // Delete sale header
      SQL := 'DELETE FROM Sales WHERE SaleID = :SaleID';

      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('SaleID').AsInteger := SaleID;
      Query.ExecSQL;

      // Commit transaction
      DMDatabase.CommitTrans;
      Result := True;
      ShowMessage('Sale cancelled successfully');

    except
      on E: Exception do
      begin
        DMDatabase.RollbackTrans;
        ShowMessage('Error cancelling sale: ' + E.Message);
        Result := False;
      end;
    end;

  except
    on E: Exception do
      ShowMessage('Error cancelling sale: ' + E.Message);
  end;
end;

initialization
  GSalesService := TSalesService.Create;

finalization
  GSalesService.Free;

end.
