// included by gtkcallback.pp

{
 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.LCL, included in this distribution,                 *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}

procedure DrawNotebookPageIcon(Page: TPage; Widget: PGtkWidget);
var
  NoteBook: TCustomNotebook;
  NoteBookWidget: PGtkWidget;
  PageWidget: PGtkWidget;
  TabWidget: PGtkWidget;
begin
  NoteBook:=Page.Parent as TCustomNotebook;
  if (NoteBook.Images=nil) or (Page.ImageIndex<0)
  or (Page.ImageIndex>=NoteBook.Images.Count)
  or (not NoteBook.HandleAllocated)
  or (not Page.HandleAllocated)
  then exit;
  NoteBookWidget:=PGtkWidget(NoteBook.Handle);
  PageWidget:=PGtkWidget(Page.Handle);

  // get the tab container and the tab icon widget
  TabWidget:=gtk_notebook_get_tab_label(PGtkNoteBook(NotebookWidget),
                                        PageWidget);
  if TabWidget=nil then exit;
  DrawImageListIconOnWidget(NoteBook.Images,Page.ImageIndex,Widget);
end;

function PageIconWidgetExposeAfter(Widget: PGtkWidget; Event: PGDKEventExpose;
  Data: gPointer): GBoolean; cdecl;
var
  ThePage: TPage;
begin
  Result := false;
  //DebugLn('PageIconWidgetExposeAfter ',HexStr(Cardinal(Widget),8));
  EventTrace('PageIconWidgetExposeAfter', Data);
  if (Event^.Count > 0) then exit;
  ThePage:=TObject(Data) as TPage;
  DrawNotebookPageIcon(ThePage,Widget);
end;

{$IFNDEF GTK2}
function PageIconWidgetDrawAfter(Widget: PGtkWidget; area: PGDKRectangle;
  data: gPointer) : GBoolean; cdecl;
var
  ThePage: TPage;
begin
  Result := false;
  //DebugLn('PageIconWidgetDrawAfter ',HexStr(Cardinal(Widget),8),' ',Area^.x,',',Area^.y);
  EventTrace('PageIconWidgetDrawAfter', Data);
  ThePage:=TObject(Data) as TPage;
  DrawNotebookPageIcon(ThePage,Widget);
end;
{$ENDIF}

// included by gtkcallback.pp
