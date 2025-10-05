unit Constants;

interface

const
  // User Roles
  ROLE_ADMIN = 1;
  ROLE_MANAGER = 2;
  ROLE_EMPLOYEE = 3;

  // Role Names
  ROLE_NAME_ADMIN = 'Administrator';
  ROLE_NAME_MANAGER = 'Manager';
  ROLE_NAME_EMPLOYEE = 'Employee';

  // Payment Methods
  PAYMENT_CASH = 'Cash';
  PAYMENT_CARD = 'Card';
  PAYMENT_MOBILE = 'Mobile';
  PAYMENT_BANK = 'Bank Transfer';

  // Payment Status
  PAYMENT_PAID = 'Paid';
  PAYMENT_PENDING = 'Pending';
  PAYMENT_PARTIAL = 'Partial';

  // Stock Status
  STOCK_OUTOFSTOCK = 'Out of Stock';
  STOCK_LOW = 'Low Stock';
  STOCK_NORMAL = 'Normal';
  STOCK_OVERSTOCK = 'Overstock';

  // Sync Status
  SYNC_PENDING = 'Pending';
  SYNC_SUCCESS = 'Success';
  SYNC_FAILED = 'Failed';

  // Operations
  OP_INSERT = 'INSERT';
  OP_UPDATE = 'UPDATE';
  OP_DELETE = 'DELETE';

  // Default Values
  DEFAULT_TAX_PERCENT = 0.0;
  DEFAULT_DISCOUNT_PERCENT = 0.0;
  MIN_PASSWORD_LENGTH = 6;

  // Date Formats
  DATE_FORMAT = 'yyyy-mm-dd';
  DATETIME_FORMAT = 'yyyy-mm-dd hh:nn:ss';
  DISPLAY_DATE_FORMAT = 'dd/mm/yyyy';
  DISPLAY_DATETIME_FORMAT = 'dd/mm/yyyy hh:nn';

  // Messages
  MSG_LOGIN_SUCCESS = 'Login successful';
  MSG_LOGIN_FAILED = 'Invalid username or password';
  MSG_ACCESS_DENIED = 'Access denied. Insufficient permissions.';
  MSG_SAVE_SUCCESS = 'Record saved successfully';
  MSG_DELETE_SUCCESS = 'Record deleted successfully';
  MSG_UPDATE_SUCCESS = 'Record updated successfully';
  MSG_OPERATION_FAILED = 'Operation failed. Please try again.';
  MSG_CONFIRM_DELETE = 'Are you sure you want to delete this record?';
  MSG_STOCK_INSUFFICIENT = 'Insufficient stock available';
  MSG_SYNC_SUCCESS = 'Data synchronized successfully';
  MSG_SYNC_FAILED = 'Synchronization failed';
  MSG_OFFLINE_MODE = 'Running in offline mode';
  MSG_ONLINE_MODE = 'Connected to online database';

function GetRoleName(RoleID: Integer): string;
function GetStockStatus(Quantity, MinLevel, MaxLevel: Integer): string;

implementation

function GetRoleName(RoleID: Integer): string;
begin
  case RoleID of
    ROLE_ADMIN: Result := ROLE_NAME_ADMIN;
    ROLE_MANAGER: Result := ROLE_NAME_MANAGER;
    ROLE_EMPLOYEE: Result := ROLE_NAME_EMPLOYEE;
  else
    Result := 'Unknown';
  end;
end;

function GetStockStatus(Quantity, MinLevel, MaxLevel: Integer): string;
begin
  if Quantity <= 0 then
    Result := STOCK_OUTOFSTOCK
  else if Quantity <= MinLevel then
    Result := STOCK_LOW
  else if (MaxLevel > 0) and (Quantity >= MaxLevel) then
    Result := STOCK_OVERSTOCK
  else
    Result := STOCK_NORMAL;
end;

end.
