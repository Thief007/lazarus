{
 /***************************************************************************
                               Toolwin.pp
                             -------------------
                             Component Library ToolWindow Controls
                   Initial Revision  : THU Dec 9th 11:00am CST


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
@author(TToolWindow - Author Name <smiller@lakefield.net>)                       
@author(TMyOtherClass - Other Author Name <otherauthor@emailaddress.com>)                       
@created(08-DEC-1999)
@lastmod(08-DEC-1999)

Detailed description of the Unit.
} 

unit Toolwin;

//{$mode delphi}
{$mode objfpc}

interface

{$ifdef Trace}
  {$ASSERTIONS ON}
{$endif}

uses
  Classes, Controls, SysUtils, stdCtrls, Graphics, vclGlobals, lMessages,LCLLinux;


type

  { TToolWindow }
  {
    @abstract(Short description of the class.)
    Introduced by Author Name <author@emailaddress.com>
    Currently maintained by Maintainer Name <mainter@emailaddress.com>
  }
{ TToolWindow }

  TEdgeBorder = (ebLeft, ebTop, ebRight, ebBottom);
  TEdgeBorders = set of TEdgeBorder;

  TEdgeStyle = (esNone, esRaised, esLowered);

  TToolWindow = class(TWinControl)
  private
    FEdgeBorders: TEdgeBorders;
    FEdgeInner: TEdgeStyle;
    FEdgeOuter: TEdgeStyle;
    procedure SetEdgeBorders(Value: TEdgeBorders);
    procedure SetEdgeInner(Value: TEdgeStyle);
    procedure SetEdgeOuter(Value: TEdgeStyle);
    procedure LMNCCalcSize(var Message: TLMNCCalcSize); message LM_NCCALCSIZE;
    procedure LMNCPaint(var Message: TLMessage); message LM_NCPAINT;
    procedure CMBorderChanged(var Message: TLMessage); message CM_BORDERCHANGED;
    procedure CMCtl3DChanged(var Message: TLMessage); message CM_CTL3DCHANGED;
  public
    constructor Create(AOwner: TComponent); override;
    property EdgeBorders: TEdgeBorders read FEdgeBorders write SetEdgeBorders default [ebLeft, ebTop, ebRight, ebBottom];
    property EdgeInner: TEdgeStyle read FEdgeInner write SetEdgeInner default esRaised;
    property EdgeOuter: TEdgeStyle read FEdgeOuter write SetEdgeOuter default esLowered;
  end;

implementation

uses Interfaces;

{$I toolwindow.inc}


initialization

finalization

end.

