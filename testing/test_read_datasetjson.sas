%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%* clinicalData and referenceData keys missing;
%read_datasetjson(
  jsonpath=&project_folder/testing/testfiles/read_datasetjson_01.json,
  datalib=work,
  dropseqvar=Y
);

%* items key missing;
%read_datasetjson(
  jsonpath=&project_folder/testing/testfiles/read_datasetjson_02.json,
  datalib=work,
  dropseqvar=Y
);

%* itemData key missing;
%read_datasetjson(
  jsonpath=&project_folder/testing/testfiles/read_datasetjson_03.json,
  datalib=work,
  dropseqvar=Y
);

%* itemGroupData key missing;
%read_datasetjson(
  jsonpath=&project_folder/testing/testfiles/read_datasetjson_04.json,
  datalib=work,
  dropseqvar=Y
);
