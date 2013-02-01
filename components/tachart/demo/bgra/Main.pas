unit Main;

{$mode objfpc}{$H+}

interface

uses
  Classes, ComCtrls, ExtCtrls, StdCtrls, SysUtils, FileUtil, Forms,
  Controls, Graphics, Dialogs,
  TAGraph, TASeries, TASources, TAAnimatedSource, TACustomSource,
  BGRASliceScaling;

type

  { TForm1 }

  TForm1 = class(TForm)
    btnStartStop: TButton;
    cbAntialiasing: TCheckBox;
    cbPie: TCheckBox;
    chSimple: TChart;
    chSimpleAreaSeries1: TAreaSeries;
    chSimpleBarSeries1: TBarSeries;
    chSimpleLineSeries1: TLineSeries;
    chSimplePieSeries1: TPieSeries;
    chBarEffects: TChart;
    chBarEffectsBarSeries1: TBarSeries;
    Image1: TImage;
    ListChartSource1: TListChartSource;
    PageControl1: TPageControl;
    PaintBox1: TPaintBox;
    Panel1: TPanel;
    Panel2: TPanel;
    RandomChartSource1: TRandomChartSource;
    rgAnimation: TRadioGroup;
    rgStyle: TRadioGroup;
    Splitter1: TSplitter;
    tsSimple: TTabSheet;
    tsBarEffects: TTabSheet;
    procedure btnStartStopClick(Sender: TObject);
    procedure cbAntialiasingChange(Sender: TObject);
    procedure cbPieChange(Sender: TObject);
    procedure chSimpleAfterPaint(ASender: TChart);
    procedure chBarEffectsBarSeries1BeforeDrawBar(ASender: TBarSeries;
      ACanvas: TCanvas; const ARect: TRect; APointIndex, AStackIndex: Integer;
      var ADoDefaultDrawing: Boolean);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure PaintBox1Paint(Sender: TObject);
    procedure rgAnimationClick(Sender: TObject);
    procedure rgStyleClick(Sender: TObject);
  private
    FAnimatedSource: TCustomAnimatedChartSource;
    FSliceScaling: TBGRASliceScaling;
    procedure OnGetItem(
      ASource: TCustomAnimatedChartSource;
      AIndex: Integer; var AItem: TChartDataItem);
  end;

var
  Form1: TForm1; 

implementation

{$R *.lfm}

uses
  Math, BGRABitmap, BGRABitmapTypes, BGRAGradients,
  TAChartUtils, TADrawerBGRA, TADrawerCanvas, TADrawUtils, TAGeometry;

function CreateChocolateBar(
  ALightPos: TPoint; ARect: TRect; ABackColor: TBGRAPixel;
  ARoundedCorners: Boolean; AOptions: TRectangleMapOptions): TBGRABitmap;
var
  phong: TPhongShading;
  t: TPoint;
begin
  t := MaxPoint(ARect.BottomRight - ARect.TopLeft, Point(0, 0));
  Result := TBGRABitmap.Create(t.X, t.Y, ABackColor);
  if (t.X = 0) and (t.Y = 0) then exit;
  phong := TPhongShading.Create;
  try
    phong.AmbientFactor := 0.5;
    phong.LightPosition := ALightPos - ARect.TopLeft;
    phong.DrawRectangle(
      Result, BoundsSize(0, 0, t), t.X div 8, t.X div 8,
      GammaCompression(SetIntensity(GammaExpansion(BGRA(86, 41, 38)), 30000)),
      ARoundedCorners, AOptions);
  finally
    phong.Free;
  end;
end;

procedure DrawPhong3DBar(ASeries: TBarSeries; ACanvas: TCanvas; ARect: TRect);

  function CreatePhong3DBar(
    ALightPos: TPoint; ARect: TRect; ADepth: Integer;
    AColor: TBGRAPixel): TBGRABitmap;
  var
    phong: TPhongShading;
    i: Integer;
    map: TBGRABitmap;
    h: TBGRAPixel;
    t: TPoint;
  begin
    t := MaxPoint(ARect.BottomRight - ARect.TopLeft, Point(0, 0));
    map := TBGRABitmap.Create(t.X + ADepth,t.Y + ADepth);
    try
      map.FillRect(0, ADepth, t.X, t.Y + ADepth, BGRAWhite, dmSet);
      for i := 1 to ADepth do begin
        h := MapHeightToBGRA((ADepth - i) / ADepth, 255);
        map.SetHorizLine(i, ADepth - i, t.X - 1 + i - 1, h);
        map.SetVertLine(t.X - 1 + i, ADepth - i, t.Y + ADepth - 1 - i, h);
      end;
      Result := TBGRABitmap.Create(t.X + ADepth, t.Y + ADepth);
      if (Result.width = 0) or (Result.Height = 0) then exit;
      phong := TPhongShading.Create;
      try
        phong.AmbientFactor := 0.5;
        phong.LightPosition := ALightPos - ARect.TopLeft;
        phong.Draw(Result, map, ADepth, 0, 0, AColor);
      finally
        phong.Free;
      end;
    finally
      map.Free;
    end;
  end;

  function DrawContour(ABar: TBGRABitmap): TPoint;
  var
    size: TPoint;
    temp: TBGRABitmap;
    margin, depth: integer;
  begin
    Result := point(0, 0);
    if ASeries.BarPen.Style = psClear then exit;
    size := ARect.BottomRight - ARect.TopLeft;
    if ASeries.BarPen.Width > 1 then begin
      margin := (ASeries.BarPen.Width + 1) div 2;
      Result := Point(margin, margin);
      temp := TBGRABitmap.Create(ABar.Width + 2 * margin, ABar.Height + 2 * margin);
      temp.PutImage(Result.X, Result.Y, ABar, dmSet);
      BGRAReplace(ABar, temp);
    end;
    depth := ASeries.Depth;
    with ABar.CanvasBGRA do begin
      Pen.Assign(ASeries.BarPen);
      Brush.Style := bsClear;
      Polygon([
         Point(Result.x + 0, Result.y + depth),
         Point(Result.x + depth, Result.y + 0),
         Point(Result.x + size.x - 1 + depth, Result.y + 0),
         Point(Result.x + size.x - 1 + depth, Result.y + size.y - 1),
         Point(Result.x + size.x - 1, Result.y + size.y - 1 + depth),
         Point(Result.x + 0, Result.y + size.y - 1 + depth)
      ]);
    end;
  end;

var
  bar: TBGRABitmap;
begin
  bar := CreatePhong3DBar(
    Point(ASeries.ParentChart.ClientWidth div 2, 0),
    ARect, ASeries.Depth, ColorToBGRA(ASeries.BarBrush.Color));
  try
    with (ARect.TopLeft - DrawContour(bar)) do
      bar.Draw(ACanvas, X, Y - ASeries.Depth, false);
  finally
    bar.Free;
  end;
end;

{ TForm1 }

procedure TForm1.btnStartStopClick(Sender: TObject);
begin
  if FAnimatedSource.IsAnimating then
    FAnimatedSource.Stop
  else
    FAnimatedSource.Start;
end;

procedure TForm1.cbAntialiasingChange(Sender: TObject);
begin
  if cbAntialiasing.Checked then
    chSimple.AntialiasingMode := amOn
  else
    chSimple.AntialiasingMode := amOff;
end;

procedure TForm1.cbPieChange(Sender: TObject);
begin
  chSimplePieSeries1.Active := cbPie.Checked;
end;

procedure TForm1.chSimpleAfterPaint(ASender: TChart);
begin
  Unused(ASender);
  PaintBox1.Invalidate;
end;

procedure TForm1.chBarEffectsBarSeries1BeforeDrawBar(ASender: TBarSeries;
  ACanvas: TCanvas; const ARect: TRect; APointIndex, AStackIndex: Integer;
  var ADoDefaultDrawing: Boolean);
var
  temp, stretched: TBGRABitmap;
  sz: TPoint;
  lightPos: TPoint;
