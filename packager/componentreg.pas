{  $Id$  }
{
 /***************************************************************************
                            componentreg.pas
                            ----------------


 ***************************************************************************/

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************

  Author: Mattias Gaertner

  Abstract:

}
unit ComponentReg;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Controls,
  {$IFDEF CustomIDEComps}
  CustomIDEComps,
  {$ENDIF}
  IDEProcs, LazarusPackageIntf;

type
  TComponentPriorityCategory = (
    cpBase,
    cpRecommended,
    cpNormal,
    cpOptional
    );
    
  TComponentPriority = record
    Category: TComponentPriorityCategory;
    Level: integer; // higher level means higher priority (range: -1000 to 1000)
  end;
    
const
  ComponentPriorityNormal: TComponentPriority = (Category: cpNormal; Level:0);

    
type
  TBaseComponentPage = class;
  TBaseComponentPalette = class;


  { TRegisteredComponent }

  TRegisteredComponent = class
  private
    FButton: TComponent;
    FComponentClass: TComponentClass;
    FPage: TBaseComponentPage;
    FPageName: string;
  protected
    FVisible: boolean;
    procedure SetVisible(const AValue: boolean); virtual;
  public
    constructor Create(TheComponentClass: TComponentClass;
      const ThePageName: string);
    destructor Destroy; override;
    procedure ConsistencyCheck; virtual;
    function GetUnitName: string; virtual; abstract;
    function GetPriority: TComponentPriority; virtual;
    procedure AddToPalette; virtual;
    function CanBeCreatedInDesigner: boolean; virtual;
    procedure ShowHideControl(Show: boolean);
  public
    property ComponentClass: TComponentClass read FComponentClass;
    property PageName: string read FPageName;
    property Page: TBaseComponentPage read FPage write FPage;
    property Button: TComponent read FButton write FButton;
    property Visible: boolean read FVisible write SetVisible;
  end;


  { TBaseComponentPage }

  TBaseComponentPage = class
  private
    FItems: TList; // list of TRegisteredComponent
    FPageComponent: TComponent;
    FPageName: string;
    FPalette: TBaseComponentPalette;
    FPriority: TComponentPriority;
    FSelectButton: TComponent;
    function GetItems(Index: integer): TRegisteredComponent;
  protected
    FVisible: boolean;
    procedure SetVisible(const AValue: boolean); virtual;
    procedure OnComponentVisibleChanged(AComponent: TRegisteredComponent); virtual;
  public
    constructor Create(const ThePageName: string);
    destructor Destroy; override;
    procedure Clear;
    procedure ClearButtons;
    procedure ConsistencyCheck;
    function Count: integer;
    procedure Add(NewComponent: TRegisteredComponent);
    procedure Remove(AComponent: TRegisteredComponent);
    function FindComponent(const CompClassName: string): TRegisteredComponent;
    function FindButton(Button: TComponent): TRegisteredComponent;
    procedure ShowHideControls(Show: boolean);
  public
    property Items[Index: integer]: TRegisteredComponent read GetItems; default;
    property PageName: string read FPageName;
    property Palette: TBaseComponentPalette read FPalette;
    property Priority: TComponentPriority read FPriority write FPriority;
    property PageComponent: TComponent read FPageComponent write FPageComponent;
    property SelectButton: TComponent read FSelectButton write FSelectButton;
    property Visible: boolean read FVisible write SetVisible;
  end;


  { TBaseComponentPalette }
  
  TEndUpdatePaletteEvent =
    procedure(Sender: TObject; PaletteChanged: boolean) of object;

  TBaseComponentPalette = class
  private
    FItems: TList; // list of TBaseComponentPage
    FOnBeginUpdate: TNotifyEvent;
    FOnEndUpdate: TEndUpdatePaletteEvent;
    FUpdateLock: integer;
    fChanged: boolean;
    function GetItems(Index: integer): TBaseComponentPage;
  protected
    procedure DoChange; virtual;
    procedure DoEndUpdate(Changed: boolean); virtual;
    procedure OnPageAddedComponent(Component: TRegisteredComponent); virtual;
    procedure OnPageRemovedComponent(Page: TBaseComponentPage;
                                Component: TRegisteredComponent); virtual;
    procedure OnComponentVisibleChanged(AComponent: TRegisteredComponent); virtual;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ClearButtons; virtual;
    procedure BeginUpdate(Change: boolean);
    procedure EndUpdate;
    function IsUpdateLocked: boolean;
    procedure ConsistencyCheck;
    function Count: integer;
    function GetPage(const APageName: string;
      CreateIfNotExists: boolean): TBaseComponentPage;
    function IndexOfPageWithName(const APageName: string): integer;
    procedure AddComponent(NewComponent: TRegisteredComponent);
    function CreateNewPage(const NewPageName: string;
      const Priority: TComponentPriority): TBaseComponentPage;
    function FindComponent(const CompClassName: string): TRegisteredComponent; virtual;
    function FindButton(Button: TComponent): TRegisteredComponent;
    function CreateNewClassName(const Prefix: string): string;
    function IndexOfPageComponent(AComponent: TComponent): integer;
    procedure ShowHideControls(Show: boolean);
  public
    property Pages[Index: integer]: TBaseComponentPage read GetItems; default;
    property UpdateLock: integer read FUpdateLock;
    property OnBeginUpdate: TNotifyEvent read FOnBeginUpdate write FOnBeginUpdate;
    property OnEndUpdate: TEndUpdatePaletteEvent read FOnEndUpdate write FOnEndUpdate;
  end;
  

