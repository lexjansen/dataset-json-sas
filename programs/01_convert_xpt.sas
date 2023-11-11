%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%let _cst_rc=;
%let _cst_rcmsg=;

/* Convert ADaM XPT files to SAS datasets */
%cstutilxptread(
  _cstSourceFolder=&project_folder/data/adam_xpt, 
  _cstOutputLibrary=dataadam,
  _cstExtension=XPT,
  _cstOptions=
  );
/*
proc contents data=dataadam._ALL_;
run;
*/

/* Convert SDTM XPT files to SAS datasets */
%cstutilxptread(
  _cstSourceFolder=&project_folder/data/sdtm_xpt, 
  _cstOutputLibrary=datasdtm,
  _cstExtension=XPT,
  _cstOptions=
  );
/*
proc contents data=datasdtm._ALL_;
run;
*/

/*
libname dataadam clear;
libname datasdtm clear;
*/  
   