unit FpDbgLinuxExtra;

{$mode objfpc}{$H+}

interface

uses
  Classes,
  BaseUnix,
  SysUtils;

const
  PTRACE_TRACEME                               = 0;
  PTRACE_PEEKTEXT                              = 1;
  PTRACE_PEEKDATA                              = 2;
  PTRACE_PEEKUSR                               = 3;
  PTRACE_POKETEXT                              = 4;
  PTRACE_POKEDATA                              = 5;
  PTRACE_POKEUSR                               = 6;
  PTRACE_CONT                                  = 7;
  PTRACE_KILL                                  = 8;
  PTRACE_SINGLESTEP                            = 9;
{$ifdef linux}
  PTRACE_GETREGS                               = 12;
  PTRACE_SETREGS                               = 13;
  PTRACE_GETFPREGS                             = 14;
  PTRACE_SETFPREGS                             = 15;
{$endif linux}
  PTRACE_ATTACH                                = 16;

  RIP                                          = 16;

function fpPTrace(ptrace_request: cint; pid: TPid; addr: Pointer; data: pointer): PtrInt;

implementation

type
  TSysResult = int64;   // all platforms, cint=32-bit.
                        // On platforms with off_t =64-bit, people should
                        // use int64, and typecast all calls that don't
                        // return off_t to cint.
  TSysParam  = int64;

{$ifdef darwin}
Function ptrace(ptrace_request: cInt; pid: TPid; addr:pointer; data:pointer): cint; cdecl; external clib name 'ptrace';
{$endif darwin}
{$ifdef linux}
function Do_SysCall(sysnr,param1,param2,param3,param4:TSysParam):TSysResult; external name 'FPC_SYSCALL4';

const
  syscall_nr_ptrace                            = 101;
{$endif linux}

function fpPTrace(ptrace_request: cint; pid: TPid; addr: Pointer; data: pointer): PtrInt;
{$ifdef linux}
var
  res : TSysResult;
  ret : PtrInt;
{$endif linux}
begin
{$ifdef darwin}
  result := ptrace(ptrace_request, pid, addr, data);
{$endif}
{$ifdef linux}
  if (ptrace_request > 0) and (ptrace_request < 4) then
    data := @ret;

  res := do_syscall(TSysParam(syscall_nr_ptrace), TSysParam(ptrace_request), TSysParam(pid), TSysParam(addr), TSysParam(data));
  if (res >= 0) and (ptrace_request > 0) and (ptrace_request < 4) then
    begin
    errno:=0;
    result := ret;
    end
  else
    result := res;
{$endif linux}
end;

end.

