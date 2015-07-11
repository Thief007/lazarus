
unit uPSR_std;
{$I PascalScript.inc}
interface
uses
  uPSRuntime, uPSUtils;


procedure RIRegisterTObject(CL: TPSRuntimeClassImporter);
procedure RIRegisterTPersistent(Cl: TPSRuntimeClassImporter);
procedure RIRegisterTComponent(Cl: TPSRuntimeClassImporter);
procedure RIRegister_Std(Cl: TPSRuntimeClassImporter);

implementation
uses
  Classes;



procedure RIRegisterTObject(CL: TPSRuntimeClassImporter); 
begin
  with cl.Add(TObject) do
  begin
    RegisterConstructor(@TObject.Create, 'CREATE');
    RegisterMethod(@TObject.Free, 'FREE');
  end;
end;

procedure RIRegisterTPersistent(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TPersistent) do
  begin
    RegisterVirtualMethod(@TPersistent.Assign, 'ASSIGN');
  end;
end;

procedure TComponentOwnerR(Self: TComponent; var T: TComponent); begin T := Self.Owner; end;


procedure TCOMPONENTCOMPONENTS_R(Self: TCOMPONENT; var T: TCOMPONENT; t1: INTEGER); begin T := Self.COMPONENTS[t1]; end;
procedure TCOMPONENTCOMPONENTCOUNT_R(Self: TCOMPONENT; var T: INTEGER); begin t := Self.COMPONENTCOUNT; end;
procedure TCOMPONENTCOMPONENTINDEX_R(Self: TCOMPONENT; var T: INTEGER); begin t := Self.COMPONENTINDEX; end;
procedure TCOMPONENTCOMPONENTINDEX_W(Self: TCOMPONENT; T: INTEGER); begin Self.COMPONENTINDEX := t; end;
procedure TCOMPONENTCOMPONENTSTATE_R(Self: TCOMPONENT; var T: TCOMPONENTSTATE); begin t := Self.COMPONENTSTATE; end;
procedure TCOMPONENTDESIGNINFO_R(Self: TCOMPONENT; var T: LONGINT); begin t := Self.DESIGNINFO; end;
procedure TCOMPONENTDESIGNINFO_W(Self: TCOMPONENT; T: LONGINT); begin Self.DESIGNINFO := t; end;


procedure RIRegisterTComponent(Cl: TPSRuntimeClassImporter);
begin
  with Cl.Add(TComponent) do
  begin
    RegisterMethod(@TComponent.FindComponent, 'FINDCOMPONENT');
    RegisterVirtualConstructor(@TComponent.Create, 'CREATE');
    RegisterPropertyHelper(@TComponentOwnerR, nil, 'OWNER');

    RegisterMethod(@TCOMPONENT.DESTROYCOMPONENTS, 'DESTROYCOMPONENTS');
    RegisterPropertyHelper(@TCOMPONENTCOMPONENTS_R, nil, 'COMPONENTS');
    RegisterPropertyHelper(@TCOMPONENTCOMPONENTCOUNT_R, nil, 'COMPONENTCOUNT');
    RegisterPropertyHelper(@TCOMPONENTCOMPONENTINDEX_R, @TCOMPONENTCOMPONENTINDEX_W, 'COMPONENTINDEX');
    RegisterPropertyHelper(@TCOMPONENTCOMPONENTSTATE_R, nil, 'COMPONENTSTATE');
    RegisterPropertyHelper(@TCOMPONENTDESIGNINFO_R, @TCOMPONENTDESIGNINFO_W, 'DESIGNINFO');
  end;
end;







procedure RIRegister_Std(Cl: TPSRuntimeClassImporter);
begin
  RIRegisterTObject(CL);
  RIRegisterTPersistent(Cl);
  RIRegisterTComponent(Cl);
end;
// PS_MINIVCL changes by Martijn Laan (mlaan at wintax _dot_ nl)

end.





