unit objectinspector;
{
  Author: Mattias Gaertner

  Abstract:
   This unit defines the TObjectInspector which is a descendent of TCustomForm.
   It uses TOIPropertyGrid and TOIPropertyGridRow which are also defined in this
   unit. The object inspector uses property editors (see TPropertyEditor) to
   display and control properties, thus the object inspector is merely an
   object viewer than an editor. The property editors do the real work.


  ToDo:
   - TCustomComboBox has a bug: it can not store objects
   - MouseDown is always fired twice -> workaround
   - clipping (almost everywhere)
   - TCustomComboBox don't know custom draw yet
   - improve TextHeight function
   - combobox can't sort (exception)
   - backgroundcolor=clNone
   - DoubleClick on Property

   - a lot more ...  see XXX
}

{$MODE OBJFPC}{$H+}

interface

uses
  Forms, SysUtils, Buttons, Classes, Graphics, StdCtrls, LCLLinux, Controls,
  ComCtrls, ExtCtrls, PropEdits, TypInfo, Messages, LResources, XMLCfg, Menus,
  Dialogs;

type
  TObjectInspector = class;

  TOIOptions = class
  private
    FFilename:string;
    
    FSaveBounds: boolean;
    FLeft: integer;
    FTop: integer;
    FWidth: integer;
    FHeight: integer;
    FPropertyGridSplitterX: integer;
    FEventGridSplitterX: integer;

    FGridBackgroundColor: TColor;
  public
    constructor Create;
    destructor Destroy;  override;
    function Load:boolean;
    function Save:boolean;
    procedure Assign(AnObjInspector: TObjectInspector);
    procedure AssignTo(AnObjInspector: TObjectInspector);
    property Filename:string read FFilename write FFilename;

    property SaveBounds:boolean read FSaveBounds write FSaveBounds;
    property Left:integer read FLeft write FLeft;
    property Top:integer read FTop write FTop;
    property Width:integer read FWidth write FWidth;
    property Height:integer read FHeight write FHeight;
    property PropertyGridSplitterX:integer
      read FPropertyGridSplitterX write FPropertyGridSplitterX;
    property EventGridSplitterX:integer
      read FEventGridSplitterX write FEventGridSplitterX;

    property GridBackgroundColor: TColor 
      read FGridBackgroundColor write FGridBackgroundColor;
  end;

  TOIPropertyGrid = class;

  TOIPropertyGridRow = class
  private
    FTop:integer;
    FHeight:integer;
    FLvl:integer;
    FName:string;
    FExpanded: boolean;
    FTree:TOIPropertyGrid;
    FChildCount:integer;
    FPriorBrother,
    FFirstChild,
    FLastChild,
    FNextBrother,
    FParent:TOIPropertyGridRow;
    FEditor: TPropertyEditor;
    procedure GetLvl;
  public
    Index:integer;
    LastPaintedValue:string;
    property Editor:TPropertyEditor read FEditor;
    property Top:integer read FTop write FTop;
    property Height:integer read FHeight write FHeight;
    function Bottom:integer;
    property Lvl:integer read FLvl;
    property Name:string read FName;
    property Expanded:boolean read FExpanded;
    property Tree:TOIPropertyGrid read FTree;
    property Parent:TOIPropertyGridRow read FParent;
    property ChildCount:integer read FChildCount;
    property FirstChild:TOIPropertyGridRow read FFirstChild;
    property LastChild:TOIPropertyGridRow read FFirstChild;
    property NextBrother:TOIPropertyGridRow read FNextBrother;
    property PriorBrother:TOIPropertyGridRow read FPriorBrother;
    constructor Create(PropertyTree:TOIPropertyGrid;  PropEditor:TPropertyEditor;
       ParentNode:TOIPropertyGridRow);
    destructor Destroy; override;
  end;

  //----------------------------------------------------------------------------
  TOIPropertyGrid = class(TCustomControl)
  private
    FComponentList: TComponentSelectionList;
    FPropertyEditorHook:TPropertyEditorHook;
    FFilter: TTypeKinds;
    FItemIndex:integer;
    FChangingItemIndex:boolean;
    FRows:TList;
    FExpandingRow:TOIPropertyGridRow;
    FTopY:integer;
    FDefaultItemHeight:integer;
    FSplitterX:integer;
    FIndent:integer;
    FBackgroundColor:TColor;
    FNameFont,FValueFont:TFont;
    FCurrentEdit:TWinControl;  // nil or ValueEdit or ValueComboBox
    FCurrentButton:TWinControl; // nil or ValueButton
    FDragging:boolean;
    FOldMouseDownY:integer;  // XXX workaround
    FExpandedProperties:TStringList;
    FBorderStyle:TBorderStyle;

    function GetRow(Index:integer):TOIPropertyGridRow;
    function GetRowCount:integer;
    procedure ClearRows;
    procedure SetItemIndex(NewIndex:integer);

    procedure SetItemsTops;
    procedure AlignEditComponents;
    procedure EndDragSplitter;
    procedure SetSplitterX(const NewValue:integer);
    procedure SetTopY(const NewValue:integer);

    function GetTreeIconX(Index:integer):integer;
    function RowRect(ARow:integer):TRect;
    procedure PaintRow(ARow:integer);
    procedure DoPaint(PaintOnlyChangedValues:boolean);

    procedure SetSelections(const NewSelections:TComponentSelectionList);
    procedure SetPropertyEditorHook(NewPropertyEditorHook:TPropertyEditorHook);

    procedure AddPropertyEditor(PropEditor: TPropertyEditor);
    procedure AddStringToComboBox(const s:string);
    procedure ExpandRow(Index:integer);
    procedure ShrinkRow(Index:integer);
    procedure AddSubEditor(PropEditor:TPropertyEditor);

    procedure SetRowValue;
    procedure ValueEditKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueEditExit(Sender: TObject);
    procedure ValueEditChange(Sender: TObject);
    procedure ValueComboBoxExit(Sender: TObject);
    procedure ValueComboBoxChange(Sender: TObject);
    procedure ValueComboBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure ValueButtonClick(Sender: TObject);

    procedure WMVScroll(var Msg: TWMScroll); message WM_VSCROLL;
    procedure WMSize(var Msg: TWMSize); message WM_SIZE;
    procedure SetBorderStyle(Value: TBorderStyle);
    procedure UpdateScrollBar;
  protected
    procedure CreateParams(var Params: TCreateParams); override;

  public
    ValueEdit:TEdit;
    ValueComboBox:TComboBox;
    ValueButton:TButton;

    property Selections:TComponentSelectionList read FComponentList write SetSelections;
    property PropertyEditorHook:TPropertyEditorHook
       read FPropertyEditorHook write SetPropertyEditorHook;
    procedure BuildPropertyList;
    procedure RefreshPropertyValues;

    property RowCount:integer read GetRowCount;
    property Rows[Index:integer]:TOIPropertyGridRow read GetRow;

    property TopY:integer read FTopY write SetTopY;
    function GridHeight:integer;
    function TopMax:integer;
    property DefaultItemHeight:integer read FDefaultItemHeight write FDefaultItemHeight;
    property SplitterX:integer read FSplitterX write SetSplitterX;
    property Indent:integer read FIndent write FIndent;
    property BackgroundColor:TColor
       read FBackgroundColor write FBackgroundColor default clBtnFace;
    property NameFont:TFont read FNameFont write FNameFont;
    property ValueFont:TFont read FValueFont write FValueFont;
    property BorderStyle: TBorderStyle read FBorderStyle write SetBorderStyle
       default bsSingle;
    property ItemIndex:integer read FItemIndex write SetItemIndex;
    property ExpandedProperties:TStringList 
       read FExpandedProperties write FExpandedProperties;
    function PropertyPath(Index:integer):string;
    function GetRowByPath(PropPath:string):TOIPropertyGridRow;

    procedure MouseDown(Button:TMouseButton; Shift:TShiftState; X,Y:integer);  override;
    procedure MouseMove(Shift:TShiftState; X,Y:integer);  override;
    procedure MouseUp(Button:TMouseButton; Shift:TShiftState; X,Y:integer);  override;
    function MouseToIndex(y:integer;MustExist:boolean):integer;

    procedure SetBounds(aLeft,aTop,aWidth,aHeight:integer); override;
    procedure Paint;  override;
    procedure Clear;
    constructor Create(AOwner:TComponent;
       APropertyEditorHook:TPropertyEditorHook;  TypeFilter:TTypeKinds);
    destructor Destroy;  override;
  end;

  //============================================================================
  TOnAddAvailableComponent = procedure(AComponent:TComponent;
    var Allowed:boolean) of object;

  TOnSelectComponentInOI = procedure(AComponent:TComponent) of object;

  TObjectInspector = class (TCustomForm)
    AvailCompsComboBox : TComboBox;
    NoteBook:TNoteBook;
    PropertyGrid:TOIPropertyGrid;
    EventGrid:TOIPropertyGrid;
    StatusBar:TStatusBar;
    MainPopupMenu:TPopupMenu;
    ColorsPopupMenuItem:TMenuItem;
    BackgroundColPopupMenuItem:TMenuItem;
    procedure AvailComboBoxChange(Sender:TObject);
    procedure OnBackgroundColPopupMenuItemClick(Sender :TObject);
  private
    FComponentList: TComponentSelectionList;
    FPropertyEditorHook:TPropertyEditorHook;
    FUpdatingAvailComboBox:boolean;
    FOnAddAvailableComponent:TOnAddAvailableComponent;
    FOnSelectComponentInOI:TOnSelectComponentInOI;
    function ComponentToString(c:TComponent):string;
    procedure SetPropertyEditorHook(NewValue:TPropertyEditorHook);
    procedure SetSelections(const NewSelections:TComponentSelectionList);
    procedure AddComponentToAvailComboBox(AComponent:TComponent);
    procedure PropEditLookupRootChange;
  public
    procedure SetBounds(aLeft,aTop,aWidth,aHeight:integer); override;
    property Selections:TComponentSelectionList 
      read FComponentList write SetSelections;
    procedure RefreshSelections;
    procedure RefreshPropertyValues;
    procedure FillComponentComboBox;
    property OnAddAvailComponent:TOnAddAvailableComponent
      read FOnAddAvailableComponent write FOnAddAvailableComponent;
    property OnSelectComponentInOI:TOnSelectComponentInOI
      read FOnSelectComponentInOI write FOnSelectComponentInOI;
    property PropertyEditorHook:TPropertyEditorHook 
      read FPropertyEditorHook write SetPropertyEditorHook;
    procedure DoInnerResize;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
  end;

