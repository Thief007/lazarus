{ 
 /*************************************************************************** 
                               Messages.pp  - 
                             ------------------- 
 
                   Initial Revision  : Tue Oct 19 CST 1999 
 
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
@author(Shane Miller)
@created()
@lastmod()

Detailed description of the Unit.
}

unit Messages; 
 
{$mode objfpc} 
//This unit is used only for compatability 
interface 
 
uses Classes,vclGlobals,lmessages; 

const
WM_DROPFILES   = LM_DROPFILES;
WM_ERASEBKGND  = LM_ERASEBKGND;
WM_GETDLGCODE  = LM_GETDLGCODE;
WM_HSCROLL     = LM_HSCROLL;
WM_KILLFOCUS   = LM_KILLFOCUS;
WM_NCHITTEST   = LM_NCHITTEST;
WM_SIZE        = LM_SIZE;
WM_SETCURSOR   = LM_SETCURSOR;
WM_SETFOCUS    = LM_SETFOCUS;
WM_SYSCHAR     = LM_SYSCHAR;
WM_SYSKEYDOWN  = LM_SYSKEYDOWN;
WM_SYSKEYUP    = LM_SYSKEYUP;
WM_VSCROLL     = LM_VSCROLL;


type

TMessage = TLMessage;

TWMKILLFOCUS      = TLMKILLFOCUS;
TWMMOUSE          = TLMMouse;
TWMNCHITTEST      = TLMNCHITTEST;
TWMSCROLL         = TLMSCROLL;
TWMSETCURSOR      = TLMSETCURSOR;
TWMSetFocus       = TLMSetFocus;
TWMSIZE           = TLMSIZE;


TWMGetDlgCode = TLMNoParams;

            

TWMMouseMove = TLMMouseMove;
 
implementation




end.
