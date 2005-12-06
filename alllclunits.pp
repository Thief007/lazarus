{  $Id$  }
{
 *****************************************************************************
                               alllclunits.pp

                      dummy unit to compile all units

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
unit AllLCLUnits;

{ At least 2.0.0 is required }
{$ifdef VER1}
  {$fatal You need at least FPC 2.0.0}
{$endif}

{$mode objfpc}{$H+}

interface

uses
  // resource strings
  LCLStrConsts,
  // base classes
  FPCAdds, LazLinkedList, DynHashArray, LCLMemManager, AvgLvlTree,
  StringHashList, ExtendedStrings, DynamicArray, UTrace, TextStrings,
  // base types and base functions
  LCLProc, LCLType, LCLResCache, GraphMath, FileCtrl, LMessages, LResources,
  FileUtil, Translations,
  // the interface base
  InterfaceBase,
  IntfGraphics,
  // components and functions
  LCLClasses, AsyncProcess,
  StdActns, Buttons, Extctrls, Calendar, Clipbrd, Forms, LCLIntf, Spin,
  Comctrls, Graphics, StdCtrls, Arrow, Controls, ImgList, Menus, Toolwin,
  Dialogs, Messages, Clistbox, ActnList, Grids, MaskEdit,
  Printers, PostScriptPrinter, PostScriptCanvas, CheckLst, PairSplitter,
  ExtDlgs, DBCtrls, DBGrids, DBActns, EditBtn, ExtGraphics, ColorBox,
  PropertyStorage, IniPropStorage, XMLPropStorage, Chart, LDockTree, LDockCtrl,
  // widgetset skeleton
  WSActnList, WSArrow, WSButtons, WSCalendar,
  WSCheckLst, WSCListBox, WSComCtrls, WSControls,
  WSDbCtrls, WSDBGrids, WSDialogs, WSDirSel,
  WSEditBtn, WSExtCtrls, WSExtDlgs, WSFileCtrl,
  WSForms, WSGrids, WSImgList, WSMaskEdit,
  WSMenus, WSPairSplitter, WSSpin, WSStdCtrls,
  WSToolwin,
  WSProc
  {$ifdef TRANSLATESTRING}
  ,DefaultTranslator
  {$ENDIF};

implementation

end.

