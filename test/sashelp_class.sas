%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

data work.class(label="%cstutilgetattribute(_cstDataSetName=sashelp.class, _cstAttribute=LABEL)");
  * attrib ITEMGROUPDATASEQ length=8 label="Record Identifier";
  label Name = "Name" Sex = "Sex" Age="Age" Height="Height";
  set sashelp.class;
  * ITEMGROUPDATASEQ = strip(put(_n_, best.));
  bmi = weight * 703 / (height * height);
run;

data work.class;
  length bmi birthdate 8.;
  format birthdate E8601DA. bmi 32.29;
  label bmi = "Body Mass Index" birthdate = "Date of birth";
  set sashelp.class;
  bmi = weight * 703 / (height * height);
  birthdate = today() - ((age +1) * 365) + rand("Integer", 1, 366);
run;

%put %cstutilgetattribute(_cstDataSetName=work.class, _cstVarName=birthdate, _cstAttribute=VARFMT);
proc contents data=work.class varnum;
proc print data=work.class;
  format bmi best32.28;
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
      jsonpath=&project_folder\test\class_bmi_num.json,
      usemetadata=N,
      pretty=PRETTY);

%write_datasetjson(
      dataset=work.class,
      jsonpath=&project_folder\test\class.json,
      usemetadata=N,
      decimalVariables=bmi,
      iso8601Variables=birthdate,
      pretty=PRETTY);

proc datasets library=work noprint nolist nodetails;
  change class = class_old;
quit;

%read_datasetjson(
  jsonpath=&project_folder\test\class.json,
  datalib=work,
  dropseqvar=Y,
  savemetadata=N
);

proc contents data=work.class varnum;
proc print data=work.class;
  format bmi best32.28;
run;
proc compare base=work.class_old compare=work.class;
run;

%read_datasetjson(
  jsonpath=&project_folder\test\class_bmi_num.json,
  datalib=work,
  dropseqvar=Y,
  savemetadata=N
);

proc compare base=work.class_old compare=work.class;
run;

%write_datasetjson(
      dataset=work.class,
      jsonpath=&project_folder\test\class_new.json,
      usemetadata=N);

proc contents data=work.class varnum;
proc print data=work.class;
  format bmi best32.28;
run;

