%macro CreateMetadataFromDefineXML(definexml=, metadatalib=);
%* Get metadata from Define-XML ;

  proc lua infile='read_definexml';
  run;

%mend CreateMetadataFromDefineXML;


%* update this location to your own location;
%let root=/_github/lexjansen/dataset-json-sas;
%include "&root/test/config.sas";


libname metadata "&root/metadata/sdtm";

%CreateMetadataFromDefineXML(
   definexml=&root/json/sdtm/define.xml, 
   metadatalib=metadata
   );

/* Some manual data type updates */
data metadata.metadata_columns;
  set metadata.metadata_columns;
  if xml_datatype='float' then do;
    if name ne 'LBSTRESN' then json_datatype='decimal';
  end;
run;
libname metadata clear;


libname metadata "&root/metadata/adam";

%CreateMetadataFromDefineXML(
   definexml=&root/json/adam/define_2_0.xml, 
   metadatalib=metadata
   );

/* Some manual data type updates */
data metadata.metadata_columns;
  set metadata.metadata_columns;
  if xml_datatype='float' then do;
    if index(name, 'VISIT') then json_datatype='decimal';
  end;
run;
libname metadata clear;
  