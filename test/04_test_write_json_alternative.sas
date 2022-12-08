%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";


/* Find the names of the datasets */
proc sql noprint;
  create table members 
  as select upcase(memname) as name
  from dictionary.tables
  where libname="DATAADAM" and memtype="DATA"
  ;
quit;


data _null_;
  length code $400 jsonfile $200;
  set members;
  name=lowcase(name);
  jsonfile=cats("&root/json_out/adam/", name, ".json");
  code=cats('%nrstr(%write_json(',
              'dataset=dataadam.', name, ', ', 
              'jsonfile=', jsonfile, ', ',
              'usemetadata=1, ',
              'metadatalib=metaadam',
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

%let StudyOID=%str(cdisc.com/CDISCPILOT01);
%let MetaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);


data _null_;
  length code $400 jsonfile $200;
  set members;
  name=lowcase(name);
  jsonfile=cats("&root/json_out/sdtm/", name, ".json");
  code=cats('%nrstr(%write_json(',
              'dataset=datasdtm.', name, ', ', 
              'jsonfile=', jsonfile, ', ',
              'usemetadata=0, ',
              'metadatalib=metasdtm, ',
              "_studyOID=&StudyOID, ",
              "_MetaDataVersionOID=&MetaDataVersionOID",
            ');)');
  call execute(code);
run;


proc delete data=members;
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname dataadam clear;
libname datasdtm clear;
*/