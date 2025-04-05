unit SalesForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, FMX.Edit, FMX.ListBox, SaleEntity, ProductEntity;

type
  TfrmSales = class(TForm)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    LayoutBottom: TLayout;
    GridCart: TStringGrid;
    edtProductSearch: TEdit;
    btnAddToCart: TButton;
    btnRemoveItem: TButton;
    edtCustomerName: TEdit;
    edtCustomerPhone: TEdit;
    cmbPaymentMethod: TComboBox;
    lblSubtotal: TLabel;
    lblTax: TLabel;
    lblDiscount: TLabel;
    lblTotal: TLabel;
    btnProcessSale: TButton;
    btnClearSale: TButton;
    lblTitle: TLabel;
    lstProducts: TListBox;
    edtQuantity: TEdit;
    lblSubtotalValue: TLabel;
    lblTaxValue: TLabel;
    lblDiscountValue: TLabel;
    lblTotalValue: TLabel;
    LayoutCustomer: TLayout;
    LayoutTotals: TLayout;
    LayoutButtons: TLayout;
    LayoutProductSearch: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure edtProductSearchChange(Sender: TObject);
    procedure btnAddToCartClick(Sender: TObject);
    procedure btnRemoveItemClick(Sender: TObject);
    procedure btnProcessSaleClick(Sender: TObject);
    procedure btnClearSaleClick(Sender: TObject);
    procedure lstProductsClick(Sender: TObject);
  private
    { Private declarations }
    FCurrentSale: TSale;
    FProducts: TArray<TProduct>;
    procedure InitializeNewSale;
    procedure SetupGrid;
    procedure LoadProducts(const SearchText: string);
    procedure UpdateCartDisplay;
    procedure UpdateTotals;
    procedure ClearProducts;
    function GetSelectedProduct: TProduct;
    function FormatCurrency(const Value: Double): string;
  public
    { Public declarations }
  end;

var
  frmSales: TfrmSales;

implementation

{$R *.fmx}

uses
  ProductService, SalesService, AuthService, FMX.DialogService, Constants;

{ TfrmSales }

procedure TfrmSales.FormCreate(Sender: TObject);
begin
  FCurrentSale := TSale.Create;
  SetupGrid;
  InitializeNewSale;

  edtProductSearch.TextPrompt := 'Search products...';
  edtQuantity.TextPrompt := 'Qty';
  edtQuantity.Text := '1';
  edtCustomerName.TextPrompt := 'Customer Name (Optional)';
  edtCustomerPhone.TextPrompt := 'Phone (Optional)';
end;

procedure TfrmSales.FormShow(Sender: TObject);
begin
  // Load payment methods
  cmbPaymentMethod.Clear;
  cmbPaymentMethod.Items.Add('Cash');
  cmbPaymentMethod.Items.Add('Card');
  cmbPaymentMethod.Items.Add('Mobile');
  cmbPaymentMethod.ItemIndex := 0;

  UpdateTotals;
end;

procedure TfrmSales.FormDestroy(Sender: TObject);
begin
  ClearProducts;
  FCurrentSale.Free;
end;

procedure TfrmSales.SetupGrid;
var
  Col: TStringColumn;
begin
  GridCart.ClearColumns;
  GridCart.RowCount := 0;

  // Product Name
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Product';
  Col.Width := 250;

  // Quantity
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Qty';
  Col.Width := 60;

  // Unit Price
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Price';
  Col.Width := 100;

  // Discount %
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Disc %';
  Col.Width := 70;

  // Tax %
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Tax %';
  Col.Width := 70;

  // Line Total
  Col := TStringColumn.Create(GridCart);
  Col.Parent := GridCart;
  Col.Header := 'Total';
  Col.Width := 120;
end;

procedure TfrmSales.InitializeNewSale;
begin
  FCurrentSale.Clear;
  FCurrentSale.SaleNumber := GSalesService.GenerateSaleNumber;
  FCurrentSale.SaleDate := Now;
  FCurrentSale.EmployeeID := GAuthService.CurrentUser.UserID;
  FCurrentSale.BranchID := GAuthService.CurrentUser.BranchID;

  edtCustomerName.Text := '';
  edtCustomerPhone.Text := '';
  cmbPaymentMethod.ItemIndex := 0;

  UpdateCartDisplay;
  UpdateTotals;
end;

procedure TfrmSales.ClearProducts;
var
  I: Integer;
begin
  for I := 0 to Length(FProducts) - 1 do
    FProducts[I].Free;
  SetLength(FProducts, 0);
end;

procedure TfrmSales.LoadProducts(const SearchText: string);
var
  I: Integer;
begin
  ClearProducts;
  lstProducts.Clear;

  if Trim(SearchText) = '' then
    Exit;

  try
    FProducts := GProductService.SearchProducts(SearchText);

    for I := 0 to Length(FProducts) - 1 do
    begin
      lstProducts.Items.AddObject(
        Format('%s - %s - $%.2f (Stock: %d)',
          [FProducts[I].ProductCode, FProducts[I].ProductName,
           FProducts[I].UnitPrice, FProducts[I].Quantity]),
        TObject(I)
      );
    end;
  except
    on E: Exception do
      ShowMessage('Error loading products: ' + E.Message);
  end;
end;

function TfrmSales.GetSelectedProduct: TProduct;
var
  Index: Integer;
begin
  Result := nil;

  if lstProducts.ItemIndex >= 0 then
  begin
    Index := Integer(lstProducts.Items.Objects[lstProducts.ItemIndex]);
    if (Index >= 0) and (Index < Length(FProducts)) then
      Result := FProducts[Index];
  end;
