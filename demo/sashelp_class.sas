%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";

%write_datasetjson(
    dataset=sashelp.class,
    jsonpath=&root/demo/class.json,
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
    jsonpath=class.json,
    datalib=work,
    dropseqvar=Y
);

proc compare base=sashelp.class compare=work.class;
run;
