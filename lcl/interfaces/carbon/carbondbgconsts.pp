{
 /***************************************************************************
                    carbondbgconsts.pp  -  Carbon string constants
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

unit CarbonDbgConsts;

{$mode objfpc}{$H+}

interface

const
  SCarbonWSPrefix = 'TCarbonWidgetSet.';
   
  SCreateWidget = 'CreateWidget';
  SDestroyWidget = 'DestroyWidget';
  SInvalidate = 'Invalidate';
  SEnable = 'Enable';
  SSetColor = 'SetColor';
  SGetText = 'GetText';
  SSetText = 'SetText';
  SSetReadOnly = 'SetReadOnly';
  
  SShowModal = 'ShowModal';
  
  SCreate = 'Create';
  SDestroy = 'Destroy';
  
  SGetCurrentProc = 'GetCurrentProcess';
  SShowHideProc = 'ShowHideProcess';
  
  SGetKeyboardFocus = 'GetKeyboardFocus';
  
  SSetControlProp = 'SetControlProperty';

  SSetFontStyle = 'SetControlFontStyle';
  
  SCreateBevelButton = 'SCreateBevelButtonControl';

  SActivateWindow = 'ActivateWindow';
  SGetWindowBounds = 'GetWindowBounds';
  
  SViewForMouse = 'HIViewGetViewForMouseEvent';
  SViewVisible  = 'HIViewSetVisible';
  SViewConvert = 'HIViewConvertPoint';
  SViewRender  = 'HIViewRenderle';
  SViewNeedsDisplay = 'HiViewSetNeedsDisplay';
  SViewNeedsDisplayRect = 'HiViewSetNeedsDisplayInRect';
  SViewAddView = 'HIViewAddSubview';
  SViewSetScrollBarAutoHide = 'HIScrollViewSetScrollBarAutoHide';
  
  SSetTXNControls = 'TXNSetTXNObjectControls';
  
  SEnableControl = 'EnableControl';
  SDisableControl = 'DisableControl';
  
  SChangeMenuItemAttrs = 'ChangeMenuItemAttributes';
  SChangeMenuAttrs = 'ChangeMenuAttributes';
  
  SChangeWindowAttrs = 'ChangeWindowAttributes';
  SSetModality = 'SetWindowModality';
  
  SGetData = 'GetControlData';
  SSetData = 'GetControlData';
  
  SGetEvent = 'GetEventParameter';
  SSetEvent = 'SetEventParameter';
  SInstallEvent = 'InstallEventHandler';
  
  SControlPart = 'kEventParamControlPart';
  SKeyModifiers = 'kEventParamKeyModifiers';
  
  SControlFont = 'kControlFontStyleTag';
  
  SGetThemeMetric = 'GetThemeMetric';
  
  SGetUnjustifiedBounds = 'ATSUGetUnjustifiedBounds';
  SCreateStyle = 'ATSUCreateStyle';
  SDisposeStyle = 'ATSUDisposeStyle';

implementation

end.
