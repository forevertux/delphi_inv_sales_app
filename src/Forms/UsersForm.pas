unit UsersForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.Generics.Collections,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, UserEntity;

type
  TfrmUsers = class(TFrame)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    LayoutButtons: TLayout;
    GridUsers: TStringGrid;
    lblTitle: TLabel;
    btnRefresh: TButton;
    btnAdd: TButton;
    btnEdit: TButton;
    btnDeactivate: TButton;
    btnResetPassword: TButton;
    procedure btnRefreshClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeactivateClick(Sender: TObject);
    procedure btnResetPasswordClick(Sender: TObject);
  private
    FUsers: TArray<TUser>;
    FBranchNames: TDictionary<Integer, string>;
    FPendingDeactivateUserID: Integer;
    procedure SetupGrid;
    procedure ClearUsers;
    procedure LoadBranchNames;
    function GetBranchDisplayName(BranchID: Integer): string;
    procedure LoadUsers;
    procedure PopulateGrid;
    function GetSelectedUser: TUser;
    function ParseRoleID(const Value: string): Integer;
    function ParseActive(const Value: string): Boolean;
    procedure EditUser(User: TUser);
    procedure OnDeactivateDialogClose(const AResult: TModalResult);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ActivateModule;
  end;

var
  frmUsers: TfrmUsers;

implementation

{$R *.fmx}

uses
  AuthService, Constants, DatabaseModule, FireDAC.Comp.Client, FMX.DialogService
{$IFDEF MSWINDOWS}
  , Vcl.Dialogs
{$ENDIF}
  ;

{ TfrmUsers }

constructor TfrmUsers.Create(AOwner: TComponent);
begin
  inherited;
  FBranchNames := TDictionary<Integer, string>.Create;
  FPendingDeactivateUserID := 0;
  SetupGrid;
end;

destructor TfrmUsers.Destroy;
begin
  ClearUsers;
  FBranchNames.Free;
  inherited;
end;

procedure TfrmUsers.SetupGrid;
var
  Col: TStringColumn;
begin
  GridUsers.ClearColumns;
  GridUsers.RowCount := 0;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Username';
  Col.Width := 120;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Full Name';
  Col.Width := 180;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Email';
  Col.Width := 200;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Phone';
  Col.Width := 130;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Role';
  Col.Width := 110;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Branch';
  Col.Width := 140;

  Col := TStringColumn.Create(GridUsers);
  Col.Parent := GridUsers;
  Col.Header := 'Active';
  Col.Width := 70;
end;

procedure TfrmUsers.ClearUsers;
var
  I: Integer;
begin
  for I := 0 to Length(FUsers) - 1 do
    FUsers[I].Free;
  SetLength(FUsers, 0);
end;

procedure TfrmUsers.LoadBranchNames;
var
  Query: TFDQuery;
begin
  FBranchNames.Clear;
  Query := DMDatabase.CreateQuery;
  try
    Query.SQL.Text := 'SELECT BranchID, BranchName FROM Branches ORDER BY BranchName';
    Query.Open;
    while not Query.Eof do
    begin
      FBranchNames.AddOrSetValue(
        Query.FieldByName('BranchID').AsInteger,
        Query.FieldByName('BranchName').AsString);
      Query.Next;
    end;
  finally
    Query.Free;
  end;
end;

function TfrmUsers.GetBranchDisplayName(BranchID: Integer): string;
begin
  if BranchID <= 0 then
    Exit('-');
  if FBranchNames.TryGetValue(BranchID, Result) then
    Exit;
  Result := IntToStr(BranchID);
end;

procedure TfrmUsers.LoadUsers;
begin
  ClearUsers;

  if not GAuthService.CurrentUser.CanAccessUserManagement then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  LoadBranchNames;
  FUsers := GAuthService.GetAllUsers;
  PopulateGrid;
end;

procedure TfrmUsers.PopulateGrid;
var
  I: Integer;
  User: TUser;
