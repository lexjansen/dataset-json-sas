options sasautos = (%qsysfunc(compress(%qsysfunc(getoption(SASAUTOS)),%str(%()%str(%)))) "&project_folder/macros");
options ls=max;
filename luapath ("&project_folder/lua");

%let now_iso8601=%sysfunc(datetime(), is8601dt.);
%let today_iso8601=%sysfunc(date(), b8601da8.);  

libname dataadam "&project_folder/data/adam";
libname datasdtm "&project_folder/data/sdtm";

libname outadam  "&project_folder/data_out/adam";
libname outsdtm  "&project_folder/data_out/sdtm";

libname metaadam "&project_folder/metadata/adam";
libname metasdtm "&project_folder/metadata/sdtm";

libname metasvad "&project_folder/metadata_save/adam";
libname metasvsd "&project_folder/metadata_save/sdtm";

libname results "&project_folder/results";
libname macros "&project_folder/macros";

options cmplib=macros.datasetjson_funcs;