var
  IDEComponentPalette: TBaseComponentPalette;

function ComparePriority(const p1,p2: TComponentPriority): integer;
function CompareIDEComponentByClassName(Data1, Data2: pointer): integer;

type
  RegisterUnitComponentProc = procedure(const Page, UnitName: ShortString;
                                       ComponentClass: TComponentClass);

procedure RegisterCustomIDEComponents(RegisterProc: RegisterUnitComponentProc);


implementation


function ComparePriority(const p1, p2: TComponentPriority): integer;
begin
  Result:=ord(p2.Category)-ord(p1.Category);
  if Result<>0 then exit;
  Result:=p1.Level-p2.Level;
end;

function CompareIDEComponentByClassName(Data1, Data2: pointer): integer;
var
  Comp1: TRegisteredComponent;
  Comp2: TRegisteredComponent;
begin
  Comp1:=TRegisteredComponent(Data1);
  Comp2:=TRegisteredComponent(Data2);
  Result:=AnsiCompareText(Comp1.ComponentClass.Classname,
                          Comp2.ComponentClass.Classname);
end;

procedure RegisterCustomIDEComponents(RegisterProc: RegisterUnitComponentProc);
begin
  {$IFDEF CustomIDEComps}
  CustomIDEComps.RegisterCustomComponents(RegisterProc);
  {$ENDIF}
end;

{ TRegisteredComponent }

procedure TRegisteredComponent.SetVisible(const AValue: boolean);
begin
  if FVisible=AValue then exit;
  FVisible:=AValue;
  if (FPage<>nil) then FPage.OnComponentVisibleChanged(Self);
end;

constructor TRegisteredComponent.Create(TheComponentClass: TComponentClass;
  const ThePageName: string);
begin
  FComponentClass:=TheComponentClass;
  FPageName:=ThePageName;
  FVisible:=true;
end;

destructor TRegisteredComponent.Destroy;
begin
  if FPage<>nil then FPage.Remove(Self);
  FreeThenNil(FButton);
  inherited Destroy;
end;

procedure TRegisteredComponent.ConsistencyCheck;
begin
  if (FComponentClass=nil) then
    RaiseException('TRegisteredComponent.ConsistencyCheck FComponentClass=nil');
  if not IsValidIdent(FComponentClass.ClassName) then
    RaiseException('TRegisteredComponent.ConsistencyCheck not IsValidIdent(FComponentClass.ClassName)');
end;

function TRegisteredComponent.GetPriority: TComponentPriority;
begin
  Result:=ComponentPriorityNormal;
end;

procedure TRegisteredComponent.AddToPalette;
begin
  IDEComponentPalette.AddComponent(Self);
end;

function TRegisteredComponent.CanBeCreatedInDesigner: boolean;
begin
  Result:=true;
end;

procedure TRegisteredComponent.ShowHideControl(Show: boolean);
begin
  if ComponentClass.InheritsFrom(TControl) then
    Visible:=Show;
end;

{ TBaseComponentPage }

function TBaseComponentPage.GetItems(Index: integer): TRegisteredComponent;
begin
  Result:=TRegisteredComponent(FItems[Index]);
