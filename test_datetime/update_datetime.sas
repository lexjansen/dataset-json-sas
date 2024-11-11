%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%let model=adam;
libname adamdata "&project_folder/data/&model";
libname data "&project_folder/test_datetime";
  

libname xptFile xport "&project_folder/data/adam_xpt/adae.xpt";
proc copy in=xptFile out=work;
run;

data work.adaedt(label="Adverse Events with DateTime");
  retain USUBJID TRTSDT TRTSDTC TRTSDTM TRTSDTMC 
                 TRTEDT TRTEDTC TRTEDTM TRTEDTMC 
                 ASTDT  ASTDTC  ASTDTM  ASTDTMC;
  length TRTSDT TRTSDTM TRTEDT TRTEDTM ASTDT ASTDTM 8 
         TRTSDTC TRTEDTC ASTDTC TRTSDTMC TRTEDTMC ASTDTMC $32;
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
  format TRTSDT  TRTEDT  ASTDT  E8601DA10.  TRTSDTM  TRTEDTM ASTDTM E8601DT24.3;
  TRTSDTC = strip(put(TRTSDT, E8601DA10.));
  TRTEDTC = strip(put(TRTEDT, E8601DA10.));
  ASTDTC = strip(put(ASTDT, E8601DA10.));
  
  TRTSDTM = DHMS(TRTSDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.001));
  TRTSDTMC = strip(put(TRTSDTM, E8601DT24.3));
  TRTEDTM = DHMS(TRTEDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.001));
  TRTEDTMC = strip(put(TRTEDTM, E8601DT24.3));
  ASTDTM = DHMS(ASTDT, rand('integer', 0, 23), rand('integer', 0, 59), round(ranuni(0) * 59, 0.001));
  ASTDTMC = strip(put(ASTDTM, E8601DT24.3));
run;

proc contents data=work.adaedt varnum;
run;
proc print data=work.adaedt(obs=5); 
run;

data work.metadata_tables;
  name="ADAEDT";
  OID="IG.ADAEDT";
  label="Adverse Events Analysis Dataset (update)";  
  output;
run;
  
proc contents data=work.adaedt noprint varnum 
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
  if sas_type=1 then do; json_datatype="float"; targetDataType="integer"; end;
                else json_datatype="string"; 
  xml_datatype = json_datatype;
  if index(displayformat, ".")=0 then displayformat=cats(displayformat, ".");
  * if displayformat="DATE." then displayformat="E8601DA10.";
  * if displayformat="DATETIME." then displayformat="E8601DT24.2";
run;

%write_datasetjson(
  dataset=work.adaedt, 
  jsonpath=%sysfunc(pathname(data))/adaedt.json, 
  usemetadata=N, 
  metadatalib=work, 
  studyOID=%str(CDISCPILOT01), 
  MetaDataVersionOID=%str(CDISC.ADaM.2.1)
  );

%read_datasetjson(
  jsonpath=%sysfunc(pathname(data))/adaedt.json, 
  datalib=data
  );

proc contents data=data.adaedt varnum;
run;
proc print data=data.adaedt(obs=5); 
run;

proc compare base=work.adaedt comp=data.adaedt;
run;