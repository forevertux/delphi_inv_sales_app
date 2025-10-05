unit SyncService;

interface

uses
  System.SysUtils, System.Classes, System.StrUtils, FireDAC.Comp.Client, Data.DB,
  System.DateUtils, System.JSON, System.NetEncoding, System.Net.HttpClient;

type
  TSyncOperation = (soInsert, soUpdate, soDelete);
  TSyncStatus = (ssNone, ssSyncing, ssSuccess, ssFailed);

  TSyncService = class
  private
    FSyncStatus: TSyncStatus;
    FLastSyncTime: TDateTime;
    FDeviceID: string;
    FServerURL: string;
    FLastError: string;

    function GetDeviceID: string;
    function OperationToString(Operation: TSyncOperation): string;
    function StringToOperation(const Str: string): TSyncOperation;
    function StatusToString(Status: TSyncStatus): string;
    function GetTableQuery(const TableName: string): TFDQuery;
    function ApplyServerRecord(const TableName: string; RecordData: TJSONObject): Boolean;
    function DeleteLocalRecord(const TableName: string; RecordID: Integer): Boolean;
    function GetRecordAsJSON(Query: TFDQuery; const TableName: string): TJSONObject;
    function UploadChangesToServer(Changes: TJSONArray): Boolean;
    function DownloadChangesFromServer: TJSONArray;
    procedure EnsureSyncLogTable;
    procedure UpdateSyncMetadata(const Key, Value: string);
    function GetSyncMetadata(const Key, DefaultValue: string): string;
    function BuildInsertSQL(const TableName: string; Data: TJSONObject): string;
    function BuildUpdateSQL(const TableName: string; Data: TJSONObject; RecordID: Integer): string;
  public
    constructor Create;
    destructor Destroy; override;

    // Core sync functions
    function SyncToServer: Boolean;
    function SyncFromServer: Boolean;
    function FullSync: Boolean;

    // Change logging
    function LogChange(const TableName: string; RecordID: Integer; Operation: TSyncOperation): Boolean;
    function GetPendingChanges: TFDQuery;
    function MarkAsSynced(SyncID: Integer): Boolean;
    function ClearSyncLog: Boolean;

    // Sync metadata
    function GetLastSyncTime: TDateTime;
    function SetLastSyncTime(DateTime: TDateTime): Boolean;
    function GetSyncStatus: string;

    // Conflict resolution
    function HandleConflict(LocalRecord, ServerRecord: TJSONObject): Boolean;

    // Configuration
    procedure SetServerURL(const URL: string);

    property DeviceID: string read FDeviceID;
    property LastError: string read FLastError;
    property SyncStatus: TSyncStatus read FSyncStatus;
  end;

var
  GSyncService: TSyncService;

implementation

uses
  DatabaseModule, ValidationUtils, Constants, FMX.Dialogs,
  {$IFDEF ANDROID}
  Androidapi.Helpers, Androidapi.JNI.Provider,
  {$ENDIF}
  {$IFDEF IOS}
  Macapi.Helpers, iOSapi.Foundation,
  {$ENDIF}
  System.IOUtils;

{ TSyncService }

constructor TSyncService.Create;
begin
  inherited Create;
  FSyncStatus := ssNone;
  FLastSyncTime := 0;
  FDeviceID := GetDeviceID;
  FServerURL := '';
  FLastError := '';

  // Ensure SyncLog table exists
  EnsureSyncLogTable;

  // Load last sync time
  FLastSyncTime := StrToDateTimeDef(GetSyncMetadata('LastSyncTime', ''), 0);
end;

destructor TSyncService.Destroy;
begin
  inherited Destroy;
end;

