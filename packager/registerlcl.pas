{  $Id$  }
{
 /***************************************************************************
                            registerlcl.pas
                            ---------------


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
    Registration of the LCL components.
}
unit RegisterLCL;

{$mode objfpc}{$H+}

interface

uses
  LazarusPackageIntf,
  Menus, Buttons, StdCtrls, ExtCtrls, ComCtrls, Forms, Grids, Controls,
  Dialogs, Spin, Arrow, Calendar;
  
procedure Register;

implementation

procedure Register;
begin
  RegisterUnit('Menus',@Menus.Register);
  RegisterUnit('Buttons',@Buttons.Register);
  RegisterUnit('StdCtrls',@StdCtrls.Register);
  RegisterUnit('ExtCtrls',@ExtCtrls.Register);
  RegisterUnit('ComCtrls',@ComCtrls.Register);
  RegisterUnit('Forms',@Forms.Register);
  RegisterUnit('Grids',@Grids.Register);
  RegisterUnit('Controls',@Controls.Register);
  RegisterUnit('Dialogs',@Dialogs.Register);
  RegisterUnit('Spin',@Spin.Register);
  RegisterUnit('Arrow',@Arrow.Register);
  RegisterUnit('Calendar',@Calendar.Register);
end;

end.

