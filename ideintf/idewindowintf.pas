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

  Author: Mattias Gaertner
  
  Abstract:
    Provides general classes and methods to access and handle IDE dialogs and
    windows.
}
unit IDEWindowIntf;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, LazConfigStorage, Forms, Controls;

  //----------------------------------------------------------------------------
  // layout settings of modal forms (dialogs) in the IDE
type

  TIDEDialogLayoutList = class;

  { TIDEDialogLayout }

  TIDEDialogLayout = class
  private
    FHeight: integer;
    FList: TIDEDialogLayoutList;
    FModified: boolean;
    FName: string;
    FWidth: integer;
    procedure SetHeight(const AValue: integer);
    procedure SetList(const AValue: TIDEDialogLayoutList);
    procedure SetModified(const AValue: boolean);
    procedure SetWidth(const AValue: integer);
  public
    constructor Create(const TheName: string; TheList: TIDEDialogLayoutList);
    function SizeValid: boolean;
    property Width: integer read FWidth write SetWidth;
    property Height: integer read FHeight write SetHeight;
    property Name: string read FName;
    procedure LoadFromConfig(Config: TConfigStorage; const Path: string);
    procedure SaveToConfig(Config: TConfigStorage; const Path: string);
    property List: TIDEDialogLayoutList read FList write SetList;
    property Modified: boolean read FModified write SetModified;
  end;
  TIDEDialogLayoutClass = class of TIDEDialogLayout;

  { TIDEDialogLayoutList }

  TIDEDialogLayoutList = class
  private
    FItemClass: TIDEDialogLayoutClass;
    FItems: TList;
    FModified: boolean;
    function GetItems(Index: integer): TIDEDialogLayout;
  protected
    procedure SetModified(const AValue: boolean); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure ApplyLayout(ADialog: TControl;
                          DefaultWidth, DefaultHeight: integer;
                          UseAsMin: boolean = true);
    procedure ApplyLayout(ADialog: TControl);
    procedure SaveLayout(ADialog: TControl);
    procedure Clear;
    function Count: integer;
    function Find(const DialogName: string;
                  CreateIfNotExists: boolean): TIDEDialogLayout;
    function Find(ADialog: TObject;
                  CreateIfNotExists: boolean): TIDEDialogLayout;
    function IndexOf(const DialogName: string): integer;
    procedure LoadFromConfig(Config: TConfigStorage; const Path: string);
    procedure SaveToConfig(Config: TConfigStorage; const Path: string);
    property Items[Index: integer]: TIDEDialogLayout read GetItems;
    property Modified: boolean read FModified write SetModified;
    property ItemClass: TIDEDialogLayoutClass read FItemClass write FItemClass;
  end;
  
  { TIDEDialogLayoutStorage }

  TIDEDialogLayoutStorage = class(TComponent)
  protected
    procedure OnCreateForm(Sender: TObject);
    procedure OnCloseForm(Sender: TObject; var CloseAction: TCloseAction);
  public
    constructor Create(TheOwner: TComponent); override;
    destructor Destroy; override;
  end;

var
  IDEDialogLayoutList: TIDEDialogLayoutList = nil;// set by the IDE

type
  TIWDLState = (
    iwdlsHidden,
    iwdlsIconified,
    iwdlsNormal,
    iwdlsDocked
    );

  { TIDEWindowDefaultLayout }

  TIDEWindowDefaultLayout = class
  private
    FDockAlign: TAlign;
    FDockSibling: string;
    FFormName: string;
    FHeight: string;
    FLeft: string;
    FState: TIWDLState;
    FTop: string;
    FWidth: string;
    procedure SetHeight(const AValue: string);
    procedure SetLeft(const AValue: string);
    procedure SetTop(const AValue: string);
    procedure SetWidth(const AValue: string);
  public
    property FormName: string read FFormName;
    property State: TIWDLState read FState write FState;
    property Left: string read FLeft write SetLeft; // '12' for 12 pixel, '10%' for 10 percent of screen.width
    property Top: string read FTop write SetTop; // '12' for 12 pixel, '10%' for 10 percent of screen.height
    property Width: string read FWidth write SetWidth; // '12' for 12 pixel, '10%' for 10 percent of screen.width
    property Height: string read FHeight write SetHeight; // '12' for 12 pixel, '10%' for 10 percent of screen.height
    property DockSibling: string read FDockSibling write FDockSibling; // another form name
    property DockAlign: TAlign read FDockAlign write FDockAlign;
    procedure CheckBoundValue(s: string);
    constructor Create(aFormName: string); overload;
    constructor Create(aFormName: string; aLeft, aTop, aWidth, aHeight: integer;
                       aUnit: string = ''; aDockSibling : string = '';
                       aDockAlign: TAlign = alNone); overload;
  end;

  { TIDEWindowDefaultLayoutList }

  TIDEWindowDefaultLayoutList = class
  private
    fItems: TFPList; // list of TIDEWindowDefaultLayout
    function GetItems(Index: integer): TIDEWindowDefaultLayout;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function Count: integer;
    property Items[Index: integer]: TIDEWindowDefaultLayout read GetItems;
    function Add(aLayout: TIDEWindowDefaultLayout): integer;
    procedure Delete(Index: integer);
    function IndexOfName(FormName: string): integer;
    function FindLayoutWithName(FormName: string): TIDEWindowDefaultLayout;
  end;

