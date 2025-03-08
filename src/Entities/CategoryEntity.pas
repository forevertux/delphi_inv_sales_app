unit CategoryEntity;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections;

type
  TCategory = class
  private
    FCategoryID: Integer;
    FCategoryCode: string;
    FCategoryName: string;
    FDescription: string;
    FIsActive: Boolean;
    FCreatedAt: TDateTime;
    FUpdatedAt: TDateTime;
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    property CategoryID: Integer read FCategoryID write FCategoryID;
    property CategoryCode: string read FCategoryCode write FCategoryCode;
    property CategoryName: string read FCategoryName write FCategoryName;
    property Description: string read FDescription write FDescription;
    property IsActive: Boolean read FIsActive write FIsActive;
    property CreatedAt: TDateTime read FCreatedAt write FCreatedAt;
    property UpdatedAt: TDateTime read FUpdatedAt write FUpdatedAt;
  end;

  TCategoryList = TObjectList<TCategory>;

implementation

{ TCategory }

constructor TCategory.Create;
begin
  inherited Create;
  Clear;
end;

destructor TCategory.Destroy;
begin
  inherited Destroy;
end;

procedure TCategory.Clear;
begin
  FCategoryID := 0;
  FCategoryCode := '';
  FCategoryName := '';
  FDescription := '';
  FIsActive := True;
  FCreatedAt := Now;
  FUpdatedAt := Now;
end;

end.
