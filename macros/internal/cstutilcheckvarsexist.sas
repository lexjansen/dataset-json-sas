%* Copyright (c) 2022, SAS Institute Inc., Cary, NC, USA.  All Rights Reserved.   *;
%* SPDX-License-Identifier: Apache-2.0                                            *;
%*                                                                                *;
%* cstutilcheckvarsexist                                                          *;
%*                                                                                *;
%* Determines whether a list of variables exists in a data set.                   *;
%*                                                                                *;
%* This macro returns 1 when all variables exist and returns 0 when at least one  *;
%* variable does not exist or when a variable is not a valid SAS name.            *;
%*                                                                                *;
%* If the data set does not exist or cannot be opened, an error occurs.           *;
%*                                                                                *;
%* @param _cstDataSetName - required - The (libname.)memname of the data set.     *;
%*            Default: _last_                                                     *;
%* @param _cstVarList - required - The list of blank-separated variables to check.*;
%* @param  _cstNotExistVarList - optional - An existing macro variable to         *;
%*            contain the variables that could not be found in the data set.      *;
%*                                                                                *;
%* @history 2024-07-24 Made i macro variable local                                *;
%*                                                                                *;
%* @since 1.7                                                                     *;
%* @exposure external                                                             *;

%macro cstutilcheckvarsexist(
  _cstDataSetName=_last_,
  _cstVarList=,
  _cstNotExistVarList=
  ) / des = 'CST: Check if variables exist in data set';
  
  %local i _cstdsid _cstrc _cst_util_exists _cst_util_var _cst_util_noexistlist;
  
  %****************************************************;
  %*  Check for missing parameters that are required  *;
  %****************************************************;
  %if %sysevalf(%superq(_cstDataSetName)=,boolean) or
      %sysevalf(%superq(_cstVarList)=,boolean) %then
  %do;
    %put %str(ER)ROR: [CSTLOG%str(MESSAGE).&sysmacroname] One or more REQUIRED parameters %str
       ()(_cstDataSetName or _cstVarList) are missing.;
    %let _cst_util_noexistlist=.;
    %goto exit_abort;
  %end;

  %let _cstdsid = %sysfunc(open(&_cstDataSetName, I));
   %* Failed to open the data set *;
   %if &_cstdsid = 0
    %then %do;
      %put %sysfunc(sysmsg());
      %let _cst_util_exists=;
      %goto exit_abort;
    %end;
    %else %do;

      %let _cst_util_noexistlist=;
      %do i=1 %to %sysfunc(countw(&_cstVarList, %str( )));
        
         %let _cst_util_var=%kscan(&_cstVarList, &i, %str( ));

         %if %sysfunc(nvalid(&_cst_util_var))=0 %then %do;
           %let _cst_util_noexistlist=&_cst_util_noexistlist &_cst_util_var;
           %put [CSTLOG%str(MESSAGE).&sysmacroname] WAR%str(NING): &_cst_util_var is not a valid SAS variable name.;
         %end;
         %else 
           %if %sysfunc(varnum(&_cstdsid,&_cst_util_var)) lt 1 %then 
             %let _cst_util_noexistlist=&_cst_util_noexistlist &_cst_util_var;
      %end;
      %if %sysevalf(%superq(_cst_util_noexistlist)=, boolean) 
        %then %let _cst_util_exists=1;
        %else %let _cst_util_exists=0;

      %let _cstrc = %sysfunc(close(&_cstdsid));
    %end;
    
    %if %sysevalf(%superq(_cstNotExistVarList)=, boolean)=0 %then %do;
      %if %symexist(&_cstNotExistVarList) %then %let &_cstNotExistVarList=&_cst_util_noexistlist;
    %end;
    
  %exit_abort:
  %*;&_cst_util_exists%*;

%mend cstutilcheckvarsexist;
