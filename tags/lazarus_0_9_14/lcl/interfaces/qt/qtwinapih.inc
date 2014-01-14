{%MainUnit qtint.pas}

{******************************************************************************
  All QT Winapi related stuff goes here.
  This are the overrides of the QT Interface for the methods defined in the
  lcl/include/winapih.inc

  !! Keep this alphabetical !!

 ******************************************************************************
 Interface
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

//##apiwiz##sps##   // Do not remove, no wizard declaration before this line

function BeginPaint(Handle: hWnd; Var PS : TPaintStruct) : hdc; override;

function CreateBitmapFromRawImage(const RawImage: TRawImage; var Bitmap, MaskBitmap: HBitmap; AlwaysCreateMask: boolean): boolean; override;
function CreateCompatibleDC(DC: HDC): HDC; override;

function DrawText(DC: HDC; Str: PChar; Count: Integer; var Rect: TRect; Flags: Cardinal): Integer; override;

function EndPaint(Handle: hwnd; var PS: TPaintStruct): Integer; override;
function ExtTextOut(DC: HDC; X, Y: Integer; Options: Longint; Rect: PRect; Str: PChar; Count: Longint; Dx: PInteger): Boolean; override;

function GetBitmapRawImageDescription(Bitmap: HBITMAP; Desc: PRawImageDescription): Boolean; override;
function GetClientBounds(handle : HWND; var ARect : TRect) : Boolean; override;
function GetClientRect(handle : HWND; var ARect : TRect) : Boolean; override;
function GetCursorPos(var lpPoint: TPoint ): Boolean; override;
function GetDeviceRawImageDescription(DC: HDC; Desc: PRawImageDescription): boolean; override;
function GetDC(hWnd: HWND): HDC; override;
function GetRawImageFromDevice(SrcDC: HDC; const SrcRect: TRect; var NewRawImage: TRawImage): boolean; override;
function GetRawImageFromBitmap(SrcBitmap, SrcMaskBitmap: HBITMAP; const SrcRect: TRect; var NewRawImage: TRawImage): boolean; Override;

function Rectangle(DC: HDC; X1, Y1, X2, Y2: Integer): Boolean; override;
function ReleaseDC(hWnd: HWND; DC: HDC): Integer; override;

function SelectObject(DC: HDC; GDIObj: HGDIOBJ): HGDIOBJ; override;
function SetCursorPos(X, Y: Integer): Boolean; override;
function ShowWindow(hWnd: HWND; nCmdShow: Integer): Boolean; override;
function StretchBlt(DestDC: HDC; X, Y, Width, Height: Integer;
  SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; ROp: Cardinal): Boolean; override;
function StretchMaskBlt(DestDC: HDC; X, Y, Width, Height: Integer;
  SrcDC: HDC; XSrc, YSrc, SrcWidth, SrcHeight: Integer; Mask: HBITMAP;
  XMask, YMask: Integer; Rop: DWORD): Boolean; override;

function TextOut(DC: HDC; X,Y : Integer; Str : Pchar; Count: Integer) : Boolean; override;

//##apiwiz##eps##   // Do not remove, no wizard declaration after this line

