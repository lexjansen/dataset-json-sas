options dlcreatedir compress=yes;

options sasautos = (%qsysfunc(compress(%qsysfunc(getoption(SASAUTOS)),%str(%()%str(%)))) "&root/macros");
filename luapath ("&root/lua");

%macro Setlib(lib, folder, option, comment=&option, engine=v9, log=1);
 %local rc;
 %let rc=%sysfunc(libname(&lib, &folder, &engine, &option));
 %if %sysfunc(libref(&lib))
   %then %do;
        %if &log=1 %then %put %str(    &lib = not assigned [&folder]);
                   %else %do;
                     %put ;
                     %put %str(war)ning: library &lib [&folder] does not exist.;
                    %end;
        %let rc=%sysfunc(libname(&lib, ""));
     %end;
   %else %if &log=1 %then
         %put %str(Libname &lib assigned [%nrbquote(%sysfunc(pathname(&lib)))]) &comment;
%mend Setlib;

%SetLib(dataadam, &root/data/adam);
%SetLib(datasdtm, &root/data/sdtm);

%SetLib(outadam, &root/data_out/adam);
%SetLib(outsdtm, &root/data_out/sdtm);

%SetLib(metaadam, &root/metadata/adam);
%SetLib(metasdtm, &root/metadata/sdtm);
