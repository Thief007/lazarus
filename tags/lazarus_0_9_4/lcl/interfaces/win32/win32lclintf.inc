{ $Id$ }
{******************************************************************************
                 All GTK interface communication implementations.
                   Initial Revision  : Sun Nov 23 23:53:53 2003


  !! Keep alphabetical !!

  Support routines go to gtkproc.pp

 ******************************************************************************
 Implementation
 ******************************************************************************

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

//##apiwiz##sps##   // Do not remove

procedure TWin32WidgetSet.DrawArrow(Arrow: TComponent; Canvas: TPersistent);
begin
  Windows.DrawFrameControl(TCanvas(Canvas).Handle, 
{$ifdef VER1_0}
  	Windows.RECT(TControl(Arrow).ClientRect),
{$else}  
  	TControl(Arrow).ClientRect,
{$endif}  
	DFC_MENU, DFCS_MENUARROW);
end;

{------------------------------------------------------------------------------
  Function: GetAcceleratorString
  Params: AVKey:
          AShiftState:
  Returns:

 ------------------------------------------------------------------------------}
function TWin32WidgetSet.GetAcceleratorString(const AVKey: Byte; const AShiftState: TShiftState): String;
begin
  //TODO: Implement
  Result := '';
end;

{------------------------------------------------------------------------------
  Function: GetControlConstraints
  Params: Constraints: TObject
  Returns: true on success

  Updates the constraints object (e.g. TSizeConstraints) with interface specific
  bounds.
 ------------------------------------------------------------------------------}
function TWin32WidgetSet.GetControlConstraints(Constraints: TObject): boolean;
var
  SizeConstraints: TSizeConstraints;
  SizeRect: TRect;
  Height: Integer;
begin
  Result:=true;
  if Constraints is TSizeConstraints then begin
    SizeConstraints:=TSizeConstraints(Constraints);

    if (SizeConstraints.Control=nil) then exit;

    if (SizeConstraints.Control is TComboBox)
      and TWinControl(SizeConstraints.Control).HandleAllocated then begin
      // the height of a combobox is fixed
      Windows.GetWindowRect(TWinControl(SizeConstraints.Control).Handle, @SizeRect);
      Height := SizeRect.Bottom - SizeRect.Top;
      SizeConstraints.SetInterfaceConstraints(0, Height, 0, Height);
    end;

  end;
end;

{------------------------------------------------------------------------------
  Function: GetListBoxIndexAtY
  Params: ListBox:
          y:
  Returns:

 ------------------------------------------------------------------------------}
function TWin32WidgetSet.GetListBoxIndexAtY(ListBox: TComponent; y: integer): integer;
begin
  Result := -1;
  if ListBox is TCustomListBox then begin
    Result := Windows.SendMessage(TCustomListBox(ListBox).Handle, LB_ITEMFROMPOINT, 0, MakeLParam(0,y));
    if hi(Result)=0 then
      Result := lo(Result)
    else Result := -1;
  end;
end;

{------------------------------------------------------------------------------
  Function: MenuItemSetCheck
  Params:  BaseMenuItem
  Returns: Nothing

  Checks or unchecks the specified menu item.
 ------------------------------------------------------------------------------}
Function TWin32WidgetSet.MenuItemSetCheck(BaseMenuItem: TComponent): Boolean;

  function doCheckMenuItem(aMI: TMenuItem; CF: Integer): boolean;
  begin
    Result := Windows.CheckMenuItem(aMI.Parent.Handle, aMI.Command, CF) <> DWORD($FFFFFFFF);
  end;
  
  procedure InterfaceTurnSiblingsOff(aMI: TMenuItem);
  var
    aParent, aSibling: TMenuItem;
    i: integer;
  begin
    // Just check all siblings that are in the same group
    // TMenuItem.TurnSiblingsOff should have modified internal flags
    aParent := aMI.Parent;
    if aParent <> nil then
      for i := 0 to aParent.Count-1 do 
      begin
        aSibling := aParent.Items[i];
        if (aSibling <> aMI) and aSibling.RadioItem and (aSibling.GroupIndex=aMI.GroupIndex) then
          doCheckMenuItem(aParent[i], MF_UNCHECKED or MF_BYCOMMAND);
      end;
  end;
var
  CheckFlag: Integer;
  AMenuItem: TMenuItem;
Begin
  AMenuItem:=BaseMenuItem as TMenuItem;
  if AMenuItem.Checked then CheckFlag := MF_CHECKED
  else CheckFlag := MF_UNCHECKED;
  CheckFlag := CheckFlag or MF_BYCOMMAND;
  if (CheckFlag and MF_CHECKED <> 0) and
    (AMenuItem.GroupIndex <> 0) and AMenuItem.RadioItem
  then
    InterfaceTurnSiblingsOff(aMenuItem);
  Result := doCheckMenuItem(aMenuItem, CheckFlag);
End;

{------------------------------------------------------------------------------
  Function: MenuItemSetEnable
  Params: BaseMenuItem:
  Returns:

  Enables, disables, or grays the specified menu item.
 ------------------------------------------------------------------------------}
Function TWin32WidgetSet.MenuItemSetEnable(BaseMenuItem: TComponent): Boolean;
Var
  EnableFlag: Integer;
  AMenuItem: TMenuItem;
Begin
  AMenuItem:=BaseMenuItem as TMenuItem;
  if AMenuItem.Enabled then EnableFlag := MF_ENABLED
  else EnableFlag := MF_GRAYED;
  EnableFlag := EnableFlag or MF_BYCOMMAND;
  Result := Boolean(Windows.EnableMenuItem(AMenuItem.Parent.Handle, AMenuItem.Command, EnableFlag));
End;

//##apiwiz##eps##   // Do not remove, no wizard declaration after this line

{ =============================================================================

  $Log$
  Revision 1.19  2004/10/16 10:15:45  micha
  cleanup statusbar methods in lcl interfaceobject
  fix statusbar recursive call issue

  Revision 1.18  2004/04/15 08:03:07  micha
  fix radiogroup menuitem, uncheck others in same group (from jreyes)

  Revision 1.17  2004/03/19 00:53:34  marc
  * Removed all ComponentCreateHandle routines

  Revision 1.16  2004/03/05 01:04:21  marc
  * Renamed TWin32Object to TWin32WidgetSet

  Revision 1.15  2004/02/27 00:42:41  marc
  * Interface CreateComponent splitup
  * Implemented CreateButtonHandle on GTK interface
    on win32 interface it still needs to be done
  * Changed ApiWizz to support multilines and more interfaces

  Revision 1.14  2004/02/23 08:19:04  micha
  revert intf split

  Revision 1.12  2004/02/22 15:47:58  micha
  fp 1.0 compatiblity

  Revision 1.11  2004/02/20 19:52:18  micha
  fixed: tarrow crash in win32
  added: interface function DrawArrow to draw themed arrow

  Revision 1.10  2004/02/05 13:53:38  mattias
  fixed GetConstraints for win32 intf

  Revision 1.9  2004/02/02 16:56:43  micha
  implement GetControlConstraints for combobox

  Revision 1.8  2004/01/12 08:36:34  micha
  statusbar interface dependent reimplementation (from vincent)

  Revision 1.7  2004/01/11 16:38:29  marc
  * renamed (Check|Enable)MenuItem to MenuItemSet(Check|Enable)
  + Started with accelerator nameing routines
  * precheckin for createwidget splitup

  Revision 1.6  2004/01/09 20:03:13  mattias
  implemented new statusbar methods in gtk intf

  Revision 1.5  2004/01/03 11:57:48  mattias
  applied implementation for LM_LB_GETINDEXAT  from Vincent

  Revision 1.4  2003/12/29 14:22:22  micha
  fix a lot of range check errors win32

  Revision 1.3  2003/11/27 23:02:30  mattias
  removed menutype.pas

  Revision 1.2  2003/11/26 21:55:15  mattias
  fixed win32 TBaseMenuitem

  Revision 1.1  2003/11/26 00:23:47  marc
  * implemented new LCL(check|enable)Menuitem functions
  * introduced the lclintf inc files to win32


}