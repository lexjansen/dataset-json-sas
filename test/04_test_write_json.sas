%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";


libname metadata "&root/metadata/adam";
libname data "&root/data/adam";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

data _null_;
  length code $400 jsonfile $200;
  set members;
  name=lowcase(name);
  jsonfile=cats("&root/json_out/adam/", name, ".json");
  code=cats('%nrstr(%write_json(',
              'dataset=data.', name, ', ', 
              'usemetadata=1, ',
              'metadatalib=metadata, ',
              'jsonfile=', jsonfile,
            ');)');
  call execute(code);
run;
libname metadata clear;
libname data clear;



libname metadata "&root/metadata/sdtm";
libname data "&root/data/sdtm";
ods output Members=members(keep=name);
  proc datasets library=data memtype=data;
quit;
run;

%let StudyOID=%str(cdisc.com/CDISCPILOT01);
%let MetaDataVersionOID=%str(MDV.MSGv2.0.SDTMIG.3.3.SDTM.1.7);


data _null_;
  length code $400 jsonfile $200;
  set members;
  name=lowcase(name);
  jsonfile=cats("&root/json_out/sdtm/", name, ".json");
  code=cats('%nrstr(%write_json(',
              'dataset=data.', name, ', ', 
              'usemetadata=0, ',
              'metadatalib=metadata, ',
              "_studyOID=&StudyOID, ",
              "_MetaDataVersionOID=&MetaDataVersionOID, ",
              'jsonfile=', jsonfile,
            ');)');
  call execute(code);
run;
libname metadata clear;
libname data clear;
