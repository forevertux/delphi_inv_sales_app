unit InventoryForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, FMX.Edit, FMX.ListBox, ProductEntity;

type
  TfrmInventory = class(TFrame)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    GridProducts: TStringGrid;
    edtSearch: TEdit;
    btnSearch: TButton;
    btnAdd: TButton;
    btnEdit: TButton;
    btnDelete: TButton;
    cmbCategory: TComboBox;
    lblTitle: TLabel;
    LayoutButtons: TLayout;
    LayoutSearch: TLayout;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnAddClick(Sender: TObject);
    procedure btnEditClick(Sender: TObject);
    procedure btnDeleteClick(Sender: TObject);
    procedure cmbCategoryChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FProducts: TArray<TProduct>;
    FPendingDeleteProductID: Integer;
    procedure LoadProducts;
    procedure LoadCategories;
    procedure SetupGrid;
    procedure PopulateGrid;
    procedure ClearProducts;
    function GetSelectedProduct: TProduct;
    procedure EditProduct(Product: TProduct);
    procedure OnDeleteDialogClose(const AResult: TModalResult);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ActivateModule;
  end;

var
  frmInventory: TfrmInventory;

implementation

{$R *.fmx}

uses
  ProductService, AuthService, FMX.DialogService, DatabaseModule, FireDAC.Comp.Client
{$IFDEF MSWINDOWS}
  , Vcl.Dialogs
{$ENDIF}
  ;

{ TfrmInventory }

constructor TfrmInventory.Create(AOwner: TComponent);
begin
  inherited;
  FormCreate(Self);
end;

destructor TfrmInventory.Destroy;
begin
  FormDestroy(Self);
  inherited;
end;

procedure TfrmInventory.FormCreate(Sender: TObject);
begin
  SetupGrid;
  edtSearch.TextPrompt := 'Search products...';
  FPendingDeleteProductID := 0;
end;

procedure TfrmInventory.ActivateModule;
begin
  LoadCategories;
  LoadProducts;
end;

procedure TfrmInventory.FormShow(Sender: TObject);
begin
  ActivateModule;
end;

procedure TfrmInventory.FormDestroy(Sender: TObject);
begin
  ClearProducts;
end;

procedure TfrmInventory.SetupGrid;
var
  Col: TStringColumn;
begin
  GridProducts.ClearColumns;
  GridProducts.RowCount := 0;

  // Product Code
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Code';
  Col.Width := 100;

  // Product Name
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Product Name';
  Col.Width := 200;

  // Category
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Category';
  Col.Width := 120;

  // Quantity
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Quantity';
  Col.Width := 80;

  // Unit Price
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Price';
  Col.Width := 100;

  // Cost Price
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Cost';
  Col.Width := 100;

  // Stock Status
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Status';
  Col.Width := 100;

  // Barcode
  Col := TStringColumn.Create(GridProducts);
  Col.Parent := GridProducts;
  Col.Header := 'Barcode';
  Col.Width := 120;
end;

procedure TfrmInventory.LoadCategories;
var
  Query: TFDQuery;
begin
  try
    cmbCategory.Clear;
    cmbCategory.Items.Add('All Categories');

    Query := DMDatabase.qryGeneral;
    Query.Close;
    Query.SQL.Text := 'SELECT CategoryID, CategoryName FROM Categories ORDER BY CategoryName';
    Query.Open;

    while not Query.Eof do
    begin
      cmbCategory.Items.AddObject(
        Query.FieldByName('CategoryName').AsString,
        TObject(Query.FieldByName('CategoryID').AsInteger)
      );
      Query.Next;
    end;

    Query.Close;
    cmbCategory.ItemIndex := 0;
  except
    on E: Exception do
      ShowMessage('Error loading categories: ' + E.Message);
  end;
end;

procedure TfrmInventory.ClearProducts;
var
  I: Integer;
begin
  for I := 0 to Length(FProducts) - 1 do
    FProducts[I].Free;
  SetLength(FProducts, 0);
end;

procedure TfrmInventory.LoadProducts;
var
  SearchText: string;
  CategoryID: Integer;
begin
  ClearProducts;

  try
    SearchText := Trim(edtSearch.Text);

    // Check if category filter is applied
    if (cmbCategory.ItemIndex > 0) and (cmbCategory.ItemIndex < cmbCategory.Count) then
      CategoryID := Integer(cmbCategory.Items.Objects[cmbCategory.ItemIndex])
    else
      CategoryID := 0;

    // Load products based on filters
    if SearchText <> '' then
      FProducts := GProductService.SearchProducts(SearchText)
    else if CategoryID > 0 then
      FProducts := GProductService.GetProductsByCategory(CategoryID)
    else
      FProducts := GProductService.GetAllProducts;

    PopulateGrid;
  except
    on E: Exception do
      ShowMessage('Error loading products: ' + E.Message);
  end;
end;

procedure TfrmInventory.PopulateGrid;
var
  I: Integer;
  Product: TProduct;
begin
  GridProducts.RowCount := Length(FProducts);

  for I := 0 to Length(FProducts) - 1 do
  begin
    Product := FProducts[I];

    GridProducts.Cells[0, I] := Product.ProductCode;
    GridProducts.Cells[1, I] := Product.ProductName;
    GridProducts.Cells[2, I] := Product.CategoryName;
    GridProducts.Cells[3, I] := IntToStr(Product.Quantity);
    GridProducts.Cells[4, I] := Format('$%.2f', [Product.UnitPrice]);
    GridProducts.Cells[5, I] := Format('$%.2f', [Product.CostPrice]);
    GridProducts.Cells[6, I] := Product.GetStockStatus;
    GridProducts.Cells[7, I] := Product.Barcode;
  end;
