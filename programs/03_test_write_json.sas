%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";

%let datasetJSONVersion=1.0.0;
%let FileOID=%str(www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0);

%let StudyOID=%str(TDF_ADaM.ADaMIG.1.1);
%let MetaDataVersionOID=%str(MDV.TDF_ADaM.ADaMIG.1.1);

data _null_;
  length fref $8 name $64 fileoid $128 jsonpath $200 code $2000;
  did = filename(fref,"%sysfunc(pathname(dataadam))");
  did = dopen(fref);
  do i = 1 to dnum(did);
/*    if index(dread(did,i), "sas7bdat") then do; */
    if index(dread(did,i), "xpt") then do;
      name=scan(dread(did,i), 1, ".");
      jsonpath=cats("&root/json_out/adam/", name, ".json");
      fileoid=cats("&FileOID", "/", "%sysfunc(date(), is8601da.)", "/", name);
      code=cats('%nrstr(%write_datasetjson('
                          /* , 'dataset=dataadam.', name, ',' */
                          , 'dataset=', ','
                          , 'xptfile=', "%sysfunc(pathname(dataadam))/", name, ".xpt",','
                          , 'jsonpath=', jsonpath, ','
                          , 'usemetadata=N,'
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
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;


%let StudyOID=%str(cdisc.com/CDISCPILOT01);
%let MetaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);

data _null_;
  length fref $8 name $64 fileoid $128 jsonpath $200 code $2000;
  did = filename(fref,"%sysfunc(pathname(datasdtm))");
  did = dopen(fref);
  do i = 1 to dnum(did);
    if index(dread(did,i), "sas7bdat") then do;
      name=scan(dread(did,i), 1, ".");
      jsonpath=cats("&root/json_out/sdtm/", name, ".json");
      fileoid=cats("&FileOID", "/", "%sysfunc(date(), is8601da.)", "/", name);
      code=cats('%nrstr(%write_datasetjson('
                          , 'dataset=datasdtm.', name, ','
                          , 'xptfile=', ','
                          , 'jsonpath=', jsonpath, ','
                          , 'usemetadata=N,'
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
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname dataadam clear;
libname datasdtm clear;
*/