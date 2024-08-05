%macro convert_iso_to_num(ds=, outds=, varlist=);

  %local _varlist _variable _outds _random _words _i;
  
  %if not %sysfunc(exist(&ds)) %then %do;
    %put ER%str(ROR): [&sysmacroname] Dataset &ds does not exist.;
    %goto exit_macro;
  %end;   

  %let _random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
  %let _words = %sysfunc(countw(&varlist, %str(' ')));
  %let _outds = &outds;
  %if %sysevalf(%superq(outds)=, boolean) %then %let _outds = &ds;
 
  %let _varlist=;
  %do _i = 1 %to &_words;
    %let _variable = %scan(&varlist, &_i);
    %if %cstutilcheckvarsexist(_cstDataSetName=&ds, _cstVarList=&_variable)=0
      %then %put WAR%str(NING): [&sysmacroname] Variable &_variable does not exist in dataset &ds..;
      %else %do;
        %if %cstutilgetattribute(_cstDataSetName=&ds, _cstVarName=&_variable, _cstAttribute=VARTYPE) eq C
          %then %let _varlist = &_varlist &_variable;
          %else %put WAR%str(NING): [&sysmacroname] &_variable is not a character variable;
      %end;  
  %end;  
  %let _words = %sysfunc(countw(&_varlist, %str(' ')));

  proc contents data=&ds noprint out=work._contents_&_random(keep=libname memname name varnum);
  run;

  proc sql noprint;
    select name into :_variables separated by ' '
      from work._contents_&_random
    order by varnum;
  quit;
  
  %put &=_variables;
  
  
  %if %sysevalf(%superq(_varlist)=, boolean) %then %do;
    %if %sysevalf(%superq(_outds)=, boolean)=0 %then %do;
      data &outds;
        set &ds;
      run;   
    %end;
  %end;
  %else %do;
    data &outds;
      retain &_variables;
      length &_varlist 8;
    set &ds(rename=(%do _i = 1 %to &_words;%scan(&_varlist, &_i)=_%scan(&_varlist, &_i) %str ( )%end;));
      %do _i = 1 %to &_words;
        %let _variable = %scan(&_varlist, &_i);
        &_variable = input(_&_variable, ?? anydtdte32.);
        if missing(&_variable) and not(missing(_&_variable))
          then putlog 'WAR' 'NING:' " [&sysmacroname] Conversion failed:" _n_= _&_variable= &_variable=;
        /* format &_variable E8601DA.; */
        drop _&_variable;
      %end;  
    run;
  %end;
    
  proc delete data=work._contents_&_random;
  run;
  
  %exit_macro:

%mend convert_iso_to_num;



/*
options mprint;
%include "convert_num_to_char.sas";
%let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

filename map&_random temp;
filename js1 temp;
filename js2 temp;

proc contents data=sashelp.class varnum;
run;
proc print data=sashelp.class;
run;  

data work.class;
  set sashelp.class;
  if _n_ = 2 then name="";
  if _n_ > 10 then height = height * (1 + rand('uniform'));
  if _n_ = 3 then height=.;
run;

%* exchange height as a number;
proc json out=js1 pretty;
  export work.class;
run;

data _null_;
infile js1;
input;
put _infile_;
run;

libname json&_random json map=map&_Random automap=create fileref=js1 noalldata ordinalcount=none;

proc compare base=work.class compare=json&_Random..sastabledata_class;
title "Transferred in JSON as numeric";
run;  

%convert_num_to_char(ds=work.class, outds=work.class1, varlist=weight height);

proc contents data=work.class1 varnum;
run;
proc print data=work.class1;
run;  

%* exchange height as a character;
proc json out=js2 pretty;
  export work.class1;
run;

data _null_;
infile js2;
input;
put _infile_;
run;

libname json&_random clear;
libname json&_random json map=map&_Random automap=create fileref=js2 noalldata ordinalcount=none;
 
%convert_char_to_num(ds=json&_Random..sastabledata_class1, outds=class_char, varlist=weight height);

proc compare base=work.class compare=work.class_char;
title "Transferred in JSON as character";
run;  


%convert_char_to_num(ds=work.classzzz, outds=work.class2, varlist=height weight);
%convert_char_to_num(ds=work.class1, outds=work.class2, varlist=height weight);
proc contents data=work.class2 varnum;
run;
proc print data=work.class2;
  format height weight best.;
run;

proc compare base=work.class compare=work.class2;
  title "Transferred back to numeric";
run;    
*/