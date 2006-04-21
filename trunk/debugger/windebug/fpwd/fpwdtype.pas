{ $Id $ }
{
 ---------------------------------------------------------------------------
 fpwdtype.pas  -  FP standalone windows debugger - Type definitions
 ---------------------------------------------------------------------------

 This unit contains types/consts not yet part of the RTL.
 It also contains some experimental types for mixing win32 and win64

 ---------------------------------------------------------------------------

 @created(Mon Apr 10th WET 2006)
 @lastmod($Date$)
 @author(Marc Weustink <marc@@dommelstein.nl>)

 ***************************************************************************
 *                                                                         *
 *   This source is free software; you can redistribute it and/or modify   *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This code is distributed in the hope that it will be useful, but      *
 *   WITHOUT ANY WARRANTY; without even the implied warranty of            *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU     *
 *   General Public License for more details.                              *
 *                                                                         *
 *   A copy of the GNU General Public License is available on the World    *
 *   Wide Web at <http://www.gnu.org/copyleft/gpl.html>. You can also      *
 *   obtain it by writing to the Free Software Foundation,                 *
 *   Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.        *
 *                                                                         *
 ***************************************************************************
}
unit FPWDType;

{$mode objfpc}{$H+}
{$ALIGN ON}

// Additional 64bit types

interface

uses
  Windows;

//type
//  DWORD64 = QWORD;
//  ULONGLONG = QWORD;
//  LONGLONG = int64;
  //QWORD = type cardinal;

const
  THREAD_TERMINATE               = $0001;
  THREAD_SUSPEND_RESUME          = $0002;
  THREAD_GET_CONTEXT             = $0008;
  THREAD_SET_CONTEXT             = $0010;
  THREAD_SET_INFORMATION         = $0020;
  THREAD_QUERY_INFORMATION       = $0040;
  THREAD_SET_THREAD_TOKEN        = $0080;
  THREAD_IMPERSONATE             = $0100;
  THREAD_DIRECT_IMPERSONATION    = $0200;

  THREAD_ALL_ACCESS              = STANDARD_RIGHTS_REQUIRED or SYNCHRONIZE or $3FF;


type
  PExceptionRecord64 = QWORD;
//  PExceptionRecord64 = ^_EXCEPTION_RECORD64;
  _EXCEPTION_RECORD64 = record
    ExceptionCode: DWORD;
    ExceptionFlags: DWORD;
    ExceptionRecord: PExceptionRecord64;
    ExceptionAddress: QWORD;
    NumberParameters: DWORD;
    __unusedAlignment: DWORD;
    ExceptionInformation: array[0..EXCEPTION_MAXIMUM_PARAMETERS - 1] of QWORD;
  end;
  TExceptionRecord64 = _EXCEPTION_RECORD64;
  EXCEPTION_RECORD64 = _EXCEPTION_RECORD64;

(*
  PContext64 = QWORD;
  PExceptionPointers64 = QWORD;
  _EXCEPTION_POINTERS64 = record
    ExceptionRecord : PExceptionRecord64;
    ContextRecord : PContext64;
  end;
  TExceptionPointers64 = _EXCEPTION_POINTERS64;
  EXCEPTION_POINTERS64 = _EXCEPTION_POINTERS64;
*)
//  PExceptionDebugInfo64 = QWORD;
  PExceptionDebugInfo64 = ^_EXCEPTION_DEBUG_INFO64;
  _EXCEPTION_DEBUG_INFO64 = record
    ExceptionRecord: TExceptionRecord64;
    dwFirstChance: DWORD;
  end;
  TExceptionDebugInfo64 = _EXCEPTION_DEBUG_INFO64;
  EXCEPTION_DEBUG_INFO64 = _EXCEPTION_DEBUG_INFO64;
