%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";



data _null_;
  length fref $8 jsonpath $200 code $400;
  did = filename(fref,"&root/json/adam");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonpath = cats("&root/json_out/adam", "/", dread(did,i));
    if scan(lowcase(jsonpath), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_datasetjson(',
                  'jsonpath=', jsonpath, ', ',
                  'dataoutlib=outadam, ',
                  'usemetadata=Y, ',
                  'dropseqvar=Y, ',
                  'metadatalib=metaadam, ',
                  'metadataoutlib=metainad',
                ');)');
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;


data _null_;
  length fref $8 jsonpath $200 code $400;
  did = filename(fref,"&root/json_out/sdtm");
  did = dopen(fref);
  do i = 1 to dnum(did);
    jsonpath = cats("&root/json/sdtm", "/", dread(did,i));
    if scan(lowcase(jsonpath), -1, ".") = 'json' then do;
      code=cats('%nrstr(%read_datasetjson(',
                  'jsonpath=', jsonpath, ', ',
                  'dataoutlib=outsdtm, ',
                  'usemetadata=Y, ',
                  'dropseqvar=Y, ',
                  'metadatalib=metasdtm, ',
                  'metadataoutlib=metainsd',
                ');)');
      call execute(code);
    end;
  end;
  did = dclose(did);
  did = filename(fref);
run;


/*
libname metaadam clear;
libname metasdtm clear;
libname outadam clear;
libname outsdtm clear;
*/