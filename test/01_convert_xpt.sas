%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;


%include "&root/test/config.sas";


%let _cst_rc=;

%let _cst_rcmsg=;
libname outa "&root/data/adam";
libname outs "&root/data/sdtm";

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(outa)), 
  _cstOutputLibrary=outa,
  _cstExtension=XPT,
  _cstOptions=
  );

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(outs)), 
  _cstOutputLibrary=outs,
  _cstExtension=XPT,
  _cstOptions=
  );

   