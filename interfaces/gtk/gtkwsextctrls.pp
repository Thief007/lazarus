{ $Id$}
{
 *****************************************************************************
 *                             GtkWSExtCtrls.pp                              * 
 *                             ----------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit GtkWSExtCtrls;

{$mode objfpc}{$H+}

interface

uses
  LCLProc, LCLType, LCLIntf, Controls,
{$IFDEF GTK2}
  gtk2, gdk2, gdk2PixBuf, glib2,
{$ELSE GTK2}
  gtk, gdk, glib, gtk1WSPrivate,
{$ENDIF GTK2}
  GtkGlobals, GtkProc, GtkDef, ExtCtrls, Classes,
  WSExtCtrls, WSLCLClasses, gtkint, interfacebase;

type

  { TGtkWSCustomPage }

  TGtkWSCustomPage = class(TWSCustomPage)
  private
  protected
  public
    class procedure UpdateProperties(const ACustomPage: TCustomPage); override;
  end;

  { TGtkWSCustomNotebook }

  TGtkWSCustomNotebook = class(TWSCustomNotebook)
  private
  protected
  public
    class function  CreateHandle(const AWinControl: TWinControl;
      const AParams: TCreateParams): TLCLIntfHandle; override;
    class procedure AddPage(const ANotebook: TCustomNotebook;
      const AChild: TCustomPage; const AIndex: integer); override;
    class procedure MovePage(const ANotebook: TCustomNotebook; 
      const AChild: TCustomPage; const NewIndex: integer); override;
    class procedure RemovePage(const ANotebook: TCustomNotebook; 
      const AIndex: integer); override;
    
    class function GetNotebookMinTabHeight(const AWinControl: TWinControl): integer; override;
    class function GetNotebookMinTabWidth(const AWinControl: TWinControl): integer; override;
    class function GetTabIndexAtPos(const ANotebook: TCustomNotebook; const AClientPos: TPoint): integer; override;
    class procedure SetPageIndex(const ANotebook: TCustomNotebook; const AIndex: integer); override;
    class procedure SetTabPosition(const ANotebook: TCustomNotebook; const ATabPosition: TTabPosition); override;
    class procedure ShowTabs(const ANotebook: TCustomNotebook; AShowTabs: boolean); override;
  end;

  { TGtkWSPage }

  TGtkWSPage = class(TWSPage)
  private
  protected
  public
  end;

  { TGtkWSNotebook }

  TGtkWSNotebook = class(TWSNotebook)
  private
  protected
  public
  end;

  { TGtkWSShape }

  TGtkWSShape = class(TWSShape)
  private
  protected
  public
  end;

  { TGtkWSCustomSplitter }

  TGtkWSCustomSplitter = class(TWSCustomSplitter)
  private
  protected
  public
    class procedure DrawSplitter(const ASplitter: TCustomSplitter); override;
  end;

  { TGtkWSSplitter }

  TGtkWSSplitter = class(TWSSplitter)
  private
  protected
  public
  end;

  { TGtkWSPaintBox }

  TGtkWSPaintBox = class(TWSPaintBox)
  private
  protected
  public
  end;

  { TGtkWSCustomImage }

  TGtkWSCustomImage = class(TWSCustomImage)
  private
  protected
  public
  end;

  { TGtkWSImage }

  TGtkWSImage = class(TWSImage)
  private
  protected
  public
  end;

  { TGtkWSBevel }

  TGtkWSBevel = class(TWSBevel)
  private
  protected
  public
  end;

  { TGtkWSCustomRadioGroup }

  TGtkWSCustomRadioGroup = class(TWSCustomRadioGroup)
  private
  protected
  public
  end;

  { TGtkWSRadioGroup }

  TGtkWSRadioGroup = class(TWSRadioGroup)
  private
  protected
  public
  end;

  { TGtkWSCustomCheckGroup }

  TGtkWSCustomCheckGroup = class(TWSCustomCheckGroup)
  private
  protected
  public
  end;

  { TGtkWSCheckGroup }

  TGtkWSCheckGroup = class(TWSCheckGroup)
  private
  protected
  public
  end;

  { TGtkWSCustomLabeledEdit }

  TGtkWSCustomLabeledEdit = class(TWSCustomLabeledEdit)
  private
  protected
  public
  end;

  { TGtkWSLabeledEdit }

  TGtkWSLabeledEdit = class(TWSLabeledEdit)
  private
  protected
  public
  end;

  { TGtkWSCustomPanel }

  TGtkWSCustomPanel = class(TWSCustomPanel)
  private
  protected
  public
    class procedure SetColor(const AWinControl: TWinControl); override;
  end;

  { TGtkWSPanel }

  TGtkWSPanel = class(TWSPanel)
  private
  protected
  public
  end;

implementation

const
  GtkPositionTypeMap: array[TTabPosition] of TGtkPositionType =
  (
{ tpTop    } GTK_POS_TOP,
{ tpBottom } GTK_POS_BOTTOM,
{ tpLeft   } GTK_POS_LEFT,
{ tpRight  } GTK_POS_RIGHT
  );

{ TGtkWSCustomPage }

class procedure TGtkWSCustomPage.UpdateProperties(const ACustomPage: TCustomPage);
begin
  UpdateNotebookPageTab(nil, ACustomPage);
end;

{ TGtkWSCustomNotebook }

class function TGtkWSCustomNotebook.CreateHandle(const AWinControl: TWinControl;
  const AParams: TCreateParams): TLCLIntfHandle;
var
  AWidget: PGtkNoteBook;
begin
  AWidget := PGtkNoteBook(gtk_notebook_new());
  {$IFDEF DebugLCLComponents}
  DebugGtkWidgets.MarkCreated(Pointer(AWidget),'notebook '+dbgsName(AWinControl));
  {$ENDIF}
  gtk_notebook_set_scrollable(AWidget, true);
  gtk_notebook_popup_enable(AWidget);
  if TCustomNotebook(AWinControl).PageCount=0 then
    // a gtk notebook needs a page
    // -> add dummy page
    GTKWidgetSet.AddDummyNoteBookPage(AWidget);

  gtk_notebook_set_tab_pos(AWidget, GtkPositionTypeMap[TCustomNotebook(AWinControl).TabPosition]);
  GTKWidgetSet.FinishComponentCreate(AWinControl, AWidget);
  Result := THandle(AWidget);
end;

class procedure TGtkWSCustomNotebook.AddPage(const ANotebook: TCustomNotebook;
  const AChild: TCustomPage; const AIndex: integer);
{
  Inserts a new page to a notebook at position Index. The ANotebook is a
  TCustomNoteBook, the AChild one of its TCustomPage. Both handles must already
  be created. ANoteBook Handle is a PGtkNoteBook and APage handle is a
  PGtkFixed.
  This procedure creates a new tab with an optional image, the page caption and
  an optional close button. The image and the caption will also be added to the
  tab popup menu.
}
var
  NoteBookWidget: PGtkWidget;  // the notebook
  PageWidget: PGtkWidget;      // the page (content widget)
  TabWidget: PGtkWidget;       // the tab (hbox containing a pixmap, a label
                               //          and a close button)
  TabLabelWidget: PGtkWidget;  // the label in the tab
  MenuWidget: PGtkWidget;      // the popup menu (hbox containing a pixmap and
                               // a label)
  MenuLabelWidget: PGtkWidget; // the label in the popup menu item
begin
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn(['TGtkWSCustomNotebook.AddPage ',dbgsName(ANoteBook),' ',ANotebook.HandleAllocated,' AChild=',dbgsName(AChild),' ',AChild.HandleAllocated,' Child.TabVisible=',AChild.TabVisible]);
  {$ENDIF}
  NoteBookWidget:=PGtkWidget(ANoteBook.Handle);
  PageWidget:=PGtkWidget(AChild.Handle);

  // set LCL size
  AChild.SetBounds(AChild.Left,AChild.Top,ANotebook.ClientWidth,ANotebook.ClientHeight);

  if AChild.TabVisible then
    gtk_widget_show(PageWidget);

  // Check if already created. if so just show it because it is invisible
  if gtk_notebook_get_tab_label(PGtkNoteBook(NoteBookWidget), PageWidget) <> nil
  then begin
    {$IFDEF NOTEBOOK_DEBUG}
    DebugLn(['TGtkWSCustomNotebook.AddPage already added']);
    {$ENDIF}
    exit;
  end;
  
  // create the tab (hbox container)
  TabWidget:=gtk_hbox_new(false,1);
  begin
    gtk_object_set_data(PGtkObject(TabWidget), 'TabImage', nil);
    gtk_object_set_data(PGtkObject(TabWidget), 'TabCloseBtn', nil);
    // put a label into the tab
    TabLabelWidget:=gtk_label_new('');
    gtk_object_set_data(PGtkObject(TabWidget), 'TabLabel', TabLabelWidget);
    gtk_widget_show(TabLabelWidget);
    gtk_box_pack_start_defaults(PGtkBox(TabWidget),TabLabelWidget);
  end;
  if AChild.TabVisible then
    gtk_widget_show(TabWidget);

  // create popup menu item
  MenuWidget:=gtk_hbox_new(false,2);
  begin
    // set icon widget to nil
    gtk_object_set_data(PGtkObject(MenuWidget), 'TabImage', nil);
    // put a label into the menu
    MenuLabelWidget:=gtk_label_new('');
    gtk_object_set_data(PGtkObject(MenuWidget), 'TabLabel', MenuLabelWidget);
    gtk_widget_show(MenuLabelWidget);
    gtk_box_pack_start_defaults(PGtkBox(MenuWidget),MenuLabelWidget);
  end;
  if AChild.TabVisible then
    gtk_widget_show(MenuWidget);

  // remove the dummy page (a gtk_notebook needs at least one page)
  RemoveDummyNoteBookPage(PGtkNotebook(NoteBookWidget));
  // insert the page
  gtk_notebook_insert_page_menu(GTK_NOTEBOOK(NotebookWidget), PageWidget,
    TabWidget, MenuWidget, AIndex);

  UpdateNotebookPageTab(ANoteBook, AChild);
  UpdateNoteBookClientWidget(ANoteBook);
end;

class procedure TGtkWSCustomNotebook.MovePage(const ANotebook: TCustomNotebook;
  const AChild: TCustomPage; const NewIndex: integer);
var
  NoteBookWidget: PGtkNotebook;
begin
  NoteBookWidget:=PGtkNotebook(ANoteBook.Handle);
  gtk_notebook_reorder_child(NoteBookWidget, PGtkWidget(AChild.Handle), NewIndex);
  UpdateNoteBookClientWidget(ANoteBook);
end;

class procedure TGtkWSCustomNotebook.RemovePage(const ANotebook: TCustomNotebook;
  const AIndex: integer);
var
  PageWidget: PGtkWidget;
  Page: TCustomPage;
begin
  // The gtk does not provide a function to remove a page without destroying it.
  // Luckily the LCL destroys the Handle, when a page is removed, so this
  // function is not needed.
  {$IFDEF NOTEBOOK_DEBUG}
  DebugLn(['TGtkWSCustomNotebook.RemovePage AIndex=',AIndex,' ',DbgSName(ANotebook.Page[AIndex])]);
  {$ENDIF}
  Page:=ANotebook.Page[AIndex];
  if not Page.HandleAllocated then exit;
  PageWidget := PGtkWidget(Page.Handle);
  gtk_widget_hide(PageWidget);
end;

class function TGtkWSCustomNotebook.GetNotebookMinTabHeight(
  const AWinControl: TWinControl): integer;
var
  NBWidget: PGTKWidget;
  BorderWidth: Integer;
  {$IFDEF Gtk1}
  Requisition: TGtkRequisition;
  {$ENDIF}
  Page: PGtkNotebookPage;
begin
  Result:=inherited GetNotebookMinTabHeight(AWinControl);
  //debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight A ',dbgs(Result));
  exit;

  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight A ',dbgs(AWinControl.HandleAllocated));
  if AWinControl.HandleAllocated then
    NBWidget:=PGTKWidget(AWinControl.Handle)
  else
    NBWidget:=GetStyleWidget(lgsNotebook);

  // ToDo: find out how to create a fully working hidden Notebook style widget

  if (NBWidget=nil) then begin
    Result:=inherited GetNotebookMinTabHeight(AWinControl);
    exit;
  end;
  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight NBWidget: ',GetWidgetDebugReport(NBWidget),
   ' ',dbgs(NBWidget^.allocation.width),'x',dbgs(NBWidget^.allocation.height));
  
  BorderWidth:=(PGtkContainer(NBWidget)^.flag0 and bm_TGtkContainer_border_width)
               shr bp_TGtkContainer_border_width;
  if PGtkNoteBook(NBWidget)^.first_tab<>nil then
    Page:=PGtkNoteBook(NBWidget)^.cur_page;

  Result:=BorderWidth;
  {$IFDEF GTK2}
  if (Page<>nil) then begin
    debugln('TGtkWSCustomNotebook.RemovePage TODO');
  end;
  {$ELSE GTK2}
  if (NBWidget^.thestyle<>nil) and (PGtkStyle(NBWidget^.thestyle)^.klass<>nil) then
    inc(Result,PGtkStyle(NBWidget^.thestyle)^.klass^.ythickness);
  if (Page<>nil) and (Page^.child<>nil) then begin
    gtk_widget_size_request(Page^.Child, @Requisition);
    gtk_widget_map(Page^.child);
    debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight B ',dbgs(Page^.child^.allocation.height),
      ' ',GetWidgetDebugReport(Page^.child),' Requisition=',dbgs(Requisition.height));
    inc(Result,Page^.child^.allocation.height);
  end;
  {$ENDIF GTK2}
  debugln('TGtkWSCustomNotebook.GetNotebookMinTabHeight END ',dbgs(Result),' ',
    GetWidgetDebugReport(NBWidget));
