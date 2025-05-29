%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

/* Choose a dataset */
%let dataset=ae;
filename jsonfile "&project_folder/json_out/sdtm/&dataset..json";

/* Convert SDTM v5 XPT files to SAS datasets */
%cstutilxptread(
  _cstSourceFolder=&project_folder/data/sdtm_xpt,
  _cstOutputLibrary=datasdtm,
  _cstExtension=XPT,
  _cstOptions=datecopy
  );

proc contents data=datasdtm.&dataset varnum;
run;  

/* Create metadata from SDTM Define-XML */
%create_metadata_from_definexml(
   definexml=&project_folder/data/sdtm_xpt/define.xml,
   metadatalib=metasdtm
   );


/* Map Define-XML datatypes to JSON datatypes */
/* this is a very rough mapping, it does not take decimal into account */
proc format;
  value $datatyp
    text = "string"
    date = "date"
    datetime = "datetime"
    time = "time"
    URI = "string"
    partialDate = "string"
    partialTime = "string"
    partialDatetime = "string"
    durationDatetime = "string"
    intervalDatetime = "string"
    incompleteDatetime = "string"
    incompleteDate = "string"
    incompleteTime = "string"
    integer = "integer"
    float = "float"
    ;
run;

/* Some manual SDTM data type updates */
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;

  dataType = put(xml_datatype, $datatyp.);
  if dataType = "string" then json_length = length;

run;



/* Create Dataset-JSON from the dataset */
%let _fileOID = %str(www.cdisc.org/StudyMSGv2/1/Define-XML_2.1.0)/%sysfunc(date(), is8601da.)/&dataset;
%let _studyOID = %str(Tcdisc.com/CDISCPILOT01);
%let _metaDataVersionOID = %str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);
%let _originator = %str(CDISC SDTM MSG Team);

%write_datasetjson(
    dataset=datasdtm.&dataset,
    jsonfref=jsonfile,
    usemetadata=Y,
    metadatalib=metasdtm,
    fileOID=&_fileOID,
    originator=&_originator,
    sourceSystem=,
    sourceSystemVersion=,
    studyOID=&_studyOID,
    metaDataVersionOID=&_metaDataVersionOID,
    metaDataRef=define.xml,
    %* In a submission, you would typicaly use pretty=NOPRETTY ;
    pretty=PRETTY
    );


/* Create SAS dataset from Dataset-JSON */
%read_datasetjson(
    jsonfref=jsonfile,
    datalib=outsdtm,
    savemetadata=Y,
    metadatalib=metasvad
    );

/* Compare original and created dataset */
ods listing close;
ods html5 path="&project_folder/demo" file="compare_data_sdtm.html";

  proc compare base=datasdtm.&dataset compare=outsdtm.&dataset criterion=0.000000000001 method=absolute listall;
    title01 "PROC COMPARE results - user &SYSUSERID";
  run;

ods html5 close;
ods listing;



%* This is needed to be able to run Python;
%* Update to your own locations           ;
options set=MAS_PYPATH="&project_folder/venv/Scripts/python.exe";
options set=MAS_M2PATH="%sysget(SASROOT)/tkmas/sasmisc/mas2py.py";

%let fcmplib=work;
%include "&project_folder/macros/validate_datasetjson.sas";

options cmplib=&fcmplib..datasetjson_funcs;

%global python_installed;
%check_python();

%if &python_installed %then %do;

  data _null_;
    length datetime $32 result_code 8 result_character result_path $255 json_file json_schema $512;
    json_schema = "&project_folder/schema/dataset.schema1-1-0.json";
    json_file = "%sysfunc(pathname(jsonfile))";
    call missing(datetime, result_code, result_character, result_path);
    call validate_datasetjson(json_file, json_schema, datetime, result_code, result_character, result_path);
    if result_code = 1 then putlog 'ERR' 'OR:' result_code= json_file= result_character= result_path= /;
                       else putlog 'NOTE:' result_code= result_path= json_file= result_character=;
  run;
%end;
