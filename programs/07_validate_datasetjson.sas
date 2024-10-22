%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%let json_schema=&project_folder/schema/dataset.schema1-1-0.json;
%let json_folder=&project_folder/json_out;

/*
This program assumes that your SAS environment is able to run Python objects.
Check the programs/config.sas file for the Python configuration.

Python objects require environment variables to be set before you can use Python objects in your SAS environment.
If the environment variables have not been set, or if they have been set incorrectly,
SAS returns an error when you publish your Python code. Environment variable related errors can look like these examples:

ERROR: MAS_PYPATH environment variable is undefined.
ERROR: The executable C:\file-path\python.exe cannot be located
       or is not a valid executable.

Also, this program assumes that your Python environment has the following packages:
  - json
  - jsonschema

More information:
  Using PROC FCMP Python Objects:
  https://documentation.sas.com/doc/en/pgmsascdc/9.4_3.5/lecompobjref/p18qp136f91aaqn1h54v3b6pkant.htm

  Configuring SAS to Run the Python Language:
  https://go.documentation.sas.com/doc/en/bicdc/9.4/biasag/n1mquxnfmfu83en1if8icqmx8cdf.htm
*/

%* This is needed to be able to run Python;
%* Update to your own locations           ;
options set=MAS_PYPATH="&project_folder/venv/Scripts/python.exe";
options set=MAS_M2PATH="%sysget(SASROOT)/tkmas/sasmisc/mas2py.py";

%let fcmplib=work;
%include "&project_folder/macros/validate_datasetjson.sas";

options cmplib=&fcmplib..datasetjson_funcs;




%global python_installed;
%check_python();

/* Get the paths of the ADaM JSON files */
%util_gettree(
  dir=&json_folder/adam,
  outds=work.dirtree_adam,
  where=%str(ext="json" and dir=0),
  keep=fullpath
);

data work.dirtree_adam;
  set work.dirtree_adam(rename=fullpath=json_file);
  length result_code 8 result_character result_path $255 json_file json_schema $512;
  retain json_schema "&json_schema";
  call missing(result_code, result_character, result_path);
  result_character = "Validation can not be executed";
  %if &python_installed %then %do;
    call validate_datasetjson(json_file, json_schema, result_code, result_character, result_path);
    if result_code = 1 then putlog 'ERR' 'OR:' json_file= result_character= result_path=;
  %end;
run;

/* Get the path of the SDTM JSON files */
%util_gettree(
  dir=&json_folder/sdtm,
  outds=work.dirtree_sdtm,
  where=%str(ext="json" and dir=0),
  keep=fullpath
);

data work.dirtree_sdtm;
  set work.dirtree_sdtm(rename=fullpath=json_file);
  length result_code 8 result_character result_path $255 json_file json_schema $512;
  retain json_schema "&json_schema";
  call missing(result_code, result_character, result_path);
  result_character = "Validation can not be executed";
  %if &python_installed %then %do;
    call validate_datasetjson(json_file, json_schema, result_code, result_character, result_path);
    if result_code = 1 then putlog 'ERR' 'OR:' json_file= result_character;
  %end;  
run;

/* Get the path of the SEND JSON files */
%util_gettree(
  dir=&json_folder/send,
  outds=work.dirtree_send,
  where=%str(ext="json" and dir=0),
  keep=fullpath
);

data work.dirtree_send;
  set work.dirtree_send(rename=fullpath=json_file);
  length result_code 8 result_character result_path $255 json_file json_schema $512;
  retain json_schema "&json_schema";
  call missing(result_code, result_character, result_path);
  result_character = "Validation can not be executed";
  %if &python_installed %then %do;
    call validate_datasetjson(json_file, json_schema, result_code, result_character, result_path);
    if result_code = 1 then putlog 'ERR' 'OR:' json_file= result_character;
  %end;
run;


/* Report the results */
%create_template(type=VALIDATION_RESULTS, out=results.schema_validation_results);
data results.schema_validation_results;
  set results.schema_validation_results work.dirtree_adam work.dirtree_sdtm work.dirtree_send;
  json_file = translate(json_file, '/', '\');
run;

ods listing close;
ods html5 path="&project_folder/programs" file="08_validate_datasetjson_results_&today_iso8601..html";

  proc print data=results.schema_validation_results label;
    title01 "Validation Results - &now_iso8601";
  run;

ods html5 close;
ods listing;
title01;

proc delete data=work.dirtree_adam work.dirtree_sdtm work.dirtree_send;
run;