type

  { TIDEDockMaster }

  TIDEDockMaster = class
  public
    procedure MakeIDEWindowDockable(AControl: TWinControl); virtual; abstract;
    procedure MakeIDEWindowDockSite(AForm: TCustomForm); virtual; abstract;
  end;

var
  IDEDockMaster: TIDEDockMaster = nil; // can be set by a package

procedure MakeIDEWindowDockable(AControl: TWinControl);
procedure MakeIDEWindowDockSite(AForm: TCustomForm);

procedure Register;

implementation

procedure MakeIDEWindowDockable(AControl: TWinControl);
begin
  if Assigned(IDEDockMaster) then
    IDEDockMaster.MakeIDEWindowDockable(AControl);
end;

procedure MakeIDEWindowDockSite(AForm: TCustomForm);
begin
  if Assigned(IDEDockMaster) then
    IDEDockMaster.MakeIDEWindowDockSite(AForm);
end;

procedure Register;
begin
  RegisterComponents('Misc',[TIDEDialogLayoutStorage]);
end;

{ TIDEDialogLayout }

procedure TIDEDialogLayout.SetHeight(const AValue: integer);
begin
  if FHeight=AValue then exit;
  FHeight:=AValue;
  Modified:=true;
end;

procedure TIDEDialogLayout.SetList(const AValue: TIDEDialogLayoutList);
begin
  if FList=AValue then exit;
  FList:=AValue;
  if (List<>nil) and Modified then List.Modified:=true;
end;

procedure TIDEDialogLayout.SetModified(const AValue: boolean);
begin
  FModified:=AValue;
  if FModified and (FList<>nil) then FList.Modified:=true;
end;

procedure TIDEDialogLayout.SetWidth(const AValue: integer);
begin
  if FWidth=AValue then exit;
  FWidth:=AValue;
  Modified:=true;
end;

constructor TIDEDialogLayout.Create(const TheName: string;
  TheList: TIDEDialogLayoutList);
begin
  FName:=TheName;
  FList:=TheList;
end;

function TIDEDialogLayout.SizeValid: boolean;
begin
  Result:=(Width>10) and (Height>10);
end;

procedure TIDEDialogLayout.LoadFromConfig(Config: TConfigStorage;
  const Path: string);
begin
  FName:=Config.GetValue(Path+'Name/Value','');
  FWidth:=Config.GetValue(Path+'Size/Width',0);
  FHeight:=Config.GetValue(Path+'Size/Height',0);
  Modified:=false;
end;

procedure TIDEDialogLayout.SaveToConfig(Config: TConfigStorage;
  const Path: string);
begin
  Config.SetValue(Path+'Name/Value',Name);
  Config.SetValue(Path+'Size/Width',Width);
  Config.SetValue(Path+'Size/Height',Height);
  Modified:=false;
end;

{ TIDEDialogLayoutList }

function TIDEDialogLayoutList.GetItems(Index: integer): TIDEDialogLayout;
begin
  Result:=TIDEDialogLayout(FItems[Index]);
end;

procedure TIDEDialogLayoutList.SetModified(const AValue: boolean);
begin
  if FModified=AValue then exit;
  FModified:=AValue;
end;

constructor TIDEDialogLayoutList.Create;
begin
  inherited Create;
  FItems:=TList.Create;
  FItemClass:=TIDEDialogLayout;
end;

destructor TIDEDialogLayoutList.Destroy;
begin
  Clear;
  FreeAndNil(FItems);
  inherited Destroy;
