{******************************************************************************
                                 gtklistslh.inc
                 TGtkListStringList and TGtkCListStringList
                 
 ******************************************************************************

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

type
  TGtkListStringsState = (glsItemCacheNeedsUpdate);
  TGtkListStringsStates = set of TGtkListStringsState;
  
  PPGtkListItem = ^PGtkListItem;

  TGtkListStringList = class(TStrings)
  private
    FGtkList : PGtkList;
    FOwner: TWinControl;
    FSorted : boolean;
    FStates: TGtkListStringsStates;
    FCachedCount: integer;
    FCachedCapacity: integer;
    FCachedItems: PPGtkListItem;
    FUpdateCount: integer;
    FWithCheckBox: Boolean;
  protected
    function GetListItem(Index: integer): PGtkListItem;
    function GetLabel(Index: integer): PGtkLabel;
    function GetCount: integer; override;
    function Get(Index : Integer) : string; override;
    function GetObject(Index: Integer): TObject; override;
    procedure Put(Index: Integer; const S: string); override;
    procedure PutObject(Index: Integer; AnObject: TObject); override;
    procedure SetSorted(Val : boolean); virtual;
    procedure ConnectItemCallbacks(Index: integer);
    procedure ConnectItemCallbacks(Li: PGtkListItem); virtual;
    procedure ConnectAllCallbacks; virtual;
    procedure RemoveItemCallbacks(Index: integer); virtual;
    procedure RemoveAllCallbacks; virtual;
    procedure UpdateItemCache;
    function CacheValid: boolean;
  public
    constructor Create(List : PGtkList; TheOwner: TWinControl;
                       const AWithCheckBox: Boolean);
    destructor Destroy; override;
    function Add(const S: string): Integer; override;
    procedure Assign(Source : TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index : integer); override;
    function IndexOf(const S: string): Integer; override;
    procedure Insert(Index : integer; const S: string); override;
    function GetInsertPosition(const S: string): integer;
    procedure Move(FromIndex, ToIndex: Integer); override;
    procedure Sort; virtual;
    function IsEqual(List: TStrings; CompareObjects: boolean): boolean;
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure ConsistencyCheck;
  public
    property Sorted: boolean read FSorted write SetSorted;
    property Owner: TWinControl read FOwner;
  end;

  TGtkCListStringList = class(TStrings)
  private
    FGtkCList : PGtkCList;
    FSorted : boolean;
  protected
    function Get(Index : Integer) : string; override;
    function GetCount : integer; override;
    function GetObject(Index: Integer): TObject; override;
    procedure PutObject(Index: Integer; AObject: TObject); override;
    procedure SetSorted(Val : boolean); virtual;
  public
    constructor Create(List : PGtkCList);
    procedure Assign(Source : TPersistent); override;
    procedure Clear; override;
    procedure Delete(Index : integer); override;
    procedure Insert(Index : integer; const S: string); override;
    procedure Sort; virtual;
    property Sorted : boolean read FSorted write SetSorted;
  end;

{ =============================================================================

  $Log$
  Revision 1.10  2004/07/03 11:11:08  mattias
  TGTKListStringList now keeps selection on Put and Move

  Revision 1.9  2004/06/27 12:37:18  mattias
  fixed gtk lists sorted

  Revision 1.8  2003/08/28 09:10:00  mattias
  listbox and comboboxes now set sort and selection at handle creation

  Revision 1.7  2003/06/20 01:37:47  marc
  + Added TCheckListBox component

  Revision 1.6  2002/11/17 11:10:04  mattias
  TComboBox and TListBox accelerated and now supports objects

  Revision 1.5  2002/10/04 14:24:15  lazarus
  MG: added DrawItem to TComboBox/TListBox

  Revision 1.4  2002/10/03 14:47:31  lazarus
  MG: added TComboBox.OnPopup+OnCloseUp+ItemWidth

  Revision 1.3  2002/05/10 06:05:57  lazarus
  MG: changed license to LGPL

  Revision 1.2  2001/10/31 10:38:26  lazarus
  MG: fixed sorted customlistbox

  Revision 1.1  2000/07/13 10:28:29  michael
  + Initial import

  Revision 1.1  2000/03/30 22:51:42  lazarus
  MWE:
    Moved from ../../lcl

  Revision 1.3  2000/03/04 00:05:21  lazarus
  MWE: added changes from Hans (HJO)

  Revision 1.2  1999/11/17 01:16:39  lazarus
  MWE:
    Added some more API stuff
    Added an initial TBitmapCanvas
    Added some DC stuff
    Changed and commented out, original gtk linedraw/rectangle code. This
      is now called through the winapi wrapper.

}