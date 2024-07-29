%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

/* Create metadata from ADaM Define-XML */
%create_metadata_from_definexml(
   definexml=&project_folder/data/adam_xpt/define.xml, 
   metadatalib=metaadam
   );

/* Create metadata from SDTM Define-XML */
%create_metadata_from_definexml(
   definexml=&project_folder/data/sdtm_xpt/define.xml, 
   metadatalib=metasdtm
   );

/* Create metadata from SEND Define-XML */
%create_metadata_from_definexml(
   definexml=&project_folder/data/send_xpt/define.xml, 
   metadatalib=metasend
   );

/*
libname metaadam clear;
libname metasdtm clear;
libname metasend clear;
*/  