//******************************************************************************

implementation

{ TOIPropertyGrid }

constructor TOIPropertyGrid.Create(AOwner:TComponent;
APropertyEditorHook:TPropertyEditorHook;  TypeFilter:TTypeKinds);
begin
  inherited Create(AOwner);
  if LazarusResources.Find(ClassName)=nil then begin
    SetBounds(1,1,200,300);
    ControlStyle:=ControlStyle+[csAcceptsControls,csOpaque];
    BorderWidth:=1;
  end;
    
  FComponentList:=TComponentSelectionList.Create;
  FPropertyEditorHook:=APropertyEditorHook;
  FFilter:=TypeFilter;
  FItemIndex:=-1;
  FChangingItemIndex:=false;
  FRows:=TList.Create;
  FExpandingRow:=nil;
  FDragging:=false;
  FExpandedProperties:=TStringList.Create;

  // visible values
  FTopY:=0;
  FSplitterX:=100;
  FIndent:=9;
  FBackgroundColor:=clBtnFace;
  FNameFont:=TFont.Create;
  FNameFont.Color:=clWindowText;
  FValueFont:=TFont.Create;
  FValueFont.Color:=clActiveCaption;
  fBorderStyle := bsSingle;

  // create sub components
  FCurrentEdit:=nil;
  FCurrentButton:=nil;

  ValueEdit:=TEdit.Create(Self);
  with ValueEdit do begin
    Parent:=Self;
    OnExit:=@ValueEditExit;
    OnChange:=@ValueEditChange;
    OnKeyDown:=@ValueEditKeyDown;
    Visible:=false;
    Enabled:=false;
  end;

  ValueComboBox:=TComboBox.Create(Self);
  with ValueComboBox do begin
    OnExit:=@ValueComboBoxExit;
    OnChange:=@ValueComboBoxChange;
    OnKeyDown:=@ValueComboBoxKeyDown;
    Visible:=false;
    Enabled:=false;
    Parent:=Self;
  end;

  ValueButton:=TButton.Create(Self);
  with ValueButton do begin
    Visible:=false;
    Enabled:=false;
    OnClick:=@ValueButtonClick;
    Caption := '...';
    Parent:=Self;
  end;

  FDefaultItemHeight:=ValueComboBox.Height-3;

  BuildPropertyList;
end;

procedure TOIPropertyGrid.UpdateScrollBar;
var
  ScrollInfo: TScrollInfo;
begin
  if HandleAllocated then begin
    ScrollInfo.cbSize := SizeOf(ScrollInfo);
    ScrollInfo.fMask := SIF_ALL or SIF_DISABLENOSCROLL;
    ScrollInfo.nMin := 0;
    ScrollInfo.nTrackPos := 0;
    ScrollInfo.nMax := TopMax+ClientWidth;
    ScrollInfo.nPage := ClientWidth;
    ScrollInfo.nPos := TopY;
    SetScrollInfo(Handle, SB_VERT, ScrollInfo, True);
    ShowScrollBar(Handle,SB_VERT,True);
  end;
end;

procedure TOIPropertyGrid.CreateParams(var Params: TCreateParams);
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);
  ClassStylesOff = CS_VREDRAW or CS_HREDRAW;
begin
  inherited CreateParams(Params);
  with Params do begin
    {$R-}
    WindowClass.Style := WindowClass.Style and not ClassStylesOff;
    Style := Style or WS_VSCROLL or BorderStyles[fBorderStyle]
      or WS_CLIPCHILDREN;
    {$R+}
    if NewStyleControls and Ctl3D and (fBorderStyle = bsSingle) then begin
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    end;
  end;
end;

procedure TOIPropertyGrid.SetBorderStyle(Value: TBorderStyle);
begin
  if fBorderStyle <> Value then begin
    fBorderStyle := Value;
    RecreateWnd;
  end;
end;

