{ $Id$}
{
 *****************************************************************************
 *                              wsreferences.pp                              *
 *                              ---------------                              *
 *                                                                           *
 *                                                                           *
 *****************************************************************************

 *****************************************************************************
 *                                                                           *
 *  This file is part of the Lazarus Component Library (LCL)                 *
 *                                                                           *
 *  See the file COPYING.modifiedLGPL, included in this distribution,        *
 *  for details about the copyright.                                         *
 *                                                                           *
 *  This program is distributed in the hope that it will be useful,          *
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of           *
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.                     *
 *                                                                           *
 *****************************************************************************
}
unit WSReferences;

{$mode objfpc}{$H+}

interface

//uses
//  Types;


type
  { TWSReference }
  {
    Abstract (temporary) base object for all references to WS classes.
    This reference replaces the functionality of a Handle.
    An object is choosen to disallow assignments of different types of handles
  }
  PWSReference = ^TWSReference;
  TWSReference = object
  private
    function GetAllocated: Boolean; inline;
  protected
    FRef: record
      case Byte of
        0: (Ptr: Pointer);
        1: (Handle: THandle);
    end;
  public
    // NOTE: These _Methods are temporary and for widgetset use only.
    //       They can be removed anytime, without notice
    procedure _Clear;
    procedure _Init(APtr: Pointer);
    procedure _Init(AHandle: THandle);
    property  _Handle: THandle read FRef.Handle;
    //----
    
    property Allocated: Boolean read GetAllocated;
    property Ptr: Pointer read FRef.Ptr;
  end;

  // NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
  // NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
  // NOTE NOTE NOTE NOTE NOTE NOTE NOTE NOTE
  //
  // All properties with _ are temporary and for lcl use only.
  // They can be removed anytime, without notice
  //
  // (don't complain that I didn't warn you)

  TWSCustomImageListReference = object(TWSReference)
  public
    property Handle: THandle read FRef.Handle;
  end;
  
  TWSGDIObjReference = object(TWSReference)
  end;
  
  TWSBitmapReference = object(TWSGDIObjReference)
    property Handle: THandle read FRef.Handle;
  end;

  TWSBrushReference = object(TWSGDIObjReference)
    property Handle: THandle read FRef.Handle;
  end;

  TWSPenReference = object(TWSGDIObjReference)
    property Handle: THandle read FRef.Handle;
  end;

  TWSFontReference = object(TWSGDIObjReference)
    property Handle: THandle read FRef.Handle;
  end;

  TWSRegionReference = object(TWSGDIObjReference)
    property _lclHandle: THandle write FRef.Handle;
    property Handle: THandle read FRef.Handle;
  end;
  
  TWSDeviceContextReference = object(TWSReference)
    property Handle: THandle read FRef.Handle;
  end;



implementation

{ TWSReference }

procedure TWSReference._Clear;
begin
  FRef.Ptr := nil;
end;

procedure TWSReference._Init(APtr: Pointer);
begin
  FRef.Ptr := APtr;
end;

procedure TWSReference._Init(AHandle: THandle);
begin
  FRef.Handle := AHandle;
end;

function TWSReference.GetAllocated: Boolean;
begin
  Result := FRef.Ptr <> nil;
end;


end.

