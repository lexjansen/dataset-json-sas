%* update this location to your own location;
%let project_folder=/_github/lexjansen/dataset-json-sas;
%include "&project_folder/programs/config.sas";

%let _SaveOptions = %sysfunc(getoption(dlcreatedir));
options dlcreatedir;

libname meta1 "&project_folder/test_metadata/metadata1";
libname meta20 "&project_folder/test_metadata/metadata20";
libname meta21 "&project_folder/test_metadata/metadata21";

/* Create metadata from Define-XML v1.0 */
%create_metadata_from_definexml(
   definexml=&project_folder/test_metadata/testdata/define1-0-0.xml, 
   metadatalib=meta1
   );

/* Create metadata from Define-XML v1.0 */
%create_metadata_from_definexml(
   definexml=&project_folder/test_metadata/testdata/define2-0-0-example-sdtm.xml, 
   metadatalib=meta20
   );

/* Create metadata from Define-XML v1.0 */
%create_metadata_from_definexml(
   definexml=&project_folder/test_metadata/testdata/defineV21-SDTM.xml, 
   metadatalib=meta21
   );


%* Restore options;
options &_SaveOptions;
 
/*
libname meta1 clear;
libname meta20 clear;
libname meta21 clear;
*/  