procedure TOIPropertyGrid.WMVScroll(var Msg: TWMScroll);
begin
  case Msg.ScrollCode of
      // Scrolls to start / end of the text
    SB_TOP:        TopY := 0;
    SB_BOTTOM:     TopY := TopMax;
      // Scrolls one line up / down
    SB_LINEDOWN:   TopY := TopY + DefaultItemHeight div 2;
    SB_LINEUP:     TopY := TopY - DefaultItemHeight div 2;
      // Scrolls one page of lines up / down
    SB_PAGEDOWN:   TopY := TopY + ClientHeight - DefaultItemHeight;
    SB_PAGEUP:     TopY := TopY - ClientHeight + DefaultItemHeight;
      // Scrolls to the current scroll bar position
    SB_THUMBPOSITION,
    SB_THUMBTRACK: TopY := Msg.Pos;
      // Ends scrolling
    SB_ENDSCROLL: ;
  end;
end;

procedure TOIPropertyGrid.WMSize(var Msg: TWMSize);
begin
  inherited;
  UpdateScrollBar;
end;

destructor TOIPropertyGrid.Destroy;
var a:integer;
begin
  FItemIndex:=-1;
  for a:=0 to FRows.Count-1 do Rows[a].Free;
  FRows.Free;
  FComponentList.Free;
  FValueFont.Free;
  FNameFont.Free;
  FExpandedProperties.Free;
  inherited Destroy;
end;

procedure TOIPropertyGrid.SetSelections(
  const NewSelections:TComponentSelectionList);
var a:integer;
  CurRow:TOIPropertyGridRow;
  OldSelectedRowPath:string;
begin
  OldSelectedRowPath:=PropertyPath(ItemIndex);
  ItemIndex:=-1;
  for a:=0 to FRows.Count-1 do
    Rows[a].Free;
  FRows.Clear;
  FComponentList.Assign(NewSelections);
  BuildPropertyList;
  CurRow:=GetRowByPath(OldSelectedRowPath);
  if CurRow<>nil then
    ItemIndex:=CurRow.Index;
end;

procedure TOIPropertyGrid.SetPropertyEditorHook(
NewPropertyEditorHook:TPropertyEditorHook);
begin
  if FPropertyEditorHook=NewPropertyEditorHook then exit;
  FPropertyEditorHook:=NewPropertyEditorHook;
  SetSelections(FComponentList);
end;

function TOIPropertyGrid.PropertyPath(Index:integer):string;
var CurRow:TOIPropertyGridRow;
begin
  if (Index>=0) and (Index<FRows.Count) then begin
    CurRow:=Rows[Index];
    Result:=CurRow.Name;
    CurRow:=CurRow.Parent;
    while CurRow<>nil do begin
      Result:=CurRow.Name+'.'+Result;
      CurRow:=CurRow.Parent;
    end;
  end else Result:='';
end;

function TOIPropertyGrid.GetRowByPath(PropPath:string):TOIPropertyGridRow;
// searches PropPath. Expands automatically parent rows
var CurName:string;
  s,e:integer;
  CurParentRow:TOIPropertyGridRow;
begin
  Result:=nil;
  if FRows.Count=0 then exit;
  CurParentRow:=nil;
  s:=1;
  while (s<=length(PropPath)) do begin
    e:=s;
    while (e<=length(PropPath)) and (PropPath[e]<>'.') do inc(e);
    CurName:=uppercase(copy(PropPath,s,e-s));
    s:=e+1;
    // search name in childs
    if CurParentRow=nil then
      Result:=Rows[0]
    else
      Result:=CurParentRow.FirstChild;
    while (Result<>nil) and (uppercase(Result.Name)<>CurName) do
      Result:=Result.NextBrother;
    if Result=nil then begin
      exit;
    end else begin
      // expand row
      CurParentRow:=Result;
      ExpandRow(CurParentRow.Index);
    end;
  end;
  if s<=length(PropPath) then Result:=nil;
end;

procedure TOIPropertyGrid.SetRowValue;
var CurRow:TOIPropertyGridRow;
  NewValue:string;
begin
  if (FChangingItemIndex=false) and (FCurrentEdit<>nil)
  and (FItemIndex>=0) and (FItemIndex<FRows.Count) then begin
    CurRow:=Rows[FItemIndex];
    if FCurrentEdit=ValueEdit then
      NewValue:=ValueEdit.Text
    else
      NewValue:=ValueComboBox.Text;
    if NewValue<>CurRow.Editor.GetVisualValue then begin
      try
        CurRow.Editor.SetValue(NewValue);
      except
writeln('[TOIPropertyGrid.SetRowValue] OH NO');
      end;
    end;
  end;
end;

procedure TOIPropertyGrid.ValueEditKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_UP) and (FItemIndex>0) then begin
    ItemIndex:=ItemIndex-1;
  end;
  if (Key=VK_Down) and (FItemIndex<FRows.Count-1) then begin
    ItemIndex:=ItemIndex+1;
  end;
end;

procedure TOIPropertyGrid.ValueEditExit(Sender: TObject);
begin
  SetRowValue;
end;

procedure TOIPropertyGrid.ValueEditChange(Sender: TObject);
var CurRow:TOIPropertyGridRow;
begin
  if (FCurrentEdit<>nil) and (FItemIndex>=0) and (FItemIndex<FRows.Count) then
  begin
    CurRow:=Rows[FItemIndex];
    if paAutoUpdate in CurRow.Editor.GetAttributes then
      SetRowValue;
  end;
end;

procedure TOIPropertyGrid.ValueComboBoxExit(Sender: TObject);
begin
  SetRowValue;
end;

procedure TOIPropertyGrid.ValueComboBoxChange(Sender: TObject);
var i:integer;
begin
  i:=TComboBox(Sender).Items.IndexOf(TComboBox(Sender).Text);
  if i>=0 then SetRowValue;
end;

procedure TOIPropertyGrid.ValueComboBoxKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if (Key=VK_UP) and (FItemIndex>0) then begin
    ItemIndex:=ItemIndex-1;
  end;
  if (Key=VK_Down) and (FItemIndex<FRows.Count-1) then begin
    ItemIndex:=ItemIndex+1;
  end;
end;

procedure TOIPropertyGrid.ValueButtonClick(Sender: TObject);
var CurRow:TOIPropertyGridRow;
begin
  if (FCurrentEdit<>nil) and (FItemIndex>=0) and (FItemIndex<FRows.Count) then
  begin
    CurRow:=Rows[FItemIndex];
    if paDialog in CurRow.Editor.GetAttributes then begin
      CurRow.Editor.Edit;
      if FCurrentEdit=ValueEdit then
        ValueEdit.Text:=CurRow.Editor.GetVisualValue
      else
        ValueComboBox.Text:=CurRow.Editor.GetVisualValue;
    end;
  end;
end;

procedure TOIPropertyGrid.SetItemIndex(NewIndex:integer);
var NewRow:TOIPropertyGridRow;
  NewValue:string;
