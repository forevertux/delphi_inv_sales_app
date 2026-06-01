unit DatabaseModule;

interface

uses
  System.SysUtils, System.Classes, System.IOUtils, FireDAC.Stan.Intf, FireDAC.Stan.Option,
  FireDAC.Stan.Error, FireDAC.UI.Intf, FireDAC.Phys.Intf, FireDAC.Stan.Def,
  FireDAC.Stan.Pool, FireDAC.Stan.Async, FireDAC.Phys, FireDAC.FMXUI.Wait,
  FireDAC.Stan.Param, FireDAC.DatS, FireDAC.DApt.Intf, FireDAC.DApt,
  Data.DB, FireDAC.Comp.DataSet, FireDAC.Comp.Client, System.IniFiles,
  FireDAC.Phys.SQLite, FireDAC.Phys.SQLiteDef, FireDAC.Stan.ExprFuncs,
  FireDAC.Comp.Script, FireDAC.Comp.ScriptCommands
  {$IFDEF USE_MSSQL}
  , FireDAC.Phys.MSSQLDef, FireDAC.Phys.MSSQL
  {$ENDIF}
  {$IFDEF USE_MYSQL}
  , FireDAC.Phys.MySQL, FireDAC.Phys.MySQLDef
  {$ENDIF}
  {$IFDEF USE_POSTGRESQL}
  , FireDAC.Phys.PG, FireDAC.Phys.PGDef
  {$ENDIF}
  {$IFDEF USE_ORACLE}
  , FireDAC.Phys.Oracle, FireDAC.Phys.OracleDef
  {$ENDIF};

type
  TDatabaseType = (dtSQLServer, dtMySQL, dtPostgreSQL, dtOracle, dtSQLite);

  TDMDatabase = class(TDataModule)
    FDConnection: TFDConnection;
    FDPhysSQLiteDriverLink: TFDPhysSQLiteDriverLink;
    {$IFDEF USE_MSSQL}
    FDPhysMSSQLDriverLink: TFDPhysMSSQLDriverLink;
    {$ENDIF}
    {$IFDEF USE_MYSQL}
    FDPhysMySQLDriverLink: TFDPhysMySQLDriverLink;
    {$ENDIF}
    {$IFDEF USE_POSTGRESQL}
    FDPhysPgDriverLink: TFDPhysPgDriverLink;
    {$ENDIF}
    {$IFDEF USE_ORACLE}
    FDPhysOracleDriverLink: TFDPhysOracleDriverLink;
    {$ENDIF}
    FDTransaction: TFDTransaction;
    qryGeneral: TFDQuery;
    qryProducts: TFDQuery;
    qrySales: TFDQuery;
    qryUsers: TFDQuery;
    qryReports: TFDQuery;
    procedure DataModuleCreate(Sender: TObject);
    procedure DataModuleDestroy(Sender: TObject);
  private
    FConfigFile: string;
    FDatabaseType: TDatabaseType;
    FIsConnected: Boolean;
    FIsOfflineMode: Boolean;
    FLocalDBPath: string;
    function GetConfigValue(const Section, Key, Default: string): string;
    procedure SetupSQLServerConnection(const Server, Database, Username, Password: string; UseWindowsAuth: Boolean);
    procedure SetupMySQLConnection(const Server, Database, Username, Password: string; Port: Integer);
    procedure SetupPostgreSQLConnection(const Server, Database, Username, Password: string; Port: Integer);
    procedure SetupOracleConnection(const Server, Database, Username, Password: string);
    procedure SetupSQLiteConnection(const DatabasePath: string);
    procedure LoadConfiguration;
    procedure CreateLocalDatabase;
    procedure InitializeDatabase;
    function RunSQLScriptFromFile(const AFileName: string): Boolean;
    function ResolveDatabaseFilePath(const AFileName: string): string;
    procedure ClearDemoData;
  public
    function Connect: Boolean;
    procedure Disconnect;
    function IsConnected: Boolean;
    function ExecuteSQL(const SQL: string): Boolean;
    function ExecuteQuery(const SQL: string; Query: TFDQuery): Boolean;
    function GetLastInsertID: Int64;
    procedure BeginTrans;
    procedure CommitTrans;
    procedure RollbackTrans;
    function TestConnection: Boolean;
    procedure SwitchToOfflineMode;
    procedure SwitchToOnlineMode;
    function CreateQuery: TFDQuery;
    function SqlDateExpr(const FieldName: string): string;
    function SqlDateGroupExpr(const FieldName: string): string;
    function ConfigFilePath: string;
    function ReadBoolField(Field: TField): Boolean;
    procedure SetBoolParam(Param: TFDParam; Value: Boolean);
    function IsDemoDataLoaded: Boolean;
    function LoadDemoData(const AReload: Boolean = False): Boolean;
    property DatabaseType: TDatabaseType read FDatabaseType;
    property IsOfflineMode: Boolean read FIsOfflineMode;
  end;

