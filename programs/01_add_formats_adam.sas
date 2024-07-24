%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%let metadata=metaadam.metadata_columns;
%let datalib=dataadam;
%let format_attribute = displayFormat;


filename initCode CATALOG "work.code._format.source" LRECL=2048;

data _null_;
  file initCode;
  set &metadata end=end;
  by dataset_name order notsorted;
  if _n_=1 then do;
    put "proc datasets library=&datalib memtype=data;";
  end;  
  if first.dataset_name then do;
    put "modify " dataset_name ";";
  end;  
  if not missing(&format_attribute) then put "attrib " name "format=" &format_attribute ";";
  if end then do;
    put "run;";
    put "quit;";
  end;  
run;

%include initCode;

proc datasets nolist lib=work;
    delete code / memtype=catalog;
quit;

filename initCode clear;
