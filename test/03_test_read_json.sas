%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;

%include "&root/test/config.sas";


%let model=adam;
data _null_;
  length fref $8 jsonfile $200 code $200;
  did = filename(fref,"&root/json/&model");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonfile = dread(did,i);
    if scan(lowcase(jsonfile), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_json(', jsonfile, ", &model);)");
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;

%let model=sdtm;
data _null_;
  length fref $8 jsonfile $200 code $200;
  did = filename(fref,"&root/json/&model");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonfile = dread(did,i);
    if scan(lowcase(jsonfile), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_json(', jsonfile, ", &model);)");
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;
