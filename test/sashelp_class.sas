%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";
options mprint ls=max;


data work.class(label="%cstutilgetattribute(_cstDataSetName=sashelp.class, _cstAttribute=LABEL)");
  * attrib ITEMGROUPDATASEQ length=8 label="Record Identifier";
  label Name = "Name" Sex = "Sex" Age="Age" Height="Height";
  set sashelp.class;
  * ITEMGROUPDATASEQ = strip(put(_n_, best.));
run;

data work.class;
  set sashelp.class;
run;


/*
%let _File=class.xpt;
libname xptFile xport "&_File";
proc copy in=work out=xptfile;
select class;
run;
*/

%write_datasetjson(
      dataset=work.class,
      xptpath=C:\_github\lexjansen\dataset-json-sas\test\class.xpt,
      jsonpath=class.json,
      usemetadata=N);

proc datasets library=work noprint nolist nodetails;
  change class = class_old;
quit;

%read_datasetjson(
  jsonpath=class.json,
  dataoutlib=work,
  dropseqvar=Y);

proc compare base=work.class_old compare=work.class;
run;

%write_datasetjson(
      dataset=work.class,
      jsonpath=class_new.json,
      usemetadata=N);

