%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;

%include "&root/test/config.sas";


%let model=adam;
libname data "&root/data/&model";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

data _null_;
  length code $200;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%write_json(data.', name, ", &model);)");
  call execute(code);
run;
libname data clear;
  

%let model=sdtm;
libname data "&root/data/&model";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

data _null_;
  length code $200;
  set members;
  name=lowcase(name);
  code=cats('%nrstr(%write_json(data.', name, ", &model);)");
  call execute(code);
run;
libname data clear;
