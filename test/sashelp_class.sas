%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

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
      xptpath=&project_folder\test\class.xpt,
      jsonpath=&project_folder\test\class.json,
      usemetadata=N,
      pretty=PRETTY);

proc datasets library=work noprint nolist nodetails;
  change class = class_old;
quit;

%read_datasetjson(
  jsonpath=&project_folder\test\class.json,
  datalib=work,
  dropseqvar=Y
);

proc compare base=work.class_old compare=work.class;
run;

%write_datasetjson(
      dataset=work.class,
      jsonpath=&project_folder\test\class_new.json,
      usemetadata=N);