end;

class function TGtkWSCustomNotebook.GetNotebookMinTabWidth(
  const AWinControl: TWinControl): integer;
begin
  Result:=inherited GetNotebookMinTabWidth(AWinControl);
end;

class function TGtkWSCustomNotebook.GetTabIndexAtPos(
  const ANotebook: TCustomNotebook; const AClientPos: TPoint): integer;
var
  NoteBookWidget: PGtkNotebook;
  i: integer;
  TabWidget: PGtkWidget;
  PageWidget: PGtkWidget;
  NotebookPos: TPoint;
  Count: guint;
begin
  Result:=-1;
  NoteBookWidget:=PGtkNotebook(ANotebook.Handle);
  if (NotebookWidget=nil) then exit;
  //DebugLn(['TGtkWSCustomNotebook.GetTabIndexAtPos ',GetWidgetDebugReport(PGtkWidget(NotebookWidget))]);
  NotebookPos:=AClientPos;
  // go through all tabs
  Count:=g_list_length(NoteBookWidget^.Children);
  for i:=0 to Count-1 do begin
    PageWidget:=gtk_notebook_get_nth_page(NoteBookWidget,i);
    if PageWidget<>nil then begin
      TabWidget:=gtk_notebook_get_tab_label(NoteBookWidget, PageWidget);
      if TabWidget<>nil then begin
        // test if position is in tabwidget
        if (TabWidget^.Allocation.X<=NoteBookPos.X)
        and (TabWidget^.Allocation.Y<=NoteBookPos.Y)
        and (TabWidget^.Allocation.X+TabWidget^.Allocation.Width>NoteBookPos.X)
        and (TabWidget^.Allocation.Y+TabWidget^.Allocation.Height>NoteBookPos.Y)
        then begin
          Result:=i;
          exit;
        end;
      end;
    end;
  end;
