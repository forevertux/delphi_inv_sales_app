unit HashUtils;

interface

uses
  System.SysUtils, System.Hash;

function HashPassword(const Password: string): string;
function VerifyPassword(const Password, Hash: string): Boolean;
function GenerateSalt: string;
function HashWithSalt(const Password, Salt: string): string;

implementation

function HashPassword(const Password: string): string;
begin
  // Using SHA256 for password hashing
  // In production, consider using bcrypt or scrypt for better security
  Result := THashSHA2.GetHashString(Password);
end;

function VerifyPassword(const Password, Hash: string): Boolean;
var
  PasswordHash: string;
begin
  PasswordHash := HashPassword(Password);
  Result := SameText(PasswordHash, Hash);
end;

function GenerateSalt: string;
var
  GUID: TGUID;
begin
  CreateGUID(GUID);
  Result := GUIDToString(GUID);
end;

function HashWithSalt(const Password, Salt: string): string;
begin
  Result := THashSHA2.GetHashString(Password + Salt);
end;

end.
