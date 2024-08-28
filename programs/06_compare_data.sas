%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


ods listing close;
ods html5 path="&project_folder/programs" file="07_compare_data_detail_&today_iso8601..html";
title01 "Compare Detail - &now_iso8601";

/* Compare ADaM datasets */
/* Get the names of the SAS datasets */
proc sql noprint;
  create table work.members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATAADAM" and memtype="DATA"
  ;
quit;

%if %cstutilnobs(_cstDataSetName=members)=0 %then %do;
  %put WAR%str(NING): No datasets to compare.;
%end;  

%create_template(type=COMPARE_RESULTS, out=results.dataset_compare_results);

data _null_;
  length code $400;
  set work.members;
  name=lowcase(name);
  code=cats('%nrstr(%util_comparedata(',
                      'baselib=dataadam, ',
                      'complib=outadam, ',
                      'dsname=', name, ', ',
                      'compareoptions=%str(criterion=0.000000000001 method=absolute), ',
                      'resultds=results.dataset_compare_results, ',
                      'detaillevel=2',
                  ');)');
  call execute(code);
run;


/* Compare SDTM datasets */
/* Get the names of the SAS datasets */
proc sql noprint;
  create table work.members 
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
  set work.members;
  name=lowcase(name);
  code=cats('%nrstr(%util_comparedata(',
                      'baselib=datasdtm, ',
                      'complib=outsdtm, ',
                      'dsname=', name, ', ',
                      'compareoptions=%str(criterion=0.00000000001 method=absolute), ',
                      'resultds=results.dataset_compare_results, ',
                      'detaillevel=2',
                  ');)');
  call execute(code);
run;


/* Compare SEND datasets */
/* Get the names of the SAS datasets */
proc sql noprint;
  create table work.members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATASEND" and memtype="DATA"
  ;
quit;

%if %cstutilnobs(_cstDataSetName=members)=0 %then %do;
  %put WAR%str(NING): No datasets to compare.;
%end;  

data _null_;
  length code $400;
  set work.members;
  name=lowcase(name);
  code=cats('%nrstr(%util_comparedata(',
                      'baselib=datasend, ',
                      'complib=outsend, ',
                      'dsname=', name, ', ',
                      'compareoptions=%str(criterion=0.00000000001 method=absolute), ',
                      'resultds=results.dataset_compare_results, ',
                      'detaillevel=2',
                  ');)');
  call execute(code);
run;

ods html5 close;
ods html5 path="&project_folder/programs" file="07_compare_data_summary_&today_iso8601..html";

  proc print data=results.dataset_compare_results label;
    title01 "Compare Summary - &now_iso8601";
  run;
  
ods html5 close;
ods listing;
title01;


proc delete data=work.members;
run;

/*
libname dataadam clear;
libname outadam clear;
libname datasdtm clear;
libname outsdtm clear;
libname datasend clear;
libname outsend clear;
*/