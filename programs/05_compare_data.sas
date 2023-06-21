%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";


/* Find the names of the datasets */
proc sql noprint;
  create table members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATAADAM" and memtype="DATA"
  ;
quit;


data _null_;
  length code $400;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%utl_comparedata(',
              'baselib=DATAADAM, ',
              'complib=OUTADAM, ',
              'dsname=', name, 
            ');)');
  call execute(code);
run;

/* Find the names of the datasets */
proc sql noprint;
  create table members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATASDTM" and memtype="DATA"
  ;
quit;

data _null_;
  length code $400;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%utl_comparedata(',
              'baselib=DATASDTM, ',
              'complib=OUTSDTM, ',
              'dsname=', name, 
            ');)');
  call execute(code);
run;


proc delete data=members;
run;

/*
libname dataaadam clear;
libname outadam clear;
libname datasdtm clear;
libname outsdtm clear;
*/