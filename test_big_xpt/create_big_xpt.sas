%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";

%macro expand(
  xptin=,           /* Path to the XPT file used as input  */
  xptout=,          /* Path to the XPT filoe to be created */
  libout=,          /* Library where SAS dataset will be created */
  dataset=,         /* Name of the SAS dataset */
  idvar=USUBJID,    /* Character Variable that will be updated by adding the iteration in z4.*/
  factor=           /* Factor with wich the XPT size will be multiplied */
  );

  %local _random_ _variables_ _varlen;
  
  %let _random_=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  libname xpti&_random_ xport "&xptin";
  libname xpto&_random_ xport "&xptout";

  %local _SaveOptions dataset_label;

  %let _SaveOptions = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options compress=Yes reuse=Yes;

  proc copy in=xpti&_random_ out=&libout;
    select &dataset;
  run;

  %let _varlen = %cstutilgetattribute(_cstDataSetName=&libout..&dataset, _cstVarName=&idvar, _cstAttribute=VARLEN);                                    
  
  proc sql noprint;
    select name into :_variables_ separated by ' '
    from dictionary.columns
    where libname=upcase("&libout") and memtype="DATA" and memname="%upcase(&dataset)"
    ;
  quit;


  %let dataset_label=%cstutilgetattribute(_cstDataSetName=&libout..&dataset, _cstAttribute=LABEL);
  %put &=dataset_label;
  
  data work.&dataset._in_&_random_;
    retain &_variables_;
    length &idvar $ %eval(&_varlen + 4);
    set &libout..&dataset;
  run;

  data &libout..&dataset;
    retain &_variables_;
    length &idvar $ %eval(&_varlen + 4);
    set &dataset._in_&_random_;
    if 0=1;
  run;

  options nonotes;
  %do i=1 %to &factor;

    data &dataset._add_&_random_ (drop=__i);
      length &idvar $ %eval(&_varlen + 4);
      retain &_variables_;
      set &dataset._in_&_random_;
          __i = put(&i, z4.);
        %if &i gt 1 %then %do;
          &idvar=cats(&idvar, __i);
        %end;
    run;

    proc append base=&libout..&dataset data=&dataset._add_&_random_;
    run;

  %end;
  options notes;

  %if %sysevalf(%superq(dataset_label)=, boolean)=0 %then %do;
    proc datasets library=&libout nolist;
       modify &dataset(label="&dataset_label");
    quit;
  %end;

  proc copy in=&libout out=xpto&_random_;
    select &dataset;
  run;

  proc delete data=work.&dataset._in_&_random_ work.&dataset._add_&_random_;
  run;

  %* Restore options;
  options &_SaveOptions;
  
  libname xpti&_random_ clear;
  libname xpto&_random_ clear;

%mend expand;



%let _dataset_=lb;
%let _random_=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

%put %sysfunc(dcreate(sas&_random_, %sysfunc(pathname(work))));

libname xptout "&root/test_big_xpt";
libname sasout "%sysfunc(pathname(work))/sas&_random_";

%expand(
  xptin=&root/data/sdtm/&_dataset_..xpt, 
  xptout=%sysfunc(pathname(xptout))/&_dataset_..xpt, 
  dataset=&_dataset_,  
  libout=work,
  idvar=USUBJID,
  factor=1939
  );

%write_datasetjson(
  xptpath=%sysfunc(pathname(xptout))/&_dataset_..xpt,
  jsonpath=%sysfunc(pathname(xptout))/&_dataset_..json,
  datasetJSONVersion=1.0.0,
  usemetadata=N
  );

%read_datasetjson(
  jsonpath=%sysfunc(pathname(xptout))/&_dataset_..json,
  datalib=sasout,
  dropseqvar=Y
  );


proc compare base=work.lb compare=sasout.lb criterion=0.00000001 method=absolute;
run;

proc delete data=work.&_dataset_ sasout.&_dataset_;
run;

libname sasout clear;
libname xptout clear;
  
