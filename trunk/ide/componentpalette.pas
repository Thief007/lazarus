{  $Id$  }
{
 /***************************************************************************
                          componentpalette.pas
                          --------------------


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
unit ComponentPalette;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Dialogs, Graphics, ExtCtrls, Buttons, Menus, LResources,
  AVL_Tree, ComponentReg, IDEProcs, PackageDefs, LazarusIDEStrConsts;

const
  ComponentPaletteBtnWidth  = 25;
  ComponentPaletteBtnHeight = 25;

type
  TComponentPalette = class(TBaseComponentPalette)
    PopupMenu: TPopupMenu;
    OpenPackageMenuItem: TMenuItem;
    OpenUnitMenuItem: TMenuItem;
    procedure ActivePageChanged(Sender: TObject);
    procedure OpenPackageClicked(Sender: TObject);
    procedure OpenUnitClicked(Sender: TObject);
    procedure PopupMenuPopup(Sender: TObject);
  private
    fComponents: TAVLTree; // tree of TRegisteredComponent sorted for componentclass
    FNoteBook: TNotebook;
    fNoteBookNeedsUpdate: boolean;
    FOnOpenPackage: TNotifyEvent;
    FOnOpenUnit: TNotifyEvent;
    FSelected: TRegisteredComponent;
    fUnregisteredIcon: TBitmap;
    fSelectButtonIcon: TBitmap;
    fUpdatingNotebook: boolean;
    procedure SetNoteBook(const AValue: TNotebook);
    procedure SelectionToolClick(Sender: TObject);
    procedure ComponentBtnClick(Sender: TObject);
    procedure SetSelected(const AValue: TRegisteredComponent);
    procedure CreatePopupMenu;
  protected
    procedure DoEndUpdate(Changed: boolean); override;
    procedure OnPageAddedComponent(Component: TRegisteredComponent); override;
    procedure OnPageRemovedComponent(Page: TBaseComponentPage;
                                     Component: TRegisteredComponent); override;
    procedure Update; override;
  public
    constructor Create;
    destructor Destroy; override;
    function GetUnregisteredIcon: TBitmap;
    function GetSelectButtonIcon: TBitmap;
    procedure ClearButtons; override;
    procedure SelectButton(Button: TComponent);
    procedure UpdateNoteBookButtons;
    procedure OnGetNonVisualCompIconCanvas(Sender: TObject;
        AComponent: TComponent; var IconCanvas: TCanvas;
        var IconWidth, IconHeight: integer);
    function FindComponent(const CompClassName: string): TRegisteredComponent; override;
    property NoteBook: TNotebook read FNoteBook write SetNoteBook;
    property Selected: TRegisteredComponent read FSelected write SetSelected;
    property OnOpenPackage: TNotifyEvent read FOnOpenPackage write FOnOpenPackage;
    property OnOpenUnit: TNotifyEvent read FOnOpenUnit write FOnOpenUnit;
  end;

implementation

function CompareRegisteredComponents(Data1, Data2: Pointer): integer;
var
  RegComp1: TRegisteredComponent;
  RegComp2: TRegisteredComponent;
begin
  RegComp1:=TRegisteredComponent(Data1);
  RegComp2:=TRegisteredComponent(Data2);
  Result:=AnsiCompareText(RegComp1.ComponentClass.ClassName,
                          RegComp2.ComponentClass.ClassName);
end;

function CompareClassNameWithRegisteredComponent(Key, Data: Pointer): integer;
var
  AClassName: String;
  RegComp: TRegisteredComponent;
begin
  AClassName:=String(Key);
  RegComp:=TRegisteredComponent(Data);
  Result:=AnsiCompareText(AClassName,RegComp.ComponentClass.ClassName);
end;

{ TComponentPalette }

procedure TComponentPalette.ActivePageChanged(Sender: TObject);
begin
  if FNoteBook=nil then exit;
  if (FSelected<>nil)
  and (FSelected.Page.PageComponent=FNoteBook.ActivePageComponent)
  then exit;
  Selected:=nil;
end;

procedure TComponentPalette.OpenPackageClicked(Sender: TObject);
var
  PkgComponent: TPkgComponent;
begin
  PkgComponent:=TPkgComponent(FindButton(PopupMenu.PopupComponent));
  if (PkgComponent=nil) or (PkgComponent.PkgFile=nil)
  or (PkgComponent.PkgFile.LazPackage=nil) then exit;
  if Assigned(OnOpenPackage) then
    OnOpenPackage(PkgComponent.PkgFile.LazPackage);
end;

procedure TComponentPalette.OpenUnitClicked(Sender: TObject);
var
  PkgComponent: TPkgComponent;
begin
  PkgComponent:=TPkgComponent(FindButton(PopupMenu.PopupComponent));
  if (PkgComponent=nil) or (PkgComponent.PkgFile=nil)
  or (PkgComponent.PkgFile.LazPackage=nil) then exit;
  if Assigned(OnOpenUnit) then
    OnOpenUnit(PkgComponent.PkgFile);
end;

procedure TComponentPalette.PopupMenuPopup(Sender: TObject);
var
  PkgComponent: TPkgComponent;
  APackage: TLazPackage;
begin
  PkgComponent:=TPkgComponent(FindButton(PopupMenu.PopupComponent));
  APackage:=nil;
  if (PkgComponent<>nil) and (PkgComponent.PkgFile<>nil) then
    APackage:=PkgComponent.PkgFile.LazPackage;
  if APackage=nil then begin
    OpenPackageMenuItem.Visible:=false;
    OpenUnitMenuItem.Visible:=false;
  end else begin
    OpenPackageMenuItem.Caption:='Open Package '+APackage.IDAsString;
    OpenPackageMenuItem.Visible:=true;
    OpenUnitMenuItem.Caption:='Open Unit '+PkgComponent.PkgFile.Filename;
    OpenUnitMenuItem.Visible:=true;
  end;
end;

procedure TComponentPalette.SetNoteBook(const AValue: TNotebook);
begin
  if FNoteBook=AValue then exit;
  ClearButtons;
  FNoteBook:=AValue;
  if FNoteBook<>nil then begin
    FNoteBook.OnPageChanged:=@ActivePageChanged;
  end;
  UpdateNoteBookButtons;
end;

procedure TComponentPalette.SelectionToolClick(Sender: TObject);
begin
  SelectButton(TComponent(Sender));
end;

procedure TComponentPalette.ComponentBtnClick(Sender: TObject);
begin
  SelectButton(TComponent(Sender));
end;

procedure TComponentPalette.SetSelected(const AValue: TRegisteredComponent);
var
  SelectButtonOnPage: TSpeedButton;
  CurPage: TBaseComponentPage;
  i: Integer;
begin
  if FSelected=AValue then exit;
  FSelected:=AValue;
  if FSelected<>nil then begin
    if (FSelected.Page=nil) or (FSelected.Page.Palette<>Self)
    or (not FSelected.Visible)
    or (not FSelected.CanBeCreatedInDesigner) then
      FSelected:=nil;
  end;
  if FNoteBook=nil then exit;
  // unselect all other buttons on all other notebook pages
  for i:=0 to Count-1 do begin
    CurPage:=Pages[i];
    if (FSelected=nil) or (FSelected.Page<>CurPage) then begin
      SelectButtonOnPage:=TSpeedButton(CurPage.SelectButton);
      if SelectButtonOnPage<>nil then SelectButtonOnPage.Down:=true;
    end;
  end;
  // select button
  if FSelected<>nil then begin
    TSpeedButton(FSelected.Button).Down:=true;
    FNoteBook.ActivePageComponent:=TPage(FSelected.Page.PageComponent);
  end;
end;

procedure TComponentPalette.CreatePopupMenu;
begin
  if PopupMenu<>nil then exit;
  PopupMenu:=TPopupMenu.Create(nil);
  PopupMenu.OnPopup:=@PopupMenuPopup;
  PopupMenu.Name:='ComponentPalettePopupMenu';
  
  OpenPackageMenuItem:=TMenuItem.Create(PopupMenu);
  with OpenPackageMenuItem do begin
    Name:='OpenPackageMenuItem';
    Caption:=lisCompPalOpenPackage;
    OnClick:=@OpenPackageClicked;
  end;
  PopupMenu.Items.Add(OpenPackageMenuItem);

  OpenUnitMenuItem:=TMenuItem.Create(PopupMenu);
  with OpenUnitMenuItem do begin
    Name:='OpenUnitMenuItem';
    Caption:=lisCompPalOpenUnit;
    OnClick:=@OpenUnitClicked;
  end;
  PopupMenu.Items.Add(OpenUnitMenuItem);
end;

procedure TComponentPalette.DoEndUpdate(Changed: boolean);
begin
  if Changed or fNoteBookNeedsUpdate then UpdateNoteBookButtons;
  inherited DoEndUpdate(Changed);
end;

procedure TComponentPalette.OnPageAddedComponent(Component: TRegisteredComponent
  );
begin
  fComponents.Add(Component);
  inherited OnPageAddedComponent(Component);
end;

procedure TComponentPalette.OnPageRemovedComponent(Page: TBaseComponentPage;
  Component: TRegisteredComponent);
begin
  fComponents.Remove(Component);
  inherited OnPageRemovedComponent(Page, Component);
end;

procedure TComponentPalette.Update;
begin
  inherited Update;
  UpdateNoteBookButtons;
end;

constructor TComponentPalette.Create;
begin
  inherited Create;
  fComponents:=TAVLTree.Create(@CompareRegisteredComponents);
end;

destructor TComponentPalette.Destroy;
begin
  NoteBook:=nil;
  fComponents.Free;
  fComponents:=nil;
  if fUnregisteredIcon<>nil then begin
    fUnregisteredIcon.Free;
    fUnregisteredIcon:=nil;
  end;
  if fSelectButtonIcon<>nil then begin
    fSelectButtonIcon.Free;
    fSelectButtonIcon:=nil;
  end;
  PopupMenu.Free;
  PopupMenu:=nil;
  inherited Destroy;
end;

function TComponentPalette.GetUnregisteredIcon: TBitMap;
var
  ResName: string;
  res: TLResource;
begin
  if fUnregisteredIcon=nil then begin
    fUnregisteredIcon:=TPixmap.Create;
    fUnregisteredIcon.TransparentColor:=clWhite;
    ResName:='unregisteredcomponent';
    res:=LazarusResources.Find(ResName);
    if (res<>nil) and (res.Value<>'') and (res.ValueType='XPM') then begin
      fUnregisteredIcon.LoadFromLazarusResource(ResName);
    end else begin
      fUnregisteredIcon.LoadFromLazarusResource('default');
    end;
  end;
  Result:=fUnregisteredIcon;
end;

function TComponentPalette.GetSelectButtonIcon: TBitmap;
begin
  if fSelectButtonIcon=nil then begin
    fSelectButtonIcon:=TPixmap.Create;
    fSelectButtonIcon.TransparentColor:=clWhite;
    fSelectButtonIcon.LoadFromLazarusResource('tmouse');
  end;
  Result:=fSelectButtonIcon;
end;

procedure TComponentPalette.ClearButtons;
begin
  Selected:=nil;
  if PopupMenu<>nil then begin
    PopupMenu.Free;
    PopupMenu:=nil;
    OpenPackageMenuItem:=nil;
  end;
  inherited ClearButtons;
end;

procedure TComponentPalette.SelectButton(Button: TComponent);
begin
  Selected:=FindButton(Button);
end;

procedure TComponentPalette.UpdateNoteBookButtons;
var
  i: Integer;
  PageIndex: Integer;
  CurPage: TBaseComponentPage;
  CurNoteBookPage: TPage;
  CurComponent: TPkgComponent;
  CurBtn: TSpeedButton;
  ButtonX: Integer;
  CurPageIndex: Integer;
  j: Integer;
  OldActivePage: String;
begin
  if fUpdatingNotebook then exit;
  if IsUpdateLocked then begin
    fNoteBookNeedsUpdate:=true;
    exit;
  end;
  if FNoteBook=nil then begin
    fNoteBookNeedsUpdate:=false;
    exit;
  end;
  //writeln('TComponentPalette.UpdateNoteBookButtons A');
  fUpdatingNotebook:=true;
  OldActivePage:=FNoteBook.ActivePage;
  // remove every page in the notebook without a visible page
  for i:=FNoteBook.PageCount-1 downto 0 do begin
    PageIndex:=IndexOfPageComponent(FNoteBook.Page[i]);
    if (PageIndex<0) or (not Pages[PageIndex].Visible) then begin
      if PageIndex>=0 then
        Pages[i].PageComponent:=nil;
      FNoteBook.Pages.Delete(i);
    end;
  end;
  // insert a notebook page for every visible palette page
  PageIndex:=0;
  for i:=0 to Count-1 do begin
    if not Pages[i].Visible then continue;
    if Pages[i].PageComponent=nil then begin
      // insert a new notebook page
      FNoteBook.Pages.Insert(PageIndex,Pages[i].PageName);
      Pages[i].PageComponent:=FNoteBook.Page[PageIndex];
    end else begin
      // move to the right position
      CurPageIndex:=TPage(Pages[i].PageComponent).PageIndex;
      if CurPageIndex<>PageIndex then
        FNoteBook.Pages.Move(CurPageIndex,PageIndex);
    end;
    inc(PageIndex);
  end;
  // create a speedbutton for every visible component
  for i:=0 to Count-1 do begin
    CurPage:=Pages[i];
    if not CurPage.Visible then continue;
    CurNoteBookPage:=TPage(CurPage.PageComponent);
    if not (CurNoteBookPage is TPage) then RaiseException('CurNoteBookPage');
    ButtonX:=0;
    // create selection button
    if CurPage.SelectButton=nil then begin
      CurBtn:=TSpeedButton.Create(nil);
      CurPage.SelectButton:=CurBtn;
      with CurBtn do begin
        Name:='PaletteSelectBtn'+IntToStr(i);
        Parent:=CurNoteBookPage;
        OnClick := @SelectionToolClick;
        Glyph.LoadFromLazarusResource('tmouse');
        Flat := True;
        GroupIndex:= 1;
        Down := True;
        Hint := lisSelectionTool;
        SetBounds(ButtonX,0,ComponentPaletteBtnWidth,ComponentPaletteBtnHeight);
      end;
    end;
    inc(ButtonX,((ComponentPaletteBtnWidth*3) div 2)+2);
    // create component buttons
    for j:=0 to CurPage.Count-1 do begin
      CurComponent:=TPkgComponent(CurPage[j]);
      if CurComponent.Visible then begin
        if CurComponent.Button=nil then begin
          CurBtn:=TSpeedButton.Create(nil);
          CurComponent.Button:=CurBtn;
          CreatePopupMenu;
          with CurBtn do begin
            Name:='PaletteBtnPage'+IntToStr(i)+'_'+IntToStr(j)
                  +'_'+CurComponent.ComponentClass.ClassName;
            Parent := CurNoteBookPage;
            Glyph := CurComponent.Icon;
            Width := ComponentPaletteBtnWidth;
            Height := ComponentPaletteBtnHeight;
            GroupIndex := 1;
            Flat := true;
            OnClick := @ComponentBtnClick;
            Hint := CurComponent.ComponentClass.ClassName;
            SetBounds(ButtonX,0,ComponentPaletteBtnWidth,ComponentPaletteBtnHeight);
            CurBtn.PopupMenu:=Self.PopupMenu;
          end;
          //writeln('TComponentPalette.UpdateNoteBookButtons Created Button: ',CurComponent.ComponentClass.ClassName,' ',CurComponent.Button.Name);
        end;
      end else if CurComponent.Button<>nil then begin
        //writeln('TComponentPalette.UpdateNoteBookButtons Destroy Button: ',CurComponent.ComponentClass.ClassName,' ',CurComponent.Button.Name);
        CurComponent.Button.Free;
        CurComponent.Button:=nil;
      end;
      inc(ButtonX,ComponentPaletteBtnWidth+2);
    end;
  end;
  // restore active page
  if (OldActivePage<>'') and (FNoteBook.Pages.IndexOf(OldActivePage)>=0) then
  begin
    FNoteBook.ActivePage:=OldActivePage;
  end else if FNoteBook.PageCount>0 then begin
    FNoteBook.PageIndex:=0;
  end;
  // unlock
  fUpdatingNotebook:=false;
  fNoteBookNeedsUpdate:=false;
  //writeln('TComponentPalette.UpdateNoteBookButtons END');
end;

procedure TComponentPalette.OnGetNonVisualCompIconCanvas(Sender: TObject;
  AComponent: TComponent; var IconCanvas: TCanvas; var IconWidth,
  IconHeight: integer);
var
  ARegComp: TRegisteredComponent;
  Icon: TBitmap;
begin
  if AComponent<>nil then
    ARegComp:=FindComponent(AComponent.ClassName)
  else
    ARegComp:=nil;
  if ARegComp<>nil then begin
    Icon:=TPkgComponent(ARegComp).Icon;
  end else begin
    Icon:=GetUnregisteredIcon;
  end;
  IconCanvas:=Icon.Canvas;
  IconWidth:=Icon.Width;
  IconHeight:=Icon.Height;
end;

function TComponentPalette.FindComponent(const CompClassName: string
  ): TRegisteredComponent;
var
  ANode: TAVLTreeNode;
begin
  ANode:=fComponents.FindKey(Pointer(CompClassName),
                          @CompareClassNameWithRegisteredComponent);
  if ANode<>nil then
    Result:=TRegisteredComponent(ANode.Data)
  else
    Result:=nil;
end;


initialization

{$I images/components_images.lrs}

end.

