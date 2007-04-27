{ $Id$ }
{
 /***************************************************************************
                       gtk2int.pas  -  GTK2 Interface Object
                       -------------------------------------


 ***************************************************************************/

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
 }

unit Gtk2Int;

{$mode objfpc}{$H+}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

uses
  Types, Classes, SysUtils,
  {$IfNDef GTK2_2}
    {$IfNDef Windows}
     XLib, X, //XUtil,
    {$EndIf}
  {$EndIf}

  gdk2pixbuf, gtk2, gdk2, glib2, Pango,

  LMessages, Controls, Forms, LCLProc, LCLStrConsts, LCLIntf, LCLType,
  DynHashArray, GraphType, GraphMath, Graphics, Menus,
  GTKWinApiWindow, StdCtrls, ComCtrls,
  Dialogs, ExtDlgs, LResources, Math, GTKGlobals,
  {Buttons, CListBox, Calendar, Arrow, Spin, FileCtrl, CommCtrl, ExtCtrls, }
  gtkDef, gtkFontCache, gtkInt, GtkExtra;

type

  { TGtk2WidgetSet }

  TGtk2WidgetSet = class(TGtkWidgetSet)
  protected
    procedure AppendText(Sender: TObject; Str: PChar);
    function CreateComponent(Sender : TObject): THandle; override;
    function GetText(Sender: TComponent; var Text: String): Boolean;
    procedure HookSignals(const AGTKObject: PGTKObject; const ALCLObject: TObject); override;
    function LoadStockPixmap(StockID: longint) : HBitmap; override;
    procedure SetCallbackEx(const AMsg: LongInt; const AGTKObject: PGTKObject; const ALCLObject: TObject; Direct: boolean);override;
    //procedure SetLabel(Sender : TObject; Data : Pointer);
    procedure SetSelectionMode(Sender: TObject; Widget: PGtkWidget;
      MultiSelect, ExtendedSelect: boolean); override;
    //function SetTopIndex(Sender: TObject; NewTopIndex: integer): integer; override;

    procedure InitializeFileDialog(FileDialog: TFileDialog;
      var SelWidget: PGtkWidget; Title: PChar); override;
    function CreateOpenDialogFilter(OpenDialog: TOpenDialog;
      SelWidget: PGtkWidget): string; override;
    procedure InitializeOpenDialog(OpenDialog: TOpenDialog;
      SelWidget: PGtkWidget); override;
    procedure CreatePreviewDialogControl(
      PreviewDialog: TPreviewFileDialog; SelWidget: PGtkWidget); override;
  public
    function WidgetSetName: string; override;
    {$I gtk2winapih.inc}
    {$I gtk2lclintfh.inc}
  end;

  { TGtkListStoreStringList }

  TGtkListStoreStringList = class(TStrings)
  private
    FColumnIndex : Integer;
    FGtkListStore : PGtkListStore;
    FOwner: TWinControl;
    FSorted : boolean;
    FStates: TGtkListStringsStates;
    FCachedCount: integer;
    FCachedItems: PGtkTreeIter;
    FUpdateCount: integer;
  protected
    function GetCount : integer; override;
    function Get(Index : Integer) : string; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AnObject: TObject); override;
    procedure SetSorted(Val : boolean); virtual;
    procedure UpdateItemCache;
  public
    constructor Create(ListStore : PGtkListStore;
                       ColumnIndex : Integer; TheOwner: TWinControl);
    destructor Destroy; override;
    function Add(const S: string): Integer; override;
    procedure Assign(Source : TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index : integer); override;
    function IndexOf(const S: string): Integer; override;
    procedure Insert(Index : integer; const S: string); override;
    procedure Sort; virtual;
    function IsEqual(List: TStrings): boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
  public
    property Sorted : boolean read FSorted write SetSorted;
    property Owner: TWinControl read FOwner;
  end;