end;

function TfrmInventory.GetSelectedProduct: TProduct;
var
  SelectedRow: Integer;
begin
  Result := nil;
  SelectedRow := GridProducts.Selected;

  if (SelectedRow >= 0) and (SelectedRow < Length(FProducts)) then
    Result := FProducts[SelectedRow];
end;

procedure TfrmInventory.btnSearchClick(Sender: TObject);
begin
  LoadProducts;
end;

procedure TfrmInventory.cmbCategoryChange(Sender: TObject);
begin
  LoadProducts;
end;

procedure TfrmInventory.btnAddClick(Sender: TObject);
var
  NewProduct: TProduct;
begin
  // Check permissions
  if not GAuthService.CurrentUser.CanEditProduct then
  begin
    ShowMessage('You do not have permission to add products');
    Exit;
  end;

  NewProduct := TProduct.Create;
  try
    EditProduct(NewProduct);
  finally
    NewProduct.Free;
  end;
end;

procedure TfrmInventory.btnEditClick(Sender: TObject);
var
  Product: TProduct;
begin
  Product := GetSelectedProduct;

  if Product = nil then
  begin
    ShowMessage('Please select a product to edit');
    Exit;
  end;

  // Check permissions
  if not GAuthService.CurrentUser.CanEditProduct then
  begin
    ShowMessage('You do not have permission to edit products');
    Exit;
  end;

  EditProduct(Product);
end;

procedure TfrmInventory.EditProduct(Product: TProduct);
var
  SCode, SName, SDesc, SBarcode, SPrice, SCost, SQty, SMin, SMax: string;
  Success: Boolean;
begin
{$IFDEF MSWINDOWS}
  SCode := Product.ProductCode;
  if not Vcl.Dialogs.InputQuery('Product Code', 'Code:', SCode) then
    Exit;
  Product.ProductCode := SCode;

  SName := Product.ProductName;
  if not Vcl.Dialogs.InputQuery('Product Name', 'Name:', SName) then
    Exit;
  Product.ProductName := SName;

  SDesc := Product.Description;
  if not Vcl.Dialogs.InputQuery('Description', 'Description:', SDesc) then
    Exit;
  Product.Description := SDesc;

  SBarcode := Product.Barcode;
  if not Vcl.Dialogs.InputQuery('Barcode', 'Barcode:', SBarcode) then
    Exit;
  Product.Barcode := SBarcode;

  SPrice := Format('%.2f', [Product.UnitPrice]);
  if not Vcl.Dialogs.InputQuery('Unit Price', 'Unit Price:', SPrice) then
    Exit;
  Product.UnitPrice := StrToFloatDef(SPrice, 0);

  SCost := Format('%.2f', [Product.CostPrice]);
  if not Vcl.Dialogs.InputQuery('Cost Price', 'Cost Price:', SCost) then
    Exit;
  Product.CostPrice := StrToFloatDef(SCost, 0);

  SQty := IntToStr(Product.Quantity);
  if not Vcl.Dialogs.InputQuery('Quantity', 'Quantity:', SQty) then
    Exit;
  Product.Quantity := StrToIntDef(SQty, 0);

  SMin := IntToStr(Product.MinStockLevel);
  if not Vcl.Dialogs.InputQuery('Min Stock', 'Min Stock:', SMin) then
    Exit;
  Product.MinStockLevel := StrToIntDef(SMin, 0);

  SMax := IntToStr(Product.MaxStockLevel);
  if not Vcl.Dialogs.InputQuery('Max Stock', 'Max Stock:', SMax) then
    Exit;
  Product.MaxStockLevel := StrToIntDef(SMax, 0);

  if Product.CategoryID = 0 then
    Product.CategoryID := 1;

  if Product.ProductID = 0 then
    Success := GProductService.CreateProduct(Product)
  else
    Success := GProductService.UpdateProduct(Product);

  if Success then
    LoadProducts;
{$ELSE}
  ShowMessage('Product editing is available on Windows desktop in this build.');
{$ENDIF}
end;

procedure TfrmInventory.OnDeleteDialogClose(const AResult: TModalResult);
begin
  if (AResult = mrYes) and (FPendingDeleteProductID > 0) then
  begin
    if GProductService.DeleteProduct(FPendingDeleteProductID) then
      LoadProducts;
  end;
  FPendingDeleteProductID := 0;
end;

procedure TfrmInventory.btnDeleteClick(Sender: TObject);
var
  Product: TProduct;
begin
  Product := GetSelectedProduct;

  if Product = nil then
  begin
    ShowMessage('Please select a product to delete');
    Exit;
  end;

  // Check permissions
  if not GAuthService.CurrentUser.CanDeleteProduct then
  begin
    ShowMessage('You do not have permission to delete products');
    Exit;
  end;

  FPendingDeleteProductID := Product.ProductID;
  TDialogService.MessageDialog(
    Format('Are you sure you want to delete "%s"?', [Product.ProductName]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0, OnDeleteDialogClose);
end;

end.
