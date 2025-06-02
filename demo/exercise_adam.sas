%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

/* Choose a dataset */
%let dataset=adsl;
filename jsonfile "&project_folder/json_out/adam/&dataset..json";

/* Convert ADaM v5 XPT files to SAS datasets */
%cstutilxptread(
  _cstSourceFolder=&project_folder/data/adam_xpt,
  _cstOutputLibrary=dataadam,
  _cstExtension=XPT,
  _cstOptions=datecopy
  );

proc contents data=dataadam.&dataset varnum;
run;

/* Create metadata from ADaM Define-XML */
%create_metadata_from_definexml(
   definexml=&project_folder/data/adam_xpt/define.xml,
   metadatalib=metaadam
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

/* Some manual ADaM data type updates */
data metaadam.metadata_columns;
  set metaadam.metadata_columns;

  dataType = put(xml_datatype, $datatyp.);
  if dataType = "string" then json_length = length;

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON. */

  if dataset_name in ('ADLBC', 'ADLBH') and
     name in ('PCHG', 'AVAL', 'BASE', 'CHG', 'PCHG', 'A1LO', 'A1HI', 'R2A1LO', 'R2A1HI', 'BR2A1LO', 'BR2A1HI', 'ALBTRVAL', 'LBSTRESN')
     then do;
      dataType='decimal';
      targetDataType='decimal';
    end;

  /* Updates for numeric dataes */
  if not missing(displayformat) then do;
    if substr(strip(reverse(upcase(name))), 1, 2) = "TD" then do;
      dataType = "date";
      targetDataType = "integer";
    end;
    if substr(strip(reverse(upcase(name))), 1, 3) = "MTD" then do;
      dataType = "datetime";
      targetDataType = "integer";
    end;
    if substr(strip(reverse(upcase(name))), 1, 2) = "MT" then do;
      dataType = "time";
      targetDataType = "integer";
    end;
  end;

run;



/* Create Dataset-JSON from the dataset */
%let _fileOID = %str(www.cdisc.org/StudyMSGv1/1/Define-XML_2.1.0)/%sysfunc(date(), is8601da.)/&dataset;
%let _studyOID = %str(TDF_ADaM.ADaMIG.1.1);
%let _metaDataVersionOID = %str(MDV.TDF_ADaM.ADaMIG.1.1);
%let _originator = %str(CDISC ADaM MSG Team);

%write_datasetjson(
    dataset=dataadam.&dataset,
    jsonfref=jsonfile,
    usemetadata=Y,
    metadatalib=metaadam,
    fileOID=&_fileOID,
    originator=&_originator,
    sourceSystem=,
    sourceSystemVersion=,
    studyOID=&_studyOID,
    metaDataVersionOID=&_metaDataVersionOID,
    metaDataRef=define.xml,
    %* In a submission, you would typicaly use pretty=NOPRETTY ;
    pretty=NOPRETTY
    );


/* Create SAS dataset from Dataset-JSON */
%read_datasetjson(
    jsonfref=jsonfile,
    datalib=outadam,
    savemetadata=Y,
    metadatalib=metasvad
    );

/* Compare original and created dataset */
ods listing close;
ods html5 path="&project_folder/demo" file="compare_data_adam.html";

  proc compare base=dataadam.&dataset compare=outadam.&dataset criterion=0.000000000001 method=absolute listall;
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