var
  GTK2WidgetSet: TGTK2WidgetSet absolute GtkWidgetSet;


implementation
  
uses
////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To get as little as possible circles,
// uncomment only those units with implementation
////////////////////////////////////////////////////
// Gtk2WSActnList,
// Gtk2WSArrow,
// Gtk2WSButtons,
// Gtk2WSCalendar,
 Gtk2WSCheckLst,
// Gtk2WSCListBox,
 Gtk2WSComCtrls,
 Gtk2WSControls,
// Gtk2WSDbCtrls,
// Gtk2WSDBGrids,
// Gtk2WSDialogs,
// Gtk2WSDirSel,
// Gtk2WSEditBtn,
 Gtk2WSExtCtrls,
// Gtk2WSExtDlgs,
// Gtk2WSFileCtrl,
// Gtk2WSForms,
// Gtk2WSGrids,
// Gtk2WSImgList,
// Gtk2WSMaskEdit,
// Gtk2WSMenus,
// Gtk2WSPairSplitter,
// Gtk2WSSpin,
 Gtk2WSStdCtrls,
// Gtk2WSToolwin,
////////////////////////////////////////////////////
  gtkProc;

{$include gtk2object.inc}
{$include gtk2winapi.inc}
{$include gtk2lclintf.inc}

const
  GtkListStoreItemGtkListTag = 'GtkList';
  GtkListStoreItemLCLListTag = 'LCLList';

{*************************************************************}
{                      TGtkListStoreStringList methods             }
{*************************************************************}

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Create
  Params:
  Returns:

 ------------------------------------------------------------------------------}
constructor TGtkListStoreStringList.Create(ListStore : PGtkListStore;
  ColumnIndex : Integer; TheOwner: TWinControl);
begin
  inherited Create;
  if ListStore = nil then RaiseGDBException(
    'TGtkListStoreStringList.Create Unspecified list store');
  FGtkListStore:= ListStore;

  if (ColumnIndex < 0) or
    (ColumnIndex >= gtk_tree_model_get_n_columns(GTK_TREE_MODEL(ListStore)))
  then
    RaiseGDBException('TGtkListStoreStringList.Create Invalid Column Index');
  FColumnIndex:=ColumnIndex;

  if TheOwner = nil then RaiseGDBException(
    'TGtkListStoreStringList.Create Unspecified owner');
  FOwner:=TheOwner;
  Include(FStates,glsItemCacheNeedsUpdate);
end;

destructor TGtkListStoreStringList.Destroy;
begin
  // don't destroy the widgets
  ReAllocMem(FCachedItems,0);
  inherited Destroy;
end;

function TGtkListStoreStringList.Add(const S: string): Integer;
begin
  Result:=Count;
  Insert(Count,S);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStringList.SetSorted
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.SetSorted(Val : boolean);
var
  i: Integer;
begin
  if Val <> FSorted then begin
    if Val then begin
      for i:=0 to Count-2 do begin
        if AnsiCompareText(Strings[i],Strings[i+1])<0 then begin
          Sort;
          break;
        end;
      end;
    end;
    FSorted:= Val;
  end;
end;

{------------------------------------------------------------------------------
  procedure TGtkListStoreStringList.RemoveAllCallbacks;

 ------------------------------------------------------------------------------}

procedure TGtkListStoreStringList.UpdateItemCache;
var
  i: integer;
begin
  if not (glsItemCacheNeedsUpdate in FStates) then exit;
  if (FGtkListStore<>nil) then
    FCachedCount:= gtk_tree_model_iter_n_children(GTK_TREE_MODEL(FGtkListStore),nil)
  else
    FCachedCount:=0;
  ReAllocMem(FCachedItems,SizeOf(TGtkTreeIter)*FCachedCount);
  if FGtkListStore<>nil then
    For I := 0 to FCachedCount - 1 do
      gtk_tree_model_iter_nth_child(GTK_TREE_MODEL(FGtkListStore),
        @FCachedItems[i], nil, I);
  Exclude(FStates,glsItemCacheNeedsUpdate);
end;

procedure TGtkListStoreStringList.PutObject(Index: Integer; AnObject: TObject);
var
  ListItem : TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) then
    RaiseGDBException('TGtkListStoreStringList.PutObject Out of bounds.')
  else if FGtkListStore<>nil then begin
    UpdateItemCache;
    ListItem:=FCachedItems[Index];
    gtk_list_store_set(FGtkListStore, @ListItem,
                       [FColumnIndex+1, Pointer(AnObject), -1]);
  end;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Sort
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Sort;
var
  sl: TStringList;
  OldSorted: Boolean;
begin
  BeginUpdate;
  // sort internally (sorting in the widget would be slow and unpretty ;)
  sl:=TStringList.Create;
  sl.Assign(Self);
  MergeSort(sl,@AnsiCompareText);
  OldSorted:=Sorted;
  FSorted:=false;
  Assign(sl);
  FSorted:=OldSorted;
  sl.Free;
  EndUpdate;
end;

function TGtkListStoreStringList.IsEqual(List: TStrings): boolean;
var
  i, Cnt: integer;
begin
  if List=Self then begin
    Result:=true;
    exit;
  end;
  Result:=false;
  if List=nil then exit;
  BeginUpdate;
  Cnt:=Count;
  if (Cnt<>List.Count) then exit;
  for i:=0 to Cnt-1 do
    if (Strings[i]<>List[i]) or (Objects[i]<>List.Objects[i]) then exit;
  Result:=true;
  EndUpdate;
end;

procedure TGtkListStoreStringList.BeginUpdate;
begin
  inc(FUpdateCount);
end;

procedure TGtkListStoreStringList.EndUpdate;
begin
  dec(FUpdateCount);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Assign
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Assign(Source : TPersistent);
var
  i, Cnt: integer;
  CmpList: TStrings;
  OldSorted: Boolean;
begin
  if (Source=Self) or (Source=nil) then exit;
  if ((Source is TGtkListStoreStringList)
    and (TGtkListStoreStringList(Source).FGtkListStore=FGtkListStore))
  then
    RaiseGDBException('TGtkListStoreStringList.Assign: There are 2 lists with the same FGtkListStore');
  BeginUpdate;
  OldSorted:=Sorted;
  CmpList:=nil;
  try
    if Source is TStrings then begin
      // clearing and resetting can change other properties of the widget,
      // => don't change if the content is already the same
      if Sorted then begin
        CmpList:=TStringList.Create;
        CmpList.Assign(TStrings(Source));
        MergeSort(TStringList(CmpList),@AnsiCompareText);
      end else
        CmpList:=TStrings(Source);
      if IsEqual(CmpList) then exit;
      Clear;
      FSorted:=false;
      Cnt:=TStrings(Source).Count;
      for i:=0 to Cnt - 1 do begin
        AddObject(CmpList[i],CmpList.Objects[i]);
      end;
      // ToDo: restore other settings

      // Do not call inherited Assign as it does things we do not want to happen
    end else
      inherited Assign(Source);
  finally
    fSorted:=OldSorted;
    if CmpList<>Source then CmpList.Free;
    EndUpdate;
  end;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Get
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function TGtkListStoreStringList.Get(Index : integer) : string;
var
  Item : PChar;
  ListItem : TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) then
    RaiseGDBException('TGtkListStoreStringList.Get Out of bounds.')
  else begin
    UpdateItemCache;
    ListItem:=FCachedItems[Index];

    Item := nil;
    gtk_tree_model_get(GTK_TREE_MODEL(FGtkListStore), @ListItem,
                       [FColumnIndex, @Item, -1]);
    if (Item <> nil) then begin
      Result:= StrPas(Item);
      g_free(Item);
    end
    else
      result := '';
  end;
end;

