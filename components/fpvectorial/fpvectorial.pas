{
fpvectorial.pas

Vector graphics document

License: The same modified LGPL as the Free Pascal RTL
         See the file COPYING.modifiedLGPL for more details

AUTHORS: Felipe Monteiro de Carvalho
         Pedro Sol Pegorini L de Lima
}
unit fpvectorial;

{$ifdef fpc}
  {$mode delphi}
{$endif}

{$define USE_LCL_CANVAS}
{$ifdef USE_LCL_CANVAS}
  {$define USE_CANVAS_CLIP_REGION}
  {.$define DEBUG_CANVAS_CLIP_REGION}
{$endif}
{.$define FPVECTORIAL_TOCANVAS_DEBUG}

interface

uses
  Classes, SysUtils, Math,
  // FCL-Image
  fpcanvas, fpimage,
  // LCL
  lazutf8
  {$ifdef USE_LCL_CANVAS}
  , Graphics, LCLIntf, LCLType
  {$endif}
  ;

type
  TvVectorialFormat = (
    { Multi-purpose document formats }
    vfPDF, vfSVG, vfCorelDrawCDR, vfWindowsMetafileWMF,
    { CAD formats }
    vfDXF,
    { Geospatial formats }
    vfLAS, vfLAZ,
    { Printing formats }
    vfPostScript, vfEncapsulatedPostScript,
    { GCode formats }
    vfGCodeAvisoCNCPrototipoV5, vfGCodeAvisoCNCPrototipoV6,
    { Formula formats }
    vfMathML,
    { Raster Image formats }
    vfRAW
    );

  TvProgressEvent = procedure (APercentage: Byte) of object;

  {@@ This routine is called to add an item of caption AStr to an item
    AParent, which is a pointer to another item as returned by a previous call
    of this same proc. If AParent = nil then it should add the item to the
    top of the tree. In all cases this routine should return a pointer to the
    newly created item.
  }
  TvDebugAddItemProc = function (AStr: string; AParent: Pointer): Pointer of object;

const
  { Default extensions }
  { Multi-purpose document formats }
  STR_PDF_EXTENSION = '.pdf';
  STR_POSTSCRIPT_EXTENSION = '.ps';
  STR_SVG_EXTENSION = '.svg';
  STR_CORELDRAW_EXTENSION = '.cdr';
  STR_WINMETAFILE_EXTENSION = '.wmf';
  STR_AUTOCAD_EXCHANGE_EXTENSION = '.dxf';
  STR_ENCAPSULATEDPOSTSCRIPT_EXTENSION = '.eps';
  STR_LAS_EXTENSION = '.las';
  STR_LAZ_EXTENSION = '.laz';
  STR_RAW_EXTENSION = '.raw';
  STR_MATHML_EXTENSION = '.mathml';

