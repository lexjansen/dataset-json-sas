options sasautos = (%qsysfunc(compress(%qsysfunc(getoption(SASAUTOS)),%str(%()%str(%)))) "&project_folder/macros");
filename luapath ("&project_folder/lua");

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

%SetLib(dataadam, &project_folder/data/adam);
%SetLib(datasdtm, &project_folder/data/sdtm);

%SetLib(outadam, &project_folder/data_out/adam);
%SetLib(outsdtm, &project_folder/data_out/sdtm);

%SetLib(metaadam, &project_folder/metadata/adam);
%SetLib(metasdtm, &project_folder/metadata/sdtm);

%SetLib(metainad, &project_folder/metadata_in/adam);
%SetLib(metainsd, &project_folder/metadata_in/sdtm);
