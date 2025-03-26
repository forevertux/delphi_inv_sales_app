unit LoginForm;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Edit, FMX.Controls.Presentation, FMX.Layouts, FMX.Objects;

type
  TfrmLogin = class(TForm)
    LayoutMain: TLayout;
    LayoutCenter: TLayout;
    RectBackground: TRectangle;
    lblTitle: TLabel;
    edtUsername: TEdit;
    edtPassword: TEdit;
    btnLogin: TButton;
    chkRememberMe: TCheckBox;
    lblError: TLabel;
    LayoutButtons: TLayout;
    StyleBook1: TStyleBook;
    procedure FormCreate(Sender: TObject);
    procedure btnLoginClick(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure edtPasswordKeyDown(Sender: TObject; var Key: Word; var KeyChar: Char;
      Shift: TShiftState);
  private
    { Private declarations }
    procedure ClearErrorMessage;
    procedure ShowErrorMessage(const Msg: string);
    function ValidateInput: Boolean;
    procedure LoadRememberedUser;
    procedure SaveRememberedUser;
  public
    { Public declarations }
  end;

var
  frmLogin: TfrmLogin;

implementation

{$R *.fmx}

uses
  AuthService, MainForm, DatabaseModule, System.IniFiles, System.IOUtils, FMX.DialogService;

{ TfrmLogin }

procedure TfrmLogin.FormCreate(Sender: TObject);
begin
  // Center the form
  {$IFDEF MSWINDOWS}
  Position := TFormPosition.ScreenCenter;
  {$ENDIF}

  // Set initial properties
  lblError.Text := '';
  lblError.Visible := False;
  edtPassword.Password := True;
  edtPassword.KillFocusByReturn := False;

  // Configure edit controls
  edtUsername.TextPrompt := 'Enter username';
  edtPassword.TextPrompt := 'Enter password';

  // Load remembered username if exists
  LoadRememberedUser;
end;

procedure TfrmLogin.FormShow(Sender: TObject);
begin
  ClearErrorMessage;

  if edtUsername.Text = '' then
    edtUsername.SetFocus
  else
    edtPassword.SetFocus;
end;

procedure TfrmLogin.ClearErrorMessage;
begin
  lblError.Text := '';
  lblError.Visible := False;
end;

procedure TfrmLogin.ShowErrorMessage(const Msg: string);
begin
  lblError.Text := Msg;
  lblError.Visible := True;
end;

function TfrmLogin.ValidateInput: Boolean;
begin
  Result := False;
  ClearErrorMessage;

  if Trim(edtUsername.Text) = '' then
  begin
    ShowErrorMessage('Please enter username');
    edtUsername.SetFocus;
    Exit;
  end;

  if Trim(edtPassword.Text) = '' then
  begin
    ShowErrorMessage('Please enter password');
    edtPassword.SetFocus;
    Exit;
  end;

  Result := True;
end;

procedure TfrmLogin.LoadRememberedUser;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  try
    IniPath := TPath.Combine(TPath.GetDocumentsPath, 'SalesInventory.ini');

    if TFile.Exists(IniPath) then
    begin
      IniFile := TIniFile.Create(IniPath);
      try
        if IniFile.ReadBool('Login', 'RememberMe', False) then
        begin
          edtUsername.Text := IniFile.ReadString('Login', 'Username', '');
          chkRememberMe.IsChecked := True;
        end;
      finally
        IniFile.Free;
      end;
    end;
  except
    // Silently fail - not critical
  end;
end;

procedure TfrmLogin.SaveRememberedUser;
var
  IniFile: TIniFile;
  IniPath: string;
begin
  try
    IniPath := TPath.Combine(TPath.GetDocumentsPath, 'SalesInventory.ini');

    IniFile := TIniFile.Create(IniPath);
    try
      if chkRememberMe.IsChecked then
      begin
        IniFile.WriteBool('Login', 'RememberMe', True);
        IniFile.WriteString('Login', 'Username', edtUsername.Text);
      end
      else
      begin
        IniFile.WriteBool('Login', 'RememberMe', False);
        IniFile.WriteString('Login', 'Username', '');
      end;
    finally
      IniFile.Free;
    end;
  except
    // Silently fail - not critical
  end;
end;

procedure TfrmLogin.btnLoginClick(Sender: TObject);
begin
  if not ValidateInput then
    Exit;

  // Disable button to prevent multiple clicks
  btnLogin.Enabled := False;
  try
    ClearErrorMessage;

    // Ensure database is connected
    if not DMDatabase.IsConnected then
    begin
      if not DMDatabase.Connect then
      begin
        ShowErrorMessage('Database connection failed. Please check configuration.');
        Exit;
      end;
    end;

    // Call GAuthService.Login
    if GAuthService.Login(edtUsername.Text, edtPassword.Text) then
    begin
      // Save remembered user preference
      SaveRememberedUser;

      // Login successful - navigate to main form
      if not Assigned(frmMain) then
        Application.CreateForm(TfrmMain, frmMain);

      frmMain.Show;
      Self.Hide;
    end
    else
    begin
      ShowErrorMessage('Invalid username or password');
      edtPassword.Text := '';
      edtPassword.SetFocus;
    end;
  finally
    btnLogin.Enabled := True;
  end;
end;

procedure TfrmLogin.edtPasswordKeyDown(Sender: TObject; var Key: Word;
  var KeyChar: Char; Shift: TShiftState);
begin
  if Key = vkReturn then
  begin
    Key := 0;
    btnLoginClick(nil);
  end;
end;

end.
