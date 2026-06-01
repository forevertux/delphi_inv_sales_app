unit HashUtils;

interface

uses
  System.SysUtils, System.Hash;

const
  PASSWORD_HASH_DELIMITER = '$';

function HashPassword(const Password: string): string;
function VerifyPassword(const Password, Hash: string): Boolean;
function GenerateSalt: string;
function HashWithSalt(const Password, Salt: string): string;
function IsLegacyPasswordHash(const Hash: string): Boolean;

implementation

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

function IsLegacyPasswordHash(const Hash: string): Boolean;
begin
  Result := (Hash <> '') and (Pos(PASSWORD_HASH_DELIMITER, Hash) = 0);
end;

function HashPassword(const Password: string): string;
var
  Salt: string;
begin
  Salt := GenerateSalt;
  Result := Salt + PASSWORD_HASH_DELIMITER + HashWithSalt(Password, Salt);
end;

function VerifyPassword(const Password, Hash: string): Boolean;
var
  DelimiterPos: Integer;
  Salt, StoredHash: string;
begin
  if Hash = '' then
    Exit(False);

  DelimiterPos := Pos(PASSWORD_HASH_DELIMITER, Hash);
  if DelimiterPos > 0 then
  begin
    Salt := Copy(Hash, 1, DelimiterPos - 1);
    StoredHash := Copy(Hash, DelimiterPos + 1, MaxInt);
    Result := SameText(HashWithSalt(Password, Salt), StoredHash);
    Exit;
  end;

  // Legacy unsalted SHA-256 hashes (existing databases)
  Result := SameText(THashSHA2.GetHashString(Password), Hash);
end;

end.
