unit BranchEntity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TBranch = class
  private
    FBranchID: Integer;
    FBranchCode: string;
    FBranchName: string;
    FAddress: string;
    FCity: string;
    FCountry: string;
    FPhone: string;
    FIsActive: Boolean;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function GetFullAddress: string;

    property BranchID: Integer read FBranchID write FBranchID;
    property BranchCode: string read FBranchCode write FBranchCode;
    property BranchName: string read FBranchName write FBranchName;
    property Address: string read FAddress write FAddress;
    property City: string read FCity write FCity;
    property Country: string read FCountry write FCountry;
    property Phone: string read FPhone write FPhone;
    property IsActive: Boolean read FIsActive write FIsActive;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

  TBranchList = TObjectList<TBranch>;

implementation

{ TBranch }

constructor TBranch.Create;
begin
  inherited Create;
  Clear;
end;

destructor TBranch.Destroy;
begin
  inherited Destroy;
end;

procedure TBranch.Clear;
begin
  FBranchID := 0;
  FBranchCode := '';
  FBranchName := '';
  FAddress := '';
  FCity := '';
  FCountry := '';
  FPhone := '';
  FIsActive := True;
  FCreatedAt := Now;
  FUpdatedAt := Now;
end;

function TBranch.GetFullAddress: string;
begin
  Result := FAddress;
  if FCity <> '' then
    Result := Result + ', ' + FCity;
  if FCountry <> '' then
    Result := Result + ', ' + FCountry;
  Result := Trim(Result);
  if (Result <> '') and (Result[1] = ',') then
    Delete(Result, 1, 2);
end;

end.