var
  DMDatabase: TDMDatabase;

implementation

{%CLASSGROUP 'FMX.Controls.TControl'}

{$R *.dfm}

uses
  FMX.Dialogs, SyncService;

procedure TDMDatabase.DataModuleCreate(Sender: TObject);
begin
  {$IFDEF MOBILE}
  FConfigFile := TPath.Combine(TPath.GetDocumentsPath, 'InventorySales.ini');
  FLocalDBPath := TPath.Combine(TPath.GetDocumentsPath, 'inventory_local.db');
  {$ELSE}
  FConfigFile := TPath.Combine(ExtractFilePath(ParamStr(0)), 'InventorySales.ini');
  if not FileExists(FConfigFile) then
    FConfigFile := TPath.Combine(TPath.GetDocumentsPath, 'InventorySales.ini');
  FLocalDBPath := TPath.Combine(ExtractFilePath(ParamStr(0)), 'data', 'inventory_local.db');
  {$ENDIF}

  FIsConnected := False;
  FIsOfflineMode := False;

  LoadConfiguration;
end;

function TDMDatabase.ConfigFilePath: string;
begin
  Result := FConfigFile;
end;

function TDMDatabase.ReadBoolField(Field: TField): Boolean;
begin
  if Field.IsNull then
    Exit(False);

  if (FDatabaseType = dtSQLite) or (Field.DataType <> ftBoolean) then
    Result := Field.AsInteger <> 0
  else
    Result := Field.AsBoolean;
end;

procedure TDMDatabase.SetBoolParam(Param: TFDParam; Value: Boolean);
begin
  if FDatabaseType = dtSQLite then
    Param.AsInteger := Ord(Value)
  else
    Param.AsBoolean := Value;
end;

function TDMDatabase.CreateQuery: TFDQuery;
begin
  Result := TFDQuery.Create(nil);
  Result.Connection := FDConnection;
  Result.Transaction := FDTransaction;
end;

function TDMDatabase.SqlDateExpr(const FieldName: string): string;
begin
  case FDatabaseType of
    dtSQLServer:
      Result := Format('CAST(%s AS DATE)', [FieldName]);
    dtOracle:
      Result := Format('TRUNC(%s)', [FieldName]);
  else
    Result := Format('DATE(%s)', [FieldName]);
  end;
end;

function TDMDatabase.SqlDateGroupExpr(const FieldName: string): string;
begin
  Result := SqlDateExpr(FieldName);
end;

procedure TDMDatabase.DataModuleDestroy(Sender: TObject);
begin
  if FIsConnected then
    Disconnect;
end;

function TDMDatabase.GetConfigValue(const Section, Key, Default: string): string;
var
  IniFile: TIniFile;
begin
  Result := Default;
  if FileExists(FConfigFile) then
  begin
    IniFile := TIniFile.Create(FConfigFile);
    try
      Result := IniFile.ReadString(Section, Key, Default);
    finally
      IniFile.Free;
    end;
  end;
