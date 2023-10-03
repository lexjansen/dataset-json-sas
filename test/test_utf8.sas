%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;

%include "&root/programs/config.sas";

libname data "&root/test";

%read_datasetjson(
  jsonpath=&root/test/ae_utf8.json, 
  datalib=data, 
  dropseqvar=Y,
  metadatalib=data
  );

%write_datasetjson(
  dataset=data.ae, 
  jsonpath=&root/test/ae_out.json, 
  datasetJSONVersion=1.0.0,
  usemetadata=Y, 
  metadatalib=data
  );

%read_datasetjson(
  jsonpath=&root/test/ae_out.json, 
  datalib=work, 
  dropseqvar=Y,
  metadatalib=work
  );

proc compare base=data.ae compare=work.ae;
run;
  