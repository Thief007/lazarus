{
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
}
unit componentpalette_options;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils,
  Graphics, Forms, Controls, StdCtrls, Dialogs, Buttons, ComCtrls, ExtCtrls,
  FileUtil, LCLProc, LCLType, IDEProcs, EnvironmentOpts, LazarusIDEStrConsts,
  IDEOptionsIntf, IDEImagesIntf, ComponentReg, ComponentPalette, PackageDefs;

type
  { TCompPaletteOptionsFrame }

  TCompPaletteOptionsFrame = class(TAbstractIDEOptionsEditor)
    AddPageButton: TBitBtn;
    ComponentsListView: TListView;
    CompMoveDownBtn: TSpeedButton;
    PageMoveDownBtn: TSpeedButton;
    CompMoveUpBtn: TSpeedButton;
    PageMoveUpBtn: TSpeedButton;
    PagesListBox: TListBox;
    ComponentsGroupBox: TGroupBox;
    PagesGroupBox: TGroupBox;
    RestoreButton: TBitBtn;
    Splitter1: TSplitter;
    procedure AddPageButtonClick(Sender: TObject);
    procedure ComponentsListViewChange(Sender: TObject; Item: TListItem;
      Change: TItemChange);
    procedure ComponentsListViewClick(Sender: TObject);
    procedure ComponentsListViewCustomDraw(Sender: TCustomListView;
      const ARect: TRect; var DefaultDraw: Boolean);
    procedure ComponentsListViewCustomDrawItem(Sender: TCustomListView;
      Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
    procedure ComponentsListViewDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure ComponentsListViewDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure ComponentsListViewItemChecked(Sender: TObject; Item: TListItem);
    procedure ComponentsListViewKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure CompMoveDownBtnClick(Sender: TObject);
    procedure PageMoveDownBtnClick(Sender: TObject);
    procedure CompMoveUpBtnClick(Sender: TObject);
    procedure PageMoveUpBtnClick(Sender: TObject);
    procedure PagesListBoxDragDrop(Sender, Source: TObject; X, Y: Integer);
    procedure PagesListBoxDragOver(Sender, Source: TObject; X, Y: Integer;
      State: TDragState; var Accept: Boolean);
    procedure PagesListBoxKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure PagesListBoxSelectionChange(Sender: TObject; User: boolean);
    procedure RestoreButtonClick(Sender: TObject);
  private
    fLocalOptions: TCompPaletteOptions;
    fLocalUserOrder: TCompPaletteUserOrder;
    fPrevPageIndex: Integer;
    fConfigChanged: Boolean;
    fDialog: TAbstractOptionsEditorDialog;
    procedure WritePages(cpo: TCompPaletteOptions);
    procedure WriteComponents(cpo: TCompPaletteOptions);
    procedure FillPages;
    procedure InitialComps(aPageName: string; aCompList: TStringList);
    procedure FillComponents(aPageName: string);
    procedure MarkAsChanged;
    procedure UpdatePageMoveButtons(ListIndex: integer);
    procedure UpdateCompMoveButtons(ListIndex: integer);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function GetTitle: String; override;
    procedure Setup(ADialog: TAbstractOptionsEditorDialog); override;
    procedure ReadSettings(AOptions: TAbstractIDEOptions); override;
    procedure WriteSettings(AOptions: TAbstractIDEOptions); override;
    class function SupportedOptionsClass: TAbstractIDEOptionsClass; override;
  public
    property ConfigChanged: Boolean read fConfigChanged;
  end;

implementation

{$R *.lfm}

{ TCompPaletteOptionsFrame }

function TCompPaletteOptionsFrame.GetTitle: String;
begin
  Result := lisMenuViewComponentPalette;
end;

constructor TCompPaletteOptionsFrame.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  fLocalOptions:=TCompPaletteOptions.Create;
  fLocalUserOrder:=TCompPaletteUserOrder.Create(IDEComponentPalette);
end;

destructor TCompPaletteOptionsFrame.Destroy;
var
  i: Integer;
begin
  fLocalUserOrder.Free;
  fLocalOptions.Free;
  for i := 0 to PagesListBox.Count-1 do
    PagesListBox.Items.Objects[i].Free;     // Free the contained StringList.
  inherited Destroy;
end;

procedure TCompPaletteOptionsFrame.Setup(ADialog: TAbstractOptionsEditorDialog);
begin
  fDialog := ADialog;
  PagesGroupBox.Caption := lisCmpPages;
  AddPageButton.Caption := lisBtnDlgAdd;
  RestoreButton.Caption := lisCmpRestoreDefaults;

  ComponentsGroupBox.Caption := lisCmpLstComponents;
  ComponentsListView.Column[1].Caption := lisName;
  ComponentsListView.Column[2].Caption := lisPage;
  ComponentsListView.Column[3].Caption := lisPackage;
  ComponentsListView.SmallImages := IDEImages.Images_24;
  // Arrow buttons for pages
  PageMoveUpBtn.LoadGlyphFromResourceName(HInstance, 'arrow_up');
  PageMoveDownBtn.LoadGlyphFromResourceName(HInstance, 'arrow_down');
  PageMoveUpBtn.Hint:=lisMoveSelectedUp;
  PageMoveDownBtn.Hint:=lisMoveSelectedDown;
  // Arrow buttons for components
  CompMoveUpBtn.LoadGlyphFromResourceName(HInstance, 'arrow_up');
  CompMoveDownBtn.LoadGlyphFromResourceName(HInstance, 'arrow_down');
  CompMoveUpBtn.Hint:=lisMoveSelectedUp;
  CompMoveDownBtn.Hint:=lisMoveSelectedDown;

  fPrevPageIndex := -1;
  UpdatePageMoveButtons(PagesListBox.ItemIndex);
  UpdateCompMoveButtons(ComponentsListView.ItemIndex);
end;

procedure TCompPaletteOptionsFrame.ReadSettings(AOptions: TAbstractIDEOptions);
var
  cpo: TCompPaletteOptions;
begin
  cpo:=(AOptions as TEnvironmentOptions).ComponentPaletteOptions;
  fLocalOptions.Assign(cpo);
  fLocalUserOrder.Options:=fLocalOptions;
  fLocalUserOrder.SortPagesAndCompsUserOrder;
  FillPages;
  RestoreButton.Enabled := not cpo.IsDefault; // Initial visibility for RestoreButton.
end;

procedure TCompPaletteOptionsFrame.WriteSettings(AOptions: TAbstractIDEOptions);
var
  cpo: TCompPaletteOptions;
begin
  cpo:=(AOptions as TEnvironmentOptions).ComponentPaletteOptions;
  WritePages(cpo);
  WriteComponents(cpo);
end;

procedure TCompPaletteOptionsFrame.WritePages(cpo: TCompPaletteOptions);
var
  OrigPages, UserPages: TStringList;
  Pg: TBaseComponentPage;
  i: Integer;
  PgName: String;
begin
  Assert(Assigned(IDEComponentPalette),
    'TCompPaletteOptionsFrame.WritePages: IDEComponentPalette is not assigned.');
  OrigPages := TStringList.Create;
  UserPages := TStringList.Create;
  try
    // Collect original page names
    for i := 0 to IDEComponentPalette.OrigPagePriorities.Count-1 do
    begin
      PgName := IDEComponentPalette.OrigPagePriorities.Keys[i];
      Pg := IDEComponentPalette.GetPage(PgName, True);
      Assert(Assigned(Pg), 'TCompPaletteOptionsFrame.WritePages: PageName "'+PgName+'" not found.');
      if (Pg<>nil) and Pg.Visible then
        OrigPages.Add(Pg.PageName);
    end;
    // Collect user defined page names
    for i := 1 to PagesListBox.Items.Count-1 do     // Skip "all components" page
      UserPages.Add(PagesListBox.Items[i]);
    // If user made changes, store all page names to options
    if OrigPages.Equals(UserPages) then
      cpo.PageNames.Clear
    else
      cpo.PageNames.Assign(UserPages);
  finally
    UserPages.Free;
    OrigPages.Free;
  end;
end;

procedure TCompPaletteOptionsFrame.WriteComponents(cpo: TCompPaletteOptions);
var
  UserComps, OrigComps: TStringList;
  Pg: TBaseComponentPage;
  Comp: TRegisteredComponent;
  i, CompCnt: Integer;
  PgName: String;
begin
  OrigComps := TStringList.Create;
  try
    cpo.ClearComponentPages;
    for i := 1 to PagesListBox.Count-1 do      // Skip all components page
    begin
      PgName := PagesListBox.Items[i];
      UserComps := PagesListBox.Items.Objects[i] as TStringList;
      Assert(Assigned(UserComps), 'TCompPaletteOptionsFrame.WriteComponents: UserComps not assigned');
      OrigComps.Clear;
      Pg := IDEComponentPalette.GetPage(PgName);
      if Assigned(Pg) then       // Can be Nil if this page was added or renamed.
      begin
        // Collect original components from this page
        for CompCnt := 0 to IDEComponentPalette.Comps.Count-1 do
        begin
          Comp := IDEComponentPalette.Comps[CompCnt];
          if Comp.OrigPageName = PgName then
            OrigComps.Add(Comp.ComponentClass.ClassName);
        end;
      end;
      // Differs from original order -> add configuration for components
      if not OrigComps.Equals(UserComps) then
        cpo.AssignComponentPage(PgName, UserComps);
    end;
  finally
    OrigComps.Free;
  end;
end;

procedure TCompPaletteOptionsFrame.FillPages;
// Collect all available components (excluding hidden)
var
  CompList: TStringList;
  i: Integer;
  PgName: String;
begin
  for i := 0 to PagesListBox.Items.Count-1 do
    PagesListBox.Items.Objects[i].Free;
  PagesListBox.Clear;
  PagesListBox.Items.Add(lis_All_);
  for i := 0 to fLocalUserOrder.ComponentPages.Count-1 do
  begin
    PgName := fLocalUserOrder.ComponentPages[i];
    Assert(PgName<>'', 'TCompPaletteOptionsFrame.FillPages: PageName is empty.');
    CompList := TStringList.Create; // StringList will hold components for this page.
    InitialComps(PgName, CompList);
    PagesListBox.AddItem(PgName, CompList);
  end;
  PagesListBox.ItemIndex := 0;     // Activate first item
end;

procedure TCompPaletteOptionsFrame.InitialComps(aPageName: string; aCompList: TStringList);
var
  OrderedComps: TStringList;
  Comp: TRegisteredComponent;
  i, PgInd: Integer;
  CompName: String;
begin
  PgInd := fLocalUserOrder.ComponentPages.IndexOf(aPageName);
  Assert(PgInd > -1, 'TCompPaletteOptionsFrame.InitialComps: PageName "'+aPageName+'" not found');
  if PgInd>=0 then
  begin
    OrderedComps := fLocalUserOrder.ComponentPages.Objects[PgInd] as TStringList;
    for i := 0 to OrderedComps.Count-1 do
    begin
      CompName := OrderedComps[i];
      Comp := IDEComponentPalette.FindComponent(CompName);
      Assert(Assigned(Comp), 'TCompPaletteOptionsFrame.InitialComps: Component "'+CompName+'" not found');
      if Comp.Visible {and (Comp.OrigPageName<>'')} then
        aCompList.AddObject(Comp.ComponentClass.ClassName, Comp);
    end;
  end;
end;

procedure TCompPaletteOptionsFrame.FillComponents(aPageName: string);
var
  Comp: TRegisteredComponent;
  Item: TListItem;
  CompList: TStringList;
  PageCnt, CompCnt: Integer;
  StartInd, EndInd: Integer;
  RealPageName, CompName: String;
begin
  if aPageName = lis_All_ then
  begin
    StartInd := 1;                // Skip the first entry for all components.
    EndInd := PagesListBox.Count-1;
  end
  else begin
    StartInd := PagesListBox.Items.IndexOf(aPageName);
    EndInd := StartInd;
  end;
  ComponentsListView.Items.Clear;
  for PageCnt := StartInd to EndInd do
  begin
    RealPageName := PagesListBox.Items[PageCnt];
    CompList := PagesListBox.Items.Objects[PageCnt] as TStringList;
    for CompCnt := 0 to CompList.Count-1 do
    begin
      CompName := CompList[CompCnt];
      Comp := CompList.Objects[CompCnt] as TRegisteredComponent;
      Item := ComponentsListView.Items.Add;
      Item.SubItems.Add(CompName);
      Item.SubItems.Add(RealPageName);
      Item.SubItems.Add(Comp.GetUnitName);
      Item.Data := Comp;
    end;
  end;
end;

procedure TCompPaletteOptionsFrame.PagesListBoxSelectionChange(Sender: TObject; User: boolean);
var
  lb: TListBox;
begin
  lb := Sender as TListBox;
  if lb.ItemIndex = fPrevPageIndex then Exit;
  FillComponents(lb.Items[lb.ItemIndex]);
  UpdatePageMoveButtons(lb.ItemIndex);
  UpdateCompMoveButtons(-1);
  fPrevPageIndex := lb.ItemIndex;
end;

procedure TCompPaletteOptionsFrame.AddPageButtonClick(Sender: TObject);
var
  s: String;
begin
  s := InputBox(lisNewPage, lisPageName, '');
  PagesListBox.AddItem(s, TStringList.Create);
  MarkAsChanged;
end;

procedure TCompPaletteOptionsFrame.RestoreButtonClick(Sender: TObject);
begin
  fLocalOptions.Clear;
  fLocalUserOrder.SortPagesAndCompsUserOrder; // Only updates data structure.
  FillPages;
  RestoreButton.Enabled := False;
  fConfigChanged := True;
end;

// Drag-drop PagesListBox

procedure TCompPaletteOptionsFrame.PagesListBoxDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  lb: TListBox;
  DestInd: integer;

  procedure DoInsideListBox;
  begin
    Assert(Source = Sender, 'TCompPaletteOptionsFrame.PagesListBoxDragDrop: Source and Sender ListBoxes differ.');
    //DebugLn(['TCompPaletteOptionsFrame.PagesListBoxDragDrop: DestInd=',DestInd,', ItemIndex=',lb.ItemIndex]);
    if lb.ItemIndex < DestInd then
      Dec(DestInd);
    if (lb.ItemIndex > 0) and (lb.ItemIndex <> DestInd) then
    begin
      lb.Items.Move(lb.ItemIndex, DestInd);
      lb.ItemIndex := DestInd;
      MarkAsChanged;
    end;
  end;

  procedure DoFromListView(aSrcView: TListView);
  var
    Item: TListItem;
    SrcComps, DestComps: TStringList;
    xComp: TObject; // Actually TRegisteredComponent;
    CompName, SrcPage, DestPage: String;
    OrigInd, Ind: integer;
  begin
    OrigInd := 0;
    While OrigInd <= aSrcView.Items.Count-1 do
    begin
      // Move possibly many selected items
      if aSrcView.Items[OrigInd].Selected then
      begin
        Item := aSrcView.Items[OrigInd];
        CompName := Item.SubItems[0];
        SrcPage := Item.SubItems[1];
        DestPage := lb.Items[DestInd];
        if SrcPage <> DestPage then
        begin
          // Source component
          Ind := lb.Items.IndexOf(SrcPage);
          Assert(Ind > -1, 'TCompPaletteOptionsFrame.PagesListBoxDragDrop: '
                             +'source page index not found.');
          SrcComps := lb.Items.Objects[Ind] as TStringList;
          Ind := SrcComps.IndexOf(CompName);
          Assert(Ind > -1, 'TCompPaletteOptionsFrame.PagesListBoxDragDrop: '
                             +'source component index not found.');
          xComp := SrcComps.Objects[Ind];
          SrcComps.Delete(Ind);
          // Destination component
          Ind := lb.Items.IndexOf(DestPage);
          Assert(Ind > -1, 'TCompPaletteOptionsFrame.PagesListBoxDragDrop: '
                              +'destination page index not found.');
          DestComps := lb.Items.Objects[Ind] as TStringList;
          Ind := DestComps.IndexOf(CompName);
          Assert(Ind = -1, 'TCompPaletteOptionsFrame.PagesListBoxDragDrop: '
                             +'source component index already found.');
          DestComps.AddObject(CompName, xComp);
          // Delete the original item from ListView
          aSrcView.Items.Delete(OrigInd);
        end;
        //DebugLn(['TCompPaletteOptionsFrame.PagesListBoxDragDrop: CompName=',
        //         CompName, ', SrcPage=', SrcPage, ', DestPage=', DestPage]);
      end;
      inc(OrigInd);
    end;
    MarkAsChanged;
  end;

begin
  lb := Sender as TListBox;
  DestInd := lb.ItemAtPos(Point(X, Y), true);
  if DestInd > 0 then
  begin
    if Source is TListBox then
      DoInsideListBox
    else if Source is TListView then
      DoFromListView(Source as TListView);
  end;
end;

procedure TCompPaletteOptionsFrame.PagesListBoxDragOver(Sender,
  Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
var
  DestPt: TPoint;
  DestInd: integer;
  lb: TListBox;
begin
  lb := Sender as TListBox;
  DestPt := Point(X, Y);
  DestInd := lb.ItemAtPos(DestPt, true);
  Accept := (DestInd > 0)
      and ( ( (Source is TListBox) and (Source = Sender) and (lb.ItemIndex > 0)
            ) or (Source is TListView) );
end;

// Drag-drop ComponentsListView

procedure TCompPaletteOptionsFrame.ComponentsListViewDragDrop(Sender, Source: TObject; X, Y: Integer);
var
  lv: TListView;
  SrcInd, DstInd: Integer;
  SrcItem, DstItem: TListItem;
  Comps: TStringList;
begin
  lv := Sender as TListView;
  DstItem := lv.GetItemAt(X, Y);
  SrcItem := lv.Selected;
  if (DstItem = nil) or (SrcItem = nil) then exit;
  DstInd := DstItem.Index;
  SrcInd := SrcItem.Index;
  Assert(Source = Sender, 'TCompPaletteOptionsFrame.ComponentsListViewDragDrop: Source and Sender ListViews differ.');
  //DebugLn(['TCompPaletteOptionsFrame.ComponentsListViewDragDrop: DestInd=',DstInd,', ItemIndex=',SrcInd]);
  if SrcInd < DstInd then
    Dec(DstInd);
  if (SrcInd > -1) and (DstInd > -1) and (SrcInd <> DstInd) then
  begin
    // Move component names in ListView.
    lv.Selected := Nil;
    lv.Items.Move(SrcInd, DstInd);
    lv.Selected := lv.Items[DstInd];
    // Move component names inside a StringList, too.
    Comps := PagesListBox.Items.Objects[PagesListBox.ItemIndex] as TStringList;
    Comps.Move(SrcInd, DstInd);
    //
    UpdateCompMoveButtons(DstInd);
    MarkAsChanged;
  end;
end;

procedure TCompPaletteOptionsFrame.ComponentsListViewDragOver(Sender,
  Source: TObject; X, Y: Integer; State: TDragState; var Accept: Boolean);
begin
  Accept := (Source is TListView) and (Source = Sender)
    and (PagesListBox.ItemIndex > 0);  // No dragging when <All> components is selected.
end;

procedure TCompPaletteOptionsFrame.ComponentsListViewChange(Sender: TObject;
  Item: TListItem; Change: TItemChange);
begin
  if Item.Selected then
    UpdateCompMoveButtons(ComponentsListView.Items.IndexOf(Item));
end;

procedure TCompPaletteOptionsFrame.ComponentsListViewClick(Sender: TObject);
begin
  //DebugLn(['TCompPaletteOptionsFrame.ComponentsListViewClick: ']);
end;

procedure TCompPaletteOptionsFrame.ComponentsListViewItemChecked(Sender: TObject; Item: TListItem);
begin
  ;
end;

// Draw ComponentsListView

procedure TCompPaletteOptionsFrame.ComponentsListViewCustomDraw(Sender: TCustomListView;
  const ARect: TRect; var DefaultDraw: Boolean);
begin
  //DebugLn(['TCompPaletteOptionsFrame.ComponentsListViewCustomDraw: DefaultDraw=', DefaultDraw]);
end;

procedure TCompPaletteOptionsFrame.ComponentsListViewCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Comp: TRegisteredComponent;
  ARect: TRect;
  CurIcon: TCustomBitmap;
begin
  Comp := TRegisteredComponent(Item.Data);
  ARect := Item.DisplayRect(drIcon);
  if Comp is TPkgComponent then begin
    CurIcon := TPkgComponent(Comp).Icon;
    if CurIcon<>nil then
      Sender.Canvas.Draw(ARect.Left+(25-CurIcon.Width) div 2,
               ARect.Top+(ARect.Bottom-ARect.Top-CurIcon.Height) div 2, CurIcon);
  end;
end;

// Page move up / down

procedure TCompPaletteOptionsFrame.PagesListBoxKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift ) and ((Key = VK_UP) or (Key = VK_DOWN)) then begin
    if Key = VK_UP then
      PageMoveUpBtnClick(nil)
    else
      PageMoveDownBtnClick(nil);
    Key:=VK_UNKNOWN;
  end;
end;

procedure TCompPaletteOptionsFrame.PageMoveUpBtnClick(Sender: TObject);
var
  i: Integer;
begin
  i := PagesListBox.ItemIndex;
  if i > 1 then
  begin
    PagesListBox.Items.Exchange(i, i-1);
    PagesListBox.ItemIndex := i-1;
    UpdatePageMoveButtons(i-1);
    MarkAsChanged;
  end;
end;

procedure TCompPaletteOptionsFrame.PageMoveDownBtnClick(Sender: TObject);
var
  i: Integer;
begin
  i := PagesListBox.ItemIndex;
  if (i > 0) and (i < PagesListBox.Count-1) then
  begin
    PagesListBox.Items.Exchange(i, i+1);
    PagesListBox.ItemIndex := i+1;
    UpdatePageMoveButtons(i+1);
    MarkAsChanged;
  end;
end;

// Component move up / down

procedure TCompPaletteOptionsFrame.ComponentsListViewKeyDown(Sender: TObject;
  var Key: Word; Shift: TShiftState);
begin
  if (ssCtrl in Shift ) and ((Key = VK_UP) or (Key = VK_DOWN)) then begin
    if Key = VK_UP then
      CompMoveUpBtnClick(nil)
    else
      CompMoveDownBtnClick(nil);
    Key:=VK_UNKNOWN;
  end;
end;

procedure TCompPaletteOptionsFrame.CompMoveUpBtnClick(Sender: TObject);
var
  i: Integer;
begin
  i := ComponentsListView.ItemIndex;
  if i > 0 then
  begin
    ComponentsListView.Selected := Nil;
    ComponentsListView.Items.Exchange(i, i-1);
    ComponentsListView.Selected := ComponentsListView.Items[i-1];
    UpdateCompMoveButtons(i-1);
    MarkAsChanged;
  end;
end;

procedure TCompPaletteOptionsFrame.CompMoveDownBtnClick(Sender: TObject);
var
  i: Integer;
begin
  i := ComponentsListView.ItemIndex;
  if (i > -1) and (i < ComponentsListView.Items.Count-1) then
  begin
    ComponentsListView.Selected := Nil;
    ComponentsListView.Items.Exchange(i, i+1);
    ComponentsListView.Selected := ComponentsListView.Items[i+1];
    UpdateCompMoveButtons(i+1);
    MarkAsChanged;
  end;
end;

procedure TCompPaletteOptionsFrame.MarkAsChanged;
begin
  // ToDo: compare settings with original palette options after each change.
  RestoreButton.Enabled := True;
  fConfigChanged := True;
end;

procedure TCompPaletteOptionsFrame.UpdatePageMoveButtons(ListIndex: integer);
begin
  //DebugLn(['TCompPaletteOptionsFrame.UpdatePageMoveButtons: Page index=', ListIndex]);
  if (ListIndex > 0) and (ListIndex < PagesListBox.Items.Count) then
  begin
    PageMoveUpBtn.Enabled := ListIndex > 1;
    PageMoveDownBtn.Enabled := ListIndex < PagesListBox.Items.Count-1;
  end
  else begin
    PageMoveUpBtn.Enabled := False;
    PageMoveDownBtn.Enabled := False;
  end;
end;

procedure TCompPaletteOptionsFrame.UpdateCompMoveButtons(ListIndex: integer);
begin
  //DebugLn(['TCompPaletteOptionsFrame.UpdateCompMoveButtons: Component index=', ListIndex]);
  if (ListIndex > -1) and (ListIndex < ComponentsListView.Items.Count)
  and (PagesListBox.ItemIndex > 0) then  // No moving when <All> components is selected.
  begin
    CompMoveUpBtn.Enabled := ListIndex > 0;
    CompMoveDownBtn.Enabled := ListIndex < ComponentsListView.Items.Count-1;
  end
  else begin
    CompMoveUpBtn.Enabled := False;
    CompMoveDownBtn.Enabled := False;
  end;
end;

class function TCompPaletteOptionsFrame.SupportedOptionsClass: TAbstractIDEOptionsClass;
begin
  Result := TEnvironmentOptions;
end;

initialization
  RegisterIDEOptionsEditor(GroupEnvironment, TCompPaletteOptionsFrame, EnvOptionsCompPalette);

end.

