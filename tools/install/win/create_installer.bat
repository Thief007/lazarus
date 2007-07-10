:: check all the necessary parameters are given
if [%1]==[] goto USAGE
if [%2]==[] goto USAGE
if [%3]==[] goto USAGE

:: These settings are dependent on the configuration of the build machine
:: Path to the Inno Setup Compiler
if [%ISCC%]==[] SET ISCC="C:\Program Files\Inno Setup 5\iscc.exe"

:: Path to the directory containing the mingw gdb debugger installation
:: it should have the debugger with the name gdb.exe in its bin subdirectory
SET GDBDIR=c:\lazarus\source\mingw

:: Path to build directory. 
:: In this directory an image of the installation will be built.
SET BUILDDIR=c:\temp\lazbuild

:: Path to the svn executable
if [%SVN%]==[] SET SVN="c:\program files\subversion\bin\svn.exe"

:: Path to the fpc sources checked out of fpcbuild svn repository
SET FPCSVNDIR=%1

:: Path to the lazarus sources checked out of subversion
SET LAZSVNDIR=%2

:: Path to latest release compiler
SET RELEASE_PPC=%3

:: Name of fpc patch file
SET PATCHFILE=%4

::=====================================================================
:: no change needed after this.

:: Some internal variables
FOR /F %%L IN ('%RELEASE_PPC% -iTO') DO SET FPCTARGETOS=%%L
FOR /F %%L IN ('%RELEASE_PPC% -iTP') DO SET FPCTARGETCPU=%%L
SET FPCFULLTARGET=%FPCTARGETCPU%-%FPCTARGETOS%

SET FPCBINDIR=%FPCSVNDIR%\install\binw%FPCTARGETOS:~-2%
SET MAKEEXE=%FPCBINDIR%\make.exe
SET PATCHEXE=%FPCSVNDIR%\install\binw32\patch.exe
SET LOGFILE=%CD%\installer.log
SET PATCHDIR=%CD%\..\patches
FOR /F %%L IN ('%FPCBINDIR%\gdate.exe +%%Y%%m%%d') DO SET DATESTAMP=%%L
SET BUILDDRIVE=%BUILDDIR:~,2%
SET CP=%FPCBINDIR%\cp.exe
FOR /F "delims='" %%F IN (%LAZSVNDIR%\ide\version.inc) DO set LAZVERSION=%%F

ECHO Starting at: > %LOGFILE%
%FPCBINDIR%\gdate >> %LOGFILE%

:: set path to make sure the right tools are used
SET OLDPATH=%PATH%
SET PATH=%FPCBINDIR%

:: copy lazarus dir
rmdir /s /q %BUILDDIR%
%SVN% export %LAZSVNDIR% %BUILDDIR% >> %LOGFILE%
..\..\svn2revisioninc %LAZSVNDIR% %BUILDDIR%\ide\revision.inc

call build-fpc.bat

:: INSTALL_BINDIR is set by build-fpc.bat
%SVN% export %FPCBINDIR% %BUILDDIR%\fpcbins >> %LOGFILE%
mv %BUILDDIR%\fpcbins\*.* %INSTALL_BINDIR%
%FPCBINDIR%\rm -rf %BUILDDIR%\fpcbins
del %INSTALL_BINDIR%\gdb.exe

:: exit if no compiler has been made
if not exist %INSTALL_BINDIR%\fpc.exe goto END

%INSTALL_BINDIR%\fpcmkcfg.exe -d "basepath=%INSTALL_BASE%" -o %INSTALL_BINDIR%\fpc.cfg

call build-lazarus.bat

:: remove fpc.cfg, the installer will create a new one
del %INSTALL_BINDIR%\fpc.cfg

:: do not create installer, if the required executables are not there
if not exist %BUILDDIR%\lazarus.exe goto END
if not exist %BUILDDIR%\startlazarus.exe goto END

:: copy gdb into build dir
if exist %GDBDIR% %CP% -pr %GDBDIR% %BUILDDIR%

:: create the installer
%ISCC% lazarus.iss >> installer.log

:: do not delete build dir, if installer failed.
if not exist output\lazarus-%LAZVERSION%-fpc-%FPCVERSION%-%DATESTAMP%-%FPCTARGETOS%.exe goto END

:: delete build dir
::rd /s /q %BUILDDIR% > NUL

:END

SET PATH=%OLDPATH%

ECHO Finished at: >> %LOGFILE%
%FPCBINDIR%\gdate >> %LOGFILE%

goto STOP

:USAGE
@echo off
echo Usage:
echo create_installer.bat FPCSVNDIR LAZSVNDIR RELEASECOMPILER [PATCHFILE]
echo FPCSVNDIR: directory that contains a svn version of the fpcbuild repository
echo LAZSVNDIR: directory that contains a svn version of the lazarus repository
echo RELEASECOMPILER: bootstrapping compiler for building fpc
echo PATCHFILE: optional patch file for the fpc sources

:STOP