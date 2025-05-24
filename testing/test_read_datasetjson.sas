%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%* This is needed to be able to run Python;
%* Update to your own locations           ;
options set=MAS_PYPATH="&project_folder/venv/Scripts/python.exe";
options set=MAS_M2PATH="%sysget(SASROOT)/tkmas/sasmisc/mas2py.py";

%let fcmplib=work;
%include "&project_folder/macros/validate_datasetjson.sas";

options cmplib=&fcmplib..datasetjson_funcs;

%global python_installed;
%check_python();


%let _SaveOptions = %sysfunc(getoption(dlcreatedir));
options dlcreatedir;

libname metadata "&project_folder/testing/metadata";
libname data "&project_folder/testing";

%macro testit(test, json_file, json_schema=&project_folder/schema/dataset.schema1-1-0.json);

  %put #### TEST &test;
  
  data _null_;
    length datetime $32 result_code 8 result_character result_path $255 json_file json_schema $512;
    json_schema = "&json_schema";
    json_file = "&json_file";
    call missing(datetime, result_code, result_character, result_path);
    call validate_datasetjson(json_file, json_schema, datetime, result_code, result_character, result_path);
    if result_code = 1 then putlog 'ERR' 'OR:' result_code= json_file= result_character= result_path=;
  run;

  %read_datasetjson(
    jsonpath=&json_file,
    datalib=data,
    savemetadata=Y,
    metadatalib=metadata
  );

%mend testit;

%* columns and rows missing;
%testit(1 - Attribute columns missing and rows missing, 
        &project_folder/testing/testfiles/datasetjson_01.json);

%* columns missing;
%testit(2 - Attribute columns missing, 
        &project_folder/testing/testfiles/datasetjson_02.json);

%* rows missing;
%testit(3 - Attribute rows missing, 
        &project_folder/testing/testfiles/datasetjson_03.json);

proc datasets lib=work;
quit;

%* rows missing and itemGroupOID missing;
%testit(4 - Attributes itemGroupOID and rows missing, 
        &project_folder/testing/testfiles/datasetjson_04.json);

%* itemGroupOID missing;
%testit(5 - Attribute itemGroupOID missing, 
        &project_folder/testing/testfiles/datasetjson_05.json);

proc compare data=data.dm_test5 compare=datasdtm.dm;
run;

%* Restore options;
options &_SaveOptions;
 
/*
libname metadata clear;
libname data clear;
*/  