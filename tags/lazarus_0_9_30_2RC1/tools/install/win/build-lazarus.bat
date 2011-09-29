SET OLDCURDRIVE=%CD:~,2%
SET OLDCURDIR=%CD%

%BUILDDRIVE%
cd %BUILDDIR%
%MAKEEXE% clean PP=%COMPILER% >> %LOGFILE%
%MAKEEXE% lcl OPT="-gl -Ur" PP=%COMPILER% >> %LOGFILE%

IF NOT "%FPCTARGETOS%"=="win32" GOTO BUILDIDE
%MAKEEXE% lcl OPT="-gl -Ur" PP=%COMPILER% LCL_PLATFORM=gtk2 >> %LOGFILE%
%MAKEEXE% lcl OPT="-gl -Ur" PP=%COMPILER% LCL_PLATFORM=qt >> %LOGFILE%

:BUILDIDE
IF "%IDE_WIDGETSET%"=="" SET IDE_WIDGETSET=win32
%MAKEEXE% bigide OPT="-Xs -XX" PP=%COMPILER% LCL_PLATFORM=%IDE_WIDGETSET% >> %LOGFILE%
%MAKEEXE% lazbuilder OPT="-Xs -XX" PP=%COMPILER% >> %LOGFILE%

%FPCBINDIR%\strip.exe lazarus.exe
%FPCBINDIR%\strip.exe lazbuild.exe
%FPCBINDIR%\strip.exe startlazarus.exe

%OLDCURDRIVE%
cd %OLDCURDIR%
