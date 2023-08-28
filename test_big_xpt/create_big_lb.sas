%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;

%include "&root/programs/config.sas";

%macro expand(factor);
  
  %local _SaveOptions dataset_label;

  %let _SaveOptions = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options compress=Yes reuse=Yes;

  proc copy in=xptFileI out=work;
  run;

  %let dataset_label=%cstutilgetattribute(_cstDataSetName=work.lb, _cstAttribute=LABEL);

  data lb_in;
    retain studyid domain usubjid;
    length usubjid $16;
    set lb;
  run;    

  data lb;
    retain studyid domain usubjid;
    length usubjid $16;
    set lb;
    if 0=1;
  run;
    
  %do i=1 %to &factor;

    data lb_add (drop=__i);
      length usubjid $16;
      retain studyid domain usubjid;
      set lb_in;
        __i = put(&i, z5.);
        usubjid=cats(usubjid, "-", __i);
    run;
    
    proc append base=lb data=lb_add;
    run;

  %end;

  %if %sysevalf(%superq(dataset_label)=, boolean)=0 %then %do;
    proc datasets library=work nolist;
       modify lb(label="&dataset_label");
    quit;
  %end;
     
  proc copy in=work out=xptFileO;
    select lb;
  run;

  proc delete data=work.lb_in work.lb_add;
  run;

  %* Restore options;
  options &_SaveOptions; 

%mend expand;




options compress=No reuse=No;

%let datasetJSONVersion=1.0.0;

%let _File_i=lb.xpt;
%let _File_o=lb.xpt;

libname data "&root/test_big_xpt";
libname data2 "&root/test_big_xpt";
libname sdtm "&root/data/sdtm" access=readonly;

libname xptFileI xport "%sysfunc(pathname(sdtm))/&_File_i";
libname xptFileO xport "%sysfunc(pathname(data))/&_File_o";


%expand(1500);

%write_datasetjson(
  xptpath=%sysfunc(pathname(data))/&_File_i, 
  jsonpath=%sysfunc(pathname(data))/lb.json, 
  usemetadata=N, 
  metadatalib=work
  );

%read_datasetjson(
  jsonpath=%sysfunc(pathname(data))/lb.json, 
  dataoutlib=data, 
  dropseqvar=Y
  );
  
  %utl_comparedata(
    baselib=work, 
    complib=data, 
    dsname=lb, 
    compareoptions=%str(listall criterion=0.00000001 method=absolute)
  );
  
proc delete data=work.lb;
run;  

