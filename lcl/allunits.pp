{  $Id$  }
{
 *****************************************************************************
                               allunits.pp

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
unit AllUnits;

{$mode objfpc}{$H+}

interface

uses
  InterfaceBase, Interfaces,   LCLStrConsts,
	Buttons,    Extctrls,        Registry,     VCLGlobals,   Calendar,
	Clipbrd,    Filectrl,        Forms,        LCLLinux,     Spin,
	Comctrls,   Graphics,        LMessages,    Stdctrls,     Arrow,
	Controls,   Imglist,         Menus,        Toolwin,
	Dialogs,    Messages,        UTrace,       DynHashArray,
	Clistbox,   Lazqueue;

implementation

end.

{ =============================================================================

  $Log$
  Revision 1.12  2002/07/04 11:46:00  lazarus
  MG: moved resourcestring to lclstrconsts.pas

  Revision 1.11  2002/05/10 06:05:48  lazarus
  MG: changed license to LGPL

  Revision 1.10  2001/12/06 13:39:36  lazarus
  Added TArrow component
  Shane

  Revision 1.9  2001/12/05 18:19:11  lazarus
  MG: added calendar to allunits and removed unused vars

  Revision 1.8  2001/06/16 09:14:38  lazarus
  MG: added lazqueue and used it for the messagequeue

  Revision 1.6  2001/03/27 20:55:23  lazarus
  MWE:
    * changed makefiles so that the LCL is build separate fron interfaces

  Revision 1.5  2001/03/19 18:51:57  lazarus
  MG: added dynhasharray and renamed tsynautocompletion

  Revision 1.4  2001/01/30 22:56:54  lazarus
  MWE:
    + added $mode objfpc directive

  Revision 1.3  2001/01/10 23:54:59  lazarus
  MWE:
    * Fixed make clean
    + moved allunits from exe to unit, skipping link stage

}
