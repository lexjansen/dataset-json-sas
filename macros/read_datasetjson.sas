%macro read_datasetjson(
  jsonpath=,
  dataoutlib=,
  dropseqvar=N,
  metadataoutlib=
  ) / des = 'Read a Dataset-JSON file to a SAS dataset';

  %local _Missing
         _SaveOptions1
         _SaveOptions2
         _Random
         _clinicalreferencedata_ _items_ _itemdata_ _itemgroupdata_ ItemGroupOID _ItemGroupName
         dslabel dsname variables rename label length format;

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
  %if %sysevalf(%superq(dataoutlib)=, boolean) %then %let _Missing = &_Missing dataoutlib;
  %if %sysevalf(%superq(dropseqvar)=, boolean) %then %let _Missing = &_Missing dropseqvar;

  %if %length(&_Missing) gt 0
    %then %do;
      %put ERR%str(OR): [&sysmacroname] Required macro parameter(s) missing: &_Missing;
      %goto exit_macro;
    %end;

  %* Rule: dropseqvar has to be Y or N  *;
  %if "%substr(%upcase(&dropseqvar),1,1)" ne "Y" and "%substr(%upcase(&dropseqvar),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter dropseqvar=&dropseqvar must be Y or N.;
    %goto exit_macro;
  %end;

%******************************************************************************;
  %* End of parameter checks                                                    *;
  %******************************************************************************;


  %* Save options;
  %let _SaveOptions2 = %sysfunc(getoption(compress, keyword)) %sysfunc(getoption(reuse, keyword));
  options compress=Yes reuse=Yes;

  filename json&_Random "&jsonpath";
  filename map&_Random temp;
  libname out_&_Random "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/))";

  libname json&_Random json map=map&_Random automap=create fileref=json&_Random
          %if %sysevalf(%superq(metadataoutlib)=, boolean) %then noalldata; ordinalcount=none;
  proc copy in=json&_Random out=out_&_Random;
  run;

  %* Restore options;
  options &_SaveOptions2;

  /* Find the names of the dataset that were created */

  %let _clinicalreferencedata_=;
  %if %sysfunc(exist(out_&_Random..clinicaldata))
    %then %let _clinicalreferencedata_=out_&_Random..clinicaldata;
    %else %if %sysfunc(exist(out_&_Random..referencedata))
            %then %let _clinicalreferencedata_=out_&_Random..referencedata;

  proc sql noprint;
    create table members
    as select upcase(memname) as name
    from dictionary.tables
    where upcase(libname)=upcase("OUT_&_Random") and memtype="DATA"
    ;
  quit;

  %let _items=;
  %let _itemdata=;
  %let _itemgroupdata_=;
  data _null_;
    set members;
    if index(upcase(name), '_ITEMS') then
      call symputx('_items_', strip(name));
    if index(upcase(name), '_ITEMDATA') then
      call symputx('_itemdata_', strip(name));
    if index(upcase(name), 'ITEMGROUPDATA_') then
      call symputx('_itemgroupdata_', strip(name));
  run;

  proc delete data=work.members;
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
      where type="string" and (not(missing(length)));
  quit;

  %put &=variables;
  %put &=rename;
  %put &=label;
  %put &=length;

  %let dslabel=;
  %let dsname=;
  proc sql noprint;
    select label, name into :dslabel, :dsname trimmed
      from out_&_Random..&_itemgroupdata_
    ;
  quit;

  proc copy in=out_&_Random out=&dataoutlib;
    select &_itemdata_;
  run;