begin
  GridUsers.RowCount := Length(FUsers);

  for I := 0 to Length(FUsers) - 1 do
  begin
    User := FUsers[I];
    GridUsers.Cells[0, I] := User.Username;
    GridUsers.Cells[1, I] := User.FullName;
    GridUsers.Cells[2, I] := User.Email;
    GridUsers.Cells[3, I] := User.Phone;
    GridUsers.Cells[4, I] := GetRoleName(User.RoleID);
    GridUsers.Cells[5, I] := GetBranchDisplayName(User.BranchID);
    if User.IsActive then
      GridUsers.Cells[6, I] := 'Yes'
    else
      GridUsers.Cells[6, I] := 'No';
  end;
end;

function TfrmUsers.GetSelectedUser: TUser;
var
  SelectedRow: Integer;
begin
  Result := nil;
  SelectedRow := GridUsers.Selected;

  if (SelectedRow >= 0) and (SelectedRow < Length(FUsers)) then
    Result := FUsers[SelectedRow];
end;

function TfrmUsers.ParseRoleID(const Value: string): Integer;
var
  S: string;
begin
  S := Trim(Value);
  Result := StrToIntDef(S, 0);
  if Result in [ROLE_ADMIN, ROLE_MANAGER, ROLE_EMPLOYEE] then
    Exit;

  if SameText(S, 'Admin') or SameText(S, 'Administrator') then
    Result := ROLE_ADMIN
  else if SameText(S, 'Manager') then
    Result := ROLE_MANAGER
  else if SameText(S, 'Employee') then
    Result := ROLE_EMPLOYEE
  else
    Result := 0;
end;

function TfrmUsers.ParseActive(const Value: string): Boolean;
var
  S: string;
begin
  S := Trim(Value);
  if SameText(S, 'N') or SameText(S, 'No') or SameText(S, '0') or SameText(S, 'False') then
    Result := False
  else
    Result := SameText(S, 'Y') or SameText(S, 'Yes') or SameText(S, '1') or
      SameText(S, 'True') or (S = '');
end;

procedure TfrmUsers.EditUser(User: TUser);
var
  SUsername, SPassword, SFullName, SEmail, SPhone, SRole, SBranch, SActive: string;
  Success: Boolean;
  RoleID: Integer;
begin
  if not GAuthService.CurrentUser.CanAccessUserManagement then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

{$IFDEF MSWINDOWS}
  if User.UserID = 0 then
  begin
    SUsername := User.Username;
    if not Vcl.Dialogs.InputQuery('Username', 'Username:', SUsername) then
      Exit;
    User.Username := Trim(SUsername);
    if User.Username = '' then
    begin
      ShowMessage('Username is required');
      Exit;
    end;

    SPassword := '';
    if not Vcl.Dialogs.InputQuery('Password', 'Password (min ' +
      IntToStr(MIN_PASSWORD_LENGTH) + ' chars):', SPassword) then
      Exit;
  end
  else
    SPassword := '';

  SFullName := User.FullName;
  if not Vcl.Dialogs.InputQuery('Full Name', 'Full Name:', SFullName) then
    Exit;
  User.FullName := Trim(SFullName);

  SEmail := User.Email;
  if not Vcl.Dialogs.InputQuery('Email', 'Email (optional):', SEmail) then
    Exit;
  User.Email := Trim(SEmail);

  SPhone := User.Phone;
  if not Vcl.Dialogs.InputQuery('Phone', 'Phone (optional):', SPhone) then
    Exit;
  User.Phone := Trim(SPhone);

  SRole := IntToStr(User.RoleID);
  if User.RoleID = 0 then
    SRole := IntToStr(ROLE_EMPLOYEE);
  if not Vcl.Dialogs.InputQuery('Role',
    'Role (1=Admin, 2=Manager, 3=Employee):', SRole) then
    Exit;
  RoleID := ParseRoleID(SRole);
  if RoleID = 0 then
  begin
    ShowMessage('Invalid role. Use 1, 2, or 3.');
    Exit;
  end;
  User.RoleID := RoleID;

  SBranch := IntToStr(User.BranchID);
  if User.BranchID = 0 then
    SBranch := '0';
  if not Vcl.Dialogs.InputQuery('Branch',
    'Branch ID (0 = none):', SBranch) then
    Exit;
  User.BranchID := StrToIntDef(Trim(SBranch), 0);

  if User.IsActive then
    SActive := 'Y'
  else
    SActive := 'N';
  if not Vcl.Dialogs.InputQuery('Active', 'Active? (Y/N):', SActive) then
    Exit;
  User.IsActive := ParseActive(SActive);

  if User.UserID = 0 then
    Success := GAuthService.CreateUser(User, SPassword)
  else
  begin
    Success := GAuthService.UpdateUser(User);
    if Success then
      ShowMessage(MSG_SAVE_SUCCESS);
  end;

  if Success then
    LoadUsers;
{$ELSE}
  ShowMessage('User management dialogs are available on Windows desktop in this build.');
{$ENDIF}
end;