begin
  Unused(ASender);
  Unused(APointIndex, AStackIndex);
  ADoDefaultDrawing := false;
  sz := ARect.BottomRight - ARect.TopLeft;
  case rgStyle.ItemIndex of
    0: begin
      temp := TBGRABitmap.Create(
        FSliceScaling.BitmapWidth,
        Round(FSliceScaling.BitmapWidth * sz.Y / sz.X));
      stretched := nil;
      try
        FSliceScaling.Draw(temp, 0, 0, temp.Width, temp.Height);
        temp.ResampleFilter := rfLinear;
        stretched := temp.Resample(sz.x, sz.Y, rmFineResample) as TBGRABitmap;
        stretched.Draw(ACanvas, ARect, False);
      finally
        temp.Free;
        stretched.Free;
      end;
    end;
    1: begin
      lightPos := Point(chBarEffects.ClientWidth div 2, 0);
      with CreateChocolateBar(
        lightPos, ARect, BGRAPixelTransparent, false, [rmoNoBottomBorder])
      do
        try
          Draw(ACanvas, ARect.Left, ARect.Top, false);
        finally
          Free;
        end;
    end;
    2:
      DrawPhong3DBar(ASender, ACanvas, ARect);
  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin
  FAnimatedSource := TCustomAnimatedChartSource.Create(Self);
  FAnimatedSource.Origin := ListChartSource1;
  FAnimatedSource.AnimationInterval := 30;
  FAnimatedSource.AnimationTime := 1000;
  FAnimatedSource.OnGetItem := @OnGetItem;

  chBarEffectsBarSeries1.Source := FAnimatedSource;
  chBarEffects.BackColor:= BGRAToColor(CSSDarkSlateBlue);
  chSimple.BackColor:= BGRAToColor(CSSYellowGreen);
  chSimple.Color:= BGRAToColor(CSSYellowGreen);
  chSimple.BackColor := BGRAToColor(CSSBeige);

  FSliceScaling := TBGRASliceScaling.Create(Image1.Picture.Bitmap, 70, 0, 35, 0);
  FSliceScaling.AutodetectRepeat;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  FSliceScaling.Free;
end;

procedure TForm1.PaintBox1Paint(Sender: TObject);
var
  bmp: TBGRABitmap;
  id: IChartDrawer;
  rp: TChartRenderingParams;
begin
  bmp := TBGRABitmap.Create(PaintBox1.Width, PaintBox1.Height);
  chSimple.DisableRedrawing;
  try
    chSimple.Title.Text.Text := 'BGRABitmap';
    id := TBGRABitmapDrawer.Create(bmp);
    id.DoGetFontOrientation := @CanvasGetFontOrientationFunc;
    rp := chSimple.RenderingParams;
    chSimple.Draw(id, Rect(0, 0, PaintBox1.Width, PaintBox1.Height));
    chSimple.RenderingParams := rp;
    bmp.Draw(PaintBox1.Canvas, 0, 0);
    chSimple.Title.Text.Text := 'Standard';
  finally
    chSimple.EnableRedrawing;
    bmp.Free;
  end;
end;

procedure TForm1.OnGetItem(
  ASource: TCustomAnimatedChartSource;
  AIndex: Integer; var AItem: TChartDataItem);
begin
  case rgAnimation.ItemIndex of
  0: AItem.Y *= ASource.Progress;
  1:
    if ASource.Count * ASource.Progress < AIndex then
      AItem.Y := 0;
  2:
    case Sign(Trunc(ASource.Count * ASource.Progress) - AIndex) of
      0: AItem.Y *= Frac(ASource.Count * ASource.Progress);
      -1: AItem.Y := 0;
    end;
  end;
end;

procedure TForm1.rgAnimationClick(Sender: TObject);
begin
  FAnimatedSource.Start;
end;

procedure TForm1.rgStyleClick(Sender: TObject);
var
  d: Integer;
begin
  d := IfThen(rgStyle.ItemIndex = 2, 10, 0);
  chBarEffects.Depth := d;
  chBarEffectsBarSeries1.Depth := d;
  chBarEffectsBarSeries1.ZPosition := d;
  FAnimatedSource.Start;
end;

end.

