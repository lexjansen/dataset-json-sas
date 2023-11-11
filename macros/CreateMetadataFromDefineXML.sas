%macro CreateMetadataFromDefineXML(definexml=, metadatalib=);
  proc lua infile='read_definexml';
  run;
%mend CreateMetadataFromDefineXML;
