%macro read_json(jsonfile, model);

%local _clinicalreferencedata_ _items_ _itemdata_ _itemgroupdata_ dslabel dsname
       variables rename label length format;

libname data "&root/data/&model";
libname dataout "&root/data_out/&model";
libname metadata "&root/metadata/&model";

filename jsonfile "&root/json/&model/&jsonfile";
filename mapfile "%sysfunc(pathname(work))/%scan(&jsonfile, 1, %str(.)).map";
libname out "%sysfunc(pathname(work))/%scan(&jsonfile, 1, %str(.))";

libname jsonfile json map=mapfile automap=create fileref=jsonfile noalldata ordinalcount=none;
proc copy in=jsonfile out=out;
run;

/* Find the names of the dataset that were created */
ods output Members=members(keep=name);
  proc datasets library=out memtype=data;
  quit;
run;

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

proc copy in=out out=dataout;
  select &_itemdata_;
run;

/* get formats from metadata */
%let format=;
proc sql noprint;
  select catx(' ', name, strip(displayformat)) into :format separated by ' '
      from metadata.metadata_columns
      where upcase(dataset_name)="%upcase(&dsname)"
      and not(missing(displayformat)) and (xml_datatype in ('integer' 'float' 'double' 'decimal'));
quit;

proc datasets library=dataout noprint nolist nodetails;
  delete &dsname;
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
  where upcase(libname)="DATAOUT" and
       upcase(memname)="%upcase(&dsname)" and
       d.name = i.name and
       d.type="char" and (not(missing(i.length))) and (i.length gt d.length)
 ;
quit ;

data dataout.&dsname(
    %if %sysevalf(%superq(dslabel)=, boolean)=0 %then %str(label = %sysfunc(quote(%nrbquote(&dslabel))));
  );
  retain &variables;
  length &length;
  set dataout.&dsname;
run;



/* Compare created data with original data*/

proc compare base=data.&dsname compare=dataout.&dsname(drop=ITEMGROUPDATASEQ) listall
  criterion=1e-8 method=absolute;
run;

%let compinfo=&sysinfo;
data _null_;
  length result 8 resultc restmp $200;
  array r(*) 8 r1 r2 r3 r4 r5 r6 r7 r8 r9 r10 r11 r12 r13 r14 r15 r16;
  result=&compinfo;
  resultc="";
  restmp='/DSLABEL/DSTYPE/INFORMAT/FORMAT/LENGTH/LABEL/BASEOBS/COMPOBS'||
        '/BASEBY/COMPBY/BASEVAR/COMPVAR/VALUE/TYPE/BYVAR/ER'||'ROR';
  do i=1 to 16;
    if result >= 0 then do;
      if band(result, 2**(i-1)) then do;
        resultc=trim(resultc)||'/'||scan(restmp,i,'/'); 
        r(i) = 1;
      end;
    end;  
  end;
  if result=0 then resultc="NO DIFFERENCES";
  resultc=left(resultc);
  if index(resultc,'/')=1 then resultc=substr(resultc,2);
  call symputx ('resultc', resultc);
run;

%put ### &dsname - &compinfo - &resultc;



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
 where upcase(libname)="DATAOUT" and
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

filename jsonfile clear;
filename mapfile clear;
libname out clear;

libname data clear;
libname dataout clear;
libname metadata clear;

%mend read_json;