function TSyncService.GetDeviceID: string;
{$IFDEF ANDROID}
var
  DeviceIDJava: JString;
{$ENDIF}
{$IFDEF IOS}
var
  Device: UIDevice;
{$ENDIF}
begin
  // Try to get from metadata first
  Result := GetSyncMetadata('DeviceID', '');

  if Result = '' then
  begin
    {$IFDEF ANDROID}
    try
      DeviceIDJava := TJSettings_Secure.JavaClass.getString(
        TAndroidHelper.Context.getContentResolver,
        TJSettings_Secure.JavaClass.ANDROID_ID);
      Result := JStringToString(DeviceIDJava);
    except
      Result := '';
    end;
    {$ENDIF}

    {$IFDEF IOS}
    try
      Device := TUIDevice.Wrap(TUIDevice.OCClass.currentDevice);
      Result := NSStrToStr(Device.identifierForVendor.UUIDString);
    except
      Result := '';
    end;
    {$ENDIF}

    // Fallback to GUID for desktop or if platform ID fails
    if Result = '' then
      Result := TGuid.NewGuid.ToString;

    // Save device ID
    UpdateSyncMetadata('DeviceID', Result);
  end;
end;

procedure TSyncService.EnsureSyncLogTable;
var
  Query: TFDQuery;
