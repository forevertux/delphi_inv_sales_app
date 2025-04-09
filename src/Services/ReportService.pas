unit ReportService;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Comp.Client, Data.DB,
  System.Generics.Collections;

type
  TReportService = class
  private
    function GetQuery: TFDQuery;
    function CheckPermissions: Boolean;
    function FormatDateForSQL(ADate: TDateTime): string;
  public
    // Sales Reports
    function GetSalesReport(StartDate, EndDate: TDateTime; BranchID: Integer): TDataSet;
    function GetTopSellingProducts(StartDate, EndDate: TDateTime; TopN: Integer): TDataSet;
    function GetSalesByCategory(StartDate, EndDate: TDateTime): TDataSet;
    function GetSalesByEmployee(StartDate, EndDate: TDateTime): TDataSet;
    function GetProfitAnalysis(StartDate, EndDate: TDateTime): TDataSet;

    // Inventory Reports
    function GetInventoryReport(BranchID: Integer): TDataSet;
    function GetLowStockReport: TDataSet;
    function GetOutOfStockReport: TDataSet;

    // Chart Data Reports
    function GetDailySalesChart(StartDate, EndDate: TDateTime): TDataSet;
    function GetMonthlySalesChart(Year: Integer): TDataSet;

    // Export Functions
    function ExportToCSV(DataSet: TDataSet; const FilePath: string): Boolean;
    function ExportToPDF(DataSet: TDataSet; const FilePath: string): Boolean;
  end;

var
  GReportService: TReportService;

implementation

uses
  DatabaseModule, AuthService, Constants, FMX.Dialogs, System.IOUtils;

{ TReportService }

function TReportService.GetQuery: TFDQuery;
begin
  Result := DMDatabase.qryReports;
end;

function TReportService.CheckPermissions: Boolean;
begin
  Result := False;

  if not Assigned(GAuthService) then
  begin
    ShowMessage('Authentication service not available');
    Exit;
  end;

  if not GAuthService.IsAuthenticated then
  begin
    ShowMessage('User not authenticated');
    Exit;
  end;

  if not GAuthService.CurrentUser.CanAccessReports then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  Result := True;
end;

function TReportService.FormatDateForSQL(ADate: TDateTime): string;
begin
  Result := FormatDateTime('yyyy-mm-dd', ADate);
end;

