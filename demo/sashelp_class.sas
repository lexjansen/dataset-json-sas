%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%write_datasetjson(
    dataset=sashelp.class,
    jsonpath=&project_folder/demo/class.json,
    fileOID=,
    asOfDateTime=,
    originator=,
    sourceSystem=,
    sourceSystemVersion=,
    studyOID=,
    metaDataVersionOID=,
    metaDataRef=
    );

%read_datasetjson(
    jsonpath=&project_folder/demo/class.json,
    datalib=work,
    dropseqvar=Y
);

proc compare base=sashelp.class compare=work.class listall;
run;