(*
  PCreateThreadDebugInfo64 = QWORD;
  _CREATE_THREAD_DEBUG_INFO64 = record
    hThread: QWORD;
    lpThreadLocalBase: QWORD;
    lpStartAddress: QWORD;
  end;
  TCreateThreadDebugInfo = _CREATE_THREAD_DEBUG_INFO;
  CREATE_THREAD_DEBUG_INFO = _CREATE_THREAD_DEBUG_INFO;

  PCreateProcessDebugInfo = QWORD;
  _CREATE_PROCESS_DEBUG_INFO = record
    hFile: THandle;
    hProcess: THandle;
    hThread: THandle;
    lpBaseOfImage: Pointer;
    dwDebugInfoFileOffset: DWORD;
    nDebugInfoSize: DWORD;
    lpThreadLocalBase: Pointer;
    lpStartAddress: TFNThreadStartRoutine;
    lpImageName: Pointer;
    fUnicode: Word;
  end;
  TCreateProcessDebugInfo = _CREATE_PROCESS_DEBUG_INFO;
  CREATE_PROCESS_DEBUG_INFO = _CREATE_PROCESS_DEBUG_INFO;

  PExitThreadDebugInfo64 = QWORD;
  PExitProcessDebugInfo64 = QWORD;

  PLoadDLLDebugInfo64 = QWORD;
  _LOAD_DLL_DEBUG_INFO64 = record
    hFile: QWORD;
    lpBaseOfDll: QWORD;
    dwDebugInfoFileOffset: DWORD;
    nDebugInfoSize: DWORD;
    lpImageName: Pointer;
    fUnicode: Word;
  end;
  {$EXTERNALSYM _LOAD_DLL_DEBUG_INFO}
  TLoadDLLDebugInfo = _LOAD_DLL_DEBUG_INFO;
  LOAD_DLL_DEBUG_INFO = _LOAD_DLL_DEBUG_INFO;
  {$EXTERNALSYM LOAD_DLL_DEBUG_INFO}

  PUnloadDLLDebugInfo = ^TUnloadDLLDebugInfo;
  _UNLOAD_DLL_DEBUG_INFO = record
    lpBaseOfDll: Pointer;
  end;
  {$EXTERNALSYM _UNLOAD_DLL_DEBUG_INFO}
  TUnloadDLLDebugInfo = _UNLOAD_DLL_DEBUG_INFO;
  UNLOAD_DLL_DEBUG_INFO = _UNLOAD_DLL_DEBUG_INFO;
  {$EXTERNALSYM UNLOAD_DLL_DEBUG_INFO}

  POutputDebugStringInfo = ^TOutputDebugStringInfo;
  _OUTPUT_DEBUG_STRING_INFO = record
    lpDebugStringData: LPSTR;
    fUnicode: Word;
    nDebugStringLength: Word;
  end;
  {$EXTERNALSYM _OUTPUT_DEBUG_STRING_INFO}
  TOutputDebugStringInfo = _OUTPUT_DEBUG_STRING_INFO;
  OUTPUT_DEBUG_STRING_INFO = _OUTPUT_DEBUG_STRING_INFO;
  {$EXTERNALSYM OUTPUT_DEBUG_STRING_INFO}

  PRIPInfo64 = QWORD;
*)

(*
  PDebugEvent64 = ^TDebugEvent64;
  _DEBUG_EVENT64 = record
    dwDebugEventCode: DWORD;
    dwProcessId: DWORD;
    dwThreadId: DWORD;
    case Integer of
      0: (Exception: TExceptionDebugInfo);
      1: (CreateThread: TCreateThreadDebugInfo);
      2: (CreateProcessInfo: TCreateProcessDebugInfo);
      3: (ExitThread: TExitThreadDebugInfo);
      4: (ExitProcess: TExitProcessDebugInfo);
      5: (LoadDll: TLoadDLLDebugInfo);
      6: (UnloadDll: TUnloadDLLDebugInfo);
      7: (DebugString: TOutputDebugStringInfo);
      8: (RipInfo: TRIPInfo);
      9: (Exception64: TExceptionDebugInfo64);
  end;
  TDebugEvent64 = _DEBUG_EVENT64;
  DEBUG_EVENT64 = _DEBUG_EVENT64;
*)
const
  CONTEXT_AMD64 =  $100000;

// MWE: added _AMD64 postfix to distinguish between i386 and amd64

  CONTEXT_CONTROL_AMD64         = (CONTEXT_AMD64 or $00000001);
  CONTEXT_INTEGER_AMD64         = (CONTEXT_AMD64 or $00000002);
  CONTEXT_SEGMENTS_AMD64        = (CONTEXT_AMD64 or $00000004);
  CONTEXT_FLOATING_POINT_AMD64  = (CONTEXT_AMD64 or $00000008);
  CONTEXT_DEBUG_REGISTERS_AMD64 = (CONTEXT_AMD64 or $00000010);

  CONTEXT_FULL_AMD64            = (CONTEXT_CONTROL_AMD64 or CONTEXT_INTEGER_AMD64 or CONTEXT_FLOATING_POINT_AMD64);
  CONTEXT_ALL_AMD64             = (CONTEXT_CONTROL_AMD64 or CONTEXT_INTEGER_AMD64 or CONTEXT_SEGMENTS_AMD64 or CONTEXT_FLOATING_POINT_AMD64 or CONTEXT_DEBUG_REGISTERS_AMD64);

  CONTEXT_EXCEPTION_ACTIVE_AMD64    = $08000000;
  CONTEXT_SERVICE_ACTIVE_AMD64      = $10000000;
  CONTEXT_EXCEPTION_REQUEST_AMD64   = $40000000;
  CONTEXT_EXCEPTION_REPORTING_AMD64 = $80000000;



//
// Define initial MxCsr and FpCsr control.
//

//#define INITIAL_MXCSR 0x1f80            // initial MXCSR value
//#define INITIAL_FPCSR 0x027f            // initial FPCSR value

//
// Define 128-bit 16-byte aligned xmm register type.
//

//typedef struct DECLSPEC_ALIGN(16) _M128A {
type
  _M128A = record
    Low: ULONGLONG;
    High: LONGLONG;
  end;
  M128A = _M128A;
  TM128A = _M128A;
  PM128A = TM128A;

//
// Format of data for 32-bit fxsave/fxrstor instructions.
//