end;

class procedure TGtkWSCustomNotebook.SetPageIndex(
  const ANotebook: TCustomNotebook; const AIndex: integer);
begin
  gtk_notebook_set_page(PGtkNotebook(ANotebook.Handle), AIndex);
  UpdateNoteBookClientWidget(ANotebook);
end;

class procedure TGtkWSCustomNotebook.SetTabPosition(
  const ANotebook: TCustomNotebook; const ATabPosition: TTabPosition);
begin
  gtk_notebook_set_tab_pos(PGtkNotebook(ANotebook.Handle),
    GtkPositionTypeMap[ATabPosition]);
end;

class procedure TGtkWSCustomNotebook.ShowTabs(const ANotebook: TCustomNotebook;
  AShowTabs: boolean);
begin
  gtk_notebook_set_show_tabs(PGtkNotebook(ANotebook.Handle), AShowTabs);
end;

{ TGtkWSCustomSplitter }

class procedure TGtkWSCustomSplitter.DrawSplitter(
  const ASplitter: TCustomSplitter);
var
  Widget: PGtkWidget;
  ClientWidget: Pointer;
  DCOrigin: TPoint;
  Area: TGdkRectangle;
  Style: PGtkStyle;
  AWindow: PGdkWindow;
  DevContext: TDeviceContext;
  ARect: TRect;
  {$IFDEF Gtk1}
  Detail: PChar;
  {$ELSE}
  Orientation: TGtkOrientation;
  {$ENDIF}
