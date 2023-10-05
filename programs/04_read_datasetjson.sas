%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%util_gettree(
  dir=&project_folder/json_out/adam, 
  outds=work.dirtree_adam, 
  where=%str(ext="json" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_adam)=0 %then %do;
  %put WAR%str(NING): No JSON files to read in directory &root/json_out/adam.;
%end;  

proc datasets lib=metainad nolist kill; 
quit; 
run;
  
data _null_;
  length code $2048;
  set work.dirtree_adam;
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'datalib=outadam, ',
                'dropseqvar=Y, ',
                'savemetadata=Y, ',
                'metadatalib=metainad',
              ');)');
    call execute(code);
run;

proc delete data=work.dirtree_adam;
run;


%util_gettree(
  dir=&project_folder/json_out/sdtm, 
  outds=work.dirtree_sdtm, 
  where=%str(ext="json" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_sdtm)=0 %then %do;
  %put WAR%str(NING): No JSON files to read in directory &root/json_out/sdtm.;
%end;  

proc datasets lib=metainsd nolist kill; 
quit; 
run;
  
data _null_;
  length code $2048;
  set work.dirtree_sdtm;
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'datalib=outsdtm, ',
                'dropseqvar=Y, ',
                'savemetadata=Y, ',
                'metadatalib=metasdtm',
              ');)');
    call execute(code);
run;

proc delete data=work.dirtree_sdtm;
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname outadam clear;
libname outsdtm clear;
*/
