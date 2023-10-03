%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";


ods listing close;
ods html5 file="&root/programs/05_compare_data_detail.html";
title01 "Compare Detail";

/* Find the names of the datasets */
proc sql noprint;
  create table members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATAADAM" and memtype="DATA"
  ;
quit;

%if %cstutilnobs(_cstDataSetName=members)=0 %then %do;
  %put WAR%str(NING): No datasets to compare.;
%end;  

%create_template(type=RESULTS, out=work.results);

data _null_;
  length code $400;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%utl_comparedata(',
              'baselib=dataadam, ',
              'complib=outadam, ',
              'dsname=', name, ', ',
              'compareoptions=%str(criterion=0.00000001 method=absolute), ',
              'resultds=work.results, ',
              'detailall=Y',
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

%if %cstutilnobs(_cstDataSetName=members)=0 %then %do;
  %put WAR%str(NING): No datasets to compare.;
%end;  

data _null_;
  length code $400;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%utl_comparedata(',
              'baselib=datasdtm, ',
              'complib=outsdtm, ',
              'dsname=', name, ', ',
              'compareoptions=%str(criterion=0.00000001 method=absolute), ',
              'resultds=work.results, ',
              'detailall=Y',
            ');)');
  call execute(code);
run;


proc delete data=members;
run;


ods html5 close;
ods html5 file="&root/programs/05_compare_data_summary.html";

proc print data=work.results;
  title01 "Compare Summary";
run;
  
ods html5 close;
ods listing;
title01;

/*
libname dataaadam clear;
libname outadam clear;
libname datasdtm clear;
libname outsdtm clear;
*/