%macro add_formats_to_datasets(metadata=, datalib=, condition=, format=);
  
  %if %cstutilnobs(_cstDataSetName=&metadata) le 0 %then %goto exit_macro;
  
    filename initCode CATALOG "work.code._format.source" LRECL=2048;

    data _null_;
      file initCode;
      set &metadata end=end;
      by dataset_name notsorted;
      if _n_=1 then do;
        put "proc datasets library=&datalib nolist memtype=data;";
      end;  
      if first.dataset_name then do;
        put "modify " dataset_name ";";
      end;  
      if &condition then put "attrib " name "format=" &format ";";
      if end then do;
        put "quit;";
        put "run;";
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

  %exit_macro:

%mend add_formats_to_datasets;