end;

procedure TDMDatabase.LoadConfiguration;
var
  DBTypeStr: string;
begin
  DBTypeStr := GetConfigValue('Database', 'Type', 'SQLServer');

  if SameText(DBTypeStr, 'SQLServer') then
    FDatabaseType := dtSQLServer
  else if SameText(DBTypeStr, 'MySQL') then
    FDatabaseType := dtMySQL
  else if SameText(DBTypeStr, 'PostgreSQL') then
    FDatabaseType := dtPostgreSQL
  else if SameText(DBTypeStr, 'Oracle') then
    FDatabaseType := dtOracle
  else if SameText(DBTypeStr, 'SQLite') then
    FDatabaseType := dtSQLite
  else if not FileExists(FConfigFile) then
    FDatabaseType := dtSQLite
  else
    FDatabaseType := dtSQLServer;
end;

procedure TDMDatabase.SetupSQLServerConnection(const Server, Database, Username, Password: string; UseWindowsAuth: Boolean);
begin
  FDConnection.DriverName := 'MSSQL';
  FDConnection.Params.Clear;
  FDConnection.Params.Add('Server=' + Server);
  FDConnection.Params.Add('Database=' + Database);

  if UseWindowsAuth then
    FDConnection.Params.Add('OSAuthent=Yes')
  else
  begin
    FDConnection.Params.Add('User_Name=' + Username);
    FDConnection.Params.Add('Password=' + Password);
  end;

  FDConnection.Params.Add('ApplicationName=InventorySales');
  FDConnection.Params.Add('Pooled=True');
  FDConnection.Params.Add('MARS=Yes');
end;

procedure TDMDatabase.SetupMySQLConnection(const Server, Database, Username, Password: string; Port: Integer);
begin
  FDConnection.DriverName := 'MySQL';
  FDConnection.Params.Clear;
  FDConnection.Params.Add('Server=' + Server);
  FDConnection.Params.Add('Database=' + Database);
  FDConnection.Params.Add('User_Name=' + Username);
  FDConnection.Params.Add('Password=' + Password);
  FDConnection.Params.Add('Port=' + IntToStr(Port));
  FDConnection.Params.Add('CharacterSet=utf8mb4');
end;

procedure TDMDatabase.SetupPostgreSQLConnection(const Server, Database, Username, Password: string; Port: Integer);
begin
  FDConnection.DriverName := 'PG';
  FDConnection.Params.Clear;
  FDConnection.Params.Add('Server=' + Server);
  FDConnection.Params.Add('Database=' + Database);
  FDConnection.Params.Add('User_Name=' + Username);
  FDConnection.Params.Add('Password=' + Password);
  FDConnection.Params.Add('Port=' + IntToStr(Port));
  FDConnection.Params.Add('CharacterSet=UTF8');
end;

procedure TDMDatabase.SetupOracleConnection(const Server, Database, Username, Password: string);
begin
  FDConnection.DriverName := 'Ora';
  FDConnection.Params.Clear;
  FDConnection.Params.Add('Server=' + Server);
  FDConnection.Params.Add('Database=' + Database);
  FDConnection.Params.Add('User_Name=' + Username);
  FDConnection.Params.Add('Password=' + Password);
  FDConnection.Params.Add('CharacterSet=UTF8');
end;

procedure TDMDatabase.SetupSQLiteConnection(const DatabasePath: string);
var
  FullPath: string;
  DBDir: string;
begin
  // Expand relative path to absolute path
  if TPath.IsRelativePath(DatabasePath) then
    FullPath := TPath.Combine(ExtractFilePath(ParamStr(0)), DatabasePath)
  else
    FullPath := DatabasePath;

  FullPath := TPath.GetFullPath(FullPath);

  // Create directory if it doesn't exist
  DBDir := ExtractFilePath(FullPath);
  if not TDirectory.Exists(DBDir) then
  begin
    try
      TDirectory.CreateDirectory(DBDir);
    except
      on E: Exception do
        ShowMessage('Error creating database directory: ' + DBDir + #13#10 + E.Message);
    end;
  end;

  if not Assigned(FDPhysSQLiteDriverLink) then
    FDPhysSQLiteDriverLink := TFDPhysSQLiteDriverLink.Create(Self);

  // Configure SQLite driver link - try multiple locations
  if FileExists(TPath.Combine(ExtractFilePath(ParamStr(0)), 'sqlite3.dll')) then
    FDPhysSQLiteDriverLink.VendorLib := TPath.Combine(ExtractFilePath(ParamStr(0)), 'sqlite3.dll')
  else if FileExists('C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\sqlite3.dll') then
    FDPhysSQLiteDriverLink.VendorLib := 'C:\Program Files (x86)\Embarcadero\Studio\23.0\bin\sqlite3.dll'
  else
    FDPhysSQLiteDriverLink.VendorLib := 'sqlite3.dll'; // Try system PATH

  // Clear and reconfigure connection
  FDConnection.Close;
  FDConnection.ConnectionDefName := '';
  FDConnection.Params.Clear;

  // Set DriverID instead of DriverName
  FDConnection.Params.Add('DriverID=SQLite');
  FDConnection.Params.Add('Database=' + FullPath);
  FDConnection.Params.Add('LockingMode=Normal');
  FDConnection.Params.Add('Synchronous=Normal');
  FDConnection.Params.Add('JournalMode=WAL');
  FDConnection.Params.Add('OpenMode=CreateUTF8');
end;

function TDMDatabase.Connect: Boolean;
var
  Server, Database, Username, Password: string;
  Port: Integer;
  UseWindowsAuth: Boolean;
begin
  Result := False;

  try
    // Check if already connected
    if FDConnection.Connected then
    begin
      Result := True;
      Exit;
    end;

    // Setup connection based on database type
    case FDatabaseType of
      dtSQLServer:
      begin
        Server := GetConfigValue('Database', 'Server', 'localhost');
        Database := GetConfigValue('Database', 'Database', 'InventorySales');
        Username := GetConfigValue('Database', 'Username', 'sa');
        Password := GetConfigValue('Database', 'Password', '');
        UseWindowsAuth := StrToBoolDef(GetConfigValue('Database', 'WindowsAuth', 'False'), False);
        SetupSQLServerConnection(Server, Database, Username, Password, UseWindowsAuth);
      end;

      dtMySQL:
      begin
        Server := GetConfigValue('Database', 'Server', 'localhost');
        Database := GetConfigValue('Database', 'Database', 'inventory_sales');
        Username := GetConfigValue('Database', 'Username', 'root');
        Password := GetConfigValue('Database', 'Password', '');
        Port := StrToIntDef(GetConfigValue('Database', 'Port', '3306'), 3306);
        SetupMySQLConnection(Server, Database, Username, Password, Port);
      end;

      dtPostgreSQL:
      begin
        Server := GetConfigValue('Database', 'Server', 'localhost');
        Database := GetConfigValue('Database', 'Database', 'inventory_sales');
        Username := GetConfigValue('Database', 'Username', 'postgres');
        Password := GetConfigValue('Database', 'Password', '');
        Port := StrToIntDef(GetConfigValue('Database', 'Port', '5432'), 5432);
        SetupPostgreSQLConnection(Server, Database, Username, Password, Port);
      end;

      dtOracle:
      begin
        Server := GetConfigValue('Database', 'Server', 'localhost:1521');
        Database := GetConfigValue('Database', 'Database', 'ORCL');
        Username := GetConfigValue('Database', 'Username', 'system');
        Password := GetConfigValue('Database', 'Password', '');
        SetupOracleConnection(Server, Database, Username, Password);
      end;

      dtSQLite:
      begin
        Database := GetConfigValue('Database', 'Database', FLocalDBPath);
        SetupSQLiteConnection(Database);
      end;
    end;

    FDConnection.Connected := True;
    InitializeDatabase;
    if FDatabaseType = dtSQLite then
      LoadDemoData(False);
    FIsConnected := True;
    if Assigned(GSyncService) then
      GSyncService.EnsureInitialized;
    Result := True;

  except
    on E: Exception do
    begin
      FIsConnected := False;

      {$IFDEF MOBILE}
      SwitchToOfflineMode;
      Result := True;
      {$ELSE}
      Result := False;
      {$ENDIF}
    end;
  end;
end;

procedure TDMDatabase.Disconnect;
begin
  try
    if FDConnection.Connected then
      FDConnection.Connected := False;
    FIsConnected := False;
  except
    on E: Exception do
      ShowMessage('Error disconnecting: ' + E.Message);
  end;
end;

function TDMDatabase.IsConnected: Boolean;
begin
  Result := FIsConnected and FDConnection.Connected;
end;

function TDMDatabase.ExecuteSQL(const SQL: string): Boolean;
begin
  Result := False;
  try
    FDConnection.ExecSQL(SQL);
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error executing SQL: ' + E.Message);
  end;
end;

function TDMDatabase.ExecuteQuery(const SQL: string; Query: TFDQuery): Boolean;
begin
  Result := False;
  try
    Query.Close;
    Query.SQL.Text := SQL;
    Query.Open;
    Result := True;
  except
    on E: Exception do
      ShowMessage('Error executing query: ' + E.Message);
  end;
end;

function TDMDatabase.GetLastInsertID: Int64;
begin
  Result := -1;
  try
    case FDatabaseType of
      dtSQLServer:
        Result := FDConnection.GetLastAutoGenValue('');
      dtMySQL:
        Result := FDConnection.GetLastAutoGenValue('');
      dtPostgreSQL:
        Result := FDConnection.GetLastAutoGenValue('');
      dtOracle:
        Result := FDConnection.GetLastAutoGenValue('');
      dtSQLite:
        Result := FDConnection.GetLastAutoGenValue('');
    end;
  except
    Result := -1;
  end;
end;

procedure TDMDatabase.BeginTrans;
begin
  if not FDTransaction.Active then
    FDTransaction.StartTransaction;
end;

procedure TDMDatabase.CommitTrans;
begin
  if FDTransaction.Active then
    FDTransaction.Commit;
end;

procedure TDMDatabase.RollbackTrans;
begin
  if FDTransaction.Active then
    FDTransaction.Rollback;
end;

function TDMDatabase.TestConnection: Boolean;
begin
  Result := False;
  try
    if not FDConnection.Connected then
      FDConnection.Connected := True;
    Result := FDConnection.Connected;
  except
    Result := False;
  end;
end;

procedure TDMDatabase.SwitchToOfflineMode;
begin
  try
    if FDConnection.Connected then
      Disconnect;

    FDatabaseType := dtSQLite;
    SetupSQLiteConnection(FLocalDBPath);
    FDConnection.Connected := True;
    InitializeDatabase;
    LoadDemoData(False);
    FIsOfflineMode := True;
    FIsConnected := True;
    if Assigned(GSyncService) then
      GSyncService.EnsureInitialized;
  except
    on E: Exception do
      raise;
  end;
end;

procedure TDMDatabase.SwitchToOnlineMode;
begin
  try
    if FDConnection.Connected then
      Disconnect;

    FIsOfflineMode := False;
    LoadConfiguration;
    Connect;
  except
    on E: Exception do
      ShowMessage('Error switching to online mode: ' + E.Message);
  end;
end;

procedure TDMDatabase.CreateLocalDatabase;
var
  LocalConn: TFDConnection;
begin
  try
    // Ensure directory exists
    ForceDirectories(ExtractFilePath(FLocalDBPath));

    LocalConn := TFDConnection.Create(nil);
    try
      LocalConn.DriverName := 'SQLite';
      LocalConn.Params.Add('Database=' + FLocalDBPath);
      LocalConn.Params.Add('LockingMode=Normal');
      LocalConn.Connected := True;

      // Create simplified schema for offline use
      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS Products (' +
        'ProductID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'ProductCode TEXT NOT NULL UNIQUE, ' +
        'ProductName TEXT NOT NULL, ' +
        'Description TEXT, ' +
        'CategoryID INTEGER, ' +
        'UnitPrice REAL NOT NULL, ' +
        'Quantity INTEGER NOT NULL DEFAULT 0, ' +
        'IsActive INTEGER DEFAULT 1, ' +
        'CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS Sales (' +
        'SaleID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'SaleNumber TEXT NOT NULL UNIQUE, ' +
        'SaleDate DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
        'EmployeeID INTEGER, ' +
        'TotalAmount REAL NOT NULL, ' +
        'IsSynced INTEGER DEFAULT 0)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS Users (' +
        'UserID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'Username TEXT NOT NULL UNIQUE, ' +
        'PasswordHash TEXT NOT NULL, ' +
        'FullName TEXT NOT NULL, ' +
        'Email TEXT, ' +
        'Phone TEXT, ' +
        'RoleID INTEGER NOT NULL, ' +
        'BranchID INTEGER, ' +
        'IsActive INTEGER DEFAULT 1, ' +
        'LastLogin DATETIME, ' +
        'CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
        'UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS Branches (' +
        'BranchID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'BranchCode TEXT NOT NULL UNIQUE, ' +
        'BranchName TEXT NOT NULL, ' +
        'IsActive INTEGER DEFAULT 1)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS Categories (' +
        'CategoryID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'CategoryCode TEXT NOT NULL UNIQUE, ' +
        'CategoryName TEXT NOT NULL, ' +
        'IsActive INTEGER DEFAULT 1)');

      LocalConn.ExecSQL(
        'INSERT OR IGNORE INTO Branches (BranchID, BranchCode, BranchName) ' +
        'VALUES (1, ''MAIN'', ''Main Branch'')');

      LocalConn.ExecSQL(
        'INSERT OR IGNORE INTO Categories (CategoryID, CategoryCode, CategoryName) ' +
        'VALUES (1, ''GEN'', ''General'')');

      LocalConn.ExecSQL(
        'INSERT OR IGNORE INTO Users (UserID, Username, PasswordHash, FullName, RoleID, BranchID) ' +
        'VALUES (1, ''admin'', ''E86F78A8A3CAF0B60D8E74E5942AA6D86DC150CD3C03338AEF25B7D2D7E3ACC7'', ' +
        '''System Administrator'', 1, 1)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS SaleItems (' +
        'SaleItemID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'SaleID INTEGER NOT NULL, ' +
        'ProductID INTEGER NOT NULL, ' +
        'Quantity INTEGER NOT NULL, ' +
        'UnitPrice REAL NOT NULL, ' +
        'DiscountPercent REAL DEFAULT 0, ' +
        'TaxPercent REAL DEFAULT 0, ' +
        'LineTotal REAL NOT NULL)');

      LocalConn.ExecSQL(
        'CREATE TABLE IF NOT EXISTS SyncLog (' +
        'SyncID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
        'TableName TEXT NOT NULL, ' +
        'RecordID INTEGER NOT NULL, ' +
        'Operation TEXT NOT NULL, ' +
        'SyncStatus TEXT DEFAULT ''Pending'', ' +
        'CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP)');

      LocalConn.Connected := False;
    finally
      LocalConn.Free;
    end;
  except
    on E: Exception do
      ShowMessage('Error creating local database: ' + E.Message);
  end;
end;


function TDMDatabase.ResolveDatabaseFilePath(const AFileName: string): string;
begin
  Result := TPath.Combine(ExtractFilePath(ParamStr(0)), 'database', AFileName);
  if not TFile.Exists(Result) then
    Result := TPath.Combine(ExtractFilePath(ParamStr(0)), '..\..', 'database', AFileName);
end;

function TDMDatabase.RunSQLScriptFromFile(const AFileName: string): Boolean;
var
  ScriptFile: string;
  Script: TFDScript;
begin
  Result := False;
  ScriptFile := ResolveDatabaseFilePath(AFileName);
  if not TFile.Exists(ScriptFile) then
    Exit;

  Script := TFDScript.Create(nil);
  try
    Script.Connection := FDConnection;
    Script.ScriptOptions.BreakOnError := False;
    Script.ScriptOptions.CommandSeparator := ';';
    Script.SQLScripts.Clear;
    Script.SQLScripts.Add.SQL.LoadFromFile(ScriptFile);
    Script.ValidateAll;
    Script.ExecuteAll;
    Result := True;
  finally
    Script.Free;
  end;
end;

procedure TDMDatabase.InitializeDatabase;
var
  Query: TFDQuery;
begin
  try
    Query := TFDQuery.Create(nil);
    try
      Query.Connection := FDConnection;
      try
        Query.SQL.Text := 'SELECT COUNT(*) FROM Users';
        Query.Open;
        Query.Close;
        Exit;
      except
      end;
    finally
      Query.Free;
    end;

    if FDatabaseType = dtSQLite then
    begin
      if not RunSQLScriptFromFile('schema_sqlite.sql') then
        CreateLocalDatabase;
    end;

  except
    on E: Exception do
      ShowMessage('Error initializing database: ' + E.Message);
  end;
end;

function TDMDatabase.IsDemoDataLoaded: Boolean;
var
  Query: TFDQuery;
begin
  Result := False;
  if not FDConnection.Connected then
    Exit;

  Query := CreateQuery;
  try
    try
      Query.SQL.Text :=
        'SELECT MetaValue FROM SyncMetadata WHERE MetaKey = ''DemoDataVersion''';
      Query.Open;
      Result := (not Query.IsEmpty) and (Trim(Query.Fields[0].AsString) <> '');
      Query.Close;
    except
      Result := False;
    end;
  finally
    Query.Free;
  end;
end;

procedure TDMDatabase.ClearDemoData;
begin
  if not FDConnection.Connected then
    Exit;

  try
    ExecuteSQL(
      'DELETE FROM SaleItems WHERE SaleID IN (' +
      'SELECT SaleID FROM Sales WHERE SaleNumber LIKE ''SALE202505%'' ' +
      'OR SaleNumber LIKE ''SALE202506%'')');
    ExecuteSQL(
      'DELETE FROM Sales WHERE SaleNumber LIKE ''SALE202505%'' ' +
      'OR SaleNumber LIKE ''SALE202506%''');
    ExecuteSQL('DELETE FROM Products WHERE ProductCode LIKE ''DEMO%''');
    ExecuteSQL('DELETE FROM Users WHERE UserID > 1');
    ExecuteSQL('DELETE FROM Categories WHERE CategoryID > 1');
    ExecuteSQL('DELETE FROM Branches WHERE BranchID > 1');
    ExecuteSQL('DELETE FROM SyncMetadata WHERE MetaKey = ''DemoDataVersion''');
  except
  end;
end;

function TDMDatabase.LoadDemoData(const AReload: Boolean): Boolean;
begin
  Result := False;
  if not FDConnection.Connected then
    Exit;
  if FDatabaseType <> dtSQLite then
    Exit;

  if IsDemoDataLoaded and not AReload then
  begin
    Result := True;
    Exit;
  end;

  if AReload then
    ClearDemoData;

  Result := RunSQLScriptFromFile('demo_data_sqlite.sql');
end;

end.
