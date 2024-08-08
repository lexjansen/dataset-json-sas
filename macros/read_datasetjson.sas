%macro read_datasetjson(
  jsonpath=,
  datalib=,
  dropseqvar=Y,
  savemetadata=Y,
  metadatalib=work
  ) / des = 'Read a Dataset-JSON file to a SAS dataset';

  %local _Missing
         _SaveOptions1
         _SaveOptions2
         _Random
         metadata_study_columns metadata_tables_columns metadata_columns_columns
         _items_ _itemdata_ _itemgroupdata_ ItemGroupOID _ItemGroupName
         dslabel dsname variables rename label length format
         _decimal_variables _iso8601_variables;

  %let _Random=%sysfunc(putn(%sysevalf(%sysfunc(ranuni(0))*10000,floor),z4.));

  %* Save options;
  %let _SaveOptions1 = %sysfunc(getoption(dlcreatedir));
  options dlcreatedir;

  %******************************************************************************;
  %* Parameter checks                                                           *;
  %******************************************************************************;

  %* Check for missing parameters ;
  %let _Missing=;
  %if %sysevalf(%superq(jsonpath)=, boolean) %then %let _Missing = &_Missing jsonpath;
  %if %sysevalf(%superq(datalib)=, boolean) %then %let _Missing = &_Missing datalib;
  %if %sysevalf(%superq(dropseqvar)=, boolean) %then %let _Missing = &_Missing dropseqvar;
  %if %sysevalf(%superq(savemetadata)=, boolean) %then %let _Missing = &_Missing savemetadata;

  %if %length(&_Missing) gt 0
    %then %do;
      %put ERR%str(OR): [&sysmacroname] Required macro parameter(s) missing: &_Missing;
      %goto exit_macro;
    %end;

  %if %sysevalf(%superq(datalib)=, boolean)=0 %then %do;
    %if (%sysfunc(libref(&datalib)) ne 0 ) %then %do;
        %put ERR%str(OR): [&sysmacroname] datalib library &datalib has not been assigned.;
        %goto exit_macro;
    %end;  
  %end;

  %if %sysevalf(%superq(metadatalib)=, boolean)=0 %then %do;
    %if (%sysfunc(libref(&metadatalib)) ne 0 ) %then %do;
        %put ERR%str(OR): [&sysmacroname] metadatalib library &metadatalib has not been assigned.;
        %goto exit_macro;
    %end;  
  %end;

  %* Rule: dropseqvar has to be Y or N  *;
  %if "%substr(%upcase(&dropseqvar),1,1)" ne "Y" and "%substr(%upcase(&dropseqvar),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter dropseqvar=&dropseqvar must be Y or N.;
    %goto exit_macro;
  %end;

  %* Rule: savemetadata has to be Y or N  *;
  %if "%substr(%upcase(&savemetadata),1,1)" ne "Y" and "%substr(%upcase(&savemetadata),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter savemetadata=&savemetadata must be Y or N.;
    %goto exit_macro;
  %end;

