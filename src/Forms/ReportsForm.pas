unit ReportsForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  System.DateUtils,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.Grid.Style, FMX.Grid,
  FMX.ScrollBox, FMX.DateTimeCtrls, FMX.ListBox, Data.DB;

type
  TfrmReports = class(TForm)
    LayoutTop: TLayout;
    LayoutContent: TLayout;
    LayoutButtons: TLayout;
    GridReport: TStringGrid;
    cmbReportType: TComboBox;
    dateStart: TDateEdit;
    dateEnd: TDateEdit;
    cmbBranch: TComboBox;
    btnGenerate: TButton;
    btnExportCSV: TButton;
    btnExportPDF: TButton;
    lblTitle: TLabel;
    lblReportType: TLabel;
    lblDateRange: TLabel;
    lblBranch: TLabel;
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnGenerateClick(Sender: TObject);
    procedure btnExportCSVClick(Sender: TObject);
    procedure btnExportPDFClick(Sender: TObject);
    procedure cmbReportTypeChange(Sender: TObject);
  private
    { Private declarations }
    FCurrentDataSet: TDataSet;
    procedure LoadBranches;
    procedure PopulateGridFromDataSet(DataSet: TDataSet);
    procedure ClearGrid;
    function GetExportFileName(const Extension: string): string;
  public
    { Public declarations }
  end;

var
  frmReports: TfrmReports;

implementation

{$R *.fmx}

uses
  ReportService, AuthService, DatabaseModule, FireDAC.Comp.Client, System.IOUtils,
  FMX.DialogService;

{ TfrmReports }

procedure TfrmReports.FormCreate(Sender: TObject);
begin
  // Initialize date range to current month
  dateStart.Date := StartOfTheMonth(Now);
  dateEnd.Date := Now;

  // Setup report types
  cmbReportType.Clear;
  cmbReportType.Items.Add('Sales Report');
  cmbReportType.Items.Add('Inventory Report');
  cmbReportType.Items.Add('Top Selling Products');
  cmbReportType.Items.Add('Sales by Category');
  cmbReportType.Items.Add('Sales by Employee');
  cmbReportType.Items.Add('Low Stock Report');
  cmbReportType.Items.Add('Out of Stock Report');
  cmbReportType.Items.Add('Profit Analysis');
  cmbReportType.ItemIndex := 0;

  FCurrentDataSet := nil;
end;

procedure TfrmReports.FormShow(Sender: TObject);
begin
  LoadBranches;
end;

procedure TfrmReports.LoadBranches;
var
  Query: TFDQuery;
begin
  try
    cmbBranch.Clear;
    cmbBranch.Items.Add('All Branches');

    Query := DMDatabase.qryGeneral;
    Query.Close;
    Query.SQL.Text := 'SELECT BranchID, BranchName FROM Branches ORDER BY BranchName';
    Query.Open;

    while not Query.Eof do
    begin
      cmbBranch.Items.AddObject(
        Query.FieldByName('BranchName').AsString,
        TObject(Query.FieldByName('BranchID').AsInteger)
      );
      Query.Next;
    end;

    Query.Close;
    cmbBranch.ItemIndex := 0;
  except
    on E: Exception do
      ShowMessage('Error loading branches: ' + E.Message);
  end;
end;

procedure TfrmReports.cmbReportTypeChange(Sender: TObject);
begin
  // Enable/disable date range based on report type
  case cmbReportType.ItemIndex of
    1: // Inventory Report
      begin
        dateStart.Enabled := False;
        dateEnd.Enabled := False;
      end;
    5, 6: // Low Stock, Out of Stock
      begin
        dateStart.Enabled := False;
        dateEnd.Enabled := False;
      end;
  else
    dateStart.Enabled := True;
    dateEnd.Enabled := True;
  end;
end;

procedure TfrmReports.ClearGrid;
begin
  GridReport.ClearColumns;
  GridReport.RowCount := 0;
end;

procedure TfrmReports.PopulateGridFromDataSet(DataSet: TDataSet);
var
  I, Row: Integer;
  Col: TStringColumn;
