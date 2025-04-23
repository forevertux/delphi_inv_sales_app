unit DateTimeUtils;

interface

uses
  System.SysUtils, System.DateUtils;

function FormatDateTimeForDB(const DateTime: TDateTime): string;
function FormatDateForDB(const Date: TDateTime): string;
function FormatDateTimeForDisplay(const DateTime: TDateTime): string;
function FormatDateForDisplay(const Date: TDateTime): string;
function ParseDBDateTime(const DateTimeStr: string): TDateTime;
function GetCurrentDateTime: TDateTime;
function GetCurrentDate: TDateTime;
function GetStartOfDay(const DateTime: TDateTime): TDateTime;
function GetEndOfDay(const DateTime: TDateTime): TDateTime;
function GetStartOfMonth(const DateTime: TDateTime): TDateTime;
function GetEndOfMonth(const DateTime: TDateTime): TDateTime;
function DaysBetween(const StartDate, EndDate: TDateTime): Integer;
function IsToday(const DateTime: TDateTime): Boolean;
function IsThisMonth(const DateTime: TDateTime): Boolean;

implementation

uses
  Constants;

function FormatDateTimeForDB(const DateTime: TDateTime): string;
begin
  Result := FormatDateTime(DATETIME_FORMAT, DateTime);
end;

function FormatDateForDB(const Date: TDateTime): string;
begin
  Result := FormatDateTime(DATE_FORMAT, Date);
end;

function FormatDateTimeForDisplay(const DateTime: TDateTime): string;
begin
  Result := FormatDateTime(DISPLAY_DATETIME_FORMAT, DateTime);
end;

function FormatDateForDisplay(const Date: TDateTime): string;
begin
  Result := FormatDateTime(DISPLAY_DATE_FORMAT, Date);
end;

function ParseDBDateTime(const DateTimeStr: string): TDateTime;
begin
  try
    Result := StrToDateTime(DateTimeStr);
  except
    Result := 0;
  end;
end;

function GetCurrentDateTime: TDateTime;
begin
  Result := Now;
end;

function GetCurrentDate: TDateTime;
begin
  Result := Date;
end;

function GetStartOfDay(const DateTime: TDateTime): TDateTime;
begin
  Result := StartOfTheDay(DateTime);
end;

function GetEndOfDay(const DateTime: TDateTime): TDateTime;
begin
  Result := EndOfTheDay(DateTime);
end;

function GetStartOfMonth(const DateTime: TDateTime): TDateTime;
begin
  Result := StartOfTheMonth(DateTime);
end;

function GetEndOfMonth(const DateTime: TDateTime): TDateTime;
begin
  Result := EndOfTheMonth(DateTime);
end;

function DaysBetween(const StartDate, EndDate: TDateTime): Integer;
begin
  Result := System.DateUtils.DaysBetween(StartDate, EndDate);
end;

function IsToday(const DateTime: TDateTime): Boolean;
begin
  Result := System.DateUtils.IsToday(DateTime);
end;

function IsThisMonth(const DateTime: TDateTime): Boolean;
begin
  Result := (YearOf(DateTime) = YearOf(Now)) and (MonthOf(DateTime) = MonthOf(Now));
end;

end.