begin
  SetRowValue;
  FChangingItemIndex:=true;
  if (FItemIndex<>NewIndex) then begin
    if (FItemIndex>=0) and (FItemIndex<FRows.Count) then
      Rows[FItemIndex].Editor.Deactivate;
    FItemIndex:=NewIndex;
    if FCurrentEdit<>nil then begin
      FCurrentEdit.Visible:=false;
      FCurrentEdit.Enabled:=false;
      FCurrentEdit:=nil;
    end;
    if FCurrentButton<>nil then begin
      FCurrentButton.Visible:=false;
      FCurrentButton.Enabled:=false;
      FCurrentButton:=nil;
    end;
    if (NewIndex>=0) and (NewIndex<FRows.Count) then begin
      NewRow:=Rows[NewIndex];
      NewRow.Editor.Activate;
      if paDialog in NewRow.Editor.GetAttributes then begin
        FCurrentButton:=ValueButton;
        FCurrentButton.Visible:=true;
      end;
      NewValue:=NewRow.Editor.GetVisualValue;
      if paValueList in NewRow.Editor.GetAttributes then begin
        FCurrentEdit:=ValueComboBox;
        ValueComboBox.MaxLength:=NewRow.Editor.GetEditLimit;
        ValueComboBox.Items.BeginUpdate;
        ValueComboBox.Items.Text:='';
        // XXX
        //ValueComboBox.Sorted:=paSortList in Node.Director.GetAttributes;
        NewRow.Editor.GetValues(@AddStringToComboBox);
        ValueComboBox.Text:=NewValue;
        ValueComboBox.Items.EndUpdate;
        ValueComboBox.Visible:=true;
      end else begin
        FCurrentEdit:=ValueEdit;
        // XXX
        //ValueEdit.ReadOnly:=paReadOnly in NewRow.Editor.GetAttributes;
        //ValueEdit.MaxLength:=NewRow.Editor.GetEditLimit;
        ValueEdit.Text:=NewValue;
        ValueEdit.Visible:=true;
      end;
      AlignEditComponents;
      if FCurrentEdit<>nil then begin
        FCurrentEdit.Enabled:=true;
        if (FDragging=false) and (FCurrentEdit.Showing) then
          FCurrentEdit.SetFocus;
      end;
      if FCurrentButton<>nil then
        FCurrentButton.Enabled:=true;
    end;
  end;
  FChangingItemIndex:=false;
end;

function TOIPropertyGrid.GetRowCount:integer;
begin
  Result:=FRows.Count;
end;

procedure TOIPropertyGrid.BuildPropertyList;
var a:integer;
  CurRow:TOIPropertyGridRow;
  OldSelectedRowPath:string;
begin
  OldSelectedRowPath:=PropertyPath(ItemIndex);
  ItemIndex:=-1;
  for a:=0 to FRows.Count-1 do Rows[a].Free;
  FRows.Clear;
  GetComponentProperties(FPropertyEditorHook,FComponentList,FFilter,
    @AddPropertyEditor);
  SetItemsTops;
  for a:=FExpandedProperties.Count-1 downto 0 do begin
    CurRow:=GetRowByPath(FExpandedProperties[a]);
    if CurRow<>nil then
      ExpandRow(CurRow.Index);
  end;
  CurRow:=GetRowByPath(OldSelectedRowPath);
  if CurRow<>nil then begin
    ItemIndex:=CurRow.Index;
  end;
  UpdateScrollBar;
  Invalidate;
end;

procedure TOIPropertyGrid.AddPropertyEditor(PropEditor: TPropertyEditor);
var NewRow:TOIPropertyGridRow;
begin
  NewRow:=TOIPropertyGridRow.Create(Self,PropEditor,nil);
  FRows.Add(NewRow);
  if FRows.Count>1 then begin
    NewRow.FPriorBrother:=Rows[FRows.Count-2];
    NewRow.FPriorBrother.FNextBrother:=NewRow;
  end;
end;

procedure TOIPropertyGrid.AddStringToComboBox(const s:string);
var NewIndex:integer;
begin
  NewIndex:=ValueComboBox.Items.Add(s);
  if ValueComboBox.Text=s then
    ValueComboBox.ItemIndex:=NewIndex;
end;

procedure TOIPropertyGrid.ExpandRow(Index:integer);
var a:integer;
  CurPath:string;
  AlreadyInExpandList:boolean;
begin
  FExpandingRow:=Rows[Index];
  if (FExpandingRow.Expanded)
  or (not (paSubProperties in FExpandingRow.Editor.GetAttributes))
  then begin
    FExpandingRow:=nil;
    exit;
  end;
  FExpandingRow.Editor.GetProperties(@AddSubEditor);
  SetItemsTops;
  FExpandingRow.FExpanded:=true;
  a:=0;
  CurPath:=uppercase(PropertyPath(FExpandingRow.Index));
  AlreadyInExpandList:=false;
  while a<FExpandedProperties.Count do begin
    if FExpandedProperties[a]=copy(CurPath,1,length(FExpandedProperties[a]))
    then begin
      if length(FExpandedProperties[a])=length(CurPath) then begin
        AlreadyInExpandList:=true;
        inc(a);
      end else begin
        FExpandedProperties.Delete(a);
      end;
    end else begin
      inc(a);
    end;
  end;
  if not AlreadyInExpandList then
    FExpandedProperties.Add(CurPath);
  FExpandingRow:=nil;
  UpdateScrollBar;
  Invalidate;
end;

procedure TOIPropertyGrid.ShrinkRow(Index:integer);
var CurRow:TOIPropertyGridRow;
  StartIndex,EndIndex,a:integer;
  CurPath:string;
begin
  CurRow:=Rows[Index];
  if (not CurRow.Expanded) then exit;
  if CurRow.NextBrother=nil then StartIndex:=FRows.Count-1
  else StartIndex:=CurRow.NextBrother.Index-1;
  EndIndex:=CurRow.Index+1;
  for a:=StartIndex downto EndIndex do begin
    Rows[a].Free;
    FRows.Delete(a);
  end;
  SetItemsTops;
  CurRow.FExpanded:=false;
  CurPath:=uppercase(PropertyPath(CurRow.Index));
  a:=0;
  while a<FExpandedProperties.Count do begin
    if copy(FExpandedProperties[a],1,length(CurPath))=CurPath then
      FExpandedProperties.Delete(a)
    else
      inc(a);
  end;
  if CurRow.Parent<>nil then
    FExpandedProperties.Add(PropertyPath(CurRow.Parent.Index));
  UpdateScrollBar;
  Invalidate;
end;

procedure TOIPropertyGrid.AddSubEditor(PropEditor:TPropertyEditor);
var NewRow:TOIPropertyGridRow;
  NewIndex:integer;
begin
  NewRow:=TOIPropertyGridRow.Create(Self,PropEditor,FExpandingRow);
  NewIndex:=FExpandingRow.Index+1+FExpandingRow.ChildCount;
  FRows.Insert(NewIndex,NewRow);
  if FExpandingRow.FFirstChild=nil then
    FExpandingRow.FFirstChild:=NewRow;
  NewRow.FPriorBrother:=FExpandingRow.FLastChild;
  FExpandingRow.FLastChild:=NewRow;
  if NewRow.FPriorBrother<>nil then NewRow.FPriorBrother.FNextBrother:=NewRow;
  inc(FExpandingRow.FChildCount);
end;

