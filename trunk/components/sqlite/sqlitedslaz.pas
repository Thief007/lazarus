{ This file was automatically created by Lazarus. Do not edit!
This source is only used to compile and install the package.
 }

unit sqlitedslaz; 

interface

uses
  sqliteds, tableeditorform, LazarusPackageIntf; 

implementation

procedure Register; 
begin
  RegisterUnit('tableeditorform', @tableeditorform.Register); 
end; 

initialization
  RegisterPackage('sqlitedslaz', @Register); 
end.
