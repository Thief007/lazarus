{
 /***************************************************************************
                                  forms.pp
                             -------------------
                             Component Library Code

                             Implements:
                             TForm
                             TApplication

                   Initial Revision  : Sun Mar 28 23:15:32 CST 1999
                   Revised : Sat Jul 15 1999

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



unit Forms;

{$mode objfpc}

interface

{$ifdef Trace}
{$ASSERTIONS ON}
{$endif}

uses classes, controls, vclglobals, sysutils,graphics,Menus, LCLLinux,LMessages;

type
  TFormStyle = (fsNormal, fsMDIChild, fsMDIFORM, fsStayOnTop);
  TFormBorderStyle = (bsNone, bsSingle, bsSizeable, bsDialog, bsToolWindow, bsSizeToolWin);
  TBorderStyle = bsNone..bsSingle;

  TPosition = (poDesigned, poDefault, poDefaultPosOnly, poDefaultSizeOnly, poScreenCenter, poDesktopCenter, poMainFormCenter, poOwnerFormCenter);

  TWindowState = (wsNormal, wsMinimized, wsMaximized);
  TCloseAction = (caNone, caHide, caFree, caMinimize);

  TControlScrollBar = class(TPersistent)
  end;

  TScrollingWinControl = class(TWinControl)
  private
    FHorzScrollBar : TControlScrollBar;
    FVertScrollBar : TControlScrollBar;
    FAutoScroll    : Boolean;
  end;

  TDesigner = class;

    
  TCloseEvent = procedure(Sender: TObject; var Action: TCloseAction) of object;
  TCloseQueryEvent = procedure(Sender : TObject; var CanClose : boolean) of object;
  TFormState = set of (fsCreating, fsVisible, fsShowing, fsModal, fsCreatedMDIChild);
  TModalResult = low(Integer)..high(Integer);

  TCustomForm = class(TWinControl)
  private
    FActive : Boolean;
    FActiveControl : TWinControl;
    FBorderStyle : TFormBorderStyle;
    FCanvas : TControlCanvas;
    FDesigner : TDesigner;
    FFormStyle : TFormStyle;
    FKeyPreview: Boolean;
    FMenu : TMainMenu;
    FModalResult : TModalResult;
    FOnCreate: TNotifyEvent;
    FOnDestroy: TNotifyEvent;
    FOnHide: TNotifyEvent;
    FOnShow: TNotifyEvent;
    FOnPaint: TNotifyEvent;
    FOnClose: TCloseEvent;
    FOnCloseQuery : TCloseQueryEvent;
    FPosition : TPosition;
    FWindowState : TWindowState;
    Procedure ClientWndProc(var Message: TLMessage);
    procedure DoCreate;
    procedure DoDestroy;
    Procedure SetActiveControl(Value : TWinControl);
    Procedure SetBorderStyle(value : TFORMBorderStyle);
    Procedure SetDesigner(Value : TDesigner);
    Procedure SetMenu(value : TMainMenu);
    Procedure SetFormStyle(Value : TFormStyle);
    Procedure SetPosition(value : TPosition); 
    Procedure SetWindowState(Value : TWIndowState);
    Function GetCanvas: TControlCanvas;
    Function IsForm : Boolean;
    { events }
    procedure WMPaint(var message: TLMPaint); message LM_PAINT;
    procedure WMSize(var message: TLMSize); message LM_Size;
    procedure WMShowWindow(var message: TLMShowWindow); message LM_SHOWWINDOW;
    procedure WMCloseQuery(var message: TLMessage); message LM_CLOSEQUERY;
    procedure WMDestroy(var message: TLMDestroy); message LM_DESTROY;
  protected
    FFormState: TFormState;
    procedure AttachSignals; override;
    function CloseQuery : boolean; virtual;
    procedure CreateParams(var Params: TCreateParams); override;
    procedure CreateWnd; override;
    procedure DoClose(var Action: TCloseAction); dynamic;
    procedure DoHide; dynamic;
    procedure DoShow; dynamic;
    Function GetClientRect : TRect ; Override;
    Procedure Notification(AComponent: TComponent; Operation : TOperation);override;
    procedure Paint; dynamic;
    Procedure RequestAlign; Override;
    procedure UpdateShowing; override;
    procedure UpdateWindowState;
    procedure ValidateRename(AComponent: TComponent; const CurName, NewName: string);
    procedure WndProc(var Message : TLMessage); override;
    property ActiveControl : TWinControl read FActiveControl write SetActiveControl;
    property FormStyle : TFormStyle read FFormStyle write SetFormStyle default fsNormal;
    property Position : TPosition read FPosition write SetPosition default poDesigned;
    {events}
    property OnCreate: TNotifyEvent read FOnCreate write FOnCreate;
    property OnDestroy: TNotifyEvent read FOnDestroy write FOnDestroy;
    property OnHide: TNotifyEvent read FOnHide write FOnHide;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
    property OnClose: TCloseEvent read FOnClose write FOnClose stored IsForm;
    property OnCloseQuery : TCloseQueryEvent read FOnCloseQuery write FOnCloseQuery stored IsForm;
  public
    constructor Create(AOwner: TComponent); override;
    constructor CreateNew(AOwner: TComponent; Num : Integer); virtual;
    procedure BeforeDestruction; override;
    destructor Destroy; override;
    procedure Close;
    procedure Hide;
    function WantChildKey(Child : TControl; var MEssage : TLMessage): Boolean; virtual;
    Procedure SetFocus; override;
    function SetFocusedControl(Control : TWinControl): Boolean ; Virtual;
    Function  ShowModal : Integer;
    property Active : Boolean read FActive;
    property BorderStyle : TFormBorderStyle read FBorderStyle write SetBorderStyle default bsSizeable;
    property Canvas: TControlCanvas read GetCanvas;
    property Caption stored IsForm;
    property Designer : TDesigner read FDesigner write SetDesigner;
    property FormState : TFormState read FFormState;
    property KeyPreview: Boolean read FKeyPreview write FKeyPreview;
    property Menu : TMainMenu read FMenu write SetMenu;
    property ModalResult : TModalResult read FModalResult write FModalResult;
    property WindowState: TWindowState read FWindowState write SetWIndowState default wsNormal;
  end;

  TForm = class(TCustomForm)
   private
      FClientHandle: HWND;
   public
      constructor Create(AOwner: TComponent); override;
      destructor destroy; override;
      property ClientHandle: HWND read FClientHandle;
   published
      property ActiveCOntrol;
      property FormStyle;
      property Position;
   end;

  TFormClass = class of TForm;

  TScreen = class(TComponent)
  private
    FFormList: TList;
    FPixelsPerInch : integer;
    Function GetFormCount: Integer;
    Function GetForms(IIndex: Integer): TForm;
    function GetHeight : Integer;
    function GetWidth : Integer;
    procedure AddForm(FForm: TCustomForm);
    procedure RemoveForm(FForm: TCustomForm);
  public
    constructor Create(AOwner : TComponent); override;
    Destructor Destroy; Override;
    property FormCount: Integer read GetFormCount;
    property Forms[Index: Integer]: TForm read GetForms;
    property PixelsPerInch : integer read FPixelsPerInch;
    property Height : Integer read Getheight;
    property Width : Integer read GetWidth;
  end;

  TIdleEvent = procedure (Sender: TObject; var Done: Boolean) of object;

  TApplication = class(TComponent)
   private
      FHandle : THandle;
      FTerminate : Boolean;
      FMainForm : TForm;
      FList: TList;
      FMouseControl: TControl;
      FOnIdle: TIdleEvent;
      // MWE:Do we need this ??
      // function ProcessMessage(Var Msg : TMsg) : Boolean;
      procedure wndproc(var Message : TLMessage);
 //the following is used for Messagebox button clicks.  Temporary until I figure out a better way.
      procedure DefaultOnClick(Sender : TObject);
 //----      
      function GetExename: String;
      procedure MouseIdle(const CurrentControl: TControl);
      procedure Idle;
   public
      constructor Create(AOwner: TComponent); override;
      destructor Destroy; override;
      Procedure BringToFront;
      procedure CreateForm(NewForm : TFormClass; var ref);
      procedure HandleMessage;
      procedure HintMouseMEssage(Control : TControl; var Message: TLMessage);
      procedure Initialize;
      function MessageBox(Text, Caption : PChar; Flags : Longint) : Integer;
      procedure Notification(AComponent : TComponent; Operation : TOperation); override;
      Procedure ProcessMessages;
      procedure Run;
      procedure Terminate;
      property Exename: String read GetExeName;
      property Handle: THandle read FHandle;
      property Terminated: Boolean read FTerminate;
      property MainForm: TForm read FMainForm;
      property OnIdle: TIdleEvent read FOnIdle write FOnIdle;
   end;

  TDesigner = class(TObject)
  private
    FCustomForm: TCustomForm;
    function GetIsControl: Boolean;
    procedure SetIsControl(Value: Boolean);
  public
    function IsDesignMsg(Sender: TControl; var Message: TLMessage): Boolean;
      virtual; abstract;
    procedure Modified; virtual; abstract;
    procedure Notification(AComponent: TComponent;
      Operation: TOperation); virtual; abstract;
    procedure PaintGrid; virtual; abstract;
    procedure ValidateRename(AComponent: TComponent;
      const CurName, NewName: string); virtual; abstract;
    property IsControl: Boolean read GetIsControl write SetIsControl;
    property Form: TCustomForm read FCustomForm write FCustomForm;
  end;




  TProcedure = procedure;



function KeysToShiftState(Keys:Word): TShiftState;
function KeyDataToShiftState(KeyData: Longint): TShiftState;
function GetParentForm(Control:TControl): TCustomForm;
function IsAccel(VK : Word; const Str : String): Boolean;

var
  Application : TApplication;
  Screen : TScreen;



implementation


uses 
  buttons,stdctrls,interfaces;

var
  FocusMessages : Boolean; //Should set it to TRUE by defualt but fpc does not handle that yet.

function KeysToShiftState(Keys:Word): TShiftState;
begin
  Result := [];
  if Keys and MK_Shift <> 0 then Include(Result,ssShift);
  if Keys and MK_Control <> 0 then Include(Result,ssCtrl);
  if Keys and MK_LButton <> 0 then Include(Result,ssLeft);
  if Keys and MK_RButton <> 0 then Include(Result,ssRight);
  if Keys and MK_MButton <> 0 then Include(Result,ssMiddle);
  if GetKeyState(VK_MENU) < 0 then Include(Result, ssAlt);
end;

function KeyDataToShiftState(KeyData: Longint): TShiftState;
begin
  Result := [];
  if GetKeyState(VK_SHIFT) < 0 then Include(Result, ssShift);
  if GetKeyState(VK_CONTROL) < 0 then Include(Result, ssCtrl);
  if KeyData and $20000000 <> 0 then Include(Result, ssAlt);
end;

function GetParentForm(Control:TControl): TCustomForm;
begin
  while Control.parent <> nil do
    Control := Control.Parent;
  if Control is TCustomForm 
  then Result := TCustomForm(Control) 
  else Result := nil;
end;

function IsAccel(VK : Word; const Str : String): Boolean;
begin
  Result := true;
end;

{$I form.inc}
{$I Customform.inc}
{$I screen.inc}
{$I application.inc}
{$I designer.inc}
initialization
  Screen:= TScreen.Create(nil);
  Application:= TApplication.Create(nil);

finalization
  Application.Free;
  Application:= nil;
  Screen.Free;
  Screen:= nil;  

end.