type
  TvCustomVectorialWriter = class;
  TvCustomVectorialReader = class;
  TvVectorialPage = class;

  { Pen, Brush and Font }

  TvPen = record
    Color: TFPColor;
    Style: TFPPenStyle;
    Width: Integer;
  end;

  TvBrush = record
    Color: TFPColor;
    Style: TFPBrushStyle;
  end;

  TvFont = record
    Color: TFPColor;
    Size: integer;
    Name: utf8string;
    {@@
      Font orientation is measured in degrees and uses the
      same direction as the LCL TFont.orientation, which is counter-clockwise.
      Zero is the normal, horizontal, orientation, directed to the right.
    }
    Orientation: Double;
  end;

  { Coordinates and polyline segments }

  T3DPoint = record
    X, Y, Z: Double;
  end;

  P3DPoint = ^T3DPoint;

  TSegmentType = (
    st2DLine, st2DLineWithPen, st2DBezier,
    st3DLine, st3DBezier, stMoveTo);

  {@@
    The coordinates in fpvectorial are given in millimiters and
    the starting point is in the bottom-left corner of the document.
    The X grows to the right and the Y grows to the top.
  }
  { TPathSegment }

  TPathSegment = class
  public
    SegmentType: TSegmentType;
    // Fields for linking the list
    Previous: TPathSegment;
    Next: TPathSegment;
  end;

  {@@
    In a 2D segment, the X and Y coordinates represent usually the
    final point of the segment, being that it starts where the previous
    segment ends. The exception is for the first segment of all, which simply
    holds the starting point for the drawing and should always be of the type
    stMoveTo.
  }
  T2DSegment = class(TPathSegment)
  public
    X, Y: Double;
  end;

  T2DSegmentWithPen = class(T2DSegment)
  public
    Pen: TvPen;
  end;

  {@@
    In Bezier segments, we remain using the X and Y coordinates for the ending point.
    The starting point is where the previous segment ended, so that the intermediary
    bezier control points are [X2, Y2] and [X3, Y3].
  }
  T2DBezierSegment = class(T2DSegment)
  public
    X2, Y2: Double;
    X3, Y3: Double;
  end;

  T3DSegment = class(TPathSegment)
  public
    {@@
      Coordinates of the end of the segment.
      For the first segment, this is the starting point.
    }
    X, Y, Z: Double;
  end;

  T3DBezierSegment = class(T3DSegment)
  public
    X2, Y2, Z2: Double;
    X3, Y3, Z3: Double;
  end;

  TvFindEntityResult = (vfrNotFound, vfrFound, vfrSubpartFound);

  { Now all elements }

  {@@
    All elements should derive from TvEntity, regardless of whatever properties
    they might contain.
  }

  { TvEntity }

  TvEntity = class
  public
    X, Y, Z: Double;
    constructor Create; virtual;
    procedure Clear; virtual;
    // in CalculateBoundingBox always remember to treat correctly the case of ADest=nil!!!
    // This cased is utilized to guess the size of a document even before getting a canvas to draw at
    procedure CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); virtual;
    procedure ExpandBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); // helper to help CalculateBoundingBox
    {@@ ASubpart is only valid if this routine returns vfrSubpartFound }
    function TryToSelect(APos: TPoint; var ASubpart: Cardinal): TvFindEntityResult; virtual;
    procedure Move(ADeltaX, ADeltaY: Integer); virtual;
    procedure MoveSubpart(ADeltaX, ADeltaY: Integer; ASubpart: Cardinal); virtual;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); virtual;
    function GetNormalizedPos(APage: TvVectorialPage; ANewMin, ANewMax: Double): T3DPoint;
    function GenerateDebugTree(ADestRoutine: TvDebugAddItemProc; APageItem: Pointer): Pointer; virtual;
  end;

  { TvEntityWithPen }

  TvEntityWithPen = class(TvEntity)
  public
    {@@ The global Pen for the entire entity. In the case of paths, individual
        elements might be able to override this setting. }
    Pen: TvPen;
    constructor Create; override;
    procedure ApplyPenToCanvas(ADest: TFPCustomCanvas);
  end;

  { TvEntityWithPenAndBrush }

  TvEntityWithPenAndBrush = class(TvEntityWithPen)
  public
    {@@ The global Brush for the entire entity. In the case of paths, individual
        elements might be able to override this setting. }
    Brush: TvBrush;
    constructor Create; override;
    procedure ApplyBrushToCanvas(ADest: TFPCustomCanvas);
  end;

  TvClipMode = (vcmNonzeroWindingRule, vcmEvenOddRule);

  TPath = class(TvEntityWithPenAndBrush)
  public
    Len: Integer;
    Points: TPathSegment;   // Beginning of the double-linked list
    PointsEnd: TPathSegment;// End of the double-linked list
    CurPoint: TPathSegment; // Used in PrepareForSequentialReading and Next
    ClipPath: TPath;
    ClipMode: TvClipMode;
    destructor Destroy; override;
    procedure Clear; override;
    procedure Assign(ASource: TPath);
    procedure PrepareForSequentialReading;
    function Next(): TPathSegment;
    procedure CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); override;
    procedure AppendSegment(ASegment: TPathSegment);
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
    TvText represents a text entity.

    The text starts in X, Y and grows upwards, towards a bigger Y (fpvectorial coordinates)
    or smaller Y (LCL coordinates).
    It has the opposite direction of text in the LCL TCanvas.
  }

  { TvText }

  TvText = class(TvEntityWithPenAndBrush)
  public
    Value: TStringList;
    Font: TvFont;
    constructor Create; override;
    destructor Destroy; override;
    function TryToSelect(APos: TPoint; var ASubpart: Cardinal): TvFindEntityResult; override;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
  }

  { TvCircle }

  TvCircle = class(TvEntityWithPenAndBrush)
  public
    Radius: Double;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
  }

  { TvCircularArc }

  TvCircularArc = class(TvEntityWithPenAndBrush)
  public
    Radius: Double;
    {@@ The Angle is measured in degrees in relation to the positive X axis }
    StartAngle, EndAngle: Double;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
  }

  { TvEllipse }

  TvEllipse = class(TvEntityWithPenAndBrush)
  public
    // Mandatory fields
    HorzHalfAxis: Double; // This half-axis is the horizontal one when Angle=0
    VertHalfAxis: Double; // This half-axis is the vertical one when Angle=0
    {@@ The Angle is measured in degrees in relation to the positive X axis }
    Angle: Double;
    procedure CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); override;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
   DimensionLeft ---text--- DimensionRight
                 |        |
                 |        | BaseRight
                 |
                 | BaseLeft
  }

  { TvAlignedDimension }

  TvAlignedDimension = class(TvEntityWithPen)
  public
    // Mandatory fields
    BaseLeft, BaseRight, DimensionLeft, DimensionRight: T3DPoint;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
   Vectorial images can contain raster images inside them and this entity
   represents this.

   If the Width and Height differ from the same data in the image, then
   the raster image will be stretched.

   Note that TFPCustomImage does not implement a storage, so the property
   RasterImage should be filled with either a FPImage.TFPMemoryImage or with
   a TLazIntfImage. The property RasterImage might be nil.
  }

  { TvRasterImage }

  TvRasterImage = class(TvEntity)
  public
    RasterImage: TFPCustomImage;
    Top, Left, Width, Height: Double;
    procedure InitializeWithConvertionOf3DPointsToHeightMap(APage: TvVectorialPage; AWidth, AHeight: Integer);
  end;

  { TvPoint }

  TvPoint = class(TvEntityWithPen)
  public
  end;

  { TvArrow }

  //
  // The arrow look like this:
  //
  // A<------|B
  //         |
  //         |C
  //
  // A -> X,Y,Z
  // B -> Base
  // C -> ExtraLineBase, which exists if HasExtraLine=True

  TvArrow = class(TvEntityWithPenAndBrush)
  public
    Base: T3DPoint;
    HasExtraLine: Boolean;
    ExtraLineBase: T3DPoint;
    ArrowLength: Double;
    ArrowBaseLength: Double;
    procedure CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); override;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
  end;

  {@@
    The elements bellow describe a formula

    The main element of a formula is TvFormula which contains a horizontal list of
    the elements of the formula. Those can then have sub-elements

    The formula starts in X, Y and grows downwards, towards a smaller Y
  }

  TvFormula = class;

  TvFormulaElementKind = (
    // Basic symbols
    fekVariable,  // Text is the text of the variable
    fekEqual,     // = symbol
    fekSubtraction, // - symbol
    fekMultiplication, // either a point . or a small x
    fekSum,       // + symbol
    fekPlusMinus, // The +/- symbol
    fekLessThan, // The < symbol
    fekLessOrEqualThan, // The <= symbol
    fekGreaterThan, // The > symbol
    fekGreaterOrEqualThan, // The >= symbol
    // More complex elements
    fekFraction,  // a division with Formula on the top and AdjacentFormula in the bottom
    fekRoot,      // A root. For example sqrt(something). Number gives the root, usually 2, and inside it goes a Formula
    fekPower,     // A Formula elevated to a AdjacentFormula, example: 2^5
    fekParenteses,// This is utilized to group elements. Inside it goes a Formula
    fekParentesesWithPower, // The same as parenteses, but elevated to the power of "Number"
    fekSomatory   // Sum of a variable given by Text from Number to AdjacentNumber
    );

  { TvFormulaElement }

  TvFormulaElement = class
  public
    Kind: TvFormulaElementKind;
    Text: string;
    Number: Double;
    AdjacentNumber: Double;
    Formula: TvFormula;
    AdjacentFormula: TvFormula;
  public
    Top, Left, Width, Height: Integer;
    function CalculateHeight(ADest: TFPCustomCanvas): Single; // 1.0 = the normal text height, will return for example 2.2 for 2,2 times the text height
    function CalculateWidth(ADest: TFPCustomCanvas): Integer; // in pixels
    function AsText: string;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); virtual;
    procedure GenerateDebugTree(ADestRoutine: TvDebugAddItemProc; APageItem: Pointer); virtual;
  end;

  { TvFormula }

  TvFormula = class(TvEntityWithPenAndBrush)
  private
    FCurIndex: Integer;
    SpacingBetweenElementsX: Integer;
    procedure CallbackDeleteElement(data,arg:pointer);
  protected
    FElements: TFPList; // of TvFormulaElement
  public
    Top, Left, Width, Height: Integer;
    constructor Create; override;
    destructor Destroy; override;
    //
    function GetFirstElement: TvFormulaElement;
    function GetNextElement: TvFormulaElement;
    procedure AddElement(AElement: TvFormulaElement);
    function  AddElementWithKind(AKind: TvFormulaElementKind): TvFormulaElement;
    function  AddElementWithKindAndText(AKind: TvFormulaElementKind; AText: string): TvFormulaElement;
    procedure Clear;
    //
    function CalculateHeight(ADest: TFPCustomCanvas): Single; // 1.0 = the normal text height, will return for example 2.2 for 2,2 times the text height
    function CalculateWidth(ADest: TFPCustomCanvas): Integer;
    procedure PositionElements(ADest: TFPCustomCanvas; ABaseX, ABaseY: Integer);
    procedure CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double); override;
    procedure Render(ADest: TFPCustomCanvas; ADestX: Integer = 0;
      ADestY: Integer = 0; AMulX: Double = 1.0; AMulY: Double = 1.0); override;
    function GenerateDebugTree(ADestRoutine: TvDebugAddItemProc; APageItem: Pointer): Pointer; override;
  end;

  { TvVectorialDocument }

  TvVectorialDocument = class
  private
    FOnProgress: TvProgressEvent;
    FPages: TFPList;
    FCurrentPageIndex: Integer;
    function CreateVectorialWriter(AFormat: TvVectorialFormat): TvCustomVectorialWriter;
    function CreateVectorialReader(AFormat: TvVectorialFormat): TvCustomVectorialReader;
  public
    Width, Height: Double; // in millimeters
    Name: string;
    // User-Interface information
    ZoomLevel: Double; // 1 = 100%
    { Selection fields }
    SelectedvElement: TvEntity;
    { Base methods }
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Assign(ASource: TvVectorialDocument);
    procedure AssignTo(ADest: TvVectorialDocument);
    procedure WriteToFile(AFileName: string; AFormat: TvVectorialFormat); overload;
    procedure WriteToFile(AFileName: string); overload;
    procedure WriteToStream(AStream: TStream; AFormat: TvVectorialFormat);
    procedure WriteToStrings(AStrings: TStrings; AFormat: TvVectorialFormat);
    procedure ReadFromFile(AFileName: string; AFormat: TvVectorialFormat); overload;
    procedure ReadFromFile(AFileName: string); overload;
    procedure ReadFromStream(AStream: TStream; AFormat: TvVectorialFormat);
    procedure ReadFromStrings(AStrings: TStrings; AFormat: TvVectorialFormat);
    class function GetFormatFromExtension(AFileName: string): TvVectorialFormat;
    function  GetDetailedFileFormat(): string;
    procedure GuessDocumentSize();
    procedure GuessGoodZoomLevel(AScreenSize: Integer = 500);
    { Page methods }
    function GetPage(AIndex: Integer): TvVectorialPage;
    function GetPageCount: Integer;
    function GetCurrentPage: TvVectorialPage;
    procedure SetCurrentPage(AIndex: Integer);
    function AddPage(): TvVectorialPage;
    { Data removing methods }
    procedure Clear; virtual;
    { Debug methods }
    procedure GenerateDebugTree(ADestRoutine: TvDebugAddItemProc);
    { Events }
    property OnProgress: TvProgressEvent read FOnProgress write FOnprogress;
  end;

  { TvVectorialPage }

  TvVectorialPage = class
  private
    FEntities: TFPList; // of TvEntity
    FTmpPath: TPath;
    FTmpText: TvText;
    //procedure RemoveCallback(data, arg: pointer);
    procedure ClearTmpPath();
    procedure AppendSegmentToTmpPath(ASegment: TPathSegment);
    procedure CallbackDeleteEntity(data,arg:pointer);
  public
    // Document size for page-based documents
    Width, Height: Double; // in millimeters
    // Document size for other documents
    MinX, MinY, MinZ, MaxX, MaxY, MaxZ: Double;
    Owner: TvVectorialDocument;
    { Base methods }
    constructor Create(AOwner: TvVectorialDocument); virtual;
    destructor Destroy; override;
    procedure Assign(ASource: TvVectorialPage);
    { Data reading methods }
    function  GetEntity(ANum: Cardinal): TvEntity;
    function  GetEntitiesCount: Integer;
    function  GetLastEntity(): TvEntity;
    function  FindAndSelectEntity(Pos: TPoint): TvFindEntityResult;
    { Data removing methods }
    procedure Clear; virtual;
    function  DeleteEntity(AIndex: Cardinal): Boolean;
    function  RemoveEntity(AEntity: TvEntity; AFreeAfterRemove: Boolean = True): Boolean;
    { Data writing methods }
    function AddEntity(AEntity: TvEntity): Integer;
    procedure AddPathCopyMem(APath: TPath);
    procedure StartPath(AX, AY: Double); overload;
    procedure StartPath(); overload;
    procedure AddMoveToPath(AX, AY: Double);
    procedure AddLineToPath(AX, AY: Double); overload;
    procedure AddLineToPath(AX, AY: Double; AColor: TFPColor); overload;
    procedure AddLineToPath(AX, AY, AZ: Double); overload;
    procedure GetCurrentPathPenPos(var AX, AY: Double);
    procedure AddBezierToPath(AX1, AY1, AX2, AY2, AX3, AY3: Double); overload;
    procedure AddBezierToPath(AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3, AZ3: Double); overload;
    procedure SetBrushColor(AColor: TFPColor);
    procedure SetBrushStyle(AStyle: TFPBrushStyle);
    procedure SetPenColor(AColor: TFPColor);
    procedure SetPenStyle(AStyle: TFPPenStyle);
    procedure SetPenWidth(AWidth: Integer);
    procedure SetClipPath(AClipPath: TPath; AClipMode: TvClipMode);
    procedure EndPath();
    procedure AddText(AX, AY, AZ: Double; FontName: string; FontSize: integer; AText: utf8string); overload;
    procedure AddText(AX, AY: Double; AStr: utf8string); overload;
    procedure AddText(AX, AY, AZ: Double; AStr: utf8string); overload;
    procedure AddCircle(ACenterX, ACenterY, ARadius: Double);
    procedure AddCircularArc(ACenterX, ACenterY, ARadius, AStartAngle, AEndAngle: Double; AColor: TFPColor);
    procedure AddEllipse(CenterX, CenterY, HorzHalfAxis, VertHalfAxis, Angle: Double);
    // Dimensions
    procedure AddAlignedDimension(BaseLeft, BaseRight, DimLeft, DimRight: T3DPoint);
    //
    function AddPoint(AX, AY, AZ: Double): TvPoint;
    { Debug methods }
    procedure GenerateDebugTree(ADestRoutine: TvDebugAddItemProc; APageItem: Pointer);
    //
    property Entities[AIndex: Cardinal]: TvEntity read GetEntity;
  end;

  {@@ TvVectorialReader class reference type }

  TvVectorialReaderClass = class of TvCustomVectorialReader;

  { TvCustomVectorialReader }

  TvCustomVectorialReader = class
  public
    { General reading methods }
    constructor Create; virtual;
    procedure ReadFromFile(AFileName: string; AData: TvVectorialDocument); virtual;
    procedure ReadFromStream(AStream: TStream; AData: TvVectorialDocument); virtual;
    procedure ReadFromStrings(AStrings: TStrings; AData: TvVectorialDocument); virtual;
  end;

  {@@ TvVectorialWriter class reference type }

  TvVectorialWriterClass = class of TvCustomVectorialWriter;

  {@@ TvCustomVectorialWriter }

  { TvCustomVectorialWriter }

  TvCustomVectorialWriter = class
  public
    { General writing methods }
    constructor Create; virtual;
    procedure WriteToFile(AFileName: string; AData: TvVectorialDocument); virtual;
    procedure WriteToStream(AStream: TStream; AData: TvVectorialDocument); virtual;
    procedure WriteToStrings(AStrings: TStrings; AData: TvVectorialDocument); virtual;
  end;

  {@@ List of registered formats }

  TvVectorialFormatData = record
    ReaderClass: TvVectorialReaderClass;
    WriterClass: TvVectorialWriterClass;
    ReaderRegistered: Boolean;
    WriterRegistered: Boolean;
    Format: TvVectorialFormat;
  end;

var
  GvVectorialFormats: array of TvVectorialFormatData;

procedure RegisterVectorialReader(
  AReaderClass: TvVectorialReaderClass;
  AFormat: TvVectorialFormat);
procedure RegisterVectorialWriter(
  AWriterClass: TvVectorialWriterClass;
  AFormat: TvVectorialFormat);
function Make2DPoint(AX, AY: Double): T3DPoint;

implementation

uses fpvutils;

const
  Str_Error_Nil_Path = ' The program attempted to add a segment before creating a path';

{@@
  Registers a new reader for a format
}
procedure RegisterVectorialReader(
  AReaderClass: TvVectorialReaderClass;
  AFormat: TvVectorialFormat);
var
  i, len: Integer;
  FormatInTheList: Boolean;
begin
  len := Length(GvVectorialFormats);
  FormatInTheList := False;

  { First search for the format in the list }
  for i := 0 to len - 1 do
  begin
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].ReaderRegistered then
       raise Exception.Create('RegisterVectorialReader: Reader class for format ' {+ AFormat} + ' already registered.');

      GvVectorialFormats[i].ReaderRegistered := True;
      GvVectorialFormats[i].ReaderClass := AReaderClass;

      FormatInTheList := True;
      Break;
    end;
  end;

  { If not already in the list, then add it }
  if not FormatInTheList then
  begin
    SetLength(GvVectorialFormats, len + 1);

    GvVectorialFormats[len].ReaderClass := AReaderClass;
    GvVectorialFormats[len].WriterClass := nil;
    GvVectorialFormats[len].ReaderRegistered := True;
    GvVectorialFormats[len].WriterRegistered := False;
    GvVectorialFormats[len].Format := AFormat;
  end;
end;

{@@
  Registers a new writer for a format
}
procedure RegisterVectorialWriter(
  AWriterClass: TvVectorialWriterClass;
  AFormat: TvVectorialFormat);
