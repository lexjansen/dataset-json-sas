%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

filename jsonfile "&project_folder/demo/class.json";

data work.class(label="%cstutilgetattribute(_cstDataSetName=sashelp.class,_cstAttribute=LABEL)");
  label Name="Name" Sex="Sex" Age="Age" Height="Height" Weight="Weight";
  set sashelp.class;
run;  

%write_datasetjson(
    dataset=work.class,
    jsonfref=jsonfile,
    fileOID=,
    originator=,
    sourceSystem=,
    sourceSystemVersion=,
    studyOID=,
    metaDataVersionOID=,
    metaDataRef=
    );

%read_datasetjson(
    jsonfref=jsonfile,
    datalib=work
);

proc compare base=sashelp.class compare=work.class listall;
run;
