{ $Id$ }
{                    ----------------------------------------  
                       DebuggerDlg.pp  -  Base class for all
                         debugger related forms
                     ---------------------------------------- 
 
 @created(Wed Mar 16st WET 2001)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.net>)                       

 This unit contains the base class for all debugger related dialogs. 
 All common info needed for the IDE is found in this class
 
/*************************************************************************** 
 *                                                                         * 
 *   This program is free software; you can redistribute it and/or modify  * 
 *   it under the terms of the GNU General Public License as published by  * 
 *   the Free Software Foundation; either version 2 of the License, or     * 
 *   (at your option) any later version.                                   * 
 *                                                                         * 
 ***************************************************************************/ 
} 
unit DebuggerDlg;

{$mode objfpc}{$H+}

interface

uses
  Forms, Debugger;

type
  TDebuggerDlgClass = class of TDebuggerDlg;
  
  TDebuggerDlg = class(TForm)
  private                        
    FDebugger: TDebugger;
  protected                                              
    procedure SetDebugger(const ADebugger: TDebugger); virtual;
  public 
    destructor Destroy; override;
    property Debugger: TDebugger read FDebugger write SetDebugger;
  end;

implementation 
          
{ TDebuggerDlg }          
          
destructor TDebuggerDlg.Destroy; 
begin
  Debugger := nil;
  inherited;
end;

procedure TDebuggerDlg.SetDebugger(const ADebugger: TDebugger); 
begin
  FDebugger := ADebugger; 
end;


{ =============================================================================
  $Log$
  Revision 1.1  2002/03/23 15:54:30  lazarus
  MWE:
    + Added locals dialog
    * Modified breakpoints dialog (load as resource)
    + Added generic debuggerdlg class
    = Reorganized main.pp, all debbugger relater routines are moved
      to include/ide_debugger.inc

  
}
end.