end;

procedure TBaseComponentPage.SetVisible(const AValue: boolean);
begin
  if FVisible=AValue then exit;
  FVisible:=AValue;
end;

procedure TBaseComponentPage.OnComponentVisibleChanged(
  AComponent: TRegisteredComponent);
begin
  if FPalette<>nil then FPalette.OnComponentVisibleChanged(AComponent);
end;

constructor TBaseComponentPage.Create(const ThePageName: string);
begin
  FPageName:=ThePageName;
  FItems:=TList.Create;
  FVisible:=FPageName<>'';
end;

destructor TBaseComponentPage.Destroy;
begin
  Clear;
  FreeThenNil(FPageComponent);
  FreeThenNil(FSelectButton);
  FItems.Free;
  inherited Destroy;
end;

procedure TBaseComponentPage.Clear;
var
  i: Integer;
begin
  ClearButtons;
  for i:=0 to FItems.Count-1 do Items[i].Page:=nil;
  FItems.Clear;
end;

procedure TBaseComponentPage.ClearButtons;
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=Count;
  for i:=0 to Cnt-1 do FreeThenNil(Items[i].FButton);
  FreeThenNil(FSelectButton);
end;

procedure TBaseComponentPage.ConsistencyCheck;
begin

end;

function TBaseComponentPage.Count: integer;
begin
  Result:=FItems.Count;
end;

procedure TBaseComponentPage.Add(NewComponent: TRegisteredComponent);
var
  InsertIndex: Integer;
  NewPriority: TComponentPriority;
begin
  NewPriority:=NewComponent.GetPriority;
  InsertIndex:=0;
  while (InsertIndex<Count)
  and (ComparePriority(NewPriority,Items[InsertIndex].GetPriority)<=0) do
    inc(InsertIndex);
  FItems.Insert(InsertIndex,NewComponent);
  NewComponent.Page:=Self;
  if FPalette<>nil then FPalette.OnPageAddedComponent(NewComponent);
end;

procedure TBaseComponentPage.Remove(AComponent: TRegisteredComponent);
begin
  FItems.Remove(AComponent);
  AComponent.Page:=nil;
  if FPalette<>nil then FPalette.OnPageRemovedComponent(Self,AComponent);
end;

function TBaseComponentPage.FindComponent(const CompClassName: string
  ): TRegisteredComponent;
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Items[i];
    if AnsiCompareText(Result.ComponentClass.ClassName,CompClassName)=0 then
      exit;
  end;
  Result:=nil;
end;

function TBaseComponentPage.FindButton(Button: TComponent
  ): TRegisteredComponent;
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Items[i];
    if Result.Button=Button then exit;
  end;
  Result:=nil;
end;

procedure TBaseComponentPage.ShowHideControls(Show: boolean);
var
  i: Integer;
begin
  for i:=0 to Count-1 do
    Items[i].ShowHideControl(Show);
end;

{ TBaseComponentPalette }

function TBaseComponentPalette.GetItems(Index: integer): TBaseComponentPage;
begin
  Result:=TBaseComponentPage(FItems[Index]);
end;

procedure TBaseComponentPalette.DoChange;
begin
  if FUpdateLock>0 then fChanged:=true;
end;

procedure TBaseComponentPalette.DoEndUpdate(Changed: boolean);
begin
  if Assigned(OnEndUpdate) then OnEndUpdate(Self,Changed);
end;

procedure TBaseComponentPalette.OnPageAddedComponent(
  Component: TRegisteredComponent);
begin
  DoChange;
end;

procedure TBaseComponentPalette.OnPageRemovedComponent(
  Page: TBaseComponentPage; Component: TRegisteredComponent);
begin
  DoChange;
end;

procedure TBaseComponentPalette.OnComponentVisibleChanged(
  AComponent: TRegisteredComponent);
begin
  DoChange;
end;

constructor TBaseComponentPalette.Create;
begin
  FItems:=TList.Create;
end;

destructor TBaseComponentPalette.Destroy;
begin
  Clear;
  FItems.Free;
  inherited Destroy;
end;

procedure TBaseComponentPalette.Clear;
var
  i: Integer;
begin
  for i:=0 to FItems.Count-1 do
    Pages[i].Free;
  FItems.Clear;
end;