%if %sysevalf(%superq(metadataoutlib)=, boolean)=0 %then %do;

  %let ItemGroupOID=;
  proc sql noprint;
    select P3 into :ItemGroupOID trimmed
      from out_&_Random..alldata
      where P2 = "itemGroupData" and P = 3;
  quit;

  %create_template(type=STUDY, out=&metadataoutlib..metadata_study);
  %create_template(type=TABLES, out=&metadataoutlib..metadata_tables);
  %create_template(type=COLUMNS, out=&metadataoutlib..metadata_columns);

  %if %sysfunc(exist(out_&_Random..root)) %then %do;
    data work._metadata_study;
      merge out_&_Random..root &_clinicalreferencedata_;
    run;
  %end;
  %else %do;
    %if %sysfunc(exist(&_clinicalreferencedata_)) %then %do;
      data work._metadata_study;
        set &_clinicalreferencedata_;
      run;
    %end;
  %end;

  data &metadataoutlib..metadata_study;
    set &metadataoutlib..metadata_study work._metadata_study;
  run;

  proc delete data=work._metadata_study;
  run;


  data &metadataoutlib..metadata_tables;
    set &metadataoutlib..metadata_tables out_&_Random..&_itemgroupdata_(in=inigd drop=records);
    if inigd then do;
      oid = "&ItemGroupOID";
      call symputx('_ItemGroupName', name);
    end;
  run;

  data work.&_items_;
    set out_&_Random..&_items_;
    order = _n_;
  run;

  data &metadataoutlib..metadata_columns(%if %substr(%upcase(&DropSeqVar),1,1) eq Y %then where=(upcase(name) ne "ITEMGROUPDATASEQ"););
    set &metadataoutlib..metadata_columns work.&_items_(rename=(type=json_datatype) in=init);
    if init then dataset_name = "&_ItemGroupName";
  run;

  proc delete data=work.&_items_;
  run;

%end;

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

  proc datasets library=&dataoutlib noprint nolist nodetails;
    %if %sysfunc(exist(&dataoutlib..&dsname)) %then %do; delete &dsname; %end;
    change &_itemdata_ = &dsname;
    modify &dsname %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str((label = %sysfunc(quote(%nrbquote(&dslabel)))));;
      rename &rename;
      label &label;
  quit;

  /* Update lengths */
  proc sql noprint;
    select catt(d.name, ' $', i.length) into :length separated by ' '
      from dictionary.columns d,
           out_&_Random..&_items_ i
    where upcase(libname)="%upcase(&dataoutlib)" and
         upcase(memname)="%upcase(&dsname)" and
         d.name = i.name and
         d.type="char" and (not(missing(i.length))) and (i.length gt d.length)
   ;
  quit ;

  data &dataoutlib..&dsname(
      %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str(label = %sysfunc(quote(%nrbquote(&dslabel))));
      %if %substr(%upcase(&DropSeqVar),1,1) eq Y %then drop=ITEMGROUPDATASEQ;
    );
    retain &variables;
    length &length;
    %if %sysevalf(%superq(format)=, boolean)=0 %then format &format;;
    set &dataoutlib..&dsname;
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
    d.type as DataType,
    i.type,
    d.length as sas_length,
    i.length,
    d.format
   from dictionary.columns d,
        out_&_Random..&_items_ i
   where upcase(libname)="%upcase(&dataoutlib)" and
         upcase(memname)="%upcase(&dsname)" and
         d.name = i.name
   ;
  quit ;

  data _null_;
    set column_metadata;
    if DataType="char" and not (type in ('string')) then put "WAR" "NING: [&sysmacroname] TYPE ISSUE: dataset=&dsname " OID= name= DataType= type=;
    if DataType="num" and not (type in ('integer' 'double' 'float' 'decimal')) then put "WAR" "NING: [&sysmacroname] TYPE ISSUE: dataset=&dsname " OID= name= DataType= type=;
    if DataType="char" and not(missing(length)) and (length lt sas_length) then put "WAR" "NING: [&sysmacroname] LENGTH ISSUE: dataset=&dsname " OID= name= length= sas_length=;
  run;

  proc delete data=work.column_metadata;
  run;

  filename json&_Random clear;
  filename map&_Random clear;

  proc datasets nolist lib=out_&_Random kill;
  quit;

  %put %sysfunc(filename(fref,%sysfunc(pathname(out_&_Random))));
  %put %sysfunc(fdelete(&fref));
  libname out_&_Random clear;


  %exit_macro:

  %* Restore options;
  options &_SaveOptions1;

%mend read_datasetjson;
