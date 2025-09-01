%macro create_zero_obs_dataset(
  outlib =,
  dsname =,
  metadata_dataset =,
  datasetlabel = 
  );

  %local _NextCode _random;
  
  %let _random = %sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
  %let _NextCode=code&_random;
  filename &_NextCode CATALOG "work.&_NextCode..nextcode.source";
  %* filename &_NextCode "__code.sas";
  
  
  %*********************************;
  %*  Create the code to run next  *;
  %*********************************;
  data _null_;
    file &_NextCode;
    set &metadata_dataset end=eof;
    by dataset_name notsorted;

    if (first.dataset_name) then 
    do;
      %if %sysevalf(%superq(datasetlabel)=, boolean)=0 %then %do;
        put @3 "data &outlib..&dsname" '(label="' %sysfunc(quote(%nrbquote(&datasetlabel))) '");';
      %end;  
      %else %do;
        put @3 "data &outlib..&dsname;";
      %end;  
      put @5 "attrib";
    end;

    put @7 name;
    put @9 "label='" label +(-1) "'";
    
    if (upcase(datatype)='STRING') then 
    do;
      if missing(length) then length=200;
      put @9 "length=$" length;
    end;
    else 
    do;
      length=8;
      put @9 "length=" length;
    end;

    %if %cstutilcheckvarsexist(_cstDataSetName=&metadata_dataset, _cstVarList=displayformat) %then %do;
      if (displayformat ne '') then 
      do;
        put @9 "format=" displayFormat;
      end;
    %end;
  
    if (last.dataset_name) then 
    do;
      put @5 ';';
      put @5 'stop;';
      put @5 'call missing(of _all_);';
      put @3 'run;' /;
    end;
  run;

  %********************************;
  %*  Include the generated code  *;
  %********************************;
   %include &_NextCode;
   filename &_NextCode;

  proc datasets nolist lib=work;
    delete &_NextCode / mt=catalog;
    quit;
  run;
  
%mend create_zero_obs_dataset;
