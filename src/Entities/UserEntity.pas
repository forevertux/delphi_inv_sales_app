unit UserEntity;

interface

uses
  System.SysUtils, System.Classes;

type
  TUser = class
  private
    FUserID: Integer;
    FUsername: string;
    FPasswordHash: string;
    FFullName: string;
    FEmail: string;
    FPhone: string;
    FRoleID: Integer;
    FBranchID: Integer;
    FIsActive: Boolean;
    FLastLogin: TDateTime;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function IsAdmin: Boolean;
    function IsManager: Boolean;
    function IsEmployee: Boolean;
    function CanAccessInventory: Boolean;
    function CanAccessSales: Boolean;
    function CanAccessReports: Boolean;
    function CanAccessUserManagement: Boolean;
    function CanEditProduct: Boolean;
    function CanDeleteProduct: Boolean;
    function CanProcessSale: Boolean;

    property UserID: Integer read FUserID write FUserID;
    property Username: string read FUsername write FUsername;
    property PasswordHash: string read FPasswordHash write FPasswordHash;
    property FullName: string read FFullName write FFullName;
    property Email: string read FEmail write FEmail;
    property Phone: string read FPhone write FPhone;
    property RoleID: Integer read FRoleID write FRoleID;
    property BranchID: Integer read FBranchID write FBranchID;
    property IsActive: Boolean read FIsActive write FIsActive;
    property LastLogin: TDateTime read FLastLogin write FLastLogin;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

implementation

uses
  Constants;

{ TUser }

constructor TUser.Create;
begin
  inherited Create;
  Clear;
end;

destructor TUser.Destroy;
begin
  inherited Destroy;
end;

procedure TUser.Clear;
begin
  FUserID := 0;
  FUsername := '';
  FPasswordHash := '';
  FFullName := '';
  FEmail := '';
  FPhone := '';
  FRoleID := 0;
  FBranchID := 0;
  FIsActive := True;
  FLastLogin := 0;
  FCreatedAt := Now;
  FUpdatedAt := Now;
end;

function TUser.IsAdmin: Boolean;
begin
  Result := FRoleID = ROLE_ADMIN;
end;

function TUser.IsManager: Boolean;
begin
  Result := FRoleID = ROLE_MANAGER;
end;

function TUser.IsEmployee: Boolean;
begin
  Result := FRoleID = ROLE_EMPLOYEE;
end;

function TUser.CanAccessInventory: Boolean;
begin
  Result := IsAdmin or IsManager or IsEmployee;
end;

function TUser.CanAccessSales: Boolean;
begin
  Result := IsAdmin or IsManager or IsEmployee;
end;

function TUser.CanAccessReports: Boolean;
begin
  Result := IsAdmin or IsManager;
end;

function TUser.CanAccessUserManagement: Boolean;
begin
  Result := IsAdmin;
end;

function TUser.CanEditProduct: Boolean;
begin
  Result := IsAdmin or IsManager;
end;

function TUser.CanDeleteProduct: Boolean;
begin
  Result := IsAdmin;
end;

function TUser.CanProcessSale: Boolean;
begin
  Result := IsAdmin or IsManager or IsEmployee;
end;

end.