%******************************************************************************;
  %* End of parameter checks                                                    *;
  %******************************************************************************;


  %* Save options;
  %let _SaveOptions2 = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options compress=Yes reuse=Yes;

  filename json&_Random "&jsonpath";
  filename mapmeta "../maps/map_meta.map";
  filename map&_Random "%sysfunc(pathname(work))/map_%scan(&jsonpath, -2, %str(.\/)).map";
  libname out_&_Random "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/))";

  libname json&_Random json map=map&_Random automap=create fileref=json&_Random
          %if "%substr(%upcase(&savemetadata),1,1)" ne "Y" %then noalldata; ordinalcount=none;
  proc copy in=json&_Random out=out_&_Random;
  run;

  %* Restore options;
  options &_SaveOptions2;

  proc sql noprint;
    select datasetJSONVersion into :datasetJSONVersion separated by ' '
      from out_&_Random..root;
  quit;
  
  %put &=datasetJSONVersion;
  
  %* Rule: allowed versions *;
  %if %substr(&datasetJSONVersion,1,3) ne %str(1.1) %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Attribute datasetJSONVersion=&datasetJSONVersion is invalid. Allowed values: 1.1.x.;
    %goto exit_macro;
  %end;

  /* Find the names of the dataset that were created */
  %let _itemgroupdata_=root;  
  %let _items_=columns;
  %let _itemdata_=rows;

  %if not %sysfunc(exist(out_&_Random..&_items_)) %then %do;
    %put ERR%str(OR): [&sysmacroname] Attribute "columns" is missing.;
    %goto exit_macro;
  %end;

  %let _itemGroupName=;
  proc sql noprint;
    select name into :_itemGroupName separated by ' '
      from out_&_Random..root;
  quit;

  %if %sysevalf(%superq(_itemGroupName)=, boolean) %then %do;
      %put ERR%str(OR): [&sysmacroname] No dataset name attribute has been defined in the Dataset-JSON file.;
      %goto exit_macro;
  %end;

  data out_&_Random..&_items_;
    set out_&_Random..&_items_;
    dataset_name = "&_ItemGroupName";
  run;
    

  proc sql noprint;
    select name into :variables separated by ' '
      from out_&_Random..&_items_;
    select cats("element", monotonic(), '=', name) into :rename separated by ' '
      from out_&_Random..&_items_;
    select cats(name, '=', quote(strip(label))) into :label separated by ' '
      from out_&_Random..&_items_
      where not(missing(label));
    select catt(name, ' $', length) into :length separated by ' '
      from out_&_Random..&_items_
      where datatype="string" and (not(missing(length)));
  quit;

  %put &=variables;
  %put &=rename;
  %put &=label;
  %put &=length;

  %let dslabel=;
  %let dsname=;
  proc sql noprint;
    %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_itemgroupdata_, _cstVarList=label) %then %do;
      select label, name into :dslabel trimmed, :dsname trimmed
        from out_&_Random..&_itemgroupdata_
    %end;
    %else %do;
      select name into :dsname trimmed
        from out_&_Random..&_itemgroupdata_
    %end;    
    ;
  quit;

  %if "%substr(%upcase(&savemetadata),1,1)" eq "Y" %then %do;


    %let ItemGroupOID=;
    %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_itemgroupdata_, _cstVarList=ItemGroupOID) %then %do;
      proc sql noprint;
        select ItemGroupOID into :ItemGroupOID trimmed
          from out_&_Random..&_itemgroupdata_;
      quit;
    %end;
    %else %put ERR%str(OR): [&sysmacroname] Attribute "itemGroupOID" is missing.;
      
    %if not %sysfunc(exist(&metadatalib..metadata_study)) %then %create_template(type=STUDY, out=&metadatalib..metadata_study);;
    %if not %sysfunc(exist(&metadatalib..metadata_tables)) %then %create_template(type=TABLES, out=&metadatalib..metadata_tables);;
    %if not %sysfunc(exist(&metadatalib..metadata_columns)) %then %create_template(type=COLUMNS, out=&metadatalib..metadata_columns);;

    %let metadata_study_columns=;
    proc sql noprint;
      select name into :metadata_study_columns separated by ' '
        from dictionary.columns
      where upcase(libname)="%upcase(&metadatalib)" and
           upcase(memname)="METADATA_STUDY"
     ;
    quit ;


    %if %sysfunc(exist(out_&_Random..sourceSystem))
    %then %do;
      data work._metadata_study;
        merge out_&_Random..root out_&_Random..sourceSystem(rename=(name=sourceSystem version=sourceSystemVersion));
      run;
    %end;
    %else %do;
      data work._metadata_study;
        set out_&_Random..root;
      run;
    %end;
      
    data &metadatalib..metadata_study(keep=&metadata_study_columns);
      set &metadatalib..metadata_study 
          work._metadata_study(
            rename=(
              datasetJSONCreationDateTime = creationDateTime
              dbLastModifiedDateTime = modifiedDateTime
            )
          );
    run;

    proc delete data=work._metadata_study;
    run;

    %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_itemgroupdata_, _cstVarList=isReferenceData) 
    %then %do;
      %if %cstutilgetattribute(_cstDataSetName=out_&_Random..&_itemgroupdata_, _cstVarName=isReferenceData, _cstAttribute=VARTYPE) eq N 
      %then %do;
        data out_&_Random..&_itemgroupdata_;
          length isReferenceData $3;
          set out_&_Random..&_itemgroupdata_(rename=(isReferenceData = _isReferenceData));
            if _isReferenceData = 1 then isReferenceData = "Yes";
            if _isReferenceData = 0 then isReferenceData = "No";
            drop _isReferenceData;
        run;  
      %end;
    %end;

    %let metadata_tables_columns=;
    proc sql noprint;
      select name into :metadata_tables_columns separated by ' '
        from dictionary.columns
      where upcase(libname)="%upcase(&metadatalib)" and
           upcase(memname)="METADATA_TABLES"
     ;
    quit ;

    data &metadatalib..metadata_tables(keep=&metadata_tables_columns);
      set &metadatalib..metadata_tables out_&_Random..&_itemgroupdata_(in=inigd);
      if inigd then do;
        oid = "&ItemGroupOID";
        call symputx('_ItemGroupName', name);
      end;
    run;

    data work.&_items_;
      set out_&_Random..&_items_;
      order = _n_;
    run;

    data &metadatalib..metadata_columns(%if %substr(%upcase(&DropSeqVar),1,1) eq Y %then where=(upcase(name) ne "ITEMGROUPDATASEQ"););
      set &metadatalib..metadata_columns work.&_items_(rename=(itemOID=OID) in=init);
      if init then do;
        dataset_name = "&_ItemGroupName";
        %if %substr(%upcase(&DropSeqVar),1,1) eq Y %then %do;
          order = order - 1;   
        %end;  
        json_length = length;
        length = .;
      end;
    run;

    proc delete data=work.&_items_;
    run;

  %end; /* savemetadata eq "Y" */
  

  /* get formats from Dataset-JSON metadata, but only when the displayformat variable exists */
  %let format=;
  %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_items_, _cstVarList=displayformat) %then %do;
    proc sql noprint;
      select catx(' ', name, strip(displayformat)) into :format separated by ' '
          from out_&_Random..&_items_
          where (not(missing(displayformat)) and (displayformat ne ".")) /* and (type in ('integer' 'float' 'double' 'decimal')) */;
    quit;
  %end;
  
  %put &=format;

  %if not %sysfunc(exist(out_&_Random..&_itemdata_)) %then %do;
    %put NOTE: [&sysmacroname] Attribute "rows" is missing.;
    %goto exit_macro_no_rows;
  %end;

  proc copy in=out_&_Random out=&datalib;
    select &_itemdata_;
  run;

  proc datasets library=&datalib noprint nolist nodetails;
    %if %sysfunc(exist(&datalib..&dsname)) %then %do; delete &dsname; %end;
    change &_itemdata_ = &dsname;
    modify &dsname %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str((label = %sysfunc(quote(%nrbquote(&dslabel)))));;
      rename &rename;
      label &label;
  quit;
  

  %******************************************************************************;
  %let _decimal_variables=;
  %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_items_, _cstVarList=targetdatatype) %then %do;
    proc sql noprint;
      select name into :_decimal_variables separated by ' '
        /* from &metadatalib..metadata_columns */
        from out_&_Random..&_items_
        where (datatype='decimal' and targetdatatype='decimal') and
              (upcase(dataset_name) = upcase("&dsname"));  
    quit;
  %end;

  %if %sysevalf(%superq(_decimal_variables)=, boolean)=0 %then %do;
    %put NOTE: [&sysmacroname] &datalib..&dsname: character variables converted to numeric: &_decimal_variables;
    %convert_char_to_num(ds=&datalib..&dsname, outds=&datalib..&dsname, varlist=&_decimal_variables);

    proc datasets library=&datalib noprint nolist nodetails;
      modify &dsname %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str((label = %sysfunc(quote(%nrbquote(&dslabel)))));;
        label &label;
    quit;

  %end;  

  %let _iso8601_variables=;
  %if %cstutilcheckvarsexist(_cstDataSetName=out_&_Random..&_items_, _cstVarList=targetdatatype) %then %do;
    proc sql noprint;
      select name into :_iso8601_variables separated by ' '
        /* from &metadatalib..metadata_columns */
        from out_&_Random..&_items_
        where (datatype in ('datetime' 'date' 'time')) and (targetdatatype = 'integer') and
              (upcase(dataset_name) = upcase("&dsname"));  
    quit;
  %end;

  %if %sysevalf(%superq(_iso8601_variables)=, boolean)=0 %then %do;

    %put NOTE: [&sysmacroname] &datalib..%upcase(&dsname), character ISO 8601 variables converted to numeric: &_iso8601_variables;
    %convert_iso_to_num(ds=&datalib..&dsname, outds=&datalib..&dsname, varlist=&_iso8601_variables);

    proc datasets library=&datalib noprint nolist nodetails;
      modify &dsname %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str((label = %sysfunc(quote(%nrbquote(&dslabel)))));;
        label &label;
    quit;

  %end;  