//typedef struct _XMM_SAVE_AREA32 {
type
  _XMM_SAVE_AREA32 = record
    ControlWord: WORD;
    StatusWord: WORD;
    TagWord: BYTE;
    Reserved1: BYTE;
    ErrorOpcode: WORD;
    ErrorOffset: DWORD;
    ErrorSelector: WORD;
    Reserved2: WORD;
    DataOffset: DWORD;
    DataSelector: WORD;
    Reserved3: WORD;
    MxCsr: DWORD;
    MxCsr_Mask: DWORD;
    FloatRegisters: array[0..7] of M128A;
    XmmRegisters: array[0..16] of M128A;
    Reserved4: array[0..95] of BYTE;
  end;
  XMM_SAVE_AREA32 = _XMM_SAVE_AREA32;
  TXmmSaveArea = XMM_SAVE_AREA32;
  PXmmSaveArea = ^TXmmSaveArea;

const
  LEGACY_SAVE_AREA_LENGTH = sizeof(XMM_SAVE_AREA32);

//
// Context Frame
//
//  This frame has a several purposes: 1) it is used as an argument to
//  NtContinue, 2) is is used to constuct a call frame for APC delivery,
//  and 3) it is used in the user level thread creation routines.
//
//
// The flags field within this record controls the contents of a CONTEXT
// record.
//
// If the context record is used as an input parameter, then for each
// portion of the context record controlled by a flag whose value is
// set, it is assumed that that portion of the context record contains
// valid context. If the context record is being used to modify a threads
// context, then only that portion of the threads context is modified.
//
// If the context record is used as an output parameter to capture the
// context of a thread, then only those portions of the thread's context
// corresponding to set flags will be returned.
//
// CONTEXT_CONTROL specifies SegSs, Rsp, SegCs, Rip, and EFlags.
//
// CONTEXT_INTEGER specifies Rax, Rcx, Rdx, Rbx, Rbp, Rsi, Rdi, and R8-R15.
//
// CONTEXT_SEGMENTS specifies SegDs, SegEs, SegFs, and SegGs.
//
// CONTEXT_DEBUG_REGISTERS specifies Dr0-Dr3 and Dr6-Dr7.
//
// CONTEXT_MMX_REGISTERS specifies the floating point and extended registers
//     Mm0/St0-Mm7/St7 and Xmm0-Xmm15).
//

//typedef struct DECLSPEC_ALIGN(16) _CONTEXT {
type
  _CONTEXTAMD64 = record

    //
    // Register parameter home addresses.
    //
    // N.B. These fields are for convience - they could be used to extend the
    //      context record in the future.
    //

    P1Home: DWORD64;
    P2Home: DWORD64;
    P3Home: DWORD64;
    P4Home: DWORD64;
    P5Home: DWORD64;
    P6Home: DWORD64;

    //
    // Control flags.
    //

    ContextFlags: DWORD;
    MxCsr: DWORD;

    //
    // Segment Registers and processor flags.
    //

    SegCs: WORD;
    SegDs: WORD;
    SegEs: WORD;
    SegFs: WORD;
    SegGs: WORD;
    SegSs: WORD;
    EFlags: DWORD;

    //
    // Debug registers
    //

    Dr0: DWORD64;
    Dr1: DWORD64;
    Dr2: DWORD64;
    Dr3: DWORD64;
    Dr6: DWORD64;
    Dr7: DWORD64;

    //
    // Integer registers.
    //

    Rax: DWORD64;
    Rcx: DWORD64;
    Rdx: DWORD64;
    Rbx: DWORD64;
    Rsp: DWORD64;
    Rbp: DWORD64;
    Rsi: DWORD64;
    Rdi: DWORD64;
    R8: DWORD64;
    R9: DWORD64;
    R10: DWORD64;
    R11: DWORD64;
    R12: DWORD64;
    R13: DWORD64;
    R14: DWORD64;
    R15: DWORD64;

    //
    // Program counter.
    //

    Rip: DWORD64;

    //
    // Floating point state.
    //

    FltSave: XMM_SAVE_AREA32; // MWE: only translated the FltSave part of the union
(*
    union  {
        XMM_SAVE_AREA32 FltSave;
        struct {
            M128A Header[2];
            M128A Legacy[8];
            M128A Xmm0;
            M128A Xmm1;
            M128A Xmm2;
            M128A Xmm3;
            M128A Xmm4;
            M128A Xmm5;
            M128A Xmm6;
            M128A Xmm7;
            M128A Xmm8;
            M128A Xmm9;
            M128A Xmm10;
            M128A Xmm11;
            M128A Xmm12;
            M128A Xmm13;
            M128A Xmm14;
            M128A Xmm15;
        };
    };
*)

    //
    // Vector registers.
    //

    VectorRegister: array[0..25] of M128A;
    VectorControl: DWORD64;

    //
    // Special debug control registers.
    //

    DebugControl: DWORD64;
    LastBranchToRip: DWORD64;
    LastBranchFromRip: DWORD64;
    LastExceptionToRip: DWORD64;
    LastExceptionFromRip: DWORD64;
  end;
  CONTEXTAMD64 = _CONTEXTAMD64;
  TContextAMD64 = _CONTEXTAMD64;
  PContextAMD64 = ^TContextAMD64;

implementation

end.
