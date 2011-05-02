{

 *****************************************************************************
 *                                                                           *
 *  See the file COPYING.modifiedLGPL.txt, included in this distribution,    *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************

 Authors: Alexander Klenin

}

unit TAIntervalSources;

{$H+}

interface

uses
  Classes, Types, TAChartUtils, TACustomSource;

type
  { TIntervalChartSource }

  TIntervalChartSource = class(TCustomChartSource)
  protected
    function GetCount: Integer; override;
    function GetItem(AIndex: Integer): PChartDataItem; override;
    procedure SetYCount(AValue: Cardinal); override;
  public
    procedure ValuesInRange(
      AMin, AMax: Double; const AFormat: String; AUseY: Boolean;
      var AValues: TDoubleDynArray; var ATexts: TStringDynArray); override;
  end;

  TDateTimeStep = (
    dtsCentury, dtsDecade, dtsYear, dtsQuarter, dtsMonth, dtsWeek, dtsDay,
    dtsHour, dtsTenMinutes, dtsMinute, dtsTenSeconds, dtsSecond, dtsMillisecond
  );
  TDateTimeSteps = set of TDateTimeStep;

const
  DATE_TIME_STEPS_ALL = [Low(TDateTimeStep) .. High(TDateTimeStep)];

type

  { TDateTimeIntervalChartSource }

  TDateTimeIntervalChartSource = class(TIntervalChartSource)
  private
    FDateTimeFormat: String;
    FSteps: TDateTimeSteps;
  public
    constructor Create(AOwner: TComponent); override;
    procedure ValuesInRange(
      AMin, AMax: Double; const AFormat: String; AUseY: Boolean;
      var AValues: TDoubleDynArray; var ATexts: TStringDynArray); override;
  published
    property DateTimeFormat: String read FDateTimeFormat write FDateTimeFormat;
    property Steps: TDateTimeSteps
      read FSteps write FSteps default DATE_TIME_STEPS_ALL;
  end;


procedure Register;

implementation

uses
  DateUtils, Math, StrUtils, SysUtils;

procedure CalculateIntervals(
  AMin, AMax: Double; AxisScale: TAxisScale; out AStart, AStep: Double);
var
  extent, extentTmp, stepCount, scale, maxStepCount, m: Double;
  i: Integer;
const
  GOOD_STEPS: array [1..3] of Double = (0.2, 0.5, 1.0);
  BASE = 10;
begin
  extent := AMax - AMin;
  AStep := 1;
  AStart := AMin;
  if extent <= 0 then exit;

  maxStepCount := 0;
  scale := 1.0;
  for i := Low(GOOD_STEPS) to High(GOOD_STEPS) do begin
    extentTmp := extent / GOOD_STEPS[i];
    m := IntPower(BASE, Round(logn(BASE, extentTmp)));
    while extentTmp * m > BASE do
      m /= BASE;
    while extentTmp * m <= 1 do
      m *= BASE;
    stepCount := extentTmp * m;
    if stepCount > maxStepCount then begin
      maxStepCount := stepCount;
      scale := m;
      AStep := GOOD_STEPS[i] / m;
    end;
  end;
  case AxisScale of
    asIncreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asDecreasing: begin
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
    asLogIncreasing: begin
      // FIXME: asLogIncreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMin - AStep) * scale) / scale;
      while AStart > AMin do AStart -= AStep;
    end;
    asLogDecreasing: begin
      // FIXME: asLogDecreasing is still not implemented.
      // The following is the same code for asIncreasing;
      // If 0 is in the interval, set it as a mark.
      if InRange(0, AMin, AMax) then
        AStart := 0
      else
        AStart := Round((AMax + AStep) * scale) / scale;
      while AStart < AMax do AStart += AStep;
    end;
  end; {case AxisScale}
end;

function GetIntervals(AMin, AMax: Double; AInverted: Boolean): TDoubleDynArray;
const
  INV_TO_SCALE: array [Boolean] of TAxisScale = (asIncreasing, asDecreasing);
  K = 1e-10;
var
  start, step, m, m1: Double;
  markCount: Integer;
begin
  CalculateIntervals(AMin, AMax, INV_TO_SCALE[AInverted], start, step);
  AMin -= step * K;
  AMax += step * K;
  if AInverted then
    step := - step;
  m := start;
  markCount := 0;
  while true do begin
    if InRange(m, AMin, AMax) then
      Inc(markCount)
    else if markCount > 0 then
      break;
    m1 := m + step;
    if m1 = m then break;
    m := m1;
  end;
  SetLength(Result, markCount);
  m := start;
  markCount := 0;
  while true do begin
    if Abs(m / step) < K then
      m := 0;
    if InRange(m, AMin, AMax) then begin
      Result[markCount] := m;
      Inc(markCount);
    end
    else if markCount > 0 then
      break;
    m1 := m + step;
    if m1 = m then break;
    m := m1;
  end;
end;

procedure Register;
begin
  RegisterComponents(
    CHART_COMPONENT_IDE_PAGE, [
      TDateTimeIntervalChartSource
    ]);
