unit TestAuthService;

interface

uses
  DUnitX.TestFramework, AuthService, UserEntity, DatabaseModule;

type
  [TestFixture]
  TTestAuthService = class
  private
    FAuthService: TAuthService;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestLoginWithValidCredentials;
    [Test]
    procedure TestLoginWithInvalidCredentials;
    [Test]
    procedure TestLoginWithEmptyUsername;
    [Test]
    procedure TestLoginWithEmptyPassword;
    [Test]
    procedure TestLogout;
    [Test]
    procedure TestValidateSession;
    [Test]
    procedure TestChangePassword;
    [Test]
    procedure TestCreateUser;
    [Test]
    procedure TestUpdateUser;
    [Test]
    procedure TestDeleteUser;
    [Test]
    procedure TestGetUserByID;
    [Test]
    procedure TestGetUserByUsername;
    [Test]
    procedure TestGetAllUsers;
    [Test]
    procedure TestResetPassword;
  end;

implementation

uses
  System.SysUtils, Constants;

procedure TTestAuthService.Setup;
begin
  // Initialize database connection
  if not DMDatabase.IsConnected then
    DMDatabase.Connect;

  FAuthService := TAuthService.Create;
end;

procedure TTestAuthService.TearDown;
begin
  FAuthService.Free;
end;

procedure TTestAuthService.TestLoginWithValidCredentials;
var
  LoginResult: Boolean;
begin
  // Test login with default admin credentials
  LoginResult := FAuthService.Login('admin', 'Admin@123');
  Assert.IsTrue(LoginResult, 'Login should succeed with valid credentials');
  Assert.IsTrue(FAuthService.IsAuthenticated, 'IsAuthenticated should be True');
  Assert.IsNotNull(FAuthService.CurrentUser, 'CurrentUser should not be nil');
  Assert.AreEqual('admin', FAuthService.CurrentUser.Username, 'Username should match');
  Assert.AreEqual(ROLE_ADMIN, FAuthService.CurrentUser.RoleID, 'Role should be Admin');
end;

procedure TTestAuthService.TestLoginWithInvalidCredentials;
var
  LoginResult: Boolean;
begin
  LoginResult := FAuthService.Login('admin', 'WrongPassword');
  Assert.IsFalse(LoginResult, 'Login should fail with invalid credentials');
  Assert.IsFalse(FAuthService.IsAuthenticated, 'IsAuthenticated should be False');
end;

procedure TTestAuthService.TestLoginWithEmptyUsername;
var
  LoginResult: Boolean;
begin
  LoginResult := FAuthService.Login('', 'password');
  Assert.IsFalse(LoginResult, 'Login should fail with empty username');
end;

procedure TTestAuthService.TestLoginWithEmptyPassword;
var
  LoginResult: Boolean;
begin
  LoginResult := FAuthService.Login('admin', '');
  Assert.IsFalse(LoginResult, 'Login should fail with empty password');
end;

procedure TTestAuthService.TestLogout;
begin
  // Login first
  FAuthService.Login('admin', 'Admin@123');
  Assert.IsTrue(FAuthService.IsAuthenticated, 'Should be authenticated');

  // Logout
  FAuthService.Logout;
  Assert.IsFalse(FAuthService.IsAuthenticated, 'Should not be authenticated after logout');
  Assert.AreEqual(0, FAuthService.CurrentUser.UserID, 'UserID should be 0 after logout');
end;

procedure TTestAuthService.TestValidateSession;
begin
  // Initially not authenticated
  Assert.IsFalse(FAuthService.ValidateSession, 'Session should be invalid before login');

  // Login
  FAuthService.Login('admin', 'Admin@123');
  Assert.IsTrue(FAuthService.ValidateSession, 'Session should be valid after login');

  // Logout
  FAuthService.Logout;
  Assert.IsFalse(FAuthService.ValidateSession, 'Session should be invalid after logout');
end;

procedure TTestAuthService.TestChangePassword;
var
  ChangeResult: Boolean;
begin
  // Login first
  FAuthService.Login('admin', 'Admin@123');

  // Change password
  ChangeResult := FAuthService.ChangePassword('Admin@123', 'NewPassword123');
  Assert.IsTrue(ChangeResult, 'Password change should succeed');

  // Logout and login with new password
  FAuthService.Logout;
  Assert.IsTrue(FAuthService.Login('admin', 'NewPassword123'), 'Should login with new password');

  // Restore original password
  FAuthService.ChangePassword('NewPassword123', 'Admin@123');
