@echo off
set SAScmd="C:\Program Files\SASHome\SASFoundation\9.4\sas.exe" -ls 200 -ps 60 -nocenter -nosplash -sysin
set SASconfig=-nologo -config "C:\Program Files\SASHome\SASFoundation\9.4\nls\u8\SASV9.CFG"

cd ..\programs

for %%i in (log html lst) do @if exist *.%%i del *.%%i

REM %SAScmd% 01_convert_xpt.sas %SASconfig%
%SAScmd% 02_create_metadata_from_definexml.sas %SASconfig%
%SAScmd% 03_write_datasetjson.sas %SASconfig%
%SAScmd% 04_read_datasetjson.sas %SASconfig%
%SAScmd% 05_compare_data.sas %SASconfig%

findstr /i /n /r /g:C:\tools\ultraedit-configuration\search.txt "*.log" | findstr /i /v /g:C:\tools\ultraedit-configuration\search_not.txt > %~n0.log

runbatch.log

PING localhost -n 5 >NUL
