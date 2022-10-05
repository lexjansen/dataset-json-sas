%* cstutilxptread                                                                 *;
%*                                                                                *;
%* Creates SAS data sets from a folder with SAS Version 5 XPORT files.            *;
%*                                                                                *;
%* This macro creates SAS data sets from a folder of SAS version 5 XPORT files.   *;
%*                                                                                *;
%* Notes:                                                                         *;
%*   1. Any librefs referenced in macro parameters must be pre-allocated.         *;
%*   2. All XPT files are located in one folder.                                  *;
%*   3. Existing SAS data sets are overwritten.                                   *;
%*                                                                                *;
%* @macvar _cst_rc Task error status                                              *;
%* @macvar _cst_rcmsg Message associated with _cst_rc                             *;
%*                                                                                *;
%* @param _cstSourceFolder - required - The folder in which the SAS Version 5     *;
%*            XPORT (XPT) files are located.                                      *;
%* @param _cstOutputLibrary - required - The libref of the output data folder/    *;
%*            library in which to create the SAS data files.                      *;
%*            Default: work                                                       *;
%* @param _cstExtension - required - The file extension of the SAS Version 5      *;
%*            XPORT files.                                                        *;
%*            Default: XPT                                                        *;
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

%macro cstutilxptread(
  _cstSourceFolder=,
  _cstOutputLibrary=work,
  _cstExtension=XPT,
  _cstOptions=,
  _cstReturn=_cst_rc,
  _cstReturnMsg=_cst_rcmsg
  ) / des='CST: Create SAS Data Sets from XPT files';

  %local
    _cstSrcMacro
    _cstRandom
    _cstCounter
    _cstXPTFile
    fref
    did
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

  %if %sysevalf(%superq(_cstSourceFolder)=, boolean) %then
  %do;
    %* Rule: _cstSourceFolder must be specified  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=_cstSourceFolder must be specified.;
    %goto exit_error;
  %end;

  %if %sysevalf(%superq(_cstOutputLibrary)=, boolean) %then
  %do;
    %* Rule: _cstOutputLibrary must be specified  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=_cstOutputLibrary must be specified.;
    %goto exit_error;
  %end;

  %if %sysevalf(%superq(_cstExtension)=, boolean) %then
  %do;
    %* Rule: _cstExtension must be specified  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=_cstExtension must be specified.;
    %goto exit_error;
  %end;

  %let rc=%sysfunc(filename(_cstDir,&_cstSourceFolder));
  %if not %sysfunc(fexist(&_cstDir)) %then
  %do;
    %* Rule: folder _cstSourceFolder must exist  *;
    %let &_cstReturn = 1;
    %let &_cstReturnMsg = Specified folder _cstSourceFolder=&_cstSourceFolder does not exist.;
    %goto exit_error;
  %end;

  %if %sysfunc(libref(&_cstOutputLibrary)) %then
  %do;
    %* Rule: If _cstOutputLibrary is specified, it must exist  *;
    %let &_cstReturn=1;
    %let &_cstReturnMsg=The libref _cstOutputLibrary=&_cstOutputLibrary has not been pre-allocated.;
    %goto exit_error;
  %end;

  %************************;
  %* Loop through folder  *;
  %************************;

  %let fref=xpt_&_cstRandom;
  %if %sysfunc(filename(fref, &_cstSourceFolder)) ne 0
    %then %put %sysfunc(sysmsg());
  %if %sysfunc(fileref(&fref)) ne 0
    %then %put %sysfunc(sysmsg());

  %let did = %sysfunc(dopen(&fref));

  %do _cstCounter = 1 %to %sysfunc(dnum(&did));
    %let _cstXPTFile = %sysfunc(dread(&did,&_cstCounter));
    %if %kindex(%upcase(&_cstXPTFile), %upcase(.&_cstExtension)) %then
    %do;

      %if %sysfunc(libname(xpt&_cstRandom, &_cstSourceFolder/&_cstXPTFile, xport)) ne 0
        %then %put %sysfunc(sysmsg());
      proc copy in=xpt&_cstRandom out=&_cstOutputLibrary memtype=data &_cstOptions;
      run;
      %if %sysfunc(libname(xpt&_cstRandom)) ne 0
        %then %put %sysfunc(sysmsg());

    %end;
  %end;

  %if %sysfunc(dclose(&did)) ne 0
    %then %put %sysfunc(sysmsg());
  %if %sysfunc(filename(fref)) ne 0
    %then %put %sysfunc(sysmsg());

  %****************************;
  %*  Handle any errors here  *;
  %****************************;
%exit_error:

  %if %length(&&&_cstReturnMsg)>0 %then
    %put ERR%STR(OR): [CSTLOG%str(MESSAGE).&_cstSrcMacro] &&&_cstReturnMsg;

%exit_macro:

%mend cstutilxptread;
