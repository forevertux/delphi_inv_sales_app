unit MainForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.TabControl,
  FMX.StdCtrls, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects,
  FMX.ListBox;

type
  TfrmMain = class(TForm)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    TabControl1: TTabControl;
    TabDashboard: TTabItem;
    TabInventory: TTabItem;
    TabSales: TTabItem;
    TabReports: TTabItem;
    TabUsers: TTabItem;
    RectTopBar: TRectangle;
    lblUserInfo: TLabel;
    btnLogout: TButton;
    lblSyncStatus: TLabel;
    LayoutDashboard: TLayout;
    RectTotalSales: TRectangle;
    lblTotalSalesTitle: TLabel;
    lblTotalSalesValue: TLabel;
    RectLowStock: TRectangle;
    lblLowStockTitle: TLabel;
    lblLowStockValue: TLabel;
    RectTodaySales: TRectangle;
    lblTodaySalesTitle: TLabel;
    lblTodaySalesValue: TLabel;
    btnRefreshDashboard: TButton;
    btnOpenInventory: TButton;
    btnOpenSales: TButton;
    btnOpenReports: TButton;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnLogoutClick(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure TabControl1Change(Sender: TObject);
    procedure btnRefreshDashboardClick(Sender: TObject);
    procedure btnOpenInventoryClick(Sender: TObject);
    procedure btnOpenSalesClick(Sender: TObject);
    procedure btnOpenReportsClick(Sender: TObject);
  private
    { Private declarations }
    procedure SetupUserInterface;
    procedure LoadDashboardData;
    procedure UpdateSyncStatus;
    procedure SetRoleBasedVisibility;
    function FormatCurrency(const Value: Double): string;
  public
    { Public declarations }
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}

uses
  AuthService, SalesService, ProductService, LoginForm,
  InventoryForm, SalesForm, ReportsForm, FMX.DialogService,
  SaleEntity, ProductEntity;

{ TfrmMain }

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  // Initialize form
  {$IFDEF MSWINDOWS}
  Position := TFormPosition.ScreenCenter;
  {$ENDIF}

  TabControl1.ActiveTab := TabDashboard;
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  SetupUserInterface;
  SetRoleBasedVisibility;
  LoadDashboardData;
  UpdateSyncStatus;
end;

procedure TfrmMain.SetupUserInterface;
begin
  // Display user information
  if Assigned(GAuthService) and GAuthService.IsAuthenticated then
  begin
    lblUserInfo.Text := 'User: ' + GAuthService.CurrentUser.FullName;
  end
  else
  begin
    lblUserInfo.Text := 'Not logged in';
  end;
end;

procedure TfrmMain.SetRoleBasedVisibility;
begin
  // Hide Users tab for non-admin users
  if Assigned(GAuthService) and GAuthService.IsAuthenticated then
  begin
    TabUsers.Visible := GAuthService.CurrentUser.CanAccessUserManagement;
    TabReports.Visible := GAuthService.CurrentUser.CanAccessReports;
  end
  else
  begin
    TabUsers.Visible := False;
    TabReports.Visible := False;
  end;
end;

procedure TfrmMain.LoadDashboardData;
var
  TodaySales: TArray<TSale>;
  LowStockProducts: TArray<TProduct>;
  TotalSalesToday: Double;
  I: Integer;
begin
  try
    // Get today's sales
    TodaySales := GSalesService.GetTodaysSales;
    TotalSalesToday := 0;

    for I := 0 to Length(TodaySales) - 1 do
    begin
      TotalSalesToday := TotalSalesToday + TodaySales[I].TotalAmount;
    end;

    lblTodaySalesValue.Text := FormatCurrency(TotalSalesToday);
    lblTotalSalesValue.Text := IntToStr(Length(TodaySales)) + ' transactions';

    // Get low stock products
    LowStockProducts := GProductService.GetLowStockProducts;
    lblLowStockValue.Text := IntToStr(Length(LowStockProducts)) + ' items';

    // Clean up
    for I := 0 to Length(TodaySales) - 1 do
      TodaySales[I].Free;

    for I := 0 to Length(LowStockProducts) - 1 do
      LowStockProducts[I].Free;

  except
    on E: Exception do
      ShowMessage('Error loading dashboard data: ' + E.Message);
  end;
end;

procedure TfrmMain.UpdateSyncStatus;
begin
  lblSyncStatus.Text := 'Last Sync: ' + FormatDateTime('hh:nn', Now);
end;

function TfrmMain.FormatCurrency(const Value: Double): string;
begin
  Result := Format('$%.2f', [Value]);
end;

procedure TfrmMain.btnRefreshDashboardClick(Sender: TObject);
begin
  LoadDashboardData;
  UpdateSyncStatus;
end;

procedure TfrmMain.btnOpenInventoryClick(Sender: TObject);
begin
  TabControl1.ActiveTab := TabInventory;
end;

procedure TfrmMain.btnOpenSalesClick(Sender: TObject);
begin
  TabControl1.ActiveTab := TabSales;
end;

procedure TfrmMain.btnOpenReportsClick(Sender: TObject);
begin
  TabControl1.ActiveTab := TabReports;
end;

procedure TfrmMain.TabControl1Change(Sender: TObject);
begin
  // Refresh data when switching tabs
  if TabControl1.ActiveTab = TabDashboard then
    LoadDashboardData;
end;

procedure TfrmMain.btnLogoutClick(Sender: TObject);
begin
  TDialogService.MessageDialog('Are you sure you want to logout?',
    TMsgDlgType.mtConfirmation, [TMsgDlgBtn.mbYes, TMsgDlgBtn.mbNo],
    TMsgDlgBtn.mbNo, 0,
    procedure(const AResult: TModalResult)
    begin
      if AResult = mrYes then
      begin
        // Logout
        GAuthService.Logout;

        // Show login form
        if not Assigned(frmLogin) then
          Application.CreateForm(TfrmLogin, frmLogin);

        frmLogin.Show;
        Self.Close;
      end;
    end);
end;

procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := TCloseAction.caFree;
  frmMain := nil;
end;

end.
