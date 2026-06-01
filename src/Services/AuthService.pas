unit AuthService;

interface

uses
  System.SysUtils, System.Classes, FireDAC.Comp.Client, Data.DB,
  UserEntity;

type
  TAuthService = class
  private
    FCurrentUser: TUser;
    FIsAuthenticated: Boolean;
    function GetUserFromQuery(Query: TFDQuery): TUser;
    procedure UpgradePasswordHash(UserID: Integer; const PlainPassword: string);
  public
    constructor Create;
    destructor Destroy; override;

    function Login(const Username, Password: string): Boolean;
    procedure Logout;
    function ValidateSession: Boolean;
    function ChangePassword(const OldPassword, NewPassword: string): Boolean;
    function ResetPassword(const Username, NewPassword: string): Boolean;
    function CreateUser(User: TUser; const Password: string): Boolean;
    function UpdateUser(User: TUser): Boolean;
    function DeleteUser(UserID: Integer): Boolean;
    function GetUserByID(UserID: Integer): TUser;
    function GetUserByUsername(const Username: string): TUser;
    function GetAllUsers: TArray<TUser>;
    function UpdateLastLogin(UserID: Integer): Boolean;

    property CurrentUser: TUser read FCurrentUser;
    property IsAuthenticated: Boolean read FIsAuthenticated;
  end;

var
  GAuthService: TAuthService;

implementation

uses
  DatabaseModule, HashUtils, ValidationUtils, Constants, FMX.Dialogs;

{ TAuthService }

constructor TAuthService.Create;
begin
  inherited Create;
  FCurrentUser := TUser.Create;
  FIsAuthenticated := False;
end;

destructor TAuthService.Destroy;
begin
  FCurrentUser.Free;
  inherited Destroy;
end;

function TAuthService.GetUserFromQuery(Query: TFDQuery): TUser;
begin
  Result := TUser.Create;
  Result.UserID := Query.FieldByName('UserID').AsInteger;
  Result.Username := Query.FieldByName('Username').AsString;
  Result.PasswordHash := Query.FieldByName('PasswordHash').AsString;
  Result.FullName := Query.FieldByName('FullName').AsString;
  Result.Email := Query.FieldByName('Email').AsString;
  Result.Phone := Query.FieldByName('Phone').AsString;
  Result.RoleID := Query.FieldByName('RoleID').AsInteger;
  Result.BranchID := Query.FieldByName('BranchID').AsInteger;
  Result.IsActive := Query.FieldByName('IsActive').AsBoolean;

  if not Query.FieldByName('LastLogin').IsNull then
    Result.LastLogin := Query.FieldByName('LastLogin').AsDateTime;

  if not Query.FieldByName('CreatedAt').IsNull then
    Result.CreatedAt := Query.FieldByName('CreatedAt').AsDateTime;

  if not Query.FieldByName('UpdatedAt').IsNull then
    Result.UpdatedAt := Query.FieldByName('UpdatedAt').AsDateTime;
end;

procedure TAuthService.UpgradePasswordHash(UserID: Integer; const PlainPassword: string);
var
  Query: TFDQuery;
  NewHash: string;
begin
  NewHash := HashPassword(PlainPassword);
  Query := DMDatabase.CreateQuery;
  try
    Query.SQL.Text :=
      'UPDATE Users SET PasswordHash = :PasswordHash, UpdatedAt = CURRENT_TIMESTAMP ' +
      'WHERE UserID = :UserID';
    Query.ParamByName('PasswordHash').AsString := NewHash;
    Query.ParamByName('UserID').AsInteger := UserID;
    Query.ExecSQL;
    if FCurrentUser.UserID = UserID then
      FCurrentUser.PasswordHash := NewHash;
  finally
    Query.Free;
  end;
end;

function TAuthService.Login(const Username, Password: string): Boolean;
var
  Query: TFDQuery;
  StoredHash: string;
begin
  Result := False;

  if IsEmptyOrWhiteSpace(Username) or IsEmptyOrWhiteSpace(Password) then
    Exit;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text := 'SELECT * FROM Users WHERE Username = :Username AND IsActive = 1';
      Query.ParamByName('Username').AsString := Username;
      Query.Open;

      if not Query.IsEmpty then
      begin
        StoredHash := Query.FieldByName('PasswordHash').AsString;
        if VerifyPassword(Password, StoredHash) then
        begin
          FCurrentUser.Free;
          FCurrentUser := GetUserFromQuery(Query);
          FIsAuthenticated := True;

          if IsLegacyPasswordHash(StoredHash) then
            UpgradePasswordHash(FCurrentUser.UserID, Password);

          UpdateLastLogin(FCurrentUser.UserID);
          Result := True;
        end;
      end;
    except
      on E: Exception do
      begin
        ShowMessage('Login error: ' + E.Message);
        Result := False;
      end;
    end;
  finally
    Query.Free;
  end;
end;

procedure TAuthService.Logout;
begin
  FCurrentUser.Clear;
  FIsAuthenticated := False;
end;

function TAuthService.ValidateSession: Boolean;
begin
  Result := FIsAuthenticated and (FCurrentUser.UserID > 0);
end;

function TAuthService.ChangePassword(const OldPassword, NewPassword: string): Boolean;
var
  Query: TFDQuery;
  NewPasswordHash: string;
begin
  Result := False;

  if not FIsAuthenticated then
    Exit;

  if not IsValidPassword(NewPassword) then
  begin
    ShowMessage('Password must be at least ' + IntToStr(MIN_PASSWORD_LENGTH) + ' characters');
    Exit;
  end;

  if not VerifyPassword(OldPassword, FCurrentUser.PasswordHash) then
  begin
    ShowMessage('Current password is incorrect');
    Exit;
  end;

  NewPasswordHash := HashPassword(NewPassword);
  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text :=
        'UPDATE Users SET PasswordHash = :PasswordHash, UpdatedAt = CURRENT_TIMESTAMP ' +
        'WHERE UserID = :UserID';
      Query.ParamByName('PasswordHash').AsString := NewPasswordHash;
      Query.ParamByName('UserID').AsInteger := FCurrentUser.UserID;
      Query.ExecSQL;
      FCurrentUser.PasswordHash := NewPasswordHash;
      Result := True;
    except
      on E: Exception do
        ShowMessage('Error changing password: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.ResetPassword(const Username, NewPassword: string): Boolean;
var
  Query: TFDQuery;
  NewPasswordHash: string;
begin
  Result := False;

  if not FCurrentUser.IsAdmin then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  if not IsValidPassword(NewPassword) then
  begin
    ShowMessage('Password must be at least ' + IntToStr(MIN_PASSWORD_LENGTH) + ' characters');
    Exit;
  end;

  NewPasswordHash := HashPassword(NewPassword);
  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text :=
        'UPDATE Users SET PasswordHash = :PasswordHash, UpdatedAt = CURRENT_TIMESTAMP ' +
        'WHERE Username = :Username';
      Query.ParamByName('PasswordHash').AsString := NewPasswordHash;
      Query.ParamByName('Username').AsString := Username;
      Query.ExecSQL;
      Result := Query.RowsAffected > 0;
    except
      on E: Exception do
        ShowMessage('Error resetting password: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.CreateUser(User: TUser; const Password: string): Boolean;
var
  Query: TFDQuery;
  PasswordHash: string;
  ErrorMsg: string;
begin
  Result := False;

  if not FCurrentUser.IsAdmin then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  if not ValidateRequired(User.Username, 'Username', ErrorMsg) then
  begin
    ShowMessage(ErrorMsg);
    Exit;
  end;

  if not ValidateRequired(User.FullName, 'Full Name', ErrorMsg) then
  begin
    ShowMessage(ErrorMsg);
    Exit;
  end;

  if not IsValidPassword(Password) then
  begin
    ShowMessage('Password must be at least ' + IntToStr(MIN_PASSWORD_LENGTH) + ' characters');
    Exit;
  end;

  if (User.Email <> '') and not IsValidEmail(User.Email) then
  begin
    ShowMessage('Invalid email address');
    Exit;
  end;

  PasswordHash := HashPassword(Password);
  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text :=
        'INSERT INTO Users (Username, PasswordHash, FullName, Email, Phone, RoleID, BranchID, IsActive) ' +
        'VALUES (:Username, :PasswordHash, :FullName, :Email, :Phone, :RoleID, :BranchID, :IsActive)';
      Query.ParamByName('Username').AsString := User.Username;
      Query.ParamByName('PasswordHash').AsString := PasswordHash;
      Query.ParamByName('FullName').AsString := User.FullName;
      Query.ParamByName('Email').AsString := User.Email;
      Query.ParamByName('Phone').AsString := User.Phone;
      Query.ParamByName('RoleID').AsInteger := User.RoleID;

      if User.BranchID > 0 then
        Query.ParamByName('BranchID').AsInteger := User.BranchID
      else
        Query.ParamByName('BranchID').Clear;

      Query.ParamByName('IsActive').AsBoolean := User.IsActive;
      Query.ExecSQL;
      Result := True;
    except
      on E: Exception do
        ShowMessage('Error creating user: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.UpdateUser(User: TUser): Boolean;
var
  Query: TFDQuery;
  ErrorMsg: string;
begin
  Result := False;

  if not FCurrentUser.IsAdmin then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  if not ValidateRequired(User.FullName, 'Full Name', ErrorMsg) then
  begin
    ShowMessage(ErrorMsg);
    Exit;
  end;

  if (User.Email <> '') and not IsValidEmail(User.Email) then
  begin
    ShowMessage('Invalid email address');
    Exit;
  end;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text :=
        'UPDATE Users SET FullName = :FullName, Email = :Email, Phone = :Phone, ' +
        'RoleID = :RoleID, BranchID = :BranchID, IsActive = :IsActive, UpdatedAt = CURRENT_TIMESTAMP ' +
        'WHERE UserID = :UserID';
      Query.ParamByName('FullName').AsString := User.FullName;
      Query.ParamByName('Email').AsString := User.Email;
      Query.ParamByName('Phone').AsString := User.Phone;
      Query.ParamByName('RoleID').AsInteger := User.RoleID;

      if User.BranchID > 0 then
        Query.ParamByName('BranchID').AsInteger := User.BranchID
      else
        Query.ParamByName('BranchID').Clear;

      Query.ParamByName('IsActive').AsBoolean := User.IsActive;
      Query.ParamByName('UserID').AsInteger := User.UserID;
      Query.ExecSQL;
      Result := Query.RowsAffected > 0;
    except
      on E: Exception do
        ShowMessage('Error updating user: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.DeleteUser(UserID: Integer): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;

  if not FCurrentUser.IsAdmin then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  if UserID = FCurrentUser.UserID then
  begin
    ShowMessage('Cannot delete your own account');
    Exit;
  end;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text :=
        'UPDATE Users SET IsActive = 0, UpdatedAt = CURRENT_TIMESTAMP WHERE UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.ExecSQL;
      Result := Query.RowsAffected > 0;
    except
      on E: Exception do
        ShowMessage('Error deleting user: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.GetUserByID(UserID: Integer): TUser;
var
  Query: TFDQuery;
begin
  Result := nil;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text := 'SELECT * FROM Users WHERE UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.Open;

      if not Query.IsEmpty then
        Result := GetUserFromQuery(Query);
    except
      on E: Exception do
        ShowMessage('Error getting user: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.GetUserByUsername(const Username: string): TUser;
var
  Query: TFDQuery;
begin
  Result := nil;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text := 'SELECT * FROM Users WHERE Username = :Username';
      Query.ParamByName('Username').AsString := Username;
      Query.Open;

      if not Query.IsEmpty then
        Result := GetUserFromQuery(Query);
    except
      on E: Exception do
        ShowMessage('Error getting user: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.GetAllUsers: TArray<TUser>;
var
  Query: TFDQuery;
  Count: Integer;
begin
  SetLength(Result, 0);
  Count := 0;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text := 'SELECT * FROM Users ORDER BY FullName';
      Query.Open;

      while not Query.Eof do
      begin
        SetLength(Result, Count + 1);
        Result[Count] := GetUserFromQuery(Query);
        Inc(Count);
        Query.Next;
      end;
    except
      on E: Exception do
        ShowMessage('Error getting users: ' + E.Message);
    end;
  finally
    Query.Free;
  end;
end;

function TAuthService.UpdateLastLogin(UserID: Integer): Boolean;
var
  Query: TFDQuery;
begin
  Result := False;

  Query := DMDatabase.CreateQuery;
  try
    try
      Query.SQL.Text := 'UPDATE Users SET LastLogin = CURRENT_TIMESTAMP WHERE UserID = :UserID';
      Query.ParamByName('UserID').AsInteger := UserID;
      Query.ExecSQL;
      Result := True;
    except
    end;
  finally
    Query.Free;
  end;
end;

initialization
  GAuthService := TAuthService.Create;

finalization
  GAuthService.Free;

end.
