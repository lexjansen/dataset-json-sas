options sasautos = ("&project_folder/macros" "&project_folder/macros/internal" 
                    %qsysfunc(compress(%qsysfunc(getoption(SASAUTOS)),%str(%()%str(%)))));
options ls=max;
filename luapath ("&project_folder/lua");

%let now_iso8601=%sysfunc(datetime(), is8601dt.);
%let today_iso8601=%sysfunc(date(), b8601da8.);

libname dataadam "&project_folder/data/adam";
libname datasdtm "&project_folder/data/sdtm";
libname datasend "&project_folder/data/send";

libname outadam  "&project_folder/data_out/adam";
libname outsdtm  "&project_folder/data_out/sdtm";
libname outsend  "&project_folder/data_out/send";

libname metaadam "&project_folder/metadata/adam";
libname metasdtm "&project_folder/metadata/sdtm";
libname metasend "&project_folder/metadata/send";

libname metasvad "&project_folder/metadata_save/adam";
libname metasvsd "&project_folder/metadata_save/sdtm";
libname metasvse "&project_folder/metadata_save/send";

libname results "&project_folder/results";
libname macros "&project_folder/macros";

options mprint nomlogic nosymbolgen;