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
  metadatalib=) des = 'Extract metadata from a Define-XML file';

  proc lua infile='read_definexml';
  run;
%mend create_metadata_from_definexml;
