%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

libname data "&project_folder/test";

proc datasets lib=data nolist kill; 
quit; 
run;

%read_datasetjson(
  jsonpath=&project_folder/test/ae_utf8.json, 
  datalib=data, 
  savemetadata=Y,
  metadatalib=data
  );
  
%write_datasetjson(
  dataset=data.ae, 
  jsonpath=&project_folder/test/ae_out.json, 
  datasetJSONVersion=1.1.0,
  usemetadata=N, 
  metadatalib=data,
  studyOID=LZZT,
  metaDataVersionOID=CDISC.SDTMIG.3.1.2  
  );

%read_datasetjson(
  jsonpath=&project_folder/test/ae_out.json, 
  datalib=work, 
  savemetadata=Y,
  metadatalib=work
  );

proc compare base=data.ae compare=work.ae;
run;
  