function TReportService.GetSalesReport(StartDate, EndDate: TDateTime; BranchID: Integer): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    // Complex SQL with multiple JOINs and aggregations
    SQL :=
      'SELECT ' +
      '  s.SaleID, ' +
      '  s.SaleNumber, ' +
      '  s.SaleDate, ' +
      '  b.BranchName, ' +
      '  u.FullName AS EmployeeName, ' +
      '  s.CustomerName, ' +
      '  s.CustomerPhone, ' +
      '  COUNT(si.SaleItemID) AS ItemCount, ' +
      '  SUM(si.Quantity) AS TotalQuantity, ' +
      '  s.SubTotal, ' +
      '  s.DiscountAmount, ' +
      '  s.TaxAmount, ' +
      '  s.TotalAmount, ' +
      '  s.PaymentMethod, ' +
      '  s.PaymentStatus, ' +
      '  s.Notes ' +
      'FROM Sales s ' +
      'LEFT JOIN Users u ON s.EmployeeID = u.UserID ' +
      'LEFT JOIN Branches b ON s.BranchID = b.BranchID ' +
      'LEFT JOIN SaleItems si ON s.SaleID = si.SaleID ' +
      'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ';

    if BranchID > 0 then
      SQL := SQL + 'AND s.BranchID = :BranchID ';

    SQL := SQL +
      'GROUP BY s.SaleID, s.SaleNumber, s.SaleDate, b.BranchName, u.FullName, ' +
      '  s.CustomerName, s.CustomerPhone, s.SubTotal, s.DiscountAmount, ' +
      '  s.TaxAmount, s.TotalAmount, s.PaymentMethod, s.PaymentStatus, s.Notes ' +
      'ORDER BY s.SaleDate DESC, s.SaleNumber DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;

    if BranchID > 0 then
      Query.ParamByName('BranchID').AsInteger := BranchID;

    Query.Open;
    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating sales report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetInventoryReport(BranchID: Integer): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  p.ProductID, ' +
      '  p.ProductCode, ' +
      '  p.ProductName, ' +
      '  p.Description, ' +
      '  c.CategoryName, ' +
      '  p.Barcode, ' +
      '  p.SKU, ' +
      '  p.UnitPrice, ' +
      '  p.CostPrice, ' +
      '  p.Quantity, ' +
      '  p.MinStockLevel, ' +
      '  p.MaxStockLevel, ' +
      '  b.BranchName, ' +
      '  (p.UnitPrice - p.CostPrice) AS ProfitPerUnit, ' +
      '  CASE ' +
      '    WHEN p.CostPrice > 0 THEN ((p.UnitPrice - p.CostPrice) / p.CostPrice * 100) ' +
      '    ELSE 0 ' +
      '  END AS ProfitMarginPercent, ' +
      '  (p.Quantity * p.CostPrice) AS TotalCostValue, ' +
      '  (p.Quantity * p.UnitPrice) AS TotalRetailValue, ' +
      '  CASE ' +
      '    WHEN p.Quantity <= 0 THEN ''Out of Stock'' ' +
      '    WHEN p.Quantity <= p.MinStockLevel THEN ''Low Stock'' ' +
      '    WHEN p.MaxStockLevel > 0 AND p.Quantity >= p.MaxStockLevel THEN ''Overstock'' ' +
      '    ELSE ''Normal'' ' +
      '  END AS StockStatus, ' +
      '  p.IsActive, ' +
      '  p.CreatedAt, ' +
      '  p.UpdatedAt ' +
      'FROM Products p ' +
      'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
      'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
      'WHERE 1=1 ';

    if BranchID > 0 then
      SQL := SQL + 'AND p.BranchID = :BranchID ';

    SQL := SQL + 'ORDER BY c.CategoryName, p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;

    if BranchID > 0 then
      Query.ParamByName('BranchID').AsInteger := BranchID;

    Query.Open;
    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating inventory report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetTopSellingProducts(StartDate, EndDate: TDateTime; TopN: Integer): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ';

    // Top N clause varies by database type
    case DMDatabase.DatabaseType of
      dtSQLServer:
        SQL := SQL + 'TOP ' + IntToStr(TopN) + ' ';
      dtMySQL, dtSQLite:
        ; // LIMIT clause added at end
      dtPostgreSQL:
        ; // LIMIT clause added at end
      dtOracle:
        ; // ROWNUM clause in WHERE
    end;

    SQL := SQL +
      '  p.ProductID, ' +
      '  p.ProductCode, ' +
      '  p.ProductName, ' +
      '  c.CategoryName, ' +
      '  SUM(si.Quantity) AS TotalQuantitySold, ' +
      '  COUNT(DISTINCT s.SaleID) AS NumberOfSales, ' +
      '  SUM(si.LineTotal) AS TotalRevenue, ' +
      '  AVG(si.UnitPrice) AS AverageSellingPrice, ' +
      '  SUM(si.Quantity * p.CostPrice) AS TotalCost, ' +
      '  SUM(si.LineTotal) - SUM(si.Quantity * p.CostPrice) AS TotalProfit, ' +
      '  CASE ' +
      '    WHEN SUM(si.Quantity * p.CostPrice) > 0 THEN ' +
      '      ((SUM(si.LineTotal) - SUM(si.Quantity * p.CostPrice)) / SUM(si.Quantity * p.CostPrice) * 100) ' +
      '    ELSE 0 ' +
      '  END AS ProfitMarginPercent ' +
      'FROM SaleItems si ' +
      'INNER JOIN Products p ON si.ProductID = p.ProductID ' +
      'INNER JOIN Sales s ON si.SaleID = s.SaleID ' +
      'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
      'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
      'GROUP BY p.ProductID, p.ProductCode, p.ProductName, c.CategoryName ' +
      'ORDER BY TotalQuantitySold DESC';

    // Add LIMIT clause for MySQL, PostgreSQL, SQLite
    case DMDatabase.DatabaseType of
      dtMySQL, dtPostgreSQL, dtSQLite:
        SQL := SQL + ' LIMIT ' + IntToStr(TopN);
    end;

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating top selling products report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetSalesByCategory(StartDate, EndDate: TDateTime): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  c.CategoryID, ' +
      '  c.CategoryName, ' +
      '  COUNT(DISTINCT s.SaleID) AS NumberOfSales, ' +
      '  SUM(si.Quantity) AS TotalQuantitySold, ' +
      '  COUNT(DISTINCT p.ProductID) AS UniqueProductsSold, ' +
      '  SUM(si.LineTotal) AS TotalRevenue, ' +
      '  AVG(si.LineTotal) AS AverageLineTotal, ' +
      '  SUM(si.Quantity * p.CostPrice) AS TotalCost, ' +
      '  SUM(si.LineTotal) - SUM(si.Quantity * p.CostPrice) AS TotalProfit, ' +
      '  CASE ' +
      '    WHEN SUM(si.Quantity * p.CostPrice) > 0 THEN ' +
      '      ((SUM(si.LineTotal) - SUM(si.Quantity * p.CostPrice)) / SUM(si.Quantity * p.CostPrice) * 100) ' +
      '    ELSE 0 ' +
      '  END AS ProfitMarginPercent ' +
      'FROM Categories c ' +
      'INNER JOIN Products p ON c.CategoryID = p.CategoryID ' +
      'INNER JOIN SaleItems si ON p.ProductID = si.ProductID ' +
      'INNER JOIN Sales s ON si.SaleID = s.SaleID ' +
      'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
      'GROUP BY c.CategoryID, c.CategoryName ' +
      'ORDER BY TotalRevenue DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating sales by category report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetSalesByEmployee(StartDate, EndDate: TDateTime): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  u.UserID, ' +
      '  u.FullName AS EmployeeName, ' +
      '  u.Email, ' +
      '  b.BranchName, ' +
      '  COUNT(s.SaleID) AS NumberOfSales, ' +
      '  SUM(s.TotalAmount) AS TotalSalesAmount, ' +
      '  AVG(s.TotalAmount) AS AverageSaleAmount, ' +
      '  MIN(s.TotalAmount) AS MinSaleAmount, ' +
      '  MAX(s.TotalAmount) AS MaxSaleAmount, ' +
      '  SUM(s.SubTotal) AS TotalSubTotal, ' +
      '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
      '  SUM(s.TaxAmount) AS TotalTax, ' +
      '  COUNT(DISTINCT DATE(s.SaleDate)) AS DaysWorked, ' +
      '  CASE ' +
      '    WHEN COUNT(DISTINCT DATE(s.SaleDate)) > 0 THEN ' +
      '      SUM(s.TotalAmount) / COUNT(DISTINCT DATE(s.SaleDate)) ' +
      '    ELSE 0 ' +
      '  END AS AverageDailySales ' +
      'FROM Users u ' +
      'LEFT JOIN Sales s ON u.UserID = s.EmployeeID ' +
      '  AND s.SaleDate BETWEEN :StartDate AND :EndDate ' +
      'LEFT JOIN Branches b ON u.BranchID = b.BranchID ' +
      'WHERE u.IsActive = 1 ' +
      'GROUP BY u.UserID, u.FullName, u.Email, b.BranchName ' +
      'HAVING COUNT(s.SaleID) > 0 ' +
      'ORDER BY TotalSalesAmount DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating sales by employee report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetDailySalesChart(StartDate, EndDate: TDateTime): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    // Date grouping varies by database
    case DMDatabase.DatabaseType of
      dtSQLServer:
        SQL :=
          'SELECT ' +
          '  CONVERT(DATE, s.SaleDate) AS SaleDate, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
          'GROUP BY CONVERT(DATE, s.SaleDate) ' +
          'ORDER BY SaleDate';

      dtMySQL:
        SQL :=
          'SELECT ' +
          '  DATE(s.SaleDate) AS SaleDate, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
          'GROUP BY DATE(s.SaleDate) ' +
          'ORDER BY SaleDate';

      dtPostgreSQL:
        SQL :=
          'SELECT ' +
          '  DATE(s.SaleDate) AS SaleDate, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
          'GROUP BY DATE(s.SaleDate) ' +
          'ORDER BY SaleDate';

      else // SQLite and others
        SQL :=
          'SELECT ' +
          '  DATE(s.SaleDate) AS SaleDate, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
          'GROUP BY DATE(s.SaleDate) ' +
          'ORDER BY SaleDate';
    end;

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating daily sales chart data: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetMonthlySalesChart(Year: Integer): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    // Month grouping varies by database
    case DMDatabase.DatabaseType of
      dtSQLServer:
        SQL :=
          'SELECT ' +
          '  YEAR(s.SaleDate) AS Year, ' +
          '  MONTH(s.SaleDate) AS Month, ' +
          '  DATENAME(MONTH, s.SaleDate) AS MonthName, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE YEAR(s.SaleDate) = :Year ' +
          'GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate), DATENAME(MONTH, s.SaleDate) ' +
          'ORDER BY Month';

      dtMySQL:
        SQL :=
          'SELECT ' +
          '  YEAR(s.SaleDate) AS Year, ' +
          '  MONTH(s.SaleDate) AS Month, ' +
          '  MONTHNAME(s.SaleDate) AS MonthName, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE YEAR(s.SaleDate) = :Year ' +
          'GROUP BY YEAR(s.SaleDate), MONTH(s.SaleDate) ' +
          'ORDER BY Month';

      dtPostgreSQL:
        SQL :=
          'SELECT ' +
          '  EXTRACT(YEAR FROM s.SaleDate) AS Year, ' +
          '  EXTRACT(MONTH FROM s.SaleDate) AS Month, ' +
          '  TO_CHAR(s.SaleDate, ''Month'') AS MonthName, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE EXTRACT(YEAR FROM s.SaleDate) = :Year ' +
          'GROUP BY EXTRACT(YEAR FROM s.SaleDate), EXTRACT(MONTH FROM s.SaleDate), TO_CHAR(s.SaleDate, ''Month'') ' +
          'ORDER BY Month';

      else // SQLite
        SQL :=
          'SELECT ' +
          '  CAST(STRFTIME(''%Y'', s.SaleDate) AS INTEGER) AS Year, ' +
          '  CAST(STRFTIME(''%m'', s.SaleDate) AS INTEGER) AS Month, ' +
          '  CASE CAST(STRFTIME(''%m'', s.SaleDate) AS INTEGER) ' +
          '    WHEN 1 THEN ''January'' WHEN 2 THEN ''February'' WHEN 3 THEN ''March'' ' +
          '    WHEN 4 THEN ''April'' WHEN 5 THEN ''May'' WHEN 6 THEN ''June'' ' +
          '    WHEN 7 THEN ''July'' WHEN 8 THEN ''August'' WHEN 9 THEN ''September'' ' +
          '    WHEN 10 THEN ''October'' WHEN 11 THEN ''November'' WHEN 12 THEN ''December'' ' +
          '  END AS MonthName, ' +
          '  COUNT(s.SaleID) AS NumberOfSales, ' +
          '  SUM(s.TotalAmount) AS TotalSales, ' +
          '  AVG(s.TotalAmount) AS AverageSale, ' +
          '  SUM(s.SubTotal) AS SubTotal, ' +
          '  SUM(s.DiscountAmount) AS TotalDiscounts, ' +
          '  SUM(s.TaxAmount) AS TotalTax ' +
          'FROM Sales s ' +
          'WHERE CAST(STRFTIME(''%Y'', s.SaleDate) AS INTEGER) = :Year ' +
          'GROUP BY CAST(STRFTIME(''%Y'', s.SaleDate) AS INTEGER), CAST(STRFTIME(''%m'', s.SaleDate) AS INTEGER) ' +
          'ORDER BY Month';
    end;

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Year').AsInteger := Year;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating monthly sales chart data: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetLowStockReport: TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  p.ProductID, ' +
      '  p.ProductCode, ' +
      '  p.ProductName, ' +
      '  c.CategoryName, ' +
      '  b.BranchName, ' +
      '  p.Quantity AS CurrentStock, ' +
      '  p.MinStockLevel, ' +
      '  p.MaxStockLevel, ' +
      '  (p.MaxStockLevel - p.Quantity) AS ReorderQuantity, ' +
      '  p.UnitPrice, ' +
      '  p.CostPrice, ' +
      '  (p.MaxStockLevel - p.Quantity) * p.CostPrice AS ReorderCost, ' +
      '  p.Barcode, ' +
      '  p.SKU, ' +
      '  ''Low Stock'' AS StockStatus ' +
      'FROM Products p ' +
      'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
      'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
      'WHERE p.Quantity > 0 ' +
      '  AND p.Quantity <= p.MinStockLevel ' +
      '  AND p.IsActive = 1 ' +
      'ORDER BY p.Quantity ASC, c.CategoryName, p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating low stock report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetOutOfStockReport: TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  p.ProductID, ' +
      '  p.ProductCode, ' +
      '  p.ProductName, ' +
      '  c.CategoryName, ' +
      '  b.BranchName, ' +
      '  p.Quantity AS CurrentStock, ' +
      '  p.MinStockLevel, ' +
      '  p.MaxStockLevel, ' +
      '  p.MaxStockLevel AS ReorderQuantity, ' +
      '  p.UnitPrice, ' +
      '  p.CostPrice, ' +
      '  p.MaxStockLevel * p.CostPrice AS ReorderCost, ' +
      '  p.Barcode, ' +
      '  p.SKU, ' +
      '  p.UpdatedAt AS LastUpdated, ' +
      '  ''Out of Stock'' AS StockStatus ' +
      'FROM Products p ' +
      'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
      'LEFT JOIN Branches b ON p.BranchID = b.BranchID ' +
      'WHERE p.Quantity <= 0 ' +
      '  AND p.IsActive = 1 ' +
      'ORDER BY p.UpdatedAt DESC, c.CategoryName, p.ProductName';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating out of stock report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.GetProfitAnalysis(StartDate, EndDate: TDateTime): TDataSet;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := nil;

  if not CheckPermissions then
    Exit;

  try
    Query := GetQuery;

    SQL :=
      'SELECT ' +
      '  p.ProductID, ' +
      '  p.ProductCode, ' +
      '  p.ProductName, ' +
      '  c.CategoryName, ' +
      '  SUM(si.Quantity) AS TotalQuantitySold, ' +
      '  SUM(si.Quantity * si.UnitPrice) AS TotalRevenue, ' +
      '  SUM(si.Quantity * p.CostPrice) AS TotalCost, ' +
      '  SUM(si.Quantity * si.UnitPrice) - SUM(si.Quantity * p.CostPrice) AS GrossProfit, ' +
      '  CASE ' +
      '    WHEN SUM(si.Quantity * p.CostPrice) > 0 THEN ' +
      '      ((SUM(si.Quantity * si.UnitPrice) - SUM(si.Quantity * p.CostPrice)) / ' +
      '       SUM(si.Quantity * p.CostPrice) * 100) ' +
      '    ELSE 0 ' +
      '  END AS ProfitMarginPercent, ' +
      '  CASE ' +
      '    WHEN SUM(si.Quantity * si.UnitPrice) > 0 THEN ' +
      '      ((SUM(si.Quantity * si.UnitPrice) - SUM(si.Quantity * p.CostPrice)) / ' +
      '       SUM(si.Quantity * si.UnitPrice) * 100) ' +
      '    ELSE 0 ' +
      '  END AS MarkupPercent, ' +
      '  AVG(si.UnitPrice) AS AverageSellingPrice, ' +
      '  p.CostPrice AS CurrentCostPrice, ' +
      '  p.UnitPrice AS CurrentRetailPrice, ' +
      '  (p.UnitPrice - p.CostPrice) AS CurrentProfitPerUnit, ' +
      '  COUNT(DISTINCT s.SaleID) AS NumberOfTransactions ' +
      'FROM SaleItems si ' +
      'INNER JOIN Products p ON si.ProductID = p.ProductID ' +
      'INNER JOIN Sales s ON si.SaleID = s.SaleID ' +
      'LEFT JOIN Categories c ON p.CategoryID = c.CategoryID ' +
      'WHERE s.SaleDate BETWEEN :StartDate AND :EndDate ' +
      'GROUP BY p.ProductID, p.ProductCode, p.ProductName, c.CategoryName, ' +
      '  p.CostPrice, p.UnitPrice ' +
      'HAVING SUM(si.Quantity) > 0 ' +
      'ORDER BY GrossProfit DESC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('StartDate').AsDateTime := StartDate;
    Query.ParamByName('EndDate').AsDateTime := EndDate;
    Query.Open;

    Result := Query;

  except
    on E: Exception do
    begin
      ShowMessage('Error generating profit analysis report: ' + E.Message);
      Result := nil;
    end;
  end;