%******************************************************************************;
  
  

  /* Update lengths */
  proc sql noprint;
    select catt(d.name, ' $', i.length) into :length separated by ' '
      from dictionary.columns d,
           out_&_Random..&_items_ i
    where upcase(libname)="%upcase(&datalib)" and
         upcase(memname)="%upcase(&dsname)" and
         d.name = i.name and
         d.type="char" and (not(missing(i.length))) and (i.length gt d.length)
   ;
  quit ;

  data &datalib..&dsname(
      %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str(label = %sysfunc(quote(%nrbquote(&dslabel))));
      %if %substr(%upcase(&DropSeqVar),1,1) eq Y %then drop=ITEMGROUPDATASEQ;
    );
    retain &variables;
    length &length;
    %if %sysevalf(%superq(format)=, boolean)=0 %then format &format;;
    set &datalib..&dsname;
  run;



  /*  Validate datatypes and lengths */
  proc sql ;
   create table column_metadata
   as select
    case upcase(d.name)
      when "ITEMGROUPDATASEQ" then d.name
      else cats("IT.", "%upcase(&dsname).", d.name)
    end as OID,
    d.name,
    d.type as datatype,
    i.datatype as type,
    d.length as sas_length,
    i.length,
    d.format
   from dictionary.columns d,
        out_&_Random..&_items_ i
   where upcase(libname)="%upcase(&datalib)" and
         upcase(memname)="%upcase(&dsname)" and
         d.name = i.name
   ;
  quit ;

  data _null_;
    set column_metadata;
    if DataType="char" and not (type in ('string' 'datetime' 'date' 'time')) 
      then putlog "WAR" "NING: [&sysmacroname] TYPE ISSUE: dataset=datalib..&dsname " OID= name= DataType= type=;
    if DataType="num" and not (type in ('integer' 'double' 'float' 'decimal' 'datetime' 'date' 'time')) 
      then putlog "WAR" "NING: [&sysmacroname] TYPE ISSUE: dataset=datalib..&dsname " OID= name= DataType= type=;
    if DataType="char" and not(missing(length)) and (length lt sas_length) 
      then putlog "WAR" "NING: [&sysmacroname] LENGTH ISSUE: dataset=datalib..&dsname " OID= name= length= sas_length=;
  run;

  proc delete data=work.column_metadata;
  run;

  %exit_macro_no_rows:
  
  libname json&_Random clear;
  filename json&_Random clear;
  filename map&_Random clear;
  filename mapmeta clear;

  proc datasets nolist lib=out_&_Random kill;
  quit;

  %put %sysfunc(filename(fref,%sysfunc(pathname(out_&_Random))));
  %put %sysfunc(fdelete(&fref));
  libname out_&_Random clear;


  %exit_macro:

  %* Restore options;
  options &_SaveOptions1;

%mend read_datasetjson;