end;

procedure TfrmSales.edtProductSearchChange(Sender: TObject);
begin
  LoadProducts(edtProductSearch.Text);
end;

procedure TfrmSales.lstProductsClick(Sender: TObject);
begin
  // Product selected in list - focus quantity field
  if lstProducts.ItemIndex >= 0 then
    edtQuantity.SetFocus;
end;

procedure TfrmSales.btnAddToCartClick(Sender: TObject);
var
  Product: TProduct;
  SaleItem: TSaleItem;
  Qty: Integer;
begin
  Product := GetSelectedProduct;

  if Product = nil then
  begin
    ShowMessage('Please select a product');
    Exit;
  end;

  Qty := StrToIntDef(edtQuantity.Text, 1);

  if Qty <= 0 then
  begin
    ShowMessage('Please enter a valid quantity');
    Exit;
  end;

  if not Product.CanSell(Qty) then
  begin
    ShowMessage(Format('Insufficient stock. Available: %d', [Product.Quantity]));
    Exit;
  end;

  // Create sale item
  SaleItem := TSaleItem.Create;
  SaleItem.ProductID := Product.ProductID;
  SaleItem.ProductName := Product.ProductName;
  SaleItem.Quantity := Qty;
  SaleItem.UnitPrice := Product.UnitPrice;
  SaleItem.DiscountPercent := DEFAULT_DISCOUNT_PERCENT;
  SaleItem.TaxPercent := DEFAULT_TAX_PERCENT;
  SaleItem.CalculateLineTotal;

  // Add to sale
  FCurrentSale.AddItem(SaleItem);

  // Update display
  UpdateCartDisplay;
  UpdateTotals;

  // Reset quantity and search
  edtQuantity.Text := '1';
  edtProductSearch.Text := '';
  lstProducts.Clear;
  edtProductSearch.SetFocus;
end;

procedure TfrmSales.UpdateCartDisplay;
var
  I: Integer;
  Item: TSaleItem;
begin
  GridCart.RowCount := FCurrentSale.Items.Count;

  for I := 0 to FCurrentSale.Items.Count - 1 do
  begin
    Item := FCurrentSale.Items[I];

    GridCart.Cells[0, I] := Item.ProductName;
    GridCart.Cells[1, I] := IntToStr(Item.Quantity);
    GridCart.Cells[2, I] := Format('$%.2f', [Item.UnitPrice]);
    GridCart.Cells[3, I] := Format('%.1f%%', [Item.DiscountPercent]);
    GridCart.Cells[4, I] := Format('%.1f%%', [Item.TaxPercent]);
    GridCart.Cells[5, I] := Format('$%.2f', [Item.LineTotal]);
  end;
end;

procedure TfrmSales.UpdateTotals;
begin
  FCurrentSale.CalculateTotals;

  lblSubtotalValue.Text := FormatCurrency(FCurrentSale.SubTotal);
  lblTaxValue.Text := FormatCurrency(FCurrentSale.TaxAmount);
  lblDiscountValue.Text := FormatCurrency(FCurrentSale.DiscountAmount);
  lblTotalValue.Text := FormatCurrency(FCurrentSale.TotalAmount);
end;

function TfrmSales.FormatCurrency(const Value: Double): string;
begin
  Result := Format('$%.2f', [Value]);
end;

procedure TfrmSales.btnRemoveItemClick(Sender: TObject);
var
  SelectedRow: Integer;
begin
  SelectedRow := GridCart.Selected;

  if (SelectedRow >= 0) and (SelectedRow < FCurrentSale.Items.Count) then
  begin
    FCurrentSale.RemoveItem(SelectedRow);
    UpdateCartDisplay;
    UpdateTotals;
  end
  else
  begin
    ShowMessage('Please select an item to remove');
  end;
end;

procedure TfrmSales.btnProcessSaleClick(Sender: TObject);
begin
  // Check if cart is empty
  if FCurrentSale.Items.Count = 0 then
  begin
    ShowMessage('Please add items to the cart');
    Exit;
  end;

  // Check permissions
  if not GAuthService.CurrentUser.CanProcessSale then
  begin
    ShowMessage('You do not have permission to process sales');
    Exit;
  end;

  // Set customer information
  FCurrentSale.CustomerName := Trim(edtCustomerName.Text);
  FCurrentSale.CustomerPhone := Trim(edtCustomerPhone.Text);

  // Set payment method
  if cmbPaymentMethod.ItemIndex >= 0 then
    FCurrentSale.PaymentMethod := cmbPaymentMethod.Items[cmbPaymentMethod.ItemIndex]
  else
    FCurrentSale.PaymentMethod := 'Cash';

  FCurrentSale.PaymentStatus := 'Paid';

  // Process sale
  TDialogService.MessageDialog(
    Format('Process sale for %s?', [FormatCurrency(FCurrentSale.TotalAmount)]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbYes, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        if GSalesService.CreateSale(FCurrentSale) then
        begin
          ShowMessage(Format('Sale completed successfully!%sSale Number: %s',
            [sLineBreak, FCurrentSale.SaleNumber]));
          InitializeNewSale;
        end;
      end;
    end);
end;

procedure TfrmSales.btnClearSaleClick(Sender: TObject);
begin
  if FCurrentSale.Items.Count > 0 then
  begin
    TDialogService.MessageDialog('Clear current sale?',
      TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
      TMsgDlgBtn.mbNo, 0,
      procedure(const AResult: TModalResult)
      begin
        if AResult = mrYes then
          InitializeNewSale;
      end);
  end
  else
    InitializeNewSale;
end;

end.
