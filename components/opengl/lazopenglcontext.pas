{ This file was automatically created by Lazarus. Do not edit!
  This source is only used to compile and install the package.
 }

unit lazopenglcontext; 

interface

uses
  OpenGLContext, GLQTContext, LazarusPackageIntf;

implementation

procedure Register; 
begin
  RegisterUnit('OpenGLContext', @OpenGLContext.Register); 
end; 

initialization
  RegisterPackage('LazOpenGLContext', @Register); 
end.
