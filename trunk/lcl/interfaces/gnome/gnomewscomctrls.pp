{ $Id$}
{
 *****************************************************************************
 *                            gnomewscomctrls.pp                             * 
 *                            ------------------                             * 
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
unit gnomewscomctrls;

{$mode objfpc}{H+}

interface

uses
////////////////////////////////////////////////////
// I M P O R T A N T                                
////////////////////////////////////////////////////
// To get as litle as posible circles,
// Uncomment only when needed for registration
////////////////////////////////////////////////////
//  comctrls,
////////////////////////////////////////////////////
  wscomctrls, wslclclasses;

type

  { TGnomeWSStatusBar }

  TGnomeWSStatusBar = class(TWSStatusBar)
  private
  protected
  public
  end;

  { TGnomeWSTabSheet }

  TGnomeWSTabSheet = class(TWSTabSheet)
  private
  protected
  public
  end;

  { TGnomeWSPageControl }

  TGnomeWSPageControl = class(TWSPageControl)
  private
  protected
  public
  end;

  { TGnomeWSCustomListView }

  TGnomeWSCustomListView = class(TWSCustomListView)
  private
  protected
  public
  end;

  { TGnomeWSListView }

  TGnomeWSListView = class(TWSListView)
  private
  protected
  public
  end;

  { TGnomeWSProgressBar }

  TGnomeWSProgressBar = class(TWSProgressBar)
  private
  protected
  public
  end;

  { TGnomeWSCustomUpDown }

  TGnomeWSCustomUpDown = class(TWSCustomUpDown)
  private
  protected
  public
  end;

  { TGnomeWSUpDown }

  TGnomeWSUpDown = class(TWSUpDown)
  private
  protected
  public
  end;

  { TGnomeWSToolButton }

  TGnomeWSToolButton = class(TWSToolButton)
  private
  protected
  public
  end;

  { TGnomeWSToolBar }

  TGnomeWSToolBar = class(TWSToolBar)
  private
  protected
  public
  end;

  { TGnomeWSToolButton }

  TGnomeWSToolButton = class(TWSToolButton)
  private
  protected
  public
  end;

  { TGnomeWSToolBar }

  TGnomeWSToolBar = class(TWSToolBar)
  private
  protected
  public
  end;

  { TGnomeWSTrackBar }

  TGnomeWSTrackBar = class(TWSTrackBar)
  private
  protected
  public
  end;

  { TGnomeWSCustomTreeView }

  TGnomeWSCustomTreeView = class(TWSCustomTreeView)
  private
  protected
  public
  end;

  { TGnomeWSTreeView }

  TGnomeWSTreeView = class(TWSTreeView)
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
//  RegisterWSComponent(TStatusBar, TGnomeWSStatusBar);
//  RegisterWSComponent(TTabSheet, TGnomeWSTabSheet);
//  RegisterWSComponent(TPageControl, TGnomeWSPageControl);
//  RegisterWSComponent(TCustomListView, TGnomeWSCustomListView);
//  RegisterWSComponent(TListView, TGnomeWSListView);
//  RegisterWSComponent(TProgressBar, TGnomeWSProgressBar);
//  RegisterWSComponent(TCustomUpDown, TGnomeWSCustomUpDown);
//  RegisterWSComponent(TUpDown, TGnomeWSUpDown);
//  RegisterWSComponent(TToolButton, TGnomeWSToolButton);
//  RegisterWSComponent(TToolBar, TGnomeWSToolBar);
//  RegisterWSComponent(TToolButton, TGnomeWSToolButton);
//  RegisterWSComponent(TToolBar, TGnomeWSToolBar);
//  RegisterWSComponent(TTrackBar, TGnomeWSTrackBar);
//  RegisterWSComponent(TCustomTreeView, TGnomeWSCustomTreeView);
//  RegisterWSComponent(TTreeView, TGnomeWSTreeView);
////////////////////////////////////////////////////
end.
