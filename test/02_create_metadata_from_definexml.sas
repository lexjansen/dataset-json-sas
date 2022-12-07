%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";

%macro CreateMetadataFromDefineXML(definexml=, metadatalib=);
  proc lua infile='read_definexml';
  run;
%mend CreateMetadataFromDefineXML;



/* Create metadata from Define-XML for SDTM */
%CreateMetadataFromDefineXML(
   definexml=&root/json/adam/define_2_0.xml, 
   metadatalib=metaadam
   );

/* Some manual data type updates */
data metaadam.metadata_columns;
  set metaadam.metadata_columns;
  if xml_datatype='float' then do;
    if index(name, 'VISIT') then json_datatype='decimal';
  end;
run;



/* Create metadata from Define-XML for SDTM */
%CreateMetadataFromDefineXML(
   definexml=&root/json/sdtm/define.xml, 
   metadatalib=metasdtm
   );

/* Some manual data type updates */
data metasdtm.metadata_columns;
  set metasdtm.metadata_columns;
  if xml_datatype='float' then do;
    if name ne 'LBSTRESN' then json_datatype='decimal';
  end;
run;


/*
libname metaadam clear;
libname metasdtm clear;
*/  