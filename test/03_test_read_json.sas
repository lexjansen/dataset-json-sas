%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";


%let model=adam;
libname dataout "&root/data_out/&model";
libname metadata "&root/metadata/&model";

data _null_;
  length fref $8 jsonfile $200 code $200;
  did = filename(fref,"&root/json/&model");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonfile = cats("&root/json/&model", "/", dread(did,i));
    if scan(lowcase(jsonfile), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_json(',
                  'dataoutlib=dataout, ',
                  'metadatalib=metadata, ',
                  'usemetadata=1, ',
                  'jsonfile=', jsonfile, 
                ');)');
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;
libname dataout clear;
libname metadata clear;

%let model=sdtm;
libname dataout "&root/data_out/&model";
libname metadata "&root/metadata/&model";
data _null_;
  length fref $8 jsonfile $200 code $200;
  did = filename(fref,"&root/json/&model");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonfile = cats("&root/json/&model", "/", dread(did,i));
    if scan(lowcase(jsonfile), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_json(',
                  'dataoutlib=dataout, ',
                  'metadatalib=metadata, ',
                  'usemetadata=1, ',
                  'jsonfile=', jsonfile,
                ');)');
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;
libname dataout clear;
libname metadata clear;