function TOIPropertyGrid.MouseToIndex(y:integer;MustExist:boolean):integer;
var l,r,m:integer;
begin
  l:=0;
  r:=FRows.Count-1;
  inc(y,FTopY);
  while (l<=r) do begin
    m:=(l+r) shr 1;
    if Rows[m].Top>y then begin
      r:=m-1;
    end else if Rows[m].Bottom<=y then begin
      l:=m+1;
    end else begin
      Result:=m;  exit;
    end;
  end;
  if (MustExist=false) and (FRows.Count>0) then begin
    if y<0 then Result:=0
    else Result:=FRows.Count-1;
  end else Result:=-1;
end;

procedure TOIPropertyGrid.MouseDown(Button:TMouseButton;  Shift:TShiftState;
  X,Y:integer);
var IconX,Index:integer;
  PointedRow:TOIpropertyGridRow;
begin
  //ShowMessageDialog('X'+IntToStr(X)+',Y'+IntToStr(Y));
  //inherited MouseDown(Button,Shift,X,Y);
  // XXX
  // the MouseDown event is fired two times
  // this is a workaround
  if FOldMouseDownY=Y then begin
    FOldMouseDownY:=-1;
    exit;
  end else FOldMouseDownY:=Y;

  if Button=mbLeft then begin
    if Cursor=crHSplit then begin
      FDragging:=true;
    end else begin
      Index:=MouseToIndex(Y,false);
      ItemIndex:=Index;
      if (Index>=0) and (Index<FRows.Count) then begin
        IconX:=GetTreeIconX(Index);
        if (X>=IconX) and (X<=IconX+FIndent) then begin
          PointedRow:=Rows[Index];
          if paSubProperties in PointedRow.Editor.GetAttributes then begin
            if PointedRow.Expanded then
              ShrinkRow(Index)
            else
              ExpandRow(Index);
          end;
        end;
      end;
    end;
  end;
end;

procedure TOIPropertyGrid.MouseMove(Shift:TShiftState;  X,Y:integer);
var SplitDistance:integer;
begin
  //inherited MouseMove(Shift,X,Y);
  SplitDistance:=X-SplitterX;
  if FDragging then begin
    if ssLeft in Shift then begin
      SplitterX:=SplitterX+SplitDistance;
    end else begin
      EndDragSplitter;
    end;
  end else begin
    if (abs(SplitDistance)<=2) then begin
      Cursor:=crHSplit;
    end else begin
      Cursor:=crDefault;
    end;
  end;
end;

procedure TOIPropertyGrid.MouseUp(Button:TMouseButton;  Shift:TShiftState;
X,Y:integer);
begin
  if FDragging then EndDragSplitter;
  inherited MouseUp(Button,Shift,X,Y);
end;

procedure TOIPropertyGrid.EndDragSplitter;
begin
  if FDragging then begin
    Cursor:=crDefault;
    FDragging:=false;
    if FCurrentEdit<>nil then FCurrentEdit.SetFocus;
  end;
end;

procedure TOIPropertyGrid.SetSplitterX(const NewValue:integer);
var AdjustedValue:integer;
begin
  AdjustedValue:=NewValue;
  if AdjustedValue>ClientWidth then AdjustedValue:=ClientWidth;
  if AdjustedValue<1 then AdjustedValue:=1;
  if FSplitterX<>AdjustedValue then begin
    FSplitterX:=AdjustedValue;
    AlignEditComponents;
    Invalidate;
  end;
end;

procedure TOIPropertyGrid.SetTopY(const NewValue:integer);
begin
  if FTopY<>NewValue then begin
    FTopY:=NewValue;
    if FTopY<0 then FTopY:=0;
    UpdateScrollBar;
    ItemIndex:=-1;
    Invalidate;
  end;
end;

procedure TOIPropertyGrid.SetBounds(aLeft,aTop,aWidth,aHeight:integer);
begin
  inherited SetBounds(aLeft,aTop,aWidth,aHeight);
  if Visible then begin
    SplitterX:=SplitterX;
    AlignEditComponents;
  end;
end;

function TOIPropertyGrid.GetTreeIconX(Index:integer):integer;
begin
  Result:=Rows[Index].Lvl*Indent+2;
end;

function TOIPropertyGrid.TopMax:integer;
begin
  Result:=GridHeight-ClientHeight+2*BorderWidth;
  if Result<0 then Result:=0;
end;

function TOIPropertyGrid.GridHeight:integer;
begin
  if FRows.Count>0 then
    Result:=Rows[FRows.Count-1].Bottom
  else
    Result:=0;
end;

procedure TOIPropertyGrid.AlignEditComponents;
var RRect,EditCompRect,EditBtnRect:TRect;

  function CompareRectangles(r1,r2:TRect):boolean;
  begin
    Result:=(r1.Left=r2.Left) and (r1.Top=r2.Top) and (r1.Right=r2.Right)
       and (r1.Bottom=r2.Bottom);
  end;

// AlignEditComponents
begin
  if ItemIndex>=0 then begin
    RRect:=RowRect(ItemIndex);
    EditCompRect:=RRect;
    EditCompRect.Top:=EditCompRect.Top-1;
    EditCompRect.Left:=RRect.Left+SplitterX;
    if FCurrentButton<>nil then begin
      // edit dialog button
      with EditBtnRect do begin
        Top:=RRect.Top;
        Left:=RRect.Right-20;
        Bottom:=RRect.Bottom;
        Right:=RRect.Right;
        EditCompRect.Right:=Left;
      end;
      if not CompareRectangles(FCurrentButton.BoundsRect,EditBtnRect) then begin
        FCurrentButton.BoundsRect:=EditBtnRect;
        //FCurrentButton.Invalidate;
      end;
    end;
    if FCurrentEdit<>nil then begin
      // edit component
      EditCompRect.Left:=EditCompRect.Left-1;
      // XXX
      //
      EditCompRect.Bottom:=EditCompRect.Top+FCurrentEdit.Height;
      if not CompareRectangles(FCurrentEdit.BoundsRect,EditCompRect) then begin
        FCurrentEdit.BoundsRect:=EditCompRect;
        FCurrentEdit.Invalidate;
      end;
    end;
  end;
end;

procedure TOIPropertyGrid.PaintRow(ARow:integer);
var ARowRect,NameRect,NameIconRect,NameTextRect,ValueRect:TRect;
  IconX,IconY:integer;
  CurRow:TOIPropertyGridRow;
  DrawState:TPropEditDrawState;
  OldFont:TFont;

  procedure DrawTreeIcon(x,y:integer;Plus:boolean);
  begin
    with Canvas do begin
      Brush.Color:=clWhite;
      Pen.Color:=clBlack;
      Rectangle(x,y,x+8,y+8);
      MoveTo(x+2,y+4);
      LineTo(x+7,y+4);
      if Plus then begin
        MoveTo(x+4,y+2);
        LineTo(x+4,y+7);
      end;
    end;
  end;

