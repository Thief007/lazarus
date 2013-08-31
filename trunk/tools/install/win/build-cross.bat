:: check all the necessary parameters are given
if [%1]==[] goto USAGE
if [%2]==[] goto USAGE
if [%3]==[] goto USAGE
if [%4]==[] goto USAGE
if [%5]==[] goto USAGE

:: Set some environment variables from the command line
:: Path to the fpc sources checked out of fpcbuild svn repository
SET FPCSVNDIR=%1

:: Path to the lazarus sources checked out of subversion
SET LAZSVNDIR=%2

:: Path to latest release compiler
SET RELEASE_PPC=%3

SET TARGETCPU=%4
SET TARGETOS=%5

::=====================================================================
:: Find required programs
:: These settings are dependent on the configuration of the build machine
:: Path to the Inno Setup Compiler
if [%ISCC%]==[] SET ISCC="C:\Program Files\Inno Setup 5\iscc.exe"

:: Path to the directory containing the binutils for each target in a 
:: separate directory, for example arm-wince for the arm-wince target
if [%BINUTILSDIR%]==[] SET BINUTILSDIR=c:\lazarus\source\binutils

:: Path to build directory. 
:: In this directory an image of the installation will be built.
SET BUILDDIR=c:\temp\lazbuild

:: Path to the svn executable
if [%SVN%]==[] SET SVN="c:\program files\subversion\bin\svn.exe"

:: Some internal variables
SET OLDCURDIR=%CD%
SET OLDCURDRIVE=%CD:~,2%
SET FPCSVNDRIVE=%FPCSVNDIR:~,2%
SET BUILDDRIVE=%BUILDDIR:~,2%


SET FPCBINDIR=%FPCSVNDIR%\install\binw32
FOR /F %%L IN ('%FPCBINDIR%\gdate.exe +%%Y%%m%%d') DO SET DATESTAMP=%%L
SET FPCFULLTARGET=%TARGETCPU%-%TARGETOS%
FOR /F %%F IN ('svnversion.exe %LAZSVNDIR%') DO set LAZREVISION=%%F

SET TIMESTAMP=%date:~9,4%%date:~6,2%%date:~3,2%-%time:~,2%%time:~3,2%%time:~6,2%
SET MAKEEXE=%FPCBINDIR%\make.exe

:: set path to make sure the right tools are used
SET OLDPATH=%PATH%
PATH=%FPCBINDIR%;
%FPCSVNDRIVE%
cd %FPCSVNDIR%\fpcsrc

::=====================================================================
:: Build a native FPC

%MAKEEXE% distclean FPC=%RELEASE_PPC% 
rm -rf %FPCSVNDIR%\fpcsrc\compiler\*.exe
:: create a native compiler + utils
%MAKEEXE% compiler_cycle FPC=%RELEASE_PPC%

FOR /F %%L IN ('%FPCSVNDIR%\fpcsrc\compiler\utils\fpc.exe -PB') DO SET COMPILER=%FPCSVNDIR%\fpcsrc\compiler\%%L
FOR /F %%L IN ('%COMPILER% -iSO') DO SET FPCSourceOS=%%L
FOR /F %%L IN ('%COMPILER% -iSP') DO SET FPCSourceCPU=%%L
FOR /F %%L IN ('%FPCSVNDIR%\fpcsrc\compiler\utils\fpc.exe -P%TARGETCPU% -PB') DO SET PPCNAME=%%L
SET FPCFPMAKE=%COMPILER%

:: rebuild the rtl without WPO information
rem %MAKEEXE% rtl_clean rtl PP=%COMPILER%
%MAKEEXE% rtl_clean PP=%COMPILER%
:: 271 needs packages too
%MAKEEXE% rtl packages PP=%COMPILER% OPT="-Ur -CX"


rem %MAKEEXE% -C utils fpcm_all FPC=%COMPILER%
%MAKEEXE% utils PP=%COMPILER% OPT="-CX -XX -Xs" DATA2INC=%FPCSVNDIR%\fpcsrc\utils\data2inc

