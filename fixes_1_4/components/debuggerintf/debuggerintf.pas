{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit DebuggerIntf;

interface

uses
  DbgIntfBaseTypes, DbgIntfDebuggerBase, DbgIntfMiscClasses, LazarusPackageIntf;

implementation

procedure Register;
begin
end;

initialization
  RegisterPackage('DebuggerIntf', @Register);
end.
