{
 /***************************************************************************
                               InterfaceBase.pp
                               ----------------
                   Initial Revision  : Fri Jul 23 20:00:00 PDT 1999


 ***************************************************************************/

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

{
@author(TInterfaceBase - Marc Weustink <weus@quicknet.nl>)                       
@created(13-Nov-1999)
@lastmod(13-Nov-1999)

Detailed description of the Unit.
} 

unit InterfaceBase;

{$mode objfpc}
{$LONGSTRINGS ON}

interface

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

uses
  SysUtils, LCLLinux, LCLType, VCLGlobals, Classes, LMessages, Controls,
  GraphType, GraphicsMath;

type

  { TInterfaceBase }
  {
    @abstract(Short description of the class.)
    Introduced by Marc Weustink <weus@quicknet.nl>
    Currently maintained by Marc Weustink <weus@quicknet.nl>
  }
  TInterfaceBase = Class(TObject)
  private
//    procedure SetCallback(Msg : LongInt; Sender : TObject); virtual; abstract;
//    procedure RemoveCallbacks(Sender : TObject); virtual; abstract;
  protected
    procedure SetCallback(Msg : LongInt; Sender : TObject); virtual; abstract;
    procedure RemoveCallbacks(Sender : TObject); virtual; abstract;
  public
    procedure AppTerminate; virtual; abstract;
    procedure DoEvents; virtual; abstract;
    procedure HandleEvents; virtual; abstract;
    procedure WaitMessage; virtual; abstract;
    procedure Init; virtual; abstract;
    function GetText(Sender: TControl; var Text: String): Boolean; virtual; abstract;
    function  IntSendMessage3(LM_Message : Integer; Sender : TObject; data : pointer) : integer; virtual; abstract;
    function UpdateHint(Sender: TObject): Integer; virtual; abstract;
    function RecreateWnd(Sender: TObject): Integer; virtual; abstract;

    
    {$DEFINE IF_BASE_MEMBER}
    {$I winapih.inc}
    {$UNDEF IF_BASE_MEMBER}
  end;

{$I defaultbitbtnimages.inc}
{$I messagedialogpixmaps.inc}

implementation

Uses
  LCLStrConsts, Forms, StdCtrls, ExtCtrls, Graphics, Buttons;


{$I interfacebase.inc}


initialization

finalization

end.

{
  $Log$
  Revision 1.20  2002/10/24 22:10:39  lazarus
  AJ: More changes for better code reuse between gnome & gtk interfaces

  Revision 1.19  2002/10/16 16:58:22  lazarus
  MG: moved SendCachedLCLMessages

  Revision 1.18  2002/10/15 07:01:29  lazarus
  MG: fixed timer checking

  Revision 1.17  2002/10/12 16:36:39  lazarus
  AJ: added new QueryUser/NotifyUser

  Revision 1.16  2002/10/11 16:00:39  lazarus
  AJ: made InputQuery Interface Dependant

  Revision 1.15  2002/10/01 10:15:31  lazarus
  MG: removed last clientrectbugfix switches

  Revision 1.14  2002/10/01 10:12:34  lazarus
  MG: added SendCachedLCLMessages to interfacebase for wysiwyg

  Revision 1.13  2002/09/19 16:45:54  lazarus
  MG: fixed Menu.Free and gdkwindow=nil bug

  Revision 1.12  2002/08/19 20:34:47  lazarus
  MG: improved Clipping, TextOut, Polygon functions

  Revision 1.11  2002/05/20 14:19:03  lazarus
  MG: activated the clientrect bugfixes

  Revision 1.10  2002/05/10 06:05:50  lazarus
  MG: changed license to LGPL

  Revision 1.9  2002/05/09 12:41:28  lazarus
  MG: further clientrect bugfixes

  Revision 1.8  2002/03/29 19:11:38  lazarus
  Added Triple Click
  Shane

  Revision 1.7  2002/03/27 08:57:16  lazarus
  MG: reduced compiler warnings

  Revision 1.6  2002/03/25 17:59:19  lazarus
  GTK Cleanup
  Shane

  Revision 1.5  2002/02/03 00:24:00  lazarus
  TPanel implemented.
  Basic graphic primitives split into GraphType package, so that we can
  reference it from interface (GTK, Win32) units.
  New Frame3d canvas method that uses native (themed) drawing (GTK only).
  New overloaded Canvas.TextRect method.
  LCLLinux and Graphics was split, so a bunch of files had to be modified.

  Revision 1.4  2001/07/01 23:33:13  lazarus
  MG: added WaitMessage and HandleEvents is now non blocking

  Revision 1.3  2001/03/27 21:12:53  lazarus
  MWE:
    + Turned on longstrings
    + modified memotest to add lines

  Revision 1.2  2001/02/01 19:34:50  lazarus
  TScrollbar created and a lot of code added.

  It's cose to working.
  Shane

  Revision 1.1  2000/07/13 10:28:24  michael
  + Initial import

  Revision 1.6  2000/05/27 22:20:55  lazarus
  MWE & VRS:
    + Added new hint code

  Revision 1.5  2000/03/23 22:48:56  lazarus
  MWE & Hans-Joachim Ott <hjott@compuserve.com>:
    + added replacement for LM_GetText

  Revision 1.4  2000/01/31 20:00:22  lazarus
  Added code for Application.ProcessMessages.  Needs work.
  Added TScreen.Width and TScreen.Height.  Added the code into
  GetSystemMetrics for these two properties.
  Shane

  Revision 1.3  1999/12/08 00:56:07  lazarus
  MWE:
    Fixed menus. Events aren't enabled yet (dumps --> invalid typecast ??)

  Revision 1.2  1999/11/13 12:58:03  lazarus
  MWE:
    Converted to Unix files :-)

  Revision 1.1  1999/11/13 12:53:53  lazarus
  MWE:
    Started to implement some platform dependent WINAPI stuff
    These are now part of InterfaceObject.

}
