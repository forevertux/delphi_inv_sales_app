unit InventoryForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, FMX.Edit, FMX.ListBox, ProductEntity;

type
  TfrmInventory = class(TForm)
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
    procedure GridProductsDblClick(Sender: TObject);
    procedure cmbCategoryChange(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    FProducts: TArray<TProduct>;
    procedure LoadProducts;
    procedure LoadCategories;
    procedure SetupGrid;
    procedure PopulateGrid;
    procedure ClearProducts;
    function GetSelectedProduct: TProduct;
    procedure EditProduct(Product: TProduct);
  public
    { Public declarations }
  end;

var
  frmInventory: TfrmInventory;

implementation

{$R *.fmx}

uses
  ProductService, AuthService, FMX.DialogService, DatabaseModule, FireDAC.Comp.Client;

{ TfrmInventory }

procedure TfrmInventory.FormCreate(Sender: TObject);
begin
  SetupGrid;
  edtSearch.TextPrompt := 'Search products...';
end;

procedure TfrmInventory.FormShow(Sender: TObject);
begin
  LoadCategories;
  LoadProducts;
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

procedure TfrmInventory.GridProductsDblClick(Sender: TObject);
begin
  btnEditClick(nil);
end;

procedure TfrmInventory.EditProduct(Product: TProduct);
var
  InputCode, InputName, InputDesc, InputBarcode: string;
  InputPrice, InputCost: string;
  InputQty, InputMinStock, InputMaxStock: string;
  Success: Boolean;
begin
  // Simple input dialogs for editing
  // In a real application, you would create a proper dialog form

  TDialogService.InputQuery('Product Code', ['Code:'],
    [Product.ProductCode],
    procedure(const AResult: TModalResult; const AValues: array of string)
    begin
      if AResult = mrOk then
      begin
        InputCode := AValues[0];

        TDialogService.InputQuery('Product Details', ['Name:', 'Description:', 'Barcode:'],
          [Product.ProductName, Product.Description, Product.Barcode],
          procedure(const AResult2: TModalResult; const AValues2: array of string)
          begin
            if AResult2 = mrOk then
            begin
              InputName := AValues2[0];
              InputDesc := AValues2[1];
              InputBarcode := AValues2[2];

              TDialogService.InputQuery('Pricing', ['Unit Price:', 'Cost Price:'],
                [Format('%.2f', [Product.UnitPrice]), Format('%.2f', [Product.CostPrice])],
                procedure(const AResult3: TModalResult; const AValues3: array of string)
                begin
                  if AResult3 = mrOk then
                  begin
                    InputPrice := AValues3[0];
                    InputCost := AValues3[1];

                    TDialogService.InputQuery('Stock Levels', ['Quantity:', 'Min Stock:', 'Max Stock:'],
                      [IntToStr(Product.Quantity), IntToStr(Product.MinStockLevel), IntToStr(Product.MaxStockLevel)],
                      procedure(const AResult4: TModalResult; const AValues4: array of string)
                      begin
                        if AResult4 = mrOk then
                        begin
                          InputQty := AValues4[0];
                          InputMinStock := AValues4[1];
                          InputMaxStock := AValues4[2];

                          // Update product
                          Product.ProductCode := InputCode;
                          Product.ProductName := InputName;
                          Product.Description := InputDesc;
                          Product.Barcode := InputBarcode;
                          Product.UnitPrice := StrToFloatDef(InputPrice, 0);
                          Product.CostPrice := StrToFloatDef(InputCost, 0);
                          Product.Quantity := StrToIntDef(InputQty, 0);
                          Product.MinStockLevel := StrToIntDef(InputMinStock, 0);
                          Product.MaxStockLevel := StrToIntDef(InputMaxStock, 0);

                          // For new products, set a default category
                          if Product.CategoryID = 0 then
                            Product.CategoryID := 1; // Default category

                          // Save product
                          if Product.ProductID = 0 then
                            Success := GProductService.CreateProduct(Product)
                          else
                            Success := GProductService.UpdateProduct(Product);

                          if Success then
                            LoadProducts;
                        end;
                      end);
                  end;
                end);
            end;
          end);
      end;
    end);
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

  TDialogService.MessageDialog(
    Format('Are you sure you want to delete "%s"?', [Product.ProductName]),
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        if GProductService.DeleteProduct(Product.ProductID) then
          LoadProducts;
      end;
    end);
end;

end.
