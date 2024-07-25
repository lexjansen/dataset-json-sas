%macro add_formats(metadata=, datalib=, condition=, format=);
  
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
    if &condition then put "attrib " name "format=" &format ";";
    if end then do;
      put "run;";
      put "quit;";
    end;  
  run;

  data _null_;
    infile initCode catalog;
    input;
    put _infile_;
  run;

  %include initCode;

  proc datasets nolist lib=work;
      delete code / memtype=catalog;
  quit;

  filename initCode clear;

%mend add_formats;
