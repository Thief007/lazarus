{ $Id$}
{
 *****************************************************************************
 *                              QtWSComCtrls.pp                              * 
 *                              ---------------                              * 
 *                                                                           *
 *                                                                           *
 *****************************************************************************

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
unit QtWSComCtrls;

{$mode objfpc}{$H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as little as posible circles,
// uncomment only when needed for registration
////////////////////////////////////////////////////
//  ComCtrls,
////////////////////////////////////////////////////
  WSComCtrls, WSLCLClasses;

type

  { TQtWSStatusBar }

  TQtWSStatusBar = class(TWSStatusBar)
  private
  protected
  public
  end;

  { TQtWSTabSheet }

  TQtWSTabSheet = class(TWSTabSheet)
  private
  protected
  public
  end;

  { TQtWSPageControl }

  TQtWSPageControl = class(TWSPageControl)
  private
  protected
  public
  end;

  { TQtWSCustomListView }

  TQtWSCustomListView = class(TWSCustomListView)
  private
  protected
  public
  end;

  { TQtWSListView }

  TQtWSListView = class(TWSListView)
  private
  protected
  public
  end;

  { TQtWSProgressBar }

  TQtWSProgressBar = class(TWSProgressBar)
  private
  protected
  public
  end;

  { TQtWSCustomUpDown }

  TQtWSCustomUpDown = class(TWSCustomUpDown)
  private
  protected
  public
  end;

  { TQtWSUpDown }

  TQtWSUpDown = class(TWSUpDown)
  private
  protected
  public
  end;

  { TQtWSToolButton }

  TQtWSToolButton = class(TWSToolButton)
  private
  protected
  public
  end;

  { TQtWSToolBar }

  TQtWSToolBar = class(TWSToolBar)
  private
  protected
  public
  end;

  { TQtWSToolButton }

  TQtWSToolButton = class(TWSToolButton)
  private
  protected
  public
  end;

  { TQtWSToolBar }

  TQtWSToolBar = class(TWSToolBar)
  private
  protected
  public
  end;

  { TQtWSTrackBar }

  TQtWSTrackBar = class(TWSTrackBar)
  private
  protected
  public
  end;

  { TQtWSCustomTreeView }

  TQtWSCustomTreeView = class(TWSCustomTreeView)
  private
  protected
  public
  end;

  { TQtWSTreeView }

  TQtWSTreeView = class(TWSTreeView)
  private
  protected
  public
  end;


implementation

initialization

////////////////////////////////////////////////////
// I M P O R T A N T
////////////////////////////////////////////////////
// To improve speed, register only classes
// which actually implement something
////////////////////////////////////////////////////
//  RegisterWSComponent(TStatusBar, TQtWSStatusBar);
//  RegisterWSComponent(TTabSheet, TQtWSTabSheet);
//  RegisterWSComponent(TPageControl, TQtWSPageControl);
//  RegisterWSComponent(TCustomListView, TQtWSCustomListView);
//  RegisterWSComponent(TListView, TQtWSListView);
//  RegisterWSComponent(TProgressBar, TQtWSProgressBar);
//  RegisterWSComponent(TCustomUpDown, TQtWSCustomUpDown);
//  RegisterWSComponent(TUpDown, TQtWSUpDown);
//  RegisterWSComponent(TToolButton, TQtWSToolButton);
//  RegisterWSComponent(TToolBar, TQtWSToolBar);
//  RegisterWSComponent(TToolButton, TQtWSToolButton);
//  RegisterWSComponent(TToolBar, TQtWSToolBar);
//  RegisterWSComponent(TTrackBar, TQtWSTrackBar);
//  RegisterWSComponent(TCustomTreeView, TQtWSCustomTreeView);
//  RegisterWSComponent(TTreeView, TQtWSTreeView);
////////////////////////////////////////////////////
end.
