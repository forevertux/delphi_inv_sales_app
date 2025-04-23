program InventorySales;

{
  Inventory & Sales Management System
  Cross-platform application for inventory and sales management
  Author: forever_tux
  Version: 1.0.0
}

uses
  System.StartUpCopy,
  FMX.Forms,
  DatabaseModule in 'src\DataModules\DatabaseModule.pas' {DMDatabase: TDataModule},
  LoginForm in 'src\Forms\LoginForm.pas' {FrmLogin},
  MainForm in 'src\Forms\MainForm.pas' {FrmMain},
  InventoryForm in 'src\Forms\InventoryForm.pas' {FrmInventory},
  SalesForm in 'src\Forms\SalesForm.pas' {FrmSales},
  ReportsForm in 'src\Forms\ReportsForm.pas' {FrmReports},
  UserEntity in 'src\Entities\UserEntity.pas',
  ProductEntity in 'src\Entities\ProductEntity.pas',
  SaleEntity in 'src\Entities\SaleEntity.pas',
  CategoryEntity in 'src\Entities\CategoryEntity.pas',
  BranchEntity in 'src\Entities\BranchEntity.pas',
  AuthService in 'src\Services\AuthService.pas',
  ProductService in 'src\Services\ProductService.pas',
  SalesService in 'src\Services\SalesService.pas',
  ReportService in 'src\Services\ReportService.pas',
  SyncService in 'src\Services\SyncService.pas',
  HashUtils in 'src\Utils\HashUtils.pas',
  ValidationUtils in 'src\Utils\ValidationUtils.pas',
  DateTimeUtils in 'src\Utils\DateTimeUtils.pas',
  Constants in 'src\Utils\Constants.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TDMDatabase, DMDatabase);
  Application.CreateForm(TFrmLogin, FrmLogin);
  Application.Run;
end.
