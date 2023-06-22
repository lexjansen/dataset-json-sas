%macro read_datasetjson(
  jsonpath=, 
  dataoutlib=, 
  usemetadata=, 
  dropseqvar=,
  metadatalib=, 
  metadataoutlib=
  ) / des = 'Read a Dataset-JSON file to a SAS dataset';

  %local _Missing 
         _clinicalreferencedata_ _items_ _itemdata_ _itemgroupdata_ ItemGroupOID ItemGroupName 
         dslabel dsname variables rename label length format;


    %******************************************************************************;
    %* Parameter checks                                                           *;
    %******************************************************************************;
  
  %* Check for missing parameters ;
  %let _Missing=;
  %if %sysevalf(%superq(jsonpath)=, boolean) %then %let _Missing = &_Missing jsonpath;
  %if %sysevalf(%superq(dataoutlib)=, boolean) %then %let _Missing = &_Missing dataoutlib;
  %if %sysevalf(%superq(usemetadata)=, boolean) %then %let _Missing = &_Missing usemetadata;
  %if %sysevalf(%superq(dropseqvar)=, boolean) %then %let _Missing = &_Missing dropseqvar;

  %if %length(&_Missing) gt 0
    %then %do;
      %put ERR%str(OR): [&sysmacroname] Required macro parameter(s) missing: &_Missing;
      %goto exit_macro;
    %end;

  %* Rule: usemetadata has to be Y or N  *;
  %if "%substr(%upcase(&usemetadata),1,1)" ne "Y" and "%substr(%upcase(&usemetadata),1,1)" ne "N" %then
  %do;
    %put ERR%str(OR): [&sysmacroname] Required macro parameter usemetadata=&usemetadata must be Y or N.;
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

  filename jsonfile "&jsonpath";
  filename mapfile "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/)).map";
  libname out "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/))";

  libname jsonfile json map=mapfile automap=create fileref=jsonfile /* noalldata */ ordinalcount=none;
  proc copy in=jsonfile out=out;
  run;

  /* Find the names of the dataset that were created */
  proc sql noprint;
    create table members 
    as select upcase(memname) as name
    from dictionary.tables
    where libname="OUT" and memtype="DATA"
    ;
  quit;

  %let _clinicalreferencedata_=;
  %let _items=;
  %let _itemdata=;
  %let _itemgroupdata_=;
  data _null_;
    set members;
    if upcase(name)="CLINICALDATA" or upcase(name)="REFERENCEDATA" then 
      call symputx('_clinicalreferencedata_', strip(name));
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
      from out.&_items_;
    select cats("element", monotonic(), '=', name) into :rename separated by ' '
      from out.&_items_;
    select cats(name, '=', quote(strip(label))) into :label separated by ' '
      from out.&_items_;
    select catt(name, ' $', length) into :length separated by ' '
      from out.&_items_
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
      from out.&_itemgroupdata_
    ;
  quit;

  proc copy in=out out=&dataoutlib;
    select &_itemdata_;
  run;

  %let ItemGroupOID=;
  proc sql noprint;
    select P3 into :ItemGroupOID trimmed
      from out.alldata
      where P2 = "itemGroupData" and P = 3;
  quit;

%if %sysevalf(%superq(metadataoutlib)=, boolean)=0 %then %do;

  %create_template(type=STUDY, out=&metadataoutlib..metadata_study);
  %create_template(type=TABLES, out=&metadataoutlib..metadata_tables);
  %create_template(type=COLUMNS, out=&metadataoutlib..metadata_columns);

  %if %sysfunc(exist(out.root)) %then %do; 
    data work.metadata_study;
      merge out.root out.&_clinicalreferencedata_;
    run;  
  %end;
  %else %do;
    data work.metadata_study;
      set out.&_clinicalreferencedata_;
    run;  
  %end;  
  
  data &metadataoutlib..metadata_study;
    set &metadataoutlib..metadata_study work.metadata_study;
  run;  

  data &metadataoutlib..metadata_tables;
    set &metadataoutlib..metadata_tables out.&_itemgroupdata_(in=inigd drop=records);
    if inigd then do;
      oid = "&ItemGroupOID";
      call symputx('ItemGroupName', name);
    end;  
  run;  

  data work.&_items_;
    set out.&_items_;
    order = _n_;
  run;  

  data &metadataoutlib..metadata_columns(%if %substr(%upcase(&DropSeqVar),1,1) eq Y %then where=(upcase(name) ne "ITEMGROUPDATASEQ"););
    set &metadataoutlib..metadata_columns work.&_items_(rename=(type=json_datatype) in=init);
    if init then dataset_name = "&ItemGroupName";
  run;  

%end;

  /* get formats from Dataset-JSON metadata, but only when the displayformat variable exists */
  %let format=;
  %if %cstutilcheckvarsexist(_cstDataSetName=out.&_items_, _cstVarList=displayformat) %then %do;
    proc sql noprint;
      select catx(' ', name, strip(displayformat)) into :format separated by ' '
          from out.&_items_
          where not(missing(displayformat)) /* and (type in ('integer' 'float' 'double' 'decimal')) */;
    quit;
  %end;

  %if %substr(%upcase(&UseMetadata),1,1) eq Y %then %do;
    
    /* get formats from metadata */
    %let format=;
    proc sql noprint;
      select catx(' ', name, strip(displayformat)) into :format separated by ' '
          from &metadatalib..metadata_columns
          where upcase(dataset_name)="%upcase(&dsname)"
          and not(missing(displayformat)) /* and (xml_datatype in ('integer' 'float' 'double' 'decimal')) */;
    quit;
  %end;

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
           out.&_items_ i
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
        out.&_items_ i
   where upcase(libname)="%upcase(&dataoutlib)" and
         upcase(memname)="%upcase(&dsname)" and
         d.name = i.name
   ;
  quit ;

  data _null_;
    set column_metadata;
    if DataType="char" and not (type in ('string')) then put "WAR" "NING: TYPE ISSUE: dataset=&dsname " OID= name= DataType= type=;
    if DataType="num" and not (type in ('integer' 'double' 'float' 'decimal')) then put "WAR" "NING: TYPE ISSUE: dataset=&dsname " OID= name= DataType= type=;
    if DataType="char" and not(missing(length)) and (length lt sas_length) then put "WAR" "NING: LENGTH ISSUE: dataset=&dsname " OID= name= length= sas_length=;
  run;

  proc delete data=work.column_metadata;
  run;

  filename jsonfile clear;
  filename mapfile clear;
  libname out clear;

  %exit_macro:

%mend read_datasetjson;
