{ $Id$}
{
 *****************************************************************************
 *                               GtkWSMenus.pp                               * 
 *                               -------------                               * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit GtkWSMenus;

{$mode objfpc}{$H+}

interface

uses
  Classes, InterfaceBase, LCLProc, LCLType, WSMenus, WSLCLClasses,
  {$IFDEF gtk2}
  glib2, gdk2pixbuf, gdk2, gtk2, Pango,
  {$ELSE}
  glib, gdk, gtk, {$Ifndef NoGdkPixbufLib}gdkpixbuf,{$EndIf}
  {$ENDIF}
  GtkInt, gtkProc, gtkglobals, Menus;

type
  { TGtkWSMenuItem }

  TGtkWSMenuItem = class(TWSMenuItem)
  private
  protected
  public
    class procedure AttachMenu(const AMenuItem: TMenuItem); override;
    class function  CreateHandle(const AMenuItem: TMenuItem): HMENU; override;
    class procedure DestroyHandle(const AMenuItem: TMenuItem); override;
    class procedure SetCaption(const AMenuItem: TMenuItem; const ACaption: string); override;
    class procedure SetShortCut(const AMenuItem: TMenuItem; const OldShortCut, NewShortCut: TShortCut); override;
    class procedure SetVisible(const AMenuItem: TMenuItem; const Visible: boolean); override;
  end;

  { TGtkWSMenu }

  TGtkWSMenu = class(TWSMenu)
  private
  protected
  public
    class function  CreateHandle(const AMenu: TMenu): HMENU; override;
  end;

  { TGtkWSMainMenu }

  TGtkWSMainMenu = class(TWSMainMenu)
  private
  protected
  public
  end;

  { TGtkWSPopupMenu }

  TGtkWSPopupMenu = class(TWSPopupMenu)
  private
  protected
  public
    class procedure Popup(const APopupMenu: TPopupMenu; const X, Y: integer); override;
  end;


implementation

{ TGtkWSMenuItem }

procedure TGtkWSMenuItem.AttachMenu(const AMenuItem: TMenuItem);
var
  //AccelKey: Integer;
  //AccelGroup: PGTKAccelGroup;
  MenuItem, ParentMenuWidget, ContainerMenu: PGtkWidget;

  procedure SetContainerMenuToggleSize;
  var MenuClass: PGtkWidgetClass;
  begin
    if GtkWidgetIsA(ContainerMenu,GTK_TYPE_MENU) then begin
      MenuClass:=GTK_WIDGET_CLASS(gtk_object_get_class(ContainerMenu));
      if OldMenuSizeRequestProc=nil then begin
        OldMenuSizeRequestProc:=MenuClass^.size_request;
      end;
      MenuClass^.size_request:=@MenuSizeRequest;
    end;
  end;

begin
  //DebugLn('TGtkWidgetSet.AttachMenu START ',AMenuItem.Name,':',AMenuItem.ClassName,' Parent=',AMenuItem.Parent.Name,':',AMenuItem.Parent.ClassName);
  with AMenuItem do
  begin
    MenuItem := PGtkWidget(Handle);
    if MenuItem=nil then
      RaiseException('TGtkWidgetSet.AttachMenu Handle=0');
    ParentMenuWidget := PGtkWidget(Parent.Handle);
    if ParentMenuWidget=nil then
      RaiseException('TGtkWidgetSet.AttachMenu ParentMenuWidget=nil');

    if GtkWidgetIsA(ParentMenuWidget,GTK_TYPE_MENU_BAR) then begin
      // mainmenu (= a menu bar)
      ContainerMenu:=ParentMenuWidget;
      gtk_menu_bar_insert(ParentMenuWidget,MenuItem, AMenuItem.MenuVisibleIndex);
    end
    else begin
      // menu item

      // find the menu container
      ContainerMenu := PGtkWidget(gtk_object_get_data(
                                                   PGtkObject(ParentMenuWidget),
                                                   'ContainerMenu'));
      if ContainerMenu = nil then begin
        if (GetParentMenu is TPopupMenu) and (Parent.Parent=nil) then begin
          ContainerMenu:=PGtkWidget(GetParentMenu.Handle);
          gtk_object_set_data(PGtkObject(ContainerMenu), 'ContainerMenu',
                              ContainerMenu);
        end else begin
          ContainerMenu := gtk_menu_new;
          gtk_object_set_data(PGtkObject(ParentMenuWidget), 'ContainerMenu',
                              ContainerMenu);
          gtk_menu_item_set_submenu(PGTKMenuItem(ParentMenuWidget),ContainerMenu);
        end;
      end;
      gtk_menu_insert(ContainerMenu, MenuItem, AMenuItem.MenuVisibleIndex);
    end;

    SetContainerMenuToggleSize;

    if GtkWidgetIsA(MenuItem, GTK_TYPE_RADIO_MENU_ITEM) then
      TGtkWidgetSet(InterfaceObject).RegroupMenuItem(HMENU(MenuItem),GroupIndex);
  end;
  //DebugLn('TGtkWidgetSet.AttachMenu END ',AMenuItem.Name,':',AMenuItem.ClassName);
end;

function  TGtkWSMenuItem.CreateHandle(const AMenuItem: TMenuItem): HMENU;
begin
  { TODO: cleanup }
  Result := HMENU(TGtkWidgetSet(InterfaceObject).CreateComponent(AMenuItem));
end;

procedure TGtkWSMenuItem.DestroyHandle(const AMenuItem: TMenuItem);
begin
  { TODO: cleanup }
  TGtkWidgetSet(InterfaceObject).DestroyLCLComponent(AMenuItem);
end;

procedure TGtkWSMenuItem.SetCaption(const AMenuItem: TMenuItem; const ACaption: string);
var
  MenuItemWidget: PGtkWidget;
begin
  if not AMenuItem.HandleAllocated then exit;
  MenuItemWidget:=PGtkWidget(AMenuItem.Handle);
  UpdateInnerMenuItem(AMenuItem,MenuItemWidget);
end;

procedure TGtkWSMenuItem.SetShortCut(const AMenuItem: TMenuItem; 
  const OldShortCut, NewShortCut: TShortCut);
begin
  Accelerate(AMenuItem, PGtkWidget(AMenuItem.Handle), NewShortcut,
    {$Ifdef GTK2}'activate'{$Else}'activate_item'{$EndIF});
end;

procedure TGtkWSMenuItem.SetVisible(const AMenuItem: TMenuItem;
  const Visible: boolean);
var
  MenuItemWidget: PGtkWidget;
begin
  if not AMenuItem.HandleAllocated then exit;
  MenuItemWidget:=PGtkWidget(AMenuItem.Handle);
  if gtk_widget_visible(MenuItemWidget)=Visible then exit;
  if Visible then
    gtk_widget_show(MenuItemWidget)
  else
    gtk_widget_hide(MenuItemWidget);
end;

{ TGtkWSMenu }

function  TGtkWSMenu.CreateHandle(const AMenu: TMenu): HMENU;
begin
  { TODO: cleanup }
  Result := HMENU(TGtkWidgetSet(InterfaceObject).CreateComponent(AMenu));
end;

{ TGtkWSPopupMenu }
procedure GtkWS_Popup(menu:  PGtkMenu; X, Y: pgint; Point: PPoint); cdecl;
begin
  X^ := Point^.X;
  Y^ := Point^.Y;
end;

procedure TGtkWSPopupMenu.Popup(const APopupMenu: TPopupMenu; const X, Y: integer);
var
APoint: TPoint;
begin
  ReleaseMouseCapture;
  APoint.X := X;
  APoint.Y := Y;
  gtk_menu_popup(PgtkMenu(APopupMenu.Handle),
                 nil,
                 nil,
                 TGtkMenuPositionFunc(@GtkWS_Popup),
                 @APoint,
                 0,
                 0);
  {Displays a menu and makes it available for selection. Applications
  can use this function to display context-sensitive menus, and will
  typically supply NULL for the parent_menu_shell, parent_menu_item,
  func and data parameters.
  The default menu positioning function will position the menu at the
  current pointer position.
  menu :  a GtkMenu.
  parent_menu_shell: the menu shell containing the triggering menu item.
  parent_menu_item: the menu item whose activation triggered the popup.
  func :  a user supplied function used to position the menu.
  data :  user supplied data to be passed to func.
  button :  the button which was pressed to initiate the event.
  activate_time : the time at which the activation event occurred.
  }

end;

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
  RegisterWSComponent(TMenuItem, TGtkWSMenuItem);
  RegisterWSComponent(TMenu, TGtkWSMenu);
//  RegisterWSComponent(TMainMenu, TGtkWSMainMenu);
  RegisterWSComponent(TPopupMenu, TGtkWSPopupMenu);
////////////////////////////////////////////////////
end.
