%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%let _fileOID=%str(www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0);
%let _studyOID=%str(TDF_ADaM.ADaMIG.1.1);
%let _metaDataVersionOID=%str(MDV.TDF_ADaM.ADaMIG.1.1);

%util_gettree(
  dir=&project_folder/data/adam_xpt, 
  outds=work.dirtree_adam, 
  where=%str(ext="xpt" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_adam)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(dataadam).;
%end;  

data _null_;
  length datasetname $64 jsonpath $512 fileoid $128 code $2048;
  set work.dirtree_adam;
    datasetname=scan(filename, 1, ".");
    jsonpath=cats("&project_folder/json_out/adam/", datasetname, ".json");
    fileoid=cats("&_fileOID", "/", "%sysfunc(date(), is8601da.)", "/", datasetname);
    code=cats('%nrstr(%write_datasetjson('
                      , 'dataset=dataadam.', datasetname, ','
                      /* , 'xptpath=', fullpath,',' */
                      , 'jsonpath=', jsonpath, ','
                      , 'usemetadata=N,'
                      , 'metadatalib=metaadam,'
                      , "fileOID=", fileoid, ","
                      , "asOfDateTime=2023-05-31T00:00:00, "
                      , "originator=CDISC ADaM MSG Team", ","
                      , "sourceSystem=Sponsor System,"
                      , "sourceSystemVersion=1.0,"
                      , "studyOID=&_studyOID,"
                      , "metaDataVersionOID=&_metaDataVersionOID,"
                      , "metaDataRef=define.xml"
                    ,');)');
    call execute(code);
run;

proc delete data=work.dirtree_adam;
run;


%let _studyOID=%str(cdisc.com/CDISCPILOT01);
%let _metaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);

%util_gettree(
  dir=&project_folder/data/sdtm_xpt, 
  outds=work.dirtree_sdtm, 
  where=%str(ext="xpt" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_sdtm)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(datasdtm).;
%end;  

data _null_;
  length datasetname $64 jsonpath $512 fileoid $128 code $2048;
  set work.dirtree_sdtm;
    datasetname=scan(filename, 1, ".");
    jsonpath=cats("&project_folder/json_out/sdtm/", datasetname, ".json");
    fileoid=cats("&_fileOID", "/", "%sysfunc(date(), is8601da.)", "/", datasetname);
    code=cats('%nrstr(%write_datasetjson('
                      /* , 'dataset=datasdtm.', name, ',' */
                      , 'xptpath=', fullpath,','
                      , 'jsonpath=', jsonpath, ','
                      , 'usemetadata=Y,'
                      , 'metadatalib=metasdtm,'
                      , "fileOID=", fileoid, ","
                      , "asOfDateTime=2023-05-31T00:00:00, "
                      , "originator=CDISC SDTM MSG Team,"
                      , "sourceSystem=Sponsor System,"
                      , "sourceSystemVersion=1.0,"
                      /* , "studyOID=&_studyOID," */
                      /* , "metaDataVersionOID=&_metaDataVersionOID," */
                      , "metaDataRef=define.xml"
                    ,');)');
    call execute(code);
run;

proc delete data=work.dirtree_sdtm;
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname dataadam clear;
libname datasdtm clear;
*/
