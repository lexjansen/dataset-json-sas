%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";

options mprint;

%macro expand(xptin=, xptout=, libout=, domain=, idvar=USUBJID, factor=);

  %local _random_ _variables_ _varlen;
  
  %let _random_=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  libname xpti&_random_ xport "&xptin";
  libname xpto&_random_ xport "&xptout";

  %local _SaveOptions dataset_label;

  %let _SaveOptions = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options compress=Yes reuse=Yes;

  proc copy in=xpti&_random_ out=&libout;
    select &domain;
  run;

  %let _varlen = %cstutilgetattribute(_cstDataSetName=&libout..&domain, _cstVarName=&idvar, _cstAttribute=VARLEN);                                    
  
  proc sql noprint;
    select name into :_variables_ separated by ' '
    from dictionary.columns
    where libname=upcase("&libout") and memtype="DATA" and memname="%upcase(&domain)"
    ;
  quit;


  %let dataset_label=%cstutilgetattribute(_cstDataSetName=&libout..&domain, _cstAttribute=LABEL);
  %put &=dataset_label;
  
  data work.&domain._in_&_random_;
    retain &_variables_;
    length &idvar $ %eval(&_varlen + 4);
    set &libout..&domain;
  run;

  data &libout..&domain;
    retain &_variables_;
    length &idvar $ %eval(&_varlen + 4);
    set &domain._in_&_random_;
    if 0=1;
  run;

  %do i=1 %to &factor;

    data &domain._add_&_random_ (drop=__i);
      length &idvar $ %eval(&_varlen + 4);
      retain &_variables_;
      set &domain._in_&_random_;
        __i = put(&i, z4.);
        &idvar=cats(&idvar, __i);
    run;

    proc append base=&libout..&domain data=&domain._add_&_random_;
    run;

  %end;

  %if %sysevalf(%superq(dataset_label)=, boolean)=0 %then %do;
    proc datasets library=&libout nolist;
       modify &domain(label="&dataset_label");
    quit;
  %end;

  proc copy in=&libout out=xpto&_random_;
    select &domain;
  run;

  proc delete data=work.&domain._in_&_random_ work.&domain._add_&_random_;
  run;

  %* Restore options;
  options &_SaveOptions;
  
  libname xpti&_random_ clear;
  libname xpto&_random_ clear;

%mend expand;


options compress=No reuse=No;

%let _domain_=lb;
%let _random_=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

%put %sysfunc(dcreate(sas&_random_, %sysfunc(pathname(work))));

libname xptout "&root/test_big_xpt";
libname sasout "%sysfunc(pathname(work))/sas&_random_";

%expand(
  xptin=&root/data/sdtm/&_domain_..xpt, 
  xptout=%sysfunc(pathname(xptout))/&_domain_..xpt, 
  domain=&_domain_,  
  libout=work,
  idvar=USUBJID,
  factor=15
  );

%write_datasetjson(
  xptpath=%sysfunc(pathname(xptout))/&_domain_..xpt,
  jsonpath=%sysfunc(pathname(xptout))/&_domain_..json,
  datasetJSONVersion=1.0.0,
  usemetadata=N
  );

%read_datasetjson(
  jsonpath=%sysfunc(pathname(xptout))/&_domain_..json,
  dataoutlib=sasout,
  dropseqvar=Y
  );

  %utl_comparedata(
    baselib=work,
    complib=sasout,
    dsname=&_domain_,
    compareoptions=%str(listall criterion=0.00000001 method=absolute)
  );

proc delete data=work.&_domain_ sasout.&_domain_;
run;

libname sasout clear;
libname xptout clear;
  
