{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit TrayIconLaz; 

interface

uses
  TrayIcon, wstrayicon, LazarusPackageIntf; 

implementation

procedure Register; 
begin
end; 

initialization
  RegisterPackage('TrayIconLaz', @Register); 
end.