end;

{ TIntervalChartSource }

function TIntervalChartSource.GetCount: Integer;
begin
  Result := 0;
end;

function TIntervalChartSource.GetItem(AIndex: Integer): PChartDataItem;
begin
  Unused(AIndex);
  Result := nil;
end;

procedure TIntervalChartSource.SetYCount(AValue: Cardinal);
begin
  Unused(AValue);
  raise EYCountError.Create('Can not set YCount');
end;

procedure TIntervalChartSource.ValuesInRange(
  AMin, AMax: Double; const AFormat: String; AUseY: Boolean;
  var AValues: TDoubleDynArray; var ATexts: TStringDynArray);
var
  i: Integer;
begin
  Unused(AUseY);
  if AMin > AMax then exit;
  AValues := GetIntervals(AMin, AMax, false);
  SetLength(ATexts, Length(AValues));
  for i := 0 to High(AValues) do
    // Extra format arguments for compatibility with FormatItem.
    ATexts[i] := Format(AFormat, [AValues[i], 0.0, '', 0.0, 0.0]);
end;

{ TDateTimeIntervalChartSource }

constructor TDateTimeIntervalChartSource.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  FSteps := DATE_TIME_STEPS_ALL;
end;

procedure TDateTimeIntervalChartSource.ValuesInRange(AMin, AMax: Double;
  const AFormat: String; AUseY: Boolean; var AValues: TDoubleDynArray;
  var ATexts: TStringDynArray);
const
  YEAR = 365.25;
  STEP_INTERVALS: array [TDateTimeStep] of Double = (
    100 * YEAR, 10 * YEAR, YEAR, YEAR / 4, YEAR / 12, 7, 1,
    OneHour, 10 * OneMinute, OneMinute, 10 * OneSecond, OneSecond, OneMillisecond
  );
  MIN_STEPS = 4;
  MAX_STEPS = 20;
var
  s: TDateTimeStep;
  si, x, start: TDateTime;
  prevSt: TSystemTime;

  function FormatLabel: String;
  var
    st: TSystemTime;
  begin
    if DateTimeFormat <> '' then
      exit(FormatDateTime(DateTimeFormat, x));
    DateTimeToSystemTime(x, st);
    case s of
      dtsCentury, dtsDecade, dtsYear:
        Result := FormatDateTime('yyyy', x);
      dtsQuarter:
        Result := FormatDateTime('yyyy/', x) + IntToStr(Floor(x / si) mod 4 + 1);
      dtsMonth:
        Result := FormatDateTime(
          IfThen(st.Year = prevSt.Year, 'mm', 'mm/yyyy'), x);
      dtsWeek:
        Result := FormatDateTime('dd/mm', x);
      dtsDay:
        Result := FormatDateTime(
          IfThen(st.Month = prevSt.Month, 'dd', 'dd/mm'), x);
      dtsHour:
        Result := FormatDateTime(
          IfThen(st.Day = prevSt.Day, 'hh:00', 'dd hh:00'), x);
      dtsTenMinutes, dtsMinute:
        Result := FormatDateTime(
          IfThen(st.Hour = prevSt.Hour, 'nn', 'hh:nn'), x);
      dtsTenSeconds, dtsSecond:
        Result := FormatDateTime(
          IfThen(st.Minute = prevSt.Minute, 'ss', 'nn:ss'), x);
      dtsMillisecond:
        Result := IntToStr(st.Millisecond) + 'ms';
    end;
    prevSt := st;
  end;

var
  i, cnt: Integer;
begin
  if (AMax - AMin) / STEP_INTERVALS[dtsCentury] > MAX_STEPS then begin
    inherited ValuesInRange(
      AMin / STEP_INTERVALS[dtsYear], AMax / STEP_INTERVALS[dtsYear],
      AFormat, AUseY, AValues, ATexts);
    exit;
  end;
  s := Low(s);
  while s < High(s) do begin
    si := STEP_INTERVALS[s];
    if (s in Steps) and ((AMax - AMin) / si > MIN_STEPS) then
      break;
    Inc(s);
  end;
  start := Int(AMin / si - 1) * si;
  x := start;
  cnt := 0;
  while x <= AMax do begin
    if x >= AMin then
      cnt += 1;
    x += si;
  end;
  i := Length(AValues);
  SetLength(AValues, i + cnt);
  SetLength(ATexts, i + cnt);

  FillChar(prevSt, SizeOf(prevSt), $FF);
  x := start;
  while x <= AMax do begin
   if x >= AMin then begin
      AValues[i] := x;
      ATexts[i] := Format(AFormat, [x, 0.0, FormatLabel, 0.0, 0.0]);
      i += 1;
    end;
    case s of
      dtsCentury: x := IncYear(x, 100);
      dtsDecade: x := IncYear(x, 10);
      dtsYear: x := IncYear(x);
      dtsMonth: x := IncMonth(x);
      otherwise x += si;
    end;
  end;
end;

end.

