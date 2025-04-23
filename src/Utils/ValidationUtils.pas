unit ValidationUtils;

interface

uses
  System.SysUtils, System.RegularExpressions;

function IsValidEmail(const Email: string): Boolean;
function IsValidPhone(const Phone: string): Boolean;
function IsValidPassword(const Password: string): Boolean;
function IsPositiveNumber(const Value: Double): Boolean;
function IsValidQuantity(const Quantity: Integer): Boolean;
function IsValidPrice(const Price: Double): Boolean;
function IsEmptyOrWhiteSpace(const Value: string): Boolean;
function ValidateRequired(const Value: string; const FieldName: string; out ErrorMsg: string): Boolean;
function ValidateNumericRange(const Value: Double; const Min, Max: Double; const FieldName: string; out ErrorMsg: string): Boolean;
function ValidateLength(const Value: string; const MinLen, MaxLen: Integer; const FieldName: string; out ErrorMsg: string): Boolean;

implementation

uses
  Constants;

function IsValidEmail(const Email: string): Boolean;
const
  EmailPattern = '^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
begin
  Result := TRegEx.IsMatch(Email, EmailPattern);
end;

function IsValidPhone(const Phone: string): Boolean;
const
  PhonePattern = '^\+?[0-9\s\-\(\)]{7,20}$';
begin
  Result := TRegEx.IsMatch(Phone, PhonePattern);
end;

function IsValidPassword(const Password: string): Boolean;
begin
  // Password must be at least MIN_PASSWORD_LENGTH characters
  Result := Length(Password) >= MIN_PASSWORD_LENGTH;
end;

function IsPositiveNumber(const Value: Double): Boolean;
begin
  Result := Value >= 0;
end;

function IsValidQuantity(const Quantity: Integer): Boolean;
begin
  Result := Quantity >= 0;
end;

function IsValidPrice(const Price: Double): Boolean;
begin
  Result := Price >= 0;
end;

function IsEmptyOrWhiteSpace(const Value: string): Boolean;
begin
  Result := Trim(Value) = '';
end;

function ValidateRequired(const Value: string; const FieldName: string; out ErrorMsg: string): Boolean;
begin
  Result := not IsEmptyOrWhiteSpace(Value);
  if not Result then
    ErrorMsg := FieldName + ' is required';
end;

function ValidateNumericRange(const Value: Double; const Min, Max: Double; const FieldName: string; out ErrorMsg: string): Boolean;
begin
  Result := (Value >= Min) and (Value <= Max);
  if not Result then
    ErrorMsg := Format('%s must be between %.2f and %.2f', [FieldName, Min, Max]);
end;

function ValidateLength(const Value: string; const MinLen, MaxLen: Integer; const FieldName: string; out ErrorMsg: string): Boolean;
var
  Len: Integer;
begin
  Len := Length(Value);
  Result := (Len >= MinLen) and (Len <= MaxLen);
  if not Result then
    ErrorMsg := Format('%s must be between %d and %d characters', [FieldName, MinLen, MaxLen]);
end;

end.