begin
  try
    Query := DMDatabase.qryGeneral;

    // Create SyncLog table if not exists
    Query.Close;
    Query.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS SyncLog (' +
      'SyncID INTEGER PRIMARY KEY AUTOINCREMENT, ' +
      'TableName TEXT NOT NULL, ' +
      'RecordID INTEGER NOT NULL, ' +
      'Operation TEXT NOT NULL, ' +
      'SyncStatus TEXT DEFAULT ''Pending'', ' +
      'ErrorMessage TEXT, ' +
      'DeviceID TEXT, ' +
      'CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP, ' +
      'SyncedAt DATETIME)';
    Query.ExecSQL;

    // Create SyncMetadata table
    Query.Close;
    Query.SQL.Text :=
      'CREATE TABLE IF NOT EXISTS SyncMetadata (' +
      'MetaKey TEXT PRIMARY KEY, ' +
      'MetaValue TEXT, ' +
      'UpdatedAt DATETIME DEFAULT CURRENT_TIMESTAMP)';
    Query.ExecSQL;

    // Create indexes for performance
    Query.Close;
    Query.SQL.Text :=
      'CREATE INDEX IF NOT EXISTS idx_synclog_status ON SyncLog(SyncStatus)';
    Query.ExecSQL;

    Query.Close;
    Query.SQL.Text :=
      'CREATE INDEX IF NOT EXISTS idx_synclog_table ON SyncLog(TableName, RecordID)';
    Query.ExecSQL;

  except
    on E: Exception do
      FLastError := 'Error creating sync tables: ' + E.Message;
  end;
end;

function TSyncService.OperationToString(Operation: TSyncOperation): string;
begin
  case Operation of
    soInsert: Result := OP_INSERT;
    soUpdate: Result := OP_UPDATE;
    soDelete: Result := OP_DELETE;
  else
    Result := OP_UPDATE;
  end;
end;

function TSyncService.StringToOperation(const Str: string): TSyncOperation;
begin
  if SameText(Str, OP_INSERT) then
    Result := soInsert
  else if SameText(Str, OP_DELETE) then
    Result := soDelete
  else
    Result := soUpdate;
end;

function TSyncService.StatusToString(Status: TSyncStatus): string;
begin
  case Status of
    ssNone: Result := 'Idle';
    ssSyncing: Result := 'Syncing';
    ssSuccess: Result := 'Success';
    ssFailed: Result := 'Failed';
  else
    Result := 'Unknown';
  end;
end;

function TSyncService.LogChange(const TableName: string; RecordID: Integer;
  Operation: TSyncOperation): Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := False;

  try
    Query := DMDatabase.qryGeneral;

    // Check if change already logged
    SQL := 'SELECT SyncID FROM SyncLog WHERE TableName = :TableName AND RecordID = :RecordID ' +
           'AND SyncStatus = ''Pending'' AND Operation = :Operation';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('TableName').AsString := TableName;
    Query.ParamByName('RecordID').AsInteger := RecordID;
    Query.ParamByName('Operation').AsString := OperationToString(Operation);
    Query.Open;

    // If already exists, don't log duplicate
    if not Query.IsEmpty then
    begin
      Query.Close;
      Result := True;
      Exit;
    end;
    Query.Close;

    // Insert sync log entry
    SQL := 'INSERT INTO SyncLog (TableName, RecordID, Operation, SyncStatus, DeviceID) ' +
           'VALUES (:TableName, :RecordID, :Operation, :SyncStatus, :DeviceID)';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('TableName').AsString := TableName;
    Query.ParamByName('RecordID').AsInteger := RecordID;
    Query.ParamByName('Operation').AsString := OperationToString(Operation);
    Query.ParamByName('SyncStatus').AsString := SYNC_PENDING;
    Query.ParamByName('DeviceID').AsString := FDeviceID;
    Query.ExecSQL;

    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Error logging change: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.GetPendingChanges: TFDQuery;
var
  Query: TFDQuery;
  SQL: string;
begin
  Query := TFDQuery.Create(nil);
  Query.Connection := DMDatabase.FDConnection;

  try
    SQL := 'SELECT SyncID, TableName, RecordID, Operation, CreatedAt ' +
           'FROM SyncLog ' +
           'WHERE SyncStatus = :SyncStatus ' +
           'ORDER BY CreatedAt ASC';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SyncStatus').AsString := SYNC_PENDING;
    Query.Open;

    Result := Query;
  except
    on E: Exception do
    begin
      FLastError := 'Error getting pending changes: ' + E.Message;
      Query.Free;
      Result := nil;
    end;
  end;
end;

function TSyncService.MarkAsSynced(SyncID: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := False;

  try
    Query := DMDatabase.qryGeneral;
    SQL := 'UPDATE SyncLog SET SyncStatus = :SyncStatus, SyncedAt = CURRENT_TIMESTAMP ' +
           'WHERE SyncID = :SyncID';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SyncStatus').AsString := SYNC_SUCCESS;
    Query.ParamByName('SyncID').AsInteger := SyncID;
    Query.ExecSQL;

    Result := Query.RowsAffected > 0;
  except
    on E: Exception do
    begin
      FLastError := 'Error marking as synced: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.ClearSyncLog: Boolean;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := False;

  try
    Query := DMDatabase.qryGeneral;

    // Only delete successfully synced records older than 7 days
    SQL := 'DELETE FROM SyncLog WHERE SyncStatus = :SyncStatus ' +
           'AND SyncedAt < datetime(''now'', ''-7 days'')';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('SyncStatus').AsString := SYNC_SUCCESS;
    Query.ExecSQL;

    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Error clearing sync log: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.GetLastSyncTime: TDateTime;
begin
  Result := FLastSyncTime;
end;

function TSyncService.SetLastSyncTime(DateTime: TDateTime): Boolean;
begin
  try
    FLastSyncTime := DateTime;
    UpdateSyncMetadata('LastSyncTime', DateTimeToStr(DateTime));
    Result := True;
  except
    on E: Exception do
    begin
      FLastError := 'Error setting last sync time: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.GetSyncStatus: string;
begin
  Result := StatusToString(FSyncStatus);
end;

procedure TSyncService.UpdateSyncMetadata(const Key, Value: string);
var
  Query: TFDQuery;
  SQL: string;
begin
  try
    Query := DMDatabase.qryGeneral;

    // Try to update first
    SQL := 'UPDATE SyncMetadata SET MetaValue = :Value, UpdatedAt = CURRENT_TIMESTAMP ' +
           'WHERE MetaKey = :Key';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Key').AsString := Key;
    Query.ParamByName('Value').AsString := Value;
    Query.ExecSQL;

    // If no rows affected, insert new
    if Query.RowsAffected = 0 then
    begin
      SQL := 'INSERT INTO SyncMetadata (MetaKey, MetaValue) VALUES (:Key, :Value)';
      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('Key').AsString := Key;
      Query.ParamByName('Value').AsString := Value;
      Query.ExecSQL;
    end;
  except
    on E: Exception do
      FLastError := 'Error updating metadata: ' + E.Message;
  end;
end;

function TSyncService.GetSyncMetadata(const Key, DefaultValue: string): string;
var
  Query: TFDQuery;
  SQL: string;
begin
  Result := DefaultValue;

  try
    Query := DMDatabase.qryGeneral;
    SQL := 'SELECT MetaValue FROM SyncMetadata WHERE MetaKey = :Key';

    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('Key').AsString := Key;
    Query.Open;

    if not Query.IsEmpty then
      Result := Query.FieldByName('MetaValue').AsString;

    Query.Close;
  except
    on E: Exception do
      FLastError := 'Error getting metadata: ' + E.Message;
  end;
end;

function TSyncService.GetTableQuery(const TableName: string): TFDQuery;
begin
  // Return appropriate query based on table name
  if SameText(TableName, 'Products') then
    Result := DMDatabase.qryProducts
  else if SameText(TableName, 'Sales') or SameText(TableName, 'SaleItems') then
    Result := DMDatabase.qrySales
  else if SameText(TableName, 'Users') then
    Result := DMDatabase.qryUsers
  else
    Result := DMDatabase.qryGeneral;
end;

function TSyncService.GetRecordAsJSON(Query: TFDQuery; const TableName: string): TJSONObject;
var
  I: Integer;
  Field: TField;
begin
  Result := TJSONObject.Create;

  try
    // Add table name
    Result.AddPair('TableName', TableName);

    // Add all fields
    for I := 0 to Query.FieldCount - 1 do
    begin
      Field := Query.Fields[I];

      if Field.IsNull then
        Result.AddPair(Field.FieldName, TJSONNull.Create)
      else
      begin
        case Field.DataType of
          ftInteger, ftSmallint, ftWord, ftAutoInc, ftLargeint:
            Result.AddPair(Field.FieldName, TJSONNumber.Create(Field.AsInteger));
          ftFloat, ftCurrency, ftBCD, ftFMTBcd:
            Result.AddPair(Field.FieldName, TJSONNumber.Create(Field.AsFloat));
          ftBoolean:
            Result.AddPair(Field.FieldName, TJSONBool.Create(Field.AsBoolean));
          ftDate, ftTime, ftDateTime, ftTimeStamp:
            Result.AddPair(Field.FieldName, DateTimeToStr(Field.AsDateTime));
        else
          Result.AddPair(Field.FieldName, Field.AsString);
        end;
      end;
    end;
  except
    on E: Exception do
    begin
      Result.Free;
      Result := nil;
      FLastError := 'Error converting record to JSON: ' + E.Message;
    end;
  end;
end;

function TSyncService.BuildInsertSQL(const TableName: string; Data: TJSONObject): string;
var
  Fields, Values: TStringList;
  Pair: TJSONPair;
  I: Integer;
begin
  Fields := TStringList.Create;
  Values := TStringList.Create;
  try
    // Build field and value lists
    for I := 0 to Data.Count - 1 do
    begin
      Pair := Data.Pairs[I];

      // Skip metadata fields
      if SameText(Pair.JsonString.Value, 'TableName') then
        Continue;

      // Skip primary key fields (they're auto-increment)
      if EndsText('ID', Pair.JsonString.Value) and (I = 0) then
        Continue;

      Fields.Add(Pair.JsonString.Value);
      Values.Add(':' + Pair.JsonString.Value);
    end;

    Result := Format('INSERT INTO %s (%s) VALUES (%s)',
      [TableName, Fields.CommaText, Values.CommaText]);
  finally
    Fields.Free;
    Values.Free;
  end;
end;

function TSyncService.BuildUpdateSQL(const TableName: string; Data: TJSONObject;
  RecordID: Integer): string;
var
  SetClause: string;
  Pair: TJSONPair;
  I: Integer;
  PKField: string;
begin
  SetClause := '';

  // Determine primary key field name
  if SameText(TableName, 'Products') then
    PKField := 'ProductID'
  else if SameText(TableName, 'Sales') then
    PKField := 'SaleID'
  else if SameText(TableName, 'SaleItems') then
    PKField := 'SaleItemID'
  else if SameText(TableName, 'Users') then
    PKField := 'UserID'
  else
    PKField := 'ID';

  // Build SET clause
  for I := 0 to Data.Count - 1 do
  begin
    Pair := Data.Pairs[I];

    // Skip metadata and primary key fields
    if SameText(Pair.JsonString.Value, 'TableName') or
       SameText(Pair.JsonString.Value, PKField) then
      Continue;

    if SetClause <> '' then
      SetClause := SetClause + ', ';

    SetClause := SetClause + Format('%s = :%s',
      [Pair.JsonString.Value, Pair.JsonString.Value]);
  end;

  Result := Format('UPDATE %s SET %s WHERE %s = %d',
    [TableName, SetClause, PKField, RecordID]);
end;

function TSyncService.SyncToServer: Boolean;
var
  PendingQuery: TFDQuery;
  ChangesArray: TJSONArray;
  ChangeObj: TJSONObject;
  RecordQuery: TFDQuery;
  SQL: string;
  TableName: string;
  RecordID: Integer;
  Operation: string;
  SyncID: Integer;
begin
  Result := False;
  FSyncStatus := ssSyncing;
  FLastError := '';

  try
    // Check if server URL is configured
    if FServerURL = '' then
    begin
      FLastError := 'Server URL not configured';
      FSyncStatus := ssFailed;
      Exit;
    end;

    // Get pending changes
    PendingQuery := GetPendingChanges;
    if PendingQuery = nil then
    begin
      FSyncStatus := ssFailed;
      Exit;
    end;

    try
      if PendingQuery.IsEmpty then
      begin
        // No changes to sync
        Result := True;
        FSyncStatus := ssSuccess;
        Exit;
      end;

      ChangesArray := TJSONArray.Create;
      try
        DMDatabase.BeginTrans;
        try
          // Process each pending change
          PendingQuery.First;
          while not PendingQuery.Eof do
          begin
            SyncID := PendingQuery.FieldByName('SyncID').AsInteger;
            TableName := PendingQuery.FieldByName('TableName').AsString;
            RecordID := PendingQuery.FieldByName('RecordID').AsInteger;
            Operation := PendingQuery.FieldByName('Operation').AsString;

            ChangeObj := TJSONObject.Create;
            ChangeObj.AddPair('SyncID', TJSONNumber.Create(SyncID));
            ChangeObj.AddPair('TableName', TableName);
            ChangeObj.AddPair('RecordID', TJSONNumber.Create(RecordID));
            ChangeObj.AddPair('Operation', Operation);
            ChangeObj.AddPair('DeviceID', FDeviceID);

            // If not DELETE, get record data
            if not SameText(Operation, OP_DELETE) then
            begin
              RecordQuery := GetTableQuery(TableName);
              SQL := Format('SELECT * FROM %s WHERE %sID = :RecordID',
                [TableName, Copy(TableName, 1, Length(TableName) - 1)]);

              RecordQuery.Close;
              RecordQuery.SQL.Text := SQL;
              RecordQuery.ParamByName('RecordID').AsInteger := RecordID;
              RecordQuery.Open;

              if not RecordQuery.IsEmpty then
              begin
                ChangeObj.AddPair('Data', GetRecordAsJSON(RecordQuery, TableName));
              end;

              RecordQuery.Close;
            end;

            ChangesArray.AddElement(ChangeObj);
            PendingQuery.Next;
          end;

          // Upload changes to server
          if ChangesArray.Count > 0 then
          begin
            Result := UploadChangesToServer(ChangesArray);

            if Result then
            begin
              // Mark all as synced
              PendingQuery.First;
              while not PendingQuery.Eof do
              begin
                MarkAsSynced(PendingQuery.FieldByName('SyncID').AsInteger);
                PendingQuery.Next;
              end;

              DMDatabase.CommitTrans;
              SetLastSyncTime(Now);
              FSyncStatus := ssSuccess;
            end
            else
            begin
              DMDatabase.RollbackTrans;
              FSyncStatus := ssFailed;
            end;
          end
          else
          begin
            DMDatabase.CommitTrans;
            Result := True;
            FSyncStatus := ssSuccess;
          end;

        except
          on E: Exception do
          begin
            DMDatabase.RollbackTrans;
            FLastError := 'Error during sync transaction: ' + E.Message;
            FSyncStatus := ssFailed;
            Result := False;
          end;
        end;
      finally
        ChangesArray.Free;
      end;
    finally
      PendingQuery.Free;
    end;

  except
    on E: Exception do
    begin
      FLastError := 'Error syncing to server: ' + E.Message;
      FSyncStatus := ssFailed;
      Result := False;
    end;
  end;
end;

function TSyncService.UploadChangesToServer(Changes: TJSONArray): Boolean;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  RequestBody: TStringStream;
  ResponseJSON: TJSONObject;
begin
  Result := False;

  try
    HttpClient := THTTPClient.Create;
    try
      RequestBody := TStringStream.Create(Changes.ToJSON, TEncoding.UTF8);
      try
        // Set headers
        HttpClient.ContentType := 'application/json';
        HttpClient.Accept := 'application/json';

        // Send POST request
        Response := HttpClient.Post(FServerURL + '/api/sync/upload', RequestBody);

        if Response.StatusCode = 200 then
        begin
          ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
          try
            if ResponseJSON <> nil then
            begin
              Result := ResponseJSON.GetValue<Boolean>('success', False);
              if not Result then
                FLastError := ResponseJSON.GetValue<string>('error', 'Unknown error');
            end;
          finally
            ResponseJSON.Free;
          end;
        end
        else
        begin
          FLastError := Format('Server returned status %d: %s',
            [Response.StatusCode, Response.StatusText]);
        end;

      finally
        RequestBody.Free;
      end;
    finally
      HttpClient.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Network error: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.SyncFromServer: Boolean;
var
  Changes: TJSONArray;
  I: Integer;
  ChangeObj: TJSONObject;
  TableName: string;
  Operation: string;
  RecordID: Integer;
  Data: TJSONObject;
begin
  Result := False;
  FSyncStatus := ssSyncing;
  FLastError := '';

  try
    // Check if server URL is configured
    if FServerURL = '' then
    begin
      FLastError := 'Server URL not configured';
      FSyncStatus := ssFailed;
      Exit;
    end;

    // Download changes from server
    Changes := DownloadChangesFromServer;
    if Changes = nil then
    begin
      FSyncStatus := ssFailed;
      Exit;
    end;

    try
      if Changes.Count = 0 then
      begin
        // No changes from server
        Result := True;
        FSyncStatus := ssSuccess;
        Exit;
      end;

      DMDatabase.BeginTrans;
      try
        // Process each change
        for I := 0 to Changes.Count - 1 do
        begin
          ChangeObj := Changes.Items[I] as TJSONObject;

          TableName := ChangeObj.GetValue<string>('TableName', '');
          Operation := ChangeObj.GetValue<string>('Operation', '');
          RecordID := ChangeObj.GetValue<Integer>('RecordID', 0);

          if SameText(Operation, OP_DELETE) then
          begin
            DeleteLocalRecord(TableName, RecordID);
          end
          else
          begin
            Data := ChangeObj.GetValue('Data') as TJSONObject;
            if Data <> nil then
              ApplyServerRecord(TableName, Data);
          end;
        end;

        DMDatabase.CommitTrans;
        SetLastSyncTime(Now);
        Result := True;
        FSyncStatus := ssSuccess;

      except
        on E: Exception do
        begin
          DMDatabase.RollbackTrans;
          FLastError := 'Error applying server changes: ' + E.Message;
          FSyncStatus := ssFailed;
          Result := False;
        end;
      end;
    finally
      Changes.Free;
    end;

  except
    on E: Exception do
    begin
      FLastError := 'Error syncing from server: ' + E.Message;
      FSyncStatus := ssFailed;
      Result := False;
    end;
  end;
end;

function TSyncService.DownloadChangesFromServer: TJSONArray;
var
  HttpClient: THTTPClient;
  Response: IHTTPResponse;
  URL: string;
  ResponseJSON: TJSONObject;
begin
  Result := nil;

  try
    HttpClient := THTTPClient.Create;
    try
      // Build URL with device ID and last sync time
      URL := Format('%s/api/sync/download?deviceId=%s&lastSync=%s',
        [FServerURL, FDeviceID, FormatDateTime('yyyy-mm-dd hh:nn:ss', FLastSyncTime)]);

      // Set headers
      HttpClient.Accept := 'application/json';

      // Send GET request
      Response := HttpClient.Get(URL);

      if Response.StatusCode = 200 then
      begin
        ResponseJSON := TJSONObject.ParseJSONValue(Response.ContentAsString) as TJSONObject;
        try
          if ResponseJSON <> nil then
          begin
            if ResponseJSON.GetValue<Boolean>('success', False) then
            begin
              Result := ResponseJSON.GetValue('changes') as TJSONArray;
              if Result <> nil then
                Result := Result.Clone as TJSONArray;
            end
            else
              FLastError := ResponseJSON.GetValue<string>('error', 'Unknown error');
          end;
        finally
          ResponseJSON.Free;
        end;
      end
      else
      begin
        FLastError := Format('Server returned status %d: %s',
          [Response.StatusCode, Response.StatusText]);
      end;

    finally
      HttpClient.Free;
    end;
  except
    on E: Exception do
    begin
      FLastError := 'Network error: ' + E.Message;
      Result := nil;
    end;
  end;
end;

function TSyncService.ApplyServerRecord(const TableName: string;
  RecordData: TJSONObject): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  RecordID: Integer;
  PKField: string;
  Pair: TJSONPair;
  I: Integer;
begin
  Result := False;

  try
    Query := GetTableQuery(TableName);

    // Determine primary key field
    if SameText(TableName, 'Products') then
      PKField := 'ProductID'
    else if SameText(TableName, 'Sales') then
      PKField := 'SaleID'
    else if SameText(TableName, 'SaleItems') then
      PKField := 'SaleItemID'
    else if SameText(TableName, 'Users') then
      PKField := 'UserID'
    else
      PKField := 'ID';

    // Get record ID
    RecordID := RecordData.GetValue<Integer>(PKField, 0);
    if RecordID = 0 then
      Exit;

    // Check if record exists locally
    SQL := Format('SELECT %s FROM %s WHERE %s = :RecordID', [PKField, TableName, PKField]);
    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('RecordID').AsInteger := RecordID;
    Query.Open;

    if Query.IsEmpty then
    begin
      // Insert new record
      SQL := BuildInsertSQL(TableName, RecordData);
    end
    else
    begin
      // Update existing record
      SQL := BuildUpdateSQL(TableName, RecordData, RecordID);
    end;
    Query.Close;

    // Execute SQL
    Query.SQL.Text := SQL;

    // Set parameters
    for I := 0 to RecordData.Count - 1 do
    begin
      Pair := RecordData.Pairs[I];

      if SameText(Pair.JsonString.Value, 'TableName') then
        Continue;

      if Query.FindParam(Pair.JsonString.Value) <> nil then
      begin
        if Pair.JsonValue is TJSONNull then
          Query.ParamByName(Pair.JsonString.Value).Clear
        else if Pair.JsonValue is TJSONNumber then
        begin
          if Pos('.', Pair.JsonValue.Value) > 0 then
            Query.ParamByName(Pair.JsonString.Value).AsFloat :=
              StrToFloatDef(Pair.JsonValue.Value, 0)
          else
            Query.ParamByName(Pair.JsonString.Value).AsInteger :=
              StrToIntDef(Pair.JsonValue.Value, 0);
        end
        else if Pair.JsonValue is TJSONBool then
          Query.ParamByName(Pair.JsonString.Value).AsBoolean :=
            (Pair.JsonValue as TJSONBool).AsBoolean
        else
          Query.ParamByName(Pair.JsonString.Value).AsString := Pair.JsonValue.Value;
      end;
    end;

    Query.ExecSQL;
    Result := True;

  except
    on E: Exception do
    begin
      FLastError := 'Error applying server record: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.DeleteLocalRecord(const TableName: string;
  RecordID: Integer): Boolean;
var
  Query: TFDQuery;
  SQL: string;
  PKField: string;
begin
  Result := False;

  try
    Query := GetTableQuery(TableName);

    // Determine primary key field
    if SameText(TableName, 'Products') then
      PKField := 'ProductID'
    else if SameText(TableName, 'Sales') then
      PKField := 'SaleID'
    else if SameText(TableName, 'SaleItems') then
      PKField := 'SaleItemID'
    else if SameText(TableName, 'Users') then
      PKField := 'UserID'
    else
      PKField := 'ID';

    // Soft delete if IsActive field exists, otherwise hard delete
    SQL := Format('SELECT * FROM %s WHERE %s = :RecordID LIMIT 1', [TableName, PKField]);
    Query.Close;
    Query.SQL.Text := SQL;
    Query.ParamByName('RecordID').AsInteger := RecordID;
    Query.Open;

    if not Query.IsEmpty then
    begin
      if Query.FindField('IsActive') <> nil then
      begin
        // Soft delete
        SQL := Format('UPDATE %s SET IsActive = 0 WHERE %s = :RecordID',
          [TableName, PKField]);
      end
      else
      begin
        // Hard delete
        SQL := Format('DELETE FROM %s WHERE %s = :RecordID', [TableName, PKField]);
      end;

      Query.Close;
      Query.SQL.Text := SQL;
      Query.ParamByName('RecordID').AsInteger := RecordID;
      Query.ExecSQL;

      Result := True;
    end;

  except
    on E: Exception do
    begin
      FLastError := 'Error deleting local record: ' + E.Message;
      Result := False;
    end;
  end;
end;

function TSyncService.FullSync: Boolean;
begin
  Result := False;
  FSyncStatus := ssSyncing;
  FLastError := '';

  try
    // First, upload local changes
    if not SyncToServer then
    begin
      FSyncStatus := ssFailed;
      Exit;
    end;

    // Then, download server changes
    if not SyncFromServer then
    begin
      FSyncStatus := ssFailed;
      Exit;
    end;

    // Clean up old sync logs
    ClearSyncLog;

    Result := True;
    FSyncStatus := ssSuccess;
    SetLastSyncTime(Now);

  except
    on E: Exception do
    begin
      FLastError := 'Error during full sync: ' + E.Message;
      FSyncStatus := ssFailed;
      Result := False;
    end;
  end;
end;

function TSyncService.HandleConflict(LocalRecord, ServerRecord: TJSONObject): Boolean;
var
  LocalUpdated, ServerUpdated: TDateTime;
  LocalUpdatedStr, ServerUpdatedStr: string;
begin
  Result := False;

  try
    // Server wins strategy (can be changed based on requirements)
    // Get timestamps if available
    LocalUpdatedStr := LocalRecord.GetValue<string>('UpdatedAt', '');
    ServerUpdatedStr := ServerRecord.GetValue<string>('UpdatedAt', '');

    if (LocalUpdatedStr <> '') and (ServerUpdatedStr <> '') then
    begin
      LocalUpdated := StrToDateTime(LocalUpdatedStr);
      ServerUpdated := StrToDateTime(ServerUpdatedStr);

      // Use the most recent version
      if ServerUpdated >= LocalUpdated then
        Result := True  // Use server version
      else
        Result := False; // Use local version (requires upload)
    end
    else
    begin
      // If no timestamp, server wins by default
      Result := True;
    end;

  except
    on E: Exception do
    begin
      FLastError := 'Error handling conflict: ' + E.Message;
      // Default to server wins on error
      Result := True;
    end;
  end;
end;

procedure TSyncService.SetServerURL(const URL: string);
begin
  FServerURL := URL;
  UpdateSyncMetadata('ServerURL', URL);
end;

initialization
  GSyncService := TSyncService.Create;

finalization
  GSyncService.Free;

end.
