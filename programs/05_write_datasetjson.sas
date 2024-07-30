%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


/* Create Dataset-JSON for ADaM */
%let _fileOID=%str(www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0);
%let _studyOID=%str(TDF_ADaM.ADaMIG.1.1);
%let _metaDataVersionOID=%str(MDV.TDF_ADaM.ADaMIG.1.1);

/* Get the paths of the XPT files */
%util_gettree(
  dir=%sysfunc(pathname(dataadam)),
  outds=work.dirtree_adam,
  where=%str(ext="sas7bdat" and dir=0)
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
                      , 'jsonpath=', jsonpath, ','
                      , 'usemetadata=Y,'
                      , 'metadatalib=metaadam,'
                      , 'datasetJSONVersion=1.1.0,'
                      , "fileOID=", fileoid, ","
                      , "originator=CDISC ADaM MSG Team", ","
                      , "sourceSystem=SAS on &SYSHOSTNAME,"
                      , "sourceSystemVersion=&SYSVLONG4,"
                      /* , "studyOID=&_studyOID," */
                      /* , "metaDataVersionOID=&_metaDataVersionOID," */
                      , "metaDataRef=define.xml"
                    ,');)');
    call execute(code);
run;

proc delete data=work.dirtree_adam;
run;


/* Create Dataset-JSON for SDTM */
%let _fileOID=%str(www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0);
%let _studyOID=%str(cdisc.com/CDISCPILOT01);
%let _metaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);

/* Get the paths of the XPT files */
%util_gettree(
  dir=%sysfunc(pathname(datasdtm)),
  outds=work.dirtree_sdtm,
  where=%str(ext="sas7bdat" and dir=0)
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
                      , 'dataset=datasdtm.', datasetname, ','
                      , 'jsonpath=', jsonpath, ','
                      , 'usemetadata=Y,'
                      , 'metadatalib=metasdtm,'
                      , 'datasetJSONVersion=1.1.0,'
                      , "fileOID=", fileoid, ","
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


/* Create Dataset-JSON for SEND */
%let _fileOID=%str(Covance Laboratories/Study8326556-Define2-XML_2.0.0);
%let _studyOID=%str(8326556);
%let _metaDataVersionOID=%str(CDISC-SEND.3.1);

/* Get the paths of the XPT files */
%util_gettree(
  dir=%sysfunc(pathname(datasend)),
  outds=work.dirtree_send,
  where=%str(ext="sas7bdat" and dir=0)
);

%if %cstutilnobs(_cstDataSetName=work.dirtree_send)=0 %then %do;
  %put WAR%str(NING): No XPT files to read in directory %sysfunc(pathname(datasdtm).;
%end;

data _null_;
  length datasetname $64 jsonpath $512 fileoid $128 code $2048;
  set work.dirtree_send;
    datasetname=scan(filename, 1, ".");
    jsonpath=cats("&project_folder/json_out/send/", datasetname, ".json");
    fileoid=cats("&_fileOID", "/", "%sysfunc(date(), is8601da.)", "/", datasetname);
    code=cats('%nrstr(%write_datasetjson('
                      , 'dataset=datasend.', datasetname, ','
                      , 'jsonpath=', jsonpath, ','
                      , 'usemetadata=Y,'
                      , 'metadatalib=metasend,'
                      , 'datasetJSONVersion=1.1.0,'
                      , "fileOID=", fileoid, ","
                      , "originator=CDISC SEND Team,"
                      , "sourceSystem=Visual Define-XML Editor,"
                      , "sourceSystemVersion=%str(1.0.0-beta.2),"
                      , "studyOID=&_studyOID,"
                      , "metaDataVersionOID=&_metaDataVersionOID,"
                      , "metaDataRef=define.xml"
                    ,');)');
    call execute(code);
run;

proc delete data=work.dirtree_send;
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname metasend clear;
libname dataadam clear;
libname datasdtm clear;
libname datasend clear;
*/
