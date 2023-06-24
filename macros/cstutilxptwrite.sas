%* Copyright (c) 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.   *;
%* SPDX-License-Identifier: Apache-2.0                                            *;
%*                                                                                *;
%* cstutilxptwrite                                                                *;
%*                                                                                *;
%* Creates SAS Version 5 XPORT files from a library of SAS data sets.             *;
%*                                                                                *;
%* This macro creates SAS Version 5 XPORT files from a library of SAS data sets.  *;
%*                                                                                *;
%* Notes:                                                                         *;
%*   1. Any librefs referenced in macro parameters must be pre-allocated.         *;
%*   2. All SAS data sets are located in one library.                             *;
%*   3. Existing SAS Version 5 XPORT files are overwritten.                       *;
%*                                                                                *;
%* @macvar _cst_rc Task error status                                              *;
%* @macvar _cst_rcmsg Message associated with _cst_rc                             *;
%*                                                                                *;
%* @param _cstSourceLibrary - required - The libref of the data folder/library    *;
%*            in which the SAS data files are located.                            *;
%* @param _cstOutputFolder - required - The folder in which to create the SAS     *;
%*            Version 5 XPORT (XPT) files.                                        *;
%* @param _cstOptions - optional - Extra options for the PROC COPY statement.     *;
%* @param _cstReturn - required - The macro variable that contains the return     *;
%*            value as set by this macro.                                         *;
%*            Default: _cst_rc                                                    *;
%* @param _cstReturnMsg - required - The macro variable that contains the return  *;
%*            message as set by this macro.                                       *;
%*            Default: _cst_rcmsg                                                 *;
%*                                                                                *;
%* @since 1.7                                                                     *;
%* @exposure external                                                             *;

%macro cstutilxptwrite(
  _cstSourceLibrary=, 
  _cstOutputFolder=,
  _cstOptions=,
  _cstReturn=_cst_rc,
  _cstReturnMsg=_cst_rcmsg
  ) / des='CST: Create XPT files from SAS Data Sets';

  %local 
    _cstSrcMacro
    _cstDatasets
    _cstCounter 
    _cstRandom
    dsid
    ;

  %let _cstSrcMacro=&SYSMACRONAME;
  %let _cstRandom=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
  
  %***************************************************;
  %*  Check _cstReturn and _cstReturnMsg parameters  *;
  %***************************************************;
  %if (%length(&_cstReturn)=0) or (%length(&_cstReturnMsg)=0) %then
  %do;
    %* We are not able to communicate other than to the LOG;
    %put [CSTLOG%str(MESSAGE).&sysmacroname] ERR%str(OR): %str
      ()macro parameters _CSTRETURN and _CSTRETURNMSG can not be missing.;
    %goto exit_macro;
  %end;

  %if (%eval(not %symexist(&_cstReturn))) %then %global &_cstReturn;
  %if (%eval(not %symexist(&_cstReturnMsg))) %then %global &_cstReturnMsg;

  %*************************************************;
  %*  Set _cstReturn and _cstReturnMsg parameters  *;
  %*************************************************;
  %let &_cstReturn=0;
  %let &_cstReturnMsg=;

  %************************;
  %* Parameter checking   *;
  %************************;

  %if %sysevalf(%superq(_cstSourceLibrary)=, boolean) %then
  %do;
    %* Rule: _cstSourceLibrary must be specified  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=_cstSourceLibrary must be specified.;
    %goto exit_error;
  %end;

  %if %sysevalf(%superq(_cstOutputFolder)=, boolean) %then
  %do;
    %* Rule: _cstOutputFolder must be specified  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=_cstOutputFolder must be specified.;
    %goto exit_error;
  %end;

  %if %sysfunc(libref(&_cstSourceLibrary)) %then
  %do;
    %* Rule: If _cstSourceLibrary is specified, it must exist  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=The libref _cstSourceLibrary=&_cstSourceLibrary has not been pre-allocated.;
    %goto exit_error;
  %end;

  %if %sysfunc(filename(_cstDir,&_cstOutputFolder)) ne 0
    %then %put %sysfunc(sysmsg());
  %if not %sysfunc(fexist(&_cstDir)) %then
  %do;
    %* Rule: folder _cstOutputFolder must exist  *;
    %let &_cstReturn = 1;
    %let &_cstReturnMsg = Specified folder _cstOutputFolder=&_cstOutputFolder does not exist;
    %goto exit_error;
  %end;

  %************************;
  %* Loop through library *;
  %************************;

  DATA _null_;
  length mvname $8;
    SET sashelp.vtable(where=(upcase(libname)="%upcase(&_cstSourceLibrary)")) end=end;
    i+1;
    mvname="ds"||left(put(i,2.));
    call symputx(mvname,kcompress(klowcase(memname)));
    if end then call symputx('_cstDatasets',kleft(put(_n_,2.)));
  run;
  
  %do _cstCounter=1 %to &_cstDatasets;
    
    %if %sysfunc(libname(xpt&_cstRandom, &_cstOutputFolder/&&ds&_cstCounter...xpt, xport)) ne 0
      %then %put %sysfunc(sysmsg());
    %* libname xpt&_cstRandom xport "&_cstOutputFolder/&&ds&_cstCounter...xpt";
    proc copy in=&_cstSourceLibrary OUT=xpt&_cstRandom &_cstOptions; 
      select &&ds&_cstCounter;
    run;
    %* libname xpt&_cstRandom clear;
    %if %sysfunc(libname(xpt&_cstRandom)) ne 0
      %then %put %sysfunc(sysmsg());

  %end;

  %****************************;
  %*  Handle any errors here  *;
  %****************************;
%exit_error:

  %if %length(&&&_cstReturnMsg)>0 %then
    %put ERR%STR(OR): [CSTLOG%str(MESSAGE).&_cstSrcMacro] &&&_cstReturnMsg;

%exit_macro:

%mend cstutilxptwrite;