{  $Id$  }
{
 /***************************************************************************
                               startlazarus.lpr
                             --------------------
                   This is a wrapper to (re)start lazarus.

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
}
program StartLazarus;

{$mode objfpc}{$H+}

{$IFDEF WIN32}
  {$R *.res}
{$ENDIF}

uses
  Interfaces, SysUtils,
  Forms,
  LazarusManager;
  
var
  ALazarusManager: TLazarusManager;
  
begin
  Application.Initialize;
  ALazarusManager := TLazarusManager.Create;
  ALazarusManager.Run;
  FreeAndNil(ALazarusManager);
end.
{
  $Log$
  Revision 1.4  2004/10/27 20:49:26  vincents
  Lazarus can be restarted, even if not started by startlazarus (only win32 implemented).

  Revision 1.3  2004/10/01 21:33:36  vincents
  Added icon to startlazarus.

  Revision 1.2  2004/09/03 21:14:50  vincents
  fix showing splash screen on restart

}