:: find fpcmake
FOR /F %%L IN ('%COMPILER% -iV') DO SET FPCVERSION=%%L
FOR /F %%L IN ('%COMPILER% -iTO') DO SET FPCTARGETOS=%%L
FOR /F %%L IN ('%COMPILER% -iTP') DO SET FPCTARGETCPU=%%L
SET FPCFULLNATIVE=%FPCTARGETCPU%-%FPCTARGETOS%

SET FPCMAKE=%FPCSVNDIR%\fpcsrc\utils\fpcm\bin\%FPCFULLNATIVE%\fpcmake.exe
IF "%FPCVERSION:~0,3%" == "2.6" SET FPCMAKE=%FPCSVNDIR%\fpcsrc\utils\fpcm\fpcmake.exe

::=====================================================================
:: Build cross FPC

%MAKEEXE% compiler FPC=%COMPILER% PPC_TARGET=%TARGETCPU% EXENAME=%PPCNAME%
IF ERRORLEVEL 1 GOTO CLEANUP
SET COMPILER=%FPCSVNDIR%\fpcsrc\compiler\%PPCNAME%
SET CPU_TARGET=%TARGETCPU%
SET OS_TARGET=%TARGETOS%
:: CROSSBINDIR and are used in the FPC makefiles
SET CROSSBINDIR=%BINUTILSDIR%\%FPCFULLTARGET%
SET BINUTILSPREFIX=%FPCFULLTARGET%-

%MAKEEXE% -C rtl clean FPC=%COMPILER%
%MAKEEXE% -C packages clean FPC=%COMPILER%
%MAKEEXE% rtl packages FPC=%COMPILER% 
IF ERRORLEVEL 1 GOTO CLEANUP

FOR /F %%L IN ('%COMPILER% -iV') DO SET FPCVERSION=%%L
FOR /F %%L IN ('%COMPILER% -iW') DO SET FPCFULLVERSION=%%L

SET INSTALL_BASE=%BUILDDIR%\image\fpc\%FPCVERSION%
SET INSTALL_BINDIR=%INSTALL_BASE%\bin\i386-win32

:: copy the binutils
rmdir /s /q %BUILDDIR%
gmkdir -p %INSTALL_BINDIR%
cp %CROSSBINDIR%\* %INSTALL_BINDIR%

%MAKEEXE% rtl_install packages_install FPCMAKE=%FPCMAKE% INSTALL_PREFIX=%INSTALL_BASE% FPC=%COMPILER%

copy %COMPILER% %INSTALL_BINDIR%
%MAKEEXE% -C packages\fcl-base all FPC=%FPCFPMAKE% OS_TARGET=%FPCSourceOS% CPU_TARGET=%FPCSourceCPU%
%MAKEEXE% -C packages\fcl-process all FPC=%FPCFPMAKE% OS_TARGET=%FPCSourceOS% CPU_TARGET=%FPCSourceCPU%
%MAKEEXE% -C utils fpcmkcfg_all FPC=%FPCFPMAKE% OS_TARGET=%FPCSourceOS% CPU_TARGET=%FPCSourceCPU%
%FPCSVNDIR%\fpcsrc\utils\fpcmkcfg\fpcmkcfg.exe -d "basepath=%INSTALL_BASE%" -o %INSTALL_BINDIR%\fpc.cfg
SET COMPILER=%INSTALL_BINDIR%\%PPCNAME%

gmkdir -p %BUILDDIR%\packager
%SVN% export -q %LAZSVNDIR%\packager\registration %BUILDDIR%\packager\registration
%BUILDDRIVE%
cd %BUILDDIR%\packager\registration
%MAKEEXE% FPC=%compiler%
IF ERRORLEVEL 1 GOTO CLEANUP
gmkdir -p %BUILDDIR%\image\packager\units
cp -pr %BUILDDIR%\packager\units\%FPCFULLTARGET% %BUILDDIR%\image\packager\units\%FPCFULLTARGET%