// PaintRow
begin
  CurRow:=Rows[ARow];
  ARowRect:=RowRect(ARow);
  NameRect:=ARowRect;
  ValueRect:=ARowRect;
  NameRect.Right:=SplitterX;
  ValueRect.Left:=SplitterX;
  IconX:=GetTreeIconX(ARow);
  IconY:=((NameRect.Bottom-NameRect.Top-9) div 2)+NameRect.Top;
  NameIconRect:=NameRect;
  NameIconRect.Right:=IconX+Indent;
  NameTextRect:=NameRect;
  NameTextRect.Left:=NameIconRect.Right;
  DrawState:=[];
  if ARow=FItemIndex then Include(DrawState,pedsSelected);
  with Canvas do begin
    // draw name background
    if FBackgroundColor<>clNone then begin
      Brush.Color:=FBackgroundColor;
      FillRect(NameIconRect);
      FillRect(NameTextRect);
    end;
    // draw icon
    if paSubProperties in CurRow.Editor.GetAttributes then begin
      DrawTreeIcon(IconX,IconY,not CurRow.Expanded);
    end;
    // draw name
    OldFont:=Font;
    Font:=FNameFont;
    CurRow.Editor.PropDrawName(Canvas,NameTextRect,DrawState);
    Font:=OldFont;
    // draw frame
    Pen.Color:=cl3DDkShadow;
    MoveTo(NameRect.Left,NameRect.Bottom-1);
    LineTo(NameRect.Right-1,NameRect.Bottom-1);
    LineTo(NameRect.Right-1,NameRect.Top-1);
    if ARow=FItemIndex then begin
      Pen.Color:=cl3DDkShadow;
      MoveTo(NameRect.Left,NameRect.Bottom-1);
      LineTo(NameRect.Left,NameRect.Top);
      LineTo(NameRect.Right-1,NameRect.Top);
      Pen.Color:=cl3DLight;
      MoveTo(NameRect.Left+1,NameRect.Bottom-2);
      LineTo(NameRect.Right-1,NameRect.Bottom-2);
    end;
    // draw value background
    if FBackgroundColor<>clNone then begin
      Brush.Color:=FBackgroundColor;
      FillRect(ValueRect);
    end;
    // draw value
    if ARow<>ItemIndex then begin
      OldFont:=Font;
      Font:=FValueFont;
      CurRow.Editor.PropDrawValue(Canvas,ValueRect,DrawState);
      Font:=OldFont;
    end;
    CurRow.LastPaintedValue:=CurRow.Editor.GetVisualValue;
    // draw frame
    Pen.Color:=cl3DDkShadow;
    MoveTo(ValueRect.Left-1,ValueRect.Bottom-1);
    LineTo(ValueRect.Right,ValueRect.Bottom-1);
    Pen.Color:=cl3DLight;
    MoveTo(ValueRect.Left,ValueRect.Bottom-1);
    LineTo(ValueRect.Left,ValueRect.Top);
    if ARow=FItemIndex then begin
      MoveTo(ValueRect.Left,ValueRect.Bottom-2);
      LineTo(ValueRect.Right,ValueRect.Bottom-2);
    end;
  end;
end;

procedure TOIPropertyGrid.DoPaint(PaintOnlyChangedValues:boolean);
var a:integer;
  SpaceRect:TRect;
begin
  if not PaintOnlyChangedValues then begin
    with Canvas do begin
      // draw properties
      for a:=0 to FRows.Count-1 do begin
        PaintRow(a);
      end;
      // draw unused space below rows
      SpaceRect:=Rect(BorderWidth,BorderWidth,ClientWidth,Height-BorderWidth);
      if FRows.Count>0 then
        SpaceRect.Top:=Rows[FRows.Count-1].Bottom-FTopY+BorderWidth;
// TWinControl(Parent).InvalidateRect(Self,SpaceRect,true);
      if FBackgroundColor<>clNone then begin
        Brush.Color:=FBackgroundColor;
        FillRect(SpaceRect);
      end;
      // draw border
      Pen.Color:=cl3DDkShadow;
      for a:=0 to BorderWidth-1 do begin
        MoveTo(a,Self.Height-1-a);
        LineTo(a,a);
        LineTo(Self.Width-1-a,a);
      end;
      Pen.Color:=cl3DLight;
      for a:=0 to BorderWidth-1 do begin
        MoveTo(Self.Width-1-a,a);
        LineTo(Self.Width-1-a,Self.Height-1-a);
        LineTo(a,Self.Height-1-a);
      end;
    end;
  end else begin
    for a:=0 to FRows.Count-1 do begin
      if Rows[a].Editor.GetVisualValue<>Rows[a].LastPaintedValue then
        PaintRow(a);
    end;
  end;
end;

procedure TOIPropertyGrid.Paint;
begin
  inherited Paint;
  DoPaint(false);
end;

procedure TOIPropertyGrid.RefreshPropertyValues;
begin
  DoPaint(true);
end;

function TOIPropertyGrid.RowRect(ARow:integer):TRect;
begin
  Result.Left:=BorderWidth;
  Result.Top:=Rows[ARow].Top-FTopY+BorderWidth;
  Result.Right:=ClientWidth-15;
  Result.Bottom:=Rows[ARow].Bottom-FTopY+BorderWidth;
end;

procedure TOIPropertyGrid.SetItemsTops;
// compute row tops from row heights
// set indices of all rows
var a,scrollmax:integer;
begin
  for a:=0 to FRows.Count-1 do
    Rows[a].Index:=a;
  if FRows.Count>0 then
    Rows[0].Top:=0;
  for a:=1 to FRows.Count-1 do
    Rows[a].FTop:=Rows[a-1].Bottom;
  if FRows.Count>0 then
    scrollmax:=Rows[FRows.Count-1].Bottom-Height
  else
    scrollmax:=10;
  if scrollmax<10 then scrollmax:=10;
end;

procedure TOIPropertyGrid.ClearRows;
var a:integer;
begin
  for a:=0 to FRows.Count-1 do begin
    Rows[a].Free;
  end;
  FRows.Clear;
end;

procedure TOIPropertyGrid.Clear;
begin
  ClearRows;
end;

function TOIPropertyGrid.GetRow(Index:integer):TOIPropertyGridRow;
begin
  Result:=TOIPropertyGridRow(FRows[Index]);
end;

//------------------------------------------------------------------------------

{ TOIPropertyGridRow }

constructor TOIPropertyGridRow.Create(PropertyTree:TOIPropertyGrid;
PropEditor:TPropertyEditor;  ParentNode:TOIPropertyGridRow);
begin
  inherited Create;
  // tree pointer
  FTree:=PropertyTree;
  FParent:=ParentNode;
  FNextBrother:=nil;
  FPriorBrother:=nil;
  FExpanded:=false;
  // child nodes
  FChildCount:=0;
  FFirstChild:=nil;
  FLastChild:=nil;
  // director
  FEditor:=PropEditor;
  GetLvl;
  FName:=FEditor.GetName;
  FTop:=0;
  FHeight:=FTree.DefaultItemHeight;
  Index:=-1;
  LastPaintedValue:='';
end;

destructor TOIPropertyGridRow.Destroy;
begin
  if FPriorBrother<>nil then FPriorBrother.FNextBrother:=FNextBrother;
  if FNextBrother<>nil then FNextBrother.FPriorBrother:=FPriorBrother;
  if FParent<>nil then begin
    if FParent.FFirstChild=Self then FParent.FFirstChild:=FNextBrother;
    if FParent.FLastChild=Self then FParent.FLastChild:=FPriorBrother;
    dec(FParent.FChildCount);
  end;
  if FEditor<>nil then FEditor.Free;
  inherited Destroy;
end;

procedure TOIPropertyGridRow.GetLvl;
var n:TOIPropertyGridRow;
begin
  FLvl:=0;
  n:=FParent;
  while n<>nil do begin
    inc(FLvl);
    n:=n.FParent;
  end;
