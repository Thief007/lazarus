{ This is an autogenerated unit using gobject introspection (gir2pascal). Do not Edit. }
unit LazJSCore3;

{$MODE OBJFPC}{$H+}

{$PACKRECORDS C}
{$MODESWITCH DUPLICATELOCALS+}

{$LINKLIB webkitgtk-3.0}
interface
uses
  CTypes;

const
  JSCore3_library = 'webkitgtk-3.0';

type

  { JSGlobalContextRef }
  TJSGlobalContextRef = record
    { opaque type }
    Unknown: Pointer;
  end;


  { JSObjectRef }
  TJSObjectRef = record
    { opaque type }
    Unknown: Pointer;
  end;


procedure JSEvaluateScript; cdecl; external;
implementation
end.