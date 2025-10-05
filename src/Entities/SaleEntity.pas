unit SaleEntity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TSaleItem = class
  private
    FSaleItemID: Integer;
    FSaleID: Integer;
    FProductID: Integer;
    FProductName: string;
    FQuantity: Integer;
    FUnitPrice: Double;
    FDiscountPercent: Double;
    FTaxPercent: Double;
    FLineTotal: Double;
    FCreatedAt: TDateTime;
  public
    constructor Create;
    procedure CalculateLineTotal;

    property SaleItemID: Integer read FSaleItemID write FSaleItemID;
    property SaleID: Integer read FSaleID write FSaleID;
    property ProductID: Integer read FProductID write FProductID;
    property ProductName: string read FProductName write FProductName;
    property Quantity: Integer read FQuantity write FQuantity;
    property UnitPrice: Double read FUnitPrice write FUnitPrice;
    property DiscountPercent: Double read FDiscountPercent write FDiscountPercent;
    property TaxPercent: Double read FTaxPercent write FTaxPercent;
    property LineTotal: Double read FLineTotal write FLineTotal;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
  end;

  TSaleItemList = TObjectList<TSaleItem>;

  TSale = class
  private
    FSaleID: Integer;
    FSaleNumber: string;
    FSaleDate: TDateTime;
    FBranchID: Integer;
    FBranchName: string;
    FEmployeeID: Integer;
    FEmployeeName: string;
    FCustomerName: string;
    FCustomerPhone: string;
    FSubTotal: Double;
    FTaxAmount: Double;
    FDiscountAmount: Double;
    FTotalAmount: Double;
    FPaymentMethod: string;
    FPaymentStatus: string;
    FNotes: string;
    FIsSynced: Boolean;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
    FItems: TSaleItemList;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;
    procedure AddItem(Item: TSaleItem);
    procedure RemoveItem(Index: Integer);
    procedure CalculateTotals;
    function GetItemCount: Integer;
    function GetTotalQuantity: Integer;

    property SaleID: Integer read FSaleID write FSaleID;
    property SaleNumber: string read FSaleNumber write FSaleNumber;
    property SaleDate: TDateTime read FSaleDate write FSaleDate;
    property BranchID: Integer read FBranchID write FBranchID;
    property BranchName: string read FBranchName write FBranchName;
    property EmployeeID: Integer read FEmployeeID write FEmployeeID;
    property EmployeeName: string read FEmployeeName write FEmployeeName;
    property CustomerName: string read FCustomerName write FCustomerName;
    property CustomerPhone: string read FCustomerPhone write FCustomerPhone;
    property SubTotal: Double read FSubTotal write FSubTotal;
    property TaxAmount: Double read FTaxAmount write FTaxAmount;
    property DiscountAmount: Double read FDiscountAmount write FDiscountAmount;
    property TotalAmount: Double read FTotalAmount write FTotalAmount;
    property PaymentMethod: string read FPaymentMethod write FPaymentMethod;
    property PaymentStatus: string read FPaymentStatus write FPaymentStatus;
    property Notes: string read FNotes write FNotes;
    property IsSynced: Boolean read FIsSynced write FIsSynced;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
    property Items: TSaleItemList read FItems;
  end;

  TSaleList = TObjectList<TSale>;

implementation

uses
  Constants;

{ TSaleItem }

constructor TSaleItem.Create;
begin
  inherited Create;
  FSaleItemID := 0;
  FSaleID := 0;
  FProductID := 0;
  FProductName := '';
  FQuantity := 0;
  FUnitPrice := 0.0;
  FDiscountPercent := DEFAULT_DISCOUNT_PERCENT;
  FTaxPercent := DEFAULT_TAX_PERCENT;
  FLineTotal := 0.0;
  FCreatedAt := Now;
end;

procedure TSaleItem.CalculateLineTotal;
var
  Subtotal, DiscountAmt, TaxAmt: Double;
begin
  // Calculate subtotal
  Subtotal := FQuantity * FUnitPrice;

  // Calculate discount
  DiscountAmt := Subtotal * (FDiscountPercent / 100);

  // Calculate tax on discounted amount
  TaxAmt := (Subtotal - DiscountAmt) * (FTaxPercent / 100);

  // Calculate line total
  FLineTotal := Subtotal - DiscountAmt + TaxAmt;
end;

{ TSale }

constructor TSale.Create;
begin
  inherited Create;
  FItems := TSaleItemList.Create(True);
  Clear;
end;

destructor TSale.Destroy;
begin
  FItems.Free;
  inherited Destroy;
end;

procedure TSale.Clear;
begin
  FSaleID := 0;
  FSaleNumber := '';
  FSaleDate := Now;
  FBranchID := 0;
  FBranchName := '';
  FEmployeeID := 0;
  FEmployeeName := '';
  FCustomerName := '';
  FCustomerPhone := '';
  FSubTotal := 0.0;
  FTaxAmount := 0.0;
  FDiscountAmount := 0.0;
  FTotalAmount := 0.0;
  FPaymentMethod := PAYMENT_CASH;
  FPaymentStatus := PAYMENT_PAID;
  FNotes := '';
  FIsSynced := False;
  FCreatedAt := Now;
  FUpdatedAt := Now;
  FItems.Clear;
end;

procedure TSale.AddItem(Item: TSaleItem);
begin
  FItems.Add(Item);
  CalculateTotals;
end;

procedure TSale.RemoveItem(Index: Integer);
begin
  if (Index >= 0) and (Index < FItems.Count) then
  begin
    FItems.Delete(Index);
    CalculateTotals;
  end;
end;

procedure TSale.CalculateTotals;
var
  Item: TSaleItem;
  TotalTax, TotalDiscount: Double;
begin
  FSubTotal := 0.0;
  TotalTax := 0.0;
  TotalDiscount := 0.0;

  for Item in FItems do
  begin
    Item.CalculateLineTotal;
    FSubTotal := FSubTotal + (Item.Quantity * Item.UnitPrice);
    TotalDiscount := TotalDiscount + ((Item.Quantity * Item.UnitPrice) * (Item.DiscountPercent / 100));
    TotalTax := TotalTax + (((Item.Quantity * Item.UnitPrice) - ((Item.Quantity * Item.UnitPrice) * (Item.DiscountPercent / 100))) * (Item.TaxPercent / 100));
  end;

  FTaxAmount := TotalTax;
  FDiscountAmount := TotalDiscount;
  FTotalAmount := FSubTotal - FDiscountAmount + FTaxAmount;
end;

function TSale.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

function TSale.GetTotalQuantity: Integer;
var
  Item: TSaleItem;
begin
  Result := 0;
  for Item in FItems do
    Result := Result + Item.Quantity;
end;

end.