begin
  if not ASplitter.HandleAllocated then exit;
  DevContext:=TDeviceContext(ASplitter.Canvas.Handle);
  Widget:=PGtkWidget(ASplitter.Handle);
  ClientWidget:=GetFixedWidget(Widget);
  if ClientWidget<>nil then
    Widget:=ClientWidget;
  AWindow:=DevContext.Drawable;

  Style:=GetStyle(lgsButton);

  DCOrigin:=GetDCOffset(DevContext);
  Area.X:=DCOrigin.X;
  Area.Y:=DCOrigin.Y;
  Area.Width:=ASplitter.Width;
  Area.Height:=ASplitter.Height;
  
  if ASplitter.Beveled then begin
    ARect:=Bounds(Area.x,Area.y,Area.Width,Area.Height);
    DrawEdge(HDC(DevContext),ARect,BDR_RAISEDOUTER,BF_ADJUST+BF_RECT);
    Area.X:=ARect.Left;
    Area.Y:=ARect.Top;
    Area.Width:=ARect.Right-ARect.Left;
    Area.Height:=ARect.Bottom-ARect.Top;
  end;

  {$IFDEF Gtk1}
  if ASplitter.ResizeAnchor in [akTop,akBottom] then begin
    Detail:='vpaned';
  end else begin
    Detail:='hpaned';
  end;
  gtk_paint_box(Style, AWindow,
    GTK_WIDGET_STATE(Widget),
    GTK_SHADOW_NONE,
    @Area, Widget, Detail,
    Area.X,Area.Y,Area.Width,Area.Height);
  {$ELSE}
  if ASplitter.ResizeAnchor in [akTop,akBottom] then begin
    Orientation:=GTK_ORIENTATION_VERTICAL;
  end else begin
    Orientation:=GTK_ORIENTATION_HORIZONTAL;
  end;
  gtk_paint_handle(Style,AWindow,
    GTK_WIDGET_STATE(Widget),
    GTK_SHADOW_NONE,
    @Area, Widget, 'paned',
    Area.X,Area.Y,Area.Width,Area.Height,
    Orientation);
  {$ENDIF}
