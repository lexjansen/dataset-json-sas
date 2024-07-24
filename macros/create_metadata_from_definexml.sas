%macro create_metadata_from_definexml(definexml=, metadatalib=);
  proc lua infile='read_definexml';
  run;
%mend create_metadata_from_definexml;
