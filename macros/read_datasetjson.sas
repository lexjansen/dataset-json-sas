%macro read_datasetjson(jsonpath=, dataoutlib=, usemetadata=, metadatalib=, metadataoutlib=);

%local _clinicalreferencedata_ _items_ _itemdata_ _itemgroupdata_ dslabel dsname
       variables rename label length format;

filename jsonfile "&jsonpath";
filename mapfile "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/)).map";
libname out "%sysfunc(pathname(work))/%scan(&jsonpath, -2, %str(.\/))";

libname jsonfile json map=mapfile automap=create fileref=jsonfile noalldata ordinalcount=none;
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

proc copy in=out out=&metadataoutlib;
  select &_items_;
run;


%if &UseMetadata=1 %then %do;
  
  /* get formats from metadata */
  %let format=;
  proc sql noprint;
    select catx(' ', name, strip(displayformat)) into :format separated by ' '
        from &metadatalib..metadata_columns
        where upcase(dataset_name)="%upcase(&dsname)"
        and not(missing(displayformat)) and (xml_datatype in ('integer' 'float' 'double' 'decimal'));
  quit;
%end;

proc datasets library=&dataoutlib noprint nolist nodetails;
  %if %sysfunc(exist(&dataoutlib..&dsname)) %then %do; delete &dsname; %end;
  change &_itemdata_ = &dsname;
  modify &dsname %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str((label = %sysfunc(quote(%nrbquote(&dslabel)))));;
    rename &rename;
    label &label;
    %if %sysevalf(%superq(format)=, boolean)=0 %then format &format;;
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
  );
  retain &variables;
  length &length;
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
  if DataType="char" and not (type in ('string')) then put "WAR" "NING: &dsname " OID= name= DataType= type=;
  if DataType="num" and not (type in ('integer' 'double' 'float' 'decimal')) then put "WAR" "NING: &dsname " OID= name= DataType= type=;
  if DataType="char" and not(missing(length)) and (length lt sas_length) then put "WAR" "NING: &dsname " OID= name= length= sas_length=;
run;


proc delete data=work.column_metadata;
run;

filename jsonfile clear;
filename mapfile clear;
libname out clear;

%mend read_datasetjson;