end;

procedure TTestAuthService.TestCreateUser;
var
  NewUser: TUser;
  CreateResult: Boolean;
begin
  // Login as admin
  FAuthService.Login('admin', 'Admin@123');

  // Create new user
  NewUser := TUser.Create;
  try
    NewUser.Username := 'testuser' + FormatDateTime('yyyymmddhhnnss', Now);
    NewUser.FullName := 'Test User';
    NewUser.Email := 'test@example.com';
    NewUser.Phone := '+1234567890';
    NewUser.RoleID := ROLE_EMPLOYEE;
    NewUser.BranchID := 1;

    CreateResult := FAuthService.CreateUser(NewUser, 'TestPass123');
    Assert.IsTrue(CreateResult, 'User creation should succeed');
  finally
    NewUser.Free;
  end;
end;

procedure TTestAuthService.TestUpdateUser;
var
  User: TUser;
  UpdateResult: Boolean;
begin
  // Login as admin
  FAuthService.Login('admin', 'Admin@123');

  // Get existing user
  User := FAuthService.GetUserByUsername('admin');
  try
    if Assigned(User) then
    begin
      User.Phone := '+9876543210';
      UpdateResult := FAuthService.UpdateUser(User);
      Assert.IsTrue(UpdateResult, 'User update should succeed');
    end;
  finally
    User.Free;
  end;
end;

procedure TTestAuthService.TestDeleteUser;
var
  NewUser: TUser;
  UserID: Integer;
  DeleteResult: Boolean;
begin
  // Login as admin
  FAuthService.Login('admin', 'Admin@123');

  // Create a user to delete
  NewUser := TUser.Create;
  try
    NewUser.Username := 'tempuser' + FormatDateTime('yyyymmddhhnnss', Now);
    NewUser.FullName := 'Temporary User';
    NewUser.RoleID := ROLE_EMPLOYEE;
    NewUser.BranchID := 1;

    if FAuthService.CreateUser(NewUser, 'TempPass123') then
    begin
      // Get the created user
      NewUser.Free;
      NewUser := FAuthService.GetUserByUsername('tempuser' + FormatDateTime('yyyymmddhhnnss', Now));
      if Assigned(NewUser) then
      begin
        UserID := NewUser.UserID;
        DeleteResult := FAuthService.DeleteUser(UserID);
        Assert.IsTrue(DeleteResult, 'User deletion should succeed');
      end;
    end;
  finally
    NewUser.Free;
  end;
end;

procedure TTestAuthService.TestGetUserByID;
var
  User: TUser;
begin
  User := FAuthService.GetUserByID(1); // Admin user
  try
    Assert.IsNotNull(User, 'User should be found');
    Assert.AreEqual(1, User.UserID, 'UserID should be 1');
    Assert.AreEqual('admin', User.Username, 'Username should be admin');
  finally
    User.Free;
  end;
end;

procedure TTestAuthService.TestGetUserByUsername;
var
  User: TUser;
begin
  User := FAuthService.GetUserByUsername('admin');
  try
    Assert.IsNotNull(User, 'User should be found');
    Assert.AreEqual('admin', User.Username, 'Username should match');
    Assert.AreEqual(ROLE_ADMIN, User.RoleID, 'Role should be Admin');
  finally
    User.Free;
  end;
end;

procedure TTestAuthService.TestGetAllUsers;
var
  Users: TArray<TUser>;
  I: Integer;
begin
  Users := FAuthService.GetAllUsers;
  Assert.IsTrue(Length(Users) > 0, 'Should return at least one user');

  // Clean up
  for I := Low(Users) to High(Users) do
    Users[I].Free;
end;

procedure TTestAuthService.TestResetPassword;
var
  ResetResult: Boolean;
begin
  // Login as admin
  FAuthService.Login('admin', 'Admin@123');

  // Reset manager password
  ResetResult := FAuthService.ResetPassword('manager', 'NewManagerPass123');
  Assert.IsTrue(ResetResult, 'Password reset should succeed');

  // Verify new password works
  FAuthService.Logout;
  Assert.IsTrue(FAuthService.Login('manager', 'NewManagerPass123'), 'Should login with new password');

  // Restore original password
  FAuthService.Logout;
  FAuthService.Login('admin', 'Admin@123');
  FAuthService.ResetPassword('manager', 'Manager@123');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAuthService);

end.