end;


class procedure TGtkWSCustomPanel.SetColor(const AWinControl: TWinControl);
var
  MainWidget: PGtkWidget;

begin
  if not AWinControl.HandleAllocated then exit;
{  if  ((csOpaque in AWinControl.ControlStyle)
  and GtkWidgetIsA(pGtkWidget(AWinControl.handle),GTKAPIWidget_GetType)) then
    exit;
}
  //DebugLn('TGtkWSWinControl.SetColor ',DbgSName(AWinControl));
{  GtkWidgetSet.SetWidgetColor(pGtkWidget(AWinControl.handle),
                              AWinControl.font.color, AWinControl.color,
                              [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,
                               GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);
}
//    GtkWidgetSet.setWidgetFont(pGtkWidget(AWinControl.handle),aWinControl.font);


  MainWidget:=GetFixedWidget(pGtkWidget(AWinControl.handle));
  if MainWidget<>nil then
  GtkWidgetSet.SetWidgetColor(MainWidget,
                              AWinControl.font.color, AWinControl.color,
                              [GTK_STATE_NORMAL,GTK_STATE_ACTIVE,
                               GTK_STATE_PRELIGHT,GTK_STATE_SELECTED]);

  UpdateWidgetStyleOfControl(AWinControl);
end;


initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TCustomPage, TGtkWSCustomPage);
{$IFDEF GTK1}
  RegisterWSComponent(TCustomNotebook, TGtkWSCustomNotebook, TGtk1PrivateNotebook);
{$ENDIF}
//  RegisterWSComponent(TPage, TGtkWSPage);
//  RegisterWSComponent(TNotebook, TGtkWSNotebook);
//  RegisterWSComponent(TShape, TGtkWSShape);
  RegisterWSComponent(TCustomSplitter, TGtkWSCustomSplitter);
//  RegisterWSComponent(TSplitter, TGtkWSSplitter);
//  RegisterWSComponent(TPaintBox, TGtkWSPaintBox);
//  RegisterWSComponent(TCustomImage, TGtkWSCustomImage);
//  RegisterWSComponent(TImage, TGtkWSImage);
//  RegisterWSComponent(TBevel, TGtkWSBevel);
//  RegisterWSComponent(TCustomRadioGroup, TGtkWSCustomRadioGroup);
//  RegisterWSComponent(TRadioGroup, TGtkWSRadioGroup);
//  RegisterWSComponent(TCustomCheckGroup, TGtkWSCustomCheckGroup);
//  RegisterWSComponent(TCheckGroup, TGtkWSCheckGroup);
//  RegisterWSComponent(TCustomLabeledEdit, TGtkWSCustomLabeledEdit);
//  RegisterWSComponent(TLabeledEdit, TGtkWSLabeledEdit);
  RegisterWSComponent(TCustomPanel, TGtkWSCustomPanel);
//  RegisterWSComponent(TPanel, TGtkWSPanel);
////////////////////////////////////////////////////

end.