begin
  if not Assigned(DataSet) or DataSet.IsEmpty then
  begin
    ShowMessage('No data found for the selected criteria');
    ClearGrid;
    Exit;
  end;

  ClearGrid;

  // Create columns based on dataset fields
  for I := 0 to DataSet.FieldCount - 1 do
  begin
    Col := TStringColumn.Create(GridReport);
    Col.Parent := GridReport;
    Col.Header := DataSet.Fields[I].FieldName;
    Col.Width := 120;
  end;

  // Populate rows
  DataSet.First;
  Row := 0;
  GridReport.RowCount := DataSet.RecordCount;

  while not DataSet.Eof do
  begin
    for I := 0 to DataSet.FieldCount - 1 do
    begin
      if DataSet.Fields[I].IsNull then
        GridReport.Cells[I, Row] := ''
      else if DataSet.Fields[I].DataType in [ftFloat, ftCurrency, ftBCD, ftFMTBcd] then
        GridReport.Cells[I, Row] := Format('%.2f', [DataSet.Fields[I].AsFloat])
      else if DataSet.Fields[I].DataType in [ftDate, ftDateTime, ftTime] then
        GridReport.Cells[I, Row] := FormatDateTime('yyyy-mm-dd hh:nn', DataSet.Fields[I].AsDateTime)
      else
        GridReport.Cells[I, Row] := DataSet.Fields[I].AsString;
    end;
    Inc(Row);
    DataSet.Next;
  end;

  DataSet.First;
end;

procedure TfrmReports.btnGenerateClick(Sender: TObject);
var
  StartDate, EndDate: TDateTime;
  BranchID: Integer;
  DataSet: TDataSet;
begin
  // Check permissions
  if not GAuthService.CurrentUser.CanAccessReports then
  begin
    ShowMessage('You do not have permission to access reports');
    Exit;
  end;

  StartDate := dateStart.Date;
  EndDate := dateEnd.Date;

  // Get selected branch
  if (cmbBranch.ItemIndex > 0) and (cmbBranch.ItemIndex < cmbBranch.Count) then
    BranchID := Integer(cmbBranch.Items.Objects[cmbBranch.ItemIndex])
  else
    BranchID := 0;

  try
    DataSet := nil;

    case cmbReportType.ItemIndex of
      0: // Sales Report
        DataSet := GReportService.GetSalesReport(StartDate, EndDate, BranchID);

      1: // Inventory Report
        DataSet := GReportService.GetInventoryReport(BranchID);

      2: // Top Selling Products
        DataSet := GReportService.GetTopSellingProducts(StartDate, EndDate, 20);

      3: // Sales by Category
        DataSet := GReportService.GetSalesByCategory(StartDate, EndDate);

      4: // Sales by Employee
        DataSet := GReportService.GetSalesByEmployee(StartDate, EndDate);

      5: // Low Stock Report
        DataSet := GReportService.GetLowStockReport;

      6: // Out of Stock Report
        DataSet := GReportService.GetOutOfStockReport;

      7: // Profit Analysis
        DataSet := GReportService.GetProfitAnalysis(StartDate, EndDate);
    else
      ShowMessage('Please select a report type');
      Exit;
    end;

    if Assigned(DataSet) then
    begin
      FCurrentDataSet := DataSet;
      PopulateGridFromDataSet(DataSet);
    end;

  except
    on E: Exception do
      ShowMessage('Error generating report: ' + E.Message);
  end;
end;

function TfrmReports.GetExportFileName(const Extension: string): string;
var
  ReportName: string;
  DateStr: string;
begin
  if cmbReportType.ItemIndex >= 0 then
    ReportName := StringReplace(cmbReportType.Items[cmbReportType.ItemIndex], ' ', '_', [rfReplaceAll])
  else
    ReportName := 'Report';

  DateStr := FormatDateTime('yyyymmdd_hhnnss', Now);

  Result := TPath.Combine(
    TPath.GetDocumentsPath,
    Format('%s_%s.%s', [ReportName, DateStr, Extension])
  );
end;

procedure TfrmReports.btnExportCSVClick(Sender: TObject);
var
  FilePath: string;
begin
  if not Assigned(FCurrentDataSet) or FCurrentDataSet.IsEmpty then
  begin
    ShowMessage('Please generate a report first');
    Exit;
  end;

  FilePath := GetExportFileName('csv');

  if GReportService.ExportToCSV(FCurrentDataSet, FilePath) then
  begin
    TDialogService.MessageDialog(
      Format('Report exported successfully to:%s%s', [sLineBreak, FilePath]),
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
      nil
    );
  end;
end;

procedure TfrmReports.btnExportPDFClick(Sender: TObject);
var
  FilePath: string;
begin
  if not Assigned(FCurrentDataSet) or FCurrentDataSet.IsEmpty then
  begin
    ShowMessage('Please generate a report first');
    Exit;
  end;

  FilePath := GetExportFileName('pdf');

  if GReportService.ExportToPDF(FCurrentDataSet, FilePath) then
  begin
    TDialogService.MessageDialog(
      Format('Report exported successfully to:%s%s', [sLineBreak, FilePath]),
      TMsgDlgType.mtInformation, [TMsgDlgBtn.mbOK], TMsgDlgBtn.mbOK, 0,
      nil
    );
  end;
end;

end.
