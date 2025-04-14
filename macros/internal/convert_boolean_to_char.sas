%macro convert_boolean_to_char(ds=, outds=, varlist=);

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
        %if %cstutilgetattribute(_cstDataSetName=&ds, _cstVarName=&_variable, _cstAttribute=VARTYPE) eq N
          %then %let _varlist = &_varlist &_variable;
          %else %put WAR%str(NING): [&sysmacroname] Variable &_variable is not a numerical variable.;
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
    %if %sysevalf(%superq(outds)=, boolean)=0 %then %do;
      data &outds;
        set &ds;
      run;   
    %end;
  %end;
  %else %do;
    data &_outds;
      retain &_variables;
      length &_varlist $3;
    set &ds(rename=(%do _i = 1 %to &_words;%scan(&_varlist, &_i)=_%scan(&_varlist, &_i) %str ( )%end;));
      %do _i = 1 %to &_words;
        %let _variable = %scan(&_varlist, &_i);
        &_variable = "";
        if _&_variable = 1 then &_variable = "Yes";
          else if _&_variable = . then &_variable = "";
            else if _&_variable = 0 then &_variable = "No";
             else putlog 'WAR' 'NING:' " [&sysmacroname] " _n_= &_variable.= _&_variable.= "must be 0, 1 or missing.";
        drop _&_variable;
      %end;  
    run;
  %end;
  
  
  proc delete data=work._contents_&_random;
  run;
  
  %exit_macro:

%mend convert_boolean_to_char;


/*
data class;
   set sashelp.class;
   bool = (age > 13);
   if _n_=3 then bool = 777;
   if _n_=4 then bool = .;
run;   

proc contents data=work.class varnum;
run;
proc print data=work.class;
run;  

%convert_boolean_to_char(ds=work.classzzz, outds=work.class1, varlist=namez name bool);
%convert_boolean_to_char(ds=work.class, outds=work.class1, varlist=namez name bool);
proc contents data=work.class1 varnum;
run;
proc print data=work.class1;
run;  
*/