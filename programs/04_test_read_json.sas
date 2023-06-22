%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/programs/config.sas";


%get_dirtree(dir=&root/json_out/adam, outds=dirtree_adam);

data _null_;
  length code $2048;
  set dirtree_adam(where=(ext="json" and dir=0));
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'dataoutlib=outadam, ',
                'usemetadata=N, ',
                'dropseqvar=Y, ',
                'metadatalib=metaadam, ',
                'metadataoutlib=metainad',
              ');)');
    call execute(code);
run;


%get_dirtree(dir=&root/json_out/sdtm, outds=dirtree_sdtm);

data _null_;
  length code $2048;
  set dirtree_sdtm(where=(ext="json" and dir=0));
    code=cats('%nrstr(%read_datasetjson(',
                'jsonpath=', fullpath, ', ',
                'dataoutlib=outsdtm, ',
                'usemetadata=N, ',
                'dropseqvar=Y, ',
                'metadatalib=metasdtm, ',
                'metadataoutlib=metainsd',
              ');)');
    call execute(code);
run;



/*
libname metaadam clear;
libname metasdtm clear;
libname outadam clear;
libname outsdtm clear;
*/