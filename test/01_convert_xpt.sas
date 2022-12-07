%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";


%let _cst_rc=;
%let _cst_rcmsg=;

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(dataadam)), 
  _cstOutputLibrary=dataadam,
  _cstExtension=XPT,
  _cstOptions=
  );

%cstutilxptread(
  _cstSourceFolder=%sysfunc(pathname(datasdtm)), 
  _cstOutputLibrary=datasdtm,
  _cstExtension=XPT,
  _cstOptions=
  );

  /*
libname dataadam clear;
libname datasdtm clear;
*/  
   