var
  i, len: Integer;
  FormatInTheList: Boolean;
begin
  len := Length(GvVectorialFormats);
  FormatInTheList := False;

  { First search for the format in the list }
  for i := 0 to len - 1 do
  begin
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].WriterRegistered then
       raise Exception.Create('RegisterVectorialWriter: Writer class for format ' + {AFormat +} ' already registered.');

      GvVectorialFormats[i].WriterRegistered := True;
      GvVectorialFormats[i].WriterClass := AWriterClass;

      FormatInTheList := True;
      Break;
    end;
  end;

  { If not already in the list, then add it }
  if not FormatInTheList then
  begin
    SetLength(GvVectorialFormats, len + 1);

    GvVectorialFormats[len].ReaderClass := nil;
    GvVectorialFormats[len].WriterClass := AWriterClass;
    GvVectorialFormats[len].ReaderRegistered := False;
    GvVectorialFormats[len].WriterRegistered := True;
    GvVectorialFormats[len].Format := AFormat;
  end;
end;

function Make2DPoint(AX, AY: Double): T3DPoint;
begin
  Result.X := AX;
  Result.Y := AY;
  Result.Z := 0;
end;

{ TvEntity }

constructor TvEntity.Create;
begin
end;

procedure TvEntity.Clear;
begin
  X := 0.0;
  Y := 0.0;
  Z := 0.0;
end;

procedure TvEntity.CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double);
begin
  ALeft := X;
  ATop := Y;
  ARight := X+1;
  ABottom := Y+1;
end;

procedure TvEntity.ExpandBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double);
var
  lLeft, lTop, lRight, lBottom: Double;
begin
  CalculateBoundingBox(ADest, lLeft, lTop, lRight, lBottom);
  if lLeft < ALeft then ALeft := lLeft;
  if lTop < ATop then ATop := lTop;
  if lRight > ARight then ARight := lRight;
  if lBottom > ABottom then ABottom := lBottom;
end;

function TvEntity.TryToSelect(APos: TPoint; var ASubpart: Cardinal): TvFindEntityResult;
begin
  Result := vfrNotFound;
end;

procedure TvEntity.Move(ADeltaX, ADeltaY: Integer);
begin
  X := X + ADeltaX;
  Y := Y + ADeltaY;
end;

procedure TvEntity.MoveSubpart(ADeltaX, ADeltaY: Integer;
  ASubpart: Cardinal);
begin

end;

procedure TvEntity.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);
begin

end;

function TvEntity.GetNormalizedPos(APage: TvVectorialPage; ANewMin,
  ANewMax: Double): T3DPoint;
begin
  Result.X := (X - APage.MinX) * (ANewMax - ANewMin) / (APage.MaxX - APage.MinX) + ANewMin;
  Result.Y := (Y - APage.MinY) * (ANewMax - ANewMin) / (APage.MaxY - APage.MinY) + ANewMin;
  Result.Z := (Z - APage.MinZ) * (ANewMax - ANewMin) / (APage.MaxZ - APage.MinZ) + ANewMin;
end;

function TvEntity.GenerateDebugTree(ADestRoutine: TvDebugAddItemProc;
  APageItem: Pointer): Pointer;
var
  lStr: string;
begin
  lStr := Format('[%s]', [Self.ClassName]);
  Result := ADestRoutine(lStr, APageItem);
end;

{ TvEntityWithPen }

constructor TvEntityWithPen.Create;
begin
  inherited Create;
  Pen.Style := psSolid;
  Pen.Color := colBlack;
  Pen.Width := 1;
end;

procedure TvEntityWithPen.ApplyPenToCanvas(ADest: TFPCustomCanvas);
begin
  ADest.Pen.FPColor := Pen.Color;
  ADest.Pen.Width := 1;//Pen.Width;
  ADest.Pen.Style := Pen.Style;
end;

{ TvEntityWithPenAndBrush }

constructor TvEntityWithPenAndBrush.Create;
begin
  inherited Create;
  Brush.Style := bsClear;
  Brush.Color := colBlue;
end;

procedure TvEntityWithPenAndBrush.ApplyBrushToCanvas(ADest: TFPCustomCanvas);
begin
  ADest.Brush.FPColor := Brush.Color;
  ADest.Brush.Style := Brush.Style;
end;

{ TPath }

//GM: Follow the path to cleanly release the chained list!
destructor TPath.Destroy;
begin
  Clear;
  inherited Destroy;
end;

procedure TPath.Clear;
var
  p, pp, np: TPathSegment;
begin
  p:=PointsEnd;
  if (p<>nil) then
  begin
    np:=p.Next;
    while (p<>nil) do
    begin
      pp:=p.Previous;
      p.Next:=nil;
      p.Previous:=nil;
      FreeAndNil(p);
      p:=pp;
    end;
    p:=np;
    while (p<>nil) do
    begin
      np:=p.Next;
      p.Next:=nil;
      p.Previous:=nil;
      FreeAndNil(p);
      p:=np;
    end;
  end;
  PointsEnd:=nil;
  Points:=nil;

  inherited Clear;
end;

procedure TPath.Assign(ASource: TPath);
begin
  Len := ASource.Len;
  Points := ASource.Points;
  PointsEnd := ASource.PointsEnd;
  CurPoint := ASource.CurPoint;
  Pen := ASource.Pen;
  Brush := ASource.Brush;
  ClipPath := ASource.ClipPath;
  ClipMode := ASource.ClipMode;
end;

procedure TPath.PrepareForSequentialReading;
begin
  CurPoint := nil;
end;

function TPath.Next(): TPathSegment;
begin
  if CurPoint = nil then Result := Points
  else Result := CurPoint.Next;

  CurPoint := Result;
end;

procedure TPath.CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double);
var
  lSegment: TPathSegment;
  l2DSegment: T2DSegment;
  lFirstValue: Boolean = True;
begin
  inherited CalculateBoundingBox(ADest, ALeft, ATop, ARight, ABottom);

  PrepareForSequentialReading();
  lSegment := Next();
  while lSegment <> nil do
  begin
    if lSegment is T2DSegment then
    begin
      l2DSegment := T2DSegment(lSegment);
      if lFirstValue then
      begin
        ALeft := l2DSegment.X;
        ATop := l2DSegment.Y;
        ARight := l2DSegment.X;
        ABottom := l2DSegment.Y;
        lFirstValue := False;
      end
      else
      begin
        if l2DSegment.X < ALeft then ALeft := l2DSegment.X;
        if l2DSegment.Y < ATop then ATop := l2DSegment.Y;
        if l2DSegment.X > ARight then ARight := l2DSegment.X;
        if l2DSegment.Y > ABottom then ABottom := l2DSegment.Y;
      end;
    end;

    lSegment := Next();
  end;
end;

procedure TPath.AppendSegment(ASegment: TPathSegment);
var
  L: Integer;
begin
  // Check if we are the first segment in the tmp path
  if PointsEnd = nil then
  begin
    if Len <> 0 then
      Exception.Create('[TPath.AppendSegment] Assertion failed Len <> 0 with PointsEnd = nil');

    Points := ASegment;
    PointsEnd := ASegment;
    Len := 1;
    Exit;
  end;

  L := Len;
  Inc(Len);

  // Adds the element to the end of the list
  PointsEnd.Next := ASegment;
  ASegment.Previous := PointsEnd;
  PointsEnd := ASegment;
end;

procedure TPath.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  j, k: Integer;
  PosX, PosY: Double; // Not modified by ADestX, etc
  CoordX, CoordY: Integer;
  CurSegment: TPathSegment;
  Cur2DSegment: T2DSegment absolute CurSegment;
  Cur2DBSegment: T2DBezierSegment absolute CurSegment;
  // For bezier
  CurX, CurY: Integer; // Not modified by ADestX, etc
  CoordX2, CoordY2, CoordX3, CoordY3, CoordX4, CoordY4: Integer;
  CurveLength: Integer;
  t: Double;
  // For polygons
  Points: array of TPoint;
  // Clipping Region
  {$ifdef USE_LCL_CANVAS}
  ClipRegion, OldClipRegion: HRGN;
  ACanvas: TCanvas absolute ADest;
  {$endif}
