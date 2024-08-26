%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

/* Convert ADaM v5 or v8 XPT files to SAS datasets */
%util_gettree(
  dir=&project_folder/data/adam_xpt,
  outds=work.dirtree_adam,
  where=%str(ext="xpt" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_adam)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(dataadam)).;
%end;

data _null_;
  length code $2048;
  set work.dirtree_adam;
    datasetname=scan(filename, 1, ".");
    code=cats('%nrstr(%xpt2loc('
                      , "filespec='", fullpath, "',"
                      , 'libref=dataadam,'
                      , 'memlist=', datasetname
                    ,');)');
    call execute(code);
run;

/* Convert SDTM XPT v5 or v8 files to SAS datasets */
%util_gettree(
  dir=&project_folder/data/sdtm_xpt,
  outds=work.dirtree_sdtm,
  where=%str(ext="xpt" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_sdtm)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(datasdtm)).;
%end;


data _null_;
  length code $2048;
  set work.dirtree_sdtm;
    datasetname=scan(filename, 1, ".");
    code=cats('%nrstr(%xpt2loc('
                      , "filespec='", fullpath, "',"
                      , 'libref=datasdtm,'
                      , 'memlist=', datasetname
                    ,');)');
    call execute(code);
run;

/* Convert SEND XPT v5 or v8 files to SAS datasets */
%util_gettree(
  dir=&project_folder/data/send_xpt,
  outds=work.dirtree_send,
  where=%str(ext="xpt" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_send)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(datasend)).;
%end;


data _null_;
  length code $2048;
  set work.dirtree_send;
    datasetname=scan(filename, 1, ".");
    code=cats('%nrstr(%xpt2loc('
                      , "filespec='", fullpath, "',"
                      , 'libref=datasend,'
                      , 'memlist=', datasetname
                    ,');)');
    call execute(code);
run;

/*
libname dataadam clear;
libname datasdtm clear;
libname datasend clear;
*/