end;

function TReportService.ExportToCSV(DataSet: TDataSet; const FilePath: string): Boolean;
var
  CSVFile: TextFile;
  I: Integer;
  Line: string;
begin
  Result := False;

  if not Assigned(DataSet) or DataSet.IsEmpty then
  begin
    ShowMessage('No data to export');
    Exit;
  end;

  try
    // Ensure directory exists
    ForceDirectories(ExtractFilePath(FilePath));

    AssignFile(CSVFile, FilePath);
    try
      Rewrite(CSVFile);

      // Write header row
      Line := '';
      for I := 0 to DataSet.FieldCount - 1 do
      begin
        if I > 0 then
          Line := Line + ',';
        Line := Line + '"' + DataSet.Fields[I].FieldName + '"';
      end;
      WriteLn(CSVFile, Line);

      // Write data rows
      DataSet.First;
      while not DataSet.Eof do
      begin
        Line := '';
        for I := 0 to DataSet.FieldCount - 1 do
        begin
          if I > 0 then
            Line := Line + ',';

          // Handle different field types
          if DataSet.Fields[I].IsNull then
            Line := Line + '""'
          else if DataSet.Fields[I].DataType in [ftString, ftWideString, ftMemo, ftWideMemo] then
            Line := Line + '"' + StringReplace(DataSet.Fields[I].AsString, '"', '""', [rfReplaceAll]) + '"'
          else if DataSet.Fields[I].DataType in [ftDate, ftDateTime, ftTime] then
            Line := Line + '"' + FormatDateTime('yyyy-mm-dd hh:nn:ss', DataSet.Fields[I].AsDateTime) + '"'
          else if DataSet.Fields[I].DataType in [ftFloat, ftCurrency, ftBCD, ftFMTBcd] then
            Line := Line + FormatFloat('0.00', DataSet.Fields[I].AsFloat)
          else
            Line := Line + DataSet.Fields[I].AsString;
        end;
        WriteLn(CSVFile, Line);
        DataSet.Next;
      end;

      Result := True;
      ShowMessage('Data exported successfully to: ' + FilePath);

    finally
      CloseFile(CSVFile);
    end;

  except
    on E: Exception do
    begin
      ShowMessage('Error exporting to CSV: ' + E.Message);
      Result := False;
    end;
  end;
end;

function TReportService.ExportToPDF(DataSet: TDataSet; const FilePath: string): Boolean;
begin
  // PDF export stub - to be implemented with a PDF library
  // This would require a third-party component like:
  // - FastReport
  // - ReportBuilder
  // - QReport
  // - QuickReport
  // - or direct PDF generation library

  Result := False;

  if not Assigned(DataSet) or DataSet.IsEmpty then
  begin
    ShowMessage('No data to export');
    Exit;
  end;

  try
    // TODO: Implement PDF export using a PDF library
    ShowMessage('PDF export functionality will be implemented with a PDF library component.' + sLineBreak +
                'For now, please use CSV export.');
    Result := False;

  except
    on E: Exception do
    begin
      ShowMessage('Error exporting to PDF: ' + E.Message);
      Result := False;
    end;
  end;
end;

initialization
  GReportService := TReportService.Create;

finalization
  GReportService.Free;

end.
