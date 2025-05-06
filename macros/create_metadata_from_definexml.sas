/**
  @file create_metadata_from_definexml.sas
  @brief Extract metadata from a Define-XML file.

  @details This macro extracts metadat from a Define-XML file.<br />
  The following metadata tables are created:
  @li metadata_study
  @li metadata_tables
  @li metadata_columns

  Example usage:

      %create_metadata_from_definexml(
         definexml=&project_folder/data/sdtm_xpt/define.xml,
         metadatalib=metasdtm
         );

  @author Lex Jansen

  @param[in] definexml= Path to Define-XML file
  @param[out] metadatalib= Define-XML metadata library
    The following datasets are created:
    @li metadata_study
    @li metadata_tables
    @li metadata_columns

**/

%macro create_metadata_from_definexml(
  definexml=,
  metadatalib=) / des = 'Extract metadata from a Define-XML file';


  %* Since JSON keys are case-sensitive, it is required that metadata datasets have case-sensitive columns;
  %local _SaveOptions;
  %let _SaveOptions = %sysfunc(getoption(validvarname, keyword));
  options validvarname = V7;
  
  proc lua infile='read_definexml';
  run;
  
  %* Reset VALIDVARNAME option to original value;
  options &_SaveOptions;
   
%mend create_metadata_from_definexml;
