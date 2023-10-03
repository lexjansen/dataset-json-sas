%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
options mprint;

%include "&root/programs/config.sas";

%let model=adam;
libname adamdata "&root/data/&model";


libname xptFile xport "%sysfunc(pathname(adamdata))/adae.xpt";
proc copy in=xptFile out=work;
run;

data work.adaedt(label="Adverse Events with DateTime");
  retain USUBJID TRTSDT TRTSDTC TRTSDTM TRTSDTMC 
                 TRTEDT TRTEDTC TRTEDTM TRTEDTMC 
                 ASTDT  ASTDTC  ASTDTM  ASTDTMC;
  length TRTSDT TRTSDTM TRTEDT TRTEDTM ASTDT ASTDTM 8 
         TRTSDTC TRTEDTC ASTDTC TRTSDTMC TRTEDTMC ASTDTMC $32;
  format TRTSDT  TRTEDT  ASTDT  date10.  TRTSDTM  TRTEDTM  ASTDTM datetime22.2;
  label TRTSDTC = "Date of First Exposure to Treatment (c)"
        TRTSDTM = "Datetime of First Exp to Treatment"
        TRTSDTMC = "Datetime of First Exp to Treatment (c)"
        TRTEDTC = "Date of Last Exposure to Treatment (c)"
        TRTEDTM = "Datetime of Last Exp to Treatment"
        TRTEDTMC = "Datetime of Last Exp to Treatment (c)"
        ASTDTC = "Analysis Start Date (c)"
        ASTDTM = "Analysis Start Datetime"
        ASTDTMC = "Analysis Start Datetime (c)"
        ;        
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
  retain OID name label json_datatype xml_datatype length keysequence;
  length OID $128 json_datatype $32 keysequence 8;
  set work.metadata_columns;
  keysequence=.;
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
  usemetadata=N, 
  metadatalib=work, 
  studyOID=%str(CDISCPILOT01), 
  MetaDataVersionOID=%str(CDISC.ADaM.2.1)
  );

libname data "&root/test_datetime";
  
%read_datasetjson(
  jsonpath=adaedt.json, 
  datalib=data, 
  dropseqvar=Y
  );

proc compare base=work.adaedt comp=data.adaedt;
run;