procedure TBaseComponentPalette.ClearButtons;
var
  Cnt: Integer;
  i: Integer;
begin
  Cnt:=Count;
  for i:=0 to Cnt-1 do Pages[i].ClearButtons;
end;

procedure TBaseComponentPalette.BeginUpdate(Change: boolean);
begin
  inc(FUpdateLock);
  if FUpdateLock=1 then begin
    fChanged:=Change;
    if Assigned(OnBeginUpdate) then OnBeginUpdate(Self);
  end else
    fChanged:=fChanged or Change;
end;

procedure TBaseComponentPalette.EndUpdate;
begin
  if FUpdateLock<=0 then RaiseException('TBaseComponentPalette.EndUpdate');
  dec(FUpdateLock);
  if FUpdateLock=0 then DoEndUpdate(fChanged);
end;

function TBaseComponentPalette.IsUpdateLocked: boolean;
begin
  Result:=FUpdateLock>0;
end;

procedure TBaseComponentPalette.ConsistencyCheck;
begin

end;

function TBaseComponentPalette.Count: integer;
begin
  Result:=FItems.Count;
end;

function TBaseComponentPalette.GetPage(const APageName: string;
  CreateIfNotExists: boolean): TBaseComponentPage;
var
  i: Integer;
begin
  i:=IndexOfPageWithName(APageName);
  if i>=0 then begin
    Result:=Pages[i];
  end else begin
    if CreateIfNotExists then begin
      Result:=TBaseComponentPage.Create(APageName);
      Result.FPalette:=Self;
      FItems.Add(Result);
    end else
      Result:=nil;
  end;
end;

function TBaseComponentPalette.IndexOfPageWithName(const APageName: string
  ): integer;
begin
  Result:=Count-1;
  while (Result>=0) and (AnsiCompareText(Pages[Result].PageName,APageName)<>0)
  do
    dec(Result);
end;

procedure TBaseComponentPalette.AddComponent(NewComponent: TRegisteredComponent);
var
  CurPage: TBaseComponentPage;
begin
  CurPage:=GetPage(NewComponent.PageName,false);
  if CurPage=nil then
    CurPage:=CreateNewPage(NewComponent.PageName,NewComponent.GetPriority);
  CurPage.Add(NewComponent);
end;

function TBaseComponentPalette.CreateNewPage(const NewPageName: string;
  const Priority: TComponentPriority): TBaseComponentPage;
var
  InsertIndex: Integer;
begin
  Result:=TBaseComponentPage.Create(NewPageName);
  Result.Priority:=Priority;
  InsertIndex:=0;
  while (InsertIndex<Count)
  and (ComparePriority(Priority,Pages[InsertIndex].Priority)<=0) do
    inc(InsertIndex);
  FItems.Insert(InsertIndex,Result);
  Result.FPalette:=Self;
end;

function TBaseComponentPalette.FindComponent(const CompClassName: string
  ): TRegisteredComponent;
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Pages[i].FindComponent(CompClassName);
    if Result<>nil then exit;
  end;
  Result:=nil;
end;

function TBaseComponentPalette.FindButton(Button: TComponent
  ): TRegisteredComponent;
var
  i: Integer;
begin
  for i:=0 to Count-1 do begin
    Result:=Pages[i].FindButton(Button);
    if Result<>nil then exit;
  end;
  Result:=nil;
end;

function TBaseComponentPalette.CreateNewClassName(const Prefix: string): string;
var
  i: Integer;
begin
  if FindComponent(Prefix)=nil then begin
    Result:=Prefix;
  end else begin
    i:=1;
    repeat
      Result:=Prefix+IntToStr(i);
    until FindComponent(Result)=nil;
  end;
end;

function TBaseComponentPalette.IndexOfPageComponent(AComponent: TComponent
  ): integer;
begin
  if AComponent<>nil then begin
    Result:=Count-1;
    while (Result>=0) and (Pages[Result].PageComponent<>AComponent) do
      dec(Result);
  end else
    Result:=-1;
end;

procedure TBaseComponentPalette.ShowHideControls(Show: boolean);
var
  i: Integer;
begin
  BeginUpdate(false);
  for i:=0 to Count-1 do
    Pages[i].ShowHideControls(Show);
  EndUpdate;
end;


initialization
  IDEComponentPalette:=nil;
  
end.

