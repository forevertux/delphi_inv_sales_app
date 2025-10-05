unit ProductEntity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TProduct = class
  private
    FProductID: Integer;
    FProductCode: string;
    FProductName: string;
    FDescription: string;
    FCategoryID: Integer;
    FCategoryName: string;
    FUnitPrice: Double;
    FCostPrice: Double;
    FQuantity: Integer;
    FMinStockLevel: Integer;
    FMaxStockLevel: Integer;
    FBranchID: Integer;
    FBranchName: string;
    FBarcode: string;
    FSKU: string;
    FIsActive: Boolean;
    FCreatedBy: Integer;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    function GetStockStatus: string;
    function IsLowStock: Boolean;
    function IsOutOfStock: Boolean;
    function IsOverStock: Boolean;
    function GetProfitMargin: Double;
    function CanSell(RequestedQuantity: Integer): Boolean;

    property ProductID: Integer read FProductID write FProductID;
    property ProductCode: string read FProductCode write FProductCode;
    property ProductName: string read FProductName write FProductName;
    property Description: string read FDescription write FDescription;
    property CategoryID: Integer read FCategoryID write FCategoryID;
    property CategoryName: string read FCategoryName write FCategoryName;
    property UnitPrice: Double read FUnitPrice write FUnitPrice;
    property CostPrice: Double read FCostPrice write FCostPrice;
    property Quantity: Integer read FQuantity write FQuantity;
    property MinStockLevel: Integer read FMinStockLevel write FMinStockLevel;
    property MaxStockLevel: Integer read FMaxStockLevel write FMaxStockLevel;
    property BranchID: Integer read FBranchID write FBranchID;
    property BranchName: string read FBranchName write FBranchName;
    property Barcode: string read FBarcode write FBarcode;
    property SKU: string read FSKU write FSKU;
    property IsActive: Boolean read FIsActive write FIsActive;
    property CreatedBy: Integer read FCreatedBy write FCreatedBy;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

  TProductList = TObjectList<TProduct>;

implementation

uses
  Constants;

{ TProduct }

constructor TProduct.Create;
begin
  inherited Create;
  Clear;
end;

destructor TProduct.Destroy;
begin
  inherited Destroy;
end;

procedure TProduct.Clear;
begin
  FProductID := 0;
  FProductCode := '';
  FProductName := '';
  FDescription := '';
  FCategoryID := 0;
  FCategoryName := '';
  FUnitPrice := 0.0;
  FCostPrice := 0.0;
  FQuantity := 0;
  FMinStockLevel := 0;
  FMaxStockLevel := 0;
  FBranchID := 0;
  FBranchName := '';
  FBarcode := '';
  FSKU := '';
  FIsActive := True;
  FCreatedBy := 0;
  FCreatedAt := Now;
  FUpdatedAt := Now;
end;

function TProduct.GetStockStatus: string;
begin
  Result := Constants.GetStockStatus(FQuantity, FMinStockLevel, FMaxStockLevel);
end;

function TProduct.IsLowStock: Boolean;
begin
  Result := (FQuantity > 0) and (FQuantity <= FMinStockLevel);
end;

function TProduct.IsOutOfStock: Boolean;
begin
  Result := FQuantity <= 0;
end;

function TProduct.IsOverStock: Boolean;
begin
  Result := (FMaxStockLevel > 0) and (FQuantity >= FMaxStockLevel);
end;

function TProduct.GetProfitMargin: Double;
begin
  if FCostPrice > 0 then
    Result := ((FUnitPrice - FCostPrice) / FCostPrice) * 100
  else
    Result := 0;
end;

function TProduct.CanSell(RequestedQuantity: Integer): Boolean;
begin
  Result := (RequestedQuantity > 0) and (FQuantity >= RequestedQuantity) and FIsActive;
end;

end.