begin
  PosX := 0;
  PosY := 0;
  ADest.Brush.Style := bsClear;

  ADest.MoveTo(ADestX, ADestY);

  // Set the path Pen and Brush options
  ADest.Pen.Style := Pen.Style;
  ADest.Pen.Width := Round(Pen.Width * AMulX);
  if ADest.Pen.Width < 1 then ADest.Pen.Width := 1;
  if (Pen.Width <= 2) and (ADest.Pen.Width > 2) then ADest.Pen.Width := 2;
  if (Pen.Width <= 5) and (ADest.Pen.Width > 5) then ADest.Pen.Width := 5;
  ADest.Pen.FPColor := Pen.Color;
  ADest.Brush.FPColor := Brush.Color;

  // Prepare the Clipping Region, if any
  {$ifdef USE_CANVAS_CLIP_REGION}
  if ClipPath <> nil then
  begin
    OldClipRegion := LCLIntf.CreateEmptyRegion();
    GetClipRgn(ACanvas.Handle, OldClipRegion);
    ClipRegion := ConvertPathToRegion(ClipPath, ADestX, ADestY, AMulX, AMulY);
    SelectClipRgn(ACanvas.Handle, ClipRegion);
    DeleteObject(ClipRegion);
    // debug info
    {$ifdef DEBUG_CANVAS_CLIP_REGION}
    ConvertPathToPoints(CurPath.ClipPath, ADestX, ADestY, AMulX, AMulY, Points);
    ACanvas.Polygon(Points);
    {$endif}
  end;
  {$endif}

  //
  // For solid paths, draw a polygon for the main internal area
  //
  if Brush.Style <> bsClear then
  begin
    PrepareForSequentialReading;

    {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
    Write(' Solid Path Internal Area');
    {$endif}
    ADest.Brush.Style := Brush.Style;

    SetLength(Points, Len);

    for j := 0 to Len - 1 do
    begin
      //WriteLn('j = ', j);
      CurSegment := TPathSegment(Next());

      CoordX := CoordToCanvasX(Cur2DSegment.X);
      CoordY := CoordToCanvasY(Cur2DSegment.Y);

      Points[j].X := CoordX;
      Points[j].Y := CoordY;

      {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
      Write(Format(' P%d,%d', [CoordY, CoordY]));
      {$endif}
    end;

    ADest.Polygon(Points);

    {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
    Write(' Now the details ');
    {$endif}
  end;

  //
  // For other paths, draw more carefully
  //
  PrepareForSequentialReading;

  for j := 0 to Len - 1 do
  begin
    //WriteLn('j = ', j);
    CurSegment := TPathSegment(Next());

    case CurSegment.SegmentType of
    stMoveTo:
    begin
      CoordX := CoordToCanvasX(Cur2DSegment.X);
      CoordY := CoordToCanvasY(Cur2DSegment.Y);
      ADest.MoveTo(CoordX, CoordY);
      PosX := Cur2DSegment.X;
      PosY := Cur2DSegment.Y;
      {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
      Write(Format(' M%d,%d', [CoordY, CoordY]));
      {$endif}
    end;
    // This element can override temporarely the Pen
    st2DLineWithPen:
    begin
      ADest.Pen.FPColor := T2DSegmentWithPen(Cur2DSegment).Pen.Color;

      CoordX := CoordToCanvasX(PosX);
      CoordY := CoordToCanvasY(PosY);
      CoordX2 := CoordToCanvasX(Cur2DSegment.X);
      CoordY2 := CoordToCanvasY(Cur2DSegment.Y);
      ADest.Line(CoordX, CoordY, CoordX2, CoordY2);

      PosX := Cur2DSegment.X;
      PosY := Cur2DSegment.Y;

      ADest.Pen.FPColor := Pen.Color;

      {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
      Write(Format(' L%d,%d', [CoordToCanvasX(Cur2DSegment.X), CoordToCanvasY(Cur2DSegment.Y)]));
      {$endif}
    end;
    st2DLine, st3DLine:
    begin
      CoordX := CoordToCanvasX(PosX);
      CoordY := CoordToCanvasY(PosY);
      CoordX2 := CoordToCanvasX(Cur2DSegment.X);
      CoordY2 := CoordToCanvasY(Cur2DSegment.Y);
      ADest.Line(CoordX, CoordY, CoordX2, CoordY2);
      PosX := Cur2DSegment.X;
      PosY := Cur2DSegment.Y;
      {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
      Write(Format(' L%d,%d', [CoordX, CoordY]));
      {$endif}
    end;
    { To draw a bezier we need to divide the interval in parts and make
      lines between this parts }
    st2DBezier, st3DBezier:
    begin
      CoordX := CoordToCanvasX(PosX);
      CoordY := CoordToCanvasY(PosY);
      CoordX2 := CoordToCanvasX(Cur2DBSegment.X2);
      CoordY2 := CoordToCanvasY(Cur2DBSegment.Y2);
      CoordX3 := CoordToCanvasX(Cur2DBSegment.X3);
      CoordY3 := CoordToCanvasY(Cur2DBSegment.Y3);
      CoordX4 := CoordToCanvasX(Cur2DBSegment.X);
      CoordY4 := CoordToCanvasY(Cur2DBSegment.Y);
      SetLength(Points, 0);
      AddBezierToPoints(
        Make2DPoint(CoordX, CoordY),
        Make2DPoint(CoordX2, CoordY2),
        Make2DPoint(CoordX3, CoordY3),
        Make2DPoint(CoordX4, CoordY4),
        Points
      );

      ADest.Brush.Style := Brush.Style;
      if Length(Points) >= 3 then
        ADest.Polygon(Points);

      PosX := Cur2DSegment.X;
      PosY := Cur2DSegment.Y;

      {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
      Write(Format(' ***C%d,%d %d,%d %d,%d %d,%d',
        [CoordToCanvasX(PosX), CoordToCanvasY(PosY),
         CoordToCanvasX(Cur2DBSegment.X2), CoordToCanvasY(Cur2DBSegment.Y2),
         CoordToCanvasX(Cur2DBSegment.X3), CoordToCanvasY(Cur2DBSegment.Y3),
         CoordToCanvasX(Cur2DBSegment.X), CoordToCanvasY(Cur2DBSegment.Y)]));
      {$endif}
    end;
    end;
  end;
  {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
  WriteLn('');
  {$endif}

  // Restores the previous Clip Region
  {$ifdef USE_CANVAS_CLIP_REGION}
  if ClipPath <> nil then
  begin
    SelectClipRgn(ACanvas.Handle, OldClipRegion); //Using OldClipRegion crashes in Qt
  end;
  {$endif}
end;

{ TvText }

constructor TvText.Create;
begin
  inherited Create;
  Value := TStringList.Create;
end;

destructor TvText.Destroy;
begin
  Value.Free;
  inherited Destroy;
end;

function TvText.TryToSelect(APos: TPoint; var ASubpart: Cardinal): TvFindEntityResult;
var
  lProximityFactor: Integer;
begin
  lProximityFactor := 5;
  if (APos.X > X - lProximityFactor) and (APos.X < X + lProximityFactor)
    and (APos.Y > Y - lProximityFactor) and (APos.Y < Y + lProximityFactor) then
    Result := vfrFound
  else Result := vfrNotFound;
end;

procedure TvText.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  i: Integer;
  {$ifdef USE_LCL_CANVAS}
  ALCLDest: TCanvas absolute ADest;
  {$endif}
  //
  LowerDim: T3DPoint;
begin
  ADest.Font.Size := Round(AmulX * Font.Size);
  ADest.Pen.Style := psSolid;
  ADest.Pen.FPColor := colBlack;
  ADest.Brush.Style := bsClear;
  {$ifdef USE_LCL_CANVAS}
  ALCLDest.Font.Orientation := Round(Font.Orientation * 16);
  {$endif}

  // TvText supports multiple lines
  for i := 0 to Value.Count - 1 do
  begin
    if Font.Size = 0 then
      LowerDim.Y := CoordToCanvasY(Y) + 12 * (i - Value.Count)
    else
    begin
      LowerDim.Y := Y + Font.Size * 1.2 * (Value.Count - i);
      LowerDim.Y := CoordToCanvasY(LowerDim.Y);
    end;

    ADest.TextOut(CoordToCanvasX(X), Round(LowerDim.Y), Value.Strings[i]);
  end;
end;

{ TvCircle }

procedure TvCircle.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

begin
  ADest.Ellipse(
    CoordToCanvasX(X - Radius),
    CoordToCanvasY(Y - Radius),
    CoordToCanvasX(X + Radius),
    CoordToCanvasY(Y + Radius)
    );
end;

{ TvCircularArc }

procedure TvCircularArc.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  FinalStartAngle, FinalEndAngle: double;
  BoundsLeft, BoundsTop, BoundsRight, BoundsBottom,
   IntStartAngle, IntAngleLength, IntTmp: Integer;
  {$ifdef USE_LCL_CANVAS}
  ALCLDest: TCanvas absolute ADest;
  {$endif}
begin
  {$ifdef USE_LCL_CANVAS}
  // ToDo: Consider a X axis inversion
  // If the Y axis is inverted, then we need to mirror our angles as well
  BoundsLeft := CoordToCanvasX(X - Radius);
  BoundsTop := CoordToCanvasY(Y - Radius);
  BoundsRight := CoordToCanvasX(X + Radius);
  BoundsBottom := CoordToCanvasY(Y + Radius);
  {if AMulY > 0 then
  begin}
    FinalStartAngle := StartAngle;
    FinalEndAngle := EndAngle;
  {end
  else // AMulY is negative
  begin
    // Inverting the angles generates the correct result for Y axis inversion
    if CurArc.EndAngle = 0 then FinalStartAngle := 0
    else FinalStartAngle := 360 - 1* CurArc.EndAngle;
    if CurArc.StartAngle = 0 then FinalEndAngle := 0
    else FinalEndAngle := 360 - 1* CurArc.StartAngle;
  end;}
  IntStartAngle := Round(16*FinalStartAngle);
  IntAngleLength := Round(16*(FinalEndAngle - FinalStartAngle));
  // On Gtk2 and Carbon, the Left really needs to be to the Left of the Right position
  // The same for the Top and Bottom
  // On Windows it works fine either way
  // On Gtk2 if the positions are inverted then the arcs are screwed up
  // In Carbon if the positions are inverted, then the arc is inverted
  if BoundsLeft > BoundsRight then
  begin
    IntTmp := BoundsLeft;
    BoundsLeft := BoundsRight;
    BoundsRight := IntTmp;
  end;
  if BoundsTop > BoundsBottom then
  begin
    IntTmp := BoundsTop;
    BoundsTop := BoundsBottom;
    BoundsBottom := IntTmp;
  end;
  // Arc(ALeft, ATop, ARight, ABottom, Angle16Deg, Angle16DegLength: Integer);
  {$ifdef FPVECTORIAL_TOCANVAS_DEBUG}
//    WriteLn(Format('Drawing Arc Center=%f,%f Radius=%f StartAngle=%f AngleLength=%f',
//      [CurArc.CenterX, CurArc.CenterY, CurArc.Radius, IntStartAngle/16, IntAngleLength/16]));
  {$endif}
  ADest.Pen.FPColor := Pen.Color;
  ALCLDest.Arc(
    BoundsLeft, BoundsTop, BoundsRight, BoundsBottom,
    IntStartAngle, IntAngleLength
    );
  ADest.Pen.FPColor := colBlack;
  // Debug info
//      {$define FPVECTORIALDEBUG}
//      {$ifdef FPVECTORIALDEBUG}
//      WriteLn(Format('Drawing Arc x1y1=%d,%d x2y2=%d,%d start=%d end=%d',
//        [BoundsLeft, BoundsTop, BoundsRight, BoundsBottom, IntStartAngle, IntAngleLength]));
//      {$endif}
{      ADest.TextOut(CoordToCanvasX(CurArc.CenterX), CoordToCanvasY(CurArc.CenterY),
    Format('R=%d S=%d L=%d', [Round(CurArc.Radius*AMulX), Round(FinalStartAngle),
    Abs(Round((FinalEndAngle - FinalStartAngle)))]));
  ADest.Pen.Color := TColor($DDDDDD);
  ADest.Rectangle(
    BoundsLeft, BoundsTop, BoundsRight, BoundsBottom);
  ADest.Pen.Color := clBlack;}
  {$endif}
end;

{ TvEllipse }

procedure TvEllipse.CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight, ABottom: Double);
var
  t, tmp: Double;
begin
  // First do the trivial
  ALeft := X - HorzHalfAxis;
  ARight := X + HorzHalfAxis;
  ATop := Y - VertHalfAxis;
  ABottom := Y + VertHalfAxis;
  {
    To calculate the bounding rectangle we can do this:

    Ellipse equations:You could try using the parametrized equations for an ellipse rotated at an arbitrary angle:

    x = CenterX + MajorHalfAxis*cos(t)*cos(Angle) - MinorHalfAxis*sin(t)*sin(Angle)
    y = CenterY + MinorHalfAxis*sin(t)*cos(Angle) + MajorHalfAxis*cos(t)*sin(Angle)

    You can then differentiate and solve for gradient = 0:
    0 = dx/dt = -MajorHalfAxis*sin(t)*cos(Angle) - MinorHalfAxis*cos(t)*sin(Angle)
    =>
    tan(t) = -MinorHalfAxis*tan(Angle)/MajorHalfAxis
    =>
    t = cotang(-MinorHalfAxis*tan(Angle)/MajorHalfAxis)

    On the other axis:

    0 = dy/dt = b*cos(t)*cos(phi) - a*sin(t)*sin(phi)
    =>
    tan(t) = b*cot(phi)/a
  }
  if Angle <> 0.0 then
  begin
    t := cotan(-VertHalfAxis*tan(Angle)/HorzHalfAxis);
    tmp := X + HorzHalfAxis*cos(t)*cos(Angle) - VertHalfAxis*sin(t)*sin(Angle);
    ARight := Round(tmp);
  end;
end;

procedure TvEllipse.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  PointList: array[0..6] of TPoint;
  f: TPoint;
  dk, x1, x2, y1, y2: Integer;
  fx1, fy1, fx2, fy2: Double;
  {$ifdef USE_LCL_CANVAS}
  ALCLDest: TCanvas absolute ADest;
  {$endif}
begin
  ApplyPenToCanvas(ADest);

  CalculateBoundingBox(ADest, fx1, fy1, fx2, fy2);
  x1 := CoordToCanvasX(fx1);
  x2 := CoordToCanvasX(fx2);
  y1 := CoordToCanvasY(fy1);
  y2 := CoordToCanvasY(fy2);

  {$ifdef USE_LCL_CANVAS}
  if Angle <> 0 then
  begin
    dk := Round(0.654 * Abs(y2-y1));
    f.x := Round(X);
    f.y := Round(Y - 1);
    PointList[0] := Rotate2DPoint(Point(x1, f.y), f, Angle) ;  // Startpoint
    PointList[1] := Rotate2DPoint(Point(x1,  f.y - dk), f, Angle);
    //Controlpoint of Startpoint first part
    PointList[2] := Rotate2DPoint(Point(x2- 1,  f.y - dk), f, Angle);
    //Controlpoint of secondpoint first part
    PointList[3] := Rotate2DPoint(Point(x2 -1 , f.y), f, Angle);
    // Firstpoint of secondpart
    PointList[4] := Rotate2DPoint(Point(x2-1 , f.y + dk), f, Angle);
    // Controllpoint of secondpart firstpoint
    PointList[5] := Rotate2DPoint(Point(x1, f.y +  dk), f, Angle);
    // Conrollpoint of secondpart endpoint
    PointList[6] := PointList[0];   // Endpoint of
     // Back to the startpoint
    ALCLDest.PolyBezier(Pointlist[0]);
  end
  else
  {$endif}
  begin
    ADest.Ellipse(x1, y1, x2, y2);
  end;
end;

{ TvAlignedDimension }

procedure TvAlignedDimension.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  Points: array of TPoint;
  UpperDim, LowerDim: T3DPoint;
  {$ifdef USE_LCL_CANVAS}
  ALCLDest: TCanvas absolute ADest;
  {$endif}
begin
  //
  // Draws this shape:
  // vertical     horizontal
  // ___
  // | |     or   ---| X cm
  //   |           --|
  // Which marks the dimension
  ADest.MoveTo(CoordToCanvasX(BaseRight.X), CoordToCanvasY(BaseRight.Y));
  ADest.LineTo(CoordToCanvasX(DimensionRight.X), CoordToCanvasY(DimensionRight.Y));
  ADest.LineTo(CoordToCanvasX(DimensionLeft.X), CoordToCanvasY(DimensionLeft.Y));
  ADest.LineTo(CoordToCanvasX(BaseLeft.X), CoordToCanvasY(BaseLeft.Y));
  // Now the arrows
  // horizontal
  SetLength(Points, 3);
  if DimensionRight.Y = DimensionLeft.Y then
  begin
    ADest.Brush.FPColor := colBlack;
    ADest.Brush.Style := bsSolid;
    // Left arrow
    Points[0] := Point(CoordToCanvasX(DimensionLeft.X), CoordToCanvasY(DimensionLeft.Y));
    Points[1] := Point(Points[0].X + 7, Points[0].Y - 3);
    Points[2] := Point(Points[0].X + 7, Points[0].Y + 3);
    ADest.Polygon(Points);
    // Right arrow
    Points[0] := Point(CoordToCanvasX(DimensionRight.X), CoordToCanvasY(DimensionRight.Y));
    Points[1] := Point(Points[0].X - 7, Points[0].Y - 3);
    Points[2] := Point(Points[0].X - 7, Points[0].Y + 3);
    ADest.Polygon(Points);
    ADest.Brush.Style := bsClear;
    // Dimension text
    Points[0].X := CoordToCanvasX((DimensionLeft.X+DimensionRight.X)/2);
    Points[0].Y := CoordToCanvasY(DimensionLeft.Y);
    LowerDim.X := DimensionRight.X-DimensionLeft.X;
    ADest.Font.Size := 10;
    ADest.TextOut(Points[0].X, Points[0].Y, Format('%.1f', [LowerDim.X]));
  end
  else
  begin
    ADest.Brush.FPColor := colBlack;
    ADest.Brush.Style := bsSolid;
    // There is no upper/lower preference for DimensionLeft/Right, so we need to check
    if DimensionLeft.Y > DimensionRight.Y then
    begin
      UpperDim := DimensionLeft;
      LowerDim := DimensionRight;
    end
    else
    begin
      UpperDim := DimensionRight;
      LowerDim := DimensionLeft;
    end;
    // Upper arrow
    Points[0] := Point(CoordToCanvasX(UpperDim.X), CoordToCanvasY(UpperDim.Y));
    Points[1] := Point(Points[0].X + Round(AMulX), Points[0].Y - Round(AMulY*3));
    Points[2] := Point(Points[0].X - Round(AMulX), Points[0].Y - Round(AMulY*3));
    ADest.Polygon(Points);
    // Lower arrow
    Points[0] := Point(CoordToCanvasX(LowerDim.X), CoordToCanvasY(LowerDim.Y));
    Points[1] := Point(Points[0].X + Round(AMulX), Points[0].Y + Round(AMulY*3));
    Points[2] := Point(Points[0].X - Round(AMulX), Points[0].Y + Round(AMulY*3));
    ADest.Polygon(Points);
    ADest.Brush.Style := bsClear;
    // Dimension text
    Points[0].X := CoordToCanvasX(DimensionLeft.X);
    Points[0].Y := CoordToCanvasY((DimensionLeft.Y+DimensionRight.Y)/2);
    LowerDim.Y := DimensionRight.Y-DimensionLeft.Y;
    if LowerDim.Y < 0 then LowerDim.Y := -1 * LowerDim.Y;
    ADest.Font.Size := 10;
    ADest.TextOut(Points[0].X, Points[0].Y, Format('%.1f', [LowerDim.Y]));
  end;
  SetLength(Points, 0);
{      // Debug info
  ADest.TextOut(CoordToCanvasX(CurDim.BaseRight.X), CoordToCanvasY(CurDim.BaseRight.Y), 'BR');
  ADest.TextOut(CoordToCanvasX(CurDim.DimensionRight.X), CoordToCanvasY(CurDim.DimensionRight.Y), 'DR');
  ADest.TextOut(CoordToCanvasX(CurDim.DimensionLeft.X), CoordToCanvasY(CurDim.DimensionLeft.Y), 'DL');
  ADest.TextOut(CoordToCanvasX(CurDim.BaseLeft.X), CoordToCanvasY(CurDim.BaseLeft.Y), 'BL');}
end;

{ TvRasterImage }

procedure TvRasterImage.InitializeWithConvertionOf3DPointsToHeightMap(APage: TvVectorialPage; AWidth, AHeight: Integer);
var
  lEntity: TvEntity;
  i: Integer;
  lPos: TPoint;
  lValue: TFPColor;
  PreviousValue: Word;
  PreviousCount: Integer;
begin
  // First setup the map and initialize it
  if RasterImage <> nil then RasterImage.Free;
  RasterImage := TFPMemoryImage.create(AWidth, AHeight);

  // Now go through all points and attempt to fit them to our grid
  for i := 0 to APage.GetEntitiesCount - 1 do
  begin
    lEntity := APage.GetEntity(i);
    if lEntity is TvPoint then
    begin
      lPos.X := Round((lEntity.X - APage.MinX) * AWidth / (APage.MaxX - APage.MinX));
      lPos.Y := Round((lEntity.Y - APage.MinY) * AHeight / (APage.MaxY - APage.MinY));

      if lPos.X >= AWidth then lPos.X := AWidth-1;
      if lPos.Y >= AHeight then lPos.Y := AHeight-1;
      if lPos.X < 0 then lPos.X := 0;
      if lPos.Y < 0 then lPos.Y := 0;

      // Calculate the height of this point
      PreviousValue := lValue.Red;
      lValue.Red := Round((lEntity.Z - APage.MinZ) * $FFFF / (APage.MaxZ - APage.MinZ));

      // And apply it as a fraction of the total number of points which fall in this square
      // we store the number of points in the Alpha channel
      PreviousCount := lValue.Alpha div $100;
      lValue.Red := Round((PreviousCount * PreviousValue + lValue.Red) / (PreviousCount + 1));

      lValue.Green := lValue.Red;
      lValue.Blue := lValue.Red;
      lValue.Alpha := lValue.Alpha + $100;
      //lValue.alpha:=;
      RasterImage.Colors[lPos.X, lPos.Y] := lValue;
    end;
  end;
end;

{ TvArrow }

procedure TvArrow.CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop,
  ARight, ABottom: Double);
begin

end;

procedure TvArrow.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);

  function CoordToCanvasX(ACoord: Double): Integer;
  begin
    Result := Round(ADestX + AmulX * ACoord);
  end;

  function CoordToCanvasY(ACoord: Double): Integer;
  begin
    Result := Round(ADestY + AmulY * ACoord);
  end;

var
  lArrow, lBase, lExtraBase: TPoint;
  lPointD, lPointE, lPointF: T3DPoint;
  lPoints: array[0..2] of TPoint;
  AlfaAngle: Double;
begin
  ApplyPenToCanvas(ADest);
  ApplyBrushToCanvas(ADest);

  lArrow.X := CoordToCanvasX(X);
  lArrow.Y := CoordToCanvasY(Y);
  lBase.X := CoordToCanvasX(Base.X);
  lBase.Y := CoordToCanvasY(Base.Y);
  lExtraBase.X := CoordToCanvasX(ExtraLineBase.X);
  lExtraBase.Y := CoordToCanvasY(ExtraLineBase.Y);

  // Start with the lines

  ADest.Line(lArrow, lBase);

  if HasExtraLine then
    ADest.Line(lBase, lExtraBase);

  // Now draw the arrow head
  lPoints[0].X := CoordToCanvasX(X);
  lPoints[0].Y := CoordToCanvasY(Y);
  //
  // Here a lot of trigonometry comes to play, it is hard to explain in text, but in essence
  //
  // A line L is formed by the points A (Arrow head) and B (Base)
  // Our smaller triangle starts at a point D in this line which has length ArrowLength counting from A
  // This forms a rectangle triangle with a line paralel to the X axis
  // Alfa is the angle between A and the line parallel to the X axis
  //
  // This brings this equations:
  // AlfaAngle := arctg((B.Y - A.Y) / (B.X - A.X));
  // Sin(Alfa) := (D.Y - A.Y) / ArrowLength
  // Cos(Alfa) := (D.X - A.X) / ArrowLength
  //
  // Then at this point D we start a line perpendicular to the line L
  // And with this line we progress a length of ArrowBaseLength/2
  // This line, the D point and a line parallel to the Y axis for another
  // rectangle triangle with the same Alfa angle at the point D
  // The point at the end of the hipotenuse of this triangle is our point E
  // So we have more equations:
  //
  // Sin(Alfa) := (E.x - D.X) / (ArrowBaseLength/2)
  // Cos(Alfa) := (E.Y - D.Y) / (ArrowBaseLength/2)
  //
  // And the same in the opposite direction for our point F:
  //
  // Sin(Alfa) := (D.X - F.X) / (ArrowBaseLength/2)
  // Cos(Alfa) := (D.Y - F.Y) / (ArrowBaseLength/2)
  //
  AlfaAngle := ArcTan((Base.Y - Y) / (Base.X - X));
  lPointD.Y := Sin(AlfaAngle) * ArrowLength + Y;
  lPointD.X := Cos(AlfaAngle) * ArrowLength + X;
  lPointE.X := Sin(AlfaAngle) * (ArrowBaseLength/2) + lPointD.X;
  lPointE.Y := Cos(AlfaAngle) * (ArrowBaseLength/2) + lPointD.Y;
  lPointF.X := - Sin(AlfaAngle) * (ArrowBaseLength/2) + lPointD.X;
  lPointF.Y := - Cos(AlfaAngle) * (ArrowBaseLength/2) + lPointD.Y;
  lPoints[1].X := CoordToCanvasX(lPointE.X);
  lPoints[1].Y := CoordToCanvasY(lPointE.Y);
  lPoints[2].X := CoordToCanvasX(lPointF.X);
  lPoints[2].Y := CoordToCanvasY(lPointF.Y);
  ADest.Polygon(lPoints);
end;

{ TvFormulaElement }

function TvFormulaElement.CalculateHeight(ADest: TFPCustomCanvas): Single;
begin
  case Kind of
    //fekVariable,  // Text is the text of the variable
    //fekEqual,     // = symbol
    //fekSubtraction, // - symbol
    //fekMultiplication, // either a point . or a small x
    //fekSum,       // + symbol
    //fekPlusMinus, // The +/- symbol
    fekFraction: Result := 2.3;
    fekRoot: Result := Formula.CalculateHeight(ADest);
    fekPower: Result := 1.1;
    //fekParenteses: Result,// This is utilized to group elements. Inside it goes a Formula
    fekParentesesWithPower: Result := 1.1;
    fekSomatory: Result := 1.5;
  else
    Result := 1.0;
  end;
end;

function TvFormulaElement.CalculateWidth(ADest: TFPCustomCanvas): Integer;
var
  lText: String;
begin
  Result := 0;

  lText := AsText;
  if lText <> '' then
  begin
    if ADest = nil then Result := 10 * UTF8Length(lText)
    else Result := TCanvas(ADest).TextWidth(lText);
  end;

  case Kind of
//    fekFraction: Result := 2.3;
    fekRoot: Result := Formula.CalculateWidth(ADest) + 5;
    fekPower: Result := Round(Result * 1.2);
    fekParenteses: Result := Result + 6;
    fekParentesesWithPower: Result := Result + 8;
    fekSomatory: Result := 8;
  else
  end;
end;

function TvFormulaElement.AsText: string;
begin
  case Kind of
    fekVariable:  Result := Text;
    fekEqual:     Result := '=';
    fekSubtraction: Result := '-';
    fekMultiplication: Result := 'x';
    fekSum:       Result := '+';
    fekPlusMinus: Result := '+/-';
    fekLessThan:  Result := '<';
    fekLessOrEqualThan: Result := '<=';
    fekGreaterThan: Result := '>';
    fekGreaterOrEqualThan: Result := '>=';
    // More complex elements
    fekFraction:  Result := '[fekFraction]';
    fekRoot:      Result := '[fekRoot]';
    fekPower:     Result := '[fekPower]';
    fekParenteses: Result := '[fekParenteses]';
    fekParentesesWithPower: Result := '[fekParentesesWithPower]';
    fekSomatory:  Result := '[fekSomatory]';
  else
    Result := '';
  end;
end;

procedure TvFormulaElement.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);
begin
  case Kind of
    fekVariable: ADest.TextOut(ADestX + Left, ADestY + Top, Text);
    fekEqual:    ADest.TextOut(ADestX + Left, ADestY + Top, '=');
    fekSubtraction: ADest.TextOut(ADestX + Left, ADestY + Top, '-');
    fekMultiplication: ADest.TextOut(ADestX + Left, ADestY + Top, '×'); // Unicode times symbol
    fekSum:      ADest.TextOut(ADestX + Left, ADestY + Top, '+');
    fekPlusMinus:ADest.TextOut(ADestX + Left, ADestY + Top, '±');
    fekLessThan: ADest.TextOut(ADestX + Left, ADestY + Top, '<');
    fekLessOrEqualThan: ADest.TextOut(ADestX + Left, ADestY + Top, '≤');
    fekGreaterThan: ADest.TextOut(ADestX + Left, ADestY + Top, '>');
    fekGreaterOrEqualThan: ADest.TextOut(ADestX + Left, ADestY + Top, '≥');
    {fekFraction:
    begin
      Formula.Render(ADest, ADestX, ADestY, AMulX, AMulY);
      Formula.Render(ADest, ADestX, ADestY, AMulX, AMulY);
    end;}
    //fekRoot: Result := Formula.CalculateHeight();
    //fekNumberWithPower,
    //fekVariableWithPower: Result := 1.1;
    //fekParenteses: Result,// This is utilized to group elements. Inside it goes a Formula
    //fekParentesesWithPower: Result := 1.1;
    //fekSomatory: Result := 1.5;
  end;
end;

procedure TvFormulaElement.GenerateDebugTree(ADestRoutine: TvDebugAddItemProc;
  APageItem: Pointer);
var
  lDBGItem, lDBGFormula, lDBGFormulaBottom: Pointer;
begin
  lDBGItem := ADestRoutine(Self.AsText(), APageItem);

  case Kind of
    fekFraction:
    begin
      lDBGFormula := ADestRoutine('Formula', lDBGItem);
      Formula.GenerateDebugTree(ADestRoutine, lDBGFormula);
      lDBGFormulaBottom := ADestRoutine('Bottom Formula', lDBGItem);
      AdjacentFormula.GenerateDebugTree(ADestRoutine, lDBGFormulaBottom);
    end;
    fekRoot: Formula.GenerateDebugTree(ADestRoutine, lDBGItem);
    fekPower:
    begin
      lDBGFormula := ADestRoutine('Formula', lDBGItem);
      Formula.GenerateDebugTree(ADestRoutine, lDBGFormula);
      lDBGFormulaBottom := ADestRoutine('Top Formula', lDBGItem);
      AdjacentFormula.GenerateDebugTree(ADestRoutine, lDBGFormulaBottom);
    end;
    //fekParenteses: Result,// This is utilized to group elements. Inside it goes a Formula
    //fekParentesesWithPower: Result := 1.1;
    //fekSomatory: Result := 1.5;
  end;
end;

{ TvFormula }

procedure TvFormula.CallbackDeleteElement(data, arg: pointer);
begin
  TvFormulaElement(data).Free;
end;

constructor TvFormula.Create;
begin
  inherited Create;
  FElements := TFPList.Create;
  SpacingBetweenElementsX := 10;
end;

destructor TvFormula.Destroy;
begin
  FElements.Free;
  inherited Destroy;
end;

function TvFormula.GetFirstElement: TvFormulaElement;
begin
  if FElements.Count = 0 then Exit(nil);
  Result := FElements.Items[0];
  FCurIndex := 1;
end;

function TvFormula.GetNextElement: TvFormulaElement;
begin
  if FElements.Count <= FCurIndex then Exit(nil);
  Result := FElements.Items[FCurIndex];
  Inc(FCurIndex);
end;

procedure TvFormula.AddElement(AElement: TvFormulaElement);
begin
  FElements.Add(AElement);
end;

function TvFormula.AddElementWithKind(AKind: TvFormulaElementKind): TvFormulaElement;
begin
  Result := TvFormulaElement.Create;
  Result.Kind := AKind;
  AddElement(Result);
end;

function TvFormula.AddElementWithKindAndText(AKind: TvFormulaElementKind;
  AText: string): TvFormulaElement;
begin
  Result := TvFormulaElement.Create;
  Result.Kind := AKind;
  Result.Text := AText;
  AddElement(Result);
end;

procedure TvFormula.Clear;
begin
  FElements.ForEachCall(CallbackDeleteElement, nil);
  FElements.Clear;
end;

function TvFormula.CalculateHeight(ADest: TFPCustomCanvas): Single;
var
  lElement: TvFormulaElement;
begin
  Result := 1.0;
  lElement := GetFirstElement();
  while lElement <> nil do
  begin
    Result := Max(Result, lElement.CalculateHeight(ADest));
    lElement := GetNextElement;
  end;
  // Cache the result
  if ADest <> nil then
    Height := Round(Result * TCanvas(ADest).TextHeight('T'));
end;

function TvFormula.CalculateWidth(ADest: TFPCustomCanvas): Integer;
var
  lElement: TvFormulaElement;
begin
  Result := 0;
  lElement := GetFirstElement();
  while lElement <> nil do
  begin
    Result := Result + lElement.CalculateWidth(ADest) + SpacingBetweenElementsX;
    lElement := GetNextElement;
  end;
  // Cache the result
  Width := Result;
end;

procedure TvFormula.PositionElements(ADest: TFPCustomCanvas; ABaseX, ABaseY: Integer);
var
  lElement: TvFormulaElement;
  lPosX: Integer = 0;
  lPosY: Integer = 0;
begin
  CalculateHeight(ADest);
  CalculateWidth(ADest);
  Top := ABaseX;
  Left := ABaseY;

  // Then calculate the position of each element
  lElement := GetFirstElement();
  if lElement = nil then Exit;
  while lElement <> nil do
  begin
    lElement.Left := Left + lPosX;
    lPosX := lPosX + lElement.Width;
    lElement.Top := Top;

    if lElement.Formula <> nil then
      lElement.Formula.PositionElements(ADest, lElement.Left, lElement.Top);

    if lElement.AdjacentFormula <> nil then
      lElement.AdjacentFormula.PositionElements(ADest, lElement.Left, lElement.Top);

    lElement := GetNextElement();
  end;
end;

procedure TvFormula.CalculateBoundingBox(ADest: TFPCustomCanvas; var ALeft, ATop, ARight,
  ABottom: Double);
begin
  ALeft := X;
  ATop := Y;
  ARight := CalculateWidth(ADest);
  if ADest = nil then ABottom := CalculateHeight(ADest) * 15
  else ABottom := CalculateHeight(ADest) * TCanvas(ADest).TextHeight('Źç');
  ARight := X + ARight;
  ABottom := Y + ABottom;
end;

procedure TvFormula.Render(ADest: TFPCustomCanvas; ADestX: Integer;
  ADestY: Integer; AMulX: Double; AMulY: Double);
var
  lElement: TvFormulaElement;
begin
  // First position all elements
  PositionElements(ADest, 0, 0);

  // Now draw them all
  lElement := GetFirstElement();
  if lElement = nil then Exit;
  while lElement <> nil do
  begin
    lElement.Render(ADest, ADestX, ADestY, AMulX, AMulY);

    lElement := GetNextElement();
  end;
end;

function TvFormula.GenerateDebugTree(ADestRoutine: TvDebugAddItemProc;
  APageItem: Pointer): Pointer;
var
  lFormulaElement: TvFormulaElement;
begin
  Result := inherited GenerateDebugTree(ADestRoutine, APageItem);

  lFormulaElement := GetFirstElement();
  while lFormulaElement <> nil do
  begin
    lFormulaElement.GenerateDebugTree(ADestRoutine, Result);

    lFormulaElement := GetNextElement()
  end;
end;

{ TvVectorialPage }

procedure TvVectorialPage.ClearTmpPath;
var
  segment, oldsegment: TPathSegment;
begin
  FTmpPath.Points := nil;
  FTmpPath.PointsEnd := nil;
  FTmpPath.Len := 0;
  FTmpPath.Brush.Color := colBlue;
  FTmpPath.Brush.Style := bsClear;
  FTmpPath.Pen.Color := colBlack;
  FTmpPath.Pen.Style := psSolid;
  FTmpPath.Pen.Width := 1;
end;

procedure TvVectorialPage.AppendSegmentToTmpPath(ASegment: TPathSegment);
begin
  FTmpPath.AppendSegment(ASegment);
end;

procedure TvVectorialPage.CallbackDeleteEntity(data, arg: pointer);
begin
  if (data <> nil) then
    TvEntity(data).Free;
end;

constructor TvVectorialPage.Create(AOwner: TvVectorialDocument);
begin
  inherited Create;

  FEntities := TFPList.Create;
  FTmpPath := TPath.Create;
  Owner := AOwner;
end;

destructor TvVectorialPage.Destroy;
begin
  Clear;

  if FTmpPath <> nil then
  begin
    FTmpPath.Free;
    FTmpPath := nil;
  end;

  FEntities.Free;
  FEntities := nil;

  inherited Destroy;
end;

procedure TvVectorialPage.Assign(ASource: TvVectorialPage);
var
  i: Integer;
begin
  Clear;

  for i := 0 to ASource.GetEntitiesCount - 1 do
    Self.AddEntity(ASource.GetEntity(i));
end;

function TvVectorialPage.GetEntity(ANum: Cardinal): TvEntity;
begin
  if ANum >= FEntities.Count then raise Exception.Create('TvVectorialDocument.GetEntity: Entity number out of bounds');

  Result := TvEntity(FEntities.Items[ANum]);

  if Result = nil then raise Exception.Create('TvVectorialDocument.GetEntity: Invalid Entity number');
end;

function TvVectorialPage.GetEntitiesCount: Integer;
begin
  Result := FEntities.Count;
end;

function TvVectorialPage.GetLastEntity(): TvEntity;
begin
  Result:=TvEntity(FEntities.Last);
end;

function TvVectorialPage.FindAndSelectEntity(Pos: TPoint): TvFindEntityResult;
var
  lEntity: TvEntity;
  i: Integer;
  lSubpart: Cardinal;
begin
  Result := vfrNotFound;

  for i := 0 to GetEntitiesCount() - 1 do
  begin
    lEntity := GetEntity(i);

    Result := lEntity.TryToSelect(Pos, lSubpart);

    if Result <> vfrNotFound then
    begin
      Owner.SelectedvElement := lEntity;
      Exit;
    end;
  end;
end;

procedure TvVectorialPage.Clear;
begin
  FEntities.ForEachCall(CallbackDeleteEntity, nil);
  FEntities.Clear();
  ClearTmpPath();
end;

{@@
  Returns if the entity was really deleted or false if there is no entity with this index
}
function TvVectorialPage.DeleteEntity(AIndex: Cardinal): Boolean;
var
  lEntity: TvEntity;
begin
  Result := False;
  if AIndex >= GetEntitiesCount() then Exit;;
  lEntity := GetEntity(AIndex);
  if lEntity = nil then Exit;
  FEntities.Delete(AIndex);
  lEntity.Free;
  Result := True;
end;

function TvVectorialPage.RemoveEntity(AEntity: TvEntity; AFreeAfterRemove: Boolean = True): Boolean;
begin
  Result := False;
  if AEntity = nil then Exit;
  FEntities.Remove(AEntity);
  if AFreeAfterRemove then AEntity.Free;
  Result := True;
end;

{@@
  Adds an entity to the document and returns it's current index
}
function TvVectorialPage.AddEntity(AEntity: TvEntity): Integer;
begin
  Result := FEntities.Count;
  FEntities.Add(Pointer(AEntity));
end;

procedure TvVectorialPage.AddPathCopyMem(APath: TPath);
var
  lPath: TPath;
  Len: Integer;
begin
  lPath := TPath.Create;
  lPath.Assign(APath);
  AddEntity(lPath);
  //WriteLn(':>TvVectorialDocument.AddPath 1 Len = ', Len);
end;

{@@
  Starts writing a Path in multiple steps.
  Should be followed by zero or more calls to AddPointToPath
  and by a call to EndPath to effectively add the data.

  @see    EndPath, AddPointToPath
}
procedure TvVectorialPage.StartPath(AX, AY: Double);
var
  segment: T2DSegment;
begin
  ClearTmpPath();

  FTmpPath.Len := 1;
  segment := T2DSegment.Create;
  segment.SegmentType := stMoveTo;
  segment.X := AX;
  segment.Y := AY;

  FTmpPath.Points := segment;
  FTmpPath.PointsEnd := segment;
end;

procedure TvVectorialPage.StartPath;
begin
  ClearTmpPath();
end;

procedure TvVectorialPage.AddMoveToPath(AX, AY: Double);
var
  segment: T2DSegment;
begin
  segment := T2DSegment.Create;
  segment.SegmentType := stMoveTo;
  segment.X := AX;
  segment.Y := AY;

  AppendSegmentToTmpPath(segment);
end;

{@@
  Adds one more point to the end of a Path being
  writing in multiple steps.

  Does nothing if not called between StartPath and EndPath.

  Can be called multiple times to add multiple points.

  @see    StartPath, EndPath
}
procedure TvVectorialPage.AddLineToPath(AX, AY: Double);
var
  segment: T2DSegment;
begin
  segment := T2DSegment.Create;
  segment.SegmentType := st2DLine;
  segment.X := AX;
  segment.Y := AY;

  AppendSegmentToTmpPath(segment);
end;

procedure TvVectorialPage.AddLineToPath(AX, AY: Double; AColor: TFPColor);
var
  segment: T2DSegmentWithPen;
begin
  segment := T2DSegmentWithPen.Create;
  segment.SegmentType := st2DLineWithPen;
  segment.X := AX;
  segment.Y := AY;
  segment.Pen.Color := AColor;

  AppendSegmentToTmpPath(segment);
end;

procedure TvVectorialPage.AddLineToPath(AX, AY, AZ: Double);
var
  segment: T3DSegment;
begin
  segment := T3DSegment.Create;
  segment.SegmentType := st3DLine;
  segment.X := AX;
  segment.Y := AY;
  segment.Z := AZ;

  AppendSegmentToTmpPath(segment);
end;

{@@
  Gets the current Pen Pos in the temporary path
}
procedure TvVectorialPage.GetCurrentPathPenPos(var AX, AY: Double);
begin
  // Check if we are the first segment in the tmp path
  if FTmpPath.PointsEnd = nil then raise Exception.Create('[TvVectorialDocument.GetCurrentPathPenPos] One cannot obtain the Pen Pos if there are no segments in the temporary path');

  AX := T2DSegment(FTmpPath.PointsEnd).X;
  AY := T2DSegment(FTmpPath.PointsEnd).Y;
end;

{@@
  Adds a bezier element to the path. It starts where the previous element ended
  and it goes throw the control points [AX1, AY1] and [AX2, AY2] and ends
  in [AX3, AY3].
}
procedure TvVectorialPage.AddBezierToPath(AX1, AY1, AX2, AY2, AX3, AY3: Double);
var
  segment: T2DBezierSegment;
begin
  segment := T2DBezierSegment.Create;
  segment.SegmentType := st2DBezier;
  segment.X := AX3;
  segment.Y := AY3;
  segment.X2 := AX1;
  segment.Y2 := AY1;
  segment.X3 := AX2;
  segment.Y3 := AY2;

  AppendSegmentToTmpPath(segment);
end;

procedure TvVectorialPage.AddBezierToPath(AX1, AY1, AZ1, AX2, AY2, AZ2, AX3, AY3, AZ3: Double);
var
  segment: T3DBezierSegment;
begin
  segment := T3DBezierSegment.Create;
  segment.SegmentType := st3DBezier;
  segment.X := AX3;
  segment.Y := AY3;
  segment.Z := AZ3;
  segment.X2 := AX1;
  segment.Y2 := AY1;
  segment.Z2 := AZ1;
  segment.X3 := AX2;
  segment.Y3 := AY2;
  segment.Z3 := AZ2;

  AppendSegmentToTmpPath(segment);
end;

procedure TvVectorialPage.SetBrushColor(AColor: TFPColor);
begin
  FTmPPath.Brush.Color := AColor;
end;

procedure TvVectorialPage.SetBrushStyle(AStyle: TFPBrushStyle);
begin
  FTmPPath.Brush.Style := AStyle;
end;

procedure TvVectorialPage.SetPenColor(AColor: TFPColor);
begin
  FTmPPath.Pen.Color := AColor;
end;

procedure TvVectorialPage.SetPenStyle(AStyle: TFPPenStyle);
begin
  FTmPPath.Pen.Style := AStyle;
end;

procedure TvVectorialPage.SetPenWidth(AWidth: Integer);
begin
  FTmPPath.Pen.Width := AWidth;
end;

procedure TvVectorialPage.SetClipPath(AClipPath: TPath; AClipMode: TvClipMode);
begin
  FTmPPath.ClipPath := AClipPath;
  FTmPPath.ClipMode := AClipMode;
end;

{@@
  Finishes writing a Path, which was created in multiple
  steps using StartPath and AddPointToPath,
  to the document.

  Does nothing if there wasn't a previous correspondent call to
  StartPath.

  @see    StartPath, AddPointToPath
}
procedure TvVectorialPage.EndPath;
begin
  if FTmPPath.Len = 0 then Exit;
  AddPathCopyMem(FTmPPath);
  ClearTmpPath();
end;

procedure TvVectorialPage.AddText(AX, AY, AZ: Double; FontName: string;
  FontSize: integer; AText: utf8string);
var
  lText: TvText;
begin
  lText := TvText.Create;
  lText.Value.Text := AText;
  lText.X := AX;
  lText.Y := AY;
  lText.Z := AZ;
  lText.Font.Name := FontName;
  lText.Font.Size := FontSize;
  AddEntity(lText);
end;

procedure TvVectorialPage.AddText(AX, AY: Double; AStr: utf8string);
begin
  AddText(AX, AY, 0, '', 10, AStr);
end;

procedure TvVectorialPage.AddText(AX, AY, AZ: Double; AStr: utf8string);
begin
  AddText(AX, AY, AZ, '', 10, AStr);
end;

procedure TvVectorialPage.AddCircle(ACenterX, ACenterY, ARadius: Double);
var
  lCircle: TvCircle;
begin
  lCircle := TvCircle.Create;
  lCircle.X := ACenterX;
  lCircle.Y := ACenterY;
  lCircle.Radius := ARadius;
  AddEntity(lCircle);
end;

procedure TvVectorialPage.AddCircularArc(ACenterX, ACenterY, ARadius,
  AStartAngle, AEndAngle: Double; AColor: TFPColor);
var
  lCircularArc: TvCircularArc;
begin
  lCircularArc := TvCircularArc.Create;
  lCircularArc.X := ACenterX;
  lCircularArc.Y := ACenterY;
  lCircularArc.Radius := ARadius;
  lCircularArc.StartAngle := AStartAngle;
  lCircularArc.EndAngle := AEndAngle;
  lCircularArc.Pen.Color := AColor;
  AddEntity(lCircularArc);
end;

procedure TvVectorialPage.AddEllipse(CenterX, CenterY, HorzHalfAxis,
  VertHalfAxis, Angle: Double);
var
  lEllipse: TvEllipse;
begin
  lEllipse := TvEllipse.Create;
  lEllipse.X := CenterX;
  lEllipse.Y := CenterY;
  lEllipse.HorzHalfAxis := HorzHalfAxis;
  lEllipse.VertHalfAxis := VertHalfAxis;
  lEllipse.Angle := Angle;
  AddEntity(lEllipse);
end;


procedure TvVectorialPage.AddAlignedDimension(BaseLeft, BaseRight, DimLeft,
  DimRight: T3DPoint);
var
  lDim: TvAlignedDimension;
begin
  lDim := TvAlignedDimension.Create;
  lDim.BaseLeft := BaseLeft;
  lDim.BaseRight := BaseRight;
  lDim.DimensionLeft := DimLeft;
  lDim.DimensionRight := DimRight;
  AddEntity(lDim);
end;

function TvVectorialPage.AddPoint(AX, AY, AZ: Double): TvPoint;
var
  lPoint: TvPoint;
begin
  lPoint := TvPoint.Create;
  lPoint.X := AX;
  lPoint.Y := AY;
  lPoint.Z := AZ;
  AddEntity(lPoint);
  Result := lPoint;
end;

procedure TvVectorialPage.GenerateDebugTree(ADestRoutine: TvDebugAddItemProc;
  APageItem: Pointer);
var
  lCurEntity: TvEntity;
  i: Integer;
begin
  for i := 0 to FEntities.Count - 1 do
  begin
    lCurEntity := TvEntity(FEntities.Items[i]);
    lCurEntity.GenerateDebugTree(ADestRoutine, APageItem);
  end;
end;

{ TsWorksheet }

{@@
  Constructor.
}
constructor TvVectorialDocument.Create;
begin
  inherited Create;

  FPages := TFPList.Create;
  FCurrentPageIndex := -1;
end;

{@@
  Destructor.
}
destructor TvVectorialDocument.Destroy;
begin
  Clear;

  FPages.Free;
  FPages := nil;

  inherited Destroy;
end;

procedure TvVectorialDocument.Assign(ASource: TvVectorialDocument);
//var
//  i: Integer;
begin
//  Clear;
//
//  for i := 0 to ASource.GetEntitiesCount - 1 do
//    Self.AddEntity(ASource.GetEntity(i));
end;

procedure TvVectorialDocument.AssignTo(ADest: TvVectorialDocument);
begin
  ADest.Assign(Self);
end;

{@@
  Convenience method which creates the correct
  writer object for a given vector graphics document format.
}
function TvVectorialDocument.CreateVectorialWriter(AFormat: TvVectorialFormat): TvCustomVectorialWriter;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Length(GvVectorialFormats) - 1 do
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].WriterClass <> nil then
        Result := GvVectorialFormats[i].WriterClass.Create;

      Break;
    end;

  if Result = nil then raise Exception.Create('Unsupported vector graphics format.');
end;

{@@
  Convenience method which creates the correct
  reader object for a given vector graphics document format.
}
function TvVectorialDocument.CreateVectorialReader(AFormat: TvVectorialFormat): TvCustomVectorialReader;
var
  i: Integer;
begin
  Result := nil;

  for i := 0 to Length(GvVectorialFormats) - 1 do
    if GvVectorialFormats[i].Format = AFormat then
    begin
      if GvVectorialFormats[i].ReaderClass <> nil then
        Result := GvVectorialFormats[i].ReaderClass.Create;

      Break;
    end;

  if Result = nil then raise Exception.Create('Unsupported vector graphics format.');
end;

{@@
  Writes the document to a file.

  If the file doesn't exist, it will be created.
}
procedure TvVectorialDocument.WriteToFile(AFileName: string; AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToFile(AFileName, Self);
  finally
    AWriter.Free;
  end;
end;

procedure TvVectorialDocument.WriteToFile(AFileName: string);
var
  lFormat: TvVectorialFormat;
begin
  lFormat := GetFormatFromExtension(ExtractFileExt(AFileName));
  WriteToFile(AFileName, lFormat);
end;

{@@
  Writes the document to a stream
}
procedure TvVectorialDocument.WriteToStream(AStream: TStream; AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToStream(AStream, Self);
  finally
    AWriter.Free;
  end;
end;

procedure TvVectorialDocument.WriteToStrings(AStrings: TStrings;
  AFormat: TvVectorialFormat);
var
  AWriter: TvCustomVectorialWriter;
begin
  AWriter := CreateVectorialWriter(AFormat);

  try
    AWriter.WriteToStrings(AStrings, Self);
  finally
    AWriter.Free;
  end;
end;

{@@
  Reads the document from a file.

  Any current contents in this object will be removed.
}
procedure TvVectorialDocument.ReadFromFile(AFileName: string;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromFile(AFileName, Self);
  finally
    AReader.Free;
  end;
end;

{@@
  Reads the document from a file.  A variant that auto-detects the format from the extension and other factors.
}
procedure TvVectorialDocument.ReadFromFile(AFileName: string);
var
  lFormat: TvVectorialFormat;
begin
  lFormat := GetFormatFromExtension(ExtractFileExt(AFileName));
  ReadFromFile(AFileName, lFormat);
end;

{@@
  Reads the document from a stream.

  Any current contents in this object will be removed.
}
procedure TvVectorialDocument.ReadFromStream(AStream: TStream;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromStream(AStream, Self);
  finally
    AReader.Free;
  end;
end;

procedure TvVectorialDocument.ReadFromStrings(AStrings: TStrings;
  AFormat: TvVectorialFormat);
var
  AReader: TvCustomVectorialReader;
begin
  Self.Clear;

  AReader := CreateVectorialReader(AFormat);
  try
    AReader.ReadFromStrings(AStrings, Self);
  finally
    AReader.Free;
  end;
end;

class function TvVectorialDocument.GetFormatFromExtension(AFileName: string
  ): TvVectorialFormat;
var
  lExt: string;
begin
  lExt := ExtractFileExt(AFileName);
  if AnsiCompareText(lExt, STR_PDF_EXTENSION) = 0 then Result := vfPDF
  else if AnsiCompareText(lExt, STR_POSTSCRIPT_EXTENSION) = 0 then Result := vfPostScript
  else if AnsiCompareText(lExt, STR_SVG_EXTENSION) = 0 then Result := vfSVG
  else if AnsiCompareText(lExt, STR_CORELDRAW_EXTENSION) = 0 then Result := vfCorelDrawCDR
  else if AnsiCompareText(lExt, STR_WINMETAFILE_EXTENSION) = 0 then Result := vfWindowsMetafileWMF
  else if AnsiCompareText(lExt, STR_AUTOCAD_EXCHANGE_EXTENSION) = 0 then Result := vfDXF
  else if AnsiCompareText(lExt, STR_ENCAPSULATEDPOSTSCRIPT_EXTENSION) = 0 then Result := vfEncapsulatedPostScript
  else if AnsiCompareText(lExt, STR_LAS_EXTENSION) = 0 then Result := vfLAS
  else if AnsiCompareText(lExt, STR_LAZ_EXTENSION) = 0 then Result := vfLAZ
  else if AnsiCompareText(lExt, STR_RAW_EXTENSION) = 0 then Result := vfRAW
  else if AnsiCompareText(lExt, STR_MATHML_EXTENSION) = 0 then Result := vfMathML
  else
    raise Exception.Create('TvVectorialDocument.GetFormatFromExtension: The extension (' + lExt + ') doesn''t match any supported formats.');
end;

function  TvVectorialDocument.GetDetailedFileFormat(): string;
begin

end;

procedure TvVectorialDocument.GuessDocumentSize();
var
  i, j: Integer;
  lEntity: TvEntity;
  lLeft, lTop, lRight, lBottom: Double;
  CurPage: TvVectorialPage;
begin
  lLeft := 0;
  lTop := 0;
  lRight := 0;
  lBottom := 0;

  for j := 0 to GetPageCount()-1 do
  begin
    CurPage := GetPage(j);
    for i := 0 to CurPage.GetEntitiesCount() - 1 do
    begin
      lEntity := CurPage.GetEntity(I);
      lEntity.ExpandBoundingBox(nil, lLeft, lTop, lRight, lBottom);
    end;
  end;

  Width := lRight - lLeft;
  Height := lBottom - lTop;
end;

procedure TvVectorialDocument.GuessGoodZoomLevel(AScreenSize: Integer);
begin
  ZoomLevel := AScreenSize / Height;
end;

function TvVectorialDocument.GetPage(AIndex: Integer): TvVectorialPage;
begin
  Result := TvVectorialPage(FPages.Items[AIndex]);
end;

function TvVectorialDocument.GetPageCount: Integer;
begin
  Result := FPages.Count;
end;

function TvVectorialDocument.GetCurrentPage: TvVectorialPage;
begin
  if FCurrentPageIndex >= 0 then
    Result := GetPage(FCurrentPageIndex)
  else
    Result := nil;
end;

procedure TvVectorialDocument.SetCurrentPage(AIndex: Integer);
begin
  FCurrentPageIndex := AIndex;
end;

function TvVectorialDocument.AddPage: TvVectorialPage;
begin
  Result := TvVectorialPage.Create(Self);
  FPages.Add(Result);
  if FCurrentPageIndex < 0 then FCurrentPageIndex := FPages.Count-1;
end;

{@@
  Clears all data in the document
}
// GM: Release memory for each page
procedure TvVectorialDocument.Clear;
var
  i: integer;
  p: TvVectorialPage;
begin
  for i:=FPages.Count-1 downto 0 do
  begin
    p := TvVectorialPage(FPages[i]);
    p.Clear;
    FreeAndNil(p);
  end;
  FPages.Clear;
  FCurrentPageIndex:=-1;
end;

procedure TvVectorialDocument.GenerateDebugTree(ADestRoutine: TvDebugAddItemProc);
var
  i: integer;
  p: TvVectorialPage;
  lPageItem: Pointer;
begin
  for i:=0 to FPages.Count-1 do
  begin
    p := TvVectorialPage(FPages[i]);
    lPageItem := ADestRoutine(Format('Page %d', [i]), nil);
    p.GenerateDebugTree(ADestRoutine, lPageItem);
  end;
end;

{ TvCustomVectorialReader }

constructor TvCustomVectorialReader.Create;
begin
  inherited Create;
end;

procedure TvCustomVectorialReader.ReadFromFile(AFileName: string; AData: TvVectorialDocument);
var
  FileStream: TFileStream;
begin
  FileStream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyNone);
  try
    ReadFromStream(FileStream, AData);
  finally
    FileStream.Free;
  end;
end;

procedure TvCustomVectorialReader.ReadFromStream(AStream: TStream;
  AData: TvVectorialDocument);
var
  AStringStream: TStringStream;
  AStrings: TStringList;
begin
  AStringStream := TStringStream.Create('');
  AStrings := TStringList.Create;
  try
    AStringStream.CopyFrom(AStream, AStream.Size);
    AStringStream.Seek(0, soFromBeginning);
    AStrings.Text := AStringStream.DataString;
    ReadFromStrings(AStrings, AData);
  finally
    AStringStream.Free;
    AStrings.Free;
  end;
end;

procedure TvCustomVectorialReader.ReadFromStrings(AStrings: TStrings;
  AData: TvVectorialDocument);
var
  AStringStream: TStringStream;
begin
  AStringStream := TStringStream.Create('');
  try
    AStringStream.WriteString(AStrings.Text);
    AStringStream.Seek(0, soFromBeginning);
    ReadFromStream(AStringStream, AData);
  finally
    AStringStream.Free;
  end;
end;

{ TsCustomSpreadWriter }

constructor TvCustomVectorialWriter.Create;
begin
  inherited Create;
end;

{@@
  Default file writting method.

  Opens the file and calls WriteToStream

  @param  AFileName The output file name.
                   If the file already exists it will be replaced.
  @param  AData     The Workbook to be saved.

  @see    TsWorkbook
}
procedure TvCustomVectorialWriter.WriteToFile(AFileName: string; AData: TvVectorialDocument);
var
  OutputFile: TFileStream;
begin
  OutputFile := TFileStream.Create(AFileName, fmCreate or fmOpenWrite);
  try
    WriteToStream(OutputFile, AData);
  finally
    OutputFile.Free;
  end;
end;

{@@
  The default stream writer just uses WriteToStrings
}
procedure TvCustomVectorialWriter.WriteToStream(AStream: TStream;
  AData: TvVectorialDocument);
var
  lStringList: TStringList;
begin
  lStringList := TStringList.Create;
  try
    WriteToStrings(lStringList, AData);
    lStringList.SaveToStream(AStream);
  finally
    lStringList.Free;
  end;
end;

procedure TvCustomVectorialWriter.WriteToStrings(AStrings: TStrings;
  AData: TvVectorialDocument);
begin

end;

finalization

  SetLength(GvVectorialFormats, 0);

end.

