{
 /***************************************************************************
                               filectrl.pp
                             -------------------
                             Component Library File Controls
                   Initial Revision  : Sun Apr 23 18:30:00 PDT 2000


 ***************************************************************************/

/***************************************************************************
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 ***************************************************************************/
}

{
@author(DirectoryExists - Curtis White <cwhite@aracnet.com>)                       
@created(23-Apr-2000)
@lastmod(23-Apr-2000)

This unit contains file and directory controls and supporting handling functions. 
} 

unit filectrl;

//{$mode delphi}
{$mode objfpc}

interface

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

uses
  SysUtils;


  {
    @abstract (Function to determine if a directory exists or not.)
    Introduced by Curtis White
    Currently maintained by Curtis White
  }
  function DirectoryExists(const Name: String): Boolean;


implementation

{$I filectrl.inc}


initialization

finalization

end.

{
  $Log$
  Revision 1.1  2000/07/13 10:28:23  michael
  + Initial import

  Revision 1.2  2000/05/09 00:00:33  lazarus
  Updated my email address in the documentation to the current one. Also
  removed email references in comments that were not @author comments to
  fix problems with the documentation produced by pasdoc.           CAW

  Revision 1.1  2000/04/24 05:03:25  lazarus
  Added filectrl unit for DirectoryExists function.      CAW


}

