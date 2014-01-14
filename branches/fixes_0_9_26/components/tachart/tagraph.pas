{
 /***************************************************************************
                               TAGraph.pas
                               -----------
                    Component Library Standard Graph


 ***************************************************************************/

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

Authors: Lu�s Rodrigues, Philippe Martinole, Alexander Klenin

}
unit TAGraph;

{$H+}

interface

uses
  LCLIntF, LCLType, LResources,
  SysUtils, Classes, Controls, Graphics, Dialogs, StdCtrls,
  TAChartUtils, TATypes;

const
  clTAColor = clScrollBar;
  LEGEND_SPACING = 5;

type
  TChart = class;

  TReticuleMode = (rmNone, rmVertical, rmHorizontal, rmCross);

  TDrawReticuleEvent = procedure(
    ASender: TChart; ASeriesIndex, AIndex: Integer;
    const AImg: TPoint; const AData: TDoublePoint) of object;

  { TBasicChartSeries }

  TBasicChartSeries = class(TComponent)
  protected
    FTitle: String;
    FChart: TChart;
    FActive: Boolean;
    FShowInLegend: Boolean;

    procedure AfterAdd; virtual;
    procedure DrawLegend(ACanvas: TCanvas; const ARect: TRect); virtual; abstract;
    function GetLegendCount: Integer; virtual; abstract;
    function GetLegendWidth(ACanvas: TCanvas): Integer; virtual; abstract;
    function GetNearestPoint(
      ADistFunc: TPointDistFunc; const APoint: TPoint;
      out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
      virtual;
    function GetSeriesColor: TColor; virtual; abstract;
    procedure UpdateBounds(
      var AXMin, AYMin, AXMax, AYMax: Double); virtual; abstract;
    procedure UpdateMargins(ACanvas: TCanvas; var AMargins: TRect); virtual;
    procedure SetActive(AValue: Boolean); virtual; abstract;
    procedure SetSeriesColor(const AValue: TColor); virtual; abstract;
    procedure SetShowInLegend(AValue: Boolean); virtual; abstract;

    procedure ReadState(Reader: TReader); override;
    procedure SetParentComponent(AParent: TComponent); override;
  public
    destructor Destroy; override;

    function GetParentComponent: TComponent; override;
    function HasParent: Boolean; override;

    function IsEmpty: Boolean; virtual; abstract;
    procedure Draw(ACanvas: TCanvas); virtual; abstract;

    property Active: Boolean read FActive write SetActive;
    property ParentChart: TChart read FChart;
    property SeriesColor: TColor
      read GetSeriesColor write SetSeriesColor default clTAColor;
    property ShowInLegend: Boolean
      read FShowInLegend write SetShowInLegend default true;
    property Title: String read FTitle write FTitle;
  end;

  TSeriesClass = class of TBasicChartSeries;

  { TChartSeriesList }

  TChartSeriesList = class(TPersistent)
  private
    FChart: TChart;
    FList: TFPList;
    function GetItem(AIndex: Integer): TBasicChartSeries;
    procedure SetItem(AIndex: Integer; const AValue: TBasicChartSeries);
  public
    constructor Create(AOwner: TChart);
    destructor Destroy; override;

    function Count: Integer;
    property Chart: TChart read FChart;
    property Items[AIndex: Integer]: TBasicChartSeries
      read GetItem write SetItem; default;
  end;

  { TChart }

  TChart = class(TCustomChart)
  private
    FSeries: TChartSeriesList;
    FMirrorX: Boolean;                // From right to left ?
    FXGraphMin, FYGraphMin: Double;   // Graph coordinates of limits
    FXGraphMax, FYGraphMax: Double;
    FAutoUpdateXMin: Boolean;         // Automatic calculation of XMin limit of graph ?
    FAutoUpdateXMax: Boolean;         // Automatic calculation of XMax limit of graph ?
    FAutoUpdateYMin: Boolean;         // Automatic calculation of YMin limit of graph ?
    FAutoUpdateYMax: Boolean;         // Automatic calculation of YMax limit of graph ?

    FLegend: TChartLegend;            //legend configuration
    FTitle: TChartTitle;              //legend configuration
    FFoot: TChartTitle;               //legend configuration
    FLeftAxis: TChartAxis;
    FBottomAxis: TChartAxis;

    FAllowZoom: Boolean;

    FGraphBrush: TBrush;
    AxisColor: TColor;                // Axis color
    FScale, FOffset: TDoublePoint;    // Coordinates transformation

    FIsMouseDown: Boolean;
    FIsZoomed: Boolean;
    FSelectionRect: TRect;
    FCurrentExtent: TDoubleRect;
    FClipRect: TRect;

    FReticuleMode: TReticuleMode;
    FOnDrawReticule: TDrawReticuleEvent;
    FReticulePos: TPoint;

    FFrame: TChartPen;

    FBackColor: TColor;

    FAxisVisible: Boolean;

    function GetMargins(ACanvas: TCanvas): TRect;
    procedure CalculateTransformationCoeffs(const AMargin: TRect);
    procedure PrepareXorPen;
    procedure SetAutoUpdateXMin(Value: Boolean);
    procedure SetAutoUpdateXMax(Value: Boolean);
    procedure SetAutoUpdateYMin(Value: Boolean);
    procedure SetAutoUpdateYMax(Value: Boolean);
    procedure SetReticuleMode(const AValue: TReticuleMode);
    procedure SetXGraphMin(Value: Double);
    procedure SetYGraphMin(Value: Double);
    procedure SetXGraphMax(Value: Double);
    procedure SetYGraphMax(Value: Double);
    procedure SetMirrorX(AValue: Boolean);
    procedure SetGraphBrush(Value: TBrush);
    procedure SetTitle(Value: TChartTitle);
    procedure SetFoot(Value: TChartTitle);
    function  GetLegendWidth(ACanvas: TCanvas): Integer;
    procedure DrawReticule(ACanvas: TCanvas);

    procedure SetLegend(Value: TChartLegend);
    procedure SetLeftAxis(Value: TChartAxis);
    procedure SetBottomAxis(Value: TChartAxis);

    procedure SetFrame(Value: TChartPen);

    procedure SetBackColor(Value: TColor);
    procedure SetAxisVisible(Value: Boolean);

    function GetChartHeight: Integer;
    function GetChartWidth: Integer;

    function GetSeriesCount: Integer;

  protected
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoDrawReticule(
      ASeriesIndex, AIndex: Integer; const AImg: TPoint;
      const AData: TDoublePoint); virtual;

    procedure Clean(ACanvas: TCanvas; ARect: TRect);
    procedure DrawTitleFoot(ACanvas: TCanvas; ARect: TRect);
    procedure DrawAxis(ACanvas: TCanvas; ARect: TRect);
    procedure DrawLegend(ACanvas: TCanvas; ARect: TRect);
    procedure UpdateExtent;

  public
    constructor Create(AOwner: TComponent); override;
    destructor  Destroy; override;
    procedure Paint; override;
    procedure EraseBackground(DC: HDC); override;
    procedure GetChildren(AProc: TGetChildProc; ARoot: TComponent); override;
    procedure SetChildOrder(Child: TComponent; Order: Integer); override;

    procedure PaintOnCanvas(ACanvas: TCanvas; ARect: TRect);

    procedure AddSeries(ASeries: TBasicChartSeries);
    procedure DeleteSeries(ASeries: TBasicChartSeries);
    procedure SetAutoXMin(Auto: Boolean);
    procedure SetAutoXMax(Auto: Boolean);
    procedure SetAutoYMin(Auto: Boolean);
    procedure SetAutoYMax(Auto: Boolean);

    procedure XGraphToImage(Xin: Double; out XOut: Integer);
    procedure YGraphToImage(Yin: Double; out YOut: Integer);
    function GraphToImage(AGraphPoint: TDoublePoint) : TPoint;
    procedure XImageToGraph(XIn: Integer; out XOut: Double);
    procedure YImageToGraph(YIn: Integer; out YOut: Double);
    procedure ImageToGraph(XIn, YIn: Integer; out XOut, YOut: Double);
    procedure DisplaySeries(ACanvas: TCanvas);
    procedure ZoomFull;

    procedure SaveToBitmapFile(const FileName: String);
    procedure CopyToClipboardBitmap;
    procedure DrawOnCanvas(Rect: TRect; ACanvas: TCanvas);
    procedure DrawLineHoriz(ACanvas: TCanvas; AY: Integer);
    procedure DrawLineVert(ACanvas: TCanvas; AX: Integer);

    function GetNewColor: TColor;
    function GetRectangle: TRect;

    function LineInViewPort(var AG1, AG2: TDoublePoint): Boolean;
    function IsPointInViewPort(const AP: TDoublePoint): Boolean;

    property Canvas;
    property ClipRect: TRect read FClipRect;

    property SeriesCount: Integer read GetSeriesCount;
    property ChartHeight: Integer read GetChartHeight;
    property ChartWidth: Integer read GetChartWidth;
  published
    procedure StyleChanged(Sender: TObject);
    property AutoUpdateXMin: Boolean read FAutoUpdateXMin write SetAutoUpdateXMin default true;
    property AutoUpdateXMax: Boolean read FAutoUpdateXMax write SetAutoUpdateXMax default true;
    property AutoUpdateYMin: Boolean read FAutoUpdateYMin write SetAutoUpdateYMin default true;
    property AutoUpdateYMax: Boolean read FAutoUpdateYMax write SetAutoUpdateYMax default true;
    property XGraphMin: Double read FXGraphMin write SetXGraphMin;
    property YGraphMin: Double read FYGraphMin write SetYGraphMin;
    property XGraphMax: Double read FXGraphMax write SetXGraphMax;
    property YGraphMax: Double read FYGraphMax write SetYGraphMax;
    property MirrorX: Boolean read FMirrorX write SetMirrorX;
    property GraphBrush: TBrush read FGraphBrush write SetGraphBrush;
    property ReticuleMode: TReticuleMode
      read FReticuleMode write SetReticuleMode default rmNone;
    property Series: TChartSeriesList read FSeries;

    property OnDrawReticule: TDrawReticuleEvent
      read FOnDrawReticule write FOnDrawReticule;

    property Legend: TChartLegend read FLegend write SetLegend;
    property Title: TChartTitle read FTitle write SetTitle;
    property Foot: TChartTitle read FFoot write SetFoot;

    property AllowZoom: Boolean read FAllowZoom write FAllowZoom default true;

    property LeftAxis: TChartAxis read FLeftAxis write SetLeftAxis;
    property BottomAxis: TChartAxis read FBottomAxis write SetBottomAxis;
    property Frame: TChartPen read FFrame write SetFrame;

    property BackColor: TColor read FBackColor write SetBackColor;

    property AxisVisible: Boolean read FAxisVisible write SetAxisVisible default true;

    property Align;
    property Anchors;
    property Color;
    property DoubleBuffered;
    property DragCursor;
    property DragMode;
    property Enabled;
    property ParentColor;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;

    property OnClick;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnStartDrag;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
  end;

procedure Register;
procedure RegisterSeriesClass(ASeriesClass: TSeriesClass; const ACaption: string);

var
  SeriesClassRegistry: TStringList;

implementation

uses
  Clipbrd, LCLProc, GraphMath, Math, Types;

const
  MinDouble = -1.7e308;
  MaxDouble = 1.7e308;

procedure Register;
var
  i: Integer;
  sc: TSeriesClass;
begin
  RegisterComponents('Additional', [TChart]);
  for i := 0 to SeriesClassRegistry.Count - 1 do begin
    sc := TSeriesClass(SeriesClassRegistry.Objects[i]);
    RegisterClass(sc);
    RegisterNoIcon([sc]);
  end;
end;

procedure RegisterSeriesClass(ASeriesClass: TSeriesClass; const ACaption: string);
begin
  if SeriesClassRegistry.IndexOfObject(TObject(ASeriesClass)) < 0 then
    SeriesClassRegistry.AddObject(ACaption, TObject(ASeriesClass));
end;

{ TChart }

constructor TChart.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  FAllowZoom := True;
  FAxisVisible := true; 

  Width := 400;
  Height := 300;

  FReticulePos := Point(-1, -1);
  FReticuleMode := rmNone;

  FSeries := TChartSeriesList.Create(Self);

  FAutoUpdateXMin := True;
  FAutoUpdateXMax := True;
  FAutoUpdateYMin := True;
  FAutoUpdateYMax := True;

  Color := clBtnFace;
  AxisColor := clBlack;

  FXGraphMax := 0;
  FXGraphMin := 0;
  FYGraphMax := 0;
  FYGraphMin := 0;

  MirrorX := false;
  FIsZoomed := false;
  FBackColor := Color;

  FGraphBrush := TBrush.Create;
  FGraphBrush.OnChange := @StyleChanged;

  FLegend := TChartLegend.Create(Self);
  FTitle := TChartTitle.Create(Self);
  FTitle.Alignment := taCenter;
  FTitle.Text.Add('TAChart');
  FFoot := TChartTitle.Create(Self);

  FLeftAxis := TChartAxis.Create(Self);
  FLeftAxis.Title.Angle := 90;
  FLeftAxis.Inverted := false;
  FLeftAxis.Grid.Visible := True;
  FLeftAxis.Grid.Style := psDot;
  FBottomAxis := TChartAxis.Create(Self);
  FBottomAxis.Title.Angle := 0;
  FBottomAxis.Inverted := false;
  FBottomAxis.Grid.Visible := True;
  FBottomAxis.Grid.Style := psDot;

  FFrame :=  TChartPen.Create;
  FFrame.Visible := true;
  FFrame.OnChange := @StyleChanged;
end;

destructor TChart.Destroy;
begin
  FSeries.Free;
  FGraphBrush.Free;

  FLegend.Destroy;
  FTitle.Destroy;
  FFoot.Destroy;
  LeftAxis.Destroy;
  BottomAxis.Destroy;
  FFrame.Destroy;

  inherited Destroy;
end;

procedure TChart.EraseBackground(DC: HDC);
begin
  // do not erase, since we will paint over it anyway
end;

procedure TChart.StyleChanged(Sender: TObject);
begin
  Invalidate;
end;

procedure TChart.Paint;
begin
  PaintOnCanvas(Canvas, Rect(0, 0, Width, Height));
end;

procedure TChart.PaintOnCanvas(ACanvas: TCanvas; ARect: TRect);
begin
  FClipRect := ARect;
  InflateRect(FClipRect, -2, -2);
  DrawReticule(ACanvas);

  UpdateExtent;
  Clean(ACanvas, ARect);
  DrawTitleFoot(ACanvas, ARect);
  DrawLegend(ACanvas, ARect);
  DrawAxis(ACanvas, ARect);
  DisplaySeries(ACanvas);
  DrawReticule(ACanvas);
end;

procedure TChart.PrepareXorPen;
begin
  Canvas.Brush.Style := bsClear;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Mode := pmXor;
  Canvas.Pen.Color := clWhite;
  Canvas.Pen.Style := psSolid;
  Canvas.Pen.Width := 1;
end;

procedure TChart.CalculateTransformationCoeffs(const AMargin: TRect);
var
  lo, hi: Integer;
begin
  if FXGraphMax <> FXGraphMin then begin
    lo := FClipRect.Left + AMargin.Left;
    hi := FClipRect.Right - AMargin.Right;
    if BottomAxis.Inverted then
      Exchange(lo, hi);
    FScale.X := (hi - lo) / (FXGraphMax - FXGraphMin);
    FOffset.X := hi - FScale.X * FXGraphMax;
    XImageToGraph(FClipRect.Left, FXGraphMin);
    XImageToGraph(FClipRect.Right, FXGraphMax);
    if BottomAxis.Inverted then
      Exchange(FXGraphMin, FXGraphMax);
  end
  else begin
    FScale.X := 1;
    FOffset.X := 0;
  end;
  if FYGraphMax <> FYGraphMin then begin
    lo := FClipRect.Bottom - AMargin.Bottom;
    hi := FClipRect.Top + AMargin.Top;
    if LeftAxis.Inverted then
      Exchange(lo, hi);
    FScale.Y := (hi - lo) / (FYGraphMax - FYGraphMin);
    FOffset.Y := hi - FScale.Y * FYGraphMax;
    YImageToGraph(FClipRect.Bottom, FYGraphMin);
    YImageToGraph(FClipRect.Top, FYGraphMax);
    if LeftAxis.Inverted then
      Exchange(FYGraphMin, FYGraphMax);
  end
  else begin
    FScale.Y := 1;
    FOffset.Y := 0;
  end;
end;

procedure TChart.Clean(ACanvas: TCanvas; ARect: TRect);
begin
  ACanvas.Pen.Mode := pmCopy;
  ACanvas.Pen.Style := psSolid;
  ACanvas.Pen.Color := Color;
  ACanvas.Brush.Color := Color;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Rectangle(ARect);
end;

procedure TChart.DrawTitleFoot(ACanvas: TCanvas; ARect: TRect);

  function AlignedTextPos(AAlign: TAlignment; const AText: String): TSize;
  begin
    Result := ACanvas.TextExtent(AText);
    case AAlign of
      taLeftJustify:
        Result.cx := FClipRect.Left;
      taCenter:
        Result.cx := (FClipRect.Left + FClipRect.Right - Result.cx) div 2;
      taRightJustify:
        Result.cx := FClipRect.Right - Result.cx;
    end;
  end;

var
  sz: TSize;
  i: Integer;
  pbf: TPenBrushFontRecall;
begin
  pbf := TPenBrushFontRecall.Create(ACanvas, [pbfBrush, pbfFont]);
  try
    with FTitle do
      if Visible and (Text.Count > 0) then begin
        ACanvas.Brush.Assign(Brush);
        ACanvas.Font.Assign(Font);
        for i := 0 to Text.Count - 1 do begin
          sz := AlignedTextPos(Alignment, Text[i]);
          ACanvas.TextOut(sz.cx, FClipRect.Top, Text[i]);
          FClipRect.Top += sz.cy;
        end;
        FClipRect.Top += 4;
      end;
    with FFoot do
      if Visible and (Text.Count > 0) then begin
        ACanvas.Brush.Assign(Brush);
        ACanvas.Font.Assign(Font);
        for i := Text.Count - 1 downto 0 do begin
          sz := AlignedTextPos(Alignment, Text[i]);
          FClipRect.Bottom -= sz.cy;
          ACanvas.TextOut(sz.cy, FClipRect.Bottom, Text[i]);
        end;
        FClipRect.Bottom -= 4;
      end;
  finally
    pbf.Free;
  end;
end;

procedure TChart.DrawAxis(ACanvas: TCanvas; ARect: TRect);

  function MarkToText(AMark: Double): String;
  begin
    if Abs(AMark) <= 1e-16 then AMark := 0;
    Result := Trim(FloatToStr(AMark));
  end;

  procedure DrawAxisTitles;
  var
    x, w: Integer;
    c: TPoint;
    sz: TSize;
    s: String;
  begin
    // FIXME: Angle assumed to be around 0 for bottom and 90 for left axis.

    c := CenterPoint(FClipRect);
    s := FLeftAxis.Title.Caption;
    if FLeftAxis.Visible and (s <> '') then begin
      w := ACanvas.TextHeight(FLeftAxis.Title.Caption);
      if FMirrorX then begin
        x := FClipRect.Right - w;
        FClipRect.Right := x - 4;
      end
      else begin
        x := FClipRect.Left;
        FClipRect.Left += w + 4;
      end;
      RotateLabel(ACanvas, x, c.Y - w div 2, s, FLeftAxis.Title.Angle)
    end;

    s := FBottomAxis.Title.Caption;
    if FBottomAxis.Visible and (s <> '') then begin
      sz := ACanvas.TextExtent(s);
      RotateLabel(
        ACanvas, c.X - sz.cx div 2, FClipRect.Bottom - sz.cy,
        s, FBottomAxis.Title.Angle);
      FClipRect.Bottom -= sz.cy + 4;
    end;
  end;

  procedure DrawXMark(AMark: Double);
  var
    x, w: Integer;
    markText: String;
  begin
    XGraphToImage(AMark, x);

    if FBottomAxis.Grid.Visible then begin
      ACanvas.Pen.Assign(FBottomAxis.Grid);
      ACanvas.Brush.Style := bsClear;
      DrawLineVert(ACanvas, x);
    end;

    ACanvas.Pen.Color := AxisColor;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Mode := pmCopy;
    ACanvas.Line(x, FClipRect.Bottom - 4, x, FClipRect.Bottom + 4);

    ACanvas.Brush.Assign(FGraphBrush);
    ACanvas.Brush.Color := Color;
    markText := MarkToText(AMark);
    w := ACanvas.TextWidth(markText);
    ACanvas.TextOut(
      EnsureRange(x - w div 2, 1, ARect.Right - w),
      FClipRect.Bottom + 5, markText);
  end;

  procedure DrawYMark(AMark: Double);
  var
    x, y, w, h: Integer;
    markText: String;
  begin
    YGraphToImage(AMark, y);

    if FLeftAxis.Grid.Visible then begin
      ACanvas.Pen.Assign(FLeftAxis.Grid);
      ACanvas.Brush.Style := bsClear;
      DrawLineHoriz(ACanvas, y);
    end;

    ACanvas.Pen.Color := AxisColor;
    ACanvas.Pen.Style := psSolid;
    ACanvas.Pen.Mode := pmCopy;
    ACanvas.Line(FClipRect.Left - 4, y, FClipRect.Left + 4, y);

    ACanvas.Brush.Assign(FGraphBrush);
    ACanvas.Brush.Color := Color;
    markText := MarkToText(AMark);
    w := ACanvas.TextWidth(markText);
    h := ACanvas.TextHeight(markText) div 2;
    if FMirrorX then
      x := FClipRect.Right + 5
    else
      x := FClipRect.Left - 5 - w;
    ACanvas.TextOut(x, y - h, markText);
  end;

var
  leftAxisWidth, maxWidth: Integer;
  leftAxisScale, bottomAxisScale: TAxisScale;
  step, mark: Double;
const
  INV_TO_SCALE: array [Boolean] of TAxisScale = (asIncreasing, asDecreasing);
begin
  if not FAxisVisible then exit;

  DrawAxisTitles;

  // Check AxisScale for both axes
  leftAxisScale := INV_TO_SCALE[LeftAxis.Inverted];
  bottomAxisScale := INV_TO_SCALE[BottomAxis.Inverted];

  leftAxisWidth := 0;
  if FLeftAxis.Visible then begin
    // Find max mark width
    maxWidth := 0;
    if FYGraphMin <> FYGraphMax then begin
      CalculateIntervals(FYGraphMin, FYGraphMax, leftAxisScale, mark, step);
      case leftAxisScale of
        asIncreasing:
          while mark <= FYGraphMax + step * 10e-10 do begin
            if mark >= FYGraphMin then
              maxWidth := Max(ACanvas.TextWidth(MarkToText(mark)), maxWidth);
            mark += step;
          end;
        asDecreasing:
          while mark >= FYGraphMin - step * 10e-10 do begin
            if mark <= FYGraphMax then
              maxWidth := Max(ACanvas.TextWidth(MarkToText(mark)), maxWidth);
            mark -= step;
          end;
      end;
    end;

    leftAxisWidth := maxWidth + 5;
    // CalculateTransformationCoeffs changes axis interval, so it is possibile
    // that a new mark longer then existing ones is introduced.
    // That will change marks width and reduce view area,
    // requiring another call to CalculateTransformationCoeffs...
    // So punt for now and just reserve space for extra digit unconditionally.
    leftAxisWidth += ACanvas.TextWidth('0');
    if FMirrorX then
      FClipRect.Right -= leftAxisWidth
    else
      FClipRect.Left += leftAxisWidth;
  end;

  if FBottomAxis.Visible then
    FClipRect.Bottom -= ACanvas.TextHeight('0') + 5;

  CalculateTransformationCoeffs(GetMargins(ACanvas));

  // Background
  with ACanvas do begin
    if FFrame.Visible then
      Pen.Assign(FFrame)
    else
      Pen.Style := psClear;
    Brush.Color := FBackColor;
    Rectangle(FClipRect);
  end;

  // X graduations
  if FBottomAxis.Visible and (FXGraphMin <> FXGraphMax) then begin
    CalculateIntervals(FXGraphMin, FXGraphMax, bottomAxisScale, mark, step);
    case bottomAxisScale of
      asIncreasing:
        while mark <= FXGraphMax + step * 10e-10 do begin
          if mark >= FXGraphMin then
            DrawXMark(mark);
          mark += step;
        end;
      asDecreasing:
        while mark >= FXGraphMin - step * 10e-10 do begin
          if mark <= FXGraphMax then
            DrawXMark(mark);
          mark -= step;
        end;
    end;
  end;

  // Y graduations
  if FLeftAxis.Visible and (FYGraphMin <> FYGraphMax) then begin
    CalculateIntervals(FYGraphMin, FYGraphMax, leftAxisScale, mark, step);
    case leftAxisScale of
      asIncreasing:
        while mark <= FYGraphMax + step * 10e-10 do begin
          if mark >= FYGraphMin then
            DrawYMark(mark);
          mark += step;
        end;
      asDecreasing:
        while mark >= FYGraphMin - step * 10e-10 do begin
          if mark <= FYGraphMax then
            DrawYMark(mark);
          mark -= step;
        end;
    end;
  end;
end;

procedure TChart.DrawLegend(ACanvas: TCanvas; ARect: TRect);
var
  w, h, x1, y1, x2, y2, i, TH: Integer;
  pbf: TPenBrushFontRecall;
  r: TRect;
begin
  if not Legend.Visible then exit;

  // TODO: Legend.Alignment

  pbf := TPenBrushFontRecall.Create(ACanvas, [pbfPen, pbfBrush, pbfFont]);
  try
    ACanvas.Font.Assign(FLegend.Font);

    w := GetLegendWidth(ACanvas);
    TH := ACanvas.TextHeight('I');
    h := 0;
    for i := 0 to SeriesCount - 1 do
      with Series[i] do
        if Active and ShowInLegend then
          Inc(h, GetLegendCount);
    FClipRect.Right -= w + 10;
    x1 := FClipRect.Right + 5;
    y1 := FClipRect.Top;
    x2 := x1 + w;
    y2 := y1 + LEGEND_SPACING + h * (TH + LEGEND_SPACING);

    // Border
    ACanvas.Brush.Assign(FGraphBrush);
    ACanvas.Pen.Assign(FLegend.Frame);
    ACanvas.Rectangle(x1, y1, x2, y2);

    r := Bounds(x1 + LEGEND_SPACING, y1 + LEGEND_SPACING, 17, TH);
    for i := 0 to SeriesCount - 1 do
      with Series[i] do
        if Active and ShowInLegend then begin
          ACanvas.Pen.Color := FLegend.Frame.Color;
          ACanvas.Brush.Assign(FGraphBrush);
          DrawLegend(ACanvas, r);
          OffsetRect(r, 0, GetLegendCount * (TH + LEGEND_SPACING));
        end;
  finally
    pbf.Free;
  end;
end;

procedure TChart.DrawLineHoriz(ACanvas: TCanvas; AY: Integer);
begin
  if (FClipRect.Top < AY) and (AY < FClipRect.Bottom) then
    ACanvas.Line(FClipRect.Left, AY, FClipRect.Right, AY);
end;

procedure TChart.DrawLineVert(ACanvas: TCanvas; AX: Integer);
begin
  if (FClipRect.Left < AX) and (AX < FClipRect.Right) then
    ACanvas.Line(AX, FClipRect.Top, AX, FClipRect.Bottom);
end;

procedure TChart.SetAutoUpdateXMin(Value: Boolean);
begin
  FAutoUpdateXMin := Value;
end;

procedure TChart.SetAutoUpdateXMax(Value: Boolean);
begin
  FAutoUpdateXMax := Value;
end;

procedure TChart.SetAutoUpdateYMin(Value: Boolean);
begin
  FAutoUpdateYMin := Value;
end;

procedure TChart.SetAutoUpdateYMax(Value: Boolean);
begin
  FAutoUpdateYMax := Value;
end;

procedure TChart.SetXGraphMin(Value: Double);
begin
  FXGraphMin := Value;
  Invalidate;
end;

procedure TChart.SetYGraphMin(Value: Double);
begin
  FYGraphMin := Value;
  Invalidate;
end;

procedure TChart.SetXGraphMax(Value: Double);
begin
  FXGraphMax := Value;
  Invalidate;
end;

procedure TChart.SetYGraphMax(Value: Double);
begin
  FYGraphMax := Value;
  Invalidate;
end;

procedure TChart.SetMirrorX(AValue: Boolean);
begin
  if AValue = FMirrorX then exit;
  FMirrorX := AValue;
  Invalidate;
end;

procedure TChart.SetReticuleMode(const AValue: TReticuleMode);
begin
  if FReticuleMode = AValue then exit;
  DrawReticule(Canvas);
  FReticuleMode := AValue;
  Invalidate;
end;

procedure TChart.SetTitle(Value: TChartTitle);
begin
  FTitle.Assign(Value);
  Invalidate;
end;

procedure TChart.SetFoot(Value: TChartTitle);
begin
  FFoot.Assign(Value);
  Invalidate;
end;


function TChart.GetLegendWidth(ACanvas: TCanvas): Integer;
var
  i: Integer;
begin
  Result := 0;
  if not FLegend.Visible then
    exit;

  for i := 0 to SeriesCount - 1 do
    with Series[i] do
      if Active and ShowInLegend then
        Result := Max(GetLegendWidth(ACanvas), Result);
  if Result > 0 then
    Result += 20 + 10;
end;

function TChart.GetMargins(ACanvas: TCanvas): TRect;
var
  i: Integer;
begin
  Result := Rect(4, 4, 4, 4);
  for i := 0 to SeriesCount - 1 do
    if Series[i].Active then
      Series[i].UpdateMargins(ACanvas, Result);
end;

procedure TChart.SetGraphBrush(Value: TBrush);
begin
  FGraphBrush.Assign(Value);
end;

procedure TChart.AddSeries(ASeries: TBasicChartSeries);
begin
  DrawReticule(Canvas);
  Series.FList.Add(ASeries);
  ASeries.FChart := Self;
  ASeries.AfterAdd;
end;

procedure TChart.DeleteSeries(ASeries: TBasicChartSeries);
var
  i: Integer;
begin
  i := FSeries.FList.IndexOf(ASeries);
  if i < 0 then exit;
  FSeries.FList.Delete(i);
  Invalidate;
end;

procedure TChart.SetAutoXMin(Auto: Boolean);
begin
  FAutoUpdateXMin := Auto;
  Invalidate;
end;

procedure TChart.SetAutoXMax(Auto: Boolean);
begin
  FAutoUpdateXMax := Auto;
  Invalidate;
end;

procedure TChart.SetAutoYMin(Auto: Boolean);
begin
  FAutoUpdateYMin := Auto;
  Invalidate;
end;

procedure TChart.SetAutoYMax(Auto: Boolean);
begin
  FAutoUpdateYMax := Auto;
  Invalidate;
end;

procedure TChart.XGraphToImage(Xin: Double; out XOut: Integer);
begin
  XOut := Round(FScale.X * XIn + FOffset.X);
end;

procedure TChart.YGraphToImage(Yin: Double; out YOut: Integer);
begin
  YOut := Round(FScale.Y * YIn + FOffset.Y);
end;

function TChart.GraphToImage(AGraphPoint: TDoublePoint): TPoint;
begin
  XGraphToImage(AGraphPoint.X, Result.X);
  YGraphToImage(AGraphPoint.Y, Result.Y);
end;

procedure TChart.XImageToGraph(XIn: Integer; out XOut: Double);
begin
  XOut := (XIn - FOffset.X) / FScale.X;
end;

procedure TChart.YImageToGraph(YIn: Integer; out YOut: Double);
begin
  YOut := (YIn - FOffset.Y) / FScale.Y;
end;

procedure TChart.ImageToGraph(XIn, YIn: Integer; out XOut, YOut: Double);
begin
  XImageToGraph(XIn, XOut);
  YImageToGraph(YIn, YOut);
end;

function TChart.IsPointInViewPort(const AP: TDoublePoint): Boolean;
begin
  Result :=
    InRange(AP.X, XGraphMin, XGraphMax) and InRange(AP.Y, YGraphMin, YGraphMax);
end;

function TChart.LineInViewPort(var AG1, AG2: TDoublePoint): Boolean;
var
  dx, dy, dxy, u1, u2, u3, u4: Double;

  procedure CalcDeltas;
  begin
    dy := AG1.Y - AG2.Y;
    dx := AG1.X - AG2.X;
    dxy := AG1.X * AG2.Y - AG1.Y * AG2.X;
  end;

begin
  CalcDeltas;
  u1 := XGraphMin * dy - YGraphMin * dx + dxy;
  u2 := XGraphMin * dy - YGraphMax * dx + dxy;
  u3 := XGraphMax * dy - YGraphMax * dx + dxy;
  u4 := XGraphMax * dy - YGraphMin * dx + dxy;

  Result := false;
  if u1 * u2 < 0 then begin
    Result := true;
    if AG1.X < XGraphMin then begin
      AG1.Y := (XGraphMin * dy + dxy) / dx;
      AG1.X := XGraphMin;
      CalcDeltas;
    end;
    if AG2.X < XGraphMin then begin
      AG2.Y := (XGraphMin * dy + dxy) / dx;
      AG2.X := XGraphMin;
      CalcDeltas;
    end;
  end;

  if u2 * u3 < 0 then begin
    Result := true;
    if AG2.Y > YGraphMax then begin
       AG2.X := (YGraphMax * dx - dxy) / dy;
       AG2.Y := YGraphMax;
       CalcDeltas;
    end;
  end;

  if u3 * u4 < 0 then begin
    Result := true;
    if AG1.X > XGraphMax then begin
       AG1.Y := (XGraphMax * dy + dxy) / dx;
       AG1.X := XGraphMax;
       CalcDeltas;
    end;
    if AG2.X > XGraphMax then begin
       AG2.Y := (XGraphMax * dy + dxy) / dx;
       AG2.X := XGraphMax;
       CalcDeltas;
    end;
  end;

  if u4 * u1 < 0 then begin
    Result := true;
    if AG1.Y < YGraphMin then begin
       AG1.X := (YGraphMin * dx - dxy) / dy;
       AG1.Y := YGraphMin;
       CalcDeltas;
    end;
  end;
end;

procedure TChart.SaveToBitmapFile(const FileName: String);
var
  tmpR: TRect;
  tmpBitmap: TBitmap;
begin
  try
    tmpBitmap := TBitmap.Create;
    tmpR := GetRectangle;
    tmpBitmap.Width := tmpR.Right - tmpR.Left;
    tmpBitmap.Height:= tmpR.Bottom - tmpR.Top;
    tmpBitmap.Canvas.CopyRect(tmpR, Canvas, tmpR);
    tmpBitmap.SaveToFile(FileName);
  finally
    tmpBitmap.Free;
  end;
end;

procedure TChart.CopyToClipboardBitmap;
var
  tmpBitmap: TBitmap;
  tmpR: TRect;
begin
  try
    tmpBitmap := TBitmap.Create;
    tmpR := GetRectangle;
    tmpBitmap.Width := tmpR.Right - tmpR.Left;
    tmpBitmap.Height:= tmpR.Bottom - tmpR.Top;
    tmpBitmap.Canvas.CopyRect(tmpR, Canvas, tmpR);
    ClipBoard.Assign(tmpBitmap);
  finally
    tmpBitmap.Free;
  end;
end;

procedure TChart.DrawOnCanvas(Rect: TRect; ACanvas: TCanvas);
begin
  PaintOnCanvas(ACanvas, Rect);
end;

procedure TChart.DisplaySeries(ACanvas: TCanvas);
var
  i: Integer;
begin
  if SeriesCount = 0 then exit;

  // Set clipping region so we don't draw outside.
  // TODO: Replace by Canvas.ClipRect after fixing issue 13418.
  IntersectClipRect(
    ACanvas.Handle, FClipRect.Left, FClipRect.Top, FClipRect.Right, FClipRect.Bottom);

  // Update all series
  for i := 0 to SeriesCount - 1 do
    if Series[i].Active then
      Series[i].Draw(ACanvas);

  // Now disable clipping.
  SelectClipRgn(ACanvas.Handle, 0);
end;

procedure TChart.DrawReticule(ACanvas: TCanvas);
begin
  PrepareXorPen;
  if ReticuleMode in [rmVertical, rmCross] then
    DrawLineVert(ACanvas, FReticulePos.X);
  if ReticuleMode in [rmHorizontal, rmCross] then
    DrawLineHoriz(ACanvas, FReticulePos.Y);
end;

procedure TChart.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if PtInRect(FClipRect, Point(X, Y)) and FAllowZoom then begin
    FIsMouseDown := true;
    FSelectionRect := Rect(X, Y, X, Y);
  end;
end;

procedure TChart.MouseMove(Shift: TShiftState; X, Y: Integer);
const
  DIST_FUNCS: array [TReticuleMode] of TPointDistFunc = (
    nil, @PointDistX, @PointDistY, @PointDist);
var
  i, pointIndex: Integer;
  pt, newRetPos: TPoint;
  value: TDoublePoint;
begin
  pt := Point(X, Y);
  if FIsMouseDown then begin
    PrepareXorPen;
    Canvas.Rectangle(FSelectionRect);
    FSelectionRect.BottomRight := pt;
    Canvas.Rectangle(FSelectionRect);
    exit;
  end;

  if FReticuleMode = rmNone then exit;
  for i := 0 to SeriesCount - 1 do begin
    if
      Series[i].GetNearestPoint(
        DIST_FUNCS[FReticuleMode], pt, pointIndex, newRetPos, value) and
      (newRetPos <> FReticulePos) and PtInRect(FClipRect, newRetPos)
    then begin
      DoDrawReticule(i, pointIndex, newRetPos, value);
      DrawReticule(Canvas);
      FReticulePos := newRetPos;
      DrawReticule(Canvas);
    end;
  end;
end;

procedure TChart.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if not FIsMouseDown then exit;
  FReticulePos := Point(X, Y);

  PrepareXorPen;
  Canvas.Rectangle(FSelectionRect);

  FIsMouseDown := false;

  with FSelectionRect do begin
    FIsZoomed := (Left < Right) and (Top < Bottom);
    if FIsZoomed then begin
      ImageToGraph(Left, Bottom, FCurrentExtent.a.X, FCurrentExtent.a.Y);
      ImageToGraph(Right, Top, FCurrentExtent.b.X, FCurrentExtent.b.Y);
    end;
  end;

  Invalidate;
end;

procedure TChart.DoDrawReticule(
  ASeriesIndex, AIndex: Integer; const AImg: TPoint; const AData: TDoublePoint);
begin
  if Assigned(FOnDrawReticule) then
    FOnDrawReticule(Self, ASeriesIndex, AIndex, AImg, AData);
end;

function TChart.GetNewColor: TColor;
var
  i, j: Integer;
  ColorFound: Boolean;
begin
  for i := 1 to MaxColor do begin
    ColorFound := false;
    for j := 0 to SeriesCount - 1 do begin
      if Series[j].SeriesColor = Colors[i] then
        ColorFound := true;
    end;
    if not ColorFound then begin
      Result := Colors[i];
      exit;
    end;
  end;
  Result := RGB(Random(255), Random(255), Random(255));
end;

function TChart.GetRectangle: TRect;
begin
  Result.Left := 0;
  Result.Top := 0;
  Result.Right := Width;
  Result.Bottom := Height;
end;

procedure TChart.SetLegend(Value: TChartLegend);
begin
  FLegend.Assign(Value);
  Invalidate;
end;

procedure TChart.SetLeftAxis(Value: TChartAxis);
begin
  FLeftAxis.Assign(Value);
  Invalidate;
end;

procedure TChart.SetBottomAxis(Value: TChartAxis);
begin
  FBottomAxis.Assign(Value);
  Invalidate;
end;

procedure TChart.SetChildOrder(Child: TComponent; Order: Integer);
var
  i: Integer;
begin
  i := Series.FList.IndexOf(Child);
  if i >= 0 then
    Series.FList.Move(i, Order);
end;

procedure TChart.SetFrame(Value: TChartPen);
begin
  FFrame.Assign(Value);
  Invalidate;
end;

procedure TChart.SetBackColor(Value: TColor);
begin
  FBackColor := Value;
  Invalidate;
end; 

procedure TChart.SetAxisVisible(Value: Boolean);
begin
  FAxisVisible := Value;
  Invalidate;
end; 

function TChart.GetChartHeight: Integer;
begin
  Result := FClipRect.Right - FClipRect.Left;
end;

function TChart.GetChartWidth: Integer;
begin
  Result := FClipRect.Bottom - FClipRect.Top;
end;

procedure TChart.GetChildren(AProc: TGetChildProc; ARoot: TComponent);
var
  i: Integer;
begin
  for i := 0 to SeriesCount - 1 do
   if Series[i].Owner = ARoot then
     AProc(Series[i]);
end;

function TChart.GetSeriesCount: Integer;
begin
  Result := FSeries.FList.Count;
end;

procedure TChart.UpdateExtent;
var
  XMinSeries, YMinSeries, XMaxSeries, YMaxSeries, Valeur, Tolerance: Double;
  allEmpty: Boolean;
  i: Integer;
begin
  if FIsZoomed then begin
    FXGraphMin := FCurrentExtent.a.X;
    FYGraphMin := FCurrentExtent.a.Y;
    FXGraphMax := FCurrentExtent.b.X;
    FYGraphMax := FCurrentExtent.b.Y;
  end
  else begin
    // Search # of points, min and max of all series
    XMinSeries := MaxDouble;
    XMaxSeries := MinDouble;
    YMinSeries := MaxDouble;
    YMaxSeries := MinDouble;
    for i := 0 to SeriesCount - 1 do
      with Series[i] do
        if Active then begin
          allEmpty := allEmpty and IsEmpty;
          UpdateBounds(XMinSeries, YMinSeries, XMaxSeries, YMaxSeries);
        end;
    if XMinSeries > MaxDouble / 10 then XMinSeries := 0;
    if YMinSeries > MaxDouble / 10 then YMinSeries := 0;
    if XMaxSeries < MinDouble / 10 then XMaxSeries := 0;
    if YMaxSeries < MinDouble / 10 then YMaxSeries := 0;

    if YMaxSeries = YMinSeries then begin
      YMaxSeries := YMaxSeries + 1;
      YMinSeries := YMinSeries - 1;
    end;
    if XMaxSeries = XMinSeries then begin
      XMaxSeries := XMaxSeries + 1;
      XMinSeries := XMinSeries - 1;
    end;


    // Image coordinates calculation
    // Update max in graph
    // if one point : + / - 10% of the point coordinates
    Tolerance := 0.001; //this should be cleaned eventually
    // Tolerance := 0.1;

    if not allEmpty then begin
      // if several points : automatic + / - 10% of interval
      Valeur := Tolerance * (XMaxSeries - XMinSeries);
      if Valeur <> 0 then begin
        if FAutoUpdateXMin then FXGraphMin := XMinSeries - Valeur;
        if FAutoUpdateXMax then FXGraphMax := XMaxSeries + Valeur;
      end
      else begin
        if FAutoUpdateXMin then FXGraphMin := XMinSeries - 1;
        if FAutoUpdateXMax then FXGraphMax := XMaxSeries + 1;
      end;
      Valeur := Tolerance * (YMaxSeries - YMinSeries);
      if Valeur <> 0 then begin
        if FAutoUpdateYMin then FYGraphMin := YMinSeries - Valeur;
        if FAutoUpdateYMax then FYGraphMax := YMaxSeries + Valeur;
      end
      else begin
        if FAutoUpdateYMin then FYGraphMin := YMinSeries - 1;
        if FAutoUpdateYMax then FYGraphMax := YMinSeries + 1;
      end;
    end
    else begin
      // 0 Points
      if FAutoUpdateXMin then FXGraphMin := 0;
      if FAutoUpdateXMax then FXGraphMax := 0;
      if FAutoUpdateYMin then FYGraphMin := 0;
      if FAutoUpdateYMax then FYGraphMax := 0;
    end;
  end;
end;

procedure TChart.ZoomFull;
begin
  FIsZoomed := false;
  Invalidate;
end;

{ TBasicChartSeries }

procedure TBasicChartSeries.AfterAdd;
begin
  // nothing
end;

destructor TBasicChartSeries.Destroy;
begin
  if FChart <> nil then
    FChart.DeleteSeries(Self);
  inherited Destroy;
end;

function TBasicChartSeries.GetNearestPoint(
  ADistFunc: TPointDistFunc; const APoint: TPoint;
  out AIndex: Integer; out AImg: TPoint; out AValue: TDoublePoint): Boolean;
begin
  Result := false;
end;

function TBasicChartSeries.GetParentComponent: TComponent;
begin
  Result := FChart;
end;

function TBasicChartSeries.HasParent: Boolean;
begin
  Result := true;
end;

procedure TBasicChartSeries.ReadState(Reader: TReader);
begin
  inherited ReadState(Reader);
  if Reader.Parent is TChart then begin
    (Reader.Parent as TChart).AddSeries(Self);
    //DebugLn('TAChart %s: %d series', [Reader.Parent.Name, (Reader.Parent as TChart).SeriesCount]);
  end;
end;

procedure TBasicChartSeries.SetParentComponent(AParent: TComponent);
begin
  if not (csLoading in ComponentState) then
    (AParent as TChart).AddSeries(Self);
end;

procedure TBasicChartSeries.UpdateMargins(
  ACanvas: TCanvas; var AMargins: TRect);
begin
  // nothing
end;

{ TChartSeriesList }

function TChartSeriesList.Count: Integer;
begin
  Result := FList.Count;
end;

constructor TChartSeriesList.Create(AOwner: TChart);
begin
  FChart := AOwner;
  FList := TFPList.Create;
end;

destructor TChartSeriesList.Destroy;
var
  i: Integer;
begin
  for i := 0 to FList.Count - 1 do begin
    Items[i].FChart := nil;
    Items[i].Free;
  end;
  FList.Free;
  inherited Destroy;
end;

function TChartSeriesList.GetItem(AIndex: Integer): TBasicChartSeries;
begin
  Result := TBasicChartSeries(FList.Items[AIndex]);
end;

procedure TChartSeriesList.SetItem(
  AIndex: Integer; const AValue: TBasicChartSeries);
begin
  GetItem(AIndex).Assign(AValue);
end;

initialization
  {$I tagraph.lrs}
  SeriesClassRegistry := TStringList.Create;

finalization
  SeriesClassRegistry.Free;

end.