end;

procedure TIDEDialogLayoutList.ApplyLayout(ADialog: TControl;
  DefaultWidth, DefaultHeight: integer; UseAsMin: boolean);
var
  ALayout: TIDEDialogLayout;
  NewWidth, NewHeight: integer;
begin
  if (ADialog=nil) or (Self=nil) then exit;
  ALayout:=Find(ADialog,true);
  if ALayout.SizeValid then begin
    NewWidth:=ALayout.Width;
    NewHeight:=ALayout.Height;
  end else begin
    NewWidth:=DefaultWidth;
    NewHeight:=DefaultHeight;
  end;
  if UseAsMin then begin
    if NewWidth<DefaultWidth then NewWidth:=DefaultWidth;
    if NewHeight<DefaultHeight then NewHeight:=DefaultHeight;
  end;
  ADialog.SetBounds(ADialog.Left,ADialog.Top,NewWidth,NewHeight);
end;

procedure TIDEDialogLayoutList.ApplyLayout(ADialog: TControl);
begin
  ApplyLayout(ADialog,ADialog.Width,ADialog.Height);
end;

procedure TIDEDialogLayoutList.SaveLayout(ADialog: TControl);
var
  ALayout: TIDEDialogLayout;
begin
  if (ADialog=nil) or (Self=nil) then exit;
  ALayout:=Find(ADialog,true);
  ALayout.Width:=ADialog.Width;
  ALayout.Height:=ADialog.Height;
end;

procedure TIDEDialogLayoutList.Clear;
var i: integer;
begin
  for i:=0 to FItems.Count-1 do
    Items[i].Free;
  FItems.Clear;
end;

function TIDEDialogLayoutList.Count: integer;
begin
  Result:=FItems.Count;
end;

function TIDEDialogLayoutList.Find(const DialogName: string;
  CreateIfNotExists: boolean): TIDEDialogLayout;
var i: integer;
begin
  i:=IndexOf(DialogName);
  if (i<0) then begin
    if CreateIfNotExists then begin
      Result:=FItemClass.Create(DialogName,Self);
      FItems.Add(Result);
    end else begin
      Result:=nil;
    end;
  end else begin
    Result:=Items[i];
  end;
end;

function TIDEDialogLayoutList.Find(ADialog: TObject; CreateIfNotExists: boolean
  ): TIDEDialogLayout;
begin
  if ADialog<>nil then begin
    Result:=Find(ADialog.ClassName,CreateIfNotExists);
  end else begin
    Result:=nil;
  end;
end;

function TIDEDialogLayoutList.IndexOf(const DialogName: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (CompareText(DialogName,Items[Result].Name)<>0) do
    dec(Result);
end;

procedure TIDEDialogLayoutList.LoadFromConfig(Config: TConfigStorage;
  const Path: string);
var
  NewCount, i: integer;
  NewDialogLayout: TIDEDialogLayout;
begin
  Clear;
  NewCount:=Config.GetValue(Path+'Count',0);
  for i:=0 to NewCount-1 do begin
    NewDialogLayout:=FItemClass.Create('',Self);
    FItems.Add(NewDialogLayout);
    NewDialogLayout.LoadFromConfig(Config,Path+'Dialog'+IntToStr(i+1)+'/');
  end;
  Modified:=false;
end;

procedure TIDEDialogLayoutList.SaveToConfig(Config: TConfigStorage;
  const Path: string);
var i: integer;
begin
  Config.SetDeleteValue(Path+'Count',Count,0);
  for i:=0 to Count-1 do
    Items[i].SaveToConfig(Config,Path+'Dialog'+IntToStr(i+1)+'/');
  Modified:=false;
end;

{ TIDEDialogLayoutStorage }

procedure TIDEDialogLayoutStorage.OnCreateForm(Sender: TObject);
begin
  if Sender=nil then ;
  IDEDialogLayoutList.ApplyLayout(Sender as TControl);
end;

procedure TIDEDialogLayoutStorage.OnCloseForm(Sender: TObject;
  var CloseAction: TCloseAction);
begin
  if Sender=nil then ;
  IDEDialogLayoutList.SaveLayout(Sender as TControl);
end;

constructor TIDEDialogLayoutStorage.Create(TheOwner: TComponent);
var
  Form: TCustomForm;
begin
  inherited Create(TheOwner);
  if Owner is TCustomForm then begin
    Form:=TCustomForm(Owner);
    Form.AddHandlerCreate(@OnCreateForm);
    Form.AddHandlerClose(@OnCloseForm);
  end;
end;

destructor TIDEDialogLayoutStorage.Destroy;
var
  Form: TCustomForm;
begin
  if Owner is TCustomForm then begin
    Form:=TCustomForm(Owner);
    Form.RemoveAllHandlersOfObject(Self);
  end;
  inherited Destroy;
end;

{ TIDEWindowDefaultLayout }

procedure TIDEWindowDefaultLayout.SetHeight(const AValue: string);
begin
  CheckBoundValue(AValue);
  if FHeight=AValue then exit;
  FHeight:=AValue;
end;

procedure TIDEWindowDefaultLayout.SetLeft(const AValue: string);
begin
  CheckBoundValue(AValue);
  if FLeft=AValue then exit;
  FLeft:=AValue;
end;

procedure TIDEWindowDefaultLayout.SetTop(const AValue: string);
begin
  CheckBoundValue(AValue);
  if FTop=AValue then exit;
  FTop:=AValue;
end;

procedure TIDEWindowDefaultLayout.SetWidth(const AValue: string);
begin
  CheckBoundValue(AValue);
  if FWidth=AValue then exit;
  FWidth:=AValue;
end;

procedure TIDEWindowDefaultLayout.CheckBoundValue(s: string);
var
  p: Integer;
begin
  if s='' then exit;
  p:=1;
  while (p<=length(s)) and (s[p] in ['0'..'9']) do inc(p);
  if p<=1 then
    raise Exception.Create('TIDEWindowDefaultLayout.CheckBoundValue: expected number, but '+s+' found');
  // check for percent
  if (p<=length(s)) and (s[p]='%') then inc(p);
  if p<=length(s) then
    raise Exception.Create('TIDEWindowDefaultLayout.CheckBoundValue: expected number, but '+s+' found');
end;

constructor TIDEWindowDefaultLayout.Create(aFormName: string);
begin
  FFormName:=aFormName;
end;

constructor TIDEWindowDefaultLayout.Create(aFormName: string; aLeft, aTop,
  aWidth, aHeight: integer; aUnit: string; aDockSibling: string;
  aDockAlign: TAlign);
begin
  Create(aFormName);
  Left:=IntToStr(aLeft)+aUnit;
  Top:=IntToStr(aTop)+aUnit;
  Width:=IntToStr(aWidth)+aUnit;
  Height:=IntToStr(aHeight)+aUnit;
  DockSibling:=aDockSibling;
  DockAlign:=aDockAlign;
end;

{ TIDEWindowDefaultLayoutList }

function TIDEWindowDefaultLayoutList.GetItems(Index: integer
  ): TIDEWindowDefaultLayout;
begin
  Result:=TIDEWindowDefaultLayout(fItems[Index]);
end;

constructor TIDEWindowDefaultLayoutList.Create;
begin
  fItems:=TFPList.Create;
end;

destructor TIDEWindowDefaultLayoutList.Destroy;
begin
  Clear;
  FreeAndNil(fItems);
  inherited Destroy;
end;

procedure TIDEWindowDefaultLayoutList.Clear;
var
  i: Integer;
begin
  for i:=0 to fItems.Count-1 do
    TObject(fItems[i]).Free;
end;

function TIDEWindowDefaultLayoutList.Count: integer;
begin
  Result:=fItems.Count;
end;

function TIDEWindowDefaultLayoutList.Add(aLayout: TIDEWindowDefaultLayout
  ): integer;
begin
  if IndexOfName(aLayout.FormName)>=0 then
    raise Exception.Create('TIDEWindowDefaultLayoutList.Add: form name already exists');
  Result:=fItems.Add(aLayout);
end;

procedure TIDEWindowDefaultLayoutList.Delete(Index: integer);
begin
  TObject(fItems[Index]).Free;
  fItems.Delete(Index);
end;

function TIDEWindowDefaultLayoutList.IndexOfName(FormName: string): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (SysUtils.CompareText(FormName,Items[Result].FormName)<>0) do
    dec(Result);
end;

function TIDEWindowDefaultLayoutList.FindLayoutWithName(FormName: string
  ): TIDEWindowDefaultLayout;
var
  i: LongInt;
begin
  i:=IndexOfName(FormName);
  if i>=0 then
    Result:=Items[i]
  else
    Result:=nil;
end;

end.