function TGtkListStoreStringList.GetObject(Index: Integer): TObject;
var
  ListItem : TGtkTreeIter;
begin
  Result:=nil;
  if (Index < 0) or (Index >= Count) then
    RaiseGDBException('TGtkListStoreStringList.GetObject Out of bounds.')
  else if FGtkListStore<>nil then begin
    UpdateItemCache;
    ListItem:=FCachedItems[Index];
    gtk_tree_model_get(FGtkListStore, @ListItem, [FColumnIndex+1, @Result, -1]);
  end;
end;

procedure TGtkListStoreStringList.Put(Index: Integer; const S: string);
var
  ListItem : TGtkTreeIter;
begin
  if (Index < 0) or (Index >= Count) then
    RaiseGDBException('TGtkListStoreStringList.Put Out of bounds.')
  else if FGtkListStore<>nil then begin
    UpdateItemCache;
    ListItem:=FCachedItems[Index];
    gtk_list_store_set(FGtkListStore, @ListItem, [FColumnIndex, PChar(S), -1]);
  end;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.GetCount
  Params:
  Returns:

 ------------------------------------------------------------------------------}
function TGtkListStoreStringList.GetCount: integer;
begin
  if (FGtkListStore<>nil) then begin
    UpdateItemCache;
    Result:=FCachedCount;
  end else begin
    Result:= 0
  end;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Clear
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Clear;
begin
  Include(FStates,glsItemCacheNeedsUpdate);
  gtk_list_store_clear(FGtkListStore);
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Delete
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Delete(Index : integer);
var
  ListItem : TGtkTreeIter;
begin
  Include(FStates,glsItemCacheNeedsUpdate);
  gtk_tree_model_iter_nth_child (FGtkListStore, @ListItem, nil, Index);
  gtk_list_store_remove(FGtkListStore, @ListItem);
end;

function TGtkListStoreStringList.IndexOf(const S: string): Integer;
var
  l, m, r, cmp: integer;
begin
  BeginUpdate;
  if FSorted then begin
    l:=0;
    r:=Count-1;
    m:=l;
    while (l<=r) do begin
      m:=(l+r) shr 1;
      cmp:=AnsiCompareText(S,Strings[m]);

      if cmp<0 then
        r:=m-1
      else if cmp>0 then
        l:=m+1
      else begin
        Result:=m;
        exit;
      end;
    end;
    Result:=-1;
  end else begin
    Result:=inherited IndexOf(S);
  end;
  EndUpdate;
end;

{------------------------------------------------------------------------------
  Method: TGtkListStoreStringList.Insert
  Params:
  Returns:

 ------------------------------------------------------------------------------}
procedure TGtkListStoreStringList.Insert(Index : integer; const S : string);
var
  li : TGtkTreeIter;
  l, m, r, cmp: integer;
begin
  BeginUpdate;
  try
    if FSorted then begin
      l:=0;
      r:=Count-1;
      m:=l;
      while (l<=r) do begin
        m:=(l+r) shr 1;
        cmp:=AnsiCompareText(S,Strings[m]);
        if cmp<0 then
          r:=m-1
        else if cmp>0 then
          l:=m+1
        else
          break;
      end;
      if (m<Count) and (AnsiCompareText(S,Strings[m])>0) then
        inc(m);
      Index:=m;
    end;
    if (Index < 0) or (Index > Count) then
      RaiseGDBException('TGtkListStoreStringList.Insert: Index '+IntToStr(Index)
        +' out of bounds. Count='+IntToStr(Count));
    if Owner = nil then RaiseGDBException(
      'TGtkListStoreStringList.Insert Unspecified owner');

    gtk_list_store_insert(FGtkListStore, @li, Index);
    gtk_list_store_set(FGtkListStore, @li, [FColumnIndex, PChar(S), -1]);

    Include(FStates,glsItemCacheNeedsUpdate);
  finally
    EndUpdate;
  end;
end;

end.
