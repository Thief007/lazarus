{  $Id$  }
{
 /***************************************************************************
                            basepkgmanager.pas
                            ------------------


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
    TBasePkgManager is the base class for TPkgManager, which controls the whole
    package system in the IDE. The base class is mostly abstract.
}
unit BasePkgManager;

{$mode objfpc}{$H+}

interface

{$I ide.inc}

uses
{$IFDEF IDE_MEM_CHECK}
  MemCheck,
{$ENDIF}
  Classes, SysUtils, Forms, PackageDefs;

type
  TPkgSaveFlag = (
    psfSaveAs
    );
  TPkgSaveFlags = set of TPkgSaveFlag;

  TBasePkgManager = class(TComponent)
  public
    procedure ConnectMainBarEvents; virtual; abstract;
    procedure ConnectSourceNotebookEvents; virtual; abstract;
    procedure SetupMainBarShortCuts; virtual; abstract;
    
    procedure LoadInstalledPackages; virtual; abstract;
    
    function ShowConfigureCustomComponents: TModalResult; virtual; abstract;
    function DoNewPackage: TModalResult; virtual; abstract;
    function DoShowOpenInstalledPckDlg: TModalResult; virtual; abstract;
    function DoOpenPackage(APackage: TLazPackage): TModalResult; virtual; abstract;
    function DoSavePackage(APackage: TLazPackage;
                           Flags: TPkgSaveFlags): TModalResult; virtual; abstract;
  end;

var
  PkgBoss: TBasePkgManager;

implementation

initialization
  PkgBoss:=nil;

end.

