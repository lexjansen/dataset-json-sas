options dlcreatedir compress=yes;

options sasautos = (%qsysfunc(compress(%qsysfunc(getoption(SASAUTOS)),%str(%()%str(%)))) "&root/macros");
filename luapath ("&root/lua");

