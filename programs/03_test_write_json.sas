%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";

%let FileOID=%str(www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0);

%let StudyOID=%str(TDF_ADaM.ADaMIG.1.1);
%let MetaDataVersionOID=%str(MDV.TDF_ADaM.ADaMIG.1.1);

%get_dirtree(dir=%sysfunc(pathname(dataadam)), outds=work.dirtree_adam);

data _null_;
  length datasetname $64 jsonpath $512 fileoid $128 code $2048;
  set work.dirtree_adam(where=(ext="xpt" and dir=0));
    datasetname=scan(filename, 1, ".");
    jsonpath=cats("&root/json_out/adam/", datasetname, ".json");
    fileoid=cats("&FileOID", "/", "%sysfunc(date(), is8601da.)", "/", datasetname);
    code=cats('%nrstr(%write_datasetjson('
      /* , 'dataset=dataadam.', name, ',' */
      , 'dataset=', ','
      , 'xptpath=', fullpath,','
      , 'jsonpath=', jsonpath, ','
      , 'usemetadata=Y,'
      , 'metadatalib=metaadam,'
      , "_FileOID=", fileoid, ","
      , "_Originator=CDISC ADaM MSG Team", ","
      , "_SourceSystem=Sponsor System,"
      , "_SourceSystemVersion=1.0,"
      , "_studyOID=&StudyOID,"
      , "_MetaDataVersionOID=&MetaDataVersionOID,"
      , "_MetaDataRef=https://metadata.location.org/TDF_ADaM_ADaMIG11/define.xml"
    ,');)');
    call execute(code);
run;

proc delete data=work.dirtree_adam;
run;



%let StudyOID=%str(cdisc.com/CDISCPILOT01);
%let MetaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);

%get_dirtree(dir=%sysfunc(pathname(datasdtm)), outds=dirtree_sdtm);

data _null_;
  length datasetname $64 jsonpath $512 fileoid $128 code $2048;
  set dirtree_sdtm(where=(ext="xpt" and dir=0));
    datasetname=scan(filename, 1, ".");
    jsonpath=cats("&root/json_out/sdtm/", datasetname, ".json");
    fileoid=cats("&FileOID", "/", "%sysfunc(date(), is8601da.)", "/", datasetname);
    code=cats('%nrstr(%write_datasetjson('
      /* , 'dataset=datasdtm.', name, ',' */
      , 'dataset=', ','
      , 'xptpath=', fullpath,','
      , 'jsonpath=', jsonpath, ','
      , 'usemetadata=Y,'
      , 'metadatalib=metasdtm,'
      , "_FileOID=", fileoid, ","
      , "_AsOfDateTime=2023-05-31T00:00:00, "
      , "_Originator=CDISC SDTM MSG Team,"
      , "_SourceSystem=Sponsor System,"
      , "_SourceSystemVersion=1.0,"
      , "_studyOID=&StudyOID,"
      , "_MetaDataVersionOID=&MetaDataVersionOID,"
      , "_MetaDataRef=https://metadata.location.org/CDISCPILOT01/define.xml"
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