procedure TfrmUsers.OnDeactivateDialogClose(const AResult: TModalResult);
begin
  if (AResult = mrYes) and (FPendingDeactivateUserID > 0) then
  begin
    if GAuthService.DeleteUser(FPendingDeactivateUserID) then
    begin
      ShowMessage('User deactivated successfully.');
      LoadUsers;
    end;
  end;
  FPendingDeactivateUserID := 0;
end;

procedure TfrmUsers.ActivateModule;
begin
  LoadUsers;
end;

procedure TfrmUsers.btnRefreshClick(Sender: TObject);
begin
  LoadUsers;
end;

procedure TfrmUsers.btnAddClick(Sender: TObject);
var
  NewUser: TUser;
begin
  if not GAuthService.CurrentUser.CanAccessUserManagement then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  NewUser := TUser.Create;
  try
    NewUser.RoleID := ROLE_EMPLOYEE;
    NewUser.IsActive := True;
    EditUser(NewUser);
  finally
    NewUser.Free;
  end;
end;

procedure TfrmUsers.btnEditClick(Sender: TObject);
var
  User: TUser;
  Editable: TUser;
begin
  User := GetSelectedUser;
  if User = nil then
  begin
    ShowMessage('Please select a user to edit');
    Exit;
  end;

  Editable := TUser.Create;
  try
    Editable.UserID := User.UserID;
    Editable.Username := User.Username;
    Editable.FullName := User.FullName;
    Editable.Email := User.Email;
    Editable.Phone := User.Phone;
    Editable.RoleID := User.RoleID;
    Editable.BranchID := User.BranchID;
    Editable.IsActive := User.IsActive;
    EditUser(Editable);
  finally
    Editable.Free;
  end;
end;

procedure TfrmUsers.btnDeactivateClick(Sender: TObject);
var
  User: TUser;
begin
  User := GetSelectedUser;
  if User = nil then
  begin
    ShowMessage('Please select a user to deactivate');
    Exit;
  end;

  if not User.IsActive then
  begin
    ShowMessage('This user is already inactive. Use Edit to reactivate.');
    Exit;
  end;

  if User.UserID = GAuthService.CurrentUser.UserID then
  begin
    ShowMessage('Cannot deactivate your own account');
    Exit;
  end;

  FPendingDeactivateUserID := User.UserID;
  TDialogService.MessageDialog(
    Format('Deactivate user "%s"? They will no longer be able to log in.', [User.Username]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo], TMsgDlgBtn.mbNo, 0,
    OnDeactivateDialogClose);
end;

procedure TfrmUsers.btnResetPasswordClick(Sender: TObject);
var
  User: TUser;
  NewPassword: string;
begin
  if not GAuthService.CurrentUser.IsAdmin then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

  User := GetSelectedUser;
  if User = nil then
  begin
    ShowMessage('Please select a user');
    Exit;
  end;

{$IFDEF MSWINDOWS}
  NewPassword := '';
  if not Vcl.Dialogs.InputQuery('Reset Password',
    Format('New password for %s:', [User.Username]), NewPassword) then
    Exit;

  if GAuthService.ResetPassword(User.Username, NewPassword) then
    ShowMessage('Password reset successfully.');
{$ELSE}
  ShowMessage('Password reset is available on Windows desktop in this build.');
{$ENDIF}
end;

end.
