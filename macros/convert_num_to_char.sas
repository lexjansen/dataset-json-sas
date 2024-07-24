%macro convert_num_to_char(ds=, outds=, varlist=);

  %local _varlist _variable _outds _random _words _i;
  
  %if not %sysfunc(exist(&ds)) %then %do;
    %put ER%str(ROR): [&sysmacroname] Dataset &ds does not exist.;
    %goto exit_macro;
  %end;   
  
  %let _random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));
  %let _words = %sysfunc(countw(&varlist, %str(' ')));
  %let _outds = &outds;
  %if %sysevalf(%superq(outds)=, boolean) %then %let _outds = &ds;

  proc contents data=&ds noprint out=work._contents_&_random(keep=libname memname name varnum);
  run;

  proc sql noprint;
    select name into :_variables separated by ' '
      from work._contents_&_random
    order by varnum;
  quit;
  
  %put NOTE: &=_variables;
  
  %let _varlist=;
  %do _i = 1 %to &_words;
    %let _variable = %scan(&varlist, &_i);
    %if %cstutilcheckvarsexist(_cstDataSetName=&ds, _cstVarList=&_variable)=0
      %then %put WAR%str(NING): [&sysmacroname] Variable &_variable does not exist in dataset &ds..;
      %else %do;
        %if %cstutilgetattribute(_cstDataSetName=&ds, _cstVarName=&_variable, _cstAttribute=VARTYPE) eq N
          %then %let _varlist = &_varlist &_variable;
          %else %put WAR%str(NING): [&sysmacroname] Variable &_variable is not a numerical variable;
      %end;  
  %end; 
  %let _words = %sysfunc(countw(&_varlist, %str(' ')));
  %put NOTE: &=_words &=_varlist; 

  %if %sysevalf(%superq(_variables)=, boolean) %then %do;
    %if %sysevalf(%superq(_outds)=, boolean)=0 %then %do;
      data &outds;
        set &ds;
      run;   
    %end;
  %end;
  %else %do;
    data &_outds;
      retain &_variables;
      length &_varlist $32;
    set &ds(rename=(%do _i = 1 %to &_words;%scan(&_varlist, &_i)=_%scan(&_varlist, &_i) %str ( )%end;));
      %do _i = 1 %to &_words;
        %let _variable = %scan(&_varlist, &_i);
        if not missing(_&_variable) then &_variable = strip(put(_&_variable, best32.));
                                    else &_variable = "";
        drop _&_variable;
      %end;  
    run;
  %end;
  
  
  proc delete data=work._contents_&_random;
  run;
  
  %exit_macro:

%mend convert_num_to_char;



/*
%convert_num_to_char(ds=sashelp.classzz, outds=work.class, varlist=namez name weight height);
%convert_num_to_char(ds=sashelp.class, outds=work.class, varlist=namez name weight height);
proc contents data=sashelp.class varnum;
run;
proc print data=sashelp.class;
  format weight height best.;
run;  
proc contents data=work.class varnum;
run;
proc print data=work.class;
run;  
*/