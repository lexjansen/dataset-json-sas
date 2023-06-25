%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";


%get_dirtree(dir=&root/json_out/adam, outds=work.dirtree_adam);

data _null_;
  length code $2048;
  set work.dirtree_adam(where=(ext="json" and dir=0));
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'dataoutlib=outadam, ',
                'dropseqvar=Y, ',
                'metadataoutlib=metainad',
              ');)');
    call execute(code);
run;

proc delete data=work.dirtree_adam;
run;



%get_dirtree(dir=&root/json_out/sdtm, outds=work.dirtree_sdtm);

data _null_;
  length code $2048;
  set work.dirtree_sdtm(where=(ext="json" and dir=0));
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'dataoutlib=outsdtm, ',
                'dropseqvar=Y, ',
                'metadataoutlib=metainsd',
              ');)');
    call execute(code);
run;

proc delete data=work.dirtree_sdtm;
run;

/*
libname metaadam clear;
libname metasdtm clear;
libname outadam clear;
libname outsdtm clear;
*/