{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit idefilebrowser;

interface

uses
  frmFileBrowser, RegIDEFileBrowser, frmConfigFileBrowser, LazarusPackageIntf;

implementation

procedure Register;
begin
  RegisterUnit('RegIDEFileBrowser', @RegIDEFileBrowser.Register);
end;

initialization
  RegisterPackage('idefilebrowser', @Register);
end.
