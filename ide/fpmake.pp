{
   File generated automatically by Lazarus Package Manager

   fpmake.pp for ide 0.0

   This file was generated on 09/07/12
}

{$ifndef ALLPACKAGES} 
{$mode objfpc}{$H+}
program fpmake;

uses fpmkunit;
{$endif ALLPACKAGES}

procedure add_ide;

var
  P : TPackage;
  T : TTarget;

begin
  with Installer do
    begin
    P:=AddPAckage('ide');
    P.Version:='0.0';

{$ifdef ALLPACKAGES}
    // when this is part of a meta package, set here the sub directory
    P.Directory:='ide';
{$endif ALLPACKAGES}

    P.Dependencies.Add('lcl');
    P.Dependencies.Add('synedit');
    P.Dependencies.Add('codetools');
    P.Dependencies.Add('lazcontrols');
    P.Dependencies.Add('ideintf');
    P.Dependencies.Add('fcl');
    P.Options.Add('-MObjFPC');
    P.Options.Add('-Scghi');
    P.Options.Add('-O1');
    P.Options.Add('-g');
    P.Options.Add('-gl');
    P.Options.Add('-vewnhi');
    P.Options.Add('-l');
    P.Options.Add('-dLCL');
    P.Options.Add('-dLCL$(LCL_PLATFORM)');
    P.IncludePath.Add('include');
    P.IncludePath.Add('include/$(OS)');
    P.Options.Add('-Fuframes');
    P.Options.Add('-Fu../converter');
    P.Options.Add('-Fudebugger');
    P.Options.Add('-Fudebugger/frames');
    P.Options.Add('-Fu../packager');
    //P.Options.Add('-Fu../designer');
    P.Options.Add('-Fudesigner');
    P.Options.Add('-Fu../packager/frames');
    //P.Options.Add('-Fu../ideintf/units/$(CPU_TARGET)-$(OS_TARGET)/$(LCL_PLATFORM)');
    //P.Options.Add('-Fu../components/lazcontrols/lib/$(CPU_TARGET)-$(OS_TARGET)/$(LCL_PLATFORM)');
    //P.Options.Add('-Fu../components/codetools/units/$(CPU_TARGET)-$(OS_TARGET)');
    //P.Options.Add('-Fu../components/synedit/units/$(CPU_TARGET)-$(OS_TARGET)/$(LCL_PLATFORM)');
    //P.Options.Add('-Fu../lcl/units/$(CPU_TARGET)-$(OS_TARGET)/$(LCL_PLATFORM)');
    //P.Options.Add('-Fu../lcl/units/$(CPU_TARGET)-$(OS_TARGET)');
    //P.Options.Add('-Fu../components/lazutils/lib/$(CPU_TARGET)-$(OS_TARGET)');
    //P.Options.Add('-Fu../packager/units/$(CPU_TARGET)-$(OS_TARGET)');
    P.Options.Add('-Fu.');
    T:=P.Targets.AddUnit('ide.pas');
    t.Dependencies.AddUnit('packagesystem');
    t.Dependencies.AddUnit('adddirtopkgdlg');
    t.Dependencies.AddUnit('addfiletoapackagedlg');
    t.Dependencies.AddUnit('addtopackagedlg');
    t.Dependencies.AddUnit('basepkgmanager');
    t.Dependencies.AddUnit('brokendependenciesdlg');
    t.Dependencies.AddUnit('confirmpkglistdlg');
    t.Dependencies.AddUnit('package_description_options');
    t.Dependencies.AddUnit('package_i18n_options');
    t.Dependencies.AddUnit('package_integration_options');
    t.Dependencies.AddUnit('package_provides_options');
    t.Dependencies.AddUnit('package_usage_options');
    t.Dependencies.AddUnit('installpkgsetdlg');
    t.Dependencies.AddUnit('missingpkgfilesdlg');
    t.Dependencies.AddUnit('openinstalledpkgdlg');
    t.Dependencies.AddUnit('packagedefs');
    t.Dependencies.AddUnit('packageeditor');
    t.Dependencies.AddUnit('packagelinks');
    t.Dependencies.AddUnit('pkggraphexplorer');
    t.Dependencies.AddUnit('pkglinksdlg');
    t.Dependencies.AddUnit('pkgmanager');
    t.Dependencies.AddUnit('pkgvirtualuniteditor');
    t.Dependencies.AddUnit('ucomponentmanmain');
    t.Dependencies.AddUnit('ufrmaddcomponent');
    t.Dependencies.AddUnit('assemblerdlg');
    t.Dependencies.AddUnit('breakpointsdlg');
    t.Dependencies.AddUnit('breakpropertydlg');
    t.Dependencies.AddUnit('breakpropertydlggroups');
    t.Dependencies.AddUnit('callstackdlg');
    t.Dependencies.AddUnit('cmdlinedebugger');
    t.Dependencies.AddUnit('debugeventsform');
    t.Dependencies.AddUnit('debugger');
    t.Dependencies.AddUnit('debuggerdlg');
    t.Dependencies.AddUnit('debugoutputform');
    t.Dependencies.AddUnit('debugutils');
    t.Dependencies.AddUnit('evaluatedlg');
    t.Dependencies.AddUnit('exceptiondlg');
    t.Dependencies.AddUnit('feedbackdlg');
    t.Dependencies.AddUnit('gdbmidebugger');
    t.Dependencies.AddUnit('gdbmimiscclasses');
    t.Dependencies.AddUnit('gdbtypeinfo');
    t.Dependencies.AddUnit('historydlg');
    t.Dependencies.AddUnit('inspectdlg');
    t.Dependencies.AddUnit('localsdlg');
    t.Dependencies.AddUnit('processdebugger');
    t.Dependencies.AddUnit('processlist');
    t.Dependencies.AddUnit('pseudoterminaldlg');
    t.Dependencies.AddUnit('registersdlg');
    t.Dependencies.AddUnit('sshgdbmidebugger');
    t.Dependencies.AddUnit('threaddlg');
    t.Dependencies.AddUnit('watchesdlg');
    t.Dependencies.AddUnit('watchpropertydlg');

    P.Sources.AddSrc('aboutfrm.pas');
    P.Sources.AddSrc('abstractsmethodsdlg.pas');
    P.Sources.AddSrc('addprofiledialog.pas');
    P.Sources.AddSrc('addtoprojectdlg.pas');
    P.Sources.AddSrc('applicationbundle.pas');
    P.Sources.AddSrc('basebuildmanager.pas');
    P.Sources.AddSrc('basedebugmanager.pas');
    P.Sources.AddSrc('buildfiledlg.pas');
    P.Sources.AddSrc('buildlazdialog.pas');
    P.Sources.AddSrc('buildmanager.pas');
    P.Sources.AddSrc('buildmodediffdlg.pas');
    P.Sources.AddSrc('buildprofilemanager.pas');
    P.Sources.AddSrc('charactermapdlg.pas');
    P.Sources.AddSrc('checkcompileropts.pas');
    P.Sources.AddSrc('checklfmdlg.pas');
    P.Sources.AddSrc('cleandirdlg.pas');
    P.Sources.AddSrc('clipboardhistory.pas');
    P.Sources.AddSrc('codebrowser.pas');
    P.Sources.AddSrc('codecontextform.pas');
    P.Sources.AddSrc('codeexplopts.pas');
    P.Sources.AddSrc('codeexplorer.pas');
    P.Sources.AddSrc('codehelp.pas');
    P.Sources.AddSrc('codemacroprompt.pas');
    P.Sources.AddSrc('codemacroselect.pas');
    P.Sources.AddSrc('codetemplatesdlg.pas');
    P.Sources.AddSrc('codetoolsdefines.pas');
    P.Sources.AddSrc('codetoolsdefpreview.pas');
    P.Sources.AddSrc('codetoolsoptions.pas');
    P.Sources.AddSrc('compatibilityrestrictions.pas');
    P.Sources.AddSrc('compiler.pp');
    P.Sources.AddSrc('compileroptions.pp');
    P.Sources.AddSrc('componentlist.pas');
    P.Sources.AddSrc('componentpalette.pas');
    P.Sources.AddSrc('compoptsmodes.pas');
    P.Sources.AddSrc('condef.pas');
    P.Sources.AddSrc('customformeditor.pp');
    P.Sources.AddSrc('debugmanager.pas');
    P.Sources.AddSrc('dialogprocs.pas');
    P.Sources.AddSrc('diffdialog.pas');
    P.Sources.AddSrc('diffpatch.pas');
    P.Sources.AddSrc('diskdiffsdialog.pas');
    P.Sources.AddSrc('editdefinetree.pas');
    P.Sources.AddSrc('editmsgscannersdlg.pas');
    P.Sources.AddSrc('editoroptions.pp');
    P.Sources.AddSrc('emptymethodsdlg.pas');
    P.Sources.AddSrc('encloseselectiondlg.pas');
    P.Sources.AddSrc('environmentopts.pp');
    P.Sources.AddSrc('extractprocdlg.pas');
    P.Sources.AddSrc('exttooldialog.pas');
    P.Sources.AddSrc('exttooleditdlg.pas');
    P.Sources.AddSrc('filereferencelist.pas');
    P.Sources.AddSrc('findinfilesdlg.pas');
    P.Sources.AddSrc('findoverloadsdlg.pas');
    P.Sources.AddSrc('findpalettecomp.pas');
    P.Sources.AddSrc('findrenameidentifier.pas');
    P.Sources.AddSrc('findreplacedialog.pp');
    P.Sources.AddSrc('findunitdlg.pas');
    P.Sources.AddSrc('formeditor.pp');
    P.Sources.AddSrc('fpcsrcscan.pas');
    P.Sources.AddSrc('fpdoceditwindow.pas');
    P.Sources.AddSrc('fpdochints.pas');
    P.Sources.AddSrc('fpdocselectinherited.pas');
    P.Sources.AddSrc('fpdocselectlink.pas');
    P.Sources.AddSrc('frames/atom_checkboxes_options.pas');
    P.Sources.AddSrc('frames/backup_options.pas');
    P.Sources.AddSrc('frames/buildmodeseditor.pas');
    P.Sources.AddSrc('frames/codeexplorer_categories_options.pas');
    P.Sources.AddSrc('frames/codeexplorer_update_options.pas');
    P.Sources.AddSrc('frames/codeobserver_options.pas');
    P.Sources.AddSrc('frames/codetools_classcompletion_options.pas');
    P.Sources.AddSrc('frames/codetools_codecreation_options.pas');
    P.Sources.AddSrc('frames/codetools_general_options.pas');
    P.Sources.AddSrc('frames/codetools_identifiercompletion_options.pas');
    P.Sources.AddSrc('frames/codetools_linesplitting_options.pas');
    P.Sources.AddSrc('frames/codetools_space_options.pas');
    P.Sources.AddSrc('frames/codetools_wordpolicy_options.pas');
    P.Sources.AddSrc('frames/compiler_buildmacro_options.pas');
    P.Sources.AddSrc('frames/compiler_codegen_options.pas');
    P.Sources.AddSrc('frames/compiler_compilation_options.pas');
    P.Sources.AddSrc('frames/compiler_config_target.pas');
    P.Sources.AddSrc('frames/compiler_linking_options.pas');
    P.Sources.AddSrc('frames/compiler_messages_options.pas');
    P.Sources.AddSrc('frames/compiler_other_options.pas');
    P.Sources.AddSrc('frames/compiler_parsing_options.pas');
    P.Sources.AddSrc('frames/compiler_path_options.pas');
    P.Sources.AddSrc('frames/compiler_verbosity_options.pas');
    P.Sources.AddSrc('frames/desktop_options.pas');
    P.Sources.AddSrc('frames/editor_codefolding_options.pas');
    P.Sources.AddSrc('frames/editor_codetools_options.pas');
    P.Sources.AddSrc('frames/editor_color_options.pas');
    P.Sources.AddSrc('frames/editor_display_options.pas');
    P.Sources.AddSrc('frames/editor_dividerdraw_options.pas');
    P.Sources.AddSrc('frames/editor_general_misc_options.pas');
    P.Sources.AddSrc('frames/editor_general_options.pas');
    P.Sources.AddSrc('frames/editor_keymapping_options.pas');
    P.Sources.AddSrc('frames/editor_mouseaction_options.pas');
    P.Sources.AddSrc('frames/editor_mouseaction_options_advanced.pas');
    P.Sources.AddSrc('frames/editor_multiwindow_options.pas');
    P.Sources.AddSrc('frames/files_options.pas');
    P.Sources.AddSrc('frames/formed_options.pas');
    P.Sources.AddSrc('frames/fpdoc_options.pas');
    P.Sources.AddSrc('frames/help_general_options.pas');
    P.Sources.AddSrc('frames/naming_options.pas');
    P.Sources.AddSrc('frames/oi_options.pas');
    P.Sources.AddSrc('frames/project_application_options.pas');
    P.Sources.AddSrc('frames/project_forms_options.pas');
    P.Sources.AddSrc('frames/project_i18n_options.pas');
    P.Sources.AddSrc('frames/project_lazdoc_options.pas');
    P.Sources.AddSrc('frames/project_misc_options.pas');
    P.Sources.AddSrc('frames/project_save_options.pas');
    P.Sources.AddSrc('frames/project_versioninfo_options.pas');
    P.Sources.AddSrc('frames/window_options.pas');
    P.Sources.AddSrc('frmcustomapplicationoptions.pas');
    P.Sources.AddSrc('gotofrm.pas');
    P.Sources.AddSrc('helpfpcmessages.pas');
    P.Sources.AddSrc('helpoptions.pas');
    P.Sources.AddSrc('idecmdline.pas');
    P.Sources.AddSrc('idecontexthelpedit.pas');
    P.Sources.AddSrc('idedefs.pas');
    P.Sources.AddSrc('idefpcinfo.pas');
    P.Sources.AddSrc('ideoptiondefs.pas');
    P.Sources.AddSrc('ideoptionsdlg.pas');
    P.Sources.AddSrc('ideprocs.pp');
    P.Sources.AddSrc('ideprotocol.pas');
    P.Sources.AddSrc('idetranslations.pas');
    P.Sources.AddSrc('idewindowhelp.pas');
    P.Sources.AddSrc('imexportcompileropts.pas');
    P.Sources.AddSrc('infobuild.pp');
    P.Sources.AddSrc('initialsetupdlgs.pas');
    P.Sources.AddSrc('inputfiledialog.pas');
    P.Sources.AddSrc('inputhistory.pas');
    P.Sources.AddSrc('invertassigntool.pas');
    P.Sources.AddSrc('jumphistoryview.pas');
    P.Sources.AddSrc('keymapping.pp');
    P.Sources.AddSrc('keymapschemedlg.pas');
    P.Sources.AddSrc('keymapshortcutdlg.pas');
    P.Sources.AddSrc('lazarus.pp');
    P.Sources.AddSrc('lazarusidestrconsts.pas');
    P.Sources.AddSrc('lazarusmanager.pas');
    P.Sources.AddSrc('lazconf.pp');
    P.Sources.AddSrc('macropromptdlg.pas');
    P.Sources.AddSrc('main.pp');
    P.Sources.AddSrc('mainbar.pas');
    P.Sources.AddSrc('mainbase.pas');
    P.Sources.AddSrc('mainintf.pas');
    P.Sources.AddSrc('makeresstrdlg.pas');
    P.Sources.AddSrc('miscoptions.pas');
    P.Sources.AddSrc('mouseactiondialog.pas');
    P.Sources.AddSrc('msgquickfixes.pas');
    P.Sources.AddSrc('msgview.pp');
    P.Sources.AddSrc('msgvieweditor.pas');
    P.Sources.AddSrc('multireplacedlg.pas');
    P.Sources.AddSrc('newdialog.pas');
    P.Sources.AddSrc('newprojectdlg.pp');
    P.Sources.AddSrc('objectlists.pas');
    P.Sources.AddSrc('outputfilter.pas');
    P.Sources.AddSrc('patheditordlg.pas');
    P.Sources.AddSrc('procedurelist.pas');
    P.Sources.AddSrc('progressdlg.pas');
    P.Sources.AddSrc('progresswnd.pas');
    P.Sources.AddSrc('project.pp');
    P.Sources.AddSrc('projectdefs.pas');
    P.Sources.AddSrc('projecticon.pas');
    P.Sources.AddSrc('projectinspector.pas');
    P.Sources.AddSrc('projectresources.pas');
    P.Sources.AddSrc('projectwizarddlg.pas');
    P.Sources.AddSrc('publishmodule.pas');
    P.Sources.AddSrc('publishprojectdlg.pas');
    P.Sources.AddSrc('restrictionbrowser.pas');
    P.Sources.AddSrc('runparamsopts.pas');
    P.Sources.AddSrc('searchfrm.pas');
    P.Sources.AddSrc('searchresultview.pp');
    P.Sources.AddSrc('showcompileropts.pas');
    P.Sources.AddSrc('showdeletingfilesdlg.pas');
    P.Sources.AddSrc('sortselectiondlg.pas');
    P.Sources.AddSrc('sourceeditor.pp');
    P.Sources.AddSrc('sourceeditprocs.pas');
    P.Sources.AddSrc('sourcemarks.pas');
    P.Sources.AddSrc('sourcesyneditor.pas');
    P.Sources.AddSrc('splash.pp');
    P.Sources.AddSrc('srcedithintfrm.pas');
    P.Sources.AddSrc('sysvaruseroverridedlg.pas');
    P.Sources.AddSrc('transfermacros.pp');
    P.Sources.AddSrc('unitdependencies.pas');
    P.Sources.AddSrc('unitinfodlg.pp');
    P.Sources.AddSrc('unusedunitsdlg.pas');
    P.Sources.AddSrc('viewunit_dlg.pp');
    P.Sources.AddSrc('w32manifest.pas');
    P.Sources.AddSrc('w32versioninfo.pas');
    P.Sources.AddSrc('wordcompletion.pp');
    T:=P.Targets.AddUnit('../packager/packagesystem.pas');
    T:=P.Targets.AddUnit('../packager/adddirtopkgdlg.pas');
    T:=P.Targets.AddUnit('../packager/addfiletoapackagedlg.pas');
    T:=P.Targets.AddUnit('../packager/addtopackagedlg.pas');
    T:=P.Targets.AddUnit('../packager/basepkgmanager.pas');
    T:=P.Targets.AddUnit('../packager/brokendependenciesdlg.pas');
    T:=P.Targets.AddUnit('../packager/confirmpkglistdlg.pas');
    T:=P.Targets.AddUnit('../packager/frames/package_description_options.pas');
    T:=P.Targets.AddUnit('../packager/frames/package_i18n_options.pas');
    T:=P.Targets.AddUnit('../packager/frames/package_integration_options.pas');
    T:=P.Targets.AddUnit('../packager/frames/package_provides_options.pas');
    T:=P.Targets.AddUnit('../packager/frames/package_usage_options.pas');
    T:=P.Targets.AddUnit('../packager/installpkgsetdlg.pas');
    T:=P.Targets.AddUnit('../packager/missingpkgfilesdlg.pas');
    T:=P.Targets.AddUnit('../packager/openinstalledpkgdlg.pas');
    T:=P.Targets.AddUnit('../packager/packagedefs.pas');
    T:=P.Targets.AddUnit('../packager/packageeditor.pas');
    T:=P.Targets.AddUnit('../packager/packagelinks.pas');
    T:=P.Targets.AddUnit('../packager/pkggraphexplorer.pas');
    T:=P.Targets.AddUnit('../packager/pkglinksdlg.pas');
    T:=P.Targets.AddUnit('../packager/pkgmanager.pas');
    T:=P.Targets.AddUnit('../packager/pkgvirtualuniteditor.pas');
    T:=P.Targets.AddUnit('../packager/ucomponentmanmain.pas');
    T:=P.Targets.AddUnit('../packager/ufrmaddcomponent.pas');
    T:=P.Targets.AddUnit('../debugger/assemblerdlg.pp');
    T:=P.Targets.AddUnit('../debugger/breakpointsdlg.pp');
    T:=P.Targets.AddUnit('../debugger/breakpropertydlg.pas');
    T:=P.Targets.AddUnit('../debugger/breakpropertydlggroups.pas');
    T:=P.Targets.AddUnit('../debugger/callstackdlg.pp');
    T:=P.Targets.AddUnit('../debugger/cmdlinedebugger.pp');
    T:=P.Targets.AddUnit('../debugger/debugeventsform.pp');
    T:=P.Targets.AddUnit('../debugger/debugger.pp');
    T:=P.Targets.AddUnit('../debugger/debuggerdlg.pp');
    T:=P.Targets.AddUnit('../debugger/debugoutputform.pp');
    T:=P.Targets.AddUnit('../debugger/debugutils.pp');
    T:=P.Targets.AddUnit('../debugger/evaluatedlg.pp');
    T:=P.Targets.AddUnit('../debugger/exceptiondlg.pas');
    T:=P.Targets.AddUnit('../debugger/feedbackdlg.pp');
    T:=P.Targets.AddUnit('../debugger/gdbmidebugger.pp');
    T:=P.Targets.AddUnit('../debugger/gdbmimiscclasses.pp');
    T:=P.Targets.AddUnit('../debugger/gdbtypeinfo.pp');
    T:=P.Targets.AddUnit('../debugger/historydlg.pp');
    T:=P.Targets.AddUnit('../debugger/inspectdlg.pas');
    T:=P.Targets.AddUnit('../debugger/localsdlg.pp');
    T:=P.Targets.AddUnit('../debugger/processdebugger.pp');
    T:=P.Targets.AddUnit('../debugger/processlist.pas');
    T:=P.Targets.AddUnit('../debugger/pseudoterminaldlg.pp');
    T:=P.Targets.AddUnit('../debugger/registersdlg.pp');
    T:=P.Targets.AddUnit('../debugger/sshgdbmidebugger.pas');
    T:=P.Targets.AddUnit('../debugger/threaddlg.pp');
    T:=P.Targets.AddUnit('../debugger/watchesdlg.pp');
    T:=P.Targets.AddUnit('../debugger/watchpropertydlg.pp');

    // copy the compiled file, so the IDE knows how the package was compiled
    P.InstallFiles.Add('ide.compiled',AllOSes,'$(unitinstalldir)');

    end;
end;

{$ifndef ALLPACKAGES}
begin
  add_ide;
  Installer.Run;
end.
{$endif ALLPACKAGES}