end;

function TOIPropertyGridRow.Bottom:integer;
begin
  Result:=FTop+FHeight;
end;

//==============================================================================


{ TOIOptions }

constructor TOIOptions.Create;
begin
  inherited Create;
  FFilename:='';

  FSaveBounds:=false;
  FLeft:=0;
  FTop:=0;
  FWidth:=250;
  FHeight:=400;
  FPropertyGridSplitterX:=110;
  FEventGridSplitterX:=110;

  FGridBackgroundColor:=clBtnFace;
end;

destructor TOIOptions.Destroy;
begin

  inherited Destroy;
end;

function TOIOptions.Load:boolean;
var XMLConfig: TXMLConfig;
begin
  Result:=false;
  if not FileExists(FFilename) then exit;
  try
    XMLConfig:=TXMLConfig.Create(FFileName);
    try
      FSaveBounds:=XMLConfig.GetValue('ObjectInspectorOptions/Bounds/Valid'
                       ,false);
      if FSaveBounds then begin
        FLeft:=XMLConfig.GetValue('ObjectInspectorOptions/Bounds/Left',0);
        FTop:=XMLConfig.GetValue('ObjectInspectorOptions/Bounds/Top',0);
        FWidth:=XMLConfig.GetValue('ObjectInspectorOptions/Bounds/Width',250);
        FHeight:=XMLConfig.GetValue('ObjectInspectorOptions/Bounds/Height',400);
        FPropertyGridSplitterX:=XMLConfig.GetValue(
           'ObjectInspectorOptions/Bounds/PropertyGridSplitterX',110);
        FEventGridSplitterX:=XMLConfig.GetValue(
           'ObjectInspectorOptions/Bounds/EventGridSplitterX',110);
      end;

      FGridBackgroundColor:=XMLConfig.GetValue(
           'ObjectInspectorOptions/GridBackgroundColor',clBtnFace);
    finally
      XMLConfig.Free;
    end;
  except
    exit;
  end;
  Result:=true;
end;

function TOIOptions.Save:boolean;
var XMLConfig: TXMLConfig;
begin
  Result:=false;
  try
    XMLConfig:=TXMLConfig.Create(FFileName);
    try
      XMLConfig.SetValue('ObjectInspectorOptions/Bounds/Valid',FSaveBounds);
      if FSaveBounds then begin
        XMLConfig.SetValue('ObjectInspectorOptions/Bounds/Left',FLeft);
        XMLConfig.SetValue('ObjectInspectorOptions/Bounds/Top',FTop);
        XMLConfig.SetValue('ObjectInspectorOptions/Bounds/Width',FWidth);
        XMLConfig.SetValue('ObjectInspectorOptions/Bounds/Height',FHeight);
        XMLConfig.SetValue(
           'ObjectInspectorOptions/Bounds/PropertyGridSplitterX'
           ,FPropertyGridSplitterX);
        XMLConfig.SetValue(
           'ObjectInspectorOptions/Bounds/EventGridSplitterX'
           ,FEventGridSplitterX);
      end;

      XMLConfig.SetValue('ObjectInspectorOptions/GridBackgroundColor'
         ,FGridBackgroundColor);
    finally
      XMLConfig.Flush;
      XMLConfig.Free;
    end;
  except
    exit;
  end;
  Result:=true;
end;

procedure TOIOptions.Assign(AnObjInspector: TObjectInspector);
begin
  FLeft:=AnObjInspector.Left;
  FTop:=AnObjInspector.Top;
  FWidth:=AnObjInspector.Width;
  FHeight:=AnObjInspector.Height;
  FPropertyGridSplitterX:=AnObjInspector.PropertyGrid.SplitterX;
  FEventGridSplitterX:=AnObjInspector.EventGrid.SplitterX;
  FGridBackgroundColor:=AnObjInspector.PropertyGrid.BackgroundColor;
end;

procedure TOIOptions.AssignTo(AnObjInspector: TObjectInspector);
begin
  if FSaveBounds then begin
    AnObjInspector.SetBounds(FLeft,FTop,FWidth,FHeight);
    AnObjInspector.PropertyGrid.SplitterX:=FPropertyGridSplitterX;
    AnObjInspector.EventGrid.SplitterX:=FEventGridSplitterX;
  end;
  AnObjInspector.PropertyGrid.BackgroundColor:=FGridBackgroundColor;
  AnObjInspector.EventGrid.BackgroundColor:=FGridBackgroundColor;
end;


//==============================================================================


{ TObjectInspector }

constructor TObjectInspector.Create(AOwner: TComponent);

  procedure AddPopupMenuItem(var NewMenuItem:TmenuItem;
     ParentMenuItem:TMenuItem; AName,ACaption,AHint:string;
     AOnClick: TNotifyEvent; CheckedFlag,EnabledFlag,VisibleFlag:boolean);
  begin
    NewMenuItem:=TMenuItem.Create(Self);
    with NewMenuItem do begin
      Name:=AName;
      Caption:=ACaption;
      Hint:=AHint;
      OnClick:=AOnClick;
      Checked:=CheckedFlag;
      Enabled:=EnabledFlag;
      Visible:=VisibleFlag;
    end;
    if ParentMenuItem<>nil then
      ParentMenuItem.Add(NewmenuItem)
    else
      MainPopupMenu.Items.Add(NewMenuItem);
  end;

begin
  inherited Create(AOwner);
  Caption := 'Object Inspector';
  FPropertyEditorHook:=nil;
  FComponentList:=TComponentSelectionList.Create;
  FUpdatingAvailComboBox:=false;
  Name := 'ObjectInspector';

  // StatusBar
  StatusBar:=TStatusBar.Create(Self);
  with StatusBar do begin
    Name:='StatusBar';
    Parent:=Self;
    SimpleText:='All';
    Show;
  end;

  // PopupMenu
  MainPopupMenu:=TPopupMenu.Create(Self);
  with MainPopupMenu do begin
    Name:='MainPopupMenu';
    AutoPopup:=true;
  end;
  AddPopupMenuItem(ColorsPopupmenuItem,nil,'ColorsPopupMenuItem','Colors',''
     ,nil,false,true,true);
  AddPopupMenuItem(BackgroundColPopupMenuItem,ColorsPopupMenuItem
     ,'BackgroundColPopupMenuItem','Background','Grid background color'
     ,@OnBackgroundColPopupMenuItemClick,false,true,true);

  PopupMenu:=MainPopupMenu;

  // combobox at top (filled with available components)
  AvailCompsComboBox := TComboBox.Create (Self);
  with AvailCompsComboBox do begin
    Name:='AvailCompsComboBox';
    Parent:=Self;
    Style:=csDropDown;
    Text:='';
    OnChange:=@AvailComboBoxChange;
    //Sorted:=true;
    Show;
  end;

  // NoteBook
  NoteBook:=TNoteBook.Create(Self);
  with NoteBook do begin
    Name:='NoteBook';
    Parent:=Self;
    Pages.Strings[0]:='Properties';
    Pages.Add('Events');
    PopupMenu:=MainPopupMenu;
    Show;
  end;

  // property grid
  PropertyGrid:=TOIPropertyGrid.Create(Self,PropertyEditorHook
      ,[tkUnknown, tkInteger, tkChar, tkEnumeration, tkFloat, tkSet{, tkMethod}
      , tkSString, tkLString, tkAString, tkWString, tkVariant
      {, tkArray, tkRecord, tkInterface}, tkClass, tkObject, tkWChar, tkBool
      , tkInt64, tkQWord]);
  with PropertyGrid do begin
    Name:='PropertyGrid';
    Parent:=NoteBook.Page[0];
    ValueEdit.Parent:=Parent;
    ValueComboBox.Parent:=Parent;
    ValueButton.Parent:=Parent;
    Selections:=Self.FComponentList;
    Align:=alClient;
    PopupMenu:=MainPopupMenu;
    Show;
  end;

  // event grid
  EventGrid:=TOIPropertyGrid.Create(Self,PropertyEditorHook,[tkMethod]);
  with EventGrid do begin
    Name:='EventGrid';
    Parent:=NoteBook.Page[1];
    ValueEdit.Parent:=Parent;
    ValueComboBox.Parent:=Parent;
    ValueButton.Parent:=Parent;
    Selections:=Self.FComponentList;
    Align:=alClient;
    PopupMenu:=MainPopupMenu;
    Show;
  end;

end;

destructor TObjectInspector.Destroy;
begin
  FComponentList.Free;
  inherited Destroy;
end;

procedure TObjectInspector.DoInnerResize;
var MaxX,MaxY,NewTop:integer;
begin
  if Visible=false then exit;
  MaxX:=ClientWidth;
  MaxY:=ClientHeight-20;

  // combobox at top (filled with available components)
  AvailCompsComboBox.SetBounds(0,0,MaxX-4,20);

  // notebook
  NewTop:=AvailCompsComboBox.Top+AvailCompsComboBox.Height+2;
  NoteBook.SetBounds(0,NewTop,MaxX-4,MaxY-NewTop);
end;

procedure TObjectInspector.SetPropertyEditorHook(NewValue:TPropertyEditorHook);
begin
//XXX writeln('OI: SetPropertyEditorHook');
  if FPropertyEditorHook<>NewValue then begin
    FPropertyEditorHook:=NewValue;
    FPropertyEditorHook.OnChangeLookupRoot:=@PropEditLookupRootChange;
    // select root component
    FComponentList.Clear;
    if (FPropertyEditorHook<>nil) and (FPropertyEditorHook.LookupRoot<>nil) then
      FComponentList.Add(FPropertyEditorHook.LookupRoot);
    FillComponentComboBox;
    PropertyGrid.PropertyEditorHook:=FPropertyEditorHook;
    EventGrid.PropertyEditorHook:=FPropertyEditorHook;
    RefreshSelections;
  end;
end;

function TObjectInspector.ComponentToString(c:TComponent):string;
begin
  Result:=c.GetNamePath+': '+c.ClassName;
end;

procedure TObjectInspector.AddComponentToAvailComboBox(AComponent:TComponent);
var Allowed:boolean;
begin
  Allowed:=true;
  if Assigned(FOnAddAvailableComponent) then
    FOnAddAvailableComponent(AComponent,Allowed);
  if Allowed then
    AvailCompsComboBox.Items.AddObject(
      ComponentToString(AComponent),AComponent);
end;

procedure TObjectInspector.PropEditLookupRootChange;
begin
  FillComponentComboBox;
end;

procedure TObjectInspector.FillComponentComboBox;
var a:integer;
  Root:TComponent;
  OldText:AnsiString;
begin
  if FUpdatingAvailComboBox then exit;
  FUpdatingAvailComboBox:=true;
  AvailCompsComboBox.Items.BeginUpdate;
  OldText:=AvailCompsComboBox.Text;
  AvailCompsComboBox.Items.Clear;
  if (FPropertyEditorHook<>nil)
  and (FPropertyEditorHook.LookupRoot<>nil) then begin
    Root:=FPropertyEditorHook.LookupRoot;
    AddComponentToAvailComboBox(Root);
    for a:=0 to Root.ComponentCount-1 do
      AddComponentToAvailComboBox(Root.Components[a]);
  end;
  AvailCompsComboBox.Items.EndUpdate;
  FUpdatingAvailComboBox:=false;
  a:=AvailCompsComboBox.Items.IndexOf(OldText);
  if (OldText='') or (a<0) then begin
    if AvailCompsComboBox.Items.Count>0 then
      AvailCompsComboBox.Text:=AvailCompsComboBox.Items[0]
    else
      AvailCompsComboBox.Text:='';
  end else
    AvailCompsComboBox.ItemIndex:=a;
end;

procedure TObjectInspector.SetSelections(
  const NewSelections:TComponentSelectionList);
begin
//writeln('[TObjectInspector.SetSelections]');
  if FComponentList.IsEqual(NewSelections) then exit;
  FComponentList.Assign(NewSelections);
  if FComponentList.Count=1 then begin
    AvailCompsComboBox.Text:=ComponentToString(FComponentList[0]);
  end else begin
    AvailCompsComboBox.Text:='';
  end;
  RefreshSelections;
end;

procedure TObjectInspector.RefreshSelections;
begin
  PropertyGrid.Selections:=FComponentList;
  EventGrid.Selections:=FComponentList;
end;

procedure TObjectInspector.RefreshPropertyValues;
begin
  PropertyGrid.RefreshPropertyValues;
  EventGrid.RefreshPropertyValues;
end;

procedure TObjectInspector.SetBounds(aLeft,aTop,aWidth,aHeight:integer);
begin
  inherited SetBounds(aLeft,aTop,aWidth,aHeight);
  DoInnerResize;
end;

procedure TObjectInspector.AvailComboBoxChange(Sender:TObject);
var NewComponent,Root:TComponent;
  a:integer;

  procedure SetSelectedComponent(c:TComponent);
  begin
    if (FComponentList.Count=1) and (FComponentList[0]=c) then exit;
    FComponentList.Clear;
    FComponentList.Add(c);
    RefreshSelections;
    if Assigned(FOnSelectComponentInOI) then
      FOnSelectComponentInOI(c);
  end;

// AvailComboBoxChange
begin
  if FUpdatingAvailComboBox then exit;
  if (FPropertyEditorHook=nil) or (FPropertyEditorHook.LookupRoot=nil) then
    exit;
  Root:=FPropertyEditorHook.LookupRoot;
  if AvailCompsComboBox.Text=ComponentToString(Root)
  then begin
    SetSelectedComponent(Root);
  end else begin
    for a:=0 to Root.ComponentCount-1 do begin
      NewComponent:=Root.Components[a];
      if AvailCompsComboBox.Text=ComponentToString(NewComponent) then begin
        SetSelectedComponent(NewComponent);
        break;
      end;
    end;
  end;
end;

procedure TObjectInspector.OnBackgroundColPopupMenuItemClick(Sender :TObject);
var ColorDialog:TColorDialog;
begin
  ColorDialog:=TColorDialog.Create(Application);
  try
    with ColorDialog do begin
      Color:=PropertyGrid.BackgroundColor;
      if Execute then begin
        PropertyGrid.BackgroundColor:=Color;
        EventGrid.BackgroundColor:=Color;
        PropertyGrid.Invalidate;
        EventGrid.Invalidate;
      end;
    end;
  finally
    ColorDialog.Free;
  end;
end;

end.

