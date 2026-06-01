unit UsersForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, UserEntity;

type
  TfrmUsers = class(TFrame)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    GridUsers: TStringGrid;
    lblTitle: TLabel;
    btnRefresh: TButton;
    procedure btnRefreshClick(Sender: TObject);
  private
    FUsers: TArray<TUser>;
    procedure SetupGrid;
    procedure ClearUsers;
    procedure LoadUsers;
    procedure PopulateGrid;
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
  AuthService, Constants;

{ TfrmUsers }

constructor TfrmUsers.Create(AOwner: TComponent);
begin
  inherited;
  SetupGrid;
end;

destructor TfrmUsers.Destroy;
begin
  ClearUsers;
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
  Col.Header := 'Branch ID';
  Col.Width := 80;

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

procedure TfrmUsers.LoadUsers;
var
  I: Integer;
begin
  ClearUsers;

  if not GAuthService.CurrentUser.CanAccessUserManagement then
  begin
    ShowMessage(MSG_ACCESS_DENIED);
    Exit;
  end;

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
    GridUsers.Cells[5, I] := IntToStr(User.BranchID);
    if User.IsActive then
      GridUsers.Cells[6, I] := 'Yes'
    else
      GridUsers.Cells[6, I] := 'No';
  end;
end;

procedure TfrmUsers.ActivateModule;
begin
  LoadUsers;
end;

procedure TfrmUsers.btnRefreshClick(Sender: TObject);
begin
  LoadUsers;
end;

end.
