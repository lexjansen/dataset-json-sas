%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;

%include "&root/test/config.sas";


%let model=adam;
libname data "&root/data/&model";


%let _File=%sysfunc(pathname(data))/adae.xpt;
libname xptFile xport "&_File";
proc copy in=xptFile out=work;
run;

data work.adaedt(label="Adverse Events with DateTime");
  retain USUBJID TRTSDT TRTSDTC TRTSDTM TRTSDTMC 
                 TRTEDT TRTEDTC TRTEDTM TRTEDTMC 
                 ASTDT  ASTDTC  ASTDTM  ASTDTMC;
  length TRTSDTC TRTEDTC ASTDTC TRTSDTMC TRTEDTMC ASTDTMC $32;
  format TRTSDT  TRTEDT  ASTDT  date10.  TRTSDTM  TRTEDTM  ASTDTM datetime22.2;
  set work.adae(keep=USUBJID TRTSDT TRTEDT ASTDT);
  TRTSDTC = strip(put(TRTSDT, E8601DA10.));
  TRTEDTC = strip(put(TRTEDT, E8601DA10.));
  ASTDTC = strip(put(ASTDT, E8601DA10.));
  
  TRTSDTM = DHMS(TRTSDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.01));
  TRTSDTMC = strip(put(TRTSDTM, E8601DT24.2));
  TRTEDTM = DHMS(TRTEDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.01));
  TRTEDTMC = strip(put(TRTEDTM, E8601DT24.2));
  ASTDTM = DHMS(ASTDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.01));
  ASTDTMC = strip(put(ASTDTM, E8601DT24.2));
run;

options ls=max;

data work.metadata_tables;
  name="ADAEDT";
  OID="IG.ADAEDT";
  label="Adverse Events Analysis Dataset (update)";  
  output;
run;
  
proc contents noprint varnum 
  data=work.adaedt 
  out=work.metadata_columns(keep=varnum memname name type length label format rename=(memname=dataset_name type=sas_type format=displayformat));
run;

proc sort data=work.metadata_columns;
  by varnum;
run;
  
data work.metadata_columns(drop=sas_type varnum);
  retain OID name label json_datatype xml_datatype length;
  length OID $128 json_datatype $32;
  set work.metadata_columns;
  OID = cats("IT", ".", "ADAEDT", ".", upcase(name));
  if sas_type=1 then json_datatype="float";
                else json_datatype="string"; 
  xml_datatype = json_datatype;
  if index(displayformat, ".")=0 then displayformat=cats(displayformat, ".");
  if displayformat="DATE." then displayformat="E8601DA10.";
  if displayformat="DATETIME." then displayformat="E8601DT24.2";
run;

%write_datasetjson(
  dataset=work.adaedt, 
  jsonpath=adaedt.json, 
  usemetadata=1, 
  metadatalib=work, 
  _studyOID=%str(CDISCPILOT01), 
  _MetaDataVersionOID=%str(CDISC.ADaM.2.1)
  );

libname data ".";
options mlogic symbolgen;
  
%read_datasetjson(
  jsonpath=adaedt.json, 
  dataoutlib=data, 
  usemetadata=1,
  metadatalib=work
  );

proc compare base=work.adaedt comp=data.adaedt listall;
run;