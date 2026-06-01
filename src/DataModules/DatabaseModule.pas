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

// NOTE: Full file pushed - truncated in this call for test