gmkdir -p %BUILDDIR%\components
%SVN% export -q %LAZSVNDIR%\components\lazutils %BUILDDIR%\components\lazutils
%BUILDDRIVE%
cd %BUILDDIR%\components\lazutils
%MAKEEXE% FPC=%compiler%
IF ERRORLEVEL 1 GOTO CLEANUP
gmkdir -p %BUILDDIR%\image\components\lazutils
cp -pr %BUILDDIR%\components\lazutils\lib %BUILDDIR%\image\components\lazutils\lib

%SVN% export -q %LAZSVNDIR%\lcl %BUILDDIR%\lcl
%BUILDDRIVE%
cd %BUILDDIR%\lcl
%MAKEEXE% FPC=%compiler%
IF ERRORLEVEL 1 GOTO CLEANUP
gmkdir -p %BUILDDIR%\image\lcl\units
cp -pr %BUILDDIR%\lcl\units\%FPCFULLTARGET% %BUILDDIR%\image\lcl\units\%FPCFULLTARGET%

%SVN% export -q %LAZSVNDIR%\components\lazcontrols %BUILDDIR%\components\lazcontrols
%BUILDDRIVE%
cd %BUILDDIR%\components\lazcontrols
%MAKEEXE% FPC=%compiler%
IF ERRORLEVEL 1 GOTO CLEANUP
gmkdir -p %BUILDDIR%\image\components\lazcontrols
cp -pr %BUILDDIR%\components\lazcontrols\lib %BUILDDIR%\image\components\lazcontrols\lib

gmkdir -p %BUILDDIR%\components
%SVN% export -q %LAZSVNDIR%\components\ideintf %BUILDDIR%\components\ideintf
:: export images dir, the ideintf includes them
%SVN% export -q %LAZSVNDIR%\images %BUILDDIR%\images
cd %BUILDDIR%\components\ideintf
IF ERRORLEVEL 1 GOTO CLEANUP
%MAKEEXE% FPC=%compiler%
gmkdir -p %BUILDDIR%\image\components\ideintf\units
cp -pr %BUILDDIR%\components\ideintf\units\%FPCFULLTARGET% %BUILDDIR%\image\components\ideintf\units\%FPCFULLTARGET%

%SVN% export -q %LAZSVNDIR%\components\synedit %BUILDDIR%\components\synedit
cd %BUILDDIR%\components\synedit
IF ERRORLEVEL 1 GOTO CLEANUP
%MAKEEXE% FPC=%compiler%
gmkdir -p %BUILDDIR%\image\components\synedit\units
cp -pr %BUILDDIR%\components\synedit\units\%FPCFULLTARGET% %BUILDDIR%\image\components\synedit\units\%FPCFULLTARGET%

del %INSTALL_BINDIR%\fpc.cfg

%OLDCURDRIVE%
cd %OLDCURDIR%
FOR /F %%F IN ('%LAZSVNDIR%\tools\install\get_lazarus_version.bat') DO set LAZVERSION=%%F

SET OutputFileName=lazarus-%LAZVERSION%-fpc-%FPCFULLVERSION%-cross-%FPCFULLTARGET%-%FPCSourceOS%
if [%BUILDLAZRELEASE%]==[] SET OutputFileName=lazarus-%LAZVERSION%-%LAZREVISION%-fpc-%FPCFULLVERSION%-%DATESTAMP%-cross-%FPCFULLTARGET%-%FPCSourceOS%

%ISCC% lazarus-cross.iss 

:CLEANUP
SET FPCFPMAKE=
SET CPU_TARGET=
SET OS_TARGET=
SET CROSSBINDIR=
SET BINUTILSPREFIX=
SET PATH=%OLDPATH%

goto STOP

:USAGE
@echo off
echo Usage:
echo build-cross.bat FPCSVNDIR LAZSVNDIR RELEASECOMPILER TARGETCPU TARGETOS
echo FPCSVNDIR: directory that contains a svn version of the fpcbuild repository
echo LAZSVNDIR: directory that contains a svn version of the lazarus repository
echo RELEASECOMPILER: bootstrapping compiler for building fpc
echo TARGETCPU: target CPU
echo TARGETOS: target operating system

:STOP
