%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";


%macro CreateMetadataFromDefineXML(definexml=, metadatalib=);
  proc lua infile='read_definexml';
  run;
%mend CreateMetadataFromDefineXML;


/* Create metadata from Define-XML for ADaM */
%CreateMetadataFromDefineXML(
   definexml=&project_folder/data/adam_xpt/define.xml, 
   metadatalib=metaadam
   );

/* Some manual data type updates */
data metaadam.metadata_columns;
  set metaadam.metadata_columns;
  if xml_datatype='float' and index(name, 'VISIT') 
    then json_datatype='decimal';
run;

/* Create metadata from Define-XML for SDTM */
%CreateMetadataFromDefineXML(
   definexml=&project_folder/data/sdtm_xpt/define.xml, 
   metadatalib=metasdtm
   );

/* Some manual data type updates */
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;
  if xml_datatype='float' and name ne 'LBSTRESN' 
    then json_datatype='decimal';
run;


/*
libname metaadam clear;
libname metasdtm clear;
*/  