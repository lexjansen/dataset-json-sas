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

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON.                   */
  if xml_datatype='float' and index(name, 'VISIT') 
    then json_datatype='decimal';

  if missing(length) then do;
    if xml_datatype="date" then length=10;
    if xml_datatype="partialDate" then length=10;
    if xml_datatype="partialDatetime" then length=19;
    if xml_datatype="durationDatetime" then length=19;
    if xml_datatype="datetime" then length=19;
  end;    
run;

/* Create metadata from Define-XML for SDTM */
%CreateMetadataFromDefineXML(
   definexml=&project_folder/data/sdtm_xpt/define.xml, 
   metadatalib=metasdtm
   );

/* Some manual data type updates */
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;

  /* Define-XML v2 does not support decimal, but it is supported by Dataset-JSON. */
  /* This update is just to show that it works in Dataset-JSON.                   */
  if xml_datatype='float' and name ne 'LBSTRESN' 
    then json_datatype='decimal';

  if missing(length) then do;
    if xml_datatype="date" then length=10;
    if xml_datatype="partialDate" then length=10;
    if xml_datatype="partialDatetime" then length=19;
    if xml_datatype="durationDatetime" then length=19;
    if xml_datatype="datetime" then length=19;
  end;    
run;


/*
libname metaadam clear;
libname metasdtm